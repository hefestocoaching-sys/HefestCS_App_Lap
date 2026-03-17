import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/domain/training_v3/data/exercise_catalog_v3.dart';

class FatigueBalancer {
  static List<Exercise> balance(List<Exercise> exercises) {
    if (exercises.length <= 2) {
      return List<Exercise>.from(exercises);
    }

    final pending = List<Exercise>.from(exercises);
    final result = <Exercise>[];
    var heavyStreak = 0;

    while (pending.isNotEmpty) {
      final index = _pickNextIndex(pending, heavyStreak);
      final exercise = pending.removeAt(index);
      final fatigue = _fatigueScore(exercise);
      if (fatigue >= 4) {
        heavyStreak++;
      } else {
        heavyStreak = 0;
      }
      result.add(exercise);
    }

    return result;
  }

  static int _pickNextIndex(List<Exercise> pending, int heavyStreak) {
    for (var i = 0; i < pending.length; i++) {
      final fatigue = _fatigueScore(pending[i]);
      if (fatigue < 4 || heavyStreak < 2) {
        return i;
      }
    }
    // Si todos los candidatos son pesados, preservamos todos y seguimos.
    return 0;
  }

  static int _fatigueScore(Exercise exercise) {
    final metadata =
        ExerciseCatalogV3.getMetadataById(exercise.id) ??
        const <String, dynamic>{};
    final raw = metadata['fatigueScore'];
    if (raw is int) return raw;
    if (raw is num) return raw.round();
    return int.tryParse(raw?.toString() ?? '') ?? 2;
  }
}
