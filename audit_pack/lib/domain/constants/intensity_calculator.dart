/// Intensity Calculator - Conversión %1RM ↔ Repeticiones
///
/// Referencias científicas:
/// - Epley (1985) Boyd Epley Workout
/// - Brzycki (1993) JOPERD 64(1):88-90
/// - NSCA (2024) Testing and Evaluation
///
/// Fórmula Epley: 1RM estimado = peso × (1 + reps/30)
class IntensityCalculator {
  /// Tabla pre-calculada de repeticiones → %1RM
  static const Map<int, double> repsToPercent = {
    1: 1.00, // 100%
    2: 0.95, // 95%
    3: 0.93, // 93%
    4: 0.90, // 90%
    5: 0.87, // 87%
    6: 0.85, // 85%
    7: 0.83, // 83%
    8: 0.80, // 80%
    9: 0.77, // 77%
    10: 0.75, // 75%
    12: 0.70, // 70%
    15: 0.65, // 65%
    20: 0.60, // 60%
  };

  /// Calcula el porcentaje de 1RM basado en peso y repeticiones realizadas
  ///
  /// [weight]: Peso levantado
  /// [reps]: Repeticiones completadas
  ///
  /// Retorna el porcentaje de 1RM (0.0 - 1.0)
  static double percentFrom1RM(double weight, int reps) {
    if (reps == 1) return 1.0;

    final estimated1RM = weight * (1 + reps / 30);
    return weight / estimated1RM;
  }

  /// Calcula el peso objetivo para un número de repeticiones dado
  ///
  /// [oneRM]: 1RM conocido o estimado
  /// [targetReps]: Número de repeticiones objetivo
  ///
  /// Retorna el peso a usar
  static double weightForTarget(double oneRM, int targetReps) {
    if (targetReps == 1) return oneRM;

    return oneRM / (1 + targetReps / 30);
  }

  /// Estima cuántas repeticiones se pueden hacer a un porcentaje dado
  ///
  /// [percent]: Porcentaje de 1RM (0.0 - 1.0)
  ///
  /// Retorna el número aproximado de repeticiones
  static int repsAtPercent(double percent) {
    // Buscar el valor más cercano en la tabla
    double minDiff = double.infinity;
    int closestReps = 1;

    for (final entry in repsToPercent.entries) {
      final diff = (entry.value - percent).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closestReps = entry.key;
      }
    }

    return closestReps;
  }

  /// Estima el 1RM usando la fórmula de Epley
  ///
  /// [weight]: Peso levantado
  /// [reps]: Repeticiones completadas
  ///
  /// Retorna el 1RM estimado
  static double estimated1RM(double weight, int reps) {
    if (reps == 1) return weight;

    return weight * (1 + reps / 30);
  }

  /// Obtiene el porcentaje de 1RM desde la tabla para un número de reps
  ///
  /// Si no está en la tabla, interpola o usa la fórmula de Epley
  static double getPercentFromTable(int reps) {
    // Si está en la tabla, retornar directamente
    if (repsToPercent.containsKey(reps)) {
      return repsToPercent[reps]!;
    }

    // Si está fuera del rango, usar fórmula
    if (reps > 20) {
      // Para más de 20 reps, usar fórmula Epley inversa
      return 1.0 / (1 + reps / 30);
    }

    // Interpolar entre valores de la tabla
    final sortedKeys = repsToPercent.keys.toList()..sort();

    for (int i = 0; i < sortedKeys.length - 1; i++) {
      final lower = sortedKeys[i];
      final upper = sortedKeys[i + 1];

      if (reps > lower && reps < upper) {
        final lowerPercent = repsToPercent[lower]!;
        final upperPercent = repsToPercent[upper]!;

        // Interpolación lineal
        final ratio = (reps - lower) / (upper - lower);
        return lowerPercent - (lowerPercent - upperPercent) * ratio;
      }
    }

    // Fallback: usar fórmula
    return 1.0 / (1 + reps / 30);
  }

  /// Calcula la intensidad relativa desde peso y 1RM conocido
  ///
  /// [weight]: Peso a levantar
  /// [oneRM]: 1RM conocido
  ///
  /// Retorna porcentaje (0.0 - 1.0)
  static double intensityFromWeight(double weight, double oneRM) {
    if (oneRM == 0) return 0.0;
    return weight / oneRM;
  }

  /// Calcula el peso desde porcentaje e 1RM
  ///
  /// [percent]: Porcentaje de 1RM (0.0 - 1.0)
  /// [oneRM]: 1RM conocido
  ///
  /// Retorna el peso correspondiente
  static double weightFromPercent(double percent, double oneRM) {
    return oneRM * percent;
  }

  /// Obtiene información completa de intensidad
  static Map<String, dynamic> getIntensityInfo(double weight, int reps) {
    final percent = percentFrom1RM(weight, reps);
    final estimated1rm = estimated1RM(weight, reps);

    String zone;
    if (percent >= 0.85) {
      zone = 'strength';
    } else if (percent >= 0.65) {
      zone = 'hypertrophy';
    } else {
      zone = 'endurance';
    }

    return {
      'weight': weight,
      'reps': reps,
      'percent': percent,
      'percentFormatted': '${(percent * 100).toStringAsFixed(1)}%',
      'estimated1RM': estimated1rm,
      'zone': zone,
    };
  }

  /// Obtiene recomendaciones de carga para diferentes zonas
  ///
  /// [oneRM]: 1RM conocido
  ///
  /// Retorna mapa con recomendaciones por zona
  static Map<String, Map<String, dynamic>> getLoadRecommendations(
    double oneRM,
  ) {
    return {
      'strength': {
        'percent': 0.85,
        'weight': weightFromPercent(0.85, oneRM),
        'reps': repsAtPercent(0.85),
        'range': '1-5 reps',
      },
      'hypertrophy': {
        'percent': 0.75,
        'weight': weightFromPercent(0.75, oneRM),
        'reps': repsAtPercent(0.75),
        'range': '6-12 reps',
      },
      'endurance': {
        'percent': 0.60,
        'weight': weightFromPercent(0.60, oneRM),
        'reps': repsAtPercent(0.60),
        'range': '12-20+ reps',
      },
    };
  }
}
