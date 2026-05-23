class WorkoutLog {
  final int? id;
  final String date;
  final String exerciseName;
  final double weight;
  final int reps;
  final int setNumber;

  WorkoutLog({
    this.id,
    required this.date,
    required this.exerciseName,
    required this.weight,
    required this.reps,
    required this.setNumber,
  });

  factory WorkoutLog.fromJson(Map<String, dynamic> json) {
    return WorkoutLog(
      id: json['id'] as int?,
      date: json['date'] as String,
      exerciseName: json['exercise_name'] ?? json['exerciseName'] ?? '',
      weight: (json['weight'] ?? 0.0) as double,
      reps: (json['reps'] ?? 0) as int,
      setNumber: (json['set_number'] ?? json['setNumber'] ?? 1) as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'exercise_name': exerciseName,
      'weight': weight,
      'reps': reps,
      'set_number': setNumber,
    };
  }
}
