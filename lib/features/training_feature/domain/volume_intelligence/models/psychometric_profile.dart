enum SemanticClassification { veryHigh, high, moderate, low }

class PsychometricProfile {
  final double globalScore;
  final Map<String, double> subscaleScores;
  final SemanticClassification semanticClassification;
  final DateTime evaluatedAt;

  const PsychometricProfile({
    required this.globalScore,
    required this.subscaleScores,
    required this.semanticClassification,
    required this.evaluatedAt,
  });

  @override
  String toString() =>
      'PsychometricProfile(score: $globalScore, class: $semanticClassification)';
}
