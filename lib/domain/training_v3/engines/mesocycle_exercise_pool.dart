import 'package:hcs_app_lap/domain/entities/exercise.dart';

class MesocycleExercisePool {
  static final Map<String, List<String>> _pool = {};

  static List<Exercise> lockExercises(
    String clientId,
    List<Exercise> exercises,
  ) {
    if (!_pool.containsKey(clientId)) {
      _pool[clientId] = exercises.map((exercise) => exercise.id).toList();
    }

    final ids = _pool[clientId]!;
    final locked = exercises
        .where((exercise) => ids.contains(exercise.id))
        .toList();
    return locked.isEmpty ? List<Exercise>.from(exercises) : locked;
  }
}
