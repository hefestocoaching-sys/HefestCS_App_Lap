/// Intención de esfuerzo semanal para prescripción
///
/// Propósito:
/// - Reemplazar RIR numérico global (2.5, 1.5, 0.5, 3.5) con intención discreta
/// - Guiar cálculo de RIR target en Phase 7 según rol/tipo de ejercicio
/// - Facilitar adaptación en Phase 8 sin decimales
///
/// Valores:
/// - technique: Alto volumen con margen; posibilidad de técnicas avanzadas
/// - base: Prescripción estándar; margen seguro
/// - push: Esfuerzo elevado; margen bajo; impacto en volumen
/// - deload: Recuperación; margen alto; volumen reducido
enum EffortIntent {
  technique,
  base,
  push,
  deload;

  /// Descripción humana
  String get label {
    switch (this) {
      case EffortIntent.technique:
        return 'Técnica & Volumen';
      case EffortIntent.base:
        return 'Base';
      case EffortIntent.push:
        return 'Esfuerzo Elevado';
      case EffortIntent.deload:
        return 'Recuperación';
    }
  }

  /// Ajuste de RIR midpoint (interno)
  /// Usado en Phase7PrescriptionService.computeRirTarget
  int get rirAdjustment {
    switch (this) {
      case EffortIntent.technique:
        return 1; // +1 RIR (más margen)
      case EffortIntent.base:
        return 0; // sin cambio
      case EffortIntent.push:
        return -1; // -1 RIR (menos margen)
      case EffortIntent.deload:
        return 1; // +1 RIR (recuperación)
    }
  }
}
