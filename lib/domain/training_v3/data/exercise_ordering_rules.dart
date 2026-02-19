import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/domain/training_v3/data/exercise_catalog_v3.dart';

/// Helper class to provide ordering metadata for exercises.
///
/// Used to sort exercises within a session according to:
/// 1. Compound > Isolation
/// 2. Heavy Load > Moderate > Light
/// 3. Large Muscle > Small Muscle (handled by session structure usually, but good for tie-breaking)
class ExerciseOrderingRules {
  /// Returns a score for sorting. Higher is better (comes first).
  static int getScore(Exercise exercise) {
    int score = 0;

    // 1. Compound vs Isolation (Base score)
    // We infer this from the 'mechanics' field if available, or tags.
    // Since Exercise model might not have explicit mechanics, we use a heuristic or catalog lookup if possible.
    // For now, we assume 'compound' tag or 'multi-joint' in metadata.
    if (_isCompound(exercise)) {
      score += 100;
    } else {
      score += 50;
    }

    // 2. Load Tier (Heavy/Med/Light)
    // Inferred from difficulty or type.
    // 'compound' usually heavy.
    if (_isHeavy(exercise)) {
      score += 20;
    } else if (_isModerate(exercise)) {
      score += 10;
    }

    return score;
  }

  static bool _isCompound(Exercise ex) {
    // Basic heuristic: check if body part is big or movement is known compound
    // Ideally this comes from ExerciseCatalogV3 metadata.

    final type = ExerciseCatalogV3.getTypeById(ex.id);
    if (type == 'compound') return true;
    if (type == 'isolation') return false;

    // Fallback by muscle group
    final heavyMuscles = [
      'quadriceps',
      'hamstrings',
      'chest',
      'back',
      'glutes',
    ];
    if (ex.primaryMuscles.any((m) => heavyMuscles.contains(m.toLowerCase()))) {
      return true;
    }
    return false;
  }

  static bool _isHeavy(Exercise ex) {
    // Compounds are generally heavy
    return _isCompound(ex);
  }

  static bool _isModerate(Exercise ex) {
    return !_isCompound(ex);
  }
}
