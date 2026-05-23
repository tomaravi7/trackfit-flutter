class Goals {
  final double calories;
  final double protein;
  final double carbs;
  final double fiber;
  final double fat;

  Goals({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fiber,
    required this.fat,
  });

  factory Goals.fromJson(Map<String, dynamic> json) {
    return Goals(
      calories: (json['calories'] ?? 2000.0) as double,
      protein: (json['protein'] ?? 130.0) as double,
      carbs: (json['carbs'] ?? 220.0) as double,
      fiber: (json['fiber'] ?? 30.0) as double,
      fat: (json['fat'] ?? 65.0) as double,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fiber': fiber,
      'fat': fat,
    };
  }

  factory Goals.defaultGoals() {
    return Goals(
      calories: 2000.0,
      protein: 130.0,
      carbs: 220.0,
      fiber: 30.0,
      fat: 65.0,
    );
  }
}
