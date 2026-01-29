/// Servicio para calcular targets iniciales de volumen por músculo
/// basados en prioridades musculares del usuario.
///
/// Concepto clínico:
/// - Músculos primarios: 80-95% de MRV (factor 0.90)
/// - Músculos secundarios: 60-75% de MRV (factor 0.70)
/// - Músculos terciarios: 45-60% de MRV (factor 0.55)
/// - Músculos no priorizados: MEV (estímulo mínimo)
class InitialVolumeTargetService {
  static const double _primaryFactor = 0.90;
  static const double _secondaryFactor = 0.70;
  static const double _tertiaryFactor = 0.55;

  /// Construye targets de volumen diferenciados por prioridad muscular.
  ///
  /// Garantiza que:
  /// - Ningún target < MEV
  /// - Ningún target > MRV
  /// - Músculos prioritarios se acercan a MRV
  /// - Músculos no prioritarios se acercan a MEV
  static Map<String, double> buildTargets({
    required Iterable<String> muscles,
    required Map<String, double> mevByMuscle,
    required Map<String, double> mrvByMuscle,
    required Iterable<String> primary,
    required Iterable<String> secondary,
    required Iterable<String> tertiary,
  }) {
    final targets = <String, double>{};

    for (final m in muscles) {
      final mev = mevByMuscle[m];
      final mrv = mrvByMuscle[m];

      if (mev == null || mrv == null) continue;

      double target;

      if (primary.contains(m)) {
        target = mrv * _primaryFactor;
      } else if (secondary.contains(m)) {
        target = mrv * _secondaryFactor;
      } else if (tertiary.contains(m)) {
        target = mrv * _tertiaryFactor;
      } else {
        target = mev;
      }

      // Guardrails duros: nunca salir del rango [MEV, MRV]
      target = target.clamp(mev, mrv);

      // Redondeo clínico (permitir medios sets)
      targets[m] = (target * 2).roundToDouble() / 2;
    }

    return targets;
  }
}
