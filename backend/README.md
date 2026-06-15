# Mixed Plate — Backend

FastAPI backend with SQLite, session-based auth, and household invite codes.

## Setup

```bash
pip install -r requirements.txt
uvicorn main:app --port 3001 --reload
```

## Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | /auth/signup | No | Create account → returns user_id, access_token |
| POST | /auth/login | No | Sign in → returns user_id, access_token |
| POST | /auth/logout | Yes | Invalidate session token |
| POST | /households | Yes | Create household → returns id, name, code |
| POST | /households/join | Yes | Join with invite code |
| POST | /households/invite-code | Yes | Get current household's code |
| GET | /meals?household_id= | Yes | List meals |
| POST | /swipes | Yes | Record a swipe |
| GET | /matches?household_id= | Yes | Get mutual matches |
| GET | /health | No | Health check |

Auth: pass `Authorization: Bearer <access_token>` header on all protected routes.
