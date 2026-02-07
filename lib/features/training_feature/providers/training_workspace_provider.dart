import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/features/training_feature/domain/training_interview_status.dart';
import 'package:hcs_app_lap/features/training_feature/domain/training_interview_validator.dart';

class TrainingWorkspaceState {
  final TrainingInterviewStatus interviewStatus;
  final bool canGeneratePlan;

  const TrainingWorkspaceState({
    required this.interviewStatus,
    required this.canGeneratePlan,
  });
}

final trainingWorkspaceProvider = Provider<TrainingWorkspaceState>((ref) {
  final client = ref.watch(clientsProvider).value?.activeClient;
  final interviewStatus = evaluateTrainingInterview(client?.training.extra);

  return TrainingWorkspaceState(
    interviewStatus: interviewStatus,
    canGeneratePlan: interviewStatus == TrainingInterviewStatus.valid,
  );
});
