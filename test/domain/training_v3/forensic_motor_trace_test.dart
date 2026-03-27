import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/intensity_distribution_engine.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_plan_config.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_session.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_week.dart';
import 'package:hcs_app_lap/domain/training_v3/models/user_profile.dart';
import 'package:hcs_app_lap/domain/training_v3/services/motor_v3_orchestrator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Forensic Motor V3 Trace', () {
    test('run forensic trace over 5 controlled scenarios', () async {
      final outputDir = Directory('audit_pack');
      if (!outputDir.existsSync()) {
        outputDir.createSync(recursive: true);
      }

      final scenarios = _buildScenarios();
      final runs = <Map<String, dynamic>>[];

      for (var i = 0; i < scenarios.length; i++) {
        final scenario = scenarios[i];
        final run = await _runScenario(i + 1, scenario);
        runs.add(run);

        final scenarioPath =
            'audit_pack/audit_motor_forensic_scenario_${i + 1}.txt';
        File(scenarioPath).writeAsStringSync(_renderScenarioReport(run));
      }

      File('audit_pack/audit_motor_forensic_raw.json').writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert({'runs': runs}),
      );

      File(
        'audit_pack/audit_motor_forensic_summary.txt',
      ).writeAsStringSync(_renderSummaryReport(runs));

      expect(runs.length, 5);
      expect(runs.where((r) => r['scenarioNumber'] is int).length, 5);
    });
  });
}

class _ForensicScenario {
  _ForensicScenario({
    required this.name,
    required this.phase,
    required this.durationWeeks,
    required this.userProfile,
    required this.splitId,
    this.trainingDaysPerWeek,
    this.intensityProfilePercentSplit,
    this.client,
  });

  final String name;
  final String phase;
  final int durationWeeks;
  final UserProfile userProfile;
  final String splitId;
  final int? trainingDaysPerWeek;
  final Map<String, double>? intensityProfilePercentSplit;
  final dynamic client;
}

Future<Map<String, dynamic>> _runScenario(
  int scenarioNumber,
  _ForensicScenario scenario,
) async {
  final capturedLogs = <String>[];
  final oldDebugPrint = debugPrint;

  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null) capturedLogs.add(message);
    oldDebugPrint(message, wrapWidth: wrapWidth);
  };

  try {
    final result = await MotorV3Orchestrator.generateProgram(
      userProfile: scenario.userProfile,
      phase: scenario.phase,
      durationWeeks: scenario.durationWeeks,
      splitId: scenario.splitId,
      trainingDaysPerWeek: scenario.trainingDaysPerWeek,
      intensityProfilePercentSplit: scenario.intensityProfilePercentSplit,
      client: scenario.client,
      exercises: _getMockExercises(),
    );

    final success = result['success'] == true;
    final errors = (result['errors'] as List?)?.map((e) => '$e').toList() ?? [];
    final warnings =
        (result['warnings'] as List?)?.map((e) => '$e').toList() ?? [];

    final stageBInitialVolume = _parseInitialVolumeFromLogs(capturedLogs);
    final stageBPriorities = _parsePrioritiesFromLogs(capturedLogs);
    final stageBLandmarks = _parseLandmarksFromLogs(capturedLogs);
    final backFocus = _resolveScenarioBackFocus(scenario.client);
    final stageCAfterExpand = success
        ? _safeToIntMap(
            ((result['planConfig'] as TrainingPlanConfig).volumePerMuscle),
          )
        : MotorV3Orchestrator.expandBackMuscle(
            Map<String, int>.from(stageBInitialVolume),
            backFocus: backFocus,
          );

    final stageFIntensity =
        IntensityDistributionEngine.buildWeeklyTargets(
          weeklySetsByMuscle: stageCAfterExpand,
          intensitySplitPercent:
              scenario.intensityProfilePercentSplit ?? _defaultIntensitySplit,
        ).map(
          (k, v) => MapEntry(k, {
            'heavy': v.heavySets,
            'medium': v.mediumSets,
            'light': v.lightSets,
          }),
        );

    final planConfig = success
        ? (result['planConfig'] as TrainingPlanConfig)
        : null;
    final week1 = _extractWeek1(planConfig);
    final stageGPerDay = _extractPerDay(week1);
    final assignedTotals = _extractAssignedTotals(week1);
    final diff = _diff(stageCAfterExpand, assignedTotals);

    final flowSections = _collectStageLogs(capturedLogs);
    final primaryFailurePoint = _resolvePrimaryFailurePoint(
      errors: errors,
      stageCTarget: stageCAfterExpand,
      assignedTotals: assignedTotals,
      stageFIntensity: stageFIntensity,
      allLogs: capturedLogs,
    );

    return {
      'scenarioNumber': scenarioNumber,
      'scenarioName': scenario.name,
      'input': {
        'sex': scenario.userProfile.gender,
        'age': scenario.userProfile.age,
        'trainingLevel': scenario.userProfile.trainingLevel,
        'days':
            scenario.trainingDaysPerWeek ?? scenario.userProfile.availableDays,
        'splitId': scenario.splitId,
        'phase': scenario.phase,
        'durationWeeks': scenario.durationWeeks,
        'musclePriorities': scenario.userProfile.musclePriorities,
        'backFocus': backFocus,
        'hasCycleState': scenario.client != null,
        'intensitySplit':
            scenario.intensityProfilePercentSplit ?? _defaultIntensitySplit,
      },
      'success': success,
      'errors': errors,
      'warnings': warnings,
      'stageA': {
        'entrypoint':
            'MotorV3Orchestrator.generateProgram(userProfile, phase, durationWeeks, splitId, trainingDaysPerWeek, intensityProfilePercentSplit, client, exercises)',
        'received': {
          'userId': scenario.userProfile.id,
          'name': scenario.userProfile.name,
          'availableDays': scenario.userProfile.availableDays,
        },
      },
      'stageB': {
        'volumeTargetInicial': stageBInitialVolume,
        'prioridadEfectivaPorMusculo': stageBPriorities,
        'landmarksUsados': stageBLandmarks,
      },
      'stageC': {
        'backFocus': backFocus,
        'targetTrasExpandBackMuscle': stageCAfterExpand,
      },
      'stageD': {
        'splitResolved': _extractSingle(
          capturedLogs,
          RegExp(r'resolvedSplit=([^ ]+)'),
        ),
        'cycleStateReadFromInput': _extractCycleStateFromInput(scenario.client),
        'effectiveFrequencyByMuscle': _parseFrequencyFromLogs(capturedLogs),
      },
      'stageE': {'poolByMuscle': _parsePoolByMuscle(capturedLogs)},
      'stageF': {'weeklyIntensityTargetsByMuscle': stageFIntensity},
      'stageG': {'buildBaseWeekByDay': stageGPerDay},
      'stageH': {
        'assignedTotals': assignedTotals,
        'diffTargetVsAssigned': diff,
      },
      'flowLogs': flowSections,
      'firstFailurePoint': primaryFailurePoint,
      'stackTrace': success ? '' : errors.join('\n'),
    };
  } catch (e, st) {
    final flowSections = _collectStageLogs(capturedLogs);

    return {
      'scenarioNumber': scenarioNumber,
      'scenarioName': scenario.name,
      'input': {
        'sex': scenario.userProfile.gender,
        'age': scenario.userProfile.age,
        'trainingLevel': scenario.userProfile.trainingLevel,
        'days':
            scenario.trainingDaysPerWeek ?? scenario.userProfile.availableDays,
        'splitId': scenario.splitId,
        'phase': scenario.phase,
        'durationWeeks': scenario.durationWeeks,
        'musclePriorities': scenario.userProfile.musclePriorities,
        'backFocus': _resolveScenarioBackFocus(scenario.client),
        'hasCycleState': scenario.client != null,
        'intensitySplit':
            scenario.intensityProfilePercentSplit ?? _defaultIntensitySplit,
      },
      'success': false,
      'errors': ['${e.runtimeType}: $e'],
      'warnings': const <String>[],
      'stageA': {
        'entrypoint':
            'MotorV3Orchestrator.generateProgram(userProfile, phase, durationWeeks, splitId, trainingDaysPerWeek, intensityProfilePercentSplit, client, exercises)',
      },
      'stageB': {
        'volumeTargetInicial': _parseInitialVolumeFromLogs(capturedLogs),
        'prioridadEfectivaPorMusculo': _parsePrioritiesFromLogs(capturedLogs),
        'landmarksUsados': _parseLandmarksFromLogs(capturedLogs),
      },
      'stageC': {'backFocus': _resolveScenarioBackFocus(scenario.client)},
      'stageD': {
        'splitResolved': _extractSingle(
          capturedLogs,
          RegExp(r'resolvedSplit=([^ ]+)'),
        ),
        'cycleStateReadFromInput': _extractCycleStateFromInput(scenario.client),
        'effectiveFrequencyByMuscle': _parseFrequencyFromLogs(capturedLogs),
      },
      'stageE': {'poolByMuscle': _parsePoolByMuscle(capturedLogs)},
      'stageF': {'weeklyIntensityTargetsByMuscle': const <String, dynamic>{}},
      'stageG': {'buildBaseWeekByDay': const <String, dynamic>{}},
      'stageH': {
        'assignedTotals': const <String, int>{},
        'diffTargetVsAssigned': const <String, int>{},
      },
      'flowLogs': flowSections,
      'firstFailurePoint': '6. validacion final',
      'stackTrace': '$e\n$st',
    };
  } finally {
    debugPrint = oldDebugPrint;
  }
}

String _resolvePrimaryFailurePoint({
  required List<String> errors,
  required Map<String, int> stageCTarget,
  required Map<String, int> assignedTotals,
  required Map<String, dynamic> stageFIntensity,
  required List<String> allLogs,
}) {
  if (errors.any((e) => e.contains('[V3][P0.2][INFEASIBLE]'))) {
    return '1. volume target';
  }

  final backLine = allLogs.where((l) => l.contains('[BackFocus]')).toList();
  if (backLine.isNotEmpty && backLine.any((l) => l.contains('backInput='))) {
    final changed = backLine.any((l) {
      final m1 = RegExp(r'backInput=(\d+)').firstMatch(l);
      final m2 = RegExp(r'consolidatedBack=(\d+)').firstMatch(l);
      if (m1 == null || m2 == null) return false;
      return m1.group(1) != m2.group(1);
    });
    if (changed) return '2. expandir back';
  }

  final hasIntensityMismatch = stageFIntensity.entries.any((entry) {
    final muscle = entry.key;
    final map = entry.value as Map<String, dynamic>;
    final sum =
        (map['heavy'] as int) + (map['medium'] as int) + (map['light'] as int);
    final target = stageCTarget[muscle] ?? 0;
    return target > 0 && sum != target;
  });
  if (hasIntensityMismatch) return '3. intensidad';

  final noExercisesError =
      errors.any((e) => e.contains('No exercises available')) ||
      allLogs.any((l) => l.contains('No exercises available'));
  if (noExercisesError) return '4. seleccion de ejercicios';

  final hasDiff = _diff(stageCTarget, assignedTotals).values.any((v) => v != 0);
  if (hasDiff) return '5. builder/session allocation';

  if (errors.isNotEmpty) return '6. validacion final';

  return 'SIN_DESVIO';
}

Map<String, dynamic> _collectStageLogs(List<String> logs) {
  List<String> pick(List<RegExp> patterns) {
    return logs.where((line) {
      for (final p in patterns) {
        if (p.hasMatch(line)) return true;
      }
      return false;
    }).toList();
  }

  return {
    'A': pick([
      RegExp(r'Perfil científico construido'),
      RegExp(r'Age:'),
      RegExp(r'Experience:'),
      RegExp(r'Recovery:'),
    ]),
    'B': pick([
      RegExp(r'Prioridades normalizadas'),
      RegExp(r'VOLÚMENES INICIALES'),
      RegExp(r' sets/semana'),
      RegExp(r'BackMap'),
    ]),
    'C': pick([RegExp(r'\[BackFocus\]'), RegExp(r'expandBackMuscle')]),
    'D': pick([
      RegExp(r'splitId='),
      RegExp(r'\[V3\]\[P1A\]'),
      RegExp(r'cycle'),
    ]),
    'E': pick([
      RegExp(r'\[B4\]\[POOL_RAW\]'),
      RegExp(r'\[B4\]\[POOL_RESOLVED\]'),
      RegExp(r'\[V3\]\[MESOCYCLE_POOL\]'),
    ]),
    'F': pick([
      RegExp(r'\[V3\]\[INTENSITY_PROFILE\]'),
      RegExp(r'\[V3\]\[INTENSITY_DISTRIBUTION\]'),
    ]),
    'G': pick([
      RegExp(r'\[CycleTemplateBuilder\]\[B4\] Day'),
      RegExp(r'\[V3\]\[SESSION_SLOT_PLAN\]'),
      RegExp(r'\[V3\]\[REP_STRUCTURE\]'),
    ]),
    'H': pick([
      RegExp(r'\[V3\]\[P0\.2\]\[VOL\]'),
      RegExp(r'\[Coverage\] assignedTotals'),
      RegExp(r'\[V3\]\[P0\.2\]\[COVERAGE_FAIL\]'),
    ]),
  };
}

Map<String, int> _parseInitialVolumeFromLogs(List<String> logs) {
  final map = <String, int>{};
  final lineReg = RegExp(r'^\s*([a-zA-Z_]+) \(P\d .*\): (\d+) sets/semana$');

  for (final line in logs) {
    final m = lineReg.firstMatch(line.trim());
    if (m != null) {
      map[m.group(1)!] = int.parse(m.group(2)!);
    }
  }

  return map;
}

Map<String, int> _parsePrioritiesFromLogs(List<String> logs) {
  final map = <String, int>{};
  final reg = RegExp(r'^- ([a-zA-Z_]+): P(\d+)$');

  for (final raw in logs) {
    final line = raw.trim();
    final m = reg.firstMatch(line);
    if (m != null) {
      map[m.group(1)!] = int.parse(m.group(2)!);
    }
  }

  return map;
}

Map<String, dynamic> _parseLandmarksFromLogs(List<String> logs) {
  final landmarks = <String, dynamic>{};
  String? currentMuscle;

  for (final raw in logs) {
    final line = raw.trim();
    final start = RegExp(
      r'^\[LandmarksCalc\] ([a-zA-Z_]+) \(P(\d+)\):$',
    ).firstMatch(line);
    if (start != null) {
      currentMuscle = start.group(1);
      landmarks[currentMuscle!] = {'priority': int.parse(start.group(2)!)};
      continue;
    }

    if (currentMuscle == null) continue;

    final vme = RegExp(r'^VME: (\d+) sets$').firstMatch(line);
    if (vme != null) {
      (landmarks[currentMuscle] as Map<String, dynamic>)['vme'] = int.parse(
        vme.group(1)!,
      );
      continue;
    }

    final vop = RegExp(r'^VOP: (\d+) sets').firstMatch(line);
    if (vop != null) {
      (landmarks[currentMuscle] as Map<String, dynamic>)['vop'] = int.parse(
        vop.group(1)!,
      );
      continue;
    }

    final vmr = RegExp(r'^VMR: (\d+) sets').firstMatch(line);
    if (vmr != null) {
      (landmarks[currentMuscle] as Map<String, dynamic>)['vmr'] = int.parse(
        vmr.group(1)!,
      );
      continue;
    }

    final target = RegExp(r'^Target: (\d+) sets').firstMatch(line);
    if (target != null) {
      (landmarks[currentMuscle] as Map<String, dynamic>)['target'] = int.parse(
        target.group(1)!,
      );
      continue;
    }
  }

  return landmarks;
}

Map<String, int> _parseFrequencyFromLogs(List<String> logs) {
  final map = <String, int>{};
  final reg = RegExp(
    r'\[V3\]\[P0\.2\]\[FEASIBLE\] muscle=([a-zA-Z_]+).*freq=(\d+)',
  );

  for (final line in logs) {
    final m = reg.firstMatch(line);
    if (m != null) {
      map[m.group(1)!] = int.parse(m.group(2)!);
    }
  }

  return map;
}

Map<String, List<String>> _parsePoolByMuscle(List<String> logs) {
  final pools = <String, List<String>>{};
  final reg = RegExp(
    r'\[V3\]\[MESOCYCLE_POOL\] muscle=([a-zA-Z_]+).* ids=\[(.*)\]',
  );

  for (final line in logs) {
    final m = reg.firstMatch(line);
    if (m == null) continue;
    final muscle = m.group(1)!;
    final itemsRaw = m.group(2)!.trim();
    if (itemsRaw.isEmpty) {
      pools[muscle] = const <String>[];
      continue;
    }
    pools[muscle] = itemsRaw.split(',').map((s) => s.trim()).toList();
  }

  return pools;
}

String _extractSingle(List<String> logs, RegExp reg) {
  for (final line in logs) {
    final m = reg.firstMatch(line);
    if (m != null && m.groupCount >= 1) {
      return m.group(1) ?? '';
    }
  }
  return '';
}

Map<String, dynamic> _extractCycleStateFromInput(dynamic client) {
  try {
    final extraRaw = client?.training?.extra;
    if (extraRaw is Map) {
      final extra = Map<String, dynamic>.from(extraRaw);
      return {
        'cycleWeek': extra['cycleWeek'],
        'cyclePhase': extra['cyclePhase'] ?? extra['phase'],
        'weeksInPhase': extra['weeksInPhase'],
        'weeksSinceLastMicro': extra['weeksSinceLastMicro'],
      };
    }
  } catch (_) {}

  return {
    'cycleWeek': null,
    'cyclePhase': null,
    'weeksInPhase': null,
    'weeksSinceLastMicro': null,
  };
}

Map<String, int> _extractAssignedTotals(TrainingWeek? week) {
  final totals = <String, int>{};
  if (week == null) return totals;

  for (final session in week.sessions.whereType<TrainingSession>()) {
    for (final ex in session.exercises) {
      final key = ex.muscleKey;
      totals[key] = (totals[key] ?? 0) + ex.sets.length;
    }
  }
  return totals;
}

Map<String, dynamic> _extractPerDay(TrainingWeek? week) {
  final perDay = <String, dynamic>{};
  if (week == null) return perDay;

  for (final session in week.sessions.whereType<TrainingSession>()) {
    final byMuscle = <String, int>{};
    final exercises = <Map<String, dynamic>>[];

    for (final ex in session.exercises) {
      byMuscle[ex.muscleKey] = (byMuscle[ex.muscleKey] ?? 0) + ex.sets.length;
      exercises.add({
        'exerciseId': ex.exerciseId,
        'muscle': ex.muscleKey,
        'sets': ex.sets.length,
      });
    }

    perDay['day_${session.dayNumber}'] = {
      'muscleSets': byMuscle,
      'exercises': exercises,
    };
  }

  return perDay;
}

TrainingWeek? _extractWeek1(TrainingPlanConfig? planConfig) {
  if (planConfig == null) return null;
  final weeks = planConfig.weeks.whereType<TrainingWeek>().toList();
  if (weeks.isEmpty) return null;
  return weeks.first;
}

Map<String, int> _diff(Map<String, int> target, Map<String, int> assigned) {
  final keys = {...target.keys, ...assigned.keys};
  final result = <String, int>{};

  for (final k in keys) {
    result[k] = (assigned[k] ?? 0) - (target[k] ?? 0);
  }

  return result;
}

Map<String, int> _safeToIntMap(Map<String, dynamic>? map) {
  final result = <String, int>{};
  if (map == null) return result;

  for (final entry in map.entries) {
    final value = entry.value;
    if (value is int) {
      result[entry.key] = value;
    } else if (value is num) {
      result[entry.key] = value.round();
    }
  }

  return result;
}

String _resolveScenarioBackFocus(dynamic client) {
  try {
    final extra = client?.training?.extra;
    if (extra is Map && extra['backFocus'] is String) {
      final v = (extra['backFocus'] as String).trim().toLowerCase();
      if (v == 'lats' || v == 'upper_back') return v;
    }
  } catch (_) {}
  return 'upper_back';
}

String _renderScenarioReport(Map<String, dynamic> run) {
  final buffer = StringBuffer();

  buffer.writeln('SCENARIO ${run['scenarioNumber']}: ${run['scenarioName']}');
  buffer.writeln('SUCCESS: ${run['success']}');
  buffer.writeln('INPUT:');
  buffer.writeln(const JsonEncoder.withIndent('  ').convert(run['input']));
  buffer.writeln();

  buffer.writeln('ETAPA A - entrada del motor');
  buffer.writeln(const JsonEncoder.withIndent('  ').convert(run['stageA']));
  buffer.writeln();

  buffer.writeln('ETAPA B - _resolveVolumeTargets');
  buffer.writeln(const JsonEncoder.withIndent('  ').convert(run['stageB']));
  buffer.writeln();

  buffer.writeln('ETAPA C - expandBackMuscle');
  buffer.writeln(const JsonEncoder.withIndent('  ').convert(run['stageC']));
  buffer.writeln();

  buffer.writeln('ETAPA D - split/frecuencia/state');
  buffer.writeln(const JsonEncoder.withIndent('  ').convert(run['stageD']));
  buffer.writeln();

  buffer.writeln('ETAPA E - catalogo/pool');
  buffer.writeln(const JsonEncoder.withIndent('  ').convert(run['stageE']));
  buffer.writeln();

  buffer.writeln('ETAPA F - weeklyIntensityTargetsByMuscle');
  buffer.writeln(const JsonEncoder.withIndent('  ').convert(run['stageF']));
  buffer.writeln();

  buffer.writeln('ETAPA G - buildBaseWeek');
  buffer.writeln(const JsonEncoder.withIndent('  ').convert(run['stageG']));
  buffer.writeln();

  buffer.writeln('ETAPA H - assignedTotals y diferencias');
  buffer.writeln(const JsonEncoder.withIndent('  ').convert(run['stageH']));
  buffer.writeln();

  buffer.writeln('PRIMER PUNTO DE FALLA: ${run['firstFailurePoint']}');
  buffer.writeln('ERRORS: ${run['errors']}');
  buffer.writeln('WARNINGS: ${run['warnings']}');

  final stackTrace = run['stackTrace']?.toString() ?? '';
  if (stackTrace.isNotEmpty) {
    buffer.writeln('STACK TRACE:');
    buffer.writeln(stackTrace);
  }

  buffer.writeln();
  buffer.writeln('TRAZAS CLAVE POR ETAPA (extraidas de ejecucion real):');
  buffer.writeln(const JsonEncoder.withIndent('  ').convert(run['flowLogs']));

  return buffer.toString();
}

String _renderSummaryReport(List<Map<String, dynamic>> runs) {
  final buffer = StringBuffer();

  buffer.writeln('AUDITORIA FORENSE MOTOR V3 - RESUMEN');
  buffer.writeln(
    'ENTRYPOINT REAL: lib/domain/training_v3/services/motor_v3_orchestrator.dart :: MotorV3Orchestrator.generateProgram(...)',
  );
  buffer.writeln(
    'DEPENDENCIAS MINIMAS: UserProfile valido, phase, durationWeeks, splitId/trainingDays, exercises o catalogo cargado, client opcional para cycle state/backFocus/intensity split.',
  );
  buffer.writeln();

  for (final run in runs) {
    final stageH = run['stageH'] as Map<String, dynamic>? ?? {};
    final diff = stageH['diffTargetVsAssigned'] as Map<String, dynamic>? ?? {};

    buffer.writeln('SCENARIO ${run['scenarioNumber']}: ${run['scenarioName']}');
    buffer.writeln('SUCCESS: ${run['success']}');
    buffer.writeln('PRIMER PUNTO DE FALLA: ${run['firstFailurePoint']}');
    buffer.writeln('DIFERENCIAS target-vs-assigned: ${jsonEncode(diff)}');
    if ((run['errors'] as List).isNotEmpty) {
      buffer.writeln('ERRORS: ${run['errors']}');
    }
    buffer.writeln();
  }

  return buffer.toString();
}

List<_ForensicScenario> _buildScenarios() {
  final now = DateTime.now();

  UserProfile profile({
    required String id,
    required String name,
    required String gender,
    required int age,
    required String level,
    required double years,
    required int days,
    required Map<String, int> priorities,
  }) {
    return UserProfile(
      id: id,
      name: name,
      email: '$id@test.local',
      age: age,
      gender: gender,
      heightCm: 175,
      weightKg: 75,
      yearsTraining: years,
      trainingLevel: level,
      availableDays: days,
      sessionDuration: 60,
      primaryGoal: 'hypertrophy',
      musclePriorities: priorities,
      availableEquipment: const [
        'barbell',
        'dumbbell',
        'machine',
        'cable',
        'bodyweight',
      ],
      createdAt: now,
      updatedAt: now,
    );
  }

  return [
    _ForensicScenario(
      name: 'novice 3 dias pocas prioridades sin back explicito',
      phase: 'accumulation',
      durationWeeks: 4,
      splitId: 'fullBody',
      trainingDaysPerWeek: 3,
      userProfile: profile(
        id: 'forensic_s1',
        name: 'Forensic S1',
        gender: 'female',
        age: 22,
        level: 'novice',
        years: 0.0,
        days: 3,
        priorities: const {
          'chest': 3,
          'quads': 4,
          'glutes': 4,
          'deltoide_lateral': 3,
        },
      ),
    ),
    _ForensicScenario(
      name: 'novice 4 dias con back prioridad',
      phase: 'accumulation',
      durationWeeks: 4,
      splitId: 'upperLower',
      trainingDaysPerWeek: 4,
      userProfile: profile(
        id: 'forensic_s2',
        name: 'Forensic S2',
        gender: 'male',
        age: 31,
        level: 'novice',
        years: 1.0,
        days: 4,
        priorities: const {
          'back': 5,
          'chest': 4,
          'quads': 4,
          'biceps': 3,
          'triceps': 3,
        },
      ),
      client: _FakeClient(
        id: 'fake_client_s2',
        training: _FakeTraining(extra: {'backFocus': 'lats'}),
      ),
    ),
    _ForensicScenario(
      name: 'intermediate 4 dias upper lower',
      phase: 'accumulation',
      durationWeeks: 4,
      splitId: 'upperLower',
      trainingDaysPerWeek: 4,
      userProfile: profile(
        id: 'forensic_s3',
        name: 'Forensic S3',
        gender: 'female',
        age: 29,
        level: 'intermediate',
        years: 3.0,
        days: 4,
        priorities: const {
          'chest': 5,
          'lats': 4,
          'upper_back': 4,
          'quads': 4,
          'hamstrings': 3,
          'deltoide_lateral': 4,
        },
      ),
    ),
    _ForensicScenario(
      name: 'intermediate 5 dias torso prioridades multiples',
      phase: 'accumulation',
      durationWeeks: 4,
      splitId: 'fullBody',
      trainingDaysPerWeek: 5,
      userProfile: profile(
        id: 'forensic_s4',
        name: 'Forensic S4',
        gender: 'male',
        age: 35,
        level: 'intermediate',
        years: 5.0,
        days: 5,
        priorities: const {
          'chest': 5,
          'lats': 5,
          'upper_back': 4,
          'deltoide_lateral': 5,
          'biceps': 4,
          'triceps': 4,
          'quads': 3,
        },
      ),
      intensityProfilePercentSplit: const {
        'heavy': 30,
        'medium': 50,
        'light': 20,
      },
    ),
    _ForensicScenario(
      name: 'advanced 6 dias alta frecuencia con cycle state',
      phase: 'intensification',
      durationWeeks: 4,
      splitId: 'pushPullLegs',
      trainingDaysPerWeek: 6,
      userProfile: profile(
        id: 'forensic_s5',
        name: 'Forensic S5',
        gender: 'male',
        age: 39,
        level: 'advanced',
        years: 12.0,
        days: 6,
        priorities: const {
          'back': 5,
          'chest': 5,
          'deltoide_lateral': 5,
          'quads': 4,
          'hamstrings': 4,
          'biceps': 4,
          'triceps': 4,
        },
      ),
      client: _FakeClient(
        id: 'fake_client_s5',
        training: _FakeTraining(
          extra: {
            'cycleWeek': 4,
            'cyclePhase': 'accumulation',
            'weeksInPhase': 3,
            'weeksSinceLastMicro': 4,
            'phase': 'accumulation',
            'backFocus': 'upper_back',
            'seriesTypePercentSplit': {'heavy': 35, 'medium': 45, 'light': 20},
          },
        ),
      ),
      intensityProfilePercentSplit: const {
        'heavy': 35,
        'medium': 45,
        'light': 20,
      },
    ),
  ];
}

const Map<String, double> _defaultIntensitySplit = {
  'heavy': 20,
  'medium': 60,
  'light': 20,
};

class _FakeTraining {
  _FakeTraining({required this.extra});
  final Map<String, dynamic> extra;
}

class _FakeClient {
  _FakeClient({required this.id, required this.training});

  final String id;
  final _FakeTraining training;
}

List<Exercise> _getMockExercises() {
  return [
    Exercise(
      id: 'bench_press',
      externalId: 'ext_bench_press',
      name: 'Bench Press',
      muscleKey: 'chest',
      primaryMuscles: ['chest'],
      secondaryMuscles: ['triceps', 'deltoide_anterior'],
      equipment: 'barbell',
      difficulty: 'intermediate',
    ),
    Exercise(
      id: 'lat_pulldown',
      externalId: 'ext_lat_pulldown',
      name: 'Lat Pulldown',
      muscleKey: 'lats',
      primaryMuscles: ['lats'],
      secondaryMuscles: ['biceps'],
      equipment: 'machine',
      difficulty: 'beginner',
    ),
    Exercise(
      id: 'upper_back_row',
      externalId: 'ext_upper_back_row',
      name: 'Upper Back Row',
      muscleKey: 'upper_back',
      primaryMuscles: ['upper_back'],
      secondaryMuscles: ['biceps'],
      equipment: 'cable',
      difficulty: 'beginner',
    ),
    Exercise(
      id: 'traps_shrug',
      externalId: 'ext_traps_shrug',
      name: 'Traps Shrug',
      muscleKey: 'traps',
      primaryMuscles: ['traps'],
      secondaryMuscles: [],
      equipment: 'dumbbell',
      difficulty: 'beginner',
    ),
    Exercise(
      id: 'squat',
      externalId: 'ext_squat',
      name: 'Squat',
      muscleKey: 'quads',
      primaryMuscles: ['quads'],
      secondaryMuscles: ['glutes', 'hamstrings'],
      equipment: 'barbell',
      difficulty: 'intermediate',
    ),
    Exercise(
      id: 'romanian_deadlift',
      externalId: 'ext_rdl',
      name: 'Romanian Deadlift',
      muscleKey: 'hamstrings',
      primaryMuscles: ['hamstrings'],
      secondaryMuscles: ['glutes'],
      equipment: 'barbell',
      difficulty: 'intermediate',
    ),
    Exercise(
      id: 'lateral_raise',
      externalId: 'ext_lateral_raise',
      name: 'Lateral Raise',
      muscleKey: 'deltoide_lateral',
      primaryMuscles: ['deltoide_lateral'],
      secondaryMuscles: [],
      equipment: 'dumbbell',
      difficulty: 'beginner',
    ),
    Exercise(
      id: 'front_raise',
      externalId: 'ext_front_raise',
      name: 'Front Raise',
      muscleKey: 'deltoide_anterior',
      primaryMuscles: ['deltoide_anterior'],
      secondaryMuscles: [],
      equipment: 'dumbbell',
      difficulty: 'beginner',
    ),
    Exercise(
      id: 'reverse_fly',
      externalId: 'ext_reverse_fly',
      name: 'Reverse Fly',
      muscleKey: 'deltoide_posterior',
      primaryMuscles: ['deltoide_posterior'],
      secondaryMuscles: [],
      equipment: 'dumbbell',
      difficulty: 'beginner',
    ),
    Exercise(
      id: 'biceps_curl',
      externalId: 'ext_biceps_curl',
      name: 'Biceps Curl',
      muscleKey: 'biceps',
      primaryMuscles: ['biceps'],
      secondaryMuscles: [],
      equipment: 'dumbbell',
      difficulty: 'beginner',
    ),
    Exercise(
      id: 'triceps_extension',
      externalId: 'ext_triceps_extension',
      name: 'Triceps Extension',
      muscleKey: 'triceps',
      primaryMuscles: ['triceps'],
      secondaryMuscles: [],
      equipment: 'cable',
      difficulty: 'beginner',
    ),
    Exercise(
      id: 'hip_thrust',
      externalId: 'ext_hip_thrust',
      name: 'Hip Thrust',
      muscleKey: 'glutes',
      primaryMuscles: ['glutes'],
      secondaryMuscles: ['hamstrings'],
      equipment: 'barbell',
      difficulty: 'intermediate',
    ),
    Exercise(
      id: 'standing_calf_raise',
      externalId: 'ext_calf_raise',
      name: 'Standing Calf Raise',
      muscleKey: 'calves',
      primaryMuscles: ['calves'],
      secondaryMuscles: [],
      equipment: 'machine',
      difficulty: 'beginner',
    ),
    Exercise(
      id: 'crunch',
      externalId: 'ext_crunch',
      name: 'Crunch',
      muscleKey: 'abs',
      primaryMuscles: ['abs'],
      secondaryMuscles: [],
      equipment: 'bodyweight',
      difficulty: 'beginner',
    ),
  ];
}
