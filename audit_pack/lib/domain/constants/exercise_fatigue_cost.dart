/// Exercise Fatigue Cost - Catálogo de costo de fatiga por ejercicio
///
/// Referencias científicas:
/// - Helms et al. (2015) J Int Soc Sports Nutr 12:1
/// - Nuckols (2020) Stronger By Science Fatigue Management
/// - Schoenfeld (2010) J Strength Cond Res 24(10):2857-2872
///
/// Factor 1.0 = baseline (moderado)
/// >1.0 = más fatigante
/// <1.0 = menos fatigante
class ExerciseFatigueCost {
  /// Catálogo de costo de fatiga por ejercicio
  static const Map<String, double> _fatigueCosts = {
    // ALTO COSTO AXIAL (1.4-1.6)
    'conventional_deadlift': 1.6,
    'sumo_deadlift': 1.5,
    'back_squat': 1.5,
    'front_squat': 1.4,
    'bulgarian_split_squat': 1.3,
    'overhead_squat': 1.5,

    // ALTO COSTO NEURAL (1.2-1.4)
    'barbell_bench_press': 1.3,
    'overhead_press': 1.3,
    'weighted_pullup': 1.3,
    'weighted_dip': 1.3,
    'barbell_row': 1.2,
    'pendlay_row': 1.3,

    // MODERADO-ALTO (1.1-1.2)
    'hack_squat': 1.1,
    'romanian_deadlift': 1.1,
    'stiff_leg_deadlift': 1.2,
    'good_morning': 1.2,
    't_bar_row': 1.1,

    // MODERADO (0.9-1.1)
    'incline_dumbbell_press': 1.0,
    'dumbbell_row': 1.0,
    'cable_row': 1.0,
    'lat_pulldown': 0.9,
    'leg_press': 1.0,
    'chest_supported_row': 0.9,
    'machine_press': 0.9,

    // BAJO COSTO - AISLADOS (0.6-0.8)
    'bicep_curl': 0.7,
    'hammer_curl': 0.7,
    'preacher_curl': 0.7,
    'tricep_extension': 0.7,
    'tricep_pushdown': 0.7,
    'lateral_raise': 0.6,
    'front_raise': 0.6,
    'rear_delt_fly': 0.6,
    'leg_extension': 0.8,
    'leg_curl': 0.8,
    'calf_raise': 0.6,
    'cable_fly': 0.7,
    'pec_deck': 0.7,
    'face_pull': 0.7,

    // GLÚTEOS ESPECÍFICOS
    'hip_thrust': 1.0,
    'glute_bridge': 0.8,
    'cable_kickback': 0.7,
    'hip_abduction': 0.6,
  };

  /// Obtiene el costo de fatiga de un ejercicio
  /// Retorna 1.0 (moderado) si el ejercicio no está en el catálogo
  static double getCost(String exerciseId) {
    return _fatigueCosts[exerciseId] ?? 1.0;
  }

  /// Obtiene la categoría de costo de fatiga
  static String getCostCategory(String exerciseId) {
    final cost = getCost(exerciseId);
    if (cost >= 1.4) return 'very_high';
    if (cost >= 1.2) return 'high';
    if (cost >= 0.9) return 'moderate';
    return 'low';
  }

  /// Obtiene la descripción de una categoría de costo
  static String getCostCategoryDescription(String category) {
    switch (category) {
      case 'very_high':
        return 'Muy alto costo - ejercicios axiales/neuralmente demandantes';
      case 'high':
        return 'Alto costo - ejercicios compuestos pesados';
      case 'moderate':
        return 'Costo moderado - ejercicios compuestos ligeros/máquinas';
      case 'low':
        return 'Bajo costo - ejercicios de aislamiento';
      default:
        return 'Categoría desconocida';
    }
  }

  /// Calcula el costo total de fatiga de una lista de ejercicios
  static double calculateTotalCost(List<String> exerciseIds) {
    if (exerciseIds.isEmpty) return 0.0;
    return exerciseIds.fold(0.0, (sum, id) => sum + getCost(id));
  }

  /// Calcula el costo promedio de fatiga de una lista de ejercicios
  static double calculateAverageCost(List<String> exerciseIds) {
    if (exerciseIds.isEmpty) return 1.0;
    final total = calculateTotalCost(exerciseIds);
    return total / exerciseIds.length;
  }

  /// Obtiene el factor de ajuste de MRV basado en el costo promedio
  ///
  /// - Costo promedio >= 1.4: -20% MRV (factor 0.80)
  /// - Costo promedio >= 1.2: -10% MRV (factor 0.90)
  /// - Costo promedio <= 0.8: +10% MRV (factor 1.10)
  /// - Otros casos: sin ajuste (factor 1.0)
  static double getMRVAdjustmentFactor(List<String> exerciseIds) {
    final avgCost = calculateAverageCost(exerciseIds);

    if (avgCost >= 1.4) return 0.80; // -20% MRV
    if (avgCost >= 1.2) return 0.90; // -10% MRV
    if (avgCost <= 0.8) return 1.10; // +10% MRV
    return 1.0; // Sin ajuste
  }

  /// Filtra ejercicios que no excedan un costo máximo
  static List<String> filterByMaxCost(
    List<String> exerciseIds,
    double maxCost,
  ) {
    return exerciseIds.where((id) => getCost(id) <= maxCost).toList();
  }

  /// Ordena ejercicios por costo de fatiga
  static List<String> sortByCost(List<String> exerciseIds, bool descending) {
    final sorted = List<String>.from(exerciseIds);
    sorted.sort((a, b) {
      final costA = getCost(a);
      final costB = getCost(b);
      return descending ? costB.compareTo(costA) : costA.compareTo(costB);
    });
    return sorted;
  }

  /// Obtiene ejercicios de bajo costo (< 0.9)
  static List<String> getLowCostExercises() {
    return _fatigueCosts.entries
        .where((entry) => entry.value < 0.9)
        .map((entry) => entry.key)
        .toList();
  }

  /// Obtiene ejercicios de alto costo (>= 1.2)
  static List<String> getHighCostExercises() {
    return _fatigueCosts.entries
        .where((entry) => entry.value >= 1.2)
        .map((entry) => entry.key)
        .toList();
  }

  /// Valida si la selección de ejercicios es apropiada para el nivel
  ///
  /// Retorna null si es válida, o un mensaje de advertencia si no lo es
  static String? validateForLevel(List<String> exerciseIds, String level) {
    final avgCost = calculateAverageCost(exerciseIds);

    if (level == 'beginner' && avgCost > 1.2) {
      return 'Advertencia: El costo promedio de fatiga ($avgCost) es alto '
          'para nivel principiante. Considera incluir más ejercicios de bajo costo.';
    }

    return null;
  }

  /// Obtiene todos los ejercicios del catálogo
  static List<String> get allExercises => _fatigueCosts.keys.toList();

  /// Verifica si un ejercicio está en el catálogo
  static bool isInCatalog(String exerciseId) =>
      _fatigueCosts.containsKey(exerciseId);
}
