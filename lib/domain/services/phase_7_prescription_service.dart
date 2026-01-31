import 'package:hcs_app_lap/core/enums/effort_intent.dart';
import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/core/enums/muscle_group.dart';
import 'package:hcs_app_lap/core/enums/training_phase.dart';
import 'package:hcs_app_lap/core/enums/training_level.dart';
import 'package:hcs_app_lap/domain/entities/decision_trace.dart';
import 'package:hcs_app_lap/domain/entities/effort_budget.dart';
import 'package:hcs_app_lap/domain/entities/manual_override.dart';
import 'package:hcs_app_lap/domain/entities/exercise_catalog.dart';
import 'package:hcs_app_lap/domain/entities/rep_range.dart';
import 'package:hcs_app_lap/domain/entities/exercise_prescription.dart';
import 'package:hcs_app_lap/domain/entities/volume_limits.dart';
import 'package:hcs_app_lap/domain/models/rir_target.dart';
import 'package:hcs_app_lap/domain/policies/day_exercise_ordering_policy.dart';
import 'package:hcs_app_lap/domain/services/phase_5_periodization_service.dart';
import 'package:hcs_app_lap/domain/entities/split_template.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/services/phase_1_data_ingestion_service.dart'
    show DerivedTrainingContext;
import 'package:hcs_app_lap/domain/services/failure_policy_service.dart';
import 'package:hcs_app_lap/domain/constants/rest_period_calculator.dart';

class Phase7PrescriptionResult {
  /// weekIndex -> day -> prescriptions
  final Map<int, Map<int, List<ExercisePrescription>>> weekDayPrescriptions;
  final List<DecisionTrace> decisions;

  const Phase7PrescriptionResult({
    required this.weekDayPrescriptions,
    required this.decisions,
  });
}

/// Fase 7: Convertir dailyVolume + selección de ejercicios a ExercisePrescription
/// - Asigna sets por ejercicio
/// - Reps según objetivo (hipertrofia)
/// - RIR según TrainingPhase (con ajustes por trainingLevel en intensification)
/// - Descanso según tipo (compuesto vs accesorio)
class Phase7PrescriptionService {
  final FailurePolicyService failurePolicy;

  Phase7PrescriptionService({FailurePolicyService? failurePolicy})
    : failurePolicy = failurePolicy ?? FailurePolicyService();
  Phase7PrescriptionResult buildPrescriptions({
    required SplitTemplate baseSplit,
    required Phase5PeriodizationResult periodization,
    required Map<int, Map<int, Map<MuscleGroup, List<ExerciseEntry>>>>
    selections,
    Map<String, VolumeLimits>? volumeLimitsByMuscle,
    TrainingLevel? trainingLevel,
    DerivedTrainingContext? derivedContext,
    TrainingProfile? profile,
    ManualOverride? manualOverride,
  }) {
    final decisions = <DecisionTrace>[];
    final out = <int, Map<int, List<ExercisePrescription>>>{};

    for (final week in periodization.weeks) {
      final wIdx = week.weekIndex;
      final weekMap = <int, List<ExercisePrescription>>{};
      final phase = week.phase;

      // Overrides de intensificación (se aplican por semana)
      bool allowIntens = derivedContext?.intensificationAllowed ?? true;
      int maxPerWeek = derivedContext?.intensificationMaxPerSession ?? 1;
      if (manualOverride != null) {
        allowIntens = manualOverride.allowIntensification;
        maxPerWeek = manualOverride.intensificationMaxPerWeek;
        decisions.add(
          DecisionTrace.info(
            phase: 'Phase7Prescription',
            category: 'intensification_override_applied',
            description:
                'Override de intensificación aplicado (allow=$allowIntens, maxPerWeek=$maxPerWeek)',
            context: {
              'week': wIdx,
              'allowIntensification': allowIntens,
              'maxPerWeek': maxPerWeek,
            },
          ),
        );
      }

      // Crear EffortBudget para la semana
      final allMuscles = <String>{};
      for (final daySelection
          in selections[wIdx]?.values ??
              <Map<MuscleGroup, List<ExerciseEntry>>>[]) {
        allMuscles.addAll(daySelection.keys.map<String>((mg) => mg.name));
      }
      var effortBudget = EffortBudget.initial(
        maxTechniquesPerWeek: maxPerWeek,
        muscles: allMuscles.toList(),
        maxPerMuscle: 1, // Máximo 1 técnica por músculo
      );

      // Usar datos de Phase 5
      final repRange = RepRange(week.repRangeMin, week.repRangeMax);

      decisions.add(
        DecisionTrace.info(
          phase: 'Phase7Prescription',
          category: 'week_setup',
          description:
              'Semana $wIdx: ${phase.name} (intent=${week.effortIntent.name}, repBias=${week.repBias.name})',
          context: {
            'weekIndex': wIdx,
            'phase': phase.name,
            'effortIntent': week.effortIntent.name,
            'repBias': week.repBias.name,
            'fatigueExpectation': week.fatigueExpectation,
            'repRange': '${repRange.min}-${repRange.max}',
          },
        ),
      );

      for (var d = 1; d <= baseSplit.daysPerWeek; d++) {
        final daySelection =
            selections[wIdx]?[d] ?? const <MuscleGroup, List<ExerciseEntry>>{};
        final dayVolume = week.dailyVolume[d] ?? const <String, int>{};

        final planned = <(_ExerciseSlot, int)>[]; // entry + sets

        for (final mg in daySelection.keys) {
          final selected = daySelection[mg] ?? const <ExerciseEntry>[];
          final setsTotal = dayVolume[mg.name] ?? 0;
          if (setsTotal <= 0 || selected.isEmpty) continue;

          if (selected.length == 1) {
            planned.add((
              _ExerciseSlot(mg: mg, entry: selected.first),
              setsTotal,
            ));
          } else {
            final s1 = (setsTotal * 0.6).round();
            final s2 = setsTotal - s1;
            planned.add((_ExerciseSlot(mg: mg, entry: selected[0]), s1));
            if (s2 > 0) {
              planned.add((_ExerciseSlot(mg: mg, entry: selected[1]), s2));
            }
          }
        }

        if (planned.isEmpty) {
          weekMap[d] = const <ExercisePrescription>[];
          decisions.add(
            DecisionTrace.warning(
              phase: 'Phase7Prescription',
              category: 'empty_day_after_planning',
              description: 'Día $d sin ejercicios planificados tras filtros',
              context: {'day': d, 'week': wIdx},
            ),
          );
          continue;
        }

        final ordered = _orderByHierarchy(planned, profile: profile);

        var labelIndex = 0;
        String nextLabel() =>
            String.fromCharCode('A'.codeUnitAt(0) + labelIndex++);

        final prescriptions = <ExercisePrescription>[];
        for (final item in ordered) {
          final pres = _buildPrescription(
            day: d,
            ex: item.entry,
            role: item.role,
            sets: item.sets,
            effortIntent: week.effortIntent,
            repRange: repRange,
            label: nextLabel(),
            phase: phase,
            weekIndex: wIdx,
            intensityTarget: week.intensityTarget,
            derivedContext: derivedContext,
            profile: profile,
            fatigueExpectation: week.fatigueExpectation,
            trainingLevel: trainingLevel,
            allowIntensification: allowIntens,
            effortBudget: effortBudget,
            volumeLimitsByMuscle: volumeLimitsByMuscle,
            baseSplit: baseSplit,
            onEffortBudgetUpdated: (newBudget) {
              effortBudget = newBudget;
            },
            decisions: decisions,
          );
          prescriptions.add(pres);
        }

        _validateSessionRoles(
          day: d,
          week: wIdx,
          ordered: ordered,
          decisions: decisions,
        );

        weekMap[d] = prescriptions;

        decisions.add(
          DecisionTrace.info(
            phase: 'Phase7Prescription',
            category: 'day_prescriptions',
            description:
                'Semana $wIdx Día $d: ${prescriptions.length} ejercicios generados',
            context: {
              'prescriptions': prescriptions
                  .map((p) => p.exerciseCode)
                  .toList(),
            },
          ),
        );
      }

      out[wIdx] = weekMap;
    }

    // Aplicar política de ordenamiento AA por día
    final orderedOutput = <int, Map<int, List<ExercisePrescription>>>{};
    for (final wIdx in out.keys) {
      final weekMap = <int, List<ExercisePrescription>>{};
      for (final dayIdx in out[wIdx]!.keys) {
        final dayPrescriptions = out[wIdx]![dayIdx]!;
        // Aplicar política AA de ordenamiento
        final ordered = DayExerciseOrderingPolicy.orderDay(dayPrescriptions);
        // Re-asignar labels secuenciales tras ordenamiento
        final relabeled = <ExercisePrescription>[];
        for (var i = 0; i < ordered.length; i++) {
          final label = String.fromCharCode('A'.codeUnitAt(0) + i);
          relabeled.add(ordered[i].copyWith(label: label, order: i));
        }
        weekMap[dayIdx] = relabeled;

        decisions.add(
          DecisionTrace.info(
            phase: 'Phase7Prescription',
            category: 'day_ordering_applied',
            description:
                'Política AA aplicada a semana $wIdx día $dayIdx: ${relabeled.map((p) => p.label).join('')}',
            context: {
              'week': wIdx,
              'day': dayIdx,
              'exerciseLabelSequence': relabeled.map((p) => p.label).toList(),
              'muscleSequence': relabeled
                  .map((p) => p.muscleGroup.name)
                  .toList(),
            },
          ),
        );
      }
      orderedOutput[wIdx] = weekMap;
    }

    return Phase7PrescriptionResult(
      weekDayPrescriptions: orderedOutput,
      decisions: decisions,
    );
  }

  /// Ordena ejercicios de una sesión en jerarquía: principal → secundario → accesorio
  /// siguiendo patrones pesados primero y rotando cuando hay múltiples compuestos.
  List<_OrderedExercise> _orderByHierarchy(
    List<(_ExerciseSlot, int)> planned, {
    required TrainingProfile? profile,
  }) {
    final slots = planned
        .map(
          (p) => _OrderedExercise(
            entry: p.$1.entry,
            mg: p.$1.mg,
            sets: p.$2,
            pattern: _primaryPattern(p.$1.entry),
            role: 'pending',
          ),
        )
        .toList();

    final priorityExercises = _parsePriorityExercises(profile);
    final primaryMuscles =
        profile?.priorityMusclesPrimary
            .map((m) => m.toLowerCase().trim())
            .where((m) => m.isNotEmpty)
            .toSet() ??
        const <String>{};

    // Orden base: compuestos por patrón, luego accesorios
    int patternRank(String? p) {
      const order = ['squat', 'hinge', 'press', 'overhead', 'row', 'thrust'];
      return p == null ? order.length : order.indexOf(p).clamp(0, order.length);
    }

    bool isPriorityExercise(ExerciseEntry e) {
      if (priorityExercises.isEmpty) return false;
      final haystack = '${e.code} ${e.name}'.toLowerCase();
      return priorityExercises.any((token) => haystack.contains(token));
    }

    bool isPrimaryMuscle(MuscleGroup mg) {
      return primaryMuscles.contains(mg.name.toLowerCase());
    }

    int score(_OrderedExercise e) {
      var s = 0;
      if (isPriorityExercise(e.entry)) s -= 1000;
      if (isPrimaryMuscle(e.mg)) s -= 200;
      if (e.entry.isCompound) s -= 50;
      s += patternRank(e.pattern);
      return s;
    }

    slots.sort((a, b) {
      final sa = score(a);
      final sb = score(b);
      final sc = sa.compareTo(sb);
      if (sc != 0) return sc;
      // desempates deterministas
      final pr = patternRank(a.pattern).compareTo(patternRank(b.pattern));
      if (pr != 0) return pr;
      return a.entry.code.compareTo(b.entry.code);
    });

    final ordered = <_OrderedExercise>[];

    for (var i = 0; i < slots.length; i++) {
      final role = i == 0 ? 'primary' : (i == 1 ? 'secondary' : 'accessory');
      ordered.add(slots[i].copyWith(role: role));
    }

    // Garantizar al menos un accesorio si hay >=3 ejercicios
    final hasAccessory = ordered.any((e) => e.role == 'accessory');
    if (!hasAccessory && ordered.length >= 3) {
      final last = ordered.removeLast();
      ordered.add(last.copyWith(role: 'accessory'));
    }

    return ordered;
  }

  Set<String> _parsePriorityExercises(TrainingProfile? profile) {
    final raw = profile?.extra[TrainingExtraKeys.priorityExercises];
    if (raw == null) return const <String>{};

    if (raw is List) {
      return raw
          .map((e) => e.toString().toLowerCase().trim())
          .where((e) => e.isNotEmpty)
          .toSet();
    }
    if (raw is String) {
      return raw
          .split(',')
          .map((e) => e.toLowerCase().trim())
          .where((e) => e.isNotEmpty)
          .toSet();
    }
    return {raw.toString().toLowerCase().trim()}..remove('');
  }

  String? _primaryPattern(ExerciseEntry ex) {
    final tags = _exerciseTags(ex);
    for (final t in ['squat', 'hinge', 'press', 'overhead', 'row', 'thrust']) {
      if (tags.contains(t)) return t;
    }
    return null;
  }

  Set<String> _exerciseTags(ExerciseEntry e) {
    final tags = <String>{};
    final code = e.code.toLowerCase();
    final name = e.name.toLowerCase();
    if (code.contains('squat') || name.contains('squat')) tags.add('squat');
    if (code.contains('deadlift') ||
        code.contains('rdl') ||
        name.contains('deadlift')) {
      tags.add('hinge');
    }
    if (code.contains('thrust') ||
        code.contains('bridge') ||
        name.contains('thrust')) {
      tags.add('thrust');
    }
    if (code.contains('abduction') || name.contains('abduction')) {
      tags.add('abduction');
    }
    if (code.contains('overhead') ||
        (code.contains('press') && name.contains('overhead'))) {
      tags.add('overhead');
    }
    if (code.contains('row') || name.contains('row')) tags.add('row');
    if (code.contains('press') || name.contains('press')) tags.add('press');
    return tags;
  }

  void _validateSessionRoles({
    required int day,
    required int week,
    required List<_OrderedExercise> ordered,
    required List<DecisionTrace> decisions,
  }) {
    final hasPrimary = ordered.any((e) => e.role == 'primary');
    final hasSecondary = ordered.any((e) => e.role == 'secondary');
    final hasAccessory = ordered.any((e) => e.role == 'accessory');

    if (!hasPrimary && ordered.isNotEmpty) {
      // Promover primero a primary
      ordered[0] = ordered[0].copyWith(role: 'primary');
    }
    if (!hasSecondary && ordered.length >= 2) {
      ordered[1] = ordered[1].copyWith(role: 'secondary');
    }
    if (!hasAccessory && ordered.length >= 3) {
      ordered[ordered.length - 1] = ordered.last.copyWith(role: 'accessory');
    }

    final missing = <String>[];
    if (!hasPrimary) missing.add('primary');
    if (!hasSecondary && ordered.length >= 2) missing.add('secondary');
    if (!hasAccessory && ordered.length >= 3) missing.add('accessory');

    if (missing.isNotEmpty) {
      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase7Prescription',
          category: 'session_role_gap',
          description:
              'Día $day semana $week sin roles completos: falta ${missing.join(', ')}',
          context: {'day': day, 'week': week, 'count': ordered.length},
        ),
      );
    }
  }

  ExercisePrescription _buildPrescription({
    required int day,
    required ExerciseEntry ex,
    required String role,
    required int sets,
    required EffortIntent effortIntent,
    required RepRange repRange,
    required String label,
    required TrainingPhase phase,
    required int weekIndex,
    required double intensityTarget,
    required DerivedTrainingContext? derivedContext,
    required TrainingProfile? profile,
    required String fatigueExpectation,
    required TrainingLevel? trainingLevel,
    required bool allowIntensification,
    required EffortBudget effortBudget,
    required Map<String, VolumeLimits>? volumeLimitsByMuscle,
    required SplitTemplate baseSplit,
    required Function(EffortBudget) onEffortBudgetUpdated,
    required List<DecisionTrace> decisions,
  }) {
    // RIR semanal base (depende de intent de Phase5)
    final weeklyRirTarget = computeRirTarget(
      reps: repRange,
      isCompound: ex.isCompound,
      role: role,
      level: trainingLevel,
      intent: effortIntent,
    );

    // Si se aplica técnica, el RIR del ejercicio se vuelve más conservador
    // para compensar la intensidad extra de la técnica.
    var rirTargetForPrescription = weeklyRirTarget;

    // Calcular descanso según reps, tipo ejercicio e intensidad
    final restSeconds = RestPeriodCalculator.getRestSeconds(
      repRange.max,
      ex.isCompound,
      intensityTarget,
    );

    final restMinutes = (restSeconds / 60).round();

    decisions.add(
      DecisionTrace.info(
        phase: 'Phase7Prescription',
        category: 'rest_period_assigned',
        description: 'Descanso calculado para ${ex.name}',
        context: {
          'exercise': ex.name,
          'reps': repRange.max,
          'isCompound': ex.isCompound,
          'intensity': intensityTarget,
          'restSeconds': restSeconds,
          'formatted': RestPeriodCalculator.formatRestTime(restSeconds),
        },
      ),
    );

    // Intensificación y política de fallo
    String? intensificationTechnique;
    String? intensificationNotes;

    // Calcular parámetros de frecuencia semanal
    final muscleWeeklySets =
        volumeLimitsByMuscle?[ex.muscleGroup.name]?.recommendedStartVolume ??
        sets;
    // Frecuencia semanal: derivar del split (daysPerWeek)
    final muscleWeeklyFrequency = baseSplit.daysPerWeek;

    // Solo considerar intensificación para ejercicios aislados (no compuestos)
    if (derivedContext != null && !ex.isCompound) {
      // Candidato: si aplicamos técnica, subimos 1-2 RIR (sin decimales)
      final techniqueRirTarget = computeRirTarget(
        reps: repRange,
        isCompound: ex.isCompound,
        role: role,
        level: trainingLevel,
        intent: EffortIntent.technique,
      );

      // Validar si intensificación está permitida y es viable
      final shouldApply = _shouldApplyIntensification(
        derivedContext: derivedContext,
        level: trainingLevel,
        fatigueExpectation: fatigueExpectation,
        phase: phase,
        targetRir: techniqueRirTarget,
        muscle: ex.muscleGroup.name,
        volumeLimitsByMuscle: volumeLimitsByMuscle,
        sets: sets,
        effortBudget: effortBudget,
        decisions: decisions,
      );

      if (shouldApply) {
        intensificationTechnique = _pickIntensificationTechnique(
          weekIndex,
          effortBudget.remainingTechniques,
        );
        if (intensificationTechnique != null) {
          // Al aplicar técnica, el RIR efectivo del ejercicio se vuelve el del intent=technique
          rirTargetForPrescription = techniqueRirTarget;
          intensificationNotes = _buildIntensificationNotes(
            intensificationTechnique,
            rirTargetForPrescription.label,
          );
          // Consumir presupuesto
          final newBudget = effortBudget.consume(ex.muscleGroup.name);
          onEffortBudgetUpdated(newBudget);

          decisions.add(
            DecisionTrace.info(
              phase: 'Phase7Prescription',
              category: 'intensification_applied',
              description:
                  'Técnica $intensificationTechnique aplicada a ${ex.code}',
              context: {
                'exercise': ex.code,
                'muscle': ex.muscleGroup.name,
                'technique': intensificationTechnique,
                'notes': intensificationNotes,
                'budgetRemaining': newBudget.remainingTechniques,
              },
            ),
          );
        }
      }
    }

    // Política de fallo (depende del RIR final del ejercicio)
    final failureDecision = failurePolicy.evaluate(
      level: trainingLevel,
      phase: phase,
      fatigueExpectation: fatigueExpectation,
      exercise: ex,
      targetRir: rirTargetForPrescription,
      weekIndex: weekIndex,
      dayIndex: day,
      daysPerWeek: baseSplit.daysPerWeek,
      muscleWeeklySets: muscleWeeklySets,
      muscleWeeklyFrequency: muscleWeeklyFrequency,
    );

    final allowFailure = failureDecision.allowFailureOnLastSet;

    decisions.add(
      DecisionTrace.info(
        phase: 'Phase7Prescription',
        category: 'failure_policy_applied',
        description:
            'Política de fallo para ${ex.code}: allow=$allowFailure, maxSlots=${failureDecision.maxFailureSetsThisSession}',
        context: {
          'exercise': ex.code,
          'muscle': ex.muscleGroup.name,
          'allowFailure': allowFailure,
          'maxFailureSetsThisSession':
              failureDecision.maxFailureSetsThisSession,
          'reasons': failureDecision.reasons,
          'debugContext': failureDecision.debugContext,
        },
      ),
    );

    // RIR visible
    final rirDisplay = rirTargetForPrescription.label;

    return ExercisePrescription(
      id: '${ex.code}__d$day',
      sessionId: 'day_$day',
      muscleGroup: ex.muscleGroup,
      exerciseCode: ex.code,
      label: label,
      exerciseName: ex.name,
      sets: sets,
      repRange: repRange,
      rir: rirDisplay,
      restMinutes: restMinutes,
      allowFailureOnLastSet: allowFailure,
      notes: intensificationNotes,
      order: 0,
      templateCode: intensificationTechnique,
      supersetGroup: null,
      slotLabel: null,
    );
  }

  /// Computa RirTarget basado en contexto del ejercicio
  RirTarget computeRirTarget({
    required RepRange reps,
    required bool isCompound,
    required String role,
    TrainingLevel? level,
    required EffortIntent intent,
  }) {
    // Normalizar role
    final normalizedRole = role.trim().toLowerCase();
    final isAccessory = normalizedRole == 'accessory';
    final repsMax = reps.max;

    RirTarget base;

    // TABLA BASE (sin decimales)
    if (repsMax <= 6) {
      if (!isCompound || isAccessory) {
        base = const RirTarget.range(2, 3);
      } else {
        if (level == TrainingLevel.advanced) {
          base = const RirTarget.single(2); // advanced push -> 1 tras -1
        } else {
          // Conservador para cumplir guardas y tests (min>=2)
          base = const RirTarget.range(2, 3);
        }
      }
    } else if (repsMax <= 10) {
      base = const RirTarget.range(2, 3);
    } else if (repsMax <= 15) {
      if (level == TrainingLevel.beginner) {
        base = const RirTarget.single(3);
      } else if (level == TrainingLevel.advanced) {
        base = const RirTarget.single(3); // advanced push -> 2 tras -1
      } else {
        base = const RirTarget.range(2, 3);
      }
    } else {
      // >= 16
      if (level == TrainingLevel.beginner) {
        base = const RirTarget.range(3, 4);
      } else if (level == TrainingLevel.advanced) {
        base = const RirTarget.range(2, 3);
      } else {
        base = const RirTarget.single(3);
      }
    }

    int min = base.min;
    int max = base.max;

    // Ajuste por intent
    if (intent == EffortIntent.technique) {
      min = (min + 1).clamp(0, 4);
      max = (max + 1).clamp(0, 4);
    } else if (intent == EffortIntent.push) {
      if (level != TrainingLevel.beginner) {
        min = (min - 1).clamp(0, 4);
        max = (max - 1).clamp(0, 4);
      }
    } else if (intent == EffortIntent.deload) {
      // +1 a +2 (determinístico: +2)
      min = (min + 2).clamp(0, 4);
      max = (max + 2).clamp(0, 4);
    }

    // Guardas
    if (level == TrainingLevel.beginner && intent == EffortIntent.push) {
      min = min.clamp(1, 4);
      max = max.clamp(1, 4);
    }

    if (max < min) max = min;
    return min == max ? RirTarget.single(min) : RirTarget.range(min, max);
  }

  RepRange _repRangeForBias(RepBias bias, int weekIdx, TrainingPhase phase) {
    // Progresión determinística por semana
    final cyclePos = weekIdx % 4;
    switch (bias) {
      case RepBias.high:
        if (phase == TrainingPhase.deload) {
          return const RepRange(12, 15);
        }
        // accumulation: high reps
        return const RepRange(11, 15);
      case RepBias.moderate:
        if (cyclePos == 0) {
          // semana 1: rango moderado-bajo
          return const RepRange(8, 11);
        } else if (cyclePos == 1) {
          // semana 2: rango moderado-alto
          return const RepRange(9, 12);
        } else if (cyclePos == 2) {
          // semana 3 intensification
          return const RepRange(8, 10);
        } else {
          // deload
          return const RepRange(10, 13);
        }
      case RepBias.low:
        if (phase == TrainingPhase.intensification) {
          return const RepRange(6, 8);
        }
        return const RepRange(6, 10);
    }
  }

  bool _shouldApplyIntensification({
    required DerivedTrainingContext derivedContext,
    required TrainingLevel? level,
    required String fatigueExpectation,
    required TrainingPhase phase,
    required RirTarget targetRir,
    required String muscle,
    required Map<String, VolumeLimits>? volumeLimitsByMuscle,
    required int sets,
    required EffortBudget effortBudget,
    required List<DecisionTrace> decisions,
  }) {
    final reasons = <String>[];

    // 1. Beginners NUNCA pueden usar técnicas
    if (level == TrainingLevel.beginner) {
      reasons.add('nivel=beginner');
      decisions.add(
        DecisionTrace.info(
          phase: 'Phase7Prescription',
          category: 'intensification_skipped_reason',
          description:
              'Intensificación omitida para $muscle: nivel principiante',
          context: {'muscle': muscle, 'level': level?.name, 'reasons': reasons},
        ),
      );
      return false;
    }

    // 2. Validación OBLIGATORIA: allowIntensification debe ser true
    if (!derivedContext.intensificationAllowed) {
      reasons.add('allowIntensification=false');
    }

    // 3. Validación OBLIGATORIA: fatigue NO debe ser high
    if (fatigueExpectation == 'high' || fatigueExpectation == 'reset') {
      reasons.add('fatigueExpectation=$fatigueExpectation');
    }

    // 4. Validación OBLIGATORIA: targetRIR >= 2
    if (targetRir.min < 2) {
      reasons.add('targetRIR=${targetRir.label}<2');
    }

    // 5. Validación OBLIGATORIA: volumen <= 0.8 * MRV
    if (volumeLimitsByMuscle != null) {
      final limits = volumeLimitsByMuscle[muscle];
      if (limits != null) {
        final maxSafe = (limits.mrv * 0.8).round();
        if (sets > maxSafe) {
          reasons.add('sets=$sets>0.8*MRV=$maxSafe');
        }
      }
    }

    // 6. Validación OBLIGATORIA: effortBudget.canApply(muscle)
    if (!effortBudget.canApply(muscle)) {
      reasons.add('effortBudget.canApply=false');
    }

    // 7. No aplicar en deload
    if (phase == TrainingPhase.deload) {
      reasons.add('phase=deload');
    }

    if (reasons.isNotEmpty) {
      decisions.add(
        DecisionTrace.info(
          phase: 'Phase7Prescription',
          category: 'intensification_skipped_reason',
          description: 'Intensificación omitida para $muscle',
          context: {
            'muscle': muscle,
            'level': level?.name,
            'reasons': reasons,
            'allowIntensification': derivedContext.intensificationAllowed,
            'fatigueExpectation': fatigueExpectation,
            'targetRIR': targetRir.label,
            'sets': sets,
            'budgetCanApply': effortBudget.canApply(muscle),
          },
        ),
      );
      return false;
    }

    // Todas las validaciones pasaron
    return true;
  }

  String? _pickIntensificationTechnique(int weekIdx, int maxPerSession) {
    if (maxPerSession <= 0) return null;
    // Determinístico por week
    final cyclePos = (weekIdx - 1) % 3;
    if (cyclePos == 0) return 'myo_reps';
    if (cyclePos == 1) return 'drop_set';
    if (cyclePos == 2) return 'rest_pause';
    return null;
  }

  String _buildIntensificationNotes(String technique, String rirLabel) {
    switch (technique) {
      case 'myo_reps':
        return 'Myo-reps: 1 top set (RIR=$rirLabel) + mini-sets (3-5 reps, 15-20s descanso)';
      case 'drop_set':
        return 'Drop set: completar sets objetivo, luego -20% carga x1 en último set';
      case 'rest_pause':
        return 'Rest-pause: si falta reps, 15-20s descanso, repetir hasta completar';
      default:
        return '';
    }
  }

  /// Ajusta RirTarget según el rango de repeticiones y tipo de ejercicio
  /// Reglas mínimas:
  /// - 4–8 reps (compuesto): RIR entre 2–4 (permitir 3–4 early)
  /// - 8–12 reps: RIR 1–3
  /// - 12–20 reps (aislamiento): permitir 1–2 (y 1 si intensificación lo dicta)
  /// Nunca decimales. Output siempre RirTarget (enteros/rangos).
  RirTarget adjustRirForRepRange({
    required RepRange repRange,
    required bool isIsolation,
    required RirTarget base,
  }) {
    final repsMax = repRange.max;

    // 4–8 reps (compuesto)
    if (repsMax <= 8) {
      // Base debe quedar entre 2–4
      // Si es aislamiento en rango bajo, mantener conservador
      if (isIsolation) {
        return const RirTarget.range(2, 3);
      }
      // Compuesto: permitir 2-4 o 3-4 si early phase
      if (base.max >= 3) {
        return const RirTarget.range(3, 4);
      }
      return const RirTarget.range(2, 3);
    }

    // 8–12 reps: RIR 1–3
    if (repsMax <= 12) {
      // Ajustar base hacia 1-3 range
      if (base.min <= 1) {
        return const RirTarget.range(1, 2);
      }
      if (base.max >= 3) {
        return const RirTarget.range(2, 3);
      }
      return base; // mantener si ya está en rango
    }

    // 12–20 reps (high reps)
    if (repsMax <= 20) {
      if (isIsolation) {
        // Aislamiento en rango alto: permitir 1–2
        return const RirTarget.range(1, 2);
      }
      // Compuesto alto: 1-3
      if (base.min <= 1) {
        return const RirTarget.range(1, 2);
      }
      return const RirTarget.range(2, 3);
    }

    // >= 20 reps (muy alto)
    if (isIsolation) {
      return const RirTarget.single(1);
    }
    return const RirTarget.range(1, 2);
  }
}

class _ExerciseSlot {
  final MuscleGroup mg;
  final ExerciseEntry entry;
  const _ExerciseSlot({required this.mg, required this.entry});
}

class _OrderedExercise {
  final ExerciseEntry entry;
  final MuscleGroup mg;
  final int sets;
  final String role; // primary | secondary | accessory
  final String? pattern;

  const _OrderedExercise({
    required this.entry,
    required this.mg,
    required this.sets,
    required this.role,
    this.pattern,
  });

  _OrderedExercise copyWith({String? role}) {
    return _OrderedExercise(
      entry: entry,
      mg: mg,
      sets: sets,
      role: role ?? this.role,
      pattern: pattern,
    );
  }
}
