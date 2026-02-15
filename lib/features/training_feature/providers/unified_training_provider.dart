import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/domain/entities/training_plan_config.dart';
import 'package:hcs_app_lap/domain/training_v3/models/exercise_log.dart';
import 'package:hcs_app_lap/domain/training_v3/models/muscle_decision.dart';
import 'package:hcs_app_lap/domain/training_v3/models/muscle_progression_tracker.dart';
import 'package:hcs_app_lap/domain/training_v3/services/unified_training_service.dart';
import 'package:hcs_app_lap/domain/training_v3/services/weekly_progression_service_impl.dart';
import 'package:hcs_app_lap/features/training_feature/providers/muscle_progression_tracker_provider.dart';

final unifiedTrainingServiceProvider = Provider<UnifiedTrainingService>((ref) {
  final progressionRepo = ref.watch(muscleProgressionRepositoryProvider);
  final analysisRepo = ref.watch(weeklyMuscleAnalysisRepositoryProvider);

  final weeklyProgression = WeeklyProgressionServiceImpl(
    progressionRepo: progressionRepo,
    analysisRepo: analysisRepo,
  );

  return UnifiedTrainingService(
    progressionRepo: progressionRepo,
    weeklyProgression: weeklyProgression,
  );
});

final unifiedTrainingProvider =
    NotifierProvider<UnifiedTrainingNotifier, UnifiedTrainingState>(
      UnifiedTrainingNotifier.new,
    );

class UnifiedTrainingNotifier extends Notifier<UnifiedTrainingState> {
  @override
  UnifiedTrainingState build() => UnifiedTrainingState.initial();

  Future<void> generateProgram({
    required Client client,
    required List<Exercise> exercises,
    DateTime? startDate,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final service = ref.read(unifiedTrainingServiceProvider);
      final result = await service.generateFullProgram(
        client: client,
        exercises: exercises,
        startDate: startDate,
      );

      if (result.isBlocked) {
        state = state.copyWith(isLoading: false, error: result.blockReason);
        return;
      }

      state = state.copyWith(
        isLoading: false,
        initialWeekPlan: result.initialWeekPlan,
        trackers: result.initialTrackers,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> processWeekFeedback({
    required String userId,
    required int weekNumber,
    required DateTime weekStart,
    required DateTime weekEnd,
    required List<ExerciseLog> exerciseLogs,
    required Map<String, Map<String, dynamic>> userFeedback,
    required Client client,
    required List<Exercise> exercises,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final service = ref.read(unifiedTrainingServiceProvider);
      final result = await service.processCompletedWeek(
        userId: userId,
        weekNumber: weekNumber,
        weekStart: weekStart,
        weekEnd: weekEnd,
        exerciseLogs: exerciseLogs,
        userFeedback: userFeedback,
        client: client,
        exercises: exercises,
        previousWeekPlan: state.initialWeekPlan,
      );

      if (result.isBlocked) {
        state = state.copyWith(isLoading: false, error: result.blockReason);
        return;
      }

      state = state.copyWith(
        isLoading: false,
        lastDecisions: result.decisions,
        trackers: result.updatedTrackers,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

class UnifiedTrainingState {
  final bool isLoading;
  final String? error;
  final TrainingPlanConfig? initialWeekPlan;
  final Map<String, MuscleProgressionTracker>? trackers;
  final Map<String, MuscleDecision>? lastDecisions;

  UnifiedTrainingState({
    required this.isLoading,
    this.error,
    this.initialWeekPlan,
    this.trackers,
    this.lastDecisions,
  });

  factory UnifiedTrainingState.initial() {
    return UnifiedTrainingState(isLoading: false);
  }

  UnifiedTrainingState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    TrainingPlanConfig? initialWeekPlan,
    Map<String, MuscleProgressionTracker>? trackers,
    Map<String, MuscleDecision>? lastDecisions,
  }) {
    return UnifiedTrainingState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      initialWeekPlan: initialWeekPlan ?? this.initialWeekPlan,
      trackers: trackers ?? this.trackers,
      lastDecisions: lastDecisions ?? this.lastDecisions,
    );
  }
}
