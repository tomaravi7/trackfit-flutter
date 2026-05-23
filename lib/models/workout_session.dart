class WorkoutSession {
  final int? id;
  final String date;
  final int duration; // in seconds
  final double energy; // calories burned
  final String notes;

  WorkoutSession({
    this.id,
    required this.date,
    required this.duration,
    required this.energy,
    required this.notes,
  });

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    return WorkoutSession(
      id: json['id'] as int?,
      date: json['date'] as String,
      duration: (json['duration'] ?? 0) as int,
      energy: (json['energy'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'duration': duration,
      'energy': energy,
      'notes': notes,
    };
  }
}
