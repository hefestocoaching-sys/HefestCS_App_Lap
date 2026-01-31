/// Volume Landmarks - MEV/MAV/MRV por músculo y nivel
///
/// Referencias científicas:
/// - Israetel et al. (2017-2020) Renaissance Periodization
/// - Ramos-Campo et al. (2024) J Strength Cond Res 38(7):1330-1340
/// - Schoenfeld et al. (2019) Meta-análisis volumen-hipertrofia
class VolumeLandmarks {
  /// Estructura de datos: músculo → nivel → landmark → valor
  static const Map<String, Map<String, Map<String, int>>> _landmarks = {
    'chest': {
      'beginner': {'mev': 6, 'mav_min': 10, 'mav_max': 12, 'mrv': 14},
      'intermediate': {'mev': 8, 'mav_min': 14, 'mav_max': 18, 'mrv': 22},
      'advanced': {'mev': 10, 'mav_min': 16, 'mav_max': 22, 'mrv': 25},
    },
    'lats': {
      'beginner': {'mev': 6, 'mav_min': 10, 'mav_max': 12, 'mrv': 16},
      'intermediate': {'mev': 8, 'mav_min': 12, 'mav_max': 16, 'mrv': 20},
      'advanced': {'mev': 10, 'mav_min': 14, 'mav_max': 20, 'mrv': 24},
    },
    'back_mid_upper': {
      'beginner': {'mev': 6, 'mav_min': 10, 'mav_max': 12, 'mrv': 16},
      'intermediate': {'mev': 8, 'mav_min': 12, 'mav_max': 16, 'mrv': 20},
      'advanced': {'mev': 10, 'mav_min': 14, 'mav_max': 20, 'mrv': 24},
    },
    'upper_traps': {
      'beginner': {'mev': 4, 'mav_min': 6, 'mav_max': 8, 'mrv': 10},
      'intermediate': {'mev': 6, 'mav_min': 8, 'mav_max': 10, 'mrv': 14},
      'advanced': {'mev': 8, 'mav_min': 10, 'mav_max': 14, 'mrv': 16},
    },
    'shoulders': {
      'beginner': {'mev': 6, 'mav_min': 10, 'mav_max': 12, 'mrv': 16},
      'intermediate': {'mev': 8, 'mav_min': 12, 'mav_max': 16, 'mrv': 20},
      'advanced': {'mev': 10, 'mav_min': 14, 'mav_max': 20, 'mrv': 24},
    },
    'quads': {
      'beginner': {'mev': 6, 'mav_min': 10, 'mav_max': 12, 'mrv': 16},
      'intermediate': {'mev': 8, 'mav_min': 12, 'mav_max': 16, 'mrv': 20},
      'advanced': {'mev': 10, 'mav_min': 14, 'mav_max': 20, 'mrv': 24},
    },
    'hamstrings': {
      'beginner': {'mev': 4, 'mav_min': 8, 'mav_max': 10, 'mrv': 12},
      'intermediate': {'mev': 6, 'mav_min': 10, 'mav_max': 14, 'mrv': 18},
      'advanced': {'mev': 8, 'mav_min': 12, 'mav_max': 18, 'mrv': 22},
    },
    'glutes': {
      'beginner': {'mev': 6, 'mav_min': 10, 'mav_max': 12, 'mrv': 16},
      'intermediate': {'mev': 8, 'mav_min': 12, 'mav_max': 18, 'mrv': 22},
      'advanced': {'mev': 10, 'mav_min': 14, 'mav_max': 22, 'mrv': 26},
    },
    'biceps': {
      'beginner': {'mev': 6, 'mav_min': 10, 'mav_max': 12, 'mrv': 14},
      'intermediate': {'mev': 8, 'mav_min': 12, 'mav_max': 16, 'mrv': 18},
      'advanced': {'mev': 10, 'mav_min': 14, 'mav_max': 18, 'mrv': 22},
    },
    'triceps': {
      'beginner': {'mev': 6, 'mav_min': 10, 'mav_max': 12, 'mrv': 14},
      'intermediate': {'mev': 8, 'mav_min': 12, 'mav_max': 16, 'mrv': 18},
      'advanced': {'mev': 10, 'mav_min': 14, 'mav_max': 18, 'mrv': 22},
    },
    'calves': {
      'beginner': {'mev': 6, 'mav_min': 8, 'mav_max': 10, 'mrv': 12},
      'intermediate': {'mev': 8, 'mav_min': 10, 'mav_max': 14, 'mrv': 16},
      'advanced': {'mev': 10, 'mav_min': 12, 'mav_max': 16, 'mrv': 20},
    },
    'abs': {
      'beginner': {'mev': 6, 'mav_min': 8, 'mav_max': 12, 'mrv': 16},
      'intermediate': {'mev': 8, 'mav_min': 12, 'mav_max': 16, 'mrv': 20},
      'advanced': {'mev': 10, 'mav_min': 14, 'mav_max': 20, 'mrv': 25},
    },
  };

  /// Músculos soportados
  static List<String> get supportedMuscles => _landmarks.keys.toList();

  /// Verifica si un músculo es soportado
  static bool isSupported(String muscle) => _landmarks.containsKey(muscle);

  /// Obtiene el MEV (Minimum Effective Volume) para un músculo y nivel
  static int getMEV(String muscle, String level) {
    _validateInput(muscle, level);
    return _landmarks[muscle]![level]!['mev']!;
  }

  /// Obtiene el MAV mínimo (Maximum Adaptive Volume) para un músculo y nivel
  static int getMAVMin(String muscle, String level) {
    _validateInput(muscle, level);
    return _landmarks[muscle]![level]!['mav_min']!;
  }

  /// Obtiene el MAV máximo (Maximum Adaptive Volume) para un músculo y nivel
  static int getMAVMax(String muscle, String level) {
    _validateInput(muscle, level);
    return _landmarks[muscle]![level]!['mav_max']!;
  }

  /// Obtiene el MRV (Maximum Recoverable Volume) para un músculo y nivel
  static int getMRV(String muscle, String level) {
    _validateInput(muscle, level);
    return _landmarks[muscle]![level]!['mrv']!;
  }

  /// Obtiene el volumen recomendado de inicio
  /// Fórmula: MEV + 30% del rango hasta MAV_min
  static int getRecommendedStart(String muscle, String level) {
    _validateInput(muscle, level);
    final mev = getMEV(muscle, level);
    final mavMin = getMAVMin(muscle, level);
    final range = mavMin - mev;
    final increment = (range * 0.3).round();
    return mev + increment;
  }

  /// Obtiene el MRV con ajuste por género
  /// Las mujeres tienen +15% tolerancia en glúteos (Contreras et al.)
  static int getMRVWithGenderAdjustment(
    String muscle,
    String level,
    bool isFemale,
  ) {
    _validateInput(muscle, level);
    final baseMRV = getMRV(muscle, level);

    // Ajuste específico para glúteos femeninos
    if (isFemale && muscle == 'glutes') {
      return (baseMRV * 1.15).round();
    }

    return baseMRV;
  }

  /// Validación de entrada
  static void _validateInput(String muscle, String level) {
    if (!_landmarks.containsKey(muscle)) {
      throw ArgumentError(
        'Músculo no soportado: $muscle. '
        'Opciones válidas: ${supportedMuscles.join(", ")}',
      );
    }

    if (!_landmarks[muscle]!.containsKey(level)) {
      throw ArgumentError(
        'Nivel no soportado: $level. '
        'Opciones válidas: beginner, intermediate, advanced',
      );
    }
  }
}
