class Meal {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final List<String> tags;
  final int calories;
  final double rating;
  final String cuisine;
  final int prepTime;

  const Meal({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.tags,
    required this.calories,
    required this.rating,
    required this.cuisine,
    required this.prepTime,
  });

  factory Meal.fromJson(Map<String, dynamic> json) => Meal(
        id: json['id']?.toString() ?? '',
        name: json['name'] ?? '',
        description: json['description'] ?? '',
        imageUrl: json['imageUrl'] ?? json['image_url'] ?? '',
        tags: List<String>.from(json['tags'] ?? []),
        calories: json['calories'] ?? 0,
        rating: (json['rating'] ?? 0).toDouble(),
        cuisine: json['cuisine'] ?? '',
        prepTime: json['prepTime'] ?? json['prep_time'] ?? 0,
      );
}
