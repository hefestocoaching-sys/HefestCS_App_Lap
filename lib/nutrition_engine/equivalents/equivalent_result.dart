class EquivalentResult {
  /// ID del equivalente aplicado (ej. aoa_bajo_grasa)
  final String equivalentId;

  /// Cantidad en gramos para alcanzar este equivalente
  final double grams;

  /// Si true, requiere revisión manual (validaciones fallaron)
  final bool needsReview;

  /// Macros estimadas para la cantidad en gramos
  final Map<String, double> estimatedMacros; // {kcal, protein, fat, carbs}

  /// Razón si está bloqueado (clínico P0)
  final String? blockageReason;

  const EquivalentResult({
    required this.equivalentId,
    required this.grams,
    required this.needsReview,
    required this.estimatedMacros,
    this.blockageReason,
  });

  /// ¿Está bloqueado por restricción clínica?
  bool get isBlocked => blockageReason != null && blockageReason!.isNotEmpty;

  /// Macro total estimada
  double get totalKcal => estimatedMacros['kcal'] ?? 0.0;
  double get totalProtein => estimatedMacros['protein'] ?? 0.0;
  double get totalFat => estimatedMacros['fat'] ?? 0.0;
  double get totalCarbs => estimatedMacros['carbs'] ?? 0.0;

  Map<String, dynamic> toJson() {
    return {
      'equivalentId': equivalentId,
      'grams': grams,
      'needsReview': needsReview,
      'estimatedMacros': estimatedMacros,
      'blockageReason': blockageReason,
    };
  }

  factory EquivalentResult.fromJson(Map<String, dynamic> json) {
    return EquivalentResult(
      equivalentId: json['equivalentId'] as String,
      grams: (json['grams'] as num?)?.toDouble() ?? 0.0,
      needsReview: json['needsReview'] as bool? ?? false,
      estimatedMacros: Map<String, double>.from(
        json['estimatedMacros'] as Map? ?? {},
      ),
      blockageReason: json['blockageReason'] as String?,
    );
  }

  @override
  String toString() =>
      'EquivalentResult('
      'id=$equivalentId, '
      'grams=$grams, '
      'needsReview=$needsReview, '
      'blocked=$isBlocked'
      ')';
}
