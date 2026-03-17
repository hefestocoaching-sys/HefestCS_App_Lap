class FrequencyInference {
  /// Infiere frecuencia semanal (2 o 3) desde VMR máximo
  ///
  /// LÓGICA:
  /// - VMR >= 20 → frecuencia 3 (división más enfocada, 2-4 ejercicios/día)
  /// - VMR < 20 → frecuencia 2 (días más densos, 5+ ejercicios/día)
  ///
  /// ENTRADA: targetSetsByMuscle (VMR semanal por músculo)
  /// SALIDA: 2 o 3
  static int inferFromVmr(Map<String, double> targetSetsByMuscle) {
    if (targetSetsByMuscle.isEmpty) return 2;

    double maxVmr = 0;
    for (final v in targetSetsByMuscle.values) {
      if (v > maxVmr) maxVmr = v;
    }

    return maxVmr >= 20 ? 3 : 2;
  }
}
