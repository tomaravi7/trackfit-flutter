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
      calories: (json['calories'] as num?)?.toDouble() ?? 2000.0,
      protein: (json['protein'] as num?)?.toDouble() ?? 130.0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 220.0,
      fiber: (json['fiber'] as num?)?.toDouble() ?? 30.0,
      fat: (json['fat'] as num?)?.toDouble() ?? 65.0,
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
