import 'dart:math';

import 'package:hcs_app_lap/domain/entities/decision_trace.dart';
import 'package:hcs_app_lap/domain/training_v2/models/training_context.dart';

class Phase4SplitResult {
  final Map<int, Map<String, int>> weeklySplit;
  final Map<String, int> frequencyByMuscle;
  final List<DecisionTrace> decisions;

  const Phase4SplitResult({
    required this.weeklySplit,
    required this.frequencyByMuscle,
    required this.decisions,
  });
}

/// Capa 4: distribuye el volumen semanal por músculo a lo largo de los días.
class Phase4SplitDistribution {
  Phase4SplitResult run({
    required TrainingContext ctx,
    required Map<String, int> targetWeeklySetsByMuscle,
    required int minExercisesPerDay,
  }) {
    final ts = ctx.asOfDate;
    final decisions = <DecisionTrace>[];

    final days = ctx.meta.daysPerWeek;
    final weeklySplit = <int, Map<String, int>>{};
    for (var d = 1; d <= days; d++) {
      weeklySplit[d] = <String, int>{};
    }

    // 1) Determinar frecuencia por músculo (1..3) según volumen y prioridad
    final freqByMuscle = <String, int>{};

    for (final entry in targetWeeklySetsByMuscle.entries) {
      final muscle = entry.key;
      final sets = entry.value;

      int freq;
      if (sets <= 6) {
        freq = 1;
      } else if (sets <= 12) {
        freq = 2;
      } else {
        freq = 3;
      }

      // Boost por prioridad
      if (ctx.priorities.primary.contains(muscle)) {
        freq = min(freq + 1, days);
      }
      if (ctx.priorities.secondary.contains(muscle)) {
        freq = min(freq + 0, days);
      }

      // Clamp por días disponibles
      freq = _clampInt(freq, 1, min(3, days));

      freqByMuscle[muscle] = freq;

      decisions.add(
        DecisionTrace.info(
          phase: 'Phase4SplitDistribution',
          category: 'frequency_assigned',
          description: 'Frecuencia semanal asignada por músculo.',
          context: {'muscle': muscle, 'weeklySets': sets, 'frequency': freq},
          timestamp: ts,
        ),
      );
    }

    // 2) Asignar sets por músculo a días (round-robin balanceado)
    final loadPerDay = List<int>.filled(days, 0);

    for (final entry in targetWeeklySetsByMuscle.entries) {
      final muscle = entry.key;
      final totalSets = entry.value;
      final freq = freqByMuscle[muscle]!;

      final baseSetsPerSession = totalSets ~/ freq;
      var remainder = totalSets % freq;

      // Días elegidos: los de menor carga actual
      final dayIndices = List<int>.generate(days, (i) => i + 1)
        ..sort((a, b) => loadPerDay[a - 1].compareTo(loadPerDay[b - 1]));

      final chosenDays = dayIndices.take(freq).toList();

      for (final day in chosenDays) {
        var setsToday = baseSetsPerSession;
        if (remainder > 0) {
          setsToday += 1;
          remainder -= 1;
        }

        weeklySplit[day]![muscle] = setsToday;
        loadPerDay[day - 1] += setsToday;
      }

      decisions.add(
        DecisionTrace.info(
          phase: 'Phase4SplitDistribution',
          category: 'muscle_distributed',
          description: 'Sets distribuidos por día para músculo.',
          context: {
            'muscle': muscle,
            'totalSets': totalSets,
            'frequency': freq,
            'days': chosenDays,
          },
          timestamp: ts,
        ),
      );
    }

    // 3) Guardrail: asegurar mínimo de ejercicios por día
    for (var d = 1; d <= days; d++) {
      final exercisesCount = weeklySplit[d]!.length;
      if (exercisesCount < minExercisesPerDay) {
        // Rebalancear: tomar músculos de días más cargados
        final deficit = minExercisesPerDay - exercisesCount;

        final donorDays = List<int>.generate(days, (i) => i + 1)
          ..remove(d)
          ..sort((a, b) => loadPerDay[b - 1].compareTo(loadPerDay[a - 1]));

        int added = 0;
        for (final donor in donorDays) {
          if (added >= deficit) break;

          final donorMuscles = weeklySplit[donor]!.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          for (final dm in donorMuscles) {
            if (added >= deficit) break;
            if (!weeklySplit[d]!.containsKey(dm.key) && dm.value > 1) {
              // mover 1 set
              weeklySplit[donor]![dm.key] = dm.value - 1;
              weeklySplit[d]![dm.key] = 1;
              loadPerDay[donor - 1] -= 1;
              loadPerDay[d - 1] += 1;
              added += 1;
            }
          }
        }

        decisions.add(
          DecisionTrace.warning(
            phase: 'Phase4SplitDistribution',
            category: 'min_exercises_enforced',
            description:
                'Se reequilibró el día para cumplir minExercisesPerDay.',
            context: {
              'day': d,
              'minExercisesPerDay': minExercisesPerDay,
              'addedExercises': added,
            },
            timestamp: ts,
            action: 'Redistribuir sets desde días más cargados.',
          ),
        );
      }
    }

    // 4) Log final por día
    for (var d = 1; d <= days; d++) {
      decisions.add(
        DecisionTrace.info(
          phase: 'Phase4SplitDistribution',
          category: 'day_summary',
          description: 'Resumen de volumen diario.',
          context: {
            'day': d,
            'muscles': weeklySplit[d],
            'totalSets': loadPerDay[d - 1],
          },
          timestamp: ts,
        ),
      );
    }

    return Phase4SplitResult(
      weeklySplit: weeklySplit,
      frequencyByMuscle: freqByMuscle,
      decisions: decisions,
    );
  }

  int _clampInt(int v, int lo, int hi) => v < lo ? lo : (v > hi ? hi : v);
}
