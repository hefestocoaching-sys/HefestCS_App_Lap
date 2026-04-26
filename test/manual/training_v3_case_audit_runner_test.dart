import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/core/enums/gender.dart';
import 'package:hcs_app_lap/core/enums/training_goal.dart';
import 'package:hcs_app_lap/core/enums/training_level.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/client_profile.dart';
import 'package:hcs_app_lap/domain/entities/clinical_history.dart';
import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/domain/entities/nutrition_settings.dart';
import 'package:hcs_app_lap/domain/entities/training_plan_config.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/training_v3/ml/strategies/rule_based_strategy.dart';
import 'package:hcs_app_lap/domain/training_v3/orchestrator/training_orchestrator_v3.dart';
import 'package:hcs_app_lap/domain/training_v3/validators/training_plan_forensic_validator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Run 5 controlled real Motor V3 cases and generate markdown audits',
    () async {
      final casesDir = Directory('docs/audits/generated_cases');
      if (!casesDir.existsSync()) {
        casesDir.createSync(recursive: true);
      }

      final allExercises = _loadExercisesFromCatalog(
        'assets/data/exercises/exercise_catalog_gym.json',
      );

      final caseSpecs = _buildCaseSpecs();
      final summaries = <_CaseSummary>[];

      final orchestrator = TrainingOrchestratorV3(
        strategy: RuleBasedStrategy(),
      );

      for (final spec in caseSpecs) {
        final exercises = spec.allowedEquipment == null
            ? allExercises
            : _filterExercisesByEquipment(allExercises, spec.allowedEquipment!);

        final client = _buildClientFromCase(spec);

        final inputPayload = _buildInputPayload(spec, client, exercises.length);

        final result = await orchestrator.generatePlan(
          client: client,
          exercises: exercises,
          asOfDate: spec.asOfDate,
          phase: spec.phase,
        );

        TrainingPlanConfig? plan;
        TrainingPlanForensicValidationResult? forensic;

        if (!result.isBlocked && result.plan != null) {
          plan = result.plan!;
          forensic = TrainingPlanForensicValidator.validate(
            planConfig: plan,
            expectedWeeklyVolumeByMuscle: plan.volumePerMuscle,
          );
        }

        final summary = _CaseSummary(
          id: spec.id,
          title: spec.title,
          caseType: spec.caseType,
          generated: !result.isBlocked && plan != null,
          forensicValid: forensic?.isValid,
          split: plan?.splitId,
          primaryMuscles: spec.mappedPrimary,
          frequency: _computeFrequencyLabel(plan),
          blockingCount:
              (forensic?.blockingErrors.length ?? 0) +
              (result.isBlocked ? 1 : 0),
          warningCount:
              (forensic?.warnings.length ?? 0) +
              (result.suggestions?.length ?? 0),
          note: result.isBlocked
              ? (result.blockReason ?? 'Blocked')
              : 'Plan generado',
        );
        summaries.add(summary);

        _printConsoleSummary(summary);

        final markdown = _buildCaseMarkdown(
          spec: spec,
          inputPayload: inputPayload,
          result: result,
          plan: plan,
          forensic: forensic,
        );

        File(spec.outputFile).writeAsStringSync(markdown);
      }

      final indexMarkdown = _buildIndexSummaryMarkdown(summaries);
      File(
        'docs/audits/generated_cases/index_summary.md',
      ).writeAsStringSync(indexMarkdown);
    },
  );
}

class _CaseSpec {
  final String id;
  final String title;
  final String objective;
  final String caseType;
  final String outputFile;
  final DateTime asOfDate;
  final String phase;

  final String fullName;
  final Gender gender;
  final int age;
  final double heightCm;
  final double weightKg;
  final TrainingLevel trainingLevel;
  final int daysPerWeek;
  final int sessionMinutes;
  final double yearsTraining;
  final double avgSleepHours;
  final String perceivedStress;
  final String recoveryQuality;
  final String goal;

  final List<String> mappedPrimary;
  final List<String> mappedSecondary;
  final List<String> mappedTertiary;

  final List<String>? allowedEquipment;
  final List<String> injuryList;
  final String mappingNotes;

  const _CaseSpec({
    required this.id,
    required this.title,
    required this.objective,
    required this.caseType,
    required this.outputFile,
    required this.asOfDate,
    required this.phase,
    required this.fullName,
    required this.gender,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.trainingLevel,
    required this.daysPerWeek,
    required this.sessionMinutes,
    required this.yearsTraining,
    required this.avgSleepHours,
    required this.perceivedStress,
    required this.recoveryQuality,
    required this.goal,
    required this.mappedPrimary,
    required this.mappedSecondary,
    required this.mappedTertiary,
    required this.allowedEquipment,
    required this.injuryList,
    required this.mappingNotes,
  });
}

class _CaseSummary {
  final String id;
  final String title;
  final String caseType;
  final bool generated;
  final bool? forensicValid;
  final String? split;
  final List<String> primaryMuscles;
  final String frequency;
  final int blockingCount;
  final int warningCount;
  final String note;

  const _CaseSummary({
    required this.id,
    required this.title,
    required this.caseType,
    required this.generated,
    required this.forensicValid,
    required this.split,
    required this.primaryMuscles,
    required this.frequency,
    required this.blockingCount,
    required this.warningCount,
    required this.note,
  });
}

List<_CaseSpec> _buildCaseSpecs() {
  final now = DateTime(2026, 4, 17);
  return [
    _CaseSpec(
      id: 'case_01',
      title: 'NORMAL TORSO PRIORITY',
      objective:
          'Validar inicio y prioridad de torso con orden coherente pectoral/espalda.',
      caseType: 'normal',
      outputFile:
          'docs/audits/generated_cases/case_01_normal_torso_priority.md',
      asOfDate: now,
      phase: 'accumulation',
      fullName: 'Caso 01 Torso',
      gender: Gender.male,
      age: 31,
      heightCm: 176,
      weightKg: 79,
      trainingLevel: TrainingLevel.intermediate,
      daysPerWeek: 4,
      sessionMinutes: 90,
      yearsTraining: 3.0,
      avgSleepHours: 7.5,
      perceivedStress: 'medium_low',
      recoveryQuality: 'normal',
      goal: 'hypertrophy_torso_emphasis',
      mappedPrimary: ['pectorals', 'lats', 'upper_back'],
      mappedSecondary: ['delts_lateral', 'biceps', 'triceps'],
      mappedTertiary: ['quads', 'glutes', 'hamstrings', 'calves'],
      allowedEquipment: null,
      injuryList: const [],
      mappingNotes:
          '"Torso" se mapeo a pectorals+lats+upper_back. Deltoide lateral se mapeo a delts_lateral. Pierna completa se expandio a quads/glutes/hamstrings/calves.',
    ),
    _CaseSpec(
      id: 'case_02',
      title: 'NORMAL LOWER PRIORITY',
      objective:
          'Validar arranque y alternancia de prioridad pierna (cuadriceps/gluteo) en 6 dias.',
      caseType: 'normal',
      outputFile:
          'docs/audits/generated_cases/case_02_normal_lower_priority.md',
      asOfDate: now,
      phase: 'accumulation',
      fullName: 'Caso 02 Lower',
      gender: Gender.female,
      age: 29,
      heightCm: 165,
      weightKg: 62,
      trainingLevel: TrainingLevel.intermediate,
      daysPerWeek: 6,
      sessionMinutes: 75,
      yearsTraining: 3.5,
      avgSleepHours: 7.0,
      perceivedStress: 'medium',
      recoveryQuality: 'normal',
      goal: 'hypertrophy_lower_emphasis',
      mappedPrimary: ['quads', 'glutes'],
      mappedSecondary: ['hamstrings', 'calves'],
      mappedTertiary: [
        'pectorals',
        'lats',
        'upper_back',
        'delts_front',
        'delts_lateral',
        'delts_rear',
        'biceps',
        'triceps',
      ],
      allowedEquipment: null,
      injuryList: const [],
      mappingNotes:
          '"Pierna" se mapeo a quads/glutes/hamstrings/calves. Torso completo se expandio a pectorals+lats+upper_back+delts+biceps+triceps.',
    ),
    _CaseSpec(
      id: 'case_03',
      title: 'RARE HIGH VOLUME FREQUENCY3',
      objective:
          'Probar comportamiento en alto volumen y frecuencia 3 potencial para musculos prioritarios.',
      caseType: 'raro',
      outputFile:
          'docs/audits/generated_cases/case_03_rare_high_volume_frequency3.md',
      asOfDate: now,
      phase: 'intensification',
      fullName: 'Caso 03 High Volume',
      gender: Gender.male,
      age: 35,
      heightCm: 182,
      weightKg: 86,
      trainingLevel: TrainingLevel.advanced,
      daysPerWeek: 6,
      sessionMinutes: 100,
      yearsTraining: 9.0,
      avgSleepHours: 8.5,
      perceivedStress: 'low',
      recoveryQuality: 'high',
      goal: 'high_volume_hypertrophy',
      mappedPrimary: ['lats', 'upper_back', 'pectorals', 'quads'],
      mappedSecondary: ['glutes', 'hamstrings', 'delts_lateral'],
      mappedTertiary: ['biceps', 'triceps', 'calves'],
      allowedEquipment: null,
      injuryList: const [],
      mappingNotes:
          'Espalda se separo en lats+upper_back para SSOT muscular. Perfil de recuperacion alto se codifico en extra (sleep/stress/recoveryQuality).',
    ),
    _CaseSpec(
      id: 'case_04',
      title: 'RARE EQUIPMENT CONSTRAINTS',
      objective:
          'Verificar respeto de restricciones de equipo y fallback por equivalence group.',
      caseType: 'raro',
      outputFile:
          'docs/audits/generated_cases/case_04_rare_equipment_constraints.md',
      asOfDate: now,
      phase: 'accumulation',
      fullName: 'Caso 04 Equipment',
      gender: Gender.male,
      age: 32,
      heightCm: 174,
      weightKg: 78,
      trainingLevel: TrainingLevel.intermediate,
      daysPerWeek: 5,
      sessionMinutes: 70,
      yearsTraining: 3.0,
      avgSleepHours: 6.8,
      perceivedStress: 'medium',
      recoveryQuality: 'normal',
      goal: 'hypertrophy_torso_priority_equipment_limited',
      mappedPrimary: ['pectorals', 'lats', 'upper_back'],
      mappedSecondary: ['delts_rear', 'biceps', 'triceps'],
      mappedTertiary: ['quads', 'glutes', 'hamstrings'],
      allowedEquipment: const [
        'dumbbell',
        'barbell',
        'bench',
        'cable',
        'pull_up_bar',
        'bodyweight',
      ],
      injuryList: const [],
      mappingNotes:
          'Se aplico filtro duro de catalogo por allowedEquipment: mancuernas/barra/banco/poleas equivalen a dumbbell/barbell/bench/cable. Se excluyen maquinas especificas no listadas.',
    ),
    _CaseSpec(
      id: 'case_05',
      title: 'RARE LOW RECOVERY CONFLICT',
      objective:
          'Evaluar conflicto entre 6 dias declarados y baja recuperacion/fatiga externa alta.',
      caseType: 'raro',
      outputFile:
          'docs/audits/generated_cases/case_05_rare_low_recovery_conflict.md',
      asOfDate: now,
      phase: 'accumulation',
      fullName: 'Caso 05 Low Recovery',
      gender: Gender.female,
      age: 27,
      heightCm: 163,
      weightKg: 61,
      trainingLevel: TrainingLevel.beginner,
      daysPerWeek: 6,
      sessionMinutes: 60,
      yearsTraining: 1.2,
      avgSleepHours: 5.6,
      perceivedStress: 'high',
      recoveryQuality: 'low',
      goal: 'glute_priority_low_recovery',
      mappedPrimary: ['glutes'],
      mappedSecondary: ['quads', 'delts_lateral'],
      mappedTertiary: [
        'hamstrings',
        'calves',
        'pectorals',
        'lats',
        'upper_back',
        'biceps',
        'triceps',
      ],
      allowedEquipment: const [
        'dumbbell',
        'barbell',
        'cable',
        'machine',
        'bodyweight',
      ],
      injuryList: const ['fatigue_limited_tolerance'],
      mappingNotes:
          '"Principiante-intermedia" se mapeo a beginner para sesgo conservador. Baja recuperacion se represento en extra: avgSleepHours 5.6, perceivedStress high, recoveryQuality low.',
    ),
  ];
}

Client _buildClientFromCase(_CaseSpec spec) {
  final now = spec.asOfDate;

  final trainingExtra = <String, dynamic>{
    'daysPerWeek': spec.daysPerWeek,
    'trainingDaysPerWeek': spec.daysPerWeek,
    'sessionDurationMinutes': spec.sessionMinutes,
    'sessionDuration': spec.sessionMinutes,
    'trainingYears': spec.yearsTraining,
    'heightCm': spec.heightCm,
    'weightKg': spec.weightKg,
    'ageYears': spec.age,
    'level': spec.trainingLevel.name,
    'goal': 'hypertrophy',
    'phase': spec.phase,
    'planDurationInWeeks': 4,
    'priorityMusclesPrimary': spec.mappedPrimary.join(','),
    'priorityMusclesSecondary': spec.mappedSecondary.join(','),
    'priorityMusclesTertiary': spec.mappedTertiary.join(','),
    'availableEquipment':
        spec.allowedEquipment ??
        ['barbell', 'dumbbell', 'cable', 'machine', 'bench', 'bodyweight'],
    'injuries': spec.injuryList,
    'avgSleepHours': spec.avgSleepHours,
    'perceivedStress': spec.perceivedStress,
    'recoveryQuality': spec.recoveryQuality,
    'seriesTypePercentSplit': const {'heavy': 20, 'medium': 60, 'light': 20},
  };

  return Client(
    id: spec.id,
    profile: ClientProfile(
      id: spec.id,
      fullName: spec.fullName,
      email: '${spec.id}@audit.local',
      phone: '0000000000',
      birthDate: DateTime(spec.asOfDate.year - spec.age, 1, 1),
      age: spec.age,
      gender: spec.gender,
      country: 'MX',
      occupation: 'audit',
      objective: spec.goal,
    ),
    history: const ClinicalHistory(),
    training: TrainingProfile(
      id: 'tp_${spec.id}',
      date: now,
      gender: spec.gender,
      age: spec.age,
      bodyWeight: spec.weightKg,
      globalGoal: TrainingGoal.hypertrophy,
      trainingLevel: spec.trainingLevel,
      daysPerWeek: spec.daysPerWeek,
      timePerSessionMinutes: spec.sessionMinutes,
      yearsTrainingContinuous: spec.yearsTraining.round(),
      sessionDurationMinutes: spec.sessionMinutes,
      avgSleepHours: spec.avgSleepHours,
      equipment: (trainingExtra['availableEquipment'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      priorityMusclesPrimary: spec.mappedPrimary,
      priorityMusclesSecondary: spec.mappedSecondary,
      priorityMusclesTertiary: spec.mappedTertiary,
      baseVolumePerMuscle: {
        for (final m in [
          ...spec.mappedPrimary,
          ...spec.mappedSecondary,
          ...spec.mappedTertiary,
        ])
          m: spec.mappedPrimary.contains(m)
              ? 18
              : spec.mappedSecondary.contains(m)
              ? 12
              : 8,
      },
      extra: trainingExtra,
    ),
    nutrition: const NutritionSettings(weeklyMacroSettings: {}),
    createdAt: now,
    updatedAt: now,
  );
}

Map<String, dynamic> _buildInputPayload(
  _CaseSpec spec,
  Client client,
  int exercisesProvided,
) {
  return {
    'caseId': spec.id,
    'asOfDate': spec.asOfDate.toIso8601String(),
    'phase': spec.phase,
    'client.id': client.id,
    'profile.age': client.profile.age,
    'profile.gender': client.profile.gender?.name,
    'training.trainingLevel': client.training.trainingLevel?.name,
    'training.daysPerWeek': client.training.daysPerWeek,
    'training.timePerSessionMinutes': client.training.timePerSessionMinutes,
    'training.extra': client.training.extra,
    'exercisesProvided': exercisesProvided,
  };
}

List<Exercise> _loadExercisesFromCatalog(String catalogPath) {
  final file = File(catalogPath);
  if (!file.existsSync()) {
    throw StateError('Catalog file not found: $catalogPath');
  }
  final raw = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final list = (raw['exercises'] as List<dynamic>? ?? const []);
  final out = <Exercise>[];
  for (final item in list) {
    if (item is Map<String, dynamic>) {
      out.add(Exercise.fromMap(item));
    }
  }
  return out;
}

List<Exercise> _filterExercisesByEquipment(
  List<Exercise> source,
  List<String> allowed,
) {
  final allow = allowed.map((e) => e.toLowerCase()).toSet();
  final out = source.where((e) {
    final eq = e.equipment.toLowerCase().trim();
    if (eq.isEmpty) return true;
    if (allow.contains(eq)) return true;
    if (eq.contains('body') && allow.contains('bodyweight')) return true;
    if (eq.contains('cable') && allow.contains('cable')) return true;
    if (eq.contains('dumb') && allow.contains('dumbbell')) return true;
    if (eq.contains('barbell') && allow.contains('barbell')) return true;
    if (eq.contains('bench') && allow.contains('bench')) return true;
    return false;
  }).toList();

  if (out.isEmpty) {
    return source;
  }
  return out;
}

String _computeFrequencyLabel(TrainingPlanConfig? plan) {
  if (plan == null || plan.weeks.isEmpty) return 'n/a';
  final week = plan.weeks.first;
  final daysByMuscle = <String, Set<int>>{};
  for (final session in week.sessions) {
    for (final ex in session.exercises) {
      final key = ex.muscleGroup.name;
      daysByMuscle.putIfAbsent(key, () => <int>{}).add(session.dayNumber);
    }
  }
  final parts = daysByMuscle.entries
      .take(6)
      .map((e) => '${e.key}:f${e.value.length}')
      .toList();
  return parts.isEmpty ? 'n/a' : parts.join(' | ');
}

String _inferZoneFromRepRange(int min, int max) {
  if (min >= 6 && max <= 8) return 'heavy';
  if (min >= 8 && max <= 12) return 'medium';
  if (min >= 15 && max <= 20) return 'light';
  return 'unknown';
}

void _printConsoleSummary(_CaseSummary summary) {
  final forensicText = summary.forensicValid == null
      ? 'n/a'
      : (summary.forensicValid! ? 'ok' : 'fail');
  // ignore: avoid_print
  print(
    '[CASE_SUMMARY] ${summary.id} | type=${summary.caseType} | generated=${summary.generated} | forensic=$forensicText | split=${summary.split ?? 'n/a'} | blocking=${summary.blockingCount} | warnings=${summary.warningCount}',
  );
}

String _buildCaseMarkdown({
  required _CaseSpec spec,
  required Map<String, dynamic> inputPayload,
  required dynamic result,
  required TrainingPlanConfig? plan,
  required TrainingPlanForensicValidationResult? forensic,
}) {
  final generated = !result.isBlocked && plan != null;
  final safeInputPayload = _toJsonSafe(inputPayload);
  final preCalcBuffer = StringBuffer();

  if (plan != null) {
    preCalcBuffer.writeln('- split elegido: ${plan.splitId}');
    preCalcBuffer.writeln('- phase: ${plan.phase.name}');
    preCalcBuffer.writeln(
      '- microcycleLengthInWeeks: ${plan.microcycleLengthInWeeks}',
    );
    preCalcBuffer.writeln(
      '- volumePerMuscle: ${_safeJsonEncode(plan.volumePerMuscle ?? const {})}',
    );
    preCalcBuffer.writeln(
      '- frecuencia observada (sample): ${_computeFrequencyLabel(plan)}',
    );
  } else {
    preCalcBuffer.writeln('- plan no generado');
  }

  final planBuffer = StringBuffer();
  if (plan != null) {
    for (final week in plan.weeks) {
      planBuffer.writeln('## Semana ${week.weekNumber} (${week.phase.name})');
      for (final session in week.sessions) {
        planBuffer.writeln(
          '- Dia/Sesion ${session.dayNumber}: ${session.sessionName}',
        );
        for (final ex in session.exercises) {
          final zone = _inferZoneFromRepRange(ex.repRange.min, ex.repRange.max);
          planBuffer.writeln(
            '  - slot: ${ex.slotLabel ?? '-'} | musculo: ${ex.muscleGroup.name} | ejercicio: ${ex.exerciseName} (${ex.exerciseCode}) | zona: $zone | reps: ${ex.repRange.min}-${ex.repRange.max} | sets: ${ex.sets} | pairing: ${ex.supersetGroup ?? '-'}',
          );
        }
      }
    }
  } else {
    planBuffer.writeln('- No se genero plan.');
  }

  final forensicBuffer = StringBuffer();
  if (forensic != null) {
    forensicBuffer.writeln('- isValid: ${forensic.isValid}');
    forensicBuffer.writeln(
      '- blockingErrors: ${_safeJsonEncode(forensic.blockingErrors)}',
    );
    forensicBuffer.writeln('- warnings: ${_safeJsonEncode(forensic.warnings)}');
    forensicBuffer.writeln('- diagnostics relevantes:');
    forensicBuffer.writeln(
      '  - totals: ${_safeJsonEncode(forensic.diagnostics['totals'])}',
    );
    forensicBuffer.writeln(
      '  - weeklyFrequencyByMuscle: ${_safeJsonEncode(forensic.diagnostics['weeklyFrequencyByMuscle'])}',
    );
    forensicBuffer.writeln(
      '  - weeklySetsByMuscle: ${_safeJsonEncode(forensic.diagnostics['weeklySetsByMuscle'])}',
    );
  } else {
    forensicBuffer.writeln('- isValid: false');
    forensicBuffer.writeln(
      '- blockingErrors: ${_safeJsonEncode([result.blockReason ?? 'plan_blocked'])}',
    );
    forensicBuffer.writeln(
      '- warnings: ${_safeJsonEncode(result.suggestions ?? const [])}',
    );
    forensicBuffer.writeln('- diagnostics relevantes: {}');
  }

  final findings = StringBuffer()
    ..writeln(
      '- que salio bien: ${generated ? 'pipeline real ejecuto y devolvio plan.' : 'se detecto bloqueo en pipeline real.'}',
    )
    ..writeln(
      '- que salio raro: ${result.isBlocked ? result.blockReason : 'sin bloqueo estructural en generacion.'}',
    )
    ..writeln(
      '- si hubo fallback: revisar warnings forenses y logs del motor en ejecucion.',
    )
    ..writeln(
      '- comportamiento inesperado: ${forensic != null && !forensic.isValid ? 'validacion forense rechazo estructura generada.' : 'sin rechazo forense.'}',
    );

  return '''# Caso
- nombre del caso: ${spec.title}
- objetivo del caso: ${spec.objective}
- tipo: ${spec.caseType}

# Input de entrevista
- llaves reales usadas por el motor (payload final):
```json
${const JsonEncoder.withIndent('  ').convert(safeInputPayload)}
```
- mapeo negocio -> campos reales:
  - ${spec.mappingNotes}

# Suposiciones tecnicas minimas
- valores necesarios por contrato del modelo: age, gender, daysPerWeek, sessionDurationMinutes, level, goal, prioridades, equipo.
- fuente: Client.training + Client.training.extra consumido por TrainingOrchestratorV3._convertClientToUserProfile.
- defaults usados del codigo: split/intensity default cuando no se fuerza explicitamente.

# Ruta de ejecucion usada
- metodo exacto invocado: TrainingOrchestratorV3.generatePlan(...)
- cadena real: training_plan_provider.generatePlanFromActiveCycle -> unified service -> training_orchestrator_v3.generatePlan -> motor_v3_orchestrator.generateProgram -> cycle_template_builder -> training_plan_forensic_validator
- archivos relevantes:
  - lib/features/training_feature/providers/training_plan_provider.dart
  - lib/domain/training_v3/services/unified_training_service.dart
  - lib/domain/training_v3/orchestrator/training_orchestrator_v3.dart
  - lib/domain/training_v3/services/motor_v3_orchestrator.dart
  - lib/domain/training_v3/services/cycle_template_builder.dart
  - lib/domain/training_v3/validators/training_plan_forensic_validator.dart

# Resultado del calculo previo
${preCalcBuffer.toString()}

# Plan generado
${planBuffer.toString()}

# Validacion forense
${forensicBuffer.toString()}

# Hallazgos del caso
${findings.toString()}

# JSON crudo o payload serializado
```json
${const JsonEncoder.withIndent('  ').convert(safeInputPayload)}
```
''';
}

String _safeJsonEncode(dynamic value) {
  return jsonEncode(_toJsonSafe(value));
}

dynamic _toJsonSafe(dynamic value) {
  if (value == null || value is String || value is num || value is bool) {
    return value;
  }

  if (value is DateTime) {
    return value.toIso8601String();
  }

  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), _toJsonSafe(v)));
  }

  if (value is Iterable) {
    return value.map(_toJsonSafe).toList(growable: false);
  }

  return value.toString();
}

String _buildIndexSummaryMarkdown(List<_CaseSummary> summaries) {
  final table = StringBuffer()
    ..writeln('# Index Summary - Motor V3 Generated Cases')
    ..writeln('')
    ..writeln(
      '| Caso | Tipo | ¿Genero plan? | ¿Validacion forense aprobo? | Split resultante | Musculos primarios | Frecuencia relevante | Errores bloqueantes | Warnings | Observacion corta |',
    )
    ..writeln('| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |');

  for (final s in summaries) {
    final forensic = s.forensicValid == null
        ? 'n/a'
        : (s.forensicValid! ? 'si' : 'no');
    table.writeln(
      '| ${s.title} | ${s.caseType} | ${s.generated ? 'si' : 'no'} | $forensic | ${s.split ?? 'n/a'} | ${s.primaryMuscles.join(', ')} | ${s.frequency} | ${s.blockingCount} | ${s.warningCount} | ${s.note.replaceAll('|', '/')} |',
    );
  }

  table
    ..writeln('')
    ..writeln('## Notas de ruta legacy detectadas')
    ..writeln(
      '- Se detecta ruta legacy interna en motor_v3_orchestrator._buildSessions con ExerciseSelectionEngine.selectExercises (no usada como entrypoint principal de app).',
    )
    ..writeln(
      '- Para esta auditoria se uso la ruta principal actual conectada por training_plan_provider -> unified service -> training_orchestrator_v3 -> motor_v3_orchestrator.',
    );

  return table.toString();
}
