import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:hcs_app_lap/core/registry/muscle_registry.dart'
    as muscle_registry;
import 'package:hcs_app_lap/domain/training_v3/models/training_audit_log.dart';
import 'package:hcs_app_lap/domain/training_v3/repositories/muscle_progression_repository.dart';
import 'package:hcs_app_lap/domain/training_v3/repositories/weekly_muscle_analysis_repository.dart';
import 'package:hcs_app_lap/domain/training_v3/services/weekly_feedback_collector.dart';
import 'package:hcs_app_lap/domain/training_v3/validators/training_validation_engine.dart';
import 'package:hcs_app_lap/domain/training_v3/data/exercise_catalog_v3.dart';
import 'package:hcs_app_lap/domain/training_v3/models/exercise_log.dart';
import 'package:hcs_app_lap/domain/training_v3/models/muscle_decision.dart';
import 'package:hcs_app_lap/domain/training_v3/models/muscle_progression_tracker.dart';
import 'package:hcs_app_lap/domain/training_v3/models/progress_record.dart';
import 'package:hcs_app_lap/domain/training_v3/models/feedback_entry.dart';
import 'package:hcs_app_lap/domain/training_v3/models/weekly_muscle_analysis.dart';
import 'weekly_progression_service_enhanced.dart';

/// Implementación de WeeklyProgressionServiceEnhanced con auditoría completa
class WeeklyProgressionServiceEnhancedImpl
    implements WeeklyProgressionServiceEnhanced {
  final MuscleProgressionRepository _progressionRepo;
  final WeeklyMuscleAnalysisRepository _analysisRepo;
  final TrainingValidationEngine _validator = TrainingValidationEngine();
  // final Map<String, Set<String>> _exerciseIdToMuscles = {};

  WeeklyProgressionServiceEnhancedImpl({
    required MuscleProgressionRepository progressionRepo,
    required WeeklyMuscleAnalysisRepository analysisRepo,
  }) : _progressionRepo = progressionRepo,
       _analysisRepo = analysisRepo;

  @override
  Future<EnhancedProgressionResult> processWeeklyProgressionEnhanced({
    required String userId,
    required int weekNumber,
    required DateTime weekStart,
    required DateTime weekEnd,
    required List<ExerciseLog> exerciseLogs,
    required Map<String, FeedbackEntry> feedbackByMuscle,
  }) async {
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('[EnhancedProgression] Week $weekNumber for user $userId');
    debugPrint('═══════════════════════════════════════════════════════════');

    final auditTrail = <TrainingAuditLogEntry>[];
    final decisions = <String, MuscleDecision>{};
    final progressRecords = <String, ProgressRecord>{};
    final requiresCoachAttention = <String>[];

    // 0. ENSURE CATALOG LOADED
    await ExerciseCatalogV3.ensureLoaded();

    // 1. LOAD PRE-STATE
    final allTrackers = await _progressionRepo.getAllTrackers(userId: userId);
    if (allTrackers.isEmpty) {
      throw StateError('User $userId has no trackers. Initialize first.');
    }

    // 2. PROCESS EACH MUSCLE
    for (final muscle in muscle_registry.canonicalMuscles) {
      try {
        debugPrint('');
        debugPrint('┌─────────────────────────────────────────┐');
        debugPrint('│ Processing: $muscle');
        debugPrint('└─────────────────────────────────────────┘');

        final tracker = allTrackers[muscle];
        if (tracker == null) {
          debugPrint('⚠️  No tracker found for $muscle');
          continue;
        }

        final feedback =
            feedbackByMuscle[muscle] ?? _getDefaultFeedback(muscle);

        // Get muscle-specific logs
        final muscleLogs = exerciseLogs.where((log) {
          return _isLogForMuscle(log, muscle);
        }).toList();

        // Process this muscle
        final result = await processMuscleProgressionEnhanced(
          userId: userId,
          muscle: muscle,
          weekNumber: weekNumber,
          weekStart: weekStart,
          weekEnd: weekEnd,
          exerciseLogs: muscleLogs,
          feedback: feedback,
          currentTracker: tracker,
        );

        decisions[muscle] = result.decision;
        progressRecords[muscle] = result.progressRecord;
        auditTrail.add(result.auditEntry);

        if (!result.isValid) {
          requiresCoachAttention.add(
            '$muscle: ${result.validationWarnings.join(", ")}',
          );
        }

        debugPrint('✅ Decision: ${result.decision.action.name}');
        debugPrint(
          '   Volume: ${tracker.currentVolume} → ${result.decision.newVolume}',
        );
      } catch (e, st) {
        debugPrint('❌ Error processing $muscle: $e');
        debugPrint('$st');
        requiresCoachAttention.add('$muscle: ERROR - $e');
      }
    }

    // 3. POST-WEEK VALIDATION
    debugPrint('');
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('[EnhancedProgression] Running weekly audit...');

    final auditReport = _validator.generateWeeklyAuditReport(
      userId: userId,
      weekNumber: weekNumber,
      validationResults: {}, // TODO: Pass validation results
    );

    debugPrint(auditReport);

    // 4. PERSIST AUDIT TRAIL
    // TODO: Save to Firebase via repository

    return EnhancedProgressionResult(
      decisions: decisions,
      progressRecords: progressRecords,
      auditTrail: auditTrail,
      auditReport: auditReport,
      allValid: requiresCoachAttention.isEmpty,
      requiresCoachAttention: requiresCoachAttention,
    );
  }

  @override
  Future<EnhancedMuscleDDecisionResult> processMuscleProgressionEnhanced({
    required String userId,
    required String muscle,
    required int weekNumber,
    required DateTime weekStart,
    required DateTime weekEnd,
    required List<ExerciseLog> exerciseLogs,
    required FeedbackEntry feedback,
    required MuscleProgressionTracker currentTracker,
  }) async {
    // 1. BUILD WEEKLY ANALYSIS
    final previousAnalysis = await _analysisRepo.getLatestAnalysis(
      userId: userId,
      muscle: muscle,
    );

    final analysis = WeeklyFeedbackCollector.buildAnalysis(
      muscle: muscle,
      weekNumber: weekNumber,
      weekStart: weekStart,
      weekEnd: weekEnd,
      exerciseLogs: exerciseLogs,
      prescribedSets: currentTracker.currentVolume,
      prescribedRir: 2, // Default
      previousAnalysis: previousAnalysis,
      userFeedback: feedback.toJson(),
    );

    // 2. DETERMINE ACTION BY PRIORITY
    final decision = _computeDecisionByPriority(
      muscle: muscle,
      priority: currentTracker.priority,
      currentTracker: currentTracker,
      analysis: analysis,
      feedback: feedback,
      weekNumber: weekNumber,
    );

    // 3. CREATE PROGRESS RECORD
    final progressRecord = _createProgressRecord(
      userId: userId,
      muscle: muscle,
      weekNumber: weekNumber,
      currentTracker: currentTracker,
      decision: decision,
      analysis: analysis,
      feedback: feedback,
      exerciseLogs: exerciseLogs,
    );

    // 4. VALIDATE
    final validationResult = _validator.validateProgressRecord(
      progressRecord,
      currentTracker.toScientificProgression(),
    );

    // 5. CREATE AUDIT ENTRY
    final auditEntry = _createAuditEntry(
      userId: userId,
      muscle: muscle,
      weekNumber: weekNumber,
      decision: decision,
      analysis: analysis,
      feedback: feedback,
      isValid: validationResult.isValid,
      validationErrors: validationResult.errors,
    );

    // 6. UPDATE TRACKER
    final updatedTracker = currentTracker.copyWith(
      currentVolume: decision.newVolume,
      currentPhase: decision.newPhase,
      weekInCurrentPhase: decision.newPhase == currentTracker.currentPhase
          ? currentTracker.weekInCurrentPhase + 1
          : 0,
      lastUpdated: DateTime.now(),
    );

    // Persist updated tracker
    await _progressionRepo.saveTracker(userId: userId, tracker: updatedTracker);

    return EnhancedMuscleDDecisionResult(
      decision: decision,
      progressRecord: progressRecord,
      auditEntry: auditEntry,
      isValid: validationResult.isValid,
      validationWarnings: validationResult.warnings,
    );
  }

  /// ═══════════════════════════════════════════════════════════════════
  /// PRIORITY-BASED DECISION LOGIC (CORE)
  /// ═══════════════════════════════════════════════════════════════════

  /// Computa decisión basada en PRIORIDAD
  MuscleDecision _computeDecisionByPriority({
    required String muscle,
    required int priority,
    required MuscleProgressionTracker currentTracker,
    required WeeklyMuscleAnalysis analysis,
    required FeedbackEntry feedback,
    required int weekNumber,
  }) {
    // Check for deload triggers first
    if (_shouldDeload(feedback, analysis, currentTracker, priority)) {
      return _makeDeloadDecision(
        muscle: muscle,
        currentTracker: currentTracker,
        reason: _getDeloadReason(feedback, analysis, currentTracker),
      );
    }

    // PRIMARY (5): Progresa a MRV
    if (priority == 5) {
      return _decidePrimaryProgression(
        muscle: muscle,
        currentTracker: currentTracker,
        analysis: analysis,
        feedback: feedback,
        weekNumber: weekNumber,
      );
    }

    // SECONDARY (3): Progresa a 0.8×MRV
    if (priority == 3) {
      return _decideSecondaryProgression(
        muscle: muscle,
        currentTracker: currentTracker,
        analysis: analysis,
        feedback: feedback,
        weekNumber: weekNumber,
      );
    }

    // TERTIARY (1): Siempre VOP
    if (priority == 1) {
      return _decideTertiaryProgression(
        muscle: muscle,
        currentTracker: currentTracker,
      );
    }

    // Fallback
    return MuscleDecision(
      muscle: muscle,
      action: VolumeAction.maintain,
      newVolume: currentTracker.currentVolume,
      previousVolume: currentTracker.currentVolume,
      newPhase: currentTracker.currentPhase,
      reason: 'Unknown priority level, maintaining volume',
      confidence: 0.0,
    );
  }

  /// Decisión para PRIMARIO (Priority 5)
  MuscleDecision _decidePrimaryProgression({
    required String muscle,
    required MuscleProgressionTracker currentTracker,
    required WeeklyMuscleAnalysis analysis,
    required FeedbackEntry feedback,
    required int weekNumber,
  }) {
    // Target: MRV (Maximum Recoverable Volume)
    final mrvTarget = currentTracker.landmarks.vmrTarget;
    final currentVolume = currentTracker.currentVolume;

    // Check if already at MRV
    if (currentVolume >= mrvTarget) {
      return MuscleDecision(
        muscle: muscle,
        action: VolumeAction.maintain,
        newVolume: mrvTarget,
        previousVolume: currentVolume,
        newPhase: ProgressionPhase.maintaining,
        reason: 'PRIMARY: At MRV target ($currentVolume sets). Maintaining.',
        confidence: 0.9,
      );
    }

    // Can progress?
    final performanceScore = _calculatePerformanceScore(analysis, feedback);
    if (performanceScore >= 0.7 && analysis.volumeAdherence >= 0.80) {
      // Progress
      final increment = min(2, mrvTarget - currentVolume);
      final newVolume = currentVolume + increment;

      return MuscleDecision(
        muscle: muscle,
        action: VolumeAction.increase,
        newVolume: newVolume,
        previousVolume: currentVolume,
        newPhase: ProgressionPhase.discovering,
        reason:
            'PRIMARY: Progressing (+$increment sets) toward MRV. Score: ${performanceScore.toStringAsFixed(2)}',
        confidence: 0.85,
      );
    }

    // Otherwise maintain
    return MuscleDecision(
      muscle: muscle,
      action: VolumeAction.maintain,
      newVolume: currentVolume,
      previousVolume: currentVolume,
      newPhase: ProgressionPhase.discovering,
      reason:
          'PRIMARY: Performance score insufficient for progression. Maintaining ($currentVolume sets).',
      confidence: 0.7,
    );
  }

  /// Decisión para SECUNDARIO (Priority 3)
  MuscleDecision _decideSecondaryProgression({
    required String muscle,
    required MuscleProgressionTracker currentTracker,
    required WeeklyMuscleAnalysis analysis,
    required FeedbackEntry feedback,
    required int weekNumber,
  }) {
    // Target: 0.8×MRV (Secondary cap)
    final secondaryCap = (currentTracker.landmarks.vmrTarget * 0.8).ceil();
    final currentVolume = currentTracker.currentVolume;

    if (currentVolume >= secondaryCap) {
      return MuscleDecision(
        muscle: muscle,
        action: VolumeAction.maintain,
        newVolume: secondaryCap,
        previousVolume: currentVolume,
        newPhase: ProgressionPhase.maintaining,
        reason: 'SECONDARY: At 0.8×MRV cap ($secondaryCap sets). Maintaining.',
        confidence: 0.9,
      );
    }

    // Can progress?
    final performanceScore = _calculatePerformanceScore(analysis, feedback);
    if (performanceScore >= 0.65 && analysis.volumeAdherence >= 0.75) {
      const increment = 1; // SECONDARY: +1 set/week
      final newVolume = min(currentVolume + increment, secondaryCap);

      return MuscleDecision(
        muscle: muscle,
        action: VolumeAction.increase,
        newVolume: newVolume,
        previousVolume: currentVolume,
        newPhase: ProgressionPhase.discovering,
        reason:
            'SECONDARY: Progressing (+$increment set) toward 0.8×MRV. Score: ${performanceScore.toStringAsFixed(2)}',
        confidence: 0.80,
      );
    }

    return MuscleDecision(
      muscle: muscle,
      action: VolumeAction.maintain,
      newVolume: currentVolume,
      previousVolume: currentVolume,
      newPhase: ProgressionPhase.discovering,
      reason:
          'SECONDARY: Performance insufficient. Maintaining ($currentVolume sets).',
      confidence: 0.7,
    );
  }

  /// Decisión para TERCIARIO (Priority 1)
  MuscleDecision _decideTertiaryProgression({
    required String muscle,
    required MuscleProgressionTracker currentTracker,
  }) {
    // TERCIARIO: SIEMPRE VOP, no cambia
    return MuscleDecision(
      muscle: muscle,
      action: VolumeAction.maintain,
      newVolume: currentTracker.landmarks.vop,
      previousVolume: currentTracker.currentVolume,
      newPhase: ProgressionPhase.maintaining,
      reason:
          'TERTIARY: Fixed VOP (${currentTracker.landmarks.vop} sets). Always maintain.',
      confidence: 1.0,
    );
  }

  /// ═══════════════════════════════════════════════════════════════════
  /// DELOAD LOGIC
  /// ═══════════════════════════════════════════════════════════════════

  /// ¿Deben hacer deload?
  bool _shouldDeload(
    FeedbackEntry feedback,
    WeeklyMuscleAnalysis analysis,
    MuscleProgressionTracker currentTracker,
    int priority,
  ) {
    // Manual request (override)
    if (feedback.deloadRequested) {
      debugPrint('🔴 Deload: Manual request from user');
      return true;
    }

    // High fatigue
    if (feedback.fatigueLevel >= 8.0) {
      debugPrint('🔴 Deload: High fatigue (${feedback.fatigueLevel})');
      return true;
    }

    // Poor recovery
    if (feedback.recoveryQuality <= 4.0) {
      debugPrint('🔴 Deload: Poor recovery (${feedback.recoveryQuality})');
      return true;
    }

    // Pain or injury
    if (feedback.hasPainOrInjury) {
      debugPrint('🔴 Deload: Pain/Injury reported');
      return true;
    }

    return false;
  }

  /// Razón del deload
  String _getDeloadReason(
    FeedbackEntry feedback,
    WeeklyMuscleAnalysis analysis,
    MuscleProgressionTracker currentTracker,
  ) {
    if (feedback.deloadRequested) {
      return 'Manual request from user';
    }
    if (feedback.fatigueLevel >= 8.0) {
      return 'High fatigue (${feedback.fatigueLevel}/10)';
    }
    if (feedback.recoveryQuality <= 4.0) {
      return 'Poor recovery (${feedback.recoveryQuality}/10)';
    }
    if (feedback.hasPainOrInjury) {
      return 'Pain or injury reported';
    }
    return 'Unknown reason';
  }

  /// Make deload decision
  MuscleDecision _makeDeloadDecision({
    required String muscle,
    required MuscleProgressionTracker currentTracker,
    required String reason,
  }) {
    // Deload: -50% (go back to below VOP)
    final deloadVolume = max(
      currentTracker.landmarks.vop ~/ 2,
      currentTracker.landmarks.vme,
    );

    return MuscleDecision(
      muscle: muscle,
      action: VolumeAction.deload,
      newVolume: deloadVolume,
      previousVolume: currentTracker.currentVolume,
      newPhase: ProgressionPhase.deloading,
      reason:
          'DELOAD: $reason. Reducing ${currentTracker.currentVolume} → $deloadVolume sets.',
      confidence: 0.95,
    );
  }

  /// ═══════════════════════════════════════════════════════════════════
  /// HELPERS
  /// ═══════════════════════════════════════════════════════════════════

  double _calculatePerformanceScore(
    WeeklyMuscleAnalysis analysis,
    FeedbackEntry feedback,
  ) {
    var score = 0.0;

    // Adherence (0-1)
    score += analysis.volumeAdherence * 0.3;

    // Feedback
    score += (feedback.muscleActivation / 10.0) * 0.3;
    score += (1.0 - feedback.fatigueLevel / 10.0) * 0.2;
    score += (feedback.recoveryQuality / 10.0) * 0.2;

    return score.clamp(0.0, 1.0);
  }

  ProgressRecord _createProgressRecord({
    required String userId,
    required String muscle,
    required int weekNumber,
    required MuscleProgressionTracker currentTracker,
    required MuscleDecision decision,
    required WeeklyMuscleAnalysis analysis,
    required FeedbackEntry feedback,
    required List<ExerciseLog> exerciseLogs,
  }) {
    final volumePerformed = exerciseLogs.fold<int>(
      0,
      (sum, log) => sum + log.sets.length,
    );

    return ProgressRecord(
      userId: userId,
      muscle: muscle,
      weekNumber: weekNumber,
      volumePrescribed: currentTracker.currentVolume,
      volumePerformed: volumePerformed,
      volumeAdherence: currentTracker.currentVolume == 0
          ? 0.0
          : volumePerformed / currentTracker.currentVolume,
      ripRange: (exerciseLogs.isNotEmpty
          ? exerciseLogs
                    .map((e) => (10 - e.averageRpe).round())
                    .fold(0, (a, b) => a + b) ~/
                exerciseLogs.length
          : 2),
      ripTarget: 2,
      muscleActivation: feedback.muscleActivation,
      pumpQuality: feedback.pumpQuality,
      fatigueLevel: feedback.fatigueLevel,
      recoveryQuality: feedback.recoveryQuality,
      hadPain: feedback.hadPain,
      userComments: feedback.userComments,
      exerciseAngles: 'pending', // TODO: Extract from exercise logs
      exerciseVariations: exerciseLogs.length,
      volumeAction: decision.action.name,
      newVolume: decision.newVolume,
      progressionPhase: decision.newPhase.name,
      decisionReason: decision.reason,
      wasDeload: decision.action == VolumeAction.deload,
      deloadReason: decision.action == VolumeAction.deload
          ? decision.reason
          : '',
      recordedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  TrainingAuditLogEntry _createAuditEntry({
    required String userId,
    required String muscle,
    required int weekNumber,
    required MuscleDecision decision,
    required WeeklyMuscleAnalysis analysis,
    required FeedbackEntry feedback,
    required bool isValid,
    required List<String> validationErrors,
  }) {
    return TrainingAuditLogEntry(
      userId: userId,
      eventType: AuditEventType.weeklyProgression,
      muscleAffected: muscle,
      weekNumber: weekNumber,
      title: '${decision.action.name} | $muscle',
      description: decision.reason,
      severity: isValid ? 'info' : 'warning',
      volumeBefore: decision.previousVolume,
      volumeAfter: decision.newVolume,
      decisionReason: decision.reason,
      actorType: 'motor',
      actorDetails: 'motor_v3_enhanced',
      isValid: isValid,
      validationErrors: validationErrors,
      timestamp: DateTime.now(),
    );
  }

  bool _isLogForMuscle(ExerciseLog log, String muscle) {
    final exercise = ExerciseCatalogV3.getById(log.exerciseId);
    if (exercise == null) return false;

    // Direct match
    if (exercise.muscleKey == muscle) return true;
    if (exercise.primaryMuscles.contains(muscle)) return true;

    // Check canonical mapping if needed
    // Assuming catalog uses canonical keys as per V3
    return false;
  }

  FeedbackEntry _getDefaultFeedback(String muscle) {
    return FeedbackEntry(
      userId: '',
      muscle: muscle,
      weekNumber: 0,
      weekStart: DateTime.now(),
      weekEnd: DateTime.now(),
      muscleActivation: 5.0,
      pumpQuality: 5.0,
      fatigueLevel: 5.0,
      recoveryQuality: 5.0,
      hadPain: false,
      deloadRequested: false,
      userComments: '',
      submittedAt: DateTime.now(),
    );
  }

  @override
  Future<List<TrainingAuditLogEntry>> getWeeklyAuditTrail({
    required String userId,
    required int weekNumber,
  }) async {
    // TODO: Implement fetch from repository
    return [];
  }

  @override
  Future<String> exportTrainingHistory({
    required String userId,
    int? fromWeek,
    int? toWeek,
    String format = 'json',
  }) async {
    // TODO: Implement export logic
    return '';
  }
}
