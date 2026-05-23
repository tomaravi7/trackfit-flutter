class FoodLog {
  final int? id;
  final String date;
  final String foodName;
  final double quantity;
  final double calories;
  final double protein;
  final double carbs;
  final double fiber;
  final double fat;
  final String mealType;
  final String servingUnit;
  final String? createdAt;

  FoodLog({
    this.id,
    required this.date,
    required this.foodName,
    required this.quantity,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fiber,
    required this.fat,
    required this.mealType,
    required this.servingUnit,
    this.createdAt,
  });

  factory FoodLog.fromJson(Map<String, dynamic> json) {
    return FoodLog(
      id: json['id'] as int?,
      date: json['date'] as String,
      foodName: json['food_name'] ?? json['foodName'] ?? '',
      quantity: (json['quantity'] ?? 0.0) as double,
      calories: (json['calories'] ?? 0.0) as double,
      protein: (json['protein'] ?? 0.0) as double,
      carbs: (json['carbs'] ?? 0.0) as double,
      fiber: (json['fiber'] ?? 0.0) as double,
      fat: (json['fat'] ?? 0.0) as double,
      mealType: json['meal_type'] ?? json['mealType'] ?? 'Breakfast',
      servingUnit: json['serving_unit'] ?? json['servingUnit'] ?? 'g',
      createdAt: json['created_at'] ?? json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'food_name': foodName,
      'quantity': quantity,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fiber': fiber,
      'fat': fat,
      'meal_type': mealType,
      'serving_unit': servingUnit,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
    };
  }
}
