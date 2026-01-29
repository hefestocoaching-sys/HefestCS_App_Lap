import 'dart:math';

import 'package:hcs_app_lap/domain/entities/decision_trace.dart';
import 'package:hcs_app_lap/domain/training_v2/models/training_context.dart';

enum V2DayLoad { heavy, medium, light }

class V2DayMusclePrescription {
  final int sets;
  final int rirTarget;
  final int repMin;
  final int repMax;
  final V2DayLoad dayLoad;

  const V2DayMusclePrescription({
    required this.sets,
    required this.rirTarget,
    required this.repMin,
    required this.repMax,
    required this.dayLoad,
  });

  Map<String, dynamic> toJson() => {
    'sets': sets,
    'rirTarget': rirTarget,
    'repMin': repMin,
    'repMax': repMax,
    'dayLoad': dayLoad.name,
  };
}

class Phase5IntensityRirResult {
  final Map<int, Map<String, V2DayMusclePrescription>> prescriptionsByDay;
  final Map<int, V2DayLoad> dayLoadProfile;
  final List<DecisionTrace> decisions;

  const Phase5IntensityRirResult({
    required this.prescriptionsByDay,
    required this.dayLoadProfile,
    required this.decisions,
  });
}

/// Capa 5: define RIR targets + rep ranges + perfil H/M/L por día.
/// Nota: no elige ejercicios; eso es Phase6.
class Phase5IntensityRir {
  Phase5IntensityRirResult run({
    required TrainingContext ctx,
    required double readinessScore,
    required Map<int, Map<String, int>> weeklySplit,
  }) {
    final ts = ctx.asOfDate;
    final decisions = <DecisionTrace>[];

    final days = ctx.meta.daysPerWeek;

    // 1) Definir perfil de carga por día (H/M/L)
    // Regla determinista por daysPerWeek:
    // 3d: H-M-L
    // 4d: H-M-H-L
    // 5d: H-M-H-M-L
    // 6d: H-M-H-M-H-L
    final dayLoads = _buildDayLoadProfile(days);

    // Ajuste conservador por readiness bajo o déficit alto: reduce "heavy"
    final deficitHard =
        ctx.energy.state == 'deficit' && ctx.energy.magnitude >= 300;
    if (readinessScore < 0.45 || deficitHard) {
      // Convertir el día heavy "más agresivo" al final en medium
      final lastHeavy =
          dayLoads.entries
              .where((e) => e.value == V2DayLoad.heavy)
              .map((e) => e.key)
              .toList()
            ..sort();
      if (lastHeavy.isNotEmpty) {
        dayLoads[lastHeavy.last] = V2DayLoad.medium;
        decisions.add(
          DecisionTrace.warning(
            phase: 'Phase5IntensityRir',
            category: 'heavy_reduced',
            description:
                'Readiness bajo o déficit alto: se redujo un día heavy a medium.',
            context: {
              'readinessScore': readinessScore,
              'deficitHard': deficitHard,
              'adjustedDay': lastHeavy.last,
            },
            timestamp: ts,
            action: 'Reducir estrés neurálgico para mejorar recuperación.',
          ),
        );
      }
    }

    decisions.add(
      DecisionTrace.info(
        phase: 'Phase5IntensityRir',
        category: 'day_load_profile',
        description: 'Perfil H/M/L por día definido.',
        context: dayLoads.map((k, v) => MapEntry(k.toString(), v.name)),
        timestamp: ts,
      ),
    );

    // 2) Definir base RIR por nivel/objetivo
    final baseRir = _baseRirByLevelAndGoal(
      levelName: ctx.meta.level!.name.toLowerCase(),
      goalName: ctx.meta.goal.name.toLowerCase(),
    );

    // 3) Ajustes globales a RIR por energía/readiness/lesión
    var globalRirDelta = 0;
    if (ctx.energy.state == 'deficit') {
      globalRirDelta += (deficitHard ? 1 : 0);
    }
    if (readinessScore < 0.45) {
      globalRirDelta += 1;
    }
    if (ctx.constraints.activeInjuries.isNotEmpty) {
      globalRirDelta += 1;
    }

    // 4) Construir prescripción por día y músculo
    final out = <int, Map<String, V2DayMusclePrescription>>{};

    for (var day = 1; day <= days; day++) {
      final load = dayLoads[day]!;
      final muscles = weeklySplit[day] ?? const <String, int>{};
      final dayOut = <String, V2DayMusclePrescription>{};

      for (final m in muscles.entries) {
        final muscle = m.key;
        final sets = m.value;

        // RIR por día-load: heavy -> menos RIR, light -> más RIR
        final loadDelta = load == V2DayLoad.heavy
            ? -1
            : (load == V2DayLoad.light ? 1 : 0);

        // Prioridad puede bajar RIR (más empuje) pero conservador
        final prioDelta = ctx.priorities.primary.contains(muscle) ? -1 : 0;

        var rir = baseRir + globalRirDelta + loadDelta + prioDelta;

        // Clamp clínico RIR (hipertrofia típica: 0-4; aquí conservador 1-4)
        rir = _clampInt(rir, 1, 4);

        // Rep range por load y objetivo (hipertrofia: 6-12 heavy, 8-15 medium, 12-20 light)
        final reps = _repRange(
          load: load,
          goalName: ctx.meta.goal.name.toLowerCase(),
        );

        dayOut[muscle] = V2DayMusclePrescription(
          sets: sets,
          rirTarget: rir,
          repMin: reps.$1,
          repMax: reps.$2,
          dayLoad: load,
        );

        decisions.add(
          DecisionTrace.info(
            phase: 'Phase5IntensityRir',
            category: 'rir_selected',
            description: 'RIR target seleccionado para músculo/día.',
            context: {
              'day': day,
              'muscle': muscle,
              'sets': sets,
              'dayLoad': load.name,
              'baseRir': baseRir,
              'globalRirDelta': globalRirDelta,
              'loadDelta': loadDelta,
              'priorityDelta': prioDelta,
              'rirTarget': rir,
            },
            timestamp: ts,
          ),
        );

        decisions.add(
          DecisionTrace.info(
            phase: 'Phase5IntensityRir',
            category: 'rep_range_selected',
            description: 'Rango de repeticiones seleccionado para músculo/día.',
            context: {
              'day': day,
              'muscle': muscle,
              'dayLoad': load.name,
              'repMin': reps.$1,
              'repMax': reps.$2,
            },
            timestamp: ts,
          ),
        );
      }

      out[day] = dayOut;
    }

    return Phase5IntensityRirResult(
      prescriptionsByDay: out,
      dayLoadProfile: dayLoads,
      decisions: decisions,
    );
  }

  Map<int, V2DayLoad> _buildDayLoadProfile(int days) {
    final out = <int, V2DayLoad>{};
    final pattern = <V2DayLoad>[];

    switch (days) {
      case 3:
        pattern.addAll([V2DayLoad.heavy, V2DayLoad.medium, V2DayLoad.light]);
        break;
      case 4:
        pattern.addAll([
          V2DayLoad.heavy,
          V2DayLoad.medium,
          V2DayLoad.heavy,
          V2DayLoad.light,
        ]);
        break;
      case 5:
        pattern.addAll([
          V2DayLoad.heavy,
          V2DayLoad.medium,
          V2DayLoad.heavy,
          V2DayLoad.medium,
          V2DayLoad.light,
        ]);
        break;
      default:
        // 6 o más
        pattern.addAll([
          V2DayLoad.heavy,
          V2DayLoad.medium,
          V2DayLoad.heavy,
          V2DayLoad.medium,
          V2DayLoad.heavy,
          V2DayLoad.light,
        ]);
        break;
    }

    for (var d = 1; d <= days; d++) {
      out[d] = pattern[min(d - 1, pattern.length - 1)];
    }
    return out;
  }

  int _baseRirByLevelAndGoal({
    required String levelName,
    required String goalName,
  }) {
    // Conservador:
    // beginner: 2-3
    // intermediate: 1-2
    // advanced: 1-2 (pero con más heavy -> 1)
    // Si el goal es strength, baja 1.
    var rir = levelName == 'beginner' ? 3 : 2;
    if (levelName == 'advanced') {
      rir = 2;
    }

    if (goalName.contains('strength') || goalName.contains('fuerza')) {
      rir = max(1, rir - 1);
    }
    return _clampInt(rir, 1, 4);
  }

  (int, int) _repRange({required V2DayLoad load, required String goalName}) {
    final isStrength =
        goalName.contains('strength') || goalName.contains('fuerza');

    if (isStrength) {
      // Fuerza: lower reps
      switch (load) {
        case V2DayLoad.heavy:
          return (3, 6);
        case V2DayLoad.medium:
          return (4, 8);
        case V2DayLoad.light:
          return (6, 10);
      }
    }

    // Hipertrofia general
    switch (load) {
      case V2DayLoad.heavy:
        return (6, 12);
      case V2DayLoad.medium:
        return (8, 15);
      case V2DayLoad.light:
        return (12, 20);
    }
  }

  int _clampInt(int v, int lo, int hi) => v < lo ? lo : (v > hi ? hi : v);
}
