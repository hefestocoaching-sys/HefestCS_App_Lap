import 'package:hcs_app_lap/domain/constants/session_limits.dart';

/// Determina frecuencia óptima de entrenamiento según volumen semanal
///
/// Regla HCS:
/// - ≤20 sets/semana → 2 sesiones (10 sets/sesión máx)
/// - ≥21 sets/semana → 3 sesiones (7 sets/sesión máx)
///
/// Justificación científica:
/// - SessionVolumeLimits: 8 sets/músculo/sesión para intermediate
/// - 20 sets ÷ 2 = 10 sets/sesión (excede límite)
/// - 21 sets ÷ 3 = 7 sets/sesión (dentro de límite)
class FrequencyByVolume {
  /// Umbral de volumen para cambiar frecuencia
  static const int volumeThresholdFor3x = 21;

  /// Calcula frecuencia óptima según volumen semanal
  static int calculateFrequency({
    required int weeklyVolume,
    required int maxDaysAvailable,
  }) {
    // Regla principal
    if (weeklyVolume >= volumeThresholdFor3x) {
      // Necesita 3 sesiones
      return maxDaysAvailable >= 3 ? 3 : maxDaysAvailable;
    } else {
      // 2 sesiones suficientes
      return maxDaysAvailable >= 2 ? 2 : maxDaysAvailable;
    }
  }

  /// Valida que la frecuencia sea suficiente para el volumen
  static bool isFrequencySufficient({
    required int weeklyVolume,
    required int frequency,
    required String level,
    required String muscle,
  }) {
    if (frequency == 0) return false;

    final setsPerSession = weeklyVolume / frequency;
    final sessionLimit = SessionVolumeLimits.getLimit(level, muscle);

    return setsPerSession <= sessionLimit;
  }

  /// Calcula frecuencia mínima necesaria para respetar límites de sesión
  static int calculateMinimumFrequency({
    required int weeklyVolume,
    required String level,
    required String muscle,
  }) {
    final sessionLimit = SessionVolumeLimits.getLimit(level, muscle);
    return (weeklyVolume / sessionLimit).ceil();
  }

  /// Retorna sets por sesión para una frecuencia dada
  static List<int> distributeSetsAcrossFrequency({
    required int weeklyVolume,
    required int frequency,
  }) {
    final basePerSession = weeklyVolume ~/ frequency;
    final remainder = weeklyVolume % frequency;

    final distribution = <int>[];
    for (int i = 0; i < frequency; i++) {
      distribution.add(basePerSession + (i < remainder ? 1 : 0));
    }

    return distribution;
  }

  /// Retorna explicación de la frecuencia calculada
  static String explainFrequency({
    required int weeklyVolume,
    required int frequency,
    required String muscle,
  }) {
    if (weeklyVolume >= volumeThresholdFor3x) {
      return '$muscle: $weeklyVolume sets/semana → $frequency sesiones '
          '(volumen alto ≥21 requiere 3x/semana)';
    } else {
      return '$muscle: $weeklyVolume sets/semana → $frequency sesiones '
          '(volumen ≤20 suficiente con 2x/semana)';
    }
  }
}
