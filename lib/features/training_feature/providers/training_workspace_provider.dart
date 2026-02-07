import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/features/training_feature/domain/training_interview_status.dart';
import 'package:hcs_app_lap/features/training_feature/domain/training_interview_validator.dart';
import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/training_plan_config.dart';

class TrainingWorkspaceState {
  final TrainingInterviewStatus interviewStatus;
  final bool canGeneratePlan;
  final bool isPlanOutdated;

  const TrainingWorkspaceState({
    required this.interviewStatus,
    required this.canGeneratePlan,
    required this.isPlanOutdated,
  });
}

final trainingWorkspaceProvider = Provider<TrainingWorkspaceState>((ref) {
  final client = ref.watch(clientsProvider).value?.activeClient;
  final interviewStatus = evaluateTrainingInterview(client?.training.extra);
  final isPlanOutdated = _resolvePlanOutdatedFlag(client);

  return TrainingWorkspaceState(
    interviewStatus: interviewStatus,
    canGeneratePlan: interviewStatus == TrainingInterviewStatus.valid,
    isPlanOutdated: isPlanOutdated,
  );
});

bool _resolvePlanOutdatedFlag(Client? client) {
  if (client == null || client.trainingPlans.isEmpty) {
    return false;
  }

  final activePlanId =
      client.training.extra[TrainingExtraKeys.activePlanId]?.toString();
  TrainingPlanConfig? plan;

  if (activePlanId != null && activePlanId.isNotEmpty) {
    try {
      plan = client.trainingPlans.firstWhere((p) => p.id == activePlanId);
    } on StateError {
      plan = null;
    }
  }

  plan ??=
      (client.trainingPlans.toList()
            ..sort((a, b) => b.startDate.compareTo(a.startDate)))
          .first;

  return client.training.hasInterviewChangedSincePlanGeneration(plan);
}
