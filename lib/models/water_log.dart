class WaterLog {
  final int? id;
  final String date;
  final int amount;

  WaterLog({
    this.id,
    required this.date,
    required this.amount,
  });

  factory WaterLog.fromJson(Map<String, dynamic> json) {
    return WaterLog(
      id: json['id'] as int?,
      date: json['date'] as String,
      amount: (json['amount'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'amount': amount,
    };
  }
}
