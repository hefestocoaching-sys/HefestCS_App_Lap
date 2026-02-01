import 'package:hcs_app_lap/core/constants/nutrition_extra_keys.dart';
import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/decision_trace.dart';
import 'package:hcs_app_lap/domain/entities/athlete_longitudinal_state.dart';
import 'package:hcs_app_lap/domain/services/latest_record_resolver.dart';
import 'package:hcs_app_lap/domain/training_v2/errors/training_context_error.dart';
import 'package:hcs_app_lap/domain/training_v2/models/training_context.dart';
import 'package:hcs_app_lap/domain/training_v2/services/training_context_normalizer.dart';
import 'package:hcs_app_lap/domain/entities/training_macro_plan.dart';
import 'package:hcs_app_lap/domain/training_v2/models/training_block_context.dart';

class TrainingContextBuildResult {
  final TrainingContext? context;
  final TrainingContextError? error;
  final List<DecisionTrace> trace;

  const TrainingContextBuildResult._({
    required this.context,
    required this.error,
    required this.trace,
  });

  factory TrainingContextBuildResult.ok(
    TrainingContext ctx,
    List<DecisionTrace> trace,
  ) => TrainingContextBuildResult._(context: ctx, error: null, trace: trace);

  factory TrainingContextBuildResult.fail(
    TrainingContextError err,
    List<DecisionTrace> trace,
  ) => TrainingContextBuildResult._(context: null, error: err, trace: trace);

  bool get isOk => context != null && error == null;
}

class TrainingContextBuilder {
  final TrainingContextNormalizer _n = const TrainingContextNormalizer();
  final LatestRecordResolver _latest = const LatestRecordResolver();

  /// Construye un snapshot canónico para el motor v2.
  TrainingContextBuildResult build({
    required Client client,
    required DateTime asOfDate,
    int schemaVersion = 1,
  }) {
    final trace = <DecisionTrace>[];

    final training = client.training;
    final extra = Map<String, dynamic>.from(training.extra);

    // -------- AthleteSnapshot (biológico) --------
    final latestAnth = _latest.latestAnthropometry(client.anthropometry);
    final gender =
        training.gender ??
        client.profile.gender; // prefer training snapshot si existe
    final ageYears = training.age ?? client.profile.age;

    if (gender == null || ageYears == null) {
      return TrainingContextBuildResult.fail(
        MissingCriticalTrainingDataError(
          message: 'Faltan datos críticos: gender/age. Completa Personal Data.',
          details: {'gender': gender, 'ageYears': ageYears},
        ),
        trace..add(
          DecisionTrace.critical(
            phase: 'TrainingContextBuilder',
            category: 'missing_critical',
            description: 'Missing gender/age for training context',
            context: {'gender': gender, 'ageYears': ageYears},
          ),
        ),
      );
    }

    final athlete = AthleteSnapshot(
      gender: gender,
      ageYears: ageYears,
      heightCm: latestAnth?.heightCm,
      weightKg: latestAnth?.weightKg,
      usesAnabolics: training.usesAnabolics,
      isCompetitor: training.isCompetitor,
    );

    // -------- Meta --------
    final meta = TrainingMetaSnapshot(
      goal: training.globalGoal,
      focus: training.trainingFocus,
      level: training.trainingLevel,
      daysPerWeek: training.daysPerWeek,
      timePerSessionMinutes: training.timePerSessionMinutes,
    );

    if (meta.level == null ||
        meta.daysPerWeek <= 0 ||
        meta.timePerSessionMinutes <= 0) {
      return TrainingContextBuildResult.fail(
        MissingCriticalTrainingDataError(
          message:
              'Faltan datos críticos de entrenamiento: level/daysPerWeek/timePerSessionMinutes.',
          details: {
            'level': meta.level?.name,
            'daysPerWeek': meta.daysPerWeek,
            'timePerSessionMinutes': meta.timePerSessionMinutes,
          },
        ),
        trace..add(
          DecisionTrace.critical(
            phase: 'TrainingContextBuilder',
            category: 'missing_critical',
            description: 'Missing training meta for context',
            context: {
              'level': meta.level?.name,
              'daysPerWeek': meta.daysPerWeek,
              'timePerSessionMinutes': meta.timePerSessionMinutes,
            },
          ),
        ),
      );
    }

    // -------- Interview (V2 - 2025) --------
    final interview = TrainingInterviewSnapshot(
      // Mandatory fields
      yearsTrainingContinuous: _n.yearsTrainingContinuous(extra),
      sessionDurationMinutes: _n.sessionDurationMinutes(extra),
      restBetweenSetsSeconds: _n.restBetweenSetsSeconds(extra),
      avgSleepHours: _n.avgSleepHours(extra),
      avgWeeklySetsPerMuscle: _n.avgWeeklySetsPerMuscle(extra),
      consecutiveWeeksTraining: _n.consecutiveWeeksTraining(extra),
      perceivedRecoveryStatus: _n.perceivedRecoveryStatus(extra),
      stressLevel: _n.readInt(extra, const [
        TrainingExtraKeys.stressLevel,
        'stress',
      ], fallback: 5),
      averageRIR: _n.averageRIR(extra),
      averageSessionRPE: _n.averageSessionRPE(extra),

      // Legacy fields
      workCapacity: _n.workCapacity(extra),
      recoveryHistory: _n.recoveryHistory(extra),
      externalRecovery: _n.externalRecovery(extra),
      programNovelty: training.programNovelty,
      physicalStress: training.physicalStress,
      nonPhysicalStress: training.nonPhysicalStress,
      restQuality: training.restQualityEnum,
      dietQuality: training.dietQuality,

      // Recommended V2 fields (nullable)
      maxWeeklySetsBeforeOverreaching: _n.maxWeeklySetsBeforeOverreaching(
        extra,
      ),
      deloadFrequencyWeeks: _n.deloadFrequencyWeeks(extra),
      restingHeartRate: _n.restingHeartRate(extra),
      heartRateVariability: _n.heartRateVariability(extra),
      soreness48hAverage: _n.soreness48hAverage(extra),
      periodBreaksLast12Months: _n.periodBreaksLast12Months(extra),
      sessionCompletionRate: _n.sessionCompletionRate(extra),
      performanceTrend: _n.performanceTrend(extra),

      // Optional PRs
      prSquatKg:
          _n.readInt(extra, const [
                TrainingExtraKeys.prSquat,
                'prSquat',
              ], fallback: 0) >
              0
          ? _n.readInt(extra, const [TrainingExtraKeys.prSquat], fallback: 0)
          : null,
      prBenchKg:
          _n.readInt(extra, const [
                TrainingExtraKeys.prBench,
                'prBench',
              ], fallback: 0) >
              0
          ? _n.readInt(extra, const [TrainingExtraKeys.prBench], fallback: 0)
          : null,
      prDeadliftKg:
          _n.readInt(extra, const [
                TrainingExtraKeys.prDeadlift,
                'prDeadlift',
              ], fallback: 0) >
              0
          ? _n.readInt(extra, const [TrainingExtraKeys.prDeadlift], fallback: 0)
          : null,
    );

    // -------- EnergyAvailability (derivado desde nutrition.extra) --------
    final energy = _deriveEnergy(client, asOfDate, trace);

    // -------- Constraints --------
    final constraints = ConstraintsSnapshot(
      movementRestrictions: training.movementRestrictions,
      availableEquipment: training.equipment,
      activeInjuries: _n.readStringList(extra, 'activeInjuries'),
    );

    // -------- Prioridades musculares --------
    final priorities = PrioritiesSnapshot(
      primary: training.priorityMusclesPrimary.isNotEmpty
          ? training.priorityMusclesPrimary
          : _n.priorityPrimary(extra),
      secondary: training.priorityMusclesSecondary.isNotEmpty
          ? training.priorityMusclesSecondary
          : _n.prioritySecondary(extra),
      tertiary: training.priorityMusclesTertiary.isNotEmpty
          ? training.priorityMusclesTertiary
          : _n.priorityTertiary(extra),
    );

    // -------- Longitudinal prior --------
    final longitudinal = AthleteLongitudinalState.fromExtra(
      training.extra,
      asOfDate,
    );

    // -------- Overrides --------
    final overrides = _n.manualOverrides(extra);

    // -------- Macroplan / BlockContext --------
    TrainingMacroPlan? macroPlan;
    final rawMacro = extra[TrainingExtraKeys.macroPlan];
    if (rawMacro is Map<String, dynamic>) {
      macroPlan = TrainingMacroPlan.fromMap(rawMacro);
    } else if (rawMacro is Map) {
      macroPlan = TrainingMacroPlan.fromMap(
        Map<String, dynamic>.from(rawMacro),
      );
    }

    final blockCtx = _deriveBlockContext(macroPlan, asOfDate);

    // -------- Intensity Profiles (light/medium/heavy) --------
    final intensityProfiles = _loadIntensityProfiles(extra);

    final ctx = TrainingContext(
      asOfDate: asOfDate,
      schemaVersion: schemaVersion,
      athlete: athlete,
      meta: meta,
      interview: interview,
      energy: energy,
      constraints: constraints,
      priorities: priorities,
      longitudinal: longitudinal,
      manualOverrides: overrides,
      intensityProfiles: intensityProfiles,
      blockContext: blockCtx,
    );

    trace.add(
      DecisionTrace.info(
        phase: 'TrainingContextBuilder',
        category: 'context_built',
        description: 'TrainingContext construido correctamente',
        context: {
          'schemaVersion': schemaVersion,
          'daysPerWeek': meta.daysPerWeek,
          'timePerSessionMinutes': meta.timePerSessionMinutes,
          'energyState': energy.state,
        },
      ),
    );

    if (blockCtx != null) {
      trace.add(
        DecisionTrace.info(
          phase: 'TrainingContextBuilder',
          category: 'block_context',
          description: 'Se derivó contexto de bloque macro',
          context: {
            'phaseType': blockCtx.phaseType.name,
            'blockWeekIndex': blockCtx.blockWeekIndex,
            'blockDurationWeeks': blockCtx.blockDurationWeeks,
          },
        ),
      );
    }

    return TrainingContextBuildResult.ok(ctx, trace);
  }

  TrainingBlockContext? _deriveBlockContext(
    TrainingMacroPlan? plan,
    DateTime asOfDate,
  ) {
    if (plan == null) return null;
    DateTime? startDate;
    try {
      startDate = DateTime.parse(plan.startDateIso);
    } catch (_) {
      return null;
    }

    var weekIndexGlobal = ((asOfDate.difference(startDate).inDays) ~/ 7) + 1;
    if (weekIndexGlobal < 1) weekIndexGlobal = 1;
    if (weekIndexGlobal > plan.totalWeeks) {
      weekIndexGlobal = plan.totalWeeks;
    }

    TrainingBlock? currentBlock;
    for (final block in plan.blocks) {
      final start = block.startWeekIndex;
      final end = block.startWeekIndex + block.durationWeeks - 1;
      if (weekIndexGlobal >= start && weekIndexGlobal <= end) {
        currentBlock = block;
        break;
      }
    }

    if (currentBlock == null && plan.blocks.isNotEmpty) {
      // fallback: último bloque si no se encontró coincidencia
      currentBlock = plan.blocks.last;
    }

    if (currentBlock == null) return null;

    final blockWeekIndex = weekIndexGlobal - currentBlock.startWeekIndex + 1;

    return TrainingBlockContext(
      phaseType: currentBlock.phaseType,
      loadProfile: currentBlock.loadProfile,
      blockWeekIndex: blockWeekIndex,
      blockDurationWeeks: currentBlock.durationWeeks,
      autoAdjustEnabled: currentBlock.autoAdjustEnabled,
    );
  }

  EnergyAvailabilitySnapshot _deriveEnergy(
    Client client,
    DateTime asOfDate,
    List<DecisionTrace> trace,
  ) {
    final extra = client.nutrition.extra;
    final raw = extra[NutritionExtraKeys.evaluationRecords];

    if (raw is! List) {
      trace.add(
        DecisionTrace.warning(
          phase: 'TrainingContextBuilder',
          category: 'energy_unavailable',
          description: 'No hay evaluationRecords; energy=unknown',
        ),
      );
      return EnergyAvailabilitySnapshot.unknown();
    }

    // Tomar el record más reciente por dateIso <= asOfDate
    Map<String, dynamic>? best;
    DateTime? bestDate;

    for (final item in raw) {
      if (item is! Map) continue;
      final m = Map<String, dynamic>.from(item);
      final dateStr = m['dateIso']?.toString() ?? '';
      if (dateStr.trim().isEmpty) continue;
      DateTime? d;
      try {
        d = DateTime.parse(dateStr);
      } catch (_) {
        continue;
      }
      if (d.isAfter(asOfDate)) continue;
      if (bestDate == null || d.isAfter(bestDate)) {
        bestDate = d;
        best = m;
      }
    }

    if (best == null) {
      trace.add(
        DecisionTrace.warning(
          phase: 'TrainingContextBuilder',
          category: 'energy_unavailable',
          description:
              'No se encontró record de energía <= asOfDate; energy=unknown',
        ),
      );
      return EnergyAvailabilitySnapshot.unknown();
    }

    final dailyKcal = (best['dailyKcal'] is num)
        ? (best['dailyKcal'] as num).toInt()
        : int.tryParse('${best['dailyKcal']}');
    final dailyGet = (best['dailyGet'] is num)
        ? (best['dailyGet'] as num).toInt()
        : int.tryParse('${best['dailyGet']}');

    if (dailyKcal == null || dailyGet == null) {
      trace.add(
        DecisionTrace.warning(
          phase: 'TrainingContextBuilder',
          category: 'energy_partial',
          description:
              'Record existe pero faltan dailyKcal/dailyGet; energy=unknown',
          context: {'dailyKcal': dailyKcal, 'dailyGet': dailyGet},
        ),
      );
      return EnergyAvailabilitySnapshot.unknown();
    }

    final delta = dailyKcal - dailyGet;
    final state = delta < -50
        ? 'deficit'
        : (delta > 50 ? 'surplus' : 'maintenance');

    return EnergyAvailabilitySnapshot(
      dailyKcal: dailyKcal,
      dailyGet: dailyGet,
      deltaKcalMinusGet: delta,
      state: state,
      magnitude: delta.abs(),
    );
  }

  /// Carga perfiles de intensidad desde extra[intensityProfiles].
  /// Fallback a defaults si no existen.
  Map<String, Map<String, num>> _loadIntensityProfiles(
    Map<String, dynamic> extra,
  ) {
    const defaults = {
      'light': {'min': 55.0, 'max': 65.0, 'rir': 4},
      'medium': {'min': 65.0, 'max': 75.0, 'rir': 3},
      'heavy': {'min': 75.0, 'max': 85.0, 'rir': 2},
    };

    final raw = extra[TrainingExtraKeys.intensityProfiles];
    if (raw is! Map) return defaults;

    // Si hay un planId guardado, usar esos perfiles; si no, usar defaults
    final profiles = <String, Map<String, num>>{};
    for (final key in ['light', 'medium', 'heavy']) {
      final entry = raw[key];
      if (entry is Map) {
        final m = <String, num>{};
        for (final f in ['min', 'max', 'rir']) {
          final v = entry[f];
          if (v is num) m[f] = v;
        }
        if (m.isNotEmpty) {
          profiles[key] = m;
        }
      }
    }

    return profiles.isEmpty ? defaults : profiles;
  }
}
