import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meal.dart';
import '../services/api_service.dart';

class AppState extends ChangeNotifier {
  final _api = ApiService();

  String? householdId;
  String? householdCode;
  String? householdName;
  bool isLoading = false;
  String? error;

  Map<String, bool> dietaryPreferences = {
    'vegetarian': false,
    'vegan': false,
    'gluten_free': false,
    'dairy_free': false,
    'nut_free': false,
    'halal': false,
  };

  List<String> favoriteCuisines = [];

  List<Meal> meals = [];
  List<Meal> likedMeals = [];
  List<Meal> matches = [];
  int currentMealIndex = 0;

  bool get hasHousehold => householdId != null;
  bool get swipingDone => meals.isNotEmpty && currentMealIndex >= meals.length;
  Meal? get currentMeal =>
      currentMealIndex < meals.length ? meals[currentMealIndex] : null;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    householdId = prefs.getString('household_id');
    householdCode = prefs.getString('household_code');
    householdName = prefs.getString('household_name');

    if (householdId != null) {
      await _loadAll();
    }
    notifyListeners();
  }

  Future<void> _loadAll() async {
    await Future.wait([loadMeals(), loadMatches()]);
  }

  Future<void> createHousehold(String name) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final data = await _api.createHousehold(name);
      householdId = data['id']?.toString();
      householdCode = data['code']?.toString();
      householdName = name;
      await _persist();
      await _loadAll();
    } catch (e) {
      error = e.toString();
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
      final data = await _api.joinHousehold(code.toUpperCase());
      householdId = data['id']?.toString();
      householdCode = data['code']?.toString();
      householdName = data['name']?.toString() ?? 'Our Household';
      await _persist();
      await _loadAll();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMeals() async {
    if (householdId == null) return;
    meals = await _api.getMeals(householdId!);
    currentMealIndex = 0;
    likedMeals = [];
    notifyListeners();
  }

  Future<void> swipe(bool liked) async {
    final meal = currentMeal;
    if (meal == null) return;
    if (liked) likedMeals.add(meal);
    await _api.recordSwipe(householdId ?? '', meal.id, liked);
    currentMealIndex++;
    notifyListeners();
    if (swipingDone) await loadMatches();
  }

  Future<void> loadMatches() async {
    if (householdId == null) return;
    matches = await _api.getMatches(householdId!);
    notifyListeners();
  }

  Future<void> savePreferences() async {
    if (householdId == null) return;
    await _api.updatePreferences(householdId!, {
      'dietary': dietaryPreferences,
      'cuisines': favoriteCuisines,
    });
    notifyListeners();
  }

  void updateDietaryPref(String key, bool value) {
    dietaryPreferences[key] = value;
    notifyListeners();
  }

  void toggleCuisine(String cuisine) {
    if (favoriteCuisines.contains(cuisine)) {
      favoriteCuisines.remove(cuisine);
    } else {
      favoriteCuisines.add(cuisine);
    }
    notifyListeners();
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

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (householdId != null) await prefs.setString('household_id', householdId!);
    if (householdCode != null) await prefs.setString('household_code', householdCode!);
    if (householdName != null) await prefs.setString('household_name', householdName!);
  }
}
