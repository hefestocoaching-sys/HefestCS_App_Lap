/// Session Volume Limits - Límites de sets por músculo por sesión
///
/// Referencias científicas:
/// - Brigatto et al. (2019) J Strength Cond Res 33(8):2104-2116
/// - Schoenfeld (2024) Session volume saturation
class SessionVolumeLimits {
  /// Músculos pequeños con límites específicos
  static const List<String> _smallMuscles = [
    'biceps',
    'triceps',
    'calves',
    'abs',
  ];

  /// Límites de sets por sesión según nivel y músculo
  static const Map<String, Map<String, int>> _limits = {
    'beginner': {'default': 6, 'small_muscles': 8},
    'intermediate': {'default': 8, 'small_muscles': 8},
    'advanced': {
      'default': 10,
      'small_muscles': 8,
      'glutes': 12, // Excepción: alta tolerancia
    },
  };

  /// Obtiene el límite de sets por sesión para un músculo y nivel
  static int getLimit(String level, String muscle) {
    if (!_limits.containsKey(level)) {
      throw ArgumentError(
        'Nivel no soportado: $level. '
        'Opciones válidas: beginner, intermediate, advanced',
      );
    }

    final levelLimits = _limits[level]!;

    // Caso especial: glúteos en nivel avanzado
    if (level == 'advanced' && muscle == 'glutes') {
      return levelLimits['glutes']!;
    }

    // Músculos pequeños
    if (_smallMuscles.contains(muscle)) {
      return levelLimits['small_muscles']!;
    }

    // Músculos grandes (default)
    return levelLimits['default']!;
  }

  /// Verifica si un volumen por sesión excede el límite
  static bool exceedsLimit(int setsPerSession, String level, String muscle) {
    final limit = getLimit(level, muscle);
    return setsPerSession > limit;
  }

  /// Calcula la frecuencia mínima necesaria para distribuir un volumen semanal
  static int calculateMinimumFrequency(
    int weeklyVolume,
    String level,
    String muscle,
  ) {
    final limit = getLimit(level, muscle);
    return (weeklyVolume / limit).ceil();
  }

  /// Distribuye el volumen semanal en sesiones respetando límites
  ///
  /// Retorna una lista con los sets por sesión
  /// Lanza ArgumentError si la frecuencia es insuficiente
  static List<int> distributeVolume(
    int weeklyVolume,
    int frequency,
    String level,
    String muscle,
  ) {
    final limit = getLimit(level, muscle);
    final minFrequency = calculateMinimumFrequency(weeklyVolume, level, muscle);

    if (frequency < minFrequency) {
      throw ArgumentError(
        'Frecuencia insuficiente. Se necesitan al menos $minFrequency sesiones '
        'para distribuir $weeklyVolume sets semanales sin exceder el límite '
        'de $limit sets/sesión para $muscle (nivel: $level)',
      );
    }

    // Distribuir sets equitativamente
    final baseSets = weeklyVolume ~/ frequency;
    final remainder = weeklyVolume % frequency;

    final distribution = List<int>.generate(
      frequency,
      (index) => baseSets + (index < remainder ? 1 : 0),
    );

    // Validar que ninguna sesión exceda el límite
    for (var i = 0; i < distribution.length; i++) {
      if (distribution[i] > limit) {
        throw ArgumentError(
          'La sesión ${i + 1} excede el límite: ${distribution[i]} > $limit sets',
        );
      }
    }

    return distribution;
  }

  /// Valida si una distribución de sets respeta el límite
  ///
  /// Retorna null si es válida, o un mensaje de error si no lo es
  static String? validateDistribution(
    int setsPerSession,
    String level,
    String muscle,
  ) {
    final limit = getLimit(level, muscle);

    if (setsPerSession > limit) {
      return 'El volumen de $setsPerSession sets por sesión excede el límite '
          'de $limit sets para $muscle en nivel $level. '
          'Considera aumentar la frecuencia de entrenamiento.';
    }

    return null;
  }

  /// Verifica si un músculo es considerado "pequeño"
  static bool isSmallMuscle(String muscle) => _smallMuscles.contains(muscle);

  /// Lista de músculos pequeños
  static List<String> get smallMuscles => List.unmodifiable(_smallMuscles);
}
