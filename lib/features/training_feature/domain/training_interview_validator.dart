import 'package:hcs_app_lap/core/constants/training_interview_keys.dart';
import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
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

  final ageYears = parseInt(extra[TrainingExtraKeys.ageYears]);
  final heightCm = _parseDouble(extra[TrainingExtraKeys.heightCm]);
  final weightKg = _parseDouble(extra[TrainingExtraKeys.weightKg]);
  final trainingMonths =
      parseInt(
        extra[TrainingExtraKeys.trainingMonths] ??
            extra[TrainingInterviewKeys.trainingMonths],
      ) ??
      (() {
        final years = parseInt(extra[TrainingExtraKeys.trainingYears]);
        if (years == null || years <= 0) return null;
        return years * 12;
      })();
  final effectiveTrainingLevel =
      (extra[TrainingExtraKeys.trainingLevelDerived] ??
              extra[TrainingExtraKeys.effectiveTrainingLevel] ??
              extra[TrainingInterviewKeys.effectiveTrainingLevel] ??
              extra[TrainingExtraKeys.trainingLevel])
          ?.toString();
  final strengthLevelClass = extra[TrainingExtraKeys.strengthLevelClass]
      ?.toString();
  final workCapacityScore = parseInt(
    extra[TrainingExtraKeys.workCapacityScore],
  );
  final recoveryHistoryScore = parseInt(
    extra[TrainingExtraKeys.recoveryHistoryScore],
  );
  final externalRecoverySupport =
      extra[TrainingExtraKeys.externalRecoverySupport] as bool?;
  final programNoveltyClass = extra[TrainingExtraKeys.programNoveltyClass]
      ?.toString();
  final externalPhysicalStressLevel =
      extra[TrainingExtraKeys.externalPhysicalStressLevel]?.toString();
  final nonPhysicalStressLevel2 =
      extra[TrainingExtraKeys.nonPhysicalStressLevel2]?.toString();
  final restQuality2 = extra[TrainingExtraKeys.restQuality2]?.toString();
  final dietHabitsClass = extra[TrainingExtraKeys.dietHabitsClass]?.toString();
  final usesAnabolics = extra[TrainingExtraKeys.usesAnabolics] as bool?;
  if (ageYears == null || ageYears <= 0) return TrainingInterviewStatus.partial;
  if (heightCm == null || heightCm <= 0) return TrainingInterviewStatus.partial;
  if (weightKg == null || weightKg <= 0) return TrainingInterviewStatus.partial;
  if (trainingMonths == null || trainingMonths <= 0) {
    return TrainingInterviewStatus.partial;
  }
  if (effectiveTrainingLevel == null ||
      !const {
        'beginner',
        'intermediate',
        'advanced',
      }.contains(effectiveTrainingLevel)) {
    return TrainingInterviewStatus.partial;
  }

  if (strengthLevelClass == null ||
      !const {'B', 'M', 'A', 'MA'}.contains(strengthLevelClass)) {
    return TrainingInterviewStatus.partial;
  }
  if (workCapacityScore == null ||
      workCapacityScore < 1 ||
      workCapacityScore > 5) {
    return TrainingInterviewStatus.partial;
  }
  if (recoveryHistoryScore == null ||
      recoveryHistoryScore < 1 ||
      recoveryHistoryScore > 5) {
    return TrainingInterviewStatus.partial;
  }
  if (externalRecoverySupport == null) return TrainingInterviewStatus.partial;
  if (programNoveltyClass == null ||
      !const {'N', 'B', 'I', 'A'}.contains(programNoveltyClass)) {
    return TrainingInterviewStatus.partial;
  }
  if (externalPhysicalStressLevel == null ||
      !const {'N', 'B', 'I', 'A'}.contains(externalPhysicalStressLevel)) {
    return TrainingInterviewStatus.partial;
  }
  if (nonPhysicalStressLevel2 == null ||
      !const {'B', 'P', 'A'}.contains(nonPhysicalStressLevel2)) {
    return TrainingInterviewStatus.partial;
  }
  if (restQuality2 == null || !const {'B', 'P', 'A'}.contains(restQuality2)) {
    return TrainingInterviewStatus.partial;
  }
  if (dietHabitsClass == null ||
      !const {
        'SCA',
        'SCM',
        'SCB',
        'ISO',
        'DCB',
        'DCM',
        'DCA',
      }.contains(dietHabitsClass)) {
    return TrainingInterviewStatus.partial;
  }
  if (usesAnabolics == null) return TrainingInterviewStatus.partial;

  return TrainingInterviewStatus.valid;
}

double? _parseDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}
