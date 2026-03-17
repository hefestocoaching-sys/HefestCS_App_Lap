// ignore_for_file: deprecated_member_use_from_same_package
import 'package:hcs_app_lap/domain/entities/decision_trace.dart';
import 'package:hcs_app_lap/domain/entities/exercise_prescription.dart';
import 'package:hcs_app_lap/domain/entities/manual_override.dart';
import 'package:hcs_app_lap/domain/entities/training_feedback.dart';
import 'package:hcs_app_lap/domain/entities/training_history.dart';
import 'package:hcs_app_lap/domain/entities/training_session_log.dart';
import 'package:hcs_app_lap/domain/entities/volume_limits.dart';
import 'package:hcs_app_lap/domain/entities/weekly_training_feedback_summary.dart';
import 'package:hcs_app_lap/domain/entities/rep_range.dart';
import 'package:hcs_app_lap/core/enums/training_level.dart';

/// C3: Acciones de progresión (una sola palanca por microciclo)
enum ProgressionAction { none, reps, load, sets }

class Phase8AdaptationResult {
  /// weekIndex -> day -> prescriptions adaptadas
  final Map<int, Map<int, List<ExercisePrescription>>>
  adaptedWeekDayPrescriptions;
  final List<DecisionTrace> decisions;

  const Phase8AdaptationResult({
    required this.adaptedWeekDayPrescriptions,
    required this.decisions,
  });
}

/// Decisión centralizada sobre si se permite progresar y cómo ajustar volumen/RIR.
class ProgressionDecision {
  final bool progressAllowed;
  final double volumeMultiplier;
  final double rirAdjustment;
  final List<String> reasons;

  const ProgressionDecision({
    required this.progressAllowed,
    required this.volumeMultiplier,
    required this.rirAdjustment,
    required this.reasons,
  });
}

/// Fase 8: Adaptación bidireccional del microciclo siguiente según feedback, historial y logs.
/// Reglas:
/// ADAPTACIÓN POSITIVA (si señales positivas):
/// - Si fatigue<4, soreness<4, adherence>=0.85+, avgRir>=2.0 y rendimiento estable
///   → Aumentar volumen +5-10% O reducir RIR en -1
/// ADAPTACIÓN NEGATIVA (si señales negativas):
/// - Si fatigue>=7.0 o soreness>=7.0 → reducir volumen 10–20%
/// - Si adherence < 0.8 → simplificar (menos ejercicios, mismo volumen)
/// - Si avgRir < 1.0 → aumentar RIR target en +1
/// Restricciones:
/// - Nunca exceder MRV
/// - Nunca cambiar split
/// - Adaptaciones SOLO para el siguiente microciclo
class Phase8AdaptationService {
  Map<String, dynamic> _updateMuscleObservedCaps({
    required WeeklyTrainingFeedbackSummary? summary,
    required Map<String, VolumeLimits>? limitsByMuscle,
    required Map<String, dynamic> existingCaps,
  }) {
    if (summary == null || limitsByMuscle == null) return existingCaps;

    // Semana estable = elegible para “explorar capacidad” con +1
    final stable =
        summary.adherenceRatio >= 0.85 &&
        summary.painEvents == 0 &&
        summary.stoppedEarlyEvents == 0 &&
        summary.formDegradationEvents == 0 &&
        summary.avgReportedRIR >= 1.5;

    if (!stable) return existingCaps;

    final out = Map<String, dynamic>.from(existingCaps);

    for (final e in limitsByMuscle.entries) {
      final muscle = e.key;
      final limits = e.value;

      // Solo aprender cerca de rango alto (evita inflar desde volúmenes bajos)
      if (limits.recommendedStartVolume < limits.mav) continue;

      final current = (out[muscle] is num)
          ? (out[muscle] as num).toInt()
          : null;
      final base = current ?? limits.mrv;

      // +1 conservador con cap duro (MRV teórico + margen pequeño)
      final next = (base + 1).clamp(limits.mrv, limits.mrv + 4);
      out[muscle] = next;
    }

    return out;
  }

  /// Exponer cálculo de caps observados para que el motor lo persista en snapshot
  Map<String, dynamic> computeObservedCapsForNextCycle({
    required WeeklyTrainingFeedbackSummary? summary,
    required Map<String, VolumeLimits>? limitsByMuscle,
    required Map<String, dynamic> existingCaps,
  }) {
    return _updateMuscleObservedCaps(
      summary: summary,
      limitsByMuscle: limitsByMuscle,
      existingCaps: existingCaps,
    );
  }

  bool _isReadinessLow(TrainingFeedback? f) {
    if (f == null) return false;
    // Umbrales conservadores: evita progresar bajo condiciones subóptimas.
    return f.sleepHours < 6.0 || f.stressLevel >= 7.0;
  }

  bool _shouldBlockIntensification({
    required TrainingFeedback? latestFeedback,
    required WeeklyTrainingFeedbackSummary? weeklyFeedback,
    required bool hasLogs,
  }) {
    // C3: Regla dura: sin logs => no intensificación (no hay señal de tolerancia).
    if (!hasLogs) return true;

    // C3: Readiness baja => bloquear siempre.
    if (_isReadinessLow(latestFeedback)) return true;

    // C3: Si hay feedback semanal, úsalo como fuente de verdad.
    if (weeklyFeedback != null) {
      if (weeklyFeedback.deloadRecommended) return true;
      if (!weeklyFeedback.progressionAllowed) return true;
      if (weeklyFeedback.fatigueExpectation == 'high') return true;

      // C3: Volumen alto (adherencia < 0.75 o avgEffort >= 8.5) => bloquear
      if (weeklyFeedback.adherenceRatio < 0.75) return true;
      if (weeklyFeedback.avgEffort >= 8.5) return true;
    }

    return false;
  }

  List<ExercisePrescription> _stripFailureAndIntensification(
    List<ExercisePrescription> list,
  ) {
    // Único flag explícito hoy: allowFailureOnLastSet
    return list
        .map(
          (p) => p.allowFailureOnLastSet
              ? p.copyWith(allowFailureOnLastSet: false)
              : p,
        )
        .toList();
  }

  /// C3: Progresión mínima (una sola palanca)
  ProgressionAction _chooseProgression({
    required bool progressionAllowed,
    required bool readinessLow,
    required bool hasLogs,
    required ExercisePrescription prescription,
  }) {
    if (!progressionAllowed || readinessLow || !hasLogs) {
      return ProgressionAction.none;
    }

    // Prioridad conservadora: reps → sets (load no es aplicable en ExercisePrescription)
    if (_canIncreaseReps(prescription)) return ProgressionAction.reps;
    if (_canIncreaseSets(prescription)) return ProgressionAction.sets;

    return ProgressionAction.none;
  }

  bool _canIncreaseReps(ExercisePrescription p) {
    // Permitir aumentar reps si el rango no está al máximo
    // repRange es un rango (min-max), no es null
    return p.repRange.max < 15; // Cap conservador: hasta 15 reps máx
  }

  bool _canIncreaseSets(ExercisePrescription p) {
    // Permitir aumentar sets si está por debajo de un límite razonable
    return p.sets < 6; // Cap conservador
  }

  /// C3: Límites por microciclo (anti-salto)
  int _capSets(int sets) => sets + 1; // +1 set

  /// C3: Aplicar progresión mínima a una prescripción
  ExercisePrescription _applyMinimalProgression(
    ExercisePrescription p,
    ProgressionAction action,
  ) {
    switch (action) {
      case ProgressionAction.reps:
        // Incrementar el límite máximo del rango en +1 rep
        final newRepRange = RepRange(p.repRange.min, p.repRange.max + 1);
        return p.copyWith(repRange: newRepRange);
      case ProgressionAction.load:
        // No aplicable en ExercisePrescription
        return p;
      case ProgressionAction.sets:
        return p.copyWith(sets: _capSets(p.sets));
      case ProgressionAction.none:
        return p;
    }
  }

  Phase8AdaptationResult adapt({
    required TrainingFeedback? latestFeedback,
    required TrainingHistory? history,
    required List<TrainingSessionLog> logs,
    required Map<int, Map<int, List<ExercisePrescription>>>
    weekDayPrescriptions,
    Map<String, VolumeLimits>? volumeLimitsByMuscle,
    int plannedSessions = 0,
    TrainingLevel? trainingLevel,
    Map<int, String>? weekFatigueExpectation,
    ManualOverride? manualOverride,
    WeeklyTrainingFeedbackSummary? weeklyFeedbackSummary,
  }) {
    final decisions = <DecisionTrace>[];

    final readinessLow = _isReadinessLow(latestFeedback);
    final blockIntensification = _shouldBlockIntensification(
      latestFeedback: latestFeedback,
      weeklyFeedback: weeklyFeedbackSummary,
      hasLogs: logs.isNotEmpty,
    );

    // REGLA: Adaptación SOLO con bitácora (logs). Si no hay logs, no se adapta.
    if (logs.isEmpty) {
      decisions.add(
        DecisionTrace.info(
          phase: 'Phase8Adaptation',
          category: 'no_logs_no_adaptation',
          description: 'Sin logs: se mantiene baseline sin cambios',
        ),
      );

      final sanitized = <int, Map<int, List<ExercisePrescription>>>{};
      weekDayPrescriptions.forEach((weekIdx, days) {
        sanitized[weekIdx] = <int, List<ExercisePrescription>>{};
        days.forEach((dayIdx, pres) {
          sanitized[weekIdx]![dayIdx] = blockIntensification
              ? _stripFailureAndIntensification(pres)
              : pres;
        });
      });

      return Phase8AdaptationResult(
        adaptedWeekDayPrescriptions: sanitized,
        decisions: decisions,
      );
    }

    // PRIORIDAD 1: Usar señales del WeeklyTrainingFeedbackSummary si está disponible
    if (weeklyFeedbackSummary != null) {
      decisions.add(
        DecisionTrace.info(
          phase: 'Phase8Adaptation',
          category: 'weekly_feedback_summary_received',
          description:
              'Usando señales reales del WeeklyTrainingFeedbackSummary',
          context: {
            'signal': weeklyFeedbackSummary.signal,
            'fatigueExpectation': weeklyFeedbackSummary.fatigueExpectation,
            'progressionAllowed': weeklyFeedbackSummary.progressionAllowed,
            'deloadRecommended': weeklyFeedbackSummary.deloadRecommended,
            'adherenceRatio': weeklyFeedbackSummary.adherenceRatio,
            'avgEffort': weeklyFeedbackSummary.avgEffort,
            'avgRIR': weeklyFeedbackSummary.avgReportedRIR,
            'painEvents': weeklyFeedbackSummary.painEvents,
            'stoppedEarlyEvents': weeklyFeedbackSummary.stoppedEarlyEvents,
            'reasons': weeklyFeedbackSummary.reasons,
          },
        ),
      );

      return _adaptWithWeeklyFeedback(
        weeklyFeedback: weeklyFeedbackSummary,
        weekDayPrescriptions: weekDayPrescriptions,
        volumeLimitsByMuscle: volumeLimitsByMuscle,
        trainingLevel: trainingLevel,
        manualOverride: manualOverride,
        readinessLow: readinessLow,
        blockIntensification: blockIntensification,
        decisions: decisions,
      );
    }

    // FALLBACK: Lógica legacy con latestFeedback + logs (mantener compatibilidad)
    if (logs.isEmpty &&
        latestFeedback == null &&
        (history == null || !history.hasData)) {
      decisions.add(
        DecisionTrace.info(
          phase: 'Phase8Adaptation',
          category: 'data_check',
          description: 'Datos insuficientes para adaptar. Se mantiene el plan.',
        ),
      );
      return Phase8AdaptationResult(
        adaptedWeekDayPrescriptions: weekDayPrescriptions,
        decisions: decisions,
      );
    }

    final sessionsPlanned = plannedSessions > 0
        ? plannedSessions
        : weekDayPrescriptions.values.first.length *
              weekDayPrescriptions.length;

    final codeToMuscle = _buildCodeToMuscleMap(weekDayPrescriptions);
    final weeklyPerformance = _computeWeeklyPerformanceByMuscle(
      logs,
      codeToMuscle,
    );
    final weeklyAvgRpe = _computeWeeklyAvgRpe(logs);
    final adherenceFromLogs = _computeAdherenceFromLogs(logs, sessionsPlanned);

    final fatigue = latestFeedback?.fatigue ?? 5.0;
    final soreness = latestFeedback?.soreness ?? 5.0;
    final adherence =
        latestFeedback?.adherence ??
        history?.averageAdherence ??
        adherenceFromLogs;
    final avgRpeLogs = weeklyAvgRpe.isNotEmpty
        ? weeklyAvgRpe.values.reduce((a, b) => a + b) / weeklyAvgRpe.length
        : 7.0;

    decisions.add(
      DecisionTrace.info(
        phase: 'Phase8Adaptation',
        category: 'log_metrics_summary',
        description: 'Métricas derivadas de logs',
        context: {
          'adherenceFromLogs': adherenceFromLogs,
          'avgRpeFromLogs': avgRpeLogs,
          'weeklyPerformance': weeklyPerformance,
        },
      ),
    );

    final fatigueSignal =
        fatigue >= 7.0 || soreness >= 7.0 || avgRpeLogs >= 8.0;
    final progressSignal = _detectProgress(weeklyPerformance);
    final plateauSignal = _detectPlateau(weeklyPerformance) && !fatigueSignal;
    final lowAdherence = adherence < 0.8 && !fatigueSignal;

    decisions.add(
      DecisionTrace.info(
        phase: 'Phase8Adaptation',
        category: 'signal_detection',
        description: 'Detección de señales',
        context: {
          'fatigueSignal': fatigueSignal,
          'progressSignal': progressSignal,
          'plateauSignal': plateauSignal,
          'lowAdherence': lowAdherence,
        },
      ),
    );

    final progressionDecision = _decideProgression(
      adherence: adherence,
      fatigue: fatigue,
      soreness: soreness,
      progressSignal: progressSignal,
      plateauSignal: plateauSignal,
    );

    decisions.add(
      DecisionTrace.info(
        phase: 'Phase8Adaptation',
        category: 'progression_decision',
        description: 'Decisión de progresión centralizada',
        context: {
          'progressAllowed': progressionDecision.progressAllowed,
          'reasons': progressionDecision.reasons,
        },
      ),
    );

    final adaptation = _decideAdaptation(
      fatigueSignal: fatigueSignal,
      progressSignal: progressSignal,
      plateauSignal: plateauSignal,
      lowAdherence: lowAdherence,
      trainingLevel: trainingLevel,
    );

    if (!progressionDecision.progressAllowed) {
      final originalVolume = adaptation.volumeFactorNext;
      final originalRir = adaptation.rirDelta;

      if (adaptation.volumeFactorNext > 1.0) {
        adaptation.volumeFactorNext = 1.0;
      }
      if (adaptation.rirDelta < 0) {
        adaptation.rirDelta = 0.0;
      }

      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase8Adaptation',
          category: 'progression_blocked_reason',
          description: 'Progresión bloqueada por señales de riesgo',
          context: {
            'reasons': progressionDecision.reasons,
            'volumeFactorBefore': originalVolume,
            'rirDeltaBefore': originalRir,
          },
        ),
      );
    }

    // Guardrails
    if (trainingLevel == TrainingLevel.beginner &&
        adaptation.volumeFactorNext > 1.05) {
      adaptation.volumeFactorNext = 1.05;
      adaptation.notes.add('beginner_cap');
    }

    final out = <int, Map<int, List<ExercisePrescription>>>{};
    final rotationList = <String, String>{};

    for (final wEntry
        in weekDayPrescriptions.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key))) {
      final wIdx = wEntry.key;
      final dayMap = <int, List<ExercisePrescription>>{};

      for (final dEntry
          in wEntry.value.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key))) {
        final day = dEntry.key;
        var list = dEntry.value.map((e) => e.copyWith()).toList();

        if (lowAdherence) {
          list = _simplifyPrescriptions(list);
        }

        // C3: Aplicar progresión mínima (una sola palanca) o ajuste de volumen
        list = list.map((p) {
          // Decidir si aplicar progresión mínima
          final progressionAction = _chooseProgression(
            progressionAllowed: progressionDecision.progressAllowed,
            readinessLow: false, // Ya verificado en progressionDecision
            hasLogs: true, // Ya verificado antes
            prescription: p,
          );

          // Si hay acción de progresión, aplicarla directamente
          if (progressionAction != ProgressionAction.none) {
            return _applyMinimalProgression(p, progressionAction);
          }

          // Sino, aplicar factor de volumen (legacy para deload/maintain)
          var newSets = (p.sets * adaptation.volumeFactorNext).round();

          // Respetar overrides de volumen si existen
          final overrideForMuscle =
              manualOverride?.volumeOverrides?[p.muscleGroup.name];

          if (volumeLimitsByMuscle != null) {
            final limits = volumeLimitsByMuscle[p.muscleGroup.name];
            if (limits != null) {
              final minSets = limits.mev;
              var maxSets = limits.mrv;

              // Si hay override de MRV, usarlo como límite superior
              if (overrideForMuscle != null && overrideForMuscle.mrv != null) {
                maxSets = overrideForMuscle.mrv!;
                decisions.add(
                  DecisionTrace.info(
                    phase: 'Phase8Adaptation',
                    category: 'override_respected_during_adaptation',
                    description:
                        'MRV override respetado para ${p.muscleGroup.name}',
                    context: {'mrvOverride': maxSets, 'mrvBase': limits.mrv},
                  ),
                );
              }

              if (newSets < minSets) {
                newSets = minSets;
                decisions.add(
                  DecisionTrace.warning(
                    phase: 'Phase8Adaptation',
                    category: 'guardrail_clamps',
                    description: 'Clamp a MEV para ${p.muscleGroup.name}',
                  ),
                );
              }
              if (newSets > maxSets) {
                newSets = maxSets;
                decisions.add(
                  DecisionTrace.warning(
                    phase: 'Phase8Adaptation',
                    category: 'guardrail_clamps',
                    description: 'Clamp a MRV para ${p.muscleGroup.name}',
                    context: {'finalMrv': maxSets},
                  ),
                );
              }
            }
          }

          // Regla: nunca modificar RIR con doubles (ni emitir decimales).
          // Phase8 aplica cambios discretos vía sets (y/o reps/rest si se implementa).
          return p.copyWith(sets: newSets);
        }).toList();

        // Rotation on plateau
        if (plateauSignal) {
          list = _rotateExercises(list, rotationList);
        }

        dayMap[day] = list;
      }

      out[wIdx] = dayMap;
    }

    decisions.add(
      DecisionTrace.info(
        phase: 'Phase8Adaptation',
        category: 'adaptation_actions',
        description: 'Acciones aplicadas',
        context: {
          'volumeFactorNext': adaptation.volumeFactorNext,
          'rirDelta': adaptation.rirDelta,
          'intensificationAllowedNext': adaptation.intensificationAllowedNext,
          'deloadEarly': adaptation.deloadEarly,
          'rotationList': rotationList,
          'notes': adaptation.notes,
          'progressAllowed': progressionDecision.progressAllowed,
          'progressionReasons': progressionDecision.reasons,
        },
      ),
    );

    // C3: Validación final - el plan debe progresar o mantener, nunca quedar ambiguo
    var hasValidProgression = false;
    for (final weekMap in out.values) {
      for (final dayList in weekMap.values) {
        if (dayList.isNotEmpty) {
          hasValidProgression = true;
          break;
        }
      }
      if (hasValidProgression) break;
    }

    assert(
      hasValidProgression,
      'C3: El plan debe progresar o mantener, nunca quedar ambiguo',
    );

    return Phase8AdaptationResult(
      adaptedWeekDayPrescriptions: out,
      decisions: decisions,
    );
  }

  List<ExercisePrescription> _simplifyPrescriptions(
    List<ExercisePrescription> original,
  ) {
    final grouped = <String, ExercisePrescription>{};
    for (final p in original) {
      final key = p.muscleGroup.name;
      if (!grouped.containsKey(key)) {
        grouped[key] = p;
      } else {
        final prev = grouped[key]!;
        grouped[key] = prev.copyWith(sets: prev.sets + p.sets);
      }
    }
    return grouped.values.toList();
  }

  Map<String, String> _buildCodeToMuscleMap(
    Map<int, Map<int, List<ExercisePrescription>>> weekDayPrescriptions,
  ) {
    final map = <String, String>{};
    for (final week in weekDayPrescriptions.values) {
      for (final day in week.values) {
        for (final p in day) {
          map[p.exerciseCode] = p.muscleGroup.name;
        }
      }
    }
    return map;
  }

  Map<int, Map<String, double>> _computeWeeklyPerformanceByMuscle(
    List<TrainingSessionLog> logs,
    Map<String, String> codeToMuscle,
  ) {
    final out = <int, Map<String, double>>{};
    for (var i = 0; i < logs.length; i++) {
      final weekIdx = (i ~/ 7) + 1;
      final weekMap = out.putIfAbsent(weekIdx, () => <String, double>{});
      for (final entry in logs[i].entries) {
        final muscle = codeToMuscle[entry.exerciseIdOrName] ?? 'unknown';
        final topLoad = entry.load.isNotEmpty
            ? entry.load.reduce((a, b) => a > b ? a : b)
            : 0.0;
        final reps = entry.reps.isNotEmpty
            ? entry.reps.reduce((a, b) => a > b ? a : b)
            : 0;
        final proxy = topLoad * (1 + reps / 30);
        final current = weekMap[muscle] ?? 0.0;
        if (proxy > current) {
          weekMap[muscle] = proxy;
        }
      }
    }
    return out;
  }

  Map<int, double> _computeWeeklyAvgRpe(List<TrainingSessionLog> logs) {
    final out = <int, double>{};
    for (var i = 0; i < logs.length; i++) {
      final weekIdx = (i ~/ 7) + 1;
      final allRpe = <double>[];
      for (final entry in logs[i].entries) {
        if (entry.rpe != null) {
          allRpe.addAll(entry.rpe!);
        }
      }
      if (allRpe.isNotEmpty) {
        final avg = allRpe.reduce((a, b) => a + b) / allRpe.length;
        out[weekIdx] = avg;
      }
    }
    return out;
  }

  double _computeAdherenceFromLogs(List<TrainingSessionLog> logs, int planned) {
    if (planned <= 0) return 1.0;
    return (logs.length / planned).clamp(0.0, 1.5);
  }

  bool _detectProgress(Map<int, Map<String, double>> perf) {
    if (perf.length < 2) return false;
    final keys = perf.keys.toList()..sort();
    final last = perf[keys.last] ?? {};
    final prev = perf[keys[keys.length - 2]] ?? {};
    double sumPrev = 0, sumLast = 0;
    for (final m in last.keys) {
      sumLast += last[m] ?? 0;
      sumPrev += prev[m] ?? 0;
    }
    if (sumPrev == 0) return false;
    final change = (sumLast - sumPrev) / sumPrev;
    return change >= 0.01;
  }

  bool _detectPlateau(Map<int, Map<String, double>> perf) {
    if (perf.length < 2) return false;
    final keys = perf.keys.toList()..sort();
    final last = perf[keys.last] ?? {};
    final prev = perf[keys[keys.length - 2]] ?? {};
    double sumPrev = 0, sumLast = 0;
    for (final m in last.keys) {
      sumLast += last[m] ?? 0;
      sumPrev += prev[m] ?? 0;
    }
    if (sumPrev == 0) return false;
    final change = (sumLast - sumPrev) / sumPrev;
    return change < 0.005;
  }

  ProgressionDecision _decideProgression({
    required double adherence,
    required double fatigue,
    required double soreness,
    required bool progressSignal,
    required bool plateauSignal,
  }) {
    final reasons = <String>[];
    var allow = true;

    if (fatigue >= 7.0 || soreness >= 7.0) {
      allow = false;
      reasons.add('fatigue_or_soreness_high');
    }

    if (adherence < 0.8) {
      allow = false;
      reasons.add('low_adherence');
    }

    if (!progressSignal) {
      allow = false;
      reasons.add(plateauSignal ? 'performance_plateau' : 'no_progress_signal');
    }

    return ProgressionDecision(
      progressAllowed: allow,
      volumeMultiplier: allow ? 1.0 : 1.0,
      rirAdjustment: allow ? 0.0 : 0.0,
      reasons: reasons,
    );
  }

  _AdaptationDecision _decideAdaptation({
    required bool fatigueSignal,
    required bool progressSignal,
    required bool plateauSignal,
    required bool lowAdherence,
    TrainingLevel? trainingLevel,
  }) {
    if (fatigueSignal) {
      return _AdaptationDecision(
        volumeFactorNext: 0.85,
        rirDelta: 0.0,
        intensificationAllowedNext: false,
        deloadEarly: true,
      );
    }
    if (progressSignal) {
      final inc = trainingLevel == TrainingLevel.beginner ? 1.05 : 1.08;
      return _AdaptationDecision(
        volumeFactorNext: inc,
        rirDelta: 0.0,
        intensificationAllowedNext: true,
      );
    }
    if (plateauSignal) {
      return _AdaptationDecision(
        volumeFactorNext: 1.03,
        rirDelta: 0.0,
        intensificationAllowedNext: false,
        rotate: true,
        repBiasShift: true,
      );
    }
    if (lowAdherence) {
      return _AdaptationDecision(
        volumeFactorNext: 1.0,
        rirDelta: 0.0,
        intensificationAllowedNext: false,
        simplify: true,
      );
    }
    return _AdaptationDecision(
      volumeFactorNext: 1.0,
      rirDelta: 0.0,
      intensificationAllowedNext: false,
    );
  }

  List<ExercisePrescription> _rotateExercises(
    List<ExercisePrescription> list,
    Map<String, String> rotationList,
  ) {
    return list.map((p) {
      final tags = _exerciseTags(p.exerciseCode);
      final replacement = _deterministicAlt(tags, p.exerciseCode);
      if (replacement != p.exerciseCode) {
        rotationList[p.exerciseCode] = replacement;
        return p.copyWith(exerciseCode: replacement, exerciseName: replacement);
      }
      return p;
    }).toList();
  }

  Set<String> _exerciseTags(String code) {
    final c = code.toLowerCase();
    final tags = <String>{};
    if (c.contains('squat')) tags.add('squat');
    if (c.contains('deadlift') || c.contains('hinge') || c.contains('rdl')) {
      tags.add('hinge');
    }
    if (c.contains('thrust') || c.contains('bridge')) tags.add('thrust');
    if (c.contains('row')) tags.add('row');
    if (c.contains('press')) tags.add('press');
    if (c.contains('curl')) tags.add('curl');
    if (c.contains('fly')) tags.add('fly');
    if (c.contains('abduction')) tags.add('abduction');
    return tags;
  }

  String _deterministicAlt(Set<String> tags, String original) {
    if (tags.contains('squat')) return '${original}_legpress_alt';
    if (tags.contains('hinge')) return '${original}_rdl_alt';
    if (tags.contains('thrust')) return '${original}_hipthrust_alt';
    if (tags.contains('row')) return '${original}_row_alt';
    if (tags.contains('press')) return '${original}_press_alt';
    if (tags.contains('curl')) return '${original}_curl_alt';
    if (tags.contains('fly')) return '${original}_fly_alt';
    if (tags.contains('abduction')) return '${original}_abduction_alt';
    return '${original}_alt';
  }

  /// Adaptación basada en WeeklyTrainingFeedbackSummary (señales reales).
  /// Conservador: solo progresa ante certeza total.
  Phase8AdaptationResult _adaptWithWeeklyFeedback({
    required WeeklyTrainingFeedbackSummary weeklyFeedback,
    required Map<int, Map<int, List<ExercisePrescription>>>
    weekDayPrescriptions,
    Map<String, VolumeLimits>? volumeLimitsByMuscle,
    TrainingLevel? trainingLevel,
    ManualOverride? manualOverride,
    required bool readinessLow,
    required bool blockIntensification,
    required List<DecisionTrace> decisions,
  }) {
    // Determinar acción según señales
    double volumeFactor = 1.0;
    double rirDelta = 0.0;
    String action = 'maintain';

    // DELOAD RECOMENDADO (prioridad máxima)
    if (weeklyFeedback.deloadRecommended) {
      volumeFactor = 0.85; // -15% volumen conservador
      rirDelta = 0.0;
      action = 'deload';

      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase8Adaptation',
          category: 'phase_8_adaptation_applied',
          description:
              'Deload aplicado por señales de alta fatiga o baja adherencia',
          context: {
            'action': action,
            'volumeFactor': volumeFactor,
            'rirDelta': rirDelta,
            'fatigueExpectation': weeklyFeedback.fatigueExpectation,
            'adherenceRatio': weeklyFeedback.adherenceRatio,
            'reasons': weeklyFeedback.reasons,
          },
        ),
      );
    }
    // PROGRESIÓN PERMITIDA (solo ante certeza total)
    else if (weeklyFeedback.progressionAllowed) {
      // Progresión pequeña y conservadora
      final progressionIncrement = trainingLevel == TrainingLevel.beginner
          ? 1.05
          : trainingLevel == TrainingLevel.advanced
          ? 1.08
          : 1.06;

      volumeFactor = progressionIncrement;
      rirDelta = 0.0; // Mantener RIR
      action = 'progress';

      decisions.add(
        DecisionTrace.info(
          phase: 'Phase8Adaptation',
          category: 'phase_8_adaptation_applied',
          description: 'Progresión incremental aplicada (señal positiva)',
          context: {
            'action': action,
            'volumeFactor': volumeFactor,
            'increment': '${((volumeFactor - 1.0) * 100).toStringAsFixed(0)}%',
            'signal': weeklyFeedback.signal,
            'adherenceRatio': weeklyFeedback.adherenceRatio,
            'avgEffort': weeklyFeedback.avgEffort,
            'avgRIR': weeklyFeedback.avgReportedRIR,
          },
        ),
      );
    }
    // MANTENER (señal ambigua o negativa sin deload extremo)
    else {
      volumeFactor = 1.0;
      rirDelta = 0.0;
      action = 'maintain';

      decisions.add(
        DecisionTrace.info(
          phase: 'Phase8Adaptation',
          category: 'phase_8_adaptation_skipped',
          description: 'Plan mantenido sin cambios (señal no positiva)',
          context: {
            'action': action,
            'signal': weeklyFeedback.signal,
            'progressionAllowed': weeklyFeedback.progressionAllowed,
            'reasons': weeklyFeedback.reasons,
          },
        ),
      );
    }

    // Readiness Gate: si readiness es baja y la acción es progresión, bloquearla
    if (readinessLow && action == 'progress') {
      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase8Adaptation',
          category: 'readiness_gate_block_progression',
          description:
              'Readiness baja (sueño/estrés): se bloquea progresión esta semana',
          context: {
            'previousAction': action,
            'forcedAction': 'maintain',
            'volumeFactorBefore': volumeFactor,
          },
        ),
      );
      action = 'maintain';
      volumeFactor = 1.0;
      rirDelta = 0.0;
    }

    // Aplicar ajustes a las prescripciones
    final adapted = <int, Map<int, List<ExercisePrescription>>>{};

    for (final wEntry in weekDayPrescriptions.entries) {
      final wIdx = wEntry.key;
      final dayMap = <int, List<ExercisePrescription>>{};

      for (final dEntry in wEntry.value.entries) {
        final day = dEntry.key;
        final list = dEntry.value.map((p) {
          var newSets = (p.sets * volumeFactor).round();

          // Respetar límites MEV/MRV
          if (volumeLimitsByMuscle != null) {
            final limits = volumeLimitsByMuscle[p.muscleGroup.name];
            if (limits != null) {
              if (newSets < limits.mev) {
                newSets = limits.mev;
                decisions.add(
                  DecisionTrace.warning(
                    phase: 'Phase8Adaptation',
                    category: 'guardrail_clamps',
                    description:
                        'Sets ajustados a MEV para ${p.muscleGroup.name}',
                    context: {
                      'mev': limits.mev,
                      'original': p.sets,
                      'adjusted': newSets,
                    },
                  ),
                );
              }

              var maxSets = limits.mrv;
              // Respetar override manual de MRV
              final overrideForMuscle =
                  manualOverride?.volumeOverrides?[p.muscleGroup.name];
              if (overrideForMuscle != null && overrideForMuscle.mrv != null) {
                maxSets = overrideForMuscle.mrv!;
              }

              if (newSets > maxSets) {
                newSets = maxSets;
                decisions.add(
                  DecisionTrace.warning(
                    phase: 'Phase8Adaptation',
                    category: 'guardrail_clamps',
                    description:
                        'Sets ajustados a MRV para ${p.muscleGroup.name}',
                    context: {
                      'mrv': maxSets,
                      'original': p.sets,
                      'adjusted': newSets,
                    },
                  ),
                );
              }
            }
          }

          // Regla: no modificar RIR en Phase8 (evitar decimales).
          return p.copyWith(sets: newSets);
        }).toList();

        dayMap[day] = blockIntensification
            ? _stripFailureAndIntensification(list)
            : list;
      }
      adapted[wIdx] = dayMap;
    }

    // C3: Validación final - el plan debe tener contenido
    var hasValidContent = false;
    for (final weekMap in adapted.values) {
      for (final dayList in weekMap.values) {
        if (dayList.isNotEmpty) {
          hasValidContent = true;
          break;
        }
      }
      if (hasValidContent) break;
    }

    assert(
      hasValidContent,
      'C3: El plan adaptado debe tener al menos una prescripción',
    );

    return Phase8AdaptationResult(
      adaptedWeekDayPrescriptions: adapted,
      decisions: decisions,
    );
  }
}

class _AdaptationDecision {
  double volumeFactorNext;
  double rirDelta;
  bool intensificationAllowedNext;
  bool deloadEarly;
  bool rotate;
  bool repBiasShift;
  bool simplify;
  List<String> notes;

  _AdaptationDecision({
    required this.volumeFactorNext,
    required this.rirDelta,
    required this.intensificationAllowedNext,
    this.deloadEarly = false,
    this.rotate = false,
    this.repBiasShift = false,
    this.simplify = false,
    List<String>? notes,
  }) : notes = notes ?? [];
}
