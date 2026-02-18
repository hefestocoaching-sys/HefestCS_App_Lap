import 'dart:math';

import 'package:hcs_app_lap/domain/training_v3/models/muscle_decision.dart';
import 'package:hcs_app_lap/domain/training_v3/models/muscle_progression_tracker.dart';
import 'package:hcs_app_lap/domain/training_v3/models/weekly_muscle_analysis.dart';
import 'package:hcs_app_lap/domain/training_v3/models/feedback_entry.dart';

/// Motor de decisiones puro para el ajuste de volumen semanal (Motor V3).
///
/// Encapsula exclusivamente las reglas de negocio para determinar si se debe
/// aumentar, mantener o reducir el volumen (o hacer deload) basado en:
/// - Prioridad del músculo (1, 3, 5).
/// - Feedback del usuario (RPE, fatiga, etc.).
/// - Adherencia y rendimiento de la semana anterior.
class VolumeDecisionEngine {
  /// Computa la decisión de ajuste de volumen basada en la PRIORIDAD del músculo.
  MuscleDecision computeDecisionByPriority({
    required String muscle,
    required int priority,
    required MuscleProgressionTracker currentTracker,
    required WeeklyMuscleAnalysis analysis,
    required FeedbackEntry feedback,
    required int weekNumber,
  }) {
    // 1. Chequeo de Deload primero (seguridad ante todo)
    if (_shouldDeload(feedback)) {
      return _makeDeloadDecision(
        muscle: muscle,
        currentTracker: currentTracker,
        reason: _getDeloadReason(feedback),
      );
    }

    // 2. Lógica por Prioridad
    switch (priority) {
      case 5: // PRIMARIO: Progresa hasta MRV
        return _decidePrimaryProgression(
          muscle: muscle,
          currentTracker: currentTracker,
          analysis: analysis,
          feedback: feedback,
        );
      case 3: // SECUNDARIO: Progresa hasta 0.8 x MRV
        return _decideSecondaryProgression(
          muscle: muscle,
          currentTracker: currentTracker,
          analysis: analysis,
          feedback: feedback,
        );
      case 1: // TERCIARIO: Mantenimiento estricto (VOP)
        return _decideTertiaryProgression(
          muscle: muscle,
          currentTracker: currentTracker,
        );
      default:
        // Fallback seguro
        return MuscleDecision(
          muscle: muscle,
          action: VolumeAction.maintain,
          newVolume: currentTracker.currentVolume,
          previousVolume: currentTracker.currentVolume,
          newPhase: currentTracker.currentPhase,
          reason: 'Unknown priority level ($priority), maintaining volume',
          confidence: 0.0,
        );
    }
  }

  /// --------------------------------------------------------------------------
  /// REGLAS POR PRIORIDAD
  /// --------------------------------------------------------------------------

  /// Decisión para PRIORIDAD 5 (Primario)
  /// Objetivo: Maximizar ganancias, empujar hacia MRV si la recuperación lo permite.
  MuscleDecision _decidePrimaryProgression({
    required String muscle,
    required MuscleProgressionTracker currentTracker,
    required WeeklyMuscleAnalysis analysis,
    required FeedbackEntry feedback,
  }) {
    // Target: MRV (Maximum Recoverable Volume)
    final mrvTarget = currentTracker.landmarks.vmrTarget;
    final currentVolume = currentTracker.currentVolume;

    // Check caps
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
    final performanceScore = calculatePerformanceScore(analysis, feedback);

    // Regla V3: Adherencia alta (>80%) y Score decente (>0.7)
    if (performanceScore >= 0.7 && analysis.volumeAdherence >= 0.80) {
      // Incremento: +1 o +2 sets, sin pasar MRV
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
          'PRIMARY: Performance score insufficient for progression. Maintaining.',
      confidence: 0.7,
    );
  }

  /// Decisión para PRIORIDAD 3 (Secundario)
  /// Objetivo: Progreso moderado, capado al 80% del MRV para no interferir con primarios.
  MuscleDecision _decideSecondaryProgression({
    required String muscle,
    required MuscleProgressionTracker currentTracker,
    required WeeklyMuscleAnalysis analysis,
    required FeedbackEntry feedback,
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
    final performanceScore = calculatePerformanceScore(analysis, feedback);

    // Regla V3 Secundarios: Requieren score un poco mas bajo (0.65) pero igual buena adherencia
    if (performanceScore >= 0.65 && analysis.volumeAdherence >= 0.75) {
      const increment = 1; // SECONDARY: Max +1 set/week
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
      reason: 'SECONDARY: Performance insufficient. Maintaining.',
      confidence: 0.7,
    );
  }

  /// Decisión para PRIORIDAD 1 (Terciario)
  /// Objetivo: Mantenimiento puro (VOP/MV). No gastar recursos de recuperación.
  MuscleDecision _decideTertiaryProgression({
    required String muscle,
    required MuscleProgressionTracker currentTracker,
  }) {
    return MuscleDecision(
      muscle: muscle,
      action: VolumeAction.maintain,
      newVolume: currentTracker
          .landmarks
          .vop, // Mantiene VOP (Volumen Óptimo de Progreso/Mantenimiento)
      previousVolume: currentTracker.currentVolume,
      newPhase: ProgressionPhase.maintaining,
      reason:
          'TERTIARY: Fixed VOP (${currentTracker.landmarks.vop} sets). Always maintain.',
      confidence: 1.0,
    );
  }

  /// --------------------------------------------------------------------------
  /// LÓGICA DE DELOAD
  /// --------------------------------------------------------------------------

  bool _shouldDeload(FeedbackEntry feedback) {
    if (feedback.deloadRequested) return true;
    if (feedback.fatigueLevel >= 8.0) return true;
    if (feedback.recoveryQuality <= 4.0) return true;
    if (feedback.hasPainOrInjury) return true;
    return false;
  }

  String _getDeloadReason(FeedbackEntry feedback) {
    if (feedback.deloadRequested) return 'Manual request from user';
    if (feedback.fatigueLevel >= 8.0) {
      return 'High fatigue (${feedback.fatigueLevel}/10)';
    }
    if (feedback.recoveryQuality <= 4.0) {
      return 'Poor recovery (${feedback.recoveryQuality}/10)';
    }
    if (feedback.hasPainOrInjury) return 'Pain or injury reported';
    return 'Unknown reason';
  }

  MuscleDecision _makeDeloadDecision({
    required String muscle,
    required MuscleProgressionTracker currentTracker,
    required String reason,
  }) {
    // Deload: Reducir al 50% del VOP o al VME (Volumen Mínimo Efectivo), lo que sea mayor.
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

  /// --------------------------------------------------------------------------
  /// METRICAS AUXILIARES
  /// --------------------------------------------------------------------------

  /// Calcula score unificado (0.0 - 1.0) combinando métricas objetivas y subjetivas
  double calculatePerformanceScore(
    WeeklyMuscleAnalysis analysis,
    FeedbackEntry feedback,
  ) {
    var score = 0.0;

    // Adherence (30%)
    score += analysis.volumeAdherence * 0.3;

    // Feedback Subjetivo (70%)
    // - Activation: más es mejor
    score += (feedback.muscleActivation / 10.0) * 0.3;
    // - Fatigue: menos es mejor
    score += (1.0 - feedback.fatigueLevel / 10.0) * 0.2;
    // - Recovery: más es mejor
    score += (feedback.recoveryQuality / 10.0) * 0.2;

    return score.clamp(0.0, 1.0);
  }
}
