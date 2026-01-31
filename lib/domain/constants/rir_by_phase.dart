/// RIR by Phase - Configuración de RIR por fase de entrenamiento
///
/// Referencias científicas:
/// - Helms et al. (2016) Strength Cond J 38(4):42-49
/// - Zourdos et al. (2016) J Strength Cond Res 30(1):267-275
/// - NSCA (2024) Essentials of Strength Training
/// - Schoenfeld et al. (2023) Deload strategies Sports Med
class RIRByPhase {
  /// Configuración completa por fase
  static const Map<String, Map<String, dynamic>> _phaseConfigs = {
    'accumulation': {
      'rirMin': 2.0,
      'rirMax': 4.0,
      'rirTarget': 2.5,
      'repRangeMin': 8,
      'repRangeMax': 15,
      'intensityMin': 0.60,
      'intensityMax': 0.75,
      'primaryGoal': 'volume',
      'description': 'Fase de acumulación de volumen moderado-alto',
      'durationWeeks': 3,
    },
    'intensification': {
      'rirMin': 1.0,
      'rirMax': 2.0,
      'rirTarget': 1.5,
      'repRangeMin': 5,
      'repRangeMax': 10,
      'intensityMin': 0.75,
      'intensityMax': 0.85,
      'primaryGoal': 'intensity',
      'description': 'Fase de incremento de intensidad relativa',
      'durationWeeks': 3,
    },
    'realization': {
      'rirMin': 0.0,
      'rirMax': 1.0,
      'rirTarget': 0.5,
      'repRangeMin': 1,
      'repRangeMax': 5,
      'intensityMin': 0.85,
      'intensityMax': 0.95,
      'primaryGoal': 'peak_strength',
      'description': 'Fase de realización de fuerza máxima',
      'durationWeeks': 2,
    },
    'deload': {
      'rirMin': 4.0,
      'rirMax': 5.0,
      'rirTarget': 4.5,
      'repRangeMin': 10,
      'repRangeMax': 15,
      'intensityMin': 0.50,
      'intensityMax': 0.60,
      'primaryGoal': 'recovery',
      'description': 'Semana de descarga activa',
      'durationWeeks': 1,
    },
  };

  /// Obtiene la configuración completa de una fase
  static Map<String, dynamic> getPhaseConfig(String phase) {
    if (!_phaseConfigs.containsKey(phase)) {
      throw ArgumentError(
        'Fase no soportada: $phase. '
        'Opciones válidas: ${allPhases.join(", ")}',
      );
    }
    return Map<String, dynamic>.from(_phaseConfigs[phase]!);
  }

  /// Obtiene el RIR objetivo de una fase
  static double getRIRTarget(String phase) {
    return getPhaseConfig(phase)['rirTarget'] as double;
  }

  /// Obtiene el rango de RIR de una fase (min, max)
  static (double, double) getRIRRange(String phase) {
    final config = getPhaseConfig(phase);
    return (config['rirMin'] as double, config['rirMax'] as double);
  }

  /// Obtiene el rango de repeticiones de una fase (min, max)
  static (int, int) getRepRange(String phase) {
    final config = getPhaseConfig(phase);
    return (config['repRangeMin'] as int, config['repRangeMax'] as int);
  }

  /// Obtiene la intensidad promedio de una fase
  static double getIntensity(String phase) {
    final config = getPhaseConfig(phase);
    final min = config['intensityMin'] as double;
    final max = config['intensityMax'] as double;
    return (min + max) / 2;
  }

  /// Obtiene el rango de intensidad de una fase (min, max)
  static (double, double) getIntensityRange(String phase) {
    final config = getPhaseConfig(phase);
    return (config['intensityMin'] as double, config['intensityMax'] as double);
  }

  /// Obtiene la duración en semanas de una fase
  static int getDurationWeeks(String phase) {
    return getPhaseConfig(phase)['durationWeeks'] as int;
  }

  /// Obtiene todas las fases disponibles
  static List<String> get allPhases => _phaseConfigs.keys.toList();

  /// Obtiene la descripción de una fase
  static String getDescription(String phase) {
    return getPhaseConfig(phase)['description'] as String;
  }

  /// Obtiene el objetivo primario de una fase
  static String getPrimaryGoal(String phase) {
    return getPhaseConfig(phase)['primaryGoal'] as String;
  }

  /// Verifica si un valor de RIR es válido para una fase
  static bool isRIRValid(String phase, double rir) {
    final (min, max) = getRIRRange(phase);
    return rir >= min && rir <= max;
  }

  /// Ajusta un valor de RIR al rango válido de una fase
  static double clampRIR(String phase, double rir) {
    final (min, max) = getRIRRange(phase);
    if (rir < min) return min;
    if (rir > max) return max;
    return rir;
  }

  /// Obtiene el RIR mínimo de una fase
  static double getRIRMin(String phase) {
    return getPhaseConfig(phase)['rirMin'] as double;
  }

  /// Obtiene el RIR máximo de una fase
  static double getRIRMax(String phase) {
    return getPhaseConfig(phase)['rirMax'] as double;
  }

  /// Obtiene el rango mínimo de repeticiones
  static int getRepRangeMin(String phase) {
    return getPhaseConfig(phase)['repRangeMin'] as int;
  }

  /// Obtiene el rango máximo de repeticiones
  static int getRepRangeMax(String phase) {
    return getPhaseConfig(phase)['repRangeMax'] as int;
  }

  /// Obtiene la intensidad mínima
  static double getIntensityMin(String phase) {
    return getPhaseConfig(phase)['intensityMin'] as double;
  }

  /// Obtiene la intensidad máxima
  static double getIntensityMax(String phase) {
    return getPhaseConfig(phase)['intensityMax'] as double;
  }
}
