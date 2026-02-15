import 'package:flutter/foundation.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/domain/entities/training_plan_config.dart';
import 'package:hcs_app_lap/domain/training_v3/models/exercise_log.dart';
import 'package:hcs_app_lap/domain/training_v3/models/muscle_decision.dart';
import 'package:hcs_app_lap/domain/training_v3/models/muscle_progression_tracker.dart';
import 'package:hcs_app_lap/domain/training_v3/orchestrator/training_orchestrator_v3.dart';
import 'package:hcs_app_lap/domain/training_v3/ml/strategies/rule_based_strategy.dart';
import 'package:hcs_app_lap/domain/training_v3/repositories/muscle_progression_repository.dart';
import 'package:hcs_app_lap/domain/training_v3/services/weekly_progression_service.dart';

/// Unified service that combines initial generation and weekly adaptation.
class UnifiedTrainingService {
  final MuscleProgressionRepository _progressionRepo;
  final WeeklyProgressionService _weeklyProgression;

  UnifiedTrainingService({
    required MuscleProgressionRepository progressionRepo,
    required WeeklyProgressionService weeklyProgression,
  }) : _progressionRepo = progressionRepo,
       _weeklyProgression = weeklyProgression;

  /// Generates the initial program and initializes trackers.
  Future<UnifiedTrainingResult> generateFullProgram({
    required Client client,
    required List<Exercise> exercises,
    DateTime? startDate,
  }) async {
    try {
      debugPrint('=== [UnifiedTraining] Start full program generation');

      final orchestrator = TrainingOrchestratorV3(
        strategy: RuleBasedStrategy(),
      );

      final week1Result = await orchestrator.generatePlan(
        client: client,
        exercises: exercises,
        asOfDate: startDate ?? DateTime.now(),
      );

      if (week1Result.isBlocked) {
        debugPrint(
          '[UnifiedTraining] Plan blocked: ${week1Result.blockReason}',
        );
        return UnifiedTrainingResult.blocked(
          reason: week1Result.blockReason ?? 'Plan blocked',
          suggestions: week1Result.suggestions,
        );
      }

      final week1Plan = week1Result.plan;
      if (week1Plan == null) {
        return UnifiedTrainingResult.blocked(
          reason: 'Plan generation failed: no plan returned',
        );
      }

      final volumeTargets = week1Plan.volumePerMuscle ?? {};
      if (volumeTargets.isEmpty) {
        throw StateError('Plan generated without volumePerMuscle');
      }

      final musclePriorities = <String, int>{};
      for (final entry in volumeTargets.entries) {
        final muscle = entry.key;
        final volume = entry.value;

        if (volume >= 16) {
          musclePriorities[muscle] = 5;
        } else if (volume >= 10) {
          musclePriorities[muscle] = 3;
        } else {
          musclePriorities[muscle] = 1;
        }
      }

      await _progressionRepo.initializeAllTrackers(
        userId: client.id,
        musclePriorities: musclePriorities,
        trainingLevel:
            client.trainingEvaluation?.experienceLevel ??
            client.training.trainingLevel?.name ??
            'intermediate',
        age: client.profile.age ?? 30,
      );

      final initialTrackers = await _progressionRepo.getAllTrackers(
        userId: client.id,
      );

      debugPrint('[UnifiedTraining] Generation complete');

      return UnifiedTrainingResult.success(
        initialWeekPlan: week1Plan,
        initialTrackers: initialTrackers,
      );
    } catch (e, stackTrace) {
      debugPrint('[UnifiedTraining] Error: $e');
      debugPrint('Stack: $stackTrace');
      return UnifiedTrainingResult.blocked(
        reason: 'Error generating program: $e',
      );
    }
  }

  /// Processes the completed week and returns adaptation decisions.
  Future<AdaptiveWeekResult> processCompletedWeek({
    required String userId,
    required int weekNumber,
    required DateTime weekStart,
    required DateTime weekEnd,
    required List<ExerciseLog> exerciseLogs,
    required Map<String, Map<String, dynamic>> userFeedback,
    required Client client,
    required List<Exercise> exercises,
    TrainingPlanConfig? previousWeekPlan,
  }) async {
    try {
      debugPrint('=== [UnifiedTraining] Process week $weekNumber');

      final decisions = await _weeklyProgression.processWeeklyProgression(
        userId: userId,
        weekNumber: weekNumber,
        weekStart: weekStart,
        weekEnd: weekEnd,
        exerciseLogs: exerciseLogs,
        userFeedbackByMuscle: userFeedback,
      );

      final adjustedVolumes = <String, int>{};
      for (final entry in decisions.entries) {
        adjustedVolumes[entry.key] = entry.value.newVolume;
      }

      debugPrint('[UnifiedTraining] Adjusted volumes: $adjustedVolumes');

      final updatedTrackers = await _progressionRepo.getAllTrackers(
        userId: userId,
      );

      return AdaptiveWeekResult.success(
        decisions: decisions,
        nextWeekPlan: null,
        updatedTrackers: updatedTrackers,
      );
    } catch (e, stackTrace) {
      debugPrint('[UnifiedTraining] Error processing week: $e');
      debugPrint('Stack: $stackTrace');
      return AdaptiveWeekResult.blocked(reason: 'Error processing week: $e');
    }
  }
}

class UnifiedTrainingResult {
  final TrainingPlanConfig? initialWeekPlan;
  final Map<String, MuscleProgressionTracker>? initialTrackers;
  final String? blockReason;
  final List<String>? suggestions;

  UnifiedTrainingResult.success({
    required this.initialWeekPlan,
    required this.initialTrackers,
  }) : blockReason = null,
       suggestions = null;

  UnifiedTrainingResult.blocked({required String reason, this.suggestions})
    : initialWeekPlan = null,
      initialTrackers = null,
      blockReason = reason;

  bool get isBlocked => blockReason != null;
  bool get isSuccess => !isBlocked;
}

class AdaptiveWeekResult {
  final Map<String, MuscleDecision>? decisions;
  final TrainingPlanConfig? nextWeekPlan;
  final Map<String, MuscleProgressionTracker>? updatedTrackers;
  final String? blockReason;

  AdaptiveWeekResult.success({
    required this.decisions,
    required this.nextWeekPlan,
    required this.updatedTrackers,
  }) : blockReason = null;

  AdaptiveWeekResult.blocked({required String reason})
    : decisions = null,
      nextWeekPlan = null,
      updatedTrackers = null,
      blockReason = reason;

  bool get isBlocked => blockReason != null;
  bool get isSuccess => !isBlocked;
}
