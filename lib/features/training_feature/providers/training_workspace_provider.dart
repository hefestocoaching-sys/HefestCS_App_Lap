import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/domain/training_v3/models/intensity_split.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_flow_stage.dart';
import 'package:hcs_app_lap/features/training_feature/domain/training_interview_status.dart';
import 'package:hcs_app_lap/features/training_feature/domain/training_interview_validator.dart';
import 'package:hcs_app_lap/features/training_feature/domain/training_pipeline_guard.dart';
import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/training_plan_config.dart';

class TrainingWorkspaceState {
  final TrainingInterviewStatus interviewStatus;
  final TrainingFlowStage flowStage;
  final IntensitySplit intensitySplit;
  final bool isIntensitySplitValid;
  final bool landmarksAreCurrent;
  final bool canAccessLandmarks;
  final bool canAccessIntensity;
  final bool canAccessGymExercises;
  final bool canGeneratePlan;
  final bool hasPlan;
  final bool isPlanOutdated;

  const TrainingWorkspaceState({
    this.interviewStatus = TrainingInterviewStatus.empty,
    this.flowStage = TrainingFlowStage.interview,
    this.intensitySplit = IntensitySplit.defaultSplit,
    this.isIntensitySplitValid = false,
    this.landmarksAreCurrent = false,
    this.canAccessLandmarks = false,
    this.canAccessIntensity = false,
    this.canAccessGymExercises = false,
    this.canGeneratePlan = false,
    this.hasPlan = false,
    this.isPlanOutdated = false,
  });
}

final trainingWorkspaceProvider = Provider<TrainingWorkspaceState>((ref) {
  final client = ref.watch(clientsProvider).value?.activeClient;
  final extra = client?.training.extra ?? const <String, dynamic>{};
  final interviewStatus = evaluateTrainingInterview(client?.training.extra);
  final interviewIsValid = interviewStatus == TrainingInterviewStatus.valid;
  final rawFlowStage = extra[TrainingExtraKeys.trainingFlowStage]?.toString();
  final persistedFlowStage = TrainingFlowStageX.fromRaw(rawFlowStage);
  final allowedStage = TrainingPipelineGuard.allowedStage(extra);
  final flowStage = TrainingFlowStageX.min(persistedFlowStage, allowedStage);
  final rawSplit = extra[TrainingExtraKeys.seriesTypePercentSplit];
  final intensitySplit = rawSplit is Map
      ? IntensitySplit.fromMap(
          rawSplit.map((key, value) => MapEntry(key.toString(), value)),
        )
      : IntensitySplit.defaultSplit;
  final isIntensitySplitValid =
      intensitySplit.isValid && TrainingPipelineGuard.isIntensityValid(extra);
  // En flujo activo, esta bandera depende de landmarks SSOT vigentes.
  final landmarksAreCurrent = TrainingPipelineGuard.landmarksAreCurrent(extra);
  final canAccessLandmarks = interviewIsValid;
  final canAccessIntensity = interviewIsValid && landmarksAreCurrent;
  final canAccessGymExercises = canAccessIntensity && isIntensitySplitValid;
  // GymExercises es OPCIONAL y NO BLOQUEANTE.
  // El plan se genera sin esperar preferencias de ejercicios del asesor.
  // El asesorado responde preferencias en su app para personalización posterior.
  final canGeneratePlan = canAccessGymExercises;
  final hasPlan = TrainingPipelineGuard.hasPlan(extra);
  final isPlanOutdated = _resolvePlanOutdatedFlag(client);

  return TrainingWorkspaceState(
    interviewStatus: interviewStatus,
    flowStage: flowStage,
    intensitySplit: intensitySplit,
    isIntensitySplitValid: isIntensitySplitValid,
    landmarksAreCurrent: landmarksAreCurrent,
    canAccessLandmarks: canAccessLandmarks,
    canAccessIntensity: canAccessIntensity,
    canAccessGymExercises: canAccessGymExercises,
    canGeneratePlan: canGeneratePlan,
    hasPlan: hasPlan,
    isPlanOutdated: isPlanOutdated,
  );
});

bool _resolvePlanOutdatedFlag(Client? client) {
  if (client == null || client.trainingPlans.isEmpty) {
    return false;
  }

  final activePlanId = client.training.extra[TrainingExtraKeys.activePlanId]
      ?.toString();
  TrainingPlanConfig? plan;

  if (activePlanId != null && activePlanId.isNotEmpty) {
    plan = client.trainingPlans.where((p) => p.id == activePlanId).firstOrNull;
  }

  if (plan == null) return false;

  return client.training.hasInterviewChangedSincePlanGeneration(plan);
}
