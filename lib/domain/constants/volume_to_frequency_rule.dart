/// Contrato funcional Fase 2 para convertir volumen semanal en frecuencia.
///
/// Regla cerrada:
/// - 6..12 series  -> frecuencia 1
/// - 13..22 series -> frecuencia 2
/// - 23..34 series -> frecuencia 3
class VolumeToFrequencyRule {
  static const int minVolume = 6;
  static const int maxVolume = 34;

  static int frequencyForWeeklyVolume(int weeklyVolume) {
    if (weeklyVolume <= 0) {
      return 0;
    }
    if (weeklyVolume <= 12) {
      return 1;
    }
    if (weeklyVolume <= 22) {
      return 2;
    }
    return 3;
  }

  static bool isInsideFormalContract(int weeklyVolume) {
    return weeklyVolume >= minVolume && weeklyVolume <= maxVolume;
  }
}
