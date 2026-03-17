/// Evalúa la calidad de un patrón de movimiento fundamental.
class MovementPatternAssessment {
  final String patternName; // ej: "Sentadilla", "Bisagra de Cadera"
  final int score; // ej: 1-5
  final String? notes;
  final String? videoUrl;
  final DateTime date;

  const MovementPatternAssessment({
    required this.patternName,
    required this.score,
    this.notes,
    this.videoUrl,
    required this.date,
  });

  MovementPatternAssessment copyWith({
    String? patternName,
    int? score,
    String? notes,
    String? videoUrl,
    DateTime? date,
  }) {
    return MovementPatternAssessment(
      patternName: patternName ?? this.patternName,
      score: score ?? this.score,
      notes: notes ?? this.notes,
      videoUrl: videoUrl ?? this.videoUrl,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patternName': patternName,
      'score': score,
      'notes': notes,
      'videoUrl': videoUrl,
      'date': date.toIso8601String(),
    };
  }

  factory MovementPatternAssessment.fromJson(Map<String, dynamic> map) {
    return MovementPatternAssessment(
      patternName: map['patternName'] as String? ?? '',
      score: map['score'] as int? ?? 0,
      notes: map['notes'] as String?,
      videoUrl: map['videoUrl'] as String?,
      date: DateTime.parse(
        map['date'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
