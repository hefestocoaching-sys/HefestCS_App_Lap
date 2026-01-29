import 'package:equatable/equatable.dart';
import 'package:hcs_app_lap/domain/entities/decision_trace.dart';
import 'package:hcs_app_lap/domain/training_v2/models/training_context.dart';
import 'package:hcs_app_lap/domain/training_v2/engine/phases/phase_5_intensity_rir.dart';
import 'package:hcs_app_lap/domain/training_v2/engine/phases/phase_6_exercise_selection_v2.dart';

class Phase7IntensificationResult extends Equatable {
  final Map<int, Map<String, Map<String, String>>> intensificationByDay;
  final int appliedCount;
  final int remainingBudget;
  final List<DecisionTrace> decisions;

  const Phase7IntensificationResult({
    required this.intensificationByDay,
    required this.appliedCount,
    required this.remainingBudget,
    required this.decisions,
  });

  @override
  List<Object?> get props => [
    intensificationByDay,
    appliedCount,
    remainingBudget,
    decisions,
  ];
}

class Phase7Intensification {
  Phase7IntensificationResult run({
    required TrainingContext ctx,
    required bool allowIntensification,
    required int maxPerWeek,
    required Map<int, Map<String, V2DayMusclePrescription>> prescriptionsByDay,
    required Map<int, Map<String, List<V2SelectedExercise>>> selectionsByDay,
  }) {
    final ts = ctx.asOfDate;
    final decisions = <DecisionTrace>[];

    final deficitHard =
        ctx.energy.state == 'deficit' && ctx.energy.magnitude >= 300;
    final injuries = ctx.constraints.activeInjuries.isNotEmpty;

    var budget = maxPerWeek;

    // Revalidación de policy dura (defensa).
    if (!allowIntensification || deficitHard || injuries) {
      decisions.add(
        DecisionTrace.info(
          phase: 'Phase7Intensification',
          category: 'intensification_budget',
          description:
              'Intensificación deshabilitada por policy (allow/deficit/injury).',
          context: {
            'allowIntensification': allowIntensification,
            'deficitHard': deficitHard,
            'injuries': injuries,
            'maxPerWeek': maxPerWeek,
            'budget': 0,
          },
          timestamp: ts,
        ),
      );

      return Phase7IntensificationResult(
        intensificationByDay: const {},
        appliedCount: 0,
        remainingBudget: 0,
        decisions: decisions,
      );
    }

    decisions.add(
      DecisionTrace.info(
        phase: 'Phase7Intensification',
        category: 'intensification_budget',
        description: 'Budget semanal de intensificación inicializado.',
        context: {'maxPerWeek': maxPerWeek, 'budget': budget},
        timestamp: ts,
      ),
    );

    // Slots candidatos: (prioridad, dayLoad, sets) determinista
    final slots = <_Slot>[];

    for (final dEntry in prescriptionsByDay.entries) {
      final day = dEntry.key;
      final dayPresc = dEntry.value;

      for (final mEntry in dayPresc.entries) {
        final muscle = mEntry.key;
        final presc = mEntry.value;

        // Nunca intensificar en LIGHT
        if (presc.dayLoad == V2DayLoad.light) continue;

        // Necesitamos sets suficientes para justificar técnica
        if (presc.sets < 4) continue;

        final selected = selectionsByDay[day]?[muscle];
        if (selected == null || selected.isEmpty) continue;

        final priorityRank = _priorityRank(muscle, ctx);
        final loadRank = presc.dayLoad == V2DayLoad.heavy
            ? 0
            : 1; // heavy primero
        final setsRank = -presc.sets; // más sets primero

        slots.add(
          _Slot(
            day: day,
            muscle: muscle,
            exerciseId: selected.first.exerciseId,
            priorityRank: priorityRank,
            loadRank: loadRank,
            setsRank: setsRank,
          ),
        );
      }
    }

    // Orden determinista
    slots.sort((a, b) {
      final pr = a.priorityRank.compareTo(b.priorityRank);
      if (pr != 0) return pr;
      final lr = a.loadRank.compareTo(b.loadRank);
      if (lr != 0) return lr;
      final sr = a.setsRank.compareTo(b.setsRank);
      if (sr != 0) return sr;
      // fallback estable
      final dd = a.day.compareTo(b.day);
      if (dd != 0) return dd;
      return a.muscle.compareTo(b.muscle);
    });

    final out = <int, Map<String, Map<String, String>>>{};
    var applied = 0;

    for (final slot in slots) {
      if (budget <= 0) break;

      final tech = _chooseTechnique(slot);

      out.putIfAbsent(slot.day, () => <String, Map<String, String>>{});
      out[slot.day]!.putIfAbsent(slot.muscle, () => <String, String>{});

      // Solo 1 técnica por músculo/día (policy), si ya existe, skip
      if (out[slot.day]![slot.muscle]!.isNotEmpty) {
        decisions.add(
          DecisionTrace.info(
            phase: 'Phase7Intensification',
            category: 'intensification_skipped',
            description:
                'Slot omitido: ya existe intensificación para ese músculo/día.',
            context: {'day': slot.day, 'muscle': slot.muscle},
            timestamp: ts,
          ),
        );
        continue;
      }

      out[slot.day]![slot.muscle]![slot.exerciseId] = tech;
      budget -= 1;
      applied += 1;

      decisions.add(
        DecisionTrace.info(
          phase: 'Phase7Intensification',
          category: 'intensification_applied',
          description: 'Técnica de intensificación aplicada.',
          context: {
            'day': slot.day,
            'muscle': slot.muscle,
            'exerciseId': slot.exerciseId,
            'technique': tech,
            'remainingBudget': budget,
          },
          timestamp: ts,
        ),
      );
    }

    // Trace final
    decisions.add(
      DecisionTrace.info(
        phase: 'Phase7Intensification',
        category: 'intensification_summary',
        description: 'Resumen de intensificación semanal.',
        context: {
          'applied': applied,
          'remainingBudget': budget,
          'slotsConsidered': slots.length,
        },
        timestamp: ts,
      ),
    );

    return Phase7IntensificationResult(
      intensificationByDay: out,
      appliedCount: applied,
      remainingBudget: budget,
      decisions: decisions,
    );
  }

  int _priorityRank(String muscle, TrainingContext ctx) {
    // menor = más prioridad
    if (ctx.priorities.primary.contains(muscle)) return 0;
    if (ctx.priorities.secondary.contains(muscle)) return 1;
    if (ctx.priorities.tertiary.contains(muscle)) return 2;
    return 3;
  }

  String _chooseTechnique(_Slot slot) {
    // Determinista: heavy -> rest_pause, medium -> myo_reps, primary heavy -> drop_set
    if (slot.loadRank == 0 && slot.priorityRank == 0) return 'drop_set';
    if (slot.loadRank == 0) return 'rest_pause';
    return 'myo_reps';
  }
}

class _Slot {
  final int day;
  final String muscle;
  final String exerciseId;
  final int priorityRank;
  final int loadRank;
  final int setsRank;

  _Slot({
    required this.day,
    required this.muscle,
    required this.exerciseId,
    required this.priorityRank,
    required this.loadRank,
    required this.setsRank,
  });
}
