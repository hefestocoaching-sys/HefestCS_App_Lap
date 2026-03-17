import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/domain/training_v3/data/exercise_catalog_v3.dart';

class ExerciseOrderingEngine {
  static List<Exercise> orderExercises(List<Exercise> exercises) {
    final ordered = List<Exercise>.from(exercises);
    ordered.sort((a, b) {
      final scoreA = _score(a);
      final scoreB = _score(b);
      return scoreB.compareTo(scoreA);
    });
    return ordered;
  }

  static int scoreFor(Exercise exercise) => _score(exercise);

  static int _score(Exercise exercise) {
    final metadata =
        ExerciseCatalogV3.getMetadataById(exercise.id) ??
        const <String, dynamic>{};

    int load = 0;
    switch (metadata['loadCategory']?.toString()) {
      case 'heavy':
        load = 3;
        break;
      case 'moderate':
        load = 2;
        break;
      case 'light':
        load = 1;
        break;
    }

    final stimulus = _readInt(metadata['stimulusScore'], fallback: 3);
    final fatigue = _readInt(metadata['fatigueScore'], fallback: 2);

    return (stimulus * 2) + load - fatigue;
  }

  static int _readInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
