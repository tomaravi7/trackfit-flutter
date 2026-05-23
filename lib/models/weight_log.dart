class WeightLog {
  final int? id;
  final String date;
  final double weight;
  final double? bodyFat;

  WeightLog({
    this.id,
    required this.date,
    required this.weight,
    this.bodyFat,
  });

  factory WeightLog.fromJson(Map<String, dynamic> json) {
    return WeightLog(
      id: json['id'] as int?,
      date: json['date'] as String,
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      bodyFat: json['body_fat'] != null ? (json['body_fat'] as num).toDouble() : (json['bodyFat'] != null ? (json['bodyFat'] as num).toDouble() : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'weight': weight,
      'body_fat': bodyFat,
    };
  }
}
