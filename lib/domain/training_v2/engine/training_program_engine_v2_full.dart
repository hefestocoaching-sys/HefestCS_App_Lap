// ignore_for_file: deprecated_member_use_from_same_package
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/decision_trace.dart';
import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/domain/entities/exercise_catalog.dart';
import 'package:hcs_app_lap/domain/entities/training_feedback.dart';
import 'package:hcs_app_lap/domain/entities/training_history.dart';
import 'package:hcs_app_lap/domain/entities/training_plan_config.dart';
import 'package:hcs_app_lap/domain/entities/training_week.dart';
import 'package:hcs_app_lap/domain/entities/training_session.dart';
import 'package:hcs_app_lap/domain/entities/exercise_prescription.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/entities/training_session_log.dart';
import 'package:hcs_app_lap/domain/entities/split_template.dart';
import 'package:hcs_app_lap/domain/exceptions/training_plan_blocked_exception.dart';
import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/core/constants/muscle_keys.dart';
import 'package:hcs_app_lap/core/enums/muscle_group.dart';
import 'package:hcs_app_lap/domain/training/training_cycle.dart';
import 'package:hcs_app_lap/domain/services/phase_1_data_ingestion_service.dart';
import 'package:hcs_app_lap/domain/services/phase_2_readiness_evaluation_service.dart';
import 'package:hcs_app_lap/domain/services/phase_3_volume_capacity_model_service.dart';
import 'package:hcs_app_lap/domain/services/phase_4_split_distribution_service.dart';
import 'package:hcs_app_lap/domain/services/phase_4_5_session_structure_service.dart';
import 'package:hcs_app_lap/domain/services/phase_5_periodization_service.dart';
import 'package:hcs_app_lap/domain/services/phase_6_exercise_selection_service.dart';
import 'package:hcs_app_lap/domain/services/phase_7_prescription_service.dart';
import 'package:hcs_app_lap/domain/services/phase_8_adaptation_service.dart';
import 'package:hcs_app_lap/domain/training_v2/models/training_context.dart';

/// Mapper local (fallback) para convertir TrainingContext -> TrainingProfile
/// En producción, se usa el mapper canónico; este garantiza compilación
class TrainingProfileFromContextMapper {
  const TrainingProfileFromContextMapper();

  TrainingProfile map(TrainingContext ctx) {
    final baseExtra = <String, dynamic>{};
    baseExtra[TrainingExtraKeys.trainingLevel] = ctx.meta.level?.name;
    baseExtra[TrainingExtraKeys.daysPerWeek] = ctx.meta.daysPerWeek;
    baseExtra[TrainingExtraKeys.timePerSessionMinutes] =
        ctx.meta.timePerSessionMinutes;
    baseExtra[TrainingExtraKeys.trainingYears] =
        ctx.interview.yearsTrainingContinuous;
    baseExtra[TrainingExtraKeys.avgSleepHours] = ctx.interview.avgSleepHours;
    baseExtra[TrainingExtraKeys.restBetweenSetsSeconds] =
        ctx.interview.restBetweenSetsSeconds;
    baseExtra[TrainingExtraKeys.priorityMusclesPrimary] =
        ctx.priorities.primary;
    baseExtra[TrainingExtraKeys.priorityMusclesSecondary] =
        ctx.priorities.secondary;
    baseExtra[TrainingExtraKeys.priorityMusclesTertiary] =
        ctx.priorities.tertiary;
    baseExtra['activeInjuries'] = ctx.constraints.activeInjuries;
    baseExtra['athlete.gender'] = ctx.athlete.gender?.name;
    baseExtra['athlete.ageYears'] = ctx.athlete.ageYears;
    baseExtra['athlete.heightCm'] = ctx.athlete.heightCm;
    baseExtra['athlete.weightKg'] = ctx.athlete.weightKg;
    baseExtra['athlete.usesAnabolics'] = ctx.athlete.usesAnabolics;
    baseExtra['athlete.isCompetitor'] = ctx.athlete.isCompetitor;
    baseExtra['energy.state'] = ctx.energy.state;
    baseExtra['energy.deltaKcalMinusGet'] = ctx.energy.deltaKcalMinusGet;
    baseExtra['energy.magnitude'] = ctx.energy.magnitude;
    baseExtra[TrainingExtraKeys.manualOverrides] = ctx.manualOverrides;

    final profile = TrainingProfile(
      trainingLevel: ctx.meta.level,
      globalGoal: ctx.meta.goal,
      trainingFocus: ctx.meta.focus,
      daysPerWeek: ctx.meta.daysPerWeek,
      timePerSessionMinutes: ctx.meta.timePerSessionMinutes,
      extra: baseExtra,
    );

    return profile.normalizedFromExtra();
  }
}

class TrainingProgramEngineV2Full {
  final Phase1DataIngestionService _p1 = Phase1DataIngestionService();
  final Phase2ReadinessEvaluationService _p2 =
      Phase2ReadinessEvaluationService();
  final Phase3VolumeCapacityModelService _p3 =
      Phase3VolumeCapacityModelService();
  final Phase4SplitDistributionService _p4 = Phase4SplitDistributionService();
  final Phase5PeriodizationService _p5 = Phase5PeriodizationService();
  final Phase6ExerciseSelectionService _p6 = Phase6ExerciseSelectionService();
  final Phase7PrescriptionService _p7 = Phase7PrescriptionService();
  final Phase8AdaptationService _p8 = Phase8AdaptationService();

  final TrainingProfileFromContextMapper _mapper =
      const TrainingProfileFromContextMapper();

  final List<DecisionTrace> lastDecisions = [];

  /// C3 — Normaliza VOPs semanales para músculos secundarios.
  ///
  /// Evita bloqueo total del motor por músculos secundarios sin VOP explícito.
  /// Asigna VOP mínimo efectivo (2-4 series/sem) a músculos no prioritarios
  /// con VOP=0/null, manteniendo bloqueo SOLO para músculos prioritarios.
  ///
  /// PARÁMETROS:
  /// - activeMuscles: Músculos que aparecen en el split + ejercicios
  /// - priorityMuscles: Músculos prioritarios (perfil + volumen)
  /// - weeklyVopRaw: Mapa de VOPs semanales del contexto (baseVolumePerMuscle)
  ///
  /// RETORNA: Mapa de VOPs normalizado con mínimos efectivos asignados
  ///
  /// NOTA: Mantiene VOPs explícitos sin modificar; solo autoasigna mínimos
  /// a secundarios vacíos. Bloqueo posterior debe validar SOLO prioritarios.
  // ignore: unused_element
  Map<String, int> _normalizeWeeklyVop({
    required Set<String> activeMuscles,
    required Set<String> priorityMuscles,
    required Map<String, int> weeklyVopRaw,
  }) {
    const int minEffectiveVop = 2;

    final result = Map<String, int>.from(weeklyVopRaw);

    for (final m in activeMuscles) {
      final current = result[m] ?? 0;

      // Si es prioritario, NO se autoasigna (hard stop después)
      if (priorityMuscles.contains(m)) {
        continue;
      }

      // Músculo activo secundario → VOP mínimo efectivo
      if (current <= 0) {
        result[m] = minEffectiveVop;
      }
    }

    return result;
  }

  TrainingCycle? _resolveActiveCycle(Client? client) {
    if (client == null || client.activeCycleId == null) return null;
    for (final cycle in client.trainingCycles) {
      if (cycle.cycleId == client.activeCycleId) return cycle;
    }
    return null;
  }

  int _daysFromSplitType(String splitType, int fallbackDays) {
    final lower = splitType.toLowerCase();
    for (final d in const [6, 5, 4, 3]) {
      if (lower.contains('${d}d')) return d;
    }
    return fallbackDays;
  }

  String _norm(String v) => v.trim().toLowerCase();

  MuscleGroup _toDomainMuscleGroup(String muscle) {
    final ml = muscle.toLowerCase();
    switch (ml) {
      case 'chest':
      case 'pecho':
        return MuscleGroup.chest;
      case 'lats':
      case 'dorsales':
      case 'dorsal':
        return MuscleGroup.lats;
      case 'upper_back':
      case 'espalda alta':
      case 'romboides':
        return MuscleGroup.back;
      case 'traps':
      case 'trapecio':
      case 'trapecios':
        return MuscleGroup.traps;
      case 'back':
      case 'espalda':
        return MuscleGroup.back;
      case 'shoulders':
      case 'hombros':
      case 'deltoide_anterior':
      case 'deltoide_lateral':
      case 'deltoide_posterior':
        return MuscleGroup.shoulders;
      case 'biceps':
        return MuscleGroup.biceps;
      case 'triceps':
        return MuscleGroup.triceps;
      case 'quads':
      case 'cuadriceps':
        return MuscleGroup.quads;
      case 'hamstrings':
      case 'isquiotibiales':
        return MuscleGroup.hamstrings;
      case 'glutes':
      case 'gluteos':
        return MuscleGroup.glutes;
      case 'calves':
      case 'pantorrillas':
        return MuscleGroup.calves;
      case 'abs':
      case 'abdominales':
        return MuscleGroup.abs;
      default:
        return MuscleGroup.chest; // fallback
    }
  }

  List<String> _pickMany({
    required List<String> candidates,
    required List<String> priority,
    required Set<String> allowed,
    required int count,
    Set<String> exclude = const {},
  }) {
    final picked = <String>[];
    for (final p in priority) {
      final key = _norm(p);
      if (!allowed.contains(key)) continue;
      if (!candidates.contains(key)) continue;
      if (exclude.contains(key)) continue;
      if (!picked.contains(key)) picked.add(key);
      if (picked.length >= count) return picked;
    }
    for (final c in candidates) {
      if (!allowed.contains(c)) continue;
      if (exclude.contains(c)) continue;
      if (!picked.contains(c)) picked.add(c);
      if (picked.length >= count) break;
    }
    return picked;
  }

  int _setsForSlots(int slots) {
    if (slots <= 1) return 4;
    if (slots == 2) return 6;
    return 8;
  }

  Map<int, Map<String, int>> _buildSessionFramework(TrainingCycle cycle) {
    final days = _daysFromSplitType(cycle.splitType, 4);
    final allowed = cycle.baseExercisesByMuscle.keys.map(_norm).toSet();
    final priority = cycle.priorityMuscles.map(_norm).toList();

    final lowerCandidates = <String>[
      MuscleKeys.glutes,
      MuscleKeys.quads,
      MuscleKeys.hamstrings,
      MuscleKeys.calves,
    ];
    final upperCandidates = <String>[
      MuscleKeys.chest,
      MuscleKeys.lats,
      MuscleKeys.upperBack,
      MuscleKeys.traps,
    ];
    final shoulderCandidates = <String>[
      MuscleKeys.deltoideAnterior,
      MuscleKeys.deltoideLateral,
      MuscleKeys.deltoidePosterior,
      'shoulders',
    ];
    final armsCandidates = <String>[
      MuscleKeys.biceps,
      MuscleKeys.triceps,
      'arms',
    ];

    Map<String, int> buildLowerDay({
      required int primarySlots,
      required int secondarySlots,
      int accessorySlots = 0,
    }) {
      final map = <String, int>{};
      final main = _pickMany(
        candidates: lowerCandidates,
        priority: priority,
        allowed: allowed,
        count: 2,
      );
      if (main.isNotEmpty) map[main[0]] = primarySlots;
      if (main.length > 1) map[main[1]] = secondarySlots;

      if (accessorySlots > 0) {
        final accessory = _pickMany(
          candidates: lowerCandidates,
          priority: priority,
          allowed: allowed,
          count: 1,
          exclude: main.toSet(),
        );
        if (accessory.isNotEmpty) {
          map[accessory.first] = accessorySlots;
        }
      }
      return map;
    }

    Map<String, int> buildUpperDay({
      required int chestSlots,
      required int backSlots,
      int shoulderSlots = 0,
      int armSlots = 0,
    }) {
      final map = <String, int>{};
      final chest = _pickMany(
        candidates: [MuscleKeys.chest],
        priority: priority,
        allowed: allowed,
        count: 1,
      );
      final back = _pickMany(
        candidates: upperCandidates,
        priority: priority,
        allowed: allowed,
        count: 1,
      );
      if (chest.isNotEmpty) map[chest.first] = chestSlots;
      if (back.isNotEmpty) map[back.first] = backSlots;

      if (shoulderSlots > 0) {
        final shoulder = _pickMany(
          candidates: shoulderCandidates,
          priority: priority,
          allowed: allowed,
          count: 1,
        );
        if (shoulder.isNotEmpty) map[shoulder.first] = shoulderSlots;
      }

      if (armSlots > 0) {
        final arms = _pickMany(
          candidates: armsCandidates,
          priority: priority,
          allowed: allowed,
          count: 1,
        );
        if (arms.isNotEmpty) map[arms.first] = armSlots;
      }

      return map;
    }

    Map<int, Map<String, int>> framework;
    switch (days) {
      case 3:
        framework = {
          1: buildLowerDay(
            primarySlots: 3,
            secondarySlots: 2,
            accessorySlots: 1,
          ),
          2: buildUpperDay(chestSlots: 2, backSlots: 2, shoulderSlots: 1),
          3: buildLowerDay(
            primarySlots: 2,
            secondarySlots: 2,
            accessorySlots: 1,
          ),
        };
        break;
      case 4:
        framework = {
          1: buildLowerDay(
            primarySlots: 3,
            secondarySlots: 2,
            accessorySlots: 1,
          ),
          2: buildUpperDay(chestSlots: 2, backSlots: 2, shoulderSlots: 1),
          3: buildLowerDay(
            primarySlots: 2,
            secondarySlots: 2,
            accessorySlots: 1,
          ),
          4: buildUpperDay(
            chestSlots: 1,
            backSlots: 2,
            shoulderSlots: 1,
            armSlots: 1,
          ),
        };
        break;
      case 5:
        framework = {
          1: buildLowerDay(
            primarySlots: 3,
            secondarySlots: 2,
            accessorySlots: 1,
          ),
          2: buildUpperDay(chestSlots: 2, backSlots: 2, shoulderSlots: 1),
          3: buildLowerDay(
            primarySlots: 2,
            secondarySlots: 2,
            accessorySlots: 1,
          ),
          4: buildUpperDay(
            chestSlots: 1,
            backSlots: 2,
            shoulderSlots: 1,
            armSlots: 1,
          ),
          5: buildUpperDay(
            chestSlots: 1,
            backSlots: 2,
            shoulderSlots: 1,
            armSlots: 1,
          ),
        };
        break;
      case 6:
        framework = {
          1: buildLowerDay(
            primarySlots: 3,
            secondarySlots: 2,
            accessorySlots: 1,
          ),
          2: buildUpperDay(chestSlots: 2, backSlots: 2, shoulderSlots: 1),
          3: buildLowerDay(
            primarySlots: 2,
            secondarySlots: 2,
            accessorySlots: 1,
          ),
          4: buildUpperDay(
            chestSlots: 1,
            backSlots: 2,
            shoulderSlots: 1,
            armSlots: 1,
          ),
          5: buildLowerDay(
            primarySlots: 2,
            secondarySlots: 2,
            accessorySlots: 1,
          ),
          6: buildUpperDay(chestSlots: 2, backSlots: 2, shoulderSlots: 1),
        };
        break;
      default:
        framework = {
          1: buildLowerDay(
            primarySlots: 3,
            secondarySlots: 2,
            accessorySlots: 1,
          ),
          2: buildUpperDay(chestSlots: 2, backSlots: 2, shoulderSlots: 1),
          3: buildLowerDay(
            primarySlots: 2,
            secondarySlots: 2,
            accessorySlots: 1,
          ),
          4: buildUpperDay(
            chestSlots: 1,
            backSlots: 2,
            shoulderSlots: 1,
            armSlots: 1,
          ),
        };
    }

    final maxPerSession =
        Phase6ExerciseSelectionService.MAX_EXERCISES_PER_SESSION;
    final filtered = <int, Map<String, int>>{};
    for (final entry in framework.entries) {
      final day = entry.key;
      final dayMap = <String, int>{};
      for (final e in entry.value.entries) {
        final key = _norm(e.key);
        if (!allowed.contains(key)) continue;
        if (e.value <= 0) continue;
        dayMap[key] = e.value;
      }

      var total = dayMap.values.fold<int>(0, (sum, v) => sum + v);
      if (total > maxPerSession) {
        final keys = dayMap.keys.toList();
        for (var i = keys.length - 1; i >= 0 && total > maxPerSession; i--) {
          final k = keys[i];
          final current = dayMap[k] ?? 0;
          if (current <= 0) continue;
          dayMap[k] = current - 1;
          if (dayMap[k] == 0) dayMap.remove(k);
          total -= 1;
        }
      }
      filtered[day] = dayMap;
    }

    return filtered;
  }

  SplitTemplate _applyFrameworkToSplit(
    SplitTemplate split,
    Map<int, Map<String, int>> framework,
  ) {
    final newDayMuscles = <int, List<String>>{};
    final newDailyVolume = <int, Map<String, int>>{};

    for (var d = 1; d <= split.daysPerWeek; d++) {
      final dayFramework = framework[d] ?? const <String, int>{};
      if (dayFramework.isEmpty) {
        newDayMuscles[d] = split.dayMuscles[d] ?? const <String>[];
        newDailyVolume[d] = split.dailyVolume[d] ?? const <String, int>{};
        continue;
      }

      newDayMuscles[d] = dayFramework.keys.toList();
      final dayVolume = <String, int>{};
      for (final entry in dayFramework.entries) {
        dayVolume[entry.key] = _setsForSlots(entry.value);
      }
      newDailyVolume[d] = dayVolume;
    }

    return split.copyWith(
      dayMuscles: newDayMuscles,
      dailyVolume: newDailyVolume,
    );
  }

  Map<int, Map<int, Map<MuscleGroup, List<ExerciseEntry>>>>
  _applyFrameworkToSelections({
    required Map<int, Map<int, Map<MuscleGroup, List<ExerciseEntry>>>>
    selections,
    required Map<int, Map<String, int>> sessionFramework,
    required List<DecisionTrace> decisions,
  }) {
    final adjusted = <int, Map<int, Map<MuscleGroup, List<ExerciseEntry>>>>{};
    for (final weekEntry in selections.entries) {
      final weekIndex = weekEntry.key;
      final weekMap = <int, Map<MuscleGroup, List<ExerciseEntry>>>{};

      for (final dayEntry in weekEntry.value.entries) {
        final day = dayEntry.key;
        final dayFramework = sessionFramework[day] ?? const <String, int>{};
        final dayMap = <MuscleGroup, List<ExerciseEntry>>{};

        if (dayFramework.isEmpty) {
          weekMap[day] = dayMap;
          continue;
        }

        for (final entry in dayEntry.value.entries) {
          final mg = entry.key;
          final key = mg.name.toLowerCase();
          final slots = dayFramework[key] ?? 0;
          if (slots <= 0) continue;

          final list = entry.value;
          if (list.isEmpty) continue;
          final capped = list.take(slots).toList();
          if (capped.isNotEmpty) {
            dayMap[mg] = capped;
          }
        }
        weekMap[day] = dayMap;
      }
      adjusted[weekIndex] = weekMap;
    }

    decisions.add(
      DecisionTrace.info(
        phase: 'TrainingProgramEngineV2Full',
        category: 'session_framework_applied',
        description: 'Session framework aplicado a selección de ejercicios',
      ),
    );

    return adjusted;
  }

  void _validateSessionFrameworkSelections({
    required Map<int, Map<int, Map<MuscleGroup, List<ExerciseEntry>>>>
    selections,
    required int daysPerWeek,
    TrainingCycle? activeCycle,
  }) {
    final int minExercises = (activeCycle?.frequency == 2) ? 5 : 2;
    const int maxExercises =
        Phase6ExerciseSelectionService.MAX_EXERCISES_PER_SESSION;

    for (final weekEntry in selections.entries) {
      final week = weekEntry.key;
      for (var day = 1; day <= daysPerWeek; day++) {
        var dayMap =
            weekEntry.value[day] ?? const <MuscleGroup, List<ExerciseEntry>>{};
        // ─────────────────────────────────────────────
        // DENSIFICACIÓN DE DÍA (solo frecuencia 2)
        // ─────────────────────────────────────────────
        if (activeCycle?.frequency == 2) {
          final usedExerciseIds = <String>{};

          for (final list in dayMap.values) {
            for (final ex in list) {
              usedExerciseIds.add(ex.code);
            }
          }

          int currentCount = usedExerciseIds.length;

          if (currentCount < minExercises) {
            // Pool de músculos permitidos para completar el día:
            // todos los músculos del ciclo que NO estén ya en el día
            final fillerMuscles =
                (activeCycle?.baseExercisesByMuscle.keys
                            .where(
                              (m) =>
                                  !dayMap.containsKey(_toDomainMuscleGroup(m)),
                            )
                            .toList() ??
                        [])
                    .toList();

            for (final muscle in fillerMuscles) {
              if (currentCount >= minExercises) break;

              final candidates =
                  activeCycle?.baseExercisesByMuscle[muscle] ?? const [];
              final muscleGroup = _toDomainMuscleGroup(muscle);

              for (final ex in candidates) {
                if (currentCount >= minExercises) break;
                if (usedExerciseIds.contains(ex)) continue;

                final entry = ExerciseEntry(
                  code: ex,
                  name: ex,
                  muscleGroup: muscleGroup,
                  equipment: const [],
                  isCompound: false,
                );

                dayMap = {...dayMap};
                dayMap.putIfAbsent(muscleGroup, () => []);
                dayMap[muscleGroup]!.add(entry);

                usedExerciseIds.add(ex);
                currentCount++;
              }
            }
          }
        }

        weekEntry.value[day] = dayMap;

        var count = dayMap.values.fold<int>(
          0,
          (sum, list) => sum + list.length,
        );

        if (count < minExercises) {
          throw TrainingPlanBlockedException.insufficientExercisesPerDay(
            week: week,
            day: day,
            count: count,
            minimum: minExercises,
          );
        }
        if (count > maxExercises) {
          throw TrainingPlanBlockedException(
            reason:
                'El día $day de la semana $week supera el máximo de ejercicios ($count > $maxExercises)',
            context: {
              'week': week,
              'day': day,
              'count': count,
              'maximum': maxExercises,
            },
            suggestions: const [
              'Reducir el número de músculos por día en el framework',
              'Disminuir los slots por músculo',
            ],
          );
        }
      }
    }
  }

  TrainingPlanConfig generatePlan({
    required String planId,
    required String clientId,
    required String planName,
    required DateTime startDate,
    required TrainingContext context,
    Client? client,
    TrainingHistory? history,
    List<TrainingSessionLog> logs = const [],
    TrainingFeedback? latestFeedback,
    ExerciseCatalog? exerciseCatalog,
    List<Exercise>? exercises,
  }) {
    lastDecisions.clear();

    // 0) mapear contexto -> profile motor-ready
    final TrainingProfile profile = _mapper.map(context);

    // 1) Phase 1 - ingest & validate (usa manualOverrides ya inyectados en extra)
    final manualOverridesRaw = profile.extra[TrainingExtraKeys.manualOverrides];

    final r1 = _p1.ingestAndValidate(
      profile: profile,
      history: history,
      latestFeedback: latestFeedback,
      manualOverridesRaw: manualOverridesRaw,
      referenceDate: startDate,
    );

    if (!r1.isValid || r1.missingData.isNotEmpty) {
      lastDecisions.add(
        DecisionTrace.critical(
          phase: 'TrainingProgramEngineV2Full',
          category: 'blocked_missing_data',
          description: 'Bloqueado por datos faltantes en Phase1',
          context: {'missingData': r1.missingData},
          action: 'Complete los datos críticos antes de continuar',
        ),
      );
      throw TrainingPlanBlockedException.missingCriticalData(
        missingFields: r1.missingData,
      );
    }

    lastDecisions.addAll(r1.decisions);

    final manualOverride = r1.manualOverride;

    // 2) Phase 2 - readiness
    final r2 = _p2.evaluateReadinessWithContext(
      profile: profile,
      history: history,
      latestFeedback: latestFeedback,
      derivedContext: r1.derivedContext,
    );
    lastDecisions.addAll(r2.decisions);

    // 3) Phase 3 - volume capacity model (+ overrides)
    final r3 = _p3.calculateVolumeCapacity(
      profile: profile,
      history: history,
      readinessAdjustment: r2.volumeAdjustmentFactor,
      readinessByMuscle: r2.readinessByMuscle,
      manualOverride: manualOverride,
    );
    lastDecisions.addAll(r3.decisions);

    // C3 — PUNTO DE NORMALIZACIÓN DE VOP (FUTURO):
    // Cuando TrainingContext.volumePerMuscle esté disponible:
    //   final activeMuscles = r4.split.dayToMuscles.values.expand((e) => e).toSet();
    //   final priorityMuscles = {...profile.priorityMusclesPrimary, ...}.toSet();
    //   final weeklyVopRaw = context.volumePerMuscle ?? {};
    //   final weeklyVopNormalized = _normalizeWeeklyVop(
    //     activeMuscles: activeMuscles,
    //     priorityMuscles: priorityMuscles,
    //     weeklyVopRaw: weeklyVopRaw,
    //   );
    // Luego pasar weeklyVopNormalized a Phase 4 o validación posterior.
    // Esta normalización asegura que motor NUNCA bloquea por secundarios sin VOP.

    // 4) Phase 4 - split distribution (+ priority overrides)
    final r4 = _p4.buildWeeklySplit(
      profile: profile,
      volumeByMuscle: r3.volumeLimitsByMuscle,
      readinessAdjustment: r2.volumeAdjustmentFactor,
      readinessMode: 'normal',
      derivedContext: r1.derivedContext,
      manualOverride: manualOverride,
    );
    lastDecisions.addAll(r4.decisions);

    // 4.5) Phase 4.5 - session structure (cap muscles per day)
    final r45 = const Phase45SessionStructureService().apply(
      profile: profile,
      baseSplit: r4.split,
    );
    final structuredSplit = r45.structuredSplit;

    final activeCycle = _resolveActiveCycle(client);
    final sessionFramework = activeCycle != null
        ? _buildSessionFramework(activeCycle)
        : null;
    final effectiveSplit = sessionFramework != null
        ? _applyFrameworkToSplit(structuredSplit, sessionFramework)
        : structuredSplit;

    if (sessionFramework != null) {
      lastDecisions.add(
        DecisionTrace.info(
          phase: 'TrainingProgramEngineV2Full',
          category: 'session_framework_built',
          description: 'Framework de sesiones generado desde ciclo activo',
          context: {
            'days': effectiveSplit.daysPerWeek,
            'splitType': activeCycle?.splitType,
          },
        ),
      );
    }

    // 5) Phase 5 - periodization (RIR targets, rep ranges) (+ rir override)
    final r5 = _p5.periodize(
      profile: profile,
      baseSplit: effectiveSplit,
      manualOverride: manualOverride,
    );
    lastDecisions.addAll(r5.decisions);

    // 6) Phase 6 - exercise selection
    final catalogInput = (exerciseCatalog ?? exercises ?? const <Exercise>[]);
    final r6 = _p6.selectExercises(
      profile: profile,
      baseSplit: effectiveSplit,
      catalog: catalogInput,
      weeks: r5.weeks.length,
      derivedContext: r1.derivedContext,
      logs: logs,
      baseExercisesByMuscle: activeCycle?.baseExercisesByMuscle,
    );
    lastDecisions.addAll(r6.decisions);

    final selections = sessionFramework == null
        ? r6.selections
        : _applyFrameworkToSelections(
            selections: r6.selections,
            sessionFramework: sessionFramework,
            decisions: lastDecisions,
          );
    if (sessionFramework != null) {
      _validateSessionFrameworkSelections(
        selections: selections,
        daysPerWeek: effectiveSplit.daysPerWeek,
        activeCycle: activeCycle,
      );
    }

    // 7) Phase 7 - prescriptions (+ intensification override)
    final r7 = _p7.buildPrescriptions(
      baseSplit: effectiveSplit,
      periodization: r5,
      selections: selections,
      volumeLimitsByMuscle: r3.volumeLimitsByMuscle,
      trainingLevel: profile.trainingLevel,
      derivedContext: r1.derivedContext,
      profile: profile,
      manualOverride: manualOverride,
    );
    lastDecisions.addAll(r7.decisions);

    // 8) Phase 8 - adaptation packaging / final plan config
    final r8 = _p8.adapt(
      latestFeedback: latestFeedback,
      history: history,
      logs: logs,
      weekDayPrescriptions: r7.weekDayPrescriptions,
      volumeLimitsByMuscle: r3.volumeLimitsByMuscle,
      trainingLevel: profile.trainingLevel,
      manualOverride: manualOverride,
    );
    lastDecisions.addAll(r8.decisions);

    // Construir semanas y sesiones finales desde prescriptions adaptadas
    // Utilizamos el mismo enfoque que el wrapper legacy para compatibilidad
    final weeks = <TrainingWeek>[];
    for (final pw in r5.weeks) {
      final weekIndex = pw.weekIndex;
      final sessions = <TrainingSession>[];
      for (var d = 1; d <= effectiveSplit.daysPerWeek; d++) {
        final dayPres =
            r8.adaptedWeekDayPrescriptions[weekIndex]?[d] ??
            const <ExercisePrescription>[];
        final session = TrainingSession(
          id: 'W$weekIndex-D$d',
          dayNumber: d,
          sessionName: 'W$weekIndex-D$d',
          prescriptions: dayPres,
        );
        sessions.add(session);
      }
      weeks.add(
        TrainingWeek(
          id: 'W$weekIndex',
          weekNumber: weekIndex,
          phase: pw.phase,
          sessions: sessions,
        ),
      );
    }

    final plan = TrainingPlanConfig(
      id: planId,
      name: planName,
      clientId: clientId,
      startDate: startDate,
      phase: r5.weeks.first.phase,
      splitId: r4.split.splitId,
      microcycleLengthInWeeks: r5.weeks.length,
      weeks: weeks,
      trainingProfileSnapshot: profile,
    );

    lastDecisions.add(
      DecisionTrace.info(
        phase: 'TrainingProgramEngineV2Full',
        category: 'summary',
        description: 'Plan v2-full generado 1→8',
        context: {
          'planId': planId,
          'clientId': clientId,
          'weeks': weeks.length,
          'splitId': r4.split.splitId,
        },
      ),
    );

    return plan;
  }
}
