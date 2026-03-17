/// Volume Landmarks - MEV/MAV/MRV por músculo y nivel
///
/// Referencias científicas:
/// - Israetel et al. (2017-2020) Renaissance Periodization
/// - Ramos-Campo et al. (2024) J Strength Cond Res 38(7):1330-1340
/// - Schoenfeld et al. (2019) Meta-análisis volumen-hipertrofia
class VolumeLandmarks {
  /// Mapeo de nombres en español a nombres canónicos en inglés
  static const Map<String, String> _spanishToEnglish = {
    'pecho': 'chest',
    'pectoral': 'chest',
    'dorsales': 'lats',
    'dorsal': 'lats',
    'espalda': 'back_mid_upper',
    'espalda_alta': 'back_mid_upper',
    'espalda_media': 'back_mid_upper',
    'trapecio': 'upper_traps',
    'traps': 'upper_traps',
    'trapecio_superior': 'upper_traps',
    'hombros': 'shoulders',
    'hombro': 'shoulders',
    'deltoides': 'shoulders',
    'deltoide anterior': 'deltoide_anterior',
    'deltoide lateral': 'deltoide_lateral',
    'deltoide posterior': 'deltoide_posterior',
    'deltoides anterior': 'deltoide_anterior',
    'deltoides lateral': 'deltoide_lateral',
    'deltoides posterior': 'deltoide_posterior',
    'cuadriceps': 'quads',
    'cuads': 'quads',
    'isquiosurales': 'hamstrings',
    'isquios': 'hamstrings',
    'femoral': 'hamstrings',
    'gluteos': 'glutes',
    'gluteo': 'glutes',
    'biceps': 'biceps',
    'triceps': 'triceps',
    'pantorrilla': 'calves',
    'pantorrillas': 'calves',
    'gemelos': 'calves',
    'abdomen': 'abs',
    'abdominal': 'abs',
  };

  static const Map<String, String> _englishAliases = {
    'back': 'back_mid_upper',
    'upper_back': 'back_mid_upper',
    'upperback': 'back_mid_upper',
    'mid_upper_back': 'back_mid_upper',
    'traps': 'upper_traps',
    'trapezius': 'upper_traps',
    'upper_traps': 'upper_traps',
    'deltoids': 'shoulders',
    'shoulder': 'shoulders',
    'deltoid_anterior': 'deltoide_anterior',
    'deltoid_lateral': 'deltoide_lateral',
    'deltoid_posterior': 'deltoide_posterior',
    'quadriceps': 'quads',
    'abdominals': 'abs',
    'latissimus': 'lats',
  };

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
    'deltoide_anterior': {
      'beginner': {'mev': 6, 'mav_min': 9, 'mav_max': 11, 'mrv': 16},
      'intermediate': {'mev': 6, 'mav_min': 9, 'mav_max': 11, 'mrv': 16},
      'advanced': {'mev': 6, 'mav_min': 9, 'mav_max': 11, 'mrv': 16},
    },
    'deltoide_lateral': {
      'beginner': {'mev': 6, 'mav_min': 9, 'mav_max': 11, 'mrv': 16},
      'intermediate': {'mev': 6, 'mav_min': 9, 'mav_max': 11, 'mrv': 16},
      'advanced': {'mev': 6, 'mav_min': 9, 'mav_max': 11, 'mrv': 16},
    },
    'deltoide_posterior': {
      'beginner': {'mev': 6, 'mav_min': 9, 'mav_max': 11, 'mrv': 16},
      'intermediate': {'mev': 6, 'mav_min': 9, 'mav_max': 11, 'mrv': 16},
      'advanced': {'mev': 6, 'mav_min': 9, 'mav_max': 11, 'mrv': 16},
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
  static bool isSupported(String muscle) {
    final normalized = _normalizeMuscle(muscle);
    return _landmarks.containsKey(normalized);
  }

  /// Obtiene el MEV (Minimum Effective Volume) para un músculo y nivel
  static int getMEV(String muscle, String level) {
    final normalized = _normalizeMuscle(muscle);
    _validateInput(normalized, level);
    return _landmarks[normalized]![level]!['mev']!;
  }

  /// Obtiene el MAV mínimo (Maximum Adaptive Volume) para un músculo y nivel
  static int getMAVMin(String muscle, String level) {
    final normalized = _normalizeMuscle(muscle);
    _validateInput(normalized, level);
    return _landmarks[normalized]![level]!['mav_min']!;
  }

  /// Obtiene el MAV máximo (Maximum Adaptive Volume) para un músculo y nivel
  static int getMAVMax(String muscle, String level) {
    final normalized = _normalizeMuscle(muscle);
    _validateInput(normalized, level);
    return _landmarks[normalized]![level]!['mav_max']!;
  }

  /// Obtiene el MRV (Maximum Recoverable Volume) para un músculo y nivel
  static int getMRV(String muscle, String level) {
    final normalized = _normalizeMuscle(muscle);
    _validateInput(normalized, level);
    return _landmarks[normalized]![level]!['mrv']!;
  }

  /// Obtiene el volumen recomendado de inicio
  /// Fórmula: MEV + 30% del rango hasta MAV_min
  static int getRecommendedStart(String muscle, String level) {
    final normalized = _normalizeMuscle(muscle);
    _validateInput(normalized, level);
    final mev = getMEV(normalized, level);
    final mavMin = getMAVMin(normalized, level);
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
    final normalized = _normalizeMuscle(muscle);
    _validateInput(normalized, level);
    final baseMRV = getMRV(normalized, level);

    // Ajuste específico para glúteos femeninos
    if (isFemale && normalized == 'glutes') {
      return (baseMRV * 1.15).round();
    }

    return baseMRV;
  }

  /// Validación de entrada
  static void _validateInput(String muscle, String level) {
    if (!_landmarks.containsKey(muscle)) {
      final validMuscles = _landmarks.keys.toList();
      final validSpanish = _spanishToEnglish.keys.toList();
      throw ArgumentError(
        'Músculo no soportado: $muscle. '
        'Opciones válidas (inglés): ${validMuscles.join(", ")}\n'
        'Opciones válidas (español): ${validSpanish.join(", ")}',
      );
    }

    if (!_landmarks[muscle]!.containsKey(level)) {
      throw ArgumentError(
        'Nivel no soportado: $level. '
        'Opciones válidas: beginner, intermediate, advanced',
      );
    }
  }

  /// Normaliza un nombre de músculo (español o inglés) a nombre canónico
  static String _normalizeMuscle(String muscle) {
    final normalized = muscle.toLowerCase().trim();

    // 1. Si ya está en inglés canónico, retornar
    if (_landmarks.containsKey(normalized)) {
      return normalized;
    }

    // 2. Si es alias en inglés, convertir a canónico
    if (_englishAliases.containsKey(normalized)) {
      return _englishAliases[normalized]!;
    }

    // 3. Si está en español, convertir a inglés
    if (_spanishToEnglish.containsKey(normalized)) {
      return _spanishToEnglish[normalized]!;
    }

    // 4. Si no se encuentra, retornar original
    return normalized;
  }
}
