// lib/domain/services/training_program_engine.dart

/// FACHADA LEGACY.
/// Mantener solo para compatibilidad con tests antiguos.
/// En el roadmap: reemplazar tests a TrainingOrchestratorV3 / Engines V3 y eliminar este archivo.
class TrainingProgramEngine {
  const TrainingProgramEngine();

  @Deprecated('Legacy. Migrar a TrainingOrchestratorV3.')
  dynamic generateProgram({required Map<String, Object?> input}) {
    throw UnimplementedError(
      'TrainingProgramEngine (legacy) no está implementado. '
      'Migrar tests a training_v3.',
    );
  }
}
