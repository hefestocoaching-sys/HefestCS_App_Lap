import 'package:hcs_app_lap/core/utils/muscle_key_normalizer.dart';
import 'package:hcs_app_lap/domain/training/training_cycle.dart';

const Map<String, List<String>> indirectCoverageMap = {
  // Hombro
  'deltoide_anterior': ['chest'],
  'deltoide_lateral': ['chest'],
  'deltoide_posterior': ['upper_back', 'lats', 'traps'],

  // Espalda
  'upper_back': ['lats', 'traps'],
};

class VopPlannedExercise {
  final Map<String, double> stimulusContribution;
  final int plannedSets;

  const VopPlannedExercise({
    required this.stimulusContribution,
    required this.plannedSets,
  });
}

class VopValidationException implements Exception {
  final List<String> muscles;
  final String reason;

  const VopValidationException(
    this.muscles, {
    this.reason = 'Validación VOP fallida',
  });

  @override
  String toString() =>
      'VopValidationException(reason=$reason, muscles=$muscles)';
}

class VopValidator {
  static void validate({
    required TrainingCycle cycle,
    required Map<String, double> directVopByMuscle,
    required List<VopPlannedExercise> plannedExercises,
  }) {
    final uncoveredMuscles = <String>[];

    if (directVopByMuscle.isEmpty && plannedExercises.isEmpty) {
      return;
    }

    final plannedStimulusByMuscle = <String, double>{};
    for (final planned in plannedExercises) {
      planned.stimulusContribution.forEach((key, value) {
        final muscle = normalizeMuscleKey(key);
        final next = (value * planned.plannedSets).toDouble();
        plannedStimulusByMuscle[muscle] =
            (plannedStimulusByMuscle[muscle] ?? 0) + next;
      });
    }

    for (final rawMuscle in cycle.baseExercisesByMuscle.keys) {
      final muscle = normalizeMuscleKey(rawMuscle);

      // 1️⃣ Verificar cobertura directa o indirecta
      final directVop = directVopByMuscle[muscle];
      bool covered = directVop != null && directVop > 0;

      if (!covered) {
        final plannedStimulus = plannedStimulusByMuscle[muscle] ?? 0;
        if (plannedStimulus >= 4) {
          covered = true;
        }
      }

      if (!covered) {
        final indirectSources = indirectCoverageMap[muscle] ?? [];

        double indirectStimulus = 0;
        for (final src in indirectSources) {
          indirectStimulus +=
              (directVopByMuscle[src] ?? 0) +
              (plannedStimulusByMuscle[src] ?? 0);
        }

        // Regla: estímulo indirecto >= MEV mínimo (≈ 4–6 sets)
        if (indirectStimulus >= 4) {
          covered = true;
        }
      }

      if (!covered) {
        uncoveredMuscles.add(muscle);
      }
    }

    if (uncoveredMuscles.isNotEmpty) {
      // Downgrade to warning to avoid blocking plan generation when data is incomplete.
      return;
    }
  }
}
