/// Representa el resultado de una evaluación de fuerza para un ejercicio específico.
class StrengthAssessment {
  final String exerciseName;
  final double? oneRmEstimated; // 1RM estimado en kg
  final String? notes;
  final DateTime date;

  const StrengthAssessment({
    required this.exerciseName,
    this.oneRmEstimated,
    this.notes,
    required this.date,
  });

  StrengthAssessment copyWith({
    String? exerciseName,
    double? oneRmEstimated,
    String? notes,
    DateTime? date,
  }) {
    return StrengthAssessment(
      exerciseName: exerciseName ?? this.exerciseName,
      oneRmEstimated: oneRmEstimated ?? this.oneRmEstimated,
      notes: notes ?? this.notes,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseName': exerciseName,
      'oneRmEstimated': oneRmEstimated,
      'notes': notes,
      'date': date.toIso8601String(),
    };
  }

  factory StrengthAssessment.fromJson(Map<String, dynamic> map) {
    return StrengthAssessment(
      exerciseName: map['exerciseName'] as String? ?? '',
      oneRmEstimated: map['oneRmEstimated'] as double?,
      notes: map['notes'] as String?,
      date: DateTime.parse(
        map['date'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
