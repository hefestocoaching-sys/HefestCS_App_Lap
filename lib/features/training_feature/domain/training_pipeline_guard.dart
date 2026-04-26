import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/landmark_engine.dart';
import 'package:hcs_app_lap/domain/training_v3/models/intensity_split.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_flow_stage.dart';
import 'package:hcs_app_lap/features/training_feature/domain/exercise_preferences_models.dart';
import 'package:hcs_app_lap/features/training_feature/domain/training_interview_status.dart';
import 'package:hcs_app_lap/features/training_feature/domain/training_interview_validator.dart';

class TrainingPipelineGuard {
  TrainingPipelineGuard._();

  static const List<String> _signatureKeys = <String>[
    TrainingExtraKeys.ageYears,
    TrainingExtraKeys.heightCm,
    TrainingExtraKeys.weightKg,
    TrainingExtraKeys.trainingMonths,
    TrainingExtraKeys.trainingLevelDerived,
    TrainingExtraKeys.effectiveTrainingLevel,
    TrainingExtraKeys.strengthLevelClass,
    TrainingExtraKeys.workCapacityScore,
    TrainingExtraKeys.recoveryHistoryScore,
    TrainingExtraKeys.externalRecoverySupport,
    TrainingExtraKeys.programNoveltyClass,
    TrainingExtraKeys.externalPhysicalStressLevel,
    TrainingExtraKeys.nonPhysicalStressLevel2,
    TrainingExtraKeys.restQuality2,
    TrainingExtraKeys.dietHabitsClass,
    TrainingExtraKeys.usesAnabolics,
    TrainingExtraKeys.vmeCalculated,
    TrainingExtraKeys.vmrCalculated,
    TrainingExtraKeys.vopCalculated,
  ];

  static String computeInterviewSignature(Map<String, dynamic> extra) {
    final buffer = StringBuffer();
    for (final key in _signatureKeys) {
      final value = extra[key];
      buffer.write(key);
      buffer.write('=');
      buffer.write(_stableValue(value));
      buffer.write('|');
    }
    return buffer.toString();
  }

  static TrainingInterviewStatus interviewStatus(Map<String, dynamic> extra) {
    return evaluateTrainingInterview(extra);
  }

  static bool isInterviewValid(Map<String, dynamic> extra) {
    return interviewStatus(extra) == TrainingInterviewStatus.valid;
  }

  static bool hasLandmarks(Map<String, dynamic> extra) {
    final landmarks = LandmarkEngine.parseByCanonicalKey(
      extra[TrainingExtraKeys.muscleLandmarks],
    );
    return landmarks.isNotEmpty;
  }

  static bool landmarksAreCurrent(Map<String, dynamic> extra) {
    if (!hasLandmarks(extra)) return false;
    final persisted = extra[TrainingExtraKeys.interviewPipelineSignature]
        ?.toString();
    if (persisted == null || persisted.isEmpty) return false;
    return persisted == computeInterviewSignature(extra);
  }

  static bool isIntensityValid(Map<String, dynamic> extra) {
    final splitRaw = extra[TrainingExtraKeys.seriesTypePercentSplit];
    final split = splitRaw is Map
        ? IntensitySplit.fromMap(
            splitRaw.map((key, value) => MapEntry(key.toString(), value)),
          )
        : IntensitySplit.defaultSplit;
    return split.isValid;
  }

  static bool isGymExercisesReady(Map<String, dynamic> extra) {
    final raw = extra[TrainingExtraKeys.exercisePreferencesByMuscle];
    final parsed = ExercisePreferencesByMuscle.fromDynamic(raw);
    return parsed.hasMinimumData;
  }

  static bool hasPlan(Map<String, dynamic> extra) {
    // Verificar si existe un plan activo generado
    final activePlanId = extra['activePlanId']?.toString();
    return activePlanId != null && activePlanId.isNotEmpty;
  }

  static TrainingFlowStage allowedStage(Map<String, dynamic> extra) {
    if (!isInterviewValid(extra)) {
      return TrainingFlowStage.interview;
    }
    if (!landmarksAreCurrent(extra)) {
      return TrainingFlowStage.landmarks;
    }
    if (!isIntensityValid(extra)) {
      return TrainingFlowStage.intensity;
    }
    // ETAPA 4 (gymExercises) es OPCIONAL y NO BLOQUEANTE.
    // El motor genera plan con ejercicios default del catálogo si no hay preferencias.
    // El asesorado puede responder preferencias después desde su app para personalización.
    // El plan se regenera/ajusta cuando hay nuevas preferencias.
    return TrainingFlowStage.plan;
  }

  static String _stableValue(dynamic value) {
    if (value == null) return 'null';
    if (value is List) {
      final values = value.map(_stableValue).toList()..sort();
      return '[${values.join(',')}]';
    }
    if (value is Map) {
      final keys = value.keys.map((e) => e.toString()).toList()..sort();
      final parts = <String>[];
      for (final key in keys) {
        parts.add('$key:${_stableValue(value[key])}');
      }
      return '{${parts.join(',')}}';
    }
    return value.toString().trim();
  }
}
