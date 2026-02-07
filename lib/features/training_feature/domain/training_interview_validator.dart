import 'package:hcs_app_lap/features/training_feature/domain/training_interview_status.dart';

TrainingInterviewStatus evaluateTrainingInterview(Map<String, dynamic>? extra) {
  if (extra == null || extra.isEmpty) {
    return TrainingInterviewStatus.empty;
  }

  final requiredKeys = [
    'discipline',
    'heightCm',
    'weightKg',
    'daysPerWeek',
    'timePerSessionMinutes',
    'planDurationInWeeks',
    'priorityMusclesPrimary',
  ];

  final hasAllRequired = requiredKeys.every(
    (k) => extra.containsKey(k) && extra[k] != null,
  );

  if (!hasAllRequired) {
    return TrainingInterviewStatus.partial;
  }

  final days = extra['daysPerWeek'];
  if (days is num) {
    final daysValue = days.toInt();
    if (daysValue < 3 || daysValue > 6) {
      return TrainingInterviewStatus.partial;
    }
  } else {
    return TrainingInterviewStatus.partial;
  }

  return TrainingInterviewStatus.valid;
}
