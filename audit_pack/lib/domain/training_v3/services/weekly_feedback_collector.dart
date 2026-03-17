import 'package:hcs_app_lap/domain/training_v3/models/exercise_feedback.dart';
import 'package:hcs_app_lap/domain/training_v3/models/exercise_log.dart';
import 'package:hcs_app_lap/domain/training_v3/models/weekly_muscle_analysis.dart';

/// Service to collect weekly data and build analyses.
///
/// Pipeline:
/// 1. Collect ExerciseLog[] for the week.
/// 2. Group by muscle.
/// 3. Calculate objective metrics (load, reps, RIR).
/// 4. Collect subjective user feedback.
/// 5. Generate a full WeeklyMuscleAnalysis.
class WeeklyFeedbackCollector {
  /// Builds a weekly analysis for a muscle.
  ///
  /// Input:
  /// - muscle: muscle to analyze
  /// - weekNumber: global week number
  /// - exerciseLogs: logs for all exercises of that muscle
  /// - prescribedSets: total planned sets
  /// - prescribedRir: planned RIR
  /// - previousAnalysis: prior week analysis (for comparison)
  /// - userFeedback: user subjective feedback
  ///
  /// Output:
  /// - full WeeklyMuscleAnalysis
  static WeeklyMuscleAnalysis buildAnalysis({
    required String muscle,
    required int weekNumber,
    required DateTime weekStart,
    required DateTime weekEnd,
    required List<ExerciseLog> exerciseLogs,
    required int prescribedSets,
    required int prescribedRir,
    WeeklyMuscleAnalysis? previousAnalysis,
    required Map<String, dynamic> userFeedback,
  }) {
    final completedSets = exerciseLogs.fold(
      0,
      (sum, log) => sum + log.sets.length,
    );

    final volumeAdherence = prescribedSets > 0
        ? completedSets / prescribedSets
        : 0.0;

    final totalLoad = exerciseLogs.fold(0.0, (sum, log) {
      return sum +
          log.sets.fold(0.0, (innerSum, set) {
            return innerSum + (set.weight * set.reps);
          });
    });

    final totalReps = exerciseLogs.fold(
      0,
      (sum, log) => sum + log.sets.fold(0, (inner, set) => inner + set.reps),
    );

    final averageLoad = totalReps > 0 ? totalLoad / totalReps : 0.0;

    final previousLoad = previousAnalysis?.averageLoad ?? averageLoad;
    final loadChange = previousLoad > 0
        ? ((averageLoad - previousLoad) / previousLoad) * 100
        : 0.0;

    final totalRpe = exerciseLogs.fold(0.0, (sum, log) => sum + log.averageRpe);
    final averageRpe = exerciseLogs.isNotEmpty
        ? totalRpe / exerciseLogs.length
        : 0.0;

    final totalRir = exerciseLogs.fold(
      0.0,
      (sum, log) => sum + (10 - log.averageRpe),
    );

    final averageRir = exerciseLogs.isNotEmpty
        ? totalRir / exerciseLogs.length
        : 0.0;
    final rirDeviation = (averageRir - prescribedRir).abs();

    final averageReps = completedSets > 0 ? totalReps / completedSets : 0.0;
    final previousReps = previousAnalysis?.averageReps ?? averageReps;

    final muscleActivation =
        userFeedback['muscle_activation'] as double? ?? 7.0;
    final pumpQuality = userFeedback['pump_quality'] as double? ?? 7.0;
    final fatigueLevel = userFeedback['fatigue_level'] as double? ?? 5.0;
    final recoveryQuality = userFeedback['recovery_quality'] as double? ?? 7.0;
    final hadPain = userFeedback['had_pain'] as bool? ?? false;
    final painSeverity = userFeedback['pain_severity'] as double?;
    final painDescription = userFeedback['pain_description'] as String?;

    final exerciseFeedbackList = <ExerciseFeedback>[];
    for (final log in exerciseLogs) {
      final feedback = userFeedback['exercises']?[log.exerciseId];
      if (feedback != null) {
        exerciseFeedbackList.add(ExerciseFeedback.fromJson(feedback));
      }
    }

    return WeeklyMuscleAnalysis(
      muscle: muscle,
      weekNumber: weekNumber,
      weekStart: weekStart,
      weekEnd: weekEnd,
      prescribedSets: prescribedSets,
      completedSets: completedSets,
      volumeAdherence: volumeAdherence,
      averageLoad: averageLoad,
      previousLoad: previousLoad,
      loadChange: loadChange,
      averageReps: averageReps,
      previousReps: previousReps,
      averageRir: averageRir,
      prescribedRir: prescribedRir,
      rirDeviation: rirDeviation,
      averageRpe: averageRpe,
      muscleActivation: muscleActivation,
      pumpQuality: pumpQuality,
      fatigueLevel: fatigueLevel,
      recoveryQuality: recoveryQuality,
      hadPain: hadPain,
      painSeverity: painSeverity,
      painDescription: painDescription,
      exerciseFeedback: exerciseFeedbackList,
    );
  }
}
