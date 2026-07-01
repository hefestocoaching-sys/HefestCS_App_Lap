import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/features/training_feature/domain/exercise_preferences_models.dart';

ExercisePreferencesByMuscle resolveClientExercisePreferences(Client? client) {
  final raw =
      client?.training.extra[TrainingExtraKeys.exercisePreferencesByMuscle];
  return ExercisePreferencesByMuscle.fromDynamic(raw);
}
