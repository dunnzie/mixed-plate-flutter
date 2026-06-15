"""Mixed Plate API — FastAPI backend with session-based auth and SQLite."""
from __future__ import annotations

import hashlib
import hmac
import os
import random
import secrets
import sqlite3
import string
import uuid
from datetime import datetime
from typing import Optional

from fastapi import Depends, FastAPI, Header, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

# ── Config ────────────────────────────────────────────────────────────────────

SECRET_KEY = os.environ.get("SECRET_KEY", "mixed-plate-dev-secret-change-in-prod")
DB_PATH = os.environ.get("DB_PATH", "mixed_plate.db")

# ── App ───────────────────────────────────────────────────────────────────────

app = FastAPI(title="Mixed Plate API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Database ──────────────────────────────────────────────────────────────────

def _db() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")
    return conn


def _init_db() -> None:
    conn = _db()
    conn.executescript("""
        CREATE TABLE IF NOT EXISTS users (
            id            TEXT PRIMARY KEY,
            email         TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            created_at    TEXT DEFAULT CURRENT_TIMESTAMP
        );
        CREATE TABLE IF NOT EXISTS sessions (
            token      TEXT PRIMARY KEY,
            user_id    TEXT NOT NULL,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
        );
        CREATE TABLE IF NOT EXISTS households (
            id          TEXT PRIMARY KEY,
            name        TEXT NOT NULL,
            invite_code TEXT UNIQUE NOT NULL,
            created_by  TEXT NOT NULL,
            created_at  TEXT DEFAULT CURRENT_TIMESTAMP
        );
        CREATE TABLE IF NOT EXISTS household_members (
            user_id      TEXT NOT NULL,
            household_id TEXT NOT NULL,
            joined_at    TEXT DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (user_id, household_id)
        );
        CREATE TABLE IF NOT EXISTS swipes (
            id           TEXT PRIMARY KEY,
            user_id      TEXT NOT NULL,
            household_id TEXT NOT NULL,
            meal_id      TEXT NOT NULL,
            liked        INTEGER NOT NULL,
            created_at   TEXT DEFAULT CURRENT_TIMESTAMP,
            UNIQUE (user_id, household_id, meal_id)
        );
    """)
    conn.commit()
    conn.close()


_init_db()

# ── Auth helpers ──────────────────────────────────────────────────────────────

def _hash_pw(password: str) -> str:
    salt = secrets.token_hex(16)
    digest = hashlib.sha256(f"{salt}{password}{SECRET_KEY}".encode()).hexdigest()
    return f"{salt}:{digest}"


def _verify_pw(password: str, stored: str) -> bool:
    salt, digest = stored.split(":", 1)
    expected = hashlib.sha256(f"{salt}{password}{SECRET_KEY}".encode()).hexdigest()
    return hmac.compare_digest(digest, expected)


def _new_token() -> str:
    return secrets.token_hex(32)


def _invite_code() -> str:
    return "".join(random.choices(string.ascii_uppercase + string.digits, k=6))


def _get_user(authorization: Optional[str] = Header(default=None)) -> str:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Not authenticated")
    token = authorization.split(" ", 1)[1]
    conn = _db()
    try:
        row = conn.execute(
            "SELECT user_id FROM sessions WHERE token = ?", (token,)
        ).fetchone()
    finally:
        conn.close()
    if not row:
        raise HTTPException(status_code=401, detail="Invalid or expired token")
    return row["user_id"]


# ── Request / response models ─────────────────────────────────────────────────

class AuthRequest(BaseModel):
    email: str
    password: str


class CreateHouseholdRequest(BaseModel):
    name: str = "Our Household"


class JoinRequest(BaseModel):
    invite_code: str


class SwipeRequest(BaseModel):
    household_id: str
    meal_id: str
    liked: bool


class PrefsRequest(BaseModel):
    dietary: dict = {}
    cuisines: list = []
    custom_allergies: str = ""
    dietary_type: str = "none"


# ── Auth endpoints ────────────────────────────────────────────────────────────

@app.post("/auth/signup")
def signup(req: AuthRequest):
    conn = _db()
    try:
        user_id = str(uuid.uuid4())
        pw_hash = _hash_pw(req.password)
        try:
            conn.execute(
                "INSERT INTO users (id, email, password_hash) VALUES (?, ?, ?)",
                (user_id, req.email.lower().strip(), pw_hash),
            )
        except sqlite3.IntegrityError:
            raise HTTPException(status_code=400, detail="Email already registered")
        token = _new_token()
        conn.execute(
            "INSERT INTO sessions (token, user_id) VALUES (?, ?)", (token, user_id)
        )
        conn.commit()
        return {"user_id": user_id, "access_token": token, "email": req.email.lower().strip()}
    finally:
        conn.close()


@app.post("/auth/login")
def login(req: AuthRequest):
    conn = _db()
    try:
        row = conn.execute(
            "SELECT id, password_hash FROM users WHERE email = ?",
            (req.email.lower().strip(),),
        ).fetchone()
        if not row or not _verify_pw(req.password, row["password_hash"]):
            raise HTTPException(status_code=401, detail="Invalid email or password")
        token = _new_token()
        conn.execute(
            "INSERT INTO sessions (token, user_id) VALUES (?, ?)", (token, row["id"])
        )
        conn.commit()
        return {"user_id": row["id"], "access_token": token, "email": req.email.lower().strip()}
    finally:
        conn.close()


@app.post("/auth/logout")
def logout(user_id: str = Depends(_get_user), authorization: Optional[str] = Header(default=None)):
    if authorization:
        token = authorization.split(" ", 1)[1]
        conn = _db()
        conn.execute("DELETE FROM sessions WHERE token = ?", (token,))
        conn.commit()
        conn.close()
    return {"ok": True}


# ── Household endpoints ───────────────────────────────────────────────────────

@app.post("/households")
def create_household(req: CreateHouseholdRequest, user_id: str = Depends(_get_user)):
    conn = _db()
    try:
        # Return existing household if already a member
        existing = conn.execute(
            """SELECT h.id, h.name, h.invite_code
               FROM households h
               JOIN household_members m ON m.household_id = h.id
               WHERE m.user_id = ?""",
            (user_id,),
        ).fetchone()
        if existing:
            return {"id": existing["id"], "name": existing["name"], "code": existing["invite_code"]}

        h_id = str(uuid.uuid4())
        code = _invite_code()
        # Ensure uniqueness
        while conn.execute(
            "SELECT 1 FROM households WHERE invite_code = ?", (code,)
        ).fetchone():
            code = _invite_code()

        conn.execute(
            "INSERT INTO households (id, name, invite_code, created_by) VALUES (?, ?, ?, ?)",
            (h_id, req.name, code, user_id),
        )
        conn.execute(
            "INSERT INTO household_members (user_id, household_id) VALUES (?, ?)",
            (user_id, h_id),
        )
        conn.commit()
        return {"id": h_id, "name": req.name, "code": code}
    finally:
        conn.close()


@app.post("/households/join")
def join_household(req: JoinRequest, user_id: str = Depends(_get_user)):
    conn = _db()
    try:
        h = conn.execute(
            "SELECT * FROM households WHERE invite_code = ?",
            (req.invite_code.upper().strip(),),
        ).fetchone()
        if not h:
            raise HTTPException(status_code=404, detail="Invalid invite code — check the code and try again")

        # Idempotent join
        conn.execute(
            "INSERT OR IGNORE INTO household_members (user_id, household_id) VALUES (?, ?)",
            (user_id, h["id"]),
        )
        conn.commit()
        return {"id": h["id"], "name": h["name"], "code": h["invite_code"]}
    finally:
        conn.close()


@app.post("/households/invite-code")
def get_invite_code(user_id: str = Depends(_get_user)):
    conn = _db()
    try:
        row = conn.execute(
            """SELECT h.invite_code
               FROM households h
               JOIN household_members m ON m.household_id = h.id
               WHERE m.user_id = ?""",
            (user_id,),
        ).fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="Not in a household")
        return {"code": row["invite_code"]}
    finally:
        conn.close()


# ── Meals ─────────────────────────────────────────────────────────────────────

_MEALS = [
    {"id": "1", "name": "Chicken Tikka Masala", "description": "Tender chicken in a creamy tomato-based curry sauce with aromatic Indian spices.", "imageUrl": "https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=600&h=750&fit=crop", "cuisine": "Indian", "tags": ["Spicy", "Gluten-Free"], "calories": 420, "prepTime": 35, "rating": 4.8},
    {"id": "2", "name": "Margherita Pizza", "description": "Classic Neapolitan pizza with San Marzano tomatoes, fresh mozzarella, and basil.", "imageUrl": "https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=600&h=750&fit=crop", "cuisine": "Italian", "tags": ["Vegetarian"], "calories": 380, "prepTime": 25, "rating": 4.6},
    {"id": "3", "name": "Beef Street Tacos", "description": "Street-style tacos with seasoned ground beef, fresh salsa, and lime crema.", "imageUrl": "https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=600&h=750&fit=crop", "cuisine": "Mexican", "tags": ["Street Food"], "calories": 350, "prepTime": 20, "rating": 4.7},
    {"id": "4", "name": "Pad Thai", "description": "Classic Thai stir-fried noodles with shrimp, peanuts, bean sprouts, and tamarind.", "imageUrl": "https://images.unsplash.com/photo-1559314809-0d155014e29e?w=600&h=750&fit=crop", "cuisine": "Thai", "tags": ["Noodles", "Seafood"], "calories": 450, "prepTime": 25, "rating": 4.5},
    {"id": "5", "name": "Salmon Teriyaki", "description": "Glazed Atlantic salmon with teriyaki sauce, steamed rice, and sesame bok choy.", "imageUrl": "https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=600&h=750&fit=crop", "cuisine": "Japanese", "tags": ["Healthy", "Seafood"], "calories": 390, "prepTime": 30, "rating": 4.9},
    {"id": "6", "name": "Wild Mushroom Risotto", "description": "Creamy arborio rice with wild mushrooms, aged parmesan, and white truffle oil.", "imageUrl": "https://images.unsplash.com/photo-1476124369491-e7addf5db371?w=600&h=750&fit=crop", "cuisine": "Italian", "tags": ["Vegetarian", "Comfort Food"], "calories": 420, "prepTime": 40, "rating": 4.7},
    {"id": "7", "name": "Greek Lamb Gyros", "description": "Marinated lamb with tzatziki, tomatoes, and red onion in warm pita bread.", "imageUrl": "https://images.unsplash.com/photo-1529193591184-b1d58069ecdd?w=600&h=750&fit=crop", "cuisine": "Greek", "tags": ["Mediterranean", "Street Food"], "calories": 480, "prepTime": 30, "rating": 4.6},
    {"id": "8", "name": "Ahi Tuna Poke Bowl", "description": "Fresh ahi tuna, cucumber, edamame, mango over sushi rice with spicy mayo.", "imageUrl": "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600&h=750&fit=crop", "cuisine": "Hawaiian", "tags": ["Healthy", "Seafood"], "calories": 360, "prepTime": 15, "rating": 4.8},
    {"id": "9", "name": "BBQ Pulled Pork", "description": "Slow-smoked pulled pork with house BBQ sauce and coleslaw on a brioche bun.", "imageUrl": "https://images.unsplash.com/photo-1544025162-d76694265947?w=600&h=750&fit=crop", "cuisine": "American", "tags": ["BBQ", "Comfort Food"], "calories": 560, "prepTime": 240, "rating": 4.7},
    {"id": "10", "name": "Tom Kha Soup", "description": "Fragrant Thai coconut soup with galangal, lemongrass, mushrooms, and kaffir lime.", "imageUrl": "https://images.unsplash.com/photo-1604909052743-94e838986d24?w=600&h=750&fit=crop", "cuisine": "Thai", "tags": ["Soup", "Dairy-Free"], "calories": 280, "prepTime": 25, "rating": 4.5},
]


@app.get("/meals")
def get_meals(household_id: str, user_id: str = Depends(_get_user)):
    return _MEALS


@app.post("/swipes")
def record_swipe(req: SwipeRequest, user_id: str = Depends(_get_user)):
    conn = _db()
    try:
        conn.execute(
            """INSERT OR REPLACE INTO swipes (id, user_id, household_id, meal_id, liked)
               VALUES (?, ?, ?, ?, ?)""",
            (str(uuid.uuid4()), user_id, req.household_id, req.meal_id, 1 if req.liked else 0),
        )
        conn.commit()
        return {"ok": True}
    finally:
        conn.close()


@app.get("/matches")
def get_matches(household_id: str, user_id: str = Depends(_get_user)):
    conn = _db()
    try:
        members = conn.execute(
            "SELECT user_id FROM household_members WHERE household_id = ?",
            (household_id,),
        ).fetchall()

        if len(members) < 2:
            return []

        liked_sets: list[set] = []
        for m in members:
            liked = {
                row["meal_id"]
                for row in conn.execute(
                    "SELECT meal_id FROM swipes WHERE user_id = ? AND household_id = ? AND liked = 1",
                    (m["user_id"], household_id),
                ).fetchall()
            }
            liked_sets.append(liked)

        matched = liked_sets[0]
        for s in liked_sets[1:]:
            matched &= s

        return [meal for meal in _MEALS if meal["id"] in matched]
    finally:
        conn.close()


@app.put("/households/{household_id}/preferences")
def update_prefs(
    household_id: str,
    req: PrefsRequest,
    user_id: str = Depends(_get_user),
):
    return {"ok": True}


@app.get("/health")
def health():
    return {"status": "ok", "time": datetime.utcnow().isoformat()}
