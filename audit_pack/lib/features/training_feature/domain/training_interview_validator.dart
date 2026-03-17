import 'package:hcs_app_lap/core/constants/training_interview_keys.dart';
import 'package:hcs_app_lap/features/training_feature/domain/training_interview_status.dart';

TrainingInterviewStatus evaluateTrainingInterview(Map<String, dynamic>? extra) {
  if (extra == null || extra.isEmpty) {
    return TrainingInterviewStatus.empty;
  }

  int? parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  final hasTrainedBefore =
      extra[TrainingInterviewKeys.hasTrainedBefore] as bool?;
  final isTrainingNow = extra[TrainingInterviewKeys.isTrainingNow] as bool?;
  final totalYearsTrainedBefore =
      parseInt(extra[TrainingInterviewKeys.totalYearsTrainedBefore]);
  final hadLongPause = extra[TrainingInterviewKeys.hadLongPause] as bool?;
  final longestPauseMonths =
      parseInt(extra[TrainingInterviewKeys.longestPauseMonths]);
  final monthsTrainingNow =
      parseInt(extra[TrainingInterviewKeys.monthsTrainingNow]);

  if (hasTrainedBefore == null || isTrainingNow == null) {
    return TrainingInterviewStatus.partial;
  }

  if (hasTrainedBefore) {
    if (totalYearsTrainedBefore == null) {
      return TrainingInterviewStatus.partial;
    }
    if (hadLongPause == null) {
      return TrainingInterviewStatus.partial;
    }
    if (hadLongPause && longestPauseMonths == null) {
      return TrainingInterviewStatus.partial;
    }
  }

  if (isTrainingNow && monthsTrainingNow == null) {
    return TrainingInterviewStatus.partial;
  }

  return TrainingInterviewStatus.valid;
}
