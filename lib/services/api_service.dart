import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/meal.dart';

class ApiService {
  static const _base = 'http://localhost:3001';
  static const _timeout = Duration(seconds: 5);

  Future<Map<String, dynamic>> createHousehold(String name) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base/households'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'name': name}),
          )
          .timeout(_timeout);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return {
      'id': 'local-${DateTime.now().millisecondsSinceEpoch}',
      'code': _randomCode(),
      'name': name,
    };
  }

  Future<Map<String, dynamic>> joinHousehold(String code) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base/households/join'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'code': code}),
          )
          .timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return {
      'id': 'local-joined-${DateTime.now().millisecondsSinceEpoch}',
      'code': code,
      'name': 'Our Household',
    };
  }

  Future<List<Meal>> getMeals(String householdId) async {
    try {
      final res = await http
          .get(Uri.parse('$_base/meals?household_id=$householdId'))
          .timeout(_timeout);
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list.map((j) => Meal.fromJson(j as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return _mockMeals;
  }

  Future<void> recordSwipe(String householdId, String mealId, bool liked) async {
    try {
      await http
          .post(
            Uri.parse('$_base/swipes'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'household_id': householdId,
              'meal_id': mealId,
              'liked': liked,
            }),
          )
          .timeout(_timeout);
    } catch (_) {}
  }

  Future<List<Meal>> getMatches(String householdId) async {
    try {
      final res = await http
          .get(Uri.parse('$_base/matches?household_id=$householdId'))
          .timeout(_timeout);
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list.map((j) => Meal.fromJson(j as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return _mockMeals.take(3).toList();
  }

  Future<void> updatePreferences(
      String householdId, Map<String, dynamic> prefs) async {
    try {
      await http
          .put(
            Uri.parse('$_base/households/$householdId/preferences'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(prefs),
          )
          .timeout(_timeout);
    } catch (_) {}
  }

  String _randomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final ms = DateTime.now().millisecondsSinceEpoch;
    return List.generate(6, (i) => chars[(ms >> (i * 4)) % chars.length]).join();
  }

  static final List<Meal> _mockMeals = [
    const Meal(
      id: '1',
      name: 'Chicken Tikka Masala',
      description:
          'Tender chicken in a creamy tomato-based curry sauce with aromatic Indian spices.',
      imageUrl:
          'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=600&h=750&fit=crop',
      tags: ['Indian', 'Spicy', 'Gluten-Free'],
      calories: 420,
      rating: 4.8,
      cuisine: 'Indian',
      prepTime: 35,
    ),
    const Meal(
      id: '2',
      name: 'Margherita Pizza',
      description:
          'Classic Neapolitan pizza with San Marzano tomatoes, fresh mozzarella, and basil.',
      imageUrl:
          'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=600&h=750&fit=crop',
      tags: ['Italian', 'Vegetarian'],
      calories: 380,
      rating: 4.6,
      cuisine: 'Italian',
      prepTime: 25,
    ),
    const Meal(
      id: '3',
      name: 'Beef Street Tacos',
      description:
          'Street-style tacos with seasoned ground beef, fresh salsa, and lime crema.',
      imageUrl:
          'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=600&h=750&fit=crop',
      tags: ['Mexican', 'Street Food'],
      calories: 350,
      rating: 4.7,
      cuisine: 'Mexican',
      prepTime: 20,
    ),
    const Meal(
      id: '4',
      name: 'Pad Thai',
      description:
          'Classic Thai stir-fried noodles with shrimp, peanuts, bean sprouts, and tamarind.',
      imageUrl:
          'https://images.unsplash.com/photo-1559314809-0d155014e29e?w=600&h=750&fit=crop',
      tags: ['Thai', 'Noodles', 'Seafood'],
      calories: 450,
      rating: 4.5,
      cuisine: 'Thai',
      prepTime: 25,
    ),
    const Meal(
      id: '5',
      name: 'Salmon Teriyaki',
      description:
          'Glazed Atlantic salmon with teriyaki sauce, steamed rice, and sesame bok choy.',
      imageUrl:
          'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=600&h=750&fit=crop',
      tags: ['Japanese', 'Healthy', 'Seafood'],
      calories: 390,
      rating: 4.9,
      cuisine: 'Japanese',
      prepTime: 30,
    ),
    const Meal(
      id: '6',
      name: 'Wild Mushroom Risotto',
      description:
          'Creamy arborio rice with wild mushrooms, aged parmesan, and white truffle oil.',
      imageUrl:
          'https://images.unsplash.com/photo-1476124369491-e7addf5db371?w=600&h=750&fit=crop',
      tags: ['Italian', 'Vegetarian', 'Comfort Food'],
      calories: 420,
      rating: 4.7,
      cuisine: 'Italian',
      prepTime: 40,
    ),
    const Meal(
      id: '7',
      name: 'Greek Lamb Gyros',
      description:
          'Marinated lamb with tzatziki, tomatoes, and red onion in warm pita bread.',
      imageUrl:
          'https://images.unsplash.com/photo-1529193591184-b1d58069ecdd?w=600&h=750&fit=crop',
      tags: ['Greek', 'Mediterranean', 'Street Food'],
      calories: 480,
      rating: 4.6,
      cuisine: 'Greek',
      prepTime: 30,
    ),
    const Meal(
      id: '8',
      name: 'Ahi Tuna Poke Bowl',
      description:
          'Fresh ahi tuna, cucumber, edamame, mango over sushi rice with spicy mayo.',
      imageUrl:
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600&h=750&fit=crop',
      tags: ['Hawaiian', 'Healthy', 'Seafood'],
      calories: 360,
      rating: 4.8,
      cuisine: 'Hawaiian',
      prepTime: 15,
    ),
    const Meal(
      id: '9',
      name: 'BBQ Pulled Pork',
      description:
          'Slow-smoked pulled pork with house BBQ sauce and coleslaw on a brioche bun.',
      imageUrl:
          'https://images.unsplash.com/photo-1544025162-d76694265947?w=600&h=750&fit=crop',
      tags: ['American', 'BBQ', 'Comfort Food'],
      calories: 560,
      rating: 4.7,
      cuisine: 'American',
      prepTime: 240,
    ),
    const Meal(
      id: '10',
      name: 'Tom Kha Soup',
      description:
          'Fragrant Thai coconut soup with galangal, lemongrass, mushrooms, and kaffir lime.',
      imageUrl:
          'https://images.unsplash.com/photo-1604909052743-94e838986d24?w=600&h=750&fit=crop',
      tags: ['Thai', 'Soup', 'Dairy-Free'],
      calories: 280,
      rating: 4.5,
      cuisine: 'Thai',
      prepTime: 25,
    ),
  ];
}
