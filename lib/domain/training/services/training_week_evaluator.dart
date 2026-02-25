import 'dart:math' as math;
import 'package:meta/meta.dart';
import 'package:hcs_app_lap/domain/training/training_cycle.dart';
import 'package:hcs_app_lap/domain/training/services/weekly_decision.dart';

/// Adaptador mínimo de bitácora (NO inventar modelos del proyecto).
/// Si ya existe WeeklyLog o TrainingLog, mapear a este snapshot.
typedef WeeklyLogSnapshot = Map<String, dynamic>;

@immutable
class TrainingWeekEvaluator {
  const TrainingWeekEvaluator();

  /// Regla de bitácora válida:
  /// - >=80% sesiones con peso+reps+RIR
  /// - incluye fatiga/sueño/dolor
  /// - medición mensual presente
  bool isValidLog(WeeklyLogSnapshot? log) {
    if (log == null) return false;
    final sessionsCompletePct =
        (log['sessionsCompletePct'] as num?)?.toDouble() ?? 0.0;
    final hasSubjective = (log['hasFatigueSleepPain'] as bool?) ?? false;
    final hasMonthly = (log['hasMonthlyMeasurement'] as bool?) ?? false;
    return sessionsCompletePct >= 0.80 && hasSubjective && hasMonthly;
  }

  /// Trigger caída brutal:
  /// -2 reps o -5% carga (a RIR comparable)
  bool hasPerformanceCrash(WeeklyLogSnapshot? log) {
    if (log == null) return false;
    final repsDrop = (log['repsDrop'] as num?)?.toDouble() ?? 0.0;
    final loadDropPct = (log['loadDropPct'] as num?)?.toDouble() ?? 0.0;
    return repsDrop <= -2.0 || loadDropPct <= -0.05;
  }

  WeeklyDecision evaluate({
    required TrainingCycle cycle,
    required WeeklyLogSnapshot? log,
    required int weekNumber,
    required String phase,
  }) {
    final valid = isValidLog(log);
    final crash = valid ? hasPerformanceCrash(log) : false;

    final action = <String, String>{};
    final newSets = <String, int>{};
    final stimulusSets = <String, Map<String, int>>{};
    final rirTargets = <String, Map<String, int>>{};
    final insight = <String, String>{};

    final vop = cycle.vopByMuscle;
    final vmr = cycle.vmrByMuscle;

    double heavyPct = 0.20;
    double lightPct = 0.20;

    int heavyRir = 2;
    int mediumRir = (phase == 'maintenance') ? 1 : 2;
    int lightRir = (phase == 'maintenance') ? 0 : 1;

    if (phase == 'adaptation') {
      heavyPct = 0.12;
      lightPct = 0.18;
      heavyRir = 2;
      mediumRir = 3;
      lightRir = 2;
    } else if (phase == 'deload' || phase == 'postMaintenanceDeload') {
      heavyPct = 0.12;
      lightPct = 0.18;
      heavyRir = 3;
      mediumRir = 4;
      lightRir = 3;
    }

    for (final muscle in vop.keys) {
      final vopSets = vop[muscle] ?? 0;
      final vmrSets = vmr[muscle] ?? vopSets;

      int target = vopSets;
      String currentAction = 'maintain';

      if (phase == 'adaptation') {
        currentAction = 'maintain';
        target = vopSets;
        insight[muscle] =
            'Adaptación: volumen estable para calibrar técnica y cargas.';
      } else if (!valid) {
        target = math.min(vmrSets, vopSets + 1);
        currentAction = (target > vopSets) ? 'increase' : 'maintain';
        insight[muscle] =
            'Sin bitácora válida: progresión conservadora (techo=VMR).';
      } else {
        if (crash) {
          currentAction = 'deload';
          target = math.max(1, (vopSets * 0.80).floor());
          insight[muscle] =
              'Caída detectada (−2 reps o −5% carga): se activa descarga/micro-deload.';
        } else if (phase == 'maintenance') {
          currentAction = 'maintain';
          target = vopSets;
          insight[muscle] =
              'Mantenimiento alto: no sube sets; sube calidad del estímulo (RIR y técnicas).';
        } else if (phase == 'accumulation') {
          target = math.min(vmrSets, vopSets + 1);
          currentAction = (target > vopSets) ? 'increase' : 'maintain';
          insight[muscle] =
              'Acumulación: incremento operativo hacia techo del ciclo.';
        } else {
          currentAction = 'maintain';
          target = vopSets;
          insight[muscle] =
              'Fase no incremental: se mantiene volumen objetivo.';
        }
      }

      action[muscle] = currentAction;
      newSets[muscle] = target;

      final heavySets = (target * heavyPct).round();
      final lightSets = (target * lightPct).round();
      final mediumSets = math.max(0, target - heavySets - lightSets);

      stimulusSets[muscle] = {
        'heavy': heavySets,
        'medium': mediumSets,
        'light': lightSets,
      };

      rirTargets[muscle] = {
        'heavy': math.max(1, heavyRir),
        'medium': mediumRir,
        'light': lightRir,
      };
    }

    return WeeklyDecision(
      weekNumber: weekNumber,
      actionByMuscle: action,
      newDirectSetsByMuscle: newSets,
      stimulusSetsByMuscle: stimulusSets,
      rirTargetsByMuscle: rirTargets,
      insightByMuscle: insight,
    );
  }
}
