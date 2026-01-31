/// Exercise Effectiveness - Ranking de efectividad por músculo
///
/// Referencias científicas:
/// - Contreras et al. (2015) J Appl Biomech 31(6):452-458
/// - Schoenfeld (2010) J Strength Cond Res 24(10):2857-2872
/// - Estudios EMG específicos por músculo
///
/// Escala: 1-5 estrellas (5 = máxima efectividad EMG/biomecánica)
class ExerciseEffectiveness {
  /// Ranking de efectividad por músculo
  /// Estructura: músculo → ejercicio → estrellas (1-5)
  static const Map<String, Map<String, int>> _effectiveness = {
    'glutes': {
      'hip_thrust': 5,
      'glute_bridge': 4,
      'bulgarian_split_squat': 4,
      'romanian_deadlift': 3,
      'back_squat': 3,
      'leg_press': 2,
    },
    'chest': {
      'barbell_bench_press': 5,
      'incline_dumbbell_press': 5,
      'dips': 4,
      'cable_fly': 3,
      'push_up': 3,
      'machine_press': 3,
    },
    'lats': {
      'weighted_pullup': 5,
      'lat_pulldown': 4,
      'one_arm_dumbbell_row': 4,
      'cable_pulldown': 3,
      'machine_pulldown': 3,
    },
    'back_mid_upper': {
      'barbell_row': 5,
      'chest_supported_row': 4,
      'cable_row': 4,
      't_bar_row': 4,
      'machine_row': 3,
    },
    'shoulders': {
      'overhead_press': 5,
      'dumbbell_press': 5,
      'lateral_raise': 4,
      'cable_lateral_raise': 4,
      'front_raise': 3,
      'machine_press': 3,
    },
    'quads': {
      'back_squat': 5,
      'front_squat': 5,
      'leg_press': 4,
      'hack_squat': 4,
      'leg_extension': 3,
    },
    'hamstrings': {
      'romanian_deadlift': 5,
      'stiff_leg_deadlift': 5,
      'nordic_curl': 5,
      'leg_curl': 4,
      'good_morning': 3,
    },
    'biceps': {
      'barbell_curl': 5,
      'incline_dumbbell_curl': 5,
      'preacher_curl': 4,
      'hammer_curl': 4,
      'cable_curl': 3,
    },
    'triceps': {
      'close_grip_bench': 5,
      'dips': 5,
      'overhead_extension': 4,
      'tricep_pushdown': 4,
      'kickback': 3,
    },
  };

  /// Obtiene la efectividad de un ejercicio para un músculo específico
  ///
  /// Retorna 3 (moderado) si el ejercicio no está catalogado para ese músculo
  static int getEffectiveness(String muscle, String exerciseId) {
    if (!_effectiveness.containsKey(muscle)) {
      return 3; // Default moderado
    }

    return _effectiveness[muscle]![exerciseId] ?? 3;
  }

  /// Ordena una lista de ejercicios por efectividad (mayor a menor)
  ///
  /// Nota: Requiere objetos Exercise con propiedades 'id' y opcionalmente otras
  static List<Map<String, dynamic>> sortByEffectiveness(
    List<Map<String, dynamic>> exercises,
    String muscle,
  ) {
    final sorted = List<Map<String, dynamic>>.from(exercises);
    sorted.sort((a, b) {
      final effectivenessA = getEffectiveness(muscle, a['id'] as String);
      final effectivenessB = getEffectiveness(muscle, b['id'] as String);
      return effectivenessB.compareTo(effectivenessA); // Descendente
    });
    return sorted;
  }

  /// Obtiene los IDs de los mejores ejercicios para un músculo
  ///
  /// [muscle]: Músculo objetivo
  /// [count]: Número de ejercicios a retornar (default: 3)
  ///
  /// Retorna lista ordenada de IDs de ejercicio (mayor a menor efectividad)
  static List<String> getTopExercises(String muscle, [int count = 3]) {
    if (!_effectiveness.containsKey(muscle)) {
      return [];
    }

    final exercises = _effectiveness[muscle]!;
    final sorted = exercises.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(count).map((e) => e.key).toList();
  }

  /// Obtiene la categoría de efectividad según las estrellas
  static String getEffectivenessCategory(int stars) {
    switch (stars) {
      case 5:
        return 'excellent';
      case 4:
        return 'good';
      case 3:
        return 'moderate';
      case 2:
      case 1:
        return 'low';
      default:
        return 'unknown';
    }
  }

  /// Obtiene la descripción de una categoría de efectividad
  static String getCategoryDescription(String category) {
    switch (category) {
      case 'excellent':
        return 'Excelente - Máxima activación EMG y estímulo biomecánico';
      case 'good':
        return 'Bueno - Alta efectividad para hipertrofia';
      case 'moderate':
        return 'Moderado - Efectividad aceptable, puede ser complementario';
      case 'low':
        return 'Bajo - Limitada efectividad, considerar alternativas';
      default:
        return 'Desconocido';
    }
  }

  /// Obtiene todos los ejercicios catalogados para un músculo
  static List<String> getExercisesForMuscle(String muscle) {
    if (!_effectiveness.containsKey(muscle)) {
      return [];
    }
    return _effectiveness[muscle]!.keys.toList();
  }

  /// Obtiene todos los músculos soportados
  static List<String> get supportedMuscles => _effectiveness.keys.toList();

  /// Verifica si un músculo está soportado
  static bool isMuscleSupported(String muscle) =>
      _effectiveness.containsKey(muscle);

  /// Filtra ejercicios con efectividad mínima para un músculo
  ///
  /// [muscle]: Músculo objetivo
  /// [minStars]: Efectividad mínima requerida (1-5)
  static List<String> filterByMinEffectiveness(String muscle, int minStars) {
    if (!_effectiveness.containsKey(muscle)) {
      return [];
    }

    return _effectiveness[muscle]!.entries
        .where((entry) => entry.value >= minStars)
        .map((entry) => entry.key)
        .toList();
  }

  /// Obtiene un mapa de ejercicio → efectividad para un músculo
  static Map<String, int> getEffectivenessMap(String muscle) {
    if (!_effectiveness.containsKey(muscle)) {
      return {};
    }
    return Map<String, int>.from(_effectiveness[muscle]!);
  }

  /// Calcula la efectividad promedio de una lista de ejercicios
  static double calculateAverageEffectiveness(
    String muscle,
    List<String> exerciseIds,
  ) {
    if (exerciseIds.isEmpty) return 0.0;

    final total = exerciseIds.fold<int>(
      0,
      (sum, id) => sum + getEffectiveness(muscle, id),
    );

    return total / exerciseIds.length;
  }
}
