/// Recomendación de fórmula TMB para un cliente específico.
///
/// Contiene información sobre la fórmula recomendada, el razonamiento
/// detrás de la recomendación, y consideraciones alternativas.
class TMBRecommendation {
  /// Clave de la fórmula recomendada (ej: 'Mifflin-St. Jeor', 'Tinsley', etc.)
  final String formulaKey;

  /// Título de la recomendación
  final String title;

  /// Resumen del perfil del cliente considerado para la recomendación
  final String clientProfileSummary;

  /// Razonamiento detrás de la recomendación de esta fórmula
  final String reasoning;

  /// Consideraciones alternativas o información adicional
  final String? alternativeConsiderations;

  const TMBRecommendation({
    required this.formulaKey,
    required this.title,
    required this.clientProfileSummary,
    required this.reasoning,
    this.alternativeConsiderations,
  });

  @override
  String toString() {
    return 'TMBRecommendation('
        'formulaKey: $formulaKey, '
        'title: $title, '
        'clientProfileSummary: $clientProfileSummary, '
        'reasoning: $reasoning, '
        'alternativeConsiderations: $alternativeConsiderations'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TMBRecommendation &&
        other.formulaKey == formulaKey &&
        other.title == title &&
        other.clientProfileSummary == clientProfileSummary &&
        other.reasoning == reasoning &&
        other.alternativeConsiderations == alternativeConsiderations;
  }

  @override
  int get hashCode {
    return formulaKey.hashCode ^
        title.hashCode ^
        clientProfileSummary.hashCode ^
        reasoning.hashCode ^
        alternativeConsiderations.hashCode;
  }
}
