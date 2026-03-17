import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/domain/training_v3/models/intensity_split.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_flow_stage.dart';
import 'package:hcs_app_lap/features/training_feature/domain/training_interview_status.dart';
import 'package:hcs_app_lap/features/training_feature/domain/training_interview_validator.dart';
import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/training_plan_config.dart';

class TrainingWorkspaceState {
  final TrainingInterviewStatus interviewStatus;
  final TrainingFlowStage flowStage;
  final IntensitySplit intensitySplit;
  final bool isIntensitySplitValid;
  final bool canGeneratePlan;
  final bool isPlanOutdated;

  const TrainingWorkspaceState({
    required this.interviewStatus,
    required this.flowStage,
    required this.intensitySplit,
    required this.isIntensitySplitValid,
    required this.canGeneratePlan,
    required this.isPlanOutdated,
  });
}

final trainingWorkspaceProvider = Provider<TrainingWorkspaceState>((ref) {
  final client = ref.watch(clientsProvider).value?.activeClient;
  final interviewStatus = evaluateTrainingInterview(client?.training.extra);
  final rawFlowStage = client
      ?.training
      .extra[TrainingExtraKeys.trainingFlowStage]
      ?.toString();
  final flowStage = TrainingFlowStageX.fromRaw(rawFlowStage);
  final rawSplit =
      client?.training.extra[TrainingExtraKeys.seriesTypePercentSplit];
  final intensitySplit = rawSplit is Map
      ? IntensitySplit.fromMap(
          rawSplit.map((key, value) => MapEntry(key.toString(), value)),
        )
      : IntensitySplit.defaultSplit;
  final isIntensitySplitValid = intensitySplit.isValid;
  final isPlanOutdated = _resolvePlanOutdatedFlag(client);

  return TrainingWorkspaceState(
    interviewStatus: interviewStatus,
    flowStage: flowStage,
    intensitySplit: intensitySplit,
    isIntensitySplitValid: isIntensitySplitValid,
    canGeneratePlan:
        interviewStatus == TrainingInterviewStatus.valid &&
        flowStage == TrainingFlowStage.plan &&
        isIntensitySplitValid,
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

  plan ??=
      (client.trainingPlans.toList()
            ..sort((a, b) => b.startDate.compareTo(a.startDate)))
          .firstOrNull;

  if (plan == null) return false;

  return client.training.hasInterviewChangedSincePlanGeneration(plan);
}
