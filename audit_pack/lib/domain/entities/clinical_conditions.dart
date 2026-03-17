/// ═══════════════════════════════════════════════════════════════════════════
/// Condiciones clínicas relevantes para nutrición (P0)
/// ═══════════════════════════════════════════════════════════════════════════
/// SSOT: 6 condiciones principales (evidencia EBN)
/// Cada una es un booleano (presente/ausente)
class ClinicalConditions {
  final bool diabetes; // T1DM, T2DM, LADA (restringe azúcares simples)
  final bool renalDisease; // CKD (restringe potasio, fósforo, sodio)
  final bool giDisorders; // GERD, úlcera, IBD (antiinflamatorio)
  final bool
  thyroidDisorders; // Hipotiroidismo, hipertiroidismo (yodo, mineral)
  final bool hypertension; // HTA (restringe sodio, potasio, magnesio)
  final bool dyslipidemia; // Colesterol elevado (restringe grasas saturadas)

  const ClinicalConditions({
    this.diabetes = false,
    this.renalDisease = false,
    this.giDisorders = false,
    this.thyroidDisorders = false,
    this.hypertension = false,
    this.dyslipidemia = false,
  });

  /// Defaults seguros (sin condiciones diagnosticadas)
  factory ClinicalConditions.defaults() {
    return const ClinicalConditions();
  }

  /// Deserialización segura desde Map
  factory ClinicalConditions.fromMap(Map<String, dynamic> map) {
    return ClinicalConditions(
      diabetes: map['diabetes'] as bool? ?? false,
      renalDisease: map['renalDisease'] as bool? ?? false,
      giDisorders: map['giDisorders'] as bool? ?? false,
      thyroidDisorders: map['thyroidDisorders'] as bool? ?? false,
      hypertension: map['hypertension'] as bool? ?? false,
      dyslipidemia: map['dyslipidemia'] as bool? ?? false,
    );
  }

  /// Serialización segura a Map
  Map<String, dynamic> toMap() {
    return {
      'diabetes': diabetes,
      'renalDisease': renalDisease,
      'giDisorders': giDisorders,
      'thyroidDisorders': thyroidDisorders,
      'hypertension': hypertension,
      'dyslipidemia': dyslipidemia,
    };
  }

  ClinicalConditions copyWith({
    bool? diabetes,
    bool? renalDisease,
    bool? giDisorders,
    bool? thyroidDisorders,
    bool? hypertension,
    bool? dyslipidemia,
  }) {
    return ClinicalConditions(
      diabetes: diabetes ?? this.diabetes,
      renalDisease: renalDisease ?? this.renalDisease,
      giDisorders: giDisorders ?? this.giDisorders,
      thyroidDisorders: thyroidDisorders ?? this.thyroidDisorders,
      hypertension: hypertension ?? this.hypertension,
      dyslipidemia: dyslipidemia ?? this.dyslipidemia,
    );
  }

  @override
  String toString() {
    return 'ClinicalConditions(diabetes: $diabetes, renalDisease: $renalDisease, '
        'giDisorders: $giDisorders, thyroidDisorders: $thyroidDisorders, '
        'hypertension: $hypertension, dyslipidemia: $dyslipidemia)';
  }
}
