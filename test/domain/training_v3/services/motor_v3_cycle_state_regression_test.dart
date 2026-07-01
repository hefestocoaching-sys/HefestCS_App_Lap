// ignore_for_file: avoid_redundant_argument_values, unused_element_parameter

import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_plan_config.dart';
import 'package:hcs_app_lap/domain/training_v3/models/user_profile.dart';
import 'package:hcs_app_lap/domain/training_v3/services/motor_v3_orchestrator.dart';
import 'package:hcs_app_lap/domain/training_v3/data/exercise_catalog_v3.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  ExerciseCatalogV3.loadFromExercises(_exercises());
  _primeTestCatalogMetadata();
  group('MotorV3Orchestrator cycle-state regression', () {
    test(
      'prioriza activePlanId sobre plan mas reciente para heredar estado',
      () async {
        final activePlan = _FakePlan(
          id: 'plan_active',
          clientId: 'client_1',
          startDate: DateTime(2026, 1, 1),
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 2),
          phase: 'accumulation',
          split: 'upperLower',
          extra: {
            'cycleWeek': 2,
            'cyclePhase': 'accumulation',
            'weeksInPhase': 1,
            'carry_marker': 'from_active',
          },
        );

        final newerPlan = _FakePlan(
          id: 'plan_newer',
          clientId: 'client_1',
          startDate: DateTime(2026, 2, 1),
          createdAt: DateTime(2026, 2, 1),
          updatedAt: DateTime(2026, 2, 2),
          phase: 'accumulation',
          split: 'upperLower',
          extra: {
            'cycleWeek': 4,
            'cyclePhase': 'maintenance',
            'weeksInPhase': 2,
            'carry_marker': 'from_latest',
          },
        );

        final client = _FakeClient(
          id: 'client_1',
          training: _FakeTraining(extra: {'activePlanId': 'plan_active'}),
          trainingPlans: [activePlan, newerPlan],
        );

        final result = await MotorV3Orchestrator.generateProgram(
          userProfile: _profile(),
          phase: 'accumulation',
          durationWeeks: 2,
          client: client,
          exercises: _exercises(),
        );

        expect(
          result['success'],
          isTrue,
          reason: 'errors: ${result['errors']}',
        );

        final planConfig = result['planConfig'] as TrainingPlanConfig;
        expect(planConfig.extra['carry_marker'], equals('from_active'));
      },
    );

    test(
      'en 4 semanas ejecuta pipeline reactivo y consume pendingLocalDeload',
      () async {
        final activePlan = _FakePlan(
          id: 'plan_active',
          clientId: 'client_2',
          startDate: DateTime(2026, 1, 1),
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 2),
          phase: 'accumulation',
          split: 'upperLower',
          extra: {
            'cycleWeek': 2,
            'cyclePhase': 'accumulation',
            'weeksInPhase': 1,
            'pendingLocalDeload': {'pectorals': true},
          },
        );

        final client = _FakeClient(
          id: 'client_2',
          training: _FakeTraining(extra: {'activePlanId': 'plan_active'}),
          trainingPlans: [activePlan],
        );

        final result = await MotorV3Orchestrator.generateProgram(
          userProfile: _profile(id: 'u2'),
          phase: 'accumulation',
          durationWeeks: 2,
          client: client,
          exercises: _exercises(),
        );

        expect(
          result['success'],
          isTrue,
          reason: 'errors: ${result['errors']}',
        );

        final planConfig = result['planConfig'] as TrainingPlanConfig;
        final pending = Map<String, dynamic>.from(
          (planConfig.extra['pendingLocalDeload'] as Map?) ??
              const <String, dynamic>{},
        );
        expect(pending['pectorals'], isFalse);
      },
    );
  });
}

UserProfile _profile({String id = 'u1'}) {
  final now = DateTime.now();
  return UserProfile(
    id: id,
    name: 'Test User',
    email: 'test@example.com',
    age: 30,
    gender: 'male',
    heightCm: 175,
    weightKg: 80,
    yearsTraining: 0,
    trainingLevel: 'novice',
    availableDays: 3,
    sessionDuration: 60,
    primaryGoal: 'hypertrophy',
    musclePriorities: const {
      'pectorals': 3,
      'lats': 2,
      'quads': 2,
      'hamstrings': 1,
      'delts_lateral': 1,
      'triceps': 1,
      'biceps': 1,
      'calves': 1,
    },
    availableEquipment: const ['barbell', 'dumbbell', 'cable', 'machine'],
    createdAt: now,
    updatedAt: now,
  );
}

List<Exercise> _exercises() {
  const allZones = <String, bool>{'heavy': true, 'medium': true, 'light': true};
  return [
    Exercise(
      id: 'bench_press',
      externalId: 'ext_bench_press',
      name: 'Bench Press',
      muscleKey: 'chest',
      primaryMuscles: const ['chest'],
      secondaryMuscles: const ['triceps'],
      equipment: 'barbell',
      difficulty: 'intermediate',
      movementPattern: 'horizontal_push',
      allowedIntensityZones: allZones,
    ),
    Exercise(
      id: 'incline_press',
      externalId: 'ext_incline_press',
      name: 'Incline Press',
      muscleKey: 'chest',
      primaryMuscles: const ['chest'],
      secondaryMuscles: const ['triceps'],
      equipment: 'dumbbell',
      difficulty: 'intermediate',
      movementPattern: 'horizontal_push',
      allowedIntensityZones: allZones,
    ),
    Exercise(
      id: 'lat_pulldown',
      externalId: 'ext_lat_pulldown',
      name: 'Lat Pulldown',
      muscleKey: 'lats',
      primaryMuscles: const ['lats'],
      secondaryMuscles: const ['biceps'],
      equipment: 'cable',
      difficulty: 'beginner',
      movementPattern: 'vertical_pull',
      allowedIntensityZones: allZones,
    ),
    Exercise(
      id: 'lat_row_chest_supported',
      externalId: 'ext_lat_row_chest_supported',
      name: 'Lat Row Chest Supported',
      muscleKey: 'lats',
      primaryMuscles: const ['lats'],
      secondaryMuscles: const ['biceps'],
      equipment: 'machine',
      difficulty: 'intermediate',
      movementPattern: 'horizontal_pull',
      allowedIntensityZones: allZones,
      equivalenceGroup: 'lat_row_chest_supported',
    ),
    Exercise(
      id: 'row',
      externalId: 'ext_row',
      name: 'Row',
      muscleKey: 'upper_back',
      primaryMuscles: const ['upper_back'],
      secondaryMuscles: const ['biceps'],
      equipment: 'cable',
      difficulty: 'beginner',
      movementPattern: 'horizontal_pull',
      allowedIntensityZones: allZones,
    ),
    Exercise(
      id: 'upper_back_row_machine',
      externalId: 'ext_upper_back_row_machine',
      name: 'Upper Back Row Machine',
      muscleKey: 'upper_back',
      primaryMuscles: const ['upper_back'],
      secondaryMuscles: const ['biceps'],
      equipment: 'machine',
      difficulty: 'intermediate',
      movementPattern: 'horizontal_pull',
      allowedIntensityZones: allZones,
      equivalenceGroup: 'upper_back_row_machine',
    ),
    Exercise(
      id: 'squat',
      externalId: 'ext_squat',
      name: 'Squat',
      muscleKey: 'quads',
      primaryMuscles: const ['quads'],
      secondaryMuscles: const ['glutes'],
      equipment: 'barbell',
      difficulty: 'intermediate',
      movementPattern: 'squat',
      allowedIntensityZones: allZones,
    ),
    Exercise(
      id: 'quad_extension_machine',
      externalId: 'ext_quad_extension_machine',
      name: 'Quad Extension Machine',
      muscleKey: 'quads',
      primaryMuscles: const ['quads'],
      secondaryMuscles: const [],
      equipment: 'machine',
      difficulty: 'intermediate',
      movementPattern: 'knee_extension',
      allowedIntensityZones: allZones,
      equivalenceGroup: 'quad_extension_machine',
    ),
    Exercise(
      id: 'leg_curl',
      externalId: 'ext_leg_curl',
      name: 'Leg Curl',
      muscleKey: 'hamstrings',
      primaryMuscles: const ['hamstrings'],
      secondaryMuscles: const [],
      equipment: 'machine',
      difficulty: 'beginner',
      movementPattern: 'knee_flexion',
      allowedIntensityZones: allZones,
    ),
    Exercise(
      id: 'lateral_raise',
      externalId: 'ext_lateral_raise',
      name: 'Lateral Raise',
      muscleKey: 'delts_lateral',
      primaryMuscles: const ['delts_lateral'],
      secondaryMuscles: const [],
      equipment: 'dumbbell',
      difficulty: 'beginner',
      movementPattern: 'lateral_raise',
      allowedIntensityZones: allZones,
    ),
    Exercise(
      id: 'front_raise',
      externalId: 'ext_front_raise',
      name: 'Front Raise',
      muscleKey: 'delts_front',
      primaryMuscles: const ['delts_front'],
      secondaryMuscles: const [],
      equipment: 'dumbbell',
      difficulty: 'beginner',
      movementPattern: 'front_raise',
      allowedIntensityZones: allZones,
    ),
    Exercise(
      id: 'rear_delt_fly',
      externalId: 'ext_rear_delt_fly',
      name: 'Rear Delt Fly',
      muscleKey: 'delts_rear',
      primaryMuscles: const ['delts_rear'],
      secondaryMuscles: const [],
      equipment: 'cable',
      difficulty: 'beginner',
      movementPattern: 'rear_raise',
      allowedIntensityZones: allZones,
    ),
    Exercise(
      id: 'shrug',
      externalId: 'ext_shrug',
      name: 'Shrug',
      muscleKey: 'traps',
      primaryMuscles: const ['traps'],
      secondaryMuscles: const [],
      equipment: 'dumbbell',
      difficulty: 'beginner',
      movementPattern: 'shrug',
      allowedIntensityZones: allZones,
    ),
    Exercise(
      id: 'traps_shrug_cable',
      externalId: 'ext_traps_shrug_cable',
      name: 'Traps Shrug Cable',
      muscleKey: 'traps',
      primaryMuscles: const ['traps'],
      secondaryMuscles: const [],
      equipment: 'cable',
      difficulty: 'beginner',
      movementPattern: 'shrug',
      allowedIntensityZones: allZones,
      equivalenceGroup: 'traps_shrug_cable',
    ),
    Exercise(
      id: 'triceps_extension',
      externalId: 'ext_triceps_extension',
      name: 'Triceps Extension',
      muscleKey: 'triceps',
      primaryMuscles: const ['triceps'],
      secondaryMuscles: const [],
      equipment: 'cable',
      difficulty: 'beginner',
      movementPattern: 'pushdown',
      allowedIntensityZones: allZones,
    ),
    Exercise(
      id: 'triceps_pushdown_cable',
      externalId: 'ext_triceps_pushdown_cable',
      name: 'Triceps Pushdown Cable',
      muscleKey: 'triceps',
      primaryMuscles: const ['triceps'],
      secondaryMuscles: const [],
      equipment: 'cable',
      difficulty: 'beginner',
      movementPattern: 'pushdown',
      allowedIntensityZones: allZones,
      equivalenceGroup: 'triceps_pushdown_cable',
    ),
    Exercise(
      id: 'biceps_curl',
      externalId: 'ext_biceps_curl',
      name: 'Biceps Curl',
      muscleKey: 'biceps',
      primaryMuscles: const ['biceps'],
      secondaryMuscles: const [],
      equipment: 'dumbbell',
      difficulty: 'beginner',
      movementPattern: 'curl',
      allowedIntensityZones: allZones,
      equivalenceGroup: 'biceps_curl_dumbbell',
    ),
    Exercise(
      id: 'biceps_curl_cable',
      externalId: 'ext_biceps_curl_cable',
      name: 'Biceps Curl Cable',
      muscleKey: 'biceps',
      primaryMuscles: const ['biceps'],
      secondaryMuscles: const [],
      equipment: 'cable',
      difficulty: 'beginner',
      movementPattern: 'curl',
      allowedIntensityZones: allZones,
      equivalenceGroup: 'biceps_curl_cable',
    ),
    Exercise(
      id: 'hamstrings_curl_seated',
      externalId: 'ext_hamstrings_curl_seated',
      name: 'Hamstrings Curl Seated',
      muscleKey: 'hamstrings',
      primaryMuscles: const ['hamstrings'],
      secondaryMuscles: const [],
      equipment: 'machine',
      difficulty: 'beginner',
      movementPattern: 'knee_flexion',
      allowedIntensityZones: allZones,
      equivalenceGroup: 'hamstrings_curl_seated',
    ),
    Exercise(
      id: 'delts_lateral_raise_cable',
      externalId: 'ext_delts_lateral_raise_cable',
      name: 'Delts Lateral Raise Cable',
      muscleKey: 'delts_lateral',
      primaryMuscles: const ['delts_lateral'],
      secondaryMuscles: const [],
      equipment: 'cable',
      difficulty: 'beginner',
      movementPattern: 'lateral_raise',
      allowedIntensityZones: allZones,
      equivalenceGroup: 'delts_lateral_raise_cable',
    ),
    Exercise(
      id: 'delts_rear_fly_dumbbell',
      externalId: 'ext_delts_rear_fly_dumbbell',
      name: 'Delts Rear Fly Dumbbell',
      muscleKey: 'delts_rear',
      primaryMuscles: const ['delts_rear'],
      secondaryMuscles: const [],
      equipment: 'dumbbell',
      difficulty: 'beginner',
      movementPattern: 'rear_raise',
      allowedIntensityZones: allZones,
      equivalenceGroup: 'delts_rear_fly_dumbbell',
    ),
    Exercise(
      id: 'standing_calf_raise',
      externalId: 'ext_calf_raise',
      name: 'Standing Calf Raise',
      muscleKey: 'calves',
      primaryMuscles: const ['calves'],
      secondaryMuscles: const [],
      equipment: 'machine',
      difficulty: 'beginner',
      movementPattern: 'ankle_extension',
      allowedIntensityZones: allZones,
    ),
    Exercise(
      id: 'calves_raise_seated',
      externalId: 'ext_calves_raise_seated',
      name: 'Calves Raise Seated',
      muscleKey: 'calves',
      primaryMuscles: const ['calves'],
      secondaryMuscles: const [],
      equipment: 'machine',
      difficulty: 'beginner',
      movementPattern: 'ankle_extension',
      allowedIntensityZones: allZones,
      equivalenceGroup: 'calves_raise_seated',
    ),
    Exercise(
      id: 'crunch',
      externalId: 'ext_crunch',
      name: 'Crunch',
      muscleKey: 'abs',
      primaryMuscles: const ['abs'],
      secondaryMuscles: const [],
      equipment: 'bodyweight',
      difficulty: 'beginner',
      movementPattern: 'trunk_flexion',
      allowedIntensityZones: allZones,
    ),
    Exercise(
      id: 'abs_crunch_cable',
      externalId: 'ext_abs_crunch_cable',
      name: 'Abs Crunch Cable',
      muscleKey: 'abs',
      primaryMuscles: const ['abs'],
      secondaryMuscles: const [],
      equipment: 'cable',
      difficulty: 'beginner',
      movementPattern: 'trunk_flexion',
      allowedIntensityZones: allZones,
      equivalenceGroup: 'abs_crunch_cable',
    ),
  ];
}

void _primeTestCatalogMetadata() {
  const slotRoles = <String>['A', 'B1', 'B2', 'C1', 'C2', 'D1', 'D2'];
  for (final exercise in _exercises()) {
    final metadata = ExerciseCatalogV3.getMetadataById(exercise.id);
    if (metadata == null) continue;
    metadata
      ..['movementPattern'] = exercise.movementPattern
      ..['loadCategory'] = exercise.loadCategory
      ..['fatigueScore'] = exercise.fatigueScore
      ..['stimulusScore'] = exercise.stimulusScore
      ..['allowedIntensityZones'] = exercise.allowedIntensityZones
      ..['equivalenceGroup'] = exercise.equivalenceGroup
      ..['slotRoles'] = slotRoles
      ..['heavyRole'] = 'forbidden'
      ..['aEligibility'] = 'secondary'
      ..['secondaryHeavyEligibility'] = true
      ..['exerciseOrderClass'] = 9
      ..['conflictPatterns'] = const <String>[]
      ..['rotationGroup'] = exercise.equivalenceGroup.isNotEmpty
          ? exercise.equivalenceGroup
          : exercise.id
      ..['angleTag'] = exercise.movementPattern
      ..['variantTier'] = 1
      ..['canPromoteToHeavyNextBlock'] = true
      ..['canDemoteToMediumNextBlock'] = true;
  }
}

class _FakeTraining {
  _FakeTraining({required this.extra});
  final Map<String, dynamic> extra;
}

class _FakePlan {
  _FakePlan({
    required this.id,
    required this.clientId,
    required this.startDate,
    required this.createdAt,
    required this.updatedAt,
    required this.extra,
    this.phase,
    this.split,
    this.splitId,
    this.volumePerMuscle,
    this.state,
  });

  final String id;
  final String clientId;
  final DateTime startDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> extra;
  final String? phase;
  final String? split;
  final String? splitId;
  final Map<String, int>? volumePerMuscle;
  final Map<String, dynamic>? state;
}

class _FakeClient {
  _FakeClient({
    required this.id,
    required this.training,
    required this.trainingPlans,
    this.activeCycleId,
    this.trainingCycles = const [],
  });

  final String id;
  final _FakeTraining training;
  final List<dynamic> trainingPlans;
  final String? activeCycleId;
  final List<dynamic> trainingCycles;
}
