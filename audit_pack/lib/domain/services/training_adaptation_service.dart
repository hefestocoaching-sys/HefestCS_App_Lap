import 'package:hcs_app_lap/domain/entities/decision_trace.dart';
import 'package:hcs_app_lap/domain/entities/exercise_prescription.dart';
import 'package:hcs_app_lap/domain/entities/training_structure.dart';
import 'package:hcs_app_lap/domain/entities/volume_limits.dart';

/// Resultado de adaptación de bitácora sin reestructurar
class TrainingAdaptationResult {
  /// Ajustes de volumen por músculo (delta sets: +1, -1, etc.)
  final Map<String, int> volumeDeltas;

  /// Ajustes de RIR target (delta RIR: +0.5, -0.5, etc.)
  final Map<String, double> rirDeltas;

  /// Swaps de accesorios (ejercicioOriginal -> ejercicioReemplazo)
  /// SOLO variantes del mismo patrón
  final Map<String, String> exerciseSwaps;

  final List<DecisionTrace> decisions;

  const TrainingAdaptationResult({
    required this.volumeDeltas,
    required this.rirDeltas,
    required this.exerciseSwaps,
    required this.decisions,
  });

  /// Adaptación vacía (sin cambios)
  factory TrainingAdaptationResult.empty() => const TrainingAdaptationResult(
    volumeDeltas: {},
    rirDeltas: {},
    exerciseSwaps: {},
    decisions: [],
  );
}

/// Servicio de adaptación conservadora basado en bitácora
/// SOLO ajusta sets/RIR/variantes. NO cambia estructura (split/patrones).
class TrainingAdaptationService {
  /// Adapta el plan basándose en feedback de bitácora
  /// Respeta TrainingStructure bloqueada (no modifica dayTemplates)
  TrainingAdaptationResult adaptFromLogs({
    required TrainingStructure lockedStructure,
    required Map<int, Map<int, List<ExercisePrescription>>>
    currentPrescriptions,
    required Map<String, VolumeLimits> volumeLimits,
    Map<String, dynamic>? feedbackData,
  }) {
    final decisions = <DecisionTrace>[];
    final volumeDeltas = <String, int>{};
    final rirDeltas = <String, double>{};
    final exerciseSwaps = <String, String>{};

    // Si no hay feedback, retornar vacío
    if (feedbackData == null || feedbackData.isEmpty) {
      decisions.add(
        DecisionTrace.info(
          phase: 'TrainingAdaptation',
          category: 'no_feedback',
          description: 'Sin datos de bitácora para adaptar',
          context: {
            'splitId': lockedStructure.splitId,
            'daysPerWeek': lockedStructure.daysPerWeek,
            'lockedFromWeek': lockedStructure.lockedFromWeek,
            'lockedUntilWeek': lockedStructure.lockedUntilWeek,
          },
        ),
      );
      return TrainingAdaptationResult(
        volumeDeltas: volumeDeltas,
        rirDeltas: rirDeltas,
        exerciseSwaps: exerciseSwaps,
        decisions: decisions,
      );
    }

    decisions.add(
      DecisionTrace.info(
        phase: 'TrainingAdaptation',
        category: 'structure_locked',
        description: 'Estructura bloqueada - solo ajustes conservadores',
        context: {
          'splitId': lockedStructure.splitId,
          'daysPerWeek': lockedStructure.daysPerWeek,
          'minExercisesPerDay': lockedStructure.minExercisesPerDay,
          'targetExercisesPerDay': lockedStructure.targetExercisesPerDay,
          'lockedFromWeek': lockedStructure.lockedFromWeek,
          'lockedUntilWeek': lockedStructure.lockedUntilWeek,
        },
      ),
    );

    // Reglas conservadoras de adaptacion (minimo viable)
    // - RIR real vs target (si RIR real < target-1 consistentemente -> aumentar carga, no sets)
    // - Fatiga reportada (si fatiga alta -> reducir volumen en -1 set para ese musculo)
    // - Adherencia (si sesiones incompletas -> mantener o reducir ligeramente)
    // - Progreso de carga (si estancamiento -> considerar swap de variante del mismo patron)

    // Por ahora: adaptación conservadora sin cambios
    decisions.add(
      DecisionTrace.info(
        phase: 'TrainingAdaptation',
        category: 'conservative_approach',
        description: 'Adaptación conservadora aplicada',
        context: {
          'volumeChanges': volumeDeltas.length,
          'rirChanges': rirDeltas.length,
          'exerciseSwaps': exerciseSwaps.length,
        },
        action:
            'Mantener estructura actual y ajustar solo si hay señales claras',
      ),
    );

    return TrainingAdaptationResult(
      volumeDeltas: volumeDeltas,
      rirDeltas: rirDeltas,
      exerciseSwaps: exerciseSwaps,
      decisions: decisions,
    );
  }

  /// Aplica deltas de volumen a prescripciones existentes
  /// NOTA: ExercisePrescription no tiene campo 'muscle' directo,
  /// por lo que esta función es un placeholder para adaptación futura
  Map<int, Map<int, List<ExercisePrescription>>> applyVolumeDeltas({
    required Map<int, Map<int, List<ExercisePrescription>>> prescriptions,
    required Map<String, int> volumeDeltas,
    required Map<String, VolumeLimits> volumeLimits,
  }) {
    // Por ahora retornar sin modificar hasta tener mapping muscle->ejercicio
    return prescriptions;
  }

  /// Aplica swaps de ejercicios (solo variantes del mismo patrón)
  Map<int, Map<int, List<ExercisePrescription>>> applyExerciseSwaps({
    required Map<int, Map<int, List<ExercisePrescription>>> prescriptions,
    required Map<String, String> exerciseSwaps,
  }) {
    if (exerciseSwaps.isEmpty) return prescriptions;

    final result = <int, Map<int, List<ExercisePrescription>>>{};

    for (final weekEntry in prescriptions.entries) {
      final weekIdx = weekEntry.key;
      result[weekIdx] = {};

      for (final dayEntry in weekEntry.value.entries) {
        final dayIdx = dayEntry.key;
        final prescList = dayEntry.value;
        final swapped = <ExercisePrescription>[];

        for (final presc in prescList) {
          final replacement = exerciseSwaps[presc.exerciseName];
          if (replacement != null) {
            swapped.add(presc.copyWith(exerciseName: replacement));
          } else {
            swapped.add(presc);
          }
        }

        result[weekIdx]![dayIdx] = swapped;
      }
    }

    return result;
  }
}
