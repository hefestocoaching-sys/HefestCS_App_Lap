/// Volume Progression - Frecuencia de incrementos de volumen
///
/// Referencias científicas:
/// - Schoenfeld & Grgic (2020) Progressive overload strategies
/// - Ramos-Campo (2024) J Strength Cond Res 38(7)
/// - Zourdos et al. (2016) Auto-regulation protocols
class VolumeProgression {
  /// Configuración de progresión por nivel
  static const Map<String, Map<String, dynamic>> _progressionConfig = {
    'beginner': {
      'setsIncrement': 2,
      'weeksInterval': 3,
      'maxFatigueScore': 6.0,
      'requiresConditions': true,
      'conditions': ['Técnica estable', 'Sin DOMS prolongado'],
    },
    'intermediate': {
      'setsIncrement': 3,
      'weeksInterval': 2,
      'maxFatigueScore': 7.0,
      'requiresConditions': true,
      'conditions': ['Rendimiento mejorando', 'Fatiga <7/10'],
    },
    'advanced': {
      'setsIncrement': 4,
      'weeksInterval': 1,
      'maxFatigueScore': 7.0,
      'requiresConditions': true,
      'conditions': ['Progreso confirmado', 'Técnica consistente'],
    },
  };

  /// Obtiene el incremento de sets para un nivel
  static int getIncrement(String level) {
    _validateLevel(level);
    return _progressionConfig[level]!['setsIncrement'] as int;
  }

  /// Obtiene el intervalo de semanas para incrementar volumen
  static int getWeeksInterval(String level) {
    _validateLevel(level);
    return _progressionConfig[level]!['weeksInterval'] as int;
  }

  /// Obtiene el máximo score de fatiga permitido para progresar
  static double getMaxFatigueScore(String level) {
    _validateLevel(level);
    return _progressionConfig[level]!['maxFatigueScore'] as double;
  }

  /// Verifica si se puede progresar en volumen
  ///
  /// [level]: Nivel del usuario (beginner, intermediate, advanced)
  /// [fatigueScore]: Score de fatiga actual (0-10)
  /// [weeksSinceLastIncrement]: Semanas desde último incremento
  /// [techniqueStable]: Si la técnica es estable
  ///
  /// Retorna true si se cumplen las condiciones para progresar
  static bool canProgress(
    String level,
    double fatigueScore,
    int weeksSinceLastIncrement,
    bool techniqueStable,
  ) {
    _validateLevel(level);

    final config = _progressionConfig[level]!;
    final maxFatigue = config['maxFatigueScore'] as double;
    final weeksInterval = config['weeksInterval'] as int;
    final requiresConditions = config['requiresConditions'] as bool;

    // Verificar fatiga
    if (fatigueScore > maxFatigue) {
      return false;
    }

    // Verificar intervalo de semanas
    if (weeksSinceLastIncrement < weeksInterval) {
      return false;
    }

    // Verificar técnica (si se requiere)
    if (requiresConditions && !techniqueStable) {
      return false;
    }

    return true;
  }

  /// Obtiene la próxima semana donde se debe incrementar volumen
  ///
  /// [level]: Nivel del usuario
  /// [currentWeek]: Semana actual del programa
  ///
  /// Retorna el número de la próxima semana de incremento
  static int getNextIncrementWeek(String level, int currentWeek) {
    _validateLevel(level);
    final interval = getWeeksInterval(level);
    return currentWeek + interval;
  }

  /// Valida las condiciones para progresión
  ///
  /// [level]: Nivel del usuario
  /// [conditions]: Mapa con condiciones a validar
  ///   - 'fatigueScore': double (requerido)
  ///   - 'weeksSinceLastIncrement': int (requerido)
  ///   - 'techniqueStable': bool (requerido)
  ///   - 'performanceDeclining': bool (opcional)
  ///
  /// Retorna null si puede progresar, o mensaje de error con la razón
  static String? validateProgressionConditions(
    String level,
    Map<String, dynamic> conditions,
  ) {
    _validateLevel(level);

    // Validar que existan los campos requeridos
    if (!conditions.containsKey('fatigueScore') ||
        !conditions.containsKey('weeksSinceLastIncrement') ||
        !conditions.containsKey('techniqueStable')) {
      return 'Faltan condiciones requeridas: fatigueScore, '
          'weeksSinceLastIncrement, techniqueStable';
    }

    final config = _progressionConfig[level]!;
    final fatigueScore = conditions['fatigueScore'] as double;
    final weeksSinceLastIncrement =
        conditions['weeksSinceLastIncrement'] as int;
    final techniqueStable = conditions['techniqueStable'] as bool;
    final performanceDeclining =
        conditions['performanceDeclining'] as bool? ?? false;

    final maxFatigue = config['maxFatigueScore'] as double;
    final weeksInterval = config['weeksInterval'] as int;
    final requiresConditions = config['requiresConditions'] as bool;

    // Verificar fatiga
    if (fatigueScore > maxFatigue) {
      return 'Fatiga muy alta ($fatigueScore/10). '
          'Debe ser ≤$maxFatigue para progresar.';
    }

    // Verificar intervalo
    if (weeksSinceLastIncrement < weeksInterval) {
      final weeksRemaining = weeksInterval - weeksSinceLastIncrement;
      return 'Aún faltan $weeksRemaining semanas antes del próximo incremento. '
          'Esperar al menos $weeksInterval semanas.';
    }

    // Verificar técnica
    if (requiresConditions && !techniqueStable) {
      return 'La técnica debe estar estable antes de incrementar volumen.';
    }

    // Verificar rendimiento
    if (performanceDeclining) {
      return 'El rendimiento está declinando. '
          'No se recomienda incrementar volumen.';
    }

    // Todas las condiciones se cumplen
    return null;
  }

  /// Obtiene las condiciones requeridas para un nivel
  static List<String> getRequiredConditions(String level) {
    _validateLevel(level);
    final config = _progressionConfig[level]!;
    return List<String>.from(config['conditions'] as List);
  }

  /// Obtiene información completa de progresión para un nivel
  static Map<String, dynamic> getProgressionInfo(String level) {
    _validateLevel(level);
    return Map<String, dynamic>.from(_progressionConfig[level]!);
  }

  /// Calcula el nuevo volumen después de un incremento
  ///
  /// [currentVolume]: Volumen semanal actual
  /// [level]: Nivel del usuario
  ///
  /// Retorna el nuevo volumen semanal
  static int calculateNewVolume(int currentVolume, String level) {
    _validateLevel(level);
    final increment = getIncrement(level);
    return currentVolume + increment;
  }

  /// Estima el volumen después de N semanas de progresión
  ///
  /// [startVolume]: Volumen inicial
  /// [level]: Nivel del usuario
  /// [weeks]: Número de semanas
  ///
  /// Retorna el volumen estimado (asumiendo progresión constante)
  static int estimateVolumeAfterWeeks(
    int startVolume,
    String level,
    int weeks,
  ) {
    _validateLevel(level);
    final interval = getWeeksInterval(level);
    final increment = getIncrement(level);
    final numberOfIncrements = weeks ~/ interval;
    return startVolume + (increment * numberOfIncrements);
  }

  /// Valida el nivel
  static void _validateLevel(String level) {
    if (!_progressionConfig.containsKey(level)) {
      throw ArgumentError(
        'Nivel no soportado: $level. '
        'Opciones válidas: beginner, intermediate, advanced',
      );
    }
  }

  /// Obtiene todos los niveles soportados
  static List<String> get supportedLevels => _progressionConfig.keys.toList();

  /// Verifica si un nivel es soportado
  static bool isLevelSupported(String level) =>
      _progressionConfig.containsKey(level);
}
