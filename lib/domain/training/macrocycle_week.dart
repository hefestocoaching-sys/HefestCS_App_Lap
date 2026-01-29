/// Fases de periodización clínica
enum MacroPhase {
  adaptation, // AA - Adaptación anual
  hypertrophy, // HF - Hipertrofia acumulativa
  intensification, // APC - Apropiación/Consolidación
  peaking, // PC - Pico
  deload, // Descarga
}

/// Bloques de entrenamiento específicos dentro de la periodización
// ignore: constant_identifier_names
enum MacroBlock {
  // ignore: constant_identifier_names
  AA, // Adaptación Anual
  // ignore: constant_identifier_names
  HF1, // Hipertrofia 1
  // ignore: constant_identifier_names
  HF2, // Hipertrofia 2
  // ignore: constant_identifier_names
  HF3, // Hipertrofia 3
  // ignore: constant_identifier_names
  HF4, // Hipertrofia 4
  // ignore: constant_identifier_names
  APC1, // Apropiación 1
  // ignore: constant_identifier_names
  APC2, // Apropiación 2
  // ignore: constant_identifier_names
  APC3, // Apropiación 3
  // ignore: constant_identifier_names
  APC4, // Apropiación 4
  // ignore: constant_identifier_names
  APC5, // Apropiación 5
  // ignore: constant_identifier_names
  PC, // Pico
}

/// Descriptor de una semana dentro del macrocycle de 52 semanas.
///
/// Representa la ESTRATEGIA de periodización sin tocar cálculos base.
/// El volumen entrenable (VOP) viene de Tab 1 y se modula por [volumeMultiplier].
/// El reparto de intensidades (Pesadas/Medias/Ligeras) viene de Tab 2 y no cambia.
class MacrocycleWeek {
  /// Número de semana (1–52)
  final int weekNumber;

  /// Fase clínica de la semana
  final MacroPhase phase;

  /// Bloque específico de entrenamiento
  final MacroBlock block;

  /// Multiplicador de volumen para esta semana
  ///
  /// Ejemplo:
  /// - AA (semana 1): 1.0 (100% del VOP)
  /// - HF1 (semana 5): 1.15 (115% del VOP)
  /// - Deload (semana 4): 0.6 (60% del VOP)
  final double volumeMultiplier;

  /// Indica si la semana es de descarga
  final bool isDeload;

  const MacrocycleWeek({
    required this.weekNumber,
    required this.phase,
    required this.block,
    required this.volumeMultiplier,
    required this.isDeload,
  });

  /// Calcula el volumen efectivo para esta semana
  /// basándose en un VOP base.
  ///
  /// NO modifica el reparto de intensidades (Pesadas/Medias/Ligeras).
  double calculateEffectiveVolume(double baseVop) {
    return baseVop * volumeMultiplier;
  }

  @override
  String toString() =>
      'W$weekNumber [$block, $volumeMultiplier× ${isDeload ? 'DELOAD' : phase.name.toUpperCase()}]';
}
