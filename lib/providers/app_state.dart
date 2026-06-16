import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meal.dart';
import '../services/api_service.dart';

class AppState extends ChangeNotifier {
  final _api = ApiService();
  static const _storage = FlutterSecureStorage(
    webOptions: WebOptions(dbName: 'mixed_plate', publicKey: 'mixed_plate_key'),
  );

  // ── Boot state ─────────────────────────────────────────────────────────────
  bool isInitialized = false;
  bool seenWelcome = false;

  // ── Auth ───────────────────────────────────────────────────────────────────
  String? userId;
  String? accessToken;
  String? userEmail;
  String? userName;
  bool get isAuthenticated => accessToken != null;

  // ── Household ──────────────────────────────────────────────────────────────
  String? householdId;
  String? householdCode;
  String? householdName;

  // ── Loading / error ────────────────────────────────────────────────────────
  bool isLoading = false;
  String? error;

  // ── Preferences ────────────────────────────────────────────────────────────
  Map<String, bool> dietaryPreferences = {
    'vegetarian': false,
    'vegan': false,
    'gluten_free': false,
    'dairy_free': false,
    'nut_free': false,
    'halal': false,
  };
  List<String> favoriteCuisines = [];
  String customAllergies = '';
  String dietaryType = 'none';

  // ── Swipe data ─────────────────────────────────────────────────────────────
  List<Meal> meals = [];
  List<Meal> likedMeals = [];
  List<Meal> matches = [];
  int currentMealIndex = 0;

  bool get hasHousehold => householdId != null;
  bool get swipingDone => meals.isNotEmpty && currentMealIndex >= meals.length;
  Meal? get currentMeal =>
      currentMealIndex < meals.length ? meals[currentMealIndex] : null;

  // ── Init ───────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    seenWelcome = prefs.getBool('seen_welcome') ?? false;
    customAllergies = prefs.getString('custom_allergies') ?? '';
    dietaryType = prefs.getString('dietary_type') ?? 'none';

    // Try to restore auth session
    final token = await _storage.read(key: 'access_token');
    final uid = await _storage.read(key: 'user_id');
    final email = await _storage.read(key: 'user_email');
    final name = await _storage.read(key: 'user_name');

    if (token != null && uid != null) {
      accessToken = token;
      userId = uid;
      userEmail = email;
      userName = name;
      _api.setToken(token);

      // Restore household
      householdId = prefs.getString('household_id');
      householdCode = prefs.getString('household_code');
      householdName = prefs.getString('household_name');

      if (householdId != null) {
        await Future.wait([_loadMeals(), _loadMatches()]);
      }
    }

    isInitialized = true;
    notifyListeners();
  }

  void markSeenWelcome() {
    seenWelcome = true;
    SharedPreferences.getInstance()
        .then((p) => p.setBool('seen_welcome', true));
    notifyListeners();
  }

  // ── Auth methods ───────────────────────────────────────────────────────────

  Future<void> signup(String name, String email, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final data = await _api.signup(name, email, password);
      await _applyAuth(data);
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final data = await _api.login(email, password);
      await _applyAuth(data);
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _api.serverLogout();
    await _storage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('household_id');
    await prefs.remove('household_code');
    await prefs.remove('household_name');

    accessToken = null;
    userId = null;
    userEmail = null;
    userName = null;
    householdId = null;
    householdCode = null;
    householdName = null;
    meals = [];
    likedMeals = [];
    matches = [];
    currentMealIndex = 0;
    _api.setToken(null);
    notifyListeners();
  }

  Future<void> _applyAuth(Map<String, dynamic> data) async {
    // The backend returns the profile nested under `user`; tolerate a flat
    // shape too for backward compatibility.
    final user = (data['user'] as Map<String, dynamic>?) ?? const {};
    final uid = (data['user_id'] ?? user['id']) as String;
    final token = data['access_token'] as String;
    final email =
        (data['email'] ?? user['email']) as String? ?? userEmail ?? '';
    final name = (data['name'] ?? user['name']) as String? ?? userName;
    accessToken = token;
    userId = uid;
    userEmail = email;
    userName = name;
    _api.setToken(token);
    await _storage.write(key: 'access_token', value: token);
    await _storage.write(key: 'user_id', value: uid);
    await _storage.write(key: 'user_email', value: email);
    if (name != null) await _storage.write(key: 'user_name', value: name);

    // Restore household from prefs if it exists
    final prefs = await SharedPreferences.getInstance();
    householdId = prefs.getString('household_id');
    householdCode = prefs.getString('household_code');
    householdName = prefs.getString('household_name');
    if (householdId != null) {
      await Future.wait([_loadMeals(), _loadMatches()]);
    }
  }

  // ── Household ──────────────────────────────────────────────────────────────

  Future<void> createHousehold(String name) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final data = await _api.createHousehold(name);
      householdId = data['id']?.toString();
      householdCode = data['code']?.toString();
      householdName = data['name']?.toString() ?? name;
      await _persistHousehold();
      await Future.wait([_loadMeals(), _loadMatches()]);
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> joinHousehold(String code) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final data = await _api.joinHousehold(code);
      householdId = data['id']?.toString();
      householdCode = data['code']?.toString();
      householdName = data['name']?.toString() ?? 'Our Household';
      await _persistHousehold();
      await Future.wait([_loadMeals(), _loadMatches()]);
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> leaveHousehold() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('household_id');
    await prefs.remove('household_code');
    await prefs.remove('household_name');
    householdId = null;
    householdCode = null;
    householdName = null;
    meals = [];
    likedMeals = [];
    matches = [];
    currentMealIndex = 0;
    notifyListeners();
  }

  Future<void> loadMeals() => _loadMeals();

  Future<void> _loadMeals() async {
    if (householdId == null) return;
    meals = await _api.getMeals(householdId!);
    currentMealIndex = 0;
    likedMeals = [];
    notifyListeners();
  }

  Future<void> _loadMatches() async {
    if (householdId == null) return;
    matches = await _api.getMatches(householdId!);
    notifyListeners();
  }

  Future<void> swipe(bool liked) async {
    final meal = currentMeal;
    if (meal == null) return;
    if (liked) likedMeals.add(meal);
    await _api.recordSwipe(householdId ?? '', meal.id, liked);
    currentMealIndex++;
    notifyListeners();
    if (swipingDone) await _loadMatches();
  }

  // ── Preferences ────────────────────────────────────────────────────────────

  Future<void> savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_allergies', customAllergies);
    await prefs.setString('dietary_type', dietaryType);
    if (householdId != null) {
      await _api.updatePreferences(householdId!, {
        'dietary': dietaryPreferences,
        'cuisines': favoriteCuisines,
        'custom_allergies': customAllergies,
        'dietary_type': dietaryType,
      });
    }
    notifyListeners();
  }

  void updateDietaryPref(String key, bool value) {
    dietaryPreferences[key] = value;
    notifyListeners();
  }

  void setDietaryType(String type) {
    dietaryType = type;
    notifyListeners();
  }

  void setCustomAllergies(String text) {
    customAllergies = text;
  }

  void toggleCuisine(String cuisine) {
    if (favoriteCuisines.contains(cuisine)) {
      favoriteCuisines.remove(cuisine);
    } else {
      favoriteCuisines.add(cuisine);
    }
    notifyListeners();
  }

  // ── Persistence ────────────────────────────────────────────────────────────

  Future<void> _persistHousehold() async {
    final prefs = await SharedPreferences.getInstance();
    if (householdId != null) await prefs.setString('household_id', householdId!);
    if (householdCode != null) await prefs.setString('household_code', householdCode!);
    if (householdName != null) await prefs.setString('household_name', householdName!);
  }
}
