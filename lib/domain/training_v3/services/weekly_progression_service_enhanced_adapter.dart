import 'package:flutter/foundation.dart';
import 'package:hcs_app_lap/domain/training_v3/models/exercise_log.dart';
import 'package:hcs_app_lap/domain/training_v3/models/muscle_decision.dart';
import 'package:hcs_app_lap/domain/training_v3/models/muscle_progression_tracker.dart';
import 'package:hcs_app_lap/domain/training_v3/models/feedback_entry.dart';
import 'package:hcs_app_lap/domain/training_v3/services/weekly_progression_service.dart';
import 'package:hcs_app_lap/domain/training_v3/services/weekly_progression_service_enhanced.dart';

/// Adaptador para usar el Motor V3 Enhanced (Fase 1) con la interfaz Legacy.
///
/// Este adaptador permite conectar `UnifiedTrainingService` (que espera la interfaz vieja)
/// con `WeeklyProgressionServiceEnhanced` (que tiene la nueva lógica P/S/T y auditoría).
class WeeklyProgressionServiceEnhancedAdapter
    implements WeeklyProgressionService {
  final WeeklyProgressionServiceEnhanced _enhancedService;

  WeeklyProgressionServiceEnhancedAdapter(this._enhancedService);

  @override
  Future<Map<String, MuscleDecision>> processWeeklyProgression({
    required String userId,
    required int weekNumber,
    required DateTime weekStart,
    required DateTime weekEnd,
    required List<ExerciseLog> exerciseLogs,
    required Map<String, Map<String, dynamic>> userFeedbackByMuscle,
  }) async {
    debugPrint(
      '[EnhancedAdapter] Processing week $weekNumber via Enhanced Service',
    );

    // 1. Convertir feedback legacy (Map) a FeedbackEntry (Modelo Nuevo)
    final feedbackEntries = <String, FeedbackEntry>{};
    userFeedbackByMuscle.forEach((muscle, data) {
      try {
        feedbackEntries[muscle] = FeedbackEntry(
          userId: userId,
          muscle: muscle,
          weekNumber: weekNumber,
          weekStart: weekStart,
          weekEnd: weekEnd,
          muscleActivation:
              (data['muscle_activation'] as num?)?.toDouble() ?? 5.0,
          pumpQuality: (data['pump_quality'] as num?)?.toDouble() ?? 5.0,
          fatigueLevel: (data['fatigue_level'] as num?)?.toDouble() ?? 5.0,
          recoveryQuality:
              (data['recovery_quality'] as num?)?.toDouble() ?? 5.0,
          hadPain: data['had_pain'] as bool? ?? false,
          deloadRequested: data['deload_requested'] as bool? ?? false,
          userComments: data['comments'] as String? ?? '',
          submittedAt: DateTime.now(),
        );
      } catch (e) {
        debugPrint('[EnhancedAdapter] Error parsing feedback for $muscle: $e');
        // Usar default si falla
      }
    });

    // 2. Llamar al servicio Enhanced
    final result = await _enhancedService.processWeeklyProgressionEnhanced(
      userId: userId,
      weekNumber: weekNumber,
      weekStart: weekStart,
      weekEnd: weekEnd,
      exerciseLogs: exerciseLogs,
      feedbackByMuscle: feedbackEntries,
    );

    // 3. Loguear reporte de auditoría (para debug)
    debugPrint('[EnhancedAdapter] Validation Report:\n${result.auditReport}');

    if (!result.allValid) {
      debugPrint('[EnhancedAdapter] ⚠️ WARNINGS DETECTED:');
      for (final warning in result.requiresCoachAttention) {
        debugPrint('  - $warning');
      }
    }

    // 4. Retornar decisiones (compatible con interfaz legacy)
    return result.decisions;
  }

  @override
  Future<MuscleDecision> processMuscleProgression({
    required String userId,
    required String muscle,
    required int weekNumber,
    required DateTime weekStart,
    required DateTime weekEnd,
    required List<ExerciseLog> exerciseLogs,
    required int prescribedSets,
    required int prescribedRir,
    required Map<String, dynamic> userFeedback,
  }) async {
    final decisions = await processWeeklyProgression(
      userId: userId,
      weekNumber: weekNumber,
      weekStart: weekStart,
      weekEnd: weekEnd,
      exerciseLogs: exerciseLogs,
      userFeedbackByMuscle: {muscle: userFeedback},
    );

    final decision = decisions[muscle];
    if (decision != null) {
      return decision;
    }

    return MuscleDecisionHelpers.noChange(
      muscle: muscle,
      reason: 'Adapter fallback: no decision generated for muscle',
      currentVolume: prescribedSets,
    );
  }

  @override
  Future<Map<String, dynamic>> getProgressionSummary({
    required String userId,
    int lastWeeks = 4,
  }) async {
    // Provisorio: usar export del enhanced service si soporta json
    final jsonString = await _enhancedService.exportTrainingHistory(
      userId: userId,
    );
    return {'status': 'managed_by_enhanced_service', 'raw_export': jsonString};
  }

  @override
  MuscleProgressionTracker applyDecisionToTracker({
    required MuscleProgressionTracker tracker,
    required MuscleDecision decision,
    required int weekNumber,
  }) {
    // El servicio Enhanced ya guarda los cambios en el repositorio internamente.
    // Este método es solo un helper utilitario en el legacy.
    // Lo replicamos "in-memory" por si alguien lo usa, pero no persiste.
    return tracker.copyWith(
      currentVolume: decision.newVolume,
      currentPhase: decision.newPhase,
      weekInCurrentPhase: decision.newPhase == tracker.currentPhase
          ? tracker.weekInCurrentPhase + 1
          : 0,
    );
  }
}
