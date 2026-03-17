import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/core/registry/muscle_registry.dart';

/// P0 Rule G: Effective Sets Calculator.
/// Primary = 1.0 sets
/// Secondary = 0.5 sets
/// Tertiary = 0.25 sets
class EffectiveSetCalculator {
  static const double weightPrimary = 1.0;
  static const double weightSecondary = 0.5;
  static const double weightTertiary = 0.25;

  /// Calculates the effective volume contribution of one exercise instance.
  /// Returns a map of Canonical Muscle -> Effective Sets.
  static Map<String, double> calculateContribution({
    required Exercise exercise,
    required int sets,
  }) {
    final contribution = <String, double>{};

    // Primary
    for (final raw in exercise.primaryMuscles) {
      final muscle = normalize(raw);
      if (muscle != null) {
        contribution[muscle] =
            (contribution[muscle] ?? 0.0) + (sets * weightPrimary);
      }
    }

    // Secondary
    for (final raw in exercise.secondaryMuscles) {
      final muscle = normalize(raw);
      if (muscle != null) {
        contribution[muscle] =
            (contribution[muscle] ?? 0.0) + (sets * weightSecondary);
      }
    }

    // Tertiary
    for (final raw in exercise.tertiaryMuscles) {
      final muscle = normalize(raw);
      if (muscle != null) {
        contribution[muscle] =
            (contribution[muscle] ?? 0.0) + (sets * weightTertiary);
      }
    }

    return contribution;
  }

  /// Calculates total effective weekly volume from a list of sessions.
  static Map<String, double> calculateWeeklyEffectiveVolume(
    List<dynamic>
    sessions, // dynamic to accept TrainingSession from different models
    Function(String id) exerciseLookup,
  ) {
    final totalVolume = <String, double>{};

    for (final session in sessions) {
      // Handle different session interfaces if needed, assuming .exercises list
      final exercises = (session.exercises as List).toList();

      for (final ep in exercises) {
        // ep is ExercisePrescription
        final ex = exerciseLookup(ep.exerciseId);
        if (ex == null) continue;

        final contrib = calculateContribution(exercise: ex, sets: ep.sets);
        contrib.forEach((m, effectiveSets) {
          totalVolume[m] = (totalVolume[m] ?? 0.0) + effectiveSets;
        });
      }
    }

    return totalVolume;
  }
}
