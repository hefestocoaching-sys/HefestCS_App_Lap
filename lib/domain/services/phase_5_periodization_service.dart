import 'package:hcs_app_lap/core/enums/effort_intent.dart';
import 'package:hcs_app_lap/core/enums/training_level.dart';
import 'package:hcs_app_lap/core/enums/training_phase.dart';
import 'package:hcs_app_lap/domain/entities/decision_trace.dart';
import 'package:hcs_app_lap/domain/entities/manual_override.dart';
import 'package:hcs_app_lap/domain/entities/split_template.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/constants/rir_by_phase.dart';

enum RepBias { high, moderate, low }

class PeriodizedWeek {
  final int weekIndex; // 1-based within block
  final TrainingPhase phase;
  final double volumeFactor; // multiplier applied to daily volumes
  final EffortIntent effortIntent;
  final RepBias repBias;
  final String fatigueExpectation; // low/moderate/high/reset
  final Map<int, Map<String, int>> dailyVolume; // scaled per week
  final double rirTarget;
  final double rirMin;
  final double rirMax;
  final int repRangeMin;
  final int repRangeMax;
  final double intensityTarget;
  final String primaryGoal;
  final String description;

  PeriodizedWeek({
    required this.weekIndex,
    required this.phase,
    required this.volumeFactor,
    required this.effortIntent,
    required this.repBias,
    required this.fatigueExpectation,
    required this.dailyVolume,
    this.rirTarget = 2.5,
    this.rirMin = 2.0,
    this.rirMax = 4.0,
    this.repRangeMin = 8,
    this.repRangeMax = 12,
    this.intensityTarget = 0.70,
    this.primaryGoal = 'volume',
    this.description = '',
  });
}

class Phase5PeriodizationResult {
  final List<PeriodizedWeek> weeks;
  final List<DecisionTrace> decisions;

  const Phase5PeriodizationResult({
    required this.weeks,
    required this.decisions,
  });
}

/// Fase 5: Periodización semanal simple (acumulación → intensificación → deload)
/// - Deload cada 3-4 semanas (patrón fijo de 4 semanas por defecto)
/// - Reducción de volumen en deload: 40-60% (usamos 50% determinístico)
class Phase5PeriodizationService {
  Phase5PeriodizationResult periodize({
    required TrainingProfile profile,
    required SplitTemplate baseSplit,
    ManualOverride? manualOverride,
  }) {
    final decisions = <DecisionTrace>[];

    final totalWeeks = profile.blockLengthWeeks > 0
        ? profile.blockLengthWeeks
        : 4;
    final startIndex = (profile.currentWeekIndex > 0
        ? profile.currentWeekIndex
        : 0);

    final pattern = _buildPhasePattern(totalWeeks);
    decisions.add(
      DecisionTrace.info(
        phase: 'Phase5Periodization',
        category: 'pattern',
        description: 'Patrón de fases generado para $totalWeeks semanas',
        context: pattern.asMap().map(
          (i, p) => MapEntry((i + 1).toString(), p.name),
        ),
      ),
    );

    final weeks = <PeriodizedWeek>[];

    for (var i = 0; i < totalWeeks; i++) {
      final phase = pattern[i];
      final phaseKey =
          phase.name; // 'accumulation', 'intensification', 'deload'
      final config = RIRByPhase.getPhaseConfig(phaseKey);
      final (repMin, repMax) = RIRByPhase.getRepRange(phaseKey);

      final targets = _weekTargets(
        phase: phase,
        weekIdx: i,
        trainingLevel: profile.trainingLevel,
      );
      var factor = targets.volumeFactor;
      var effortIntent = targets.effortIntent;

      // Override de EffortIntent si se indicó
      if (manualOverride?.rirTargetOverride != null) {
        final overrideRir = manualOverride!.rirTargetOverride!;
        if (overrideRir >= 3.0) {
          effortIntent = EffortIntent.deload;
        } else if (overrideRir >= 2.0) {
          effortIntent = EffortIntent.technique;
        } else if (overrideRir >= 1.0) {
          effortIntent = EffortIntent.base;
        } else {
          effortIntent = EffortIntent.push;
        }

        decisions.add(
          DecisionTrace.info(
            phase: 'Phase5Periodization',
            category: 'effort_intent_override_applied',
            description: 'Override de EffortIntent aplicado en periodización',
            context: {
              'week': i + 1,
              'phase': phase.name,
              'overrideRir': manualOverride.rirTargetOverride,
              'effortIntentApplied': effortIntent.name,
            },
          ),
        );
      }
      // Deload clamp 40-60%
      if (phase == TrainingPhase.deload) {
        factor = factor.clamp(0.4, 0.6);
      }

      final scaled = _scaleDailyVolume(baseSplit.dailyVolume, factor);
      weeks.add(
        PeriodizedWeek(
          weekIndex: i + 1 + startIndex,
          phase: phase,
          volumeFactor: factor,
          effortIntent: effortIntent,
          repBias: targets.repBias,
          fatigueExpectation: targets.fatigueExpectation,
          dailyVolume: scaled,
          rirTarget: config['rirTarget'] as double,
          rirMin: config['rirMin'] as double,
          rirMax: config['rirMax'] as double,
          repRangeMin: repMin,
          repRangeMax: repMax,
          intensityTarget: RIRByPhase.getIntensity(phaseKey),
          primaryGoal: config['primaryGoal'] as String,
          description: config['description'] as String,
        ),
      );

      decisions.add(
        DecisionTrace.info(
          phase: 'Phase5Periodization',
          category: 'phase_assignment',
          description: 'Semana ${i + 1}: ${config['description']}',
          context: {
            'weekNumber': i + 1,
            'phase': phaseKey,
            'rirTarget': config['rirTarget'],
            'rirRange': '${config['rirMin']}-${config['rirMax']}',
            'repRange': '$repMin-$repMax',
            'intensity':
                '${(config['intensityMin'] * 100).toInt()}-${(config['intensityMax'] * 100).toInt()}%',
            'primaryGoal': config['primaryGoal'],
          },
        ),
      );

      decisions.add(
        DecisionTrace.info(
          phase: 'Phase5Periodization',
          category: 'week_plan',
          description: 'Semana ${i + 1}: ${phase.name}',
          context: {
            'week': i + 1,
            'phase': phase.name,
            'factor': factor,
            'effortIntent': effortIntent.name,
            'repBias': targets.repBias.name,
            'fatigueExpectation': targets.fatigueExpectation,
            'rirTarget': config['rirTarget'],
            'rirRange': '${config['rirMin']}-${config['rirMax']}',
            'repRange': '$repMin-$repMax',
            'intensityTarget': RIRByPhase.getIntensity(phaseKey),
            'primaryGoal': config['primaryGoal'],
          },
        ),
      );
    }

    // Validar que las semanas de deload tengan reducción 40–60%
    for (final w in weeks) {
      if (w.phase == TrainingPhase.deload) {
        final reduction = (1.0 - w.volumeFactor);
        if (reduction < 0.40 || reduction > 0.60) {
          decisions.add(
            DecisionTrace.critical(
              phase: 'Phase5Periodization',
              category: 'deload_reduction',
              description:
                  'Reducción deload fuera de rango: ${(reduction * 100).toStringAsFixed(0)}% (esperado 40–60%)',
              context: {'factor': w.volumeFactor},
              action: 'Ajustar factor a 0.5',
            ),
          );
        }
      }
    }

    return Phase5PeriodizationResult(weeks: weeks, decisions: decisions);
  }

  List<TrainingPhase> _buildPhasePattern(int totalWeeks) {
    // Patrón determinístico de 4 semanas: A, A, I, D (repetir)
    final base = [
      TrainingPhase.accumulation,
      TrainingPhase.accumulation,
      TrainingPhase.intensification,
      TrainingPhase.deload,
    ];

    final pattern = <TrainingPhase>[];
    for (var i = 0; i < totalWeeks; i++) {
      pattern.add(base[i % base.length]);
    }
    return pattern;
  }

  _WeekTargets _weekTargets({
    required TrainingPhase phase,
    required int weekIdx,
    required TrainingLevel? trainingLevel,
  }) {
    final cyclePosition = weekIdx % 4;
    double factor;
    EffortIntent intent;
    RepBias repBias;
    String fatigue;

    switch (phase) {
      case TrainingPhase.accumulation:
        factor = cyclePosition == 0 ? 0.95 : 1.00;
        if (cyclePosition == 0) {
          intent = EffortIntent.technique;
          repBias = RepBias.high; // 10-15
          fatigue = 'low';
        } else if (cyclePosition == 1) {
          intent = EffortIntent.base;
          repBias = RepBias.moderate; // 8-12
          fatigue = 'moderate';
        } else {
          intent = EffortIntent.push;
          if (trainingLevel == TrainingLevel.beginner) {
            intent = EffortIntent.base;
          }
          repBias = RepBias.moderate; // 8-12
          fatigue = 'high';
        }
        break;
      case TrainingPhase.intensification:
        factor = 0.90;
        intent = EffortIntent.push;
        // Beginner guard: no push intent
        if (trainingLevel == TrainingLevel.beginner) {
          intent = EffortIntent.base;
        }
        repBias = RepBias.low; // 6-10
        fatigue = 'high';
        break;
      case TrainingPhase.deload:
        factor = 0.50;
        intent = EffortIntent.deload;
        repBias = RepBias.high; // 10-15
        fatigue = 'reset';
        break;
    }

    return _WeekTargets(
      volumeFactor: factor,
      effortIntent: intent,
      repBias: repBias,
      fatigueExpectation: fatigue,
    );
  }

  Map<int, Map<String, int>> _scaleDailyVolume(
    Map<int, Map<String, int>> base,
    double factor,
  ) {
    final days = base.keys.toList()..sort();
    final out = <int, Map<String, int>>{};
    // Paso 1: objetivo semanal total
    var weeklyBaseTotal = 0;
    final dayBaseTotals = <int>[];
    final dayRemainders = <double>[];
    final dayFloors = <int>[];

    for (final d in days) {
      final sumDay = base[d]!.values.fold<int>(0, (s, v) => s + v);
      weeklyBaseTotal += sumDay;
      final dbl = sumDay * factor;
      final fl = dbl.floor();
      dayFloors.add(fl);
      dayRemainders.add(dbl - fl);
      dayBaseTotals.add(sumDay);
    }

    final targetWeeklyTotal = (weeklyBaseTotal * factor).round();
    var currentWeekly = dayFloors.fold<int>(0, (s, v) => s + v);

    var diffDays = targetWeeklyTotal - currentWeekly;
    while (diffDays > 0) {
      final idx = _indexOfMax(dayRemainders);
      dayFloors[idx] += 1;
      dayRemainders[idx] = 0.0;
      diffDays -= 1;
    }
    while (diffDays < 0) {
      final idx = _indexOfMin(dayRemainders);
      if (dayFloors[idx] > 0) dayFloors[idx] -= 1;
      dayRemainders[idx] = 1.0;
      diffDays += 1;
    }

    // Paso 2: distribuir por día entre músculos respetando el objetivo del día
    for (var di = 0; di < days.length; di++) {
      final d = days[di];
      final targetDay = dayFloors[di];
      final muscles = base[d]!.keys.toList()..sort();
      final originals = muscles.map((m) => base[d]![m] ?? 0).toList();
      final dbls = originals.map((v) => v * factor).toList();
      final floors = dbls.map((x) => x.floor()).toList();
      var sumFloors = floors.fold<int>(0, (s, v) => s + v);
      final remainders = <double>[];
      for (final x in dbls) {
        remainders.add(x - x.floor());
      }

      var diff = targetDay - sumFloors;
      while (diff > 0) {
        final idx = _indexOfMax(remainders);
        floors[idx] += 1;
        remainders[idx] = 0.0;
        diff -= 1;
      }
      while (diff < 0) {
        final idx = _indexOfMin(remainders);
        if (floors[idx] > 0) floors[idx] -= 1;
        remainders[idx] = 1.0;
        diff += 1;
      }

      final inner = <String, int>{};
      for (var i = 0; i < muscles.length; i++) {
        inner[muscles[i]] = floors[i];
      }
      out[d] = inner;
    }
    return out;
  }

  int _indexOfMax(List<double> values) {
    var idx = 0;
    var max = values[0];
    for (var i = 1; i < values.length; i++) {
      if (values[i] > max) {
        max = values[i];
        idx = i;
      }
    }
    return idx;
  }

  int _indexOfMin(List<double> values) {
    var idx = 0;
    var min = values[0];
    for (var i = 1; i < values.length; i++) {
      if (values[i] < min) {
        min = values[i];
        idx = i;
      }
    }
    return idx;
  }
}

class _WeekTargets {
  final double volumeFactor;
  final EffortIntent effortIntent;
  final RepBias repBias;
  final String fatigueExpectation;

  const _WeekTargets({
    required this.volumeFactor,
    required this.effortIntent,
    required this.repBias,
    required this.fatigueExpectation,
  });
}
