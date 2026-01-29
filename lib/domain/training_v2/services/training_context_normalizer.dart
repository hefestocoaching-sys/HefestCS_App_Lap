import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/core/constants/training_interview_keys.dart';

class TrainingContextNormalizer {
  const TrainingContextNormalizer();

  int readInt(
    Map<String, dynamic> extra,
    List<String> keys, {
    int fallback = 0,
  }) {
    for (final k in keys) {
      final v = extra[k];
      if (v is int) return v;
      if (v is num) return v.toInt();
      final parsed = int.tryParse(v?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  double readDouble(
    Map<String, dynamic> extra,
    List<String> keys, {
    double fallback = 0.0,
  }) {
    for (final k in keys) {
      final v = extra[k];
      if (v is double) return v;
      if (v is num) return v.toDouble();
      final parsed = double.tryParse(v?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  bool readBool(
    Map<String, dynamic> extra,
    List<String> keys, {
    bool fallback = false,
  }) {
    for (final k in keys) {
      final v = extra[k];
      if (v is bool) return v;
      if (v is String) {
        final s = v.toLowerCase().trim();
        if (s == 'true') return true;
        if (s == 'false') return false;
      }
    }
    return fallback;
  }

  List<String> readStringList(Map<String, dynamic> extra, String key) {
    final v = extra[key];
    if (v is List) {
      return v
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (v is String && v.trim().isNotEmpty) {
      // soporta "a,b,c"
      return v
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  /// Llaves canónicas para entrevista cuantitativa (UI: training_evaluation_tab.dart)
  int yearsTrainingContinuous(Map<String, dynamic> extra) =>
      readInt(extra, const [
        TrainingExtraKeys.trainingYears,
        TrainingInterviewKeys.yearsTrainingContinuous,
        'yearsTrainingContinuous',
        'trainingAgeYears',
      ]);

  int sessionDurationMinutes(Map<String, dynamic> extra) =>
      readInt(extra, const [
        TrainingExtraKeys.timePerSessionMinutes,
        TrainingInterviewKeys.sessionDurationMinutes,
        'sessionDurationMinutes',
        'timePerSessionMinutes',
      ]);

  int restBetweenSetsSeconds(Map<String, dynamic> extra) =>
      readInt(extra, const [
        TrainingExtraKeys.restBetweenSetsSeconds,
        TrainingInterviewKeys.restBetweenSetsSeconds,
        'restBetweenSetsSeconds',
      ]);

  double avgSleepHours(Map<String, dynamic> extra) => readDouble(extra, const [
    TrainingExtraKeys.avgSleepHours,
    TrainingInterviewKeys.avgSleepHours,
    'avgSleepHours',
  ]);

  int workCapacity(Map<String, dynamic> extra) => readInt(extra, const [
    TrainingInterviewKeys.workCapacity,
    TrainingExtraKeys.workCapacityScore,
    TrainingInterviewKeys.workCapacityScore,
  ], fallback: 3);

  int recoveryHistory(Map<String, dynamic> extra) => readInt(extra, const [
    TrainingInterviewKeys.recoveryHistory,
    TrainingExtraKeys.recoveryHistoryScore,
    TrainingInterviewKeys.recoveryHistoryScore,
  ], fallback: 3);

  bool externalRecovery(Map<String, dynamic> extra) => readBool(extra, const [
    TrainingInterviewKeys.externalRecovery,
    TrainingExtraKeys.externalRecoverySupport,
    TrainingInterviewKeys.externalRecoverySupport,
  ], fallback: false);

  /// Prioridades musculares: TrainingProfile.priorityMusclesX (si existen) o extra keys.
  List<String> priorityPrimary(Map<String, dynamic> extra) =>
      readStringList(extra, TrainingExtraKeys.priorityMusclesPrimary);
  List<String> prioritySecondary(Map<String, dynamic> extra) =>
      readStringList(extra, TrainingExtraKeys.priorityMusclesSecondary);
  List<String> priorityTertiary(Map<String, dynamic> extra) =>
      readStringList(extra, TrainingExtraKeys.priorityMusclesTertiary);

  Map<String, dynamic> manualOverrides(Map<String, dynamic> extra) {
    final v = extra[TrainingExtraKeys.manualOverrides];
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return const {};
  }
}
