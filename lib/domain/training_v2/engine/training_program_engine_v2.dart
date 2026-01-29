import 'package:hcs_app_lap/domain/entities/decision_trace.dart';
import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/domain/training_v2/engine/phases/phase_1_intake_gate.dart';
import 'package:hcs_app_lap/domain/training_v2/engine/phases/phase_2_volume_capacity.dart';
import 'package:hcs_app_lap/domain/training_v2/engine/phases/phase_3_target_volume.dart';
import 'package:hcs_app_lap/domain/training_v2/engine/phases/phase_4_split_distribution.dart';
import 'package:hcs_app_lap/domain/training_v2/engine/phases/phase_5_intensity_rir.dart';
import 'package:hcs_app_lap/domain/training_v2/engine/phases/phase_6_exercise_selection_v2.dart';
import 'package:hcs_app_lap/domain/training_v2/engine/phases/phase_7_intensification.dart';
import 'package:hcs_app_lap/domain/training_v2/engine/phases/phase_8_finalize_and_learning.dart';
import 'package:hcs_app_lap/domain/training_v2/models/training_context.dart';

class TrainingPlanBlocked {
  final String reason;
  final Map<String, dynamic> details;

  const TrainingPlanBlocked({required this.reason, this.details = const {}});
}

class TrainingProgramEngineV2Result {
  final Map<String, dynamic>?
  planJson; // placeholder: luego lo mapeas a tu GeneratedPlan real
  final TrainingPlanBlocked? blocked;
  final List<DecisionTrace> trace;

  const TrainingProgramEngineV2Result({
    required this.planJson,
    required this.blocked,
    required this.trace,
  });

  bool get isBlocked => blocked != null;
}

/// Entry point Motor v2.
/// NOTA: aquí solo estructuramos el pipeline.
/// La implementación de cada fase se hará en siguientes prompts.
class TrainingProgramEngineV2 {
  TrainingProgramEngineV2Result generate({
    required TrainingContext ctx,
    List<Exercise> exercises = const <Exercise>[],
  }) {
    final trace = <DecisionTrace>[];

    // Phase 1: Intake Gate (determinista con TrainingContext)
    final p1 = Phase1IntakeGate().run(ctx: ctx);
    trace.addAll(p1.decisions);

    if (p1.isBlocked) {
      return TrainingProgramEngineV2Result(
        planJson: null,
        blocked: TrainingPlanBlocked(
          reason: p1.blockedReason ?? 'Blocked in Phase1IntakeGate',
          details: p1.blockedDetails,
        ),
        trace: trace,
      );
    }

    // Guardar output de Phase1 como base de state acumulado.
    // Por ahora, lo dejamos en planJson placeholder para B3.2+.
    final baseState = <String, dynamic>{
      'phase1': {
        'readinessScore': p1.readinessScore,
        'readinessLevel': p1.readinessLevel.name,
        'volumeAdjustmentFactor': p1.volumeAdjustmentFactor,
        'allowIntensification': p1.allowIntensification,
        'caps': {
          'minExercisesPerDay': p1.caps.minExercisesPerDay,
          'maxWeeklySetsPerMuscleSoft': p1.caps.maxWeeklySetsPerMuscleSoft,
          'maxIntensificationPerWeek': p1.caps.maxIntensificationPerWeek,
          'maxWeeklyProgression': p1.caps.maxWeeklyProgression,
        },
      },
    };

    final phase2 = Phase2VolumeCapacity().run(
      ctx: ctx,
      readinessScore: p1.readinessScore,
      maxWeeklySetsSoftCap: p1.caps.maxWeeklySetsPerMuscleSoft,
    );
    trace.addAll(phase2.decisions);

    baseState['phase2'] = {
      'capacityByMuscle': phase2.capacityByMuscle.map(
        (k, v) => MapEntry(k, v.toJson()),
      ),
    };

    final phase3 = Phase3TargetVolume().run(
      ctx: ctx,
      readinessScore: p1.readinessScore,
      capacityByMuscle: phase2.capacityByMuscle,
      maxWeeklySetsSoftCap: p1.caps.maxWeeklySetsPerMuscleSoft,
    );
    trace.addAll(phase3.decisions);

    baseState['phase3'] = {
      'targetWeeklySetsByMuscle': phase3.targetWeeklySetsByMuscle,
      'chosenPercentileByMuscle': phase3.chosenPercentileByMuscle.map(
        (k, v) => MapEntry(k, (v * 100).round() / 100.0),
      ),
    };

    final phase4 = Phase4SplitDistribution().run(
      ctx: ctx,
      targetWeeklySetsByMuscle: phase3.targetWeeklySetsByMuscle,
      minExercisesPerDay: p1.caps.minExercisesPerDay,
    );
    trace.addAll(phase4.decisions);

    baseState['phase4'] = {
      'weeklySplit': phase4.weeklySplit.map(
        (d, m) => MapEntry(d.toString(), m),
      ),
      'frequencyByMuscle': phase4.frequencyByMuscle,
    };

    final phase5 = Phase5IntensityRir().run(
      ctx: ctx,
      readinessScore: p1.readinessScore,
      weeklySplit: phase4.weeklySplit,
    );
    trace.addAll(phase5.decisions);

    baseState['phase5'] = {
      'dayLoadProfile': phase5.dayLoadProfile.map(
        (k, v) => MapEntry(k.toString(), v.name),
      ),
      'prescriptionsByDay': phase5.prescriptionsByDay.map(
        (day, muscles) => MapEntry(
          day.toString(),
          muscles.map((m, p) => MapEntry(m, p.toJson())),
        ),
      ),
    };

    final phase6 = Phase6ExerciseSelectionV2().run(
      ctx: ctx,
      prescriptionsByDay: phase5.prescriptionsByDay,
      exercises: exercises,
    );
    trace.addAll(phase6.decisions);

    baseState['phase6'] = {
      'selectionsByDay': phase6.selectionsByDay.map(
        (day, muscles) => MapEntry(
          day.toString(),
          muscles.map(
            (muscle, list) =>
                MapEntry(muscle, list.map((e) => e.toJson()).toList()),
          ),
        ),
      ),
    };

    final phase7 = Phase7Intensification().run(
      ctx: ctx,
      allowIntensification: p1.allowIntensification,
      maxPerWeek: p1.caps.maxIntensificationPerWeek,
      prescriptionsByDay: phase5.prescriptionsByDay,
      selectionsByDay: phase6.selectionsByDay,
    );
    trace.addAll(phase7.decisions);

    baseState['phase7'] = {
      'appliedCount': phase7.appliedCount,
      'remainingBudget': phase7.remainingBudget,
      'intensificationByDay': phase7.intensificationByDay.map(
        (day, muscles) => MapEntry(day.toString(), muscles),
      ),
    };

    // Phase 8: Finalization & Learning
    final phase8 = Phase8FinalizeAndLearning().run(
      ctx: ctx,
      baseState: baseState,
    );
    trace.addAll(phase8.decisions);

    // Si Phase8 falla, retornar bloqueado
    if (phase8.isBlocked) {
      return TrainingProgramEngineV2Result(
        planJson: null,
        blocked: TrainingPlanBlocked(
          reason: phase8.blockedReason ?? 'Validación final falló.',
          details: phase8.blockedDetails,
        ),
        trace: trace,
      );
    }

    // Éxito: retornar plan completo con learning payload
    return TrainingProgramEngineV2Result(
      planJson: phase8.finalPlanJson,
      blocked: null,
      trace: trace,
    );
  }
}
