import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/muscle_decision.dart';
import '../models/muscle_progression_tracker.dart';
import '../models/weekly_muscle_analysis.dart';

/// Weekly per-muscle decision engine.
class WeeklyAdaptationEngine {
  static MuscleDecision analyzeAndDecide({
    required MuscleProgressionTracker tracker,
    required WeeklyMuscleAnalysis analysis,
  }) {
    debugPrint('[WeeklyAdapt] =======================================');
    debugPrint('[WeeklyAdapt] Muscle: ${tracker.muscle}');
    debugPrint('[WeeklyAdapt] Priority: ${tracker.priority}');
    debugPrint('[WeeklyAdapt] Phase: ${tracker.currentPhase}');
    debugPrint('[WeeklyAdapt] Volume: ${tracker.currentVolume} sets');
    debugPrint('[WeeklyAdapt] Week in phase: ${tracker.weekInCurrentPhase}');
    debugPrint('[WeeklyAdapt] =======================================');

    if (tracker.priority == 1) {
      if (tracker.currentVolume != tracker.landmarks.vop) {
        return MuscleDecision(
          muscle: tracker.muscle,
          action: VolumeAction.adjust,
          newVolume: tracker.landmarks.vop,
          newPhase: ProgressionPhase.maintaining,
          reason: 'Tertiary: keep at VOP',
          confidence: 1.0,
        );
      }

      return MuscleDecision.noChange(
        muscle: tracker.muscle,
        reason: 'Tertiary: keep VOP',
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

      debugPrint('[WeeklyAdapt] MICRODELOAD preventive');
      debugPrint('  Weeks progressing: $weeksProgressing');
      debugPrint('  Volume: ${tracker.currentVolume} -> $microdeloadVolume');

      return MuscleDecision(
        muscle: tracker.muscle,
        action: VolumeAction.microdeload,
        newVolume: microdeloadVolume,
        newPhase: ProgressionPhase.microdeload,
        reason: 'Preventive microdeload (week $weeksProgressing)',
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
      final cappedVolume = min(newVolume, tracker.landmarks.vmrTarget);

      debugPrint(
        '[WeeklyAdapt] PROGRESSING: +$increment sets (+${((increment / tracker.currentVolume) * 100).toStringAsFixed(0)}%)',
      );
      debugPrint('  New volume: ${tracker.currentVolume} -> $cappedVolume');

      if (cappedVolume < newVolume) {
        debugPrint('  Capped at VMR target: ${tracker.landmarks.vmrTarget}');
      }

      return MuscleDecision(
        muscle: tracker.muscle,
        action: VolumeAction.increase,
        newVolume: cappedVolume,
        newPhase: ProgressionPhase.discovering,
        reason:
            'Progression (+$increment sets, score: ${performanceScore.toStringAsFixed(2)})',
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
        '[WeeklyAdapt] STAGNANT: VMR discovered at ${tracker.currentVolume}',
      );

      return MuscleDecision(
        muscle: tracker.muscle,
        action: VolumeAction.maintain,
        newVolume: tracker.currentVolume,
        newPhase: ProgressionPhase.maintaining,
        reason: 'Discovered real VMR: ${tracker.currentVolume} sets',
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
      debugPrint('[WeeklyAdapt] OVERLOAD: -> OVERREACHING');

      return MuscleDecision(
        muscle: tracker.muscle,
        action: VolumeAction.maintain,
        newVolume: tracker.currentVolume,
        newPhase: ProgressionPhase.overreaching,
        reason: 'Overload (score: ${performanceScore.toStringAsFixed(2)})',
        confidence: 0.7,
      );
    }

    return MuscleDecision.noChange(
      muscle: tracker.muscle,
      reason: 'Observe one more week',
    );
  }

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
      debugPrint('[WeeklyAdapt] STABLE: keep VMR');
      debugPrint('  Weeks maintaining: ${tracker.weekInCurrentPhase + 1}');

      return MuscleDecision(
        muscle: tracker.muscle,
        action: VolumeAction.maintain,
        newVolume: tracker.currentVolume,
        newPhase: ProgressionPhase.maintaining,
        reason: 'Stable at VMR (week ${tracker.weekInCurrentPhase + 1})',
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
      final newVolume = tracker.currentVolume + max(1, increment);

      debugPrint('[WeeklyAdapt] EXCEPTIONAL: can progress more');
      debugPrint('  New volume: ${tracker.currentVolume} -> $newVolume');

      return MuscleDecision(
        muscle: tracker.muscle,
        action: VolumeAction.increase,
        newVolume: newVolume,
        newPhase: ProgressionPhase.discovering,
        reason: 'Exceptional! +$increment sets',
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
      debugPrint('[WeeklyAdapt] DECLINE: -> OVERREACHING');

      return MuscleDecision(
        muscle: tracker.muscle,
        action: VolumeAction.maintain,
        newVolume: tracker.currentVolume,
        newPhase: ProgressionPhase.overreaching,
        reason: 'Decline detected',
        confidence: 0.7,
      );
    }

    return MuscleDecision(
      muscle: tracker.muscle,
      action: VolumeAction.maintain,
      newVolume: tracker.currentVolume,
      newPhase: ProgressionPhase.maintaining,
      reason: 'Continue maintaining',
      confidence: 0.7,
    );
  }

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
      debugPrint('[WeeklyAdapt] RECOVERED: -> MAINTAINING');

      return MuscleDecision(
        muscle: tracker.muscle,
        action: VolumeAction.maintain,
        newVolume: tracker.currentVolume,
        newPhase: ProgressionPhase.maintaining,
        reason: 'Recovered from overreaching',
        confidence: 0.8,
      );
    }

    if (tracker.weekInCurrentPhase == 0) {
      debugPrint('[WeeklyAdapt] First week OVERREACHING: grace week');

      return MuscleDecision(
        muscle: tracker.muscle,
        action: VolumeAction.maintain,
        newVolume: tracker.currentVolume,
        newPhase: ProgressionPhase.overreaching,
        reason: 'Week 1 overreaching: grace week',
        confidence: 0.6,
      );
    }

    debugPrint('[WeeklyAdapt] No recovery: -> DELOAD');

    final deloadVolume = max(
      tracker.landmarks.vme,
      (tracker.currentVolume * 0.5).round(),
    );

    return MuscleDecision(
      muscle: tracker.muscle,
      action: VolumeAction.deload,
      newVolume: deloadVolume,
      newPhase: ProgressionPhase.deloading,
      reason: 'Deload needed ($deloadVolume sets)',
      confidence: 0.9,
    );
  }

  static MuscleDecision _handleDeloading(
    MuscleProgressionTracker tracker,
    WeeklyMuscleAnalysis analysis,
  ) {
    debugPrint('[WeeklyAdapt] Completing DELOAD -> new cycle');

    return MuscleDecision(
      muscle: tracker.muscle,
      action: VolumeAction.increase,
      newVolume: tracker.landmarks.vop,
      newPhase: ProgressionPhase.discovering,
      reason: 'Deload completed, new cycle (${tracker.landmarks.vop} sets)',
      confidence: 1.0,
      isNewCycle: true,
    );
  }

  static MuscleDecision _handleMicrodeload(
    MuscleProgressionTracker tracker,
    WeeklyMuscleAnalysis analysis,
  ) {
    debugPrint('[WeeklyAdapt] Completing MICRODELOAD -> resume');

    final previousVolume = _getPreviousVolumeBeforeMicrodeload(tracker);
    final resumeVolume = (previousVolume * 1.05).round();

    return MuscleDecision(
      muscle: tracker.muscle,
      action: VolumeAction.increase,
      newVolume: resumeVolume,
      newPhase: ProgressionPhase.discovering,
      reason: 'Microdeload completed, +5%',
      confidence: 0.9,
    );
  }

  static int _calculateAdaptiveIncrement({
    required int currentVolume,
    required double performanceScore,
    required int weekInPhase,
  }) {
    var basePercentage = 0.20;

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

  static double _calculatePerformanceScore(WeeklyMuscleAnalysis analysis) {
    var score = 0.0;

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
    var count = 0;

    for (var i = tracker.history.length - 1; i >= 0; i--) {
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
    for (var i = tracker.phaseTimeline.length - 1; i >= 0; i--) {
      final transition = tracker.phaseTimeline[i];
      if (transition.toPhase == ProgressionPhase.microdeload) {
        return transition.volume;
      }
    }

    return tracker.currentVolume;
  }
}
