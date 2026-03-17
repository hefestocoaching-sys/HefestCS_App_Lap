import 'package:hcs_app_lap/domain/training_v3/models/planned_exercise.dart';

class SessionTimeEstimator {
  int estimateMinutes(List<PlannedExercise> exercises) {
    double total = 0;

    for (final ex in exercises) {
      for (final set in ex.sets) {
        if (set.repsMax <= 8) {
          total += 3.0;
        } else if (set.repsMax <= 12) {
          total += 2.5;
        } else {
          total += 2.0;
        }
      }
    }

    return total.round();
  }
}
