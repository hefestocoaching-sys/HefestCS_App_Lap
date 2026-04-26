import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/domain/training_v3/data/exercise_catalog_v3.dart';
import 'package:hcs_app_lap/domain/policies/structural_exercise_order_contract.dart';

/// Helper class to provide ordering metadata for exercises.
///
/// Used to sort exercises within a session according to:
/// 1. Compound > Isolation
/// 2. Heavy Load > Medium > Light
/// 3. Large Muscle > Small Muscle (handled by session structure usually, but good for tie-breaking)
class ExerciseOrderingRules {
  /// Returns a score for sorting. Higher is better (comes first).
  static int getScore(Exercise exercise) {
    final isCompound = _isCompound(exercise);
    final isLarge = _isLargeMuscle(exercise);
    final zone = _inferIntensityZone(exercise);
    final index = StructuralExerciseOrderContract.structuralIndex(
      isLargeMuscle: isLarge,
      isCompound: isCompound,
      intensityZone: zone,
    );

    // Menor índice estructural debe salir primero.
    return 1000 - index;
  }

  static bool _isCompound(Exercise ex) {
    // Basic heuristic: check if body part is big or movement is known compound
    // Ideally this comes from ExerciseCatalogV3 metadata.

    final type = ExerciseCatalogV3.getTypeById(ex.id);
    if (type == 'compound') return true;
    if (type == 'isolation') return false;

    // Fallback by muscle group
    final heavyMuscles = [
      'quads',
      'hamstrings',
      'pectorals',
      'lats',
      'upper_back',
      'glutes',
    ];
    if (ex.primaryMuscles.any((m) => heavyMuscles.contains(m.toLowerCase()))) {
      return true;
    }
    return false;
  }

  static bool _isLargeMuscle(Exercise ex) {
    final large = {
      'quads',
      'hamstrings',
      'pectorals',
      'lats',
      'upper_back',
      'glutes',
      'traps',
    };
    return ex.primaryMuscles.any((m) => large.contains(m.toLowerCase()));
  }

  static String _inferIntensityZone(Exercise ex) {
    final metadata = ExerciseCatalogV3.getMetadataById(ex.id) ?? const {};
    final loadCategory = metadata['loadCategory']?.toString().toLowerCase();
    if (loadCategory == 'heavy' || loadCategory == 'light') {
      return loadCategory!;
    }
    return 'medium';
  }
}
