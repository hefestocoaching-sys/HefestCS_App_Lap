/// Calificación para una prueba de movilidad.
enum MobilityTestRating { excellent, good, average, poor, veryPoor }

/// Representa el resultado de una evaluación de movilidad específica.
class MobilityAssessment {
  final String testName;
  final MobilityTestRating rating;
  final double? score;
  final String? notes;
  final DateTime date;

  const MobilityAssessment({
    required this.testName,
    required this.rating,
    this.score,
    this.notes,
    required this.date,
  });

  MobilityAssessment copyWith({
    String? testName,
    MobilityTestRating? rating,
    double? score,
    String? notes,
    DateTime? date,
  }) {
    return MobilityAssessment(
      testName: testName ?? this.testName,
      rating: rating ?? this.rating,
      score: score ?? this.score,
      notes: notes ?? this.notes,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'testName': testName,
      'rating': rating.name,
      'score': score,
      'notes': notes,
      'date': date.toIso8601String(),
    };
  }

  factory MobilityAssessment.fromJson(Map<String, dynamic> map) {
    return MobilityAssessment(
      testName: map['testName'] as String? ?? '',
      rating: MobilityTestRating.values.firstWhere(
        (e) => e.name == map['rating'],
        orElse: () => MobilityTestRating.average,
      ),
      score: map['score'] as double?,
      notes: map['notes'] as String?,
      date: DateTime.parse(
        map['date'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
