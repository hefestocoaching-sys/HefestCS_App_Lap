import 'package:flutter/foundation.dart';
import 'dart:math';
import '../models/muscle_progression_tracker.dart';
import '../models/weekly_muscle_analysis.dart';
import '../models/muscle_decision.dart';

/// Motor de decisiones semanales adaptativas por músculo
///
/// Analiza rendimiento semanal y decide:
/// - ¿Aumentar volumen (+18-22%)?
/// - ¿Mantener volumen?
/// - ¿Microdescarga preventiva?
/// - ¿Descarga completa?
class WeeklyAdaptationEngine {
  /// Analiza un músculo y genera decisión semanal
  static MuscleDecision analyzeAndDecide({
    required MuscleProgressionTracker tracker,
    required WeeklyMuscleAnalysis analysis,
  }) {
    debugPrint('[WeeklyAdapt] =====================================');
    debugPrint('[WeeklyAdapt] Musculo: ${tracker.muscle}');
    debugPrint('[WeeklyAdapt] Prioridad: ${tracker.priority}');
    debugPrint('[WeeklyAdapt] Fase: ${tracker.currentPhase}');
    debugPrint('[WeeklyAdapt] Volumen: ${tracker.currentVolume} sets');
    debugPrint('[WeeklyAdapt] Semana en fase: ${tracker.weekInCurrentPhase}');
    debugPrint('[WeeklyAdapt] =====================================');

    // REGLA 0: TERCIARIOS nunca progresan
    if (tracker.priority == 1) {
      if (tracker.currentVolume != tracker.landmarks.vop) {
        return MuscleDecision(
          muscle: tracker.muscle,
          action: VolumeAction.adjust,
          newVolume: tracker.landmarks.vop,
          newPhase: ProgressionPhase.maintaining,
          reason: 'Terciario: mantener en VOP (${tracker.landmarks.vop} sets)',
          confidence: 1.0,
        );
      }

      return MuscleDecisionHelpers.noChange(
        muscle: tracker.muscle,
        reason: 'Terciario: VOP estable',
      );
    }

    switch (tracker.currentPhase) {
      case ProgressionPhase.discovering:
        return _handleDiscovering(tracker, analysis);
      case ProgressionPhase.maintaining:
        return _handleMaintaining(tracker, analysis);
      case ProgressionPhase.overreaching:
        return _handleOverreaching(tracker, analysis);
      case ProgressionPhase.deloading:
        return _handleDeloading(tracker, analysis);
      case ProgressionPhase.microdeload:
        return _handleMicrodeload(tracker, analysis);
    }
  }

  /// DISCOVERING: Progresion activa hacia VMR
  static MuscleDecision _handleDiscovering(
    MuscleProgressionTracker tracker,
    WeeklyMuscleAnalysis analysis,
  ) {
    final weeksProgressing = _countContinuousProgressionWeeks(tracker);
    final shouldMicrodeload =
        weeksProgressing >= 3 &&
        weeksProgressing % 3 == 0 &&
        analysis.fatigueLevel > 6.0 &&
        analysis.recoveryQuality < 8.0;

    if (shouldMicrodeload) {
      final microdeloadVolume = (tracker.currentVolume * 0.65).round();

      debugPrint('[WeeklyAdapt] MICRODESCARGA preventiva');
      debugPrint('  Semanas progresando: $weeksProgressing');
      debugPrint('  Volumen: ${tracker.currentVolume} -> $microdeloadVolume');

      return MuscleDecision(
        muscle: tracker.muscle,
        action: VolumeAction.microdeload,
        newVolume: microdeloadVolume,
        newPhase: ProgressionPhase.microdeload,
        reason: 'Microdescarga preventiva tras $weeksProgressing semanas',
        confidence: 0.8,
        requiresMicrodeload: true,
        weeksToMicrodeload: 1,
      );
    }

    final performanceScore = _calculatePerformanceScore(analysis);

    debugPrint(
      '[WeeklyAdapt] Performance score: ${performanceScore.toStringAsFixed(2)}',
    );

    final canProgress =
        performanceScore >= 0.7 &&
        analysis.loadChange >= 0.3 &&
        analysis.rirDeviation < 1.5 &&
        analysis.volumeAdherence > 0.80 &&
        analysis.recoveryQuality >= 5.5 &&
        !analysis.hadPain;

    if (canProgress) {
      final increment = _calculateAdaptiveIncrement(
        currentVolume: tracker.currentVolume,
        performanceScore: performanceScore,
        weekInPhase: tracker.weekInCurrentPhase,
      );

      final newVolume = tracker.currentVolume + increment;
      final cappedVolume = min<int>(newVolume, tracker.landmarks.vmrTarget);

      final percentIncrease = ((increment / tracker.currentVolume) * 100)
          .toStringAsFixed(0);

      debugPrint(
        '[WeeklyAdapt] PROGRESANDO: +$increment sets (+$percentIncrease%)',
      );
      debugPrint('  Nuevo volumen: ${tracker.currentVolume} -> $cappedVolume');

      if (cappedVolume < newVolume) {
        debugPrint('  Limitado a VMR target: ${tracker.landmarks.vmrTarget}');
      }

      return MuscleDecision(
        muscle: tracker.muscle,
        action: VolumeAction.increase,
        newVolume: cappedVolume,
        newPhase: ProgressionPhase.discovering,
        reason:
            'Progresion (+$increment sets, score: ${performanceScore.toStringAsFixed(2)})',
        confidence: _calculateConfidence(performanceScore),
      );
    }

    final isStagnant =
        performanceScore >= 0.5 &&
        performanceScore < 0.7 &&
        analysis.loadChange >= -0.5 &&
        analysis.loadChange <= 0.8 &&
        analysis.volumeAdherence > 0.75;

    if (isStagnant) {
      debugPrint(
        '[WeeklyAdapt] ESTANCADO: VMR descubierto en ${tracker.currentVolume}',
      );

      return MuscleDecision(
        muscle: tracker.muscle,
        action: VolumeAction.maintain,
        newVolume: tracker.currentVolume,
        newPhase: ProgressionPhase.maintaining,
        reason: 'VMR real descubierto: ${tracker.currentVolume} sets',
        confidence: 0.8,
        vmrDiscovered: tracker.currentVolume,
      );
    }

    final hasOverload =
        performanceScore < 0.5 ||
        analysis.loadChange < -1.5 ||
        analysis.rirDeviation > 2.5 ||
        analysis.volumeAdherence < 0.70 ||
        analysis.recoveryQuality < 5.0 ||
        (analysis.hadPain && analysis.fatigueLevel > 7.5);

    if (hasOverload) {
      debugPrint('[WeeklyAdapt] SOBRECARGA: -> OVERREACHING');

      return MuscleDecision(
        muscle: tracker.muscle,
        action: VolumeAction.maintain,
        newVolume: tracker.currentVolume,
        newPhase: ProgressionPhase.overreaching,
        reason:
            'Senales de sobrecarga (score: ${performanceScore.toStringAsFixed(2)})',
        confidence: 0.7,
      );
    }

    return MuscleDecisionHelpers.noChange(
      muscle: tracker.muscle,
      reason: 'Observar 1 semana mas',
    );
  }

  /// MAINTAINING: Mantener VMR hasta que decaiga
  static MuscleDecision _handleMaintaining(
    MuscleProgressionTracker tracker,
    WeeklyMuscleAnalysis analysis,
  ) {
    final performanceScore = _calculatePerformanceScore(analysis);

    final isStable =
        performanceScore >= 0.6 &&
        analysis.loadChange >= -0.5 &&
        analysis.rirDeviation < 1.5 &&
        analysis.volumeAdherence > 0.80 &&
        analysis.recoveryQuality >= 6.0;

    if (isStable) {
      debugPrint('[WeeklyAdapt] ESTABLE: Mantener en VMR');
      debugPrint('  Semanas manteniendo: ${tracker.weekInCurrentPhase + 1}');

      return MuscleDecision(
        muscle: tracker.muscle,
        action: VolumeAction.maintain,
        newVolume: tracker.currentVolume,
        newPhase: ProgressionPhase.maintaining,
        reason: 'Estable en VMR (semana ${tracker.weekInCurrentPhase + 1})',
        confidence: 0.9,
      );
    }

    final canProgressMore =
        performanceScore > 0.85 &&
        analysis.loadChange > 1.5 &&
        analysis.rirDeviation < 1.0 &&
        analysis.volumeAdherence > 0.90 &&
        analysis.recoveryQuality >= 7.5;

    if (canProgressMore) {
      final increment = (tracker.currentVolume * 0.15).round();
      final newVolume = tracker.currentVolume + max<int>(1, increment);

      debugPrint('[WeeklyAdapt] EXCEPCIONAL: Puede progresar mas');
      debugPrint('  Nuevo volumen: ${tracker.currentVolume} -> $newVolume');

      return MuscleDecision(
        muscle: tracker.muscle,
        action: VolumeAction.increase,
        newVolume: newVolume,
        newPhase: ProgressionPhase.discovering,
        reason: 'Rendimiento excepcional, +$increment sets conservador',
        confidence: 0.8,
      );
    }

    final hasDecline =
        performanceScore < 0.5 ||
        analysis.loadChange < -1.0 ||
        analysis.rirDeviation > 2.0 ||
        analysis.volumeAdherence < 0.75 ||
        analysis.recoveryQuality < 5.5;

    if (hasDecline) {
      debugPrint('[WeeklyAdapt] DECAIMIENTO: -> OVERREACHING');

      return MuscleDecision(
        muscle: tracker.muscle,
        action: VolumeAction.maintain,
        newVolume: tracker.currentVolume,
        newPhase: ProgressionPhase.overreaching,
        reason: 'Decaimiento detectado en mantenimiento',
        confidence: 0.7,
      );
    }

    return MuscleDecision(
      muscle: tracker.muscle,
      action: VolumeAction.maintain,
      newVolume: tracker.currentVolume,
      newPhase: ProgressionPhase.maintaining,
      reason: 'Continuar manteniendo',
      confidence: 0.7,
    );
  }

  /// OVERREACHING: Dar 1 semana de gracia
  static MuscleDecision _handleOverreaching(
    MuscleProgressionTracker tracker,
    WeeklyMuscleAnalysis analysis,
  ) {
    final performanceScore = _calculatePerformanceScore(analysis);

    final hasRecovered =
        performanceScore > 0.7 &&
        analysis.loadChange > 0.5 &&
        analysis.rirDeviation < 1.0 &&
        analysis.volumeAdherence > 0.85 &&
        analysis.recoveryQuality >= 6.5;

    if (hasRecovered) {
      debugPrint('[WeeklyAdapt] RECUPERADO: -> MAINTAINING');

      return MuscleDecision(
        muscle: tracker.muscle,
        action: VolumeAction.maintain,
        newVolume: tracker.currentVolume,
        newPhase: ProgressionPhase.maintaining,
        reason: 'Recuperado de overreaching',
        confidence: 0.8,
      );
    }

    if (tracker.weekInCurrentPhase == 0) {
      debugPrint('[WeeklyAdapt] Semana 1 OVERREACHING: dar 1 semana gracia');

      return MuscleDecision(
        muscle: tracker.muscle,
        action: VolumeAction.maintain,
        newVolume: tracker.currentVolume,
        newPhase: ProgressionPhase.overreaching,
        reason: 'Semana 1 overreaching: observar',
        confidence: 0.6,
      );
    }

    debugPrint('[WeeklyAdapt] Sin recuperacion: -> DELOAD');

    final deloadVolume = max<int>(
      tracker.landmarks.vme,
      (tracker.currentVolume * 0.5).round(),
    );

    return MuscleDecision(
      muscle: tracker.muscle,
      action: VolumeAction.deload,
      newVolume: deloadVolume,
      newPhase: ProgressionPhase.deloading,
      reason: 'Descarga necesaria ($deloadVolume sets)',
      confidence: 0.9,
    );
  }

  /// DELOADING: 1 semana, luego nuevo ciclo
  static MuscleDecision _handleDeloading(
    MuscleProgressionTracker tracker,
    WeeklyMuscleAnalysis analysis,
  ) {
    debugPrint('[WeeklyAdapt] Completando DELOAD -> nuevo ciclo desde VOP');

    return MuscleDecision(
      muscle: tracker.muscle,
      action: VolumeAction.increase,
      newVolume: tracker.landmarks.vop,
      newPhase: ProgressionPhase.discovering,
      reason: 'Deload completado, nuevo ciclo (${tracker.landmarks.vop} sets)',
      confidence: 1.0,
      isNewCycle: true,
    );
  }

  /// MICRODELOAD: 1 semana, luego reanudar +5%
  static MuscleDecision _handleMicrodeload(
    MuscleProgressionTracker tracker,
    WeeklyMuscleAnalysis analysis,
  ) {
    debugPrint('[WeeklyAdapt] Completando MICRODELOAD -> reanudar progresion');

    final previousVolume = _getPreviousVolumeBeforeMicrodeload(tracker);
    final resumeVolume = (previousVolume * 1.05).round();

    return MuscleDecision(
      muscle: tracker.muscle,
      action: VolumeAction.increase,
      newVolume: resumeVolume,
      newPhase: ProgressionPhase.discovering,
      reason: 'Microdescarga completada, reanudar +5%',
      confidence: 0.9,
    );
  }

  // METODOS AUXILIARES

  /// Calcula incremento adaptativo segun rendimiento
  static int _calculateAdaptiveIncrement({
    required int currentVolume,
    required double performanceScore,
    required int weekInPhase,
  }) {
    double basePercentage = 0.20;

    if (performanceScore >= 0.9) {
      basePercentage = 0.25;
    } else if (performanceScore >= 0.8) {
      basePercentage = 0.22;
    } else if (performanceScore < 0.75) {
      basePercentage = 0.15;
    }

    if (weekInPhase > 6) {
      basePercentage *= 0.8;
    }

    final increment = (currentVolume * basePercentage).round();

    return max(1, increment);
  }

  /// Calcula score general de rendimiento (0.0-1.0)
  static double _calculatePerformanceScore(WeeklyMuscleAnalysis analysis) {
    double score = 0.0;

    if (analysis.loadChange > 2.0) {
      score += 0.30;
    } else if (analysis.loadChange > 1.0) {
      score += 0.25;
    } else if (analysis.loadChange > 0.3) {
      score += 0.20;
    } else if (analysis.loadChange >= 0.0) {
      score += 0.10;
    }

    if (analysis.rirDeviation < 0.5) {
      score += 0.20;
    } else if (analysis.rirDeviation < 1.0) {
      score += 0.15;
    } else if (analysis.rirDeviation < 1.5) {
      score += 0.10;
    }

    if (analysis.volumeAdherence > 0.95) {
      score += 0.20;
    } else if (analysis.volumeAdherence > 0.85) {
      score += 0.15;
    } else if (analysis.volumeAdherence > 0.75) {
      score += 0.10;
    }

    if (analysis.recoveryQuality >= 8.0) {
      score += 0.15;
    } else if (analysis.recoveryQuality >= 6.5) {
      score += 0.10;
    } else if (analysis.recoveryQuality >= 5.5) {
      score += 0.05;
    }

    if (analysis.fatigueLevel < 5.0) {
      score += 0.10;
    } else if (analysis.fatigueLevel < 6.5) {
      score += 0.07;
    } else if (analysis.fatigueLevel < 8.0) {
      score += 0.03;
    }

    if (analysis.muscleActivation >= 8.0) {
      score += 0.05;
    } else if (analysis.muscleActivation >= 7.0) {
      score += 0.03;
    }

    return score.clamp(0.0, 1.0);
  }

  static double _calculateConfidence(double performanceScore) {
    if (performanceScore >= 0.9) return 1.0;
    if (performanceScore >= 0.8) return 0.9;
    if (performanceScore >= 0.7) return 0.8;
    return 0.7;
  }

  static int _countContinuousProgressionWeeks(
    MuscleProgressionTracker tracker,
  ) {
    int count = 0;

    for (int i = tracker.history.length - 1; i >= 0; i--) {
      final week = tracker.history[i];

      if (i > 0 && week.volume > tracker.history[i - 1].volume) {
        count++;
      } else {
        break;
      }
    }

    return count + tracker.weekInCurrentPhase;
  }

  static int _getPreviousVolumeBeforeMicrodeload(
    MuscleProgressionTracker tracker,
  ) {
    for (int i = tracker.phaseTimeline.length - 1; i >= 0; i--) {
      final transition = tracker.phaseTimeline[i];
      if (transition.toPhase == ProgressionPhase.microdeload) {
        return transition.volume;
      }
    }

    return tracker.currentVolume;
  }
}
