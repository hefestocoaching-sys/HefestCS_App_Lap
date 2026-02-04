// lib/domain/services/phase_6_exercise_selection_service.dart

/// FACHADA LEGACY para compatibilidad con tests antiguos.
class Phase6ExerciseSelectionService {
  const Phase6ExerciseSelectionService();

  @Deprecated('Legacy. Migrar a ExerciseSelectionEngine V3.')
  dynamic selectExercises({
    required dynamic targetMuscle,
    required dynamic availableExercises,
    required dynamic config,
  }) {
    throw UnimplementedError(
      'Phase6ExerciseSelectionService.selectExercises (legacy) no está implementado. '
      'Migrar tests a training_v3.',
    );
  }
}
