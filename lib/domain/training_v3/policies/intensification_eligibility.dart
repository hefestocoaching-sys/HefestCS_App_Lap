import 'package:hcs_app_lap/core/utils/muscle_key_normalizer.dart';
import 'package:hcs_app_lap/domain/training_v3/data/exercise_catalog_v3.dart';

/// Contract-level decision for intensification by phase and exercise eligibility.
enum IntensificationRequirement { exempt, optional, required }

class IntensificationEligibility {
  static IntensificationRequirement requirementForExercise({
    required String businessPhaseLabel,
    required String exerciseId,
    String? loadCategory,
    String? movementPattern,
    String? blockLabel,
  }) {
    final phase = businessPhaseLabel.trim().toLowerCase();
    if (!_phaseAllowsZoneIntensification(phase)) {
      return IntensificationRequirement.exempt;
    }

    final eligible = isExerciseEligible(
      exerciseId: exerciseId,
      loadCategory: loadCategory,
      movementPattern: movementPattern,
      blockLabel: blockLabel,
    );
    if (!eligible) {
      return IntensificationRequirement.exempt;
    }

    if (phase == 'maintenance_late') {
      return IntensificationRequirement.required;
    }

    if (phase == 'hf2' || phase == 'hf3') {
      return IntensificationRequirement.optional;
    }

    return IntensificationRequirement.exempt;
  }

  static bool isExerciseEligible({
    required String exerciseId,
    String? loadCategory,
    String? movementPattern,
    String? blockLabel,
  }) {
    final normalizedLoad =
        (loadCategory ?? ExerciseCatalogV3.getLoadCategory(exerciseId))
            .trim()
            .toLowerCase();
    if (normalizedLoad != 'heavy' &&
        normalizedLoad != 'medium' &&
        normalizedLoad != 'light') {
      return false;
    }

    final pattern =
        (movementPattern ?? ExerciseCatalogV3.getMovementPattern(exerciseId))
            .trim()
            .toLowerCase();
    if (pattern.isEmpty || pattern == 'unknown') {
      return false;
    }

    final exercise = ExerciseCatalogV3.getById(exerciseId);
    final primary = normalizeMuscleKey(
      exercise != null && exercise.primaryMuscles.isNotEmpty
          ? exercise.primaryMuscles.first
          : '',
    );
    if (primary == 'abs' ||
        pattern.contains('core') ||
        pattern.contains('abs')) {
      return false;
    }

    if (pattern.contains('carry')) {
      return false;
    }

    // Avoid forcing intensification on neural lower compounds.
    final isCompound = ExerciseCatalogV3.getTypeById(exerciseId) == 'compound';
    if (isCompound && normalizedLoad == 'heavy') {
      if (pattern.contains('hip_hinge') ||
          pattern.contains('knee_dominant') ||
          pattern.contains('squat') ||
          pattern.contains('deadlift')) {
        return false;
      }
    }

    final normalizedBlock = (blockLabel ?? '').trim().toUpperCase();
    if (normalizedBlock == 'A' && isCompound && normalizedLoad == 'heavy') {
      return false;
    }

    return true;
  }

  static bool _phaseAllowsZoneIntensification(String phase) {
    return phase == 'hf2' || phase == 'hf3' || phase == 'maintenance_late';
  }
}
