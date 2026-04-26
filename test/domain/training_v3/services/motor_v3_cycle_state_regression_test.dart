// ignore_for_file: avoid_redundant_argument_values, unused_element_parameter

import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_plan_config.dart';
import 'package:hcs_app_lap/domain/training_v3/models/user_profile.dart';
import 'package:hcs_app_lap/domain/training_v3/services/motor_v3_orchestrator.dart';

void main() {
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
          durationWeeks: 4,
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
          durationWeeks: 4,
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
    yearsTraining: 3,
    trainingLevel: 'intermediate',
    availableDays: 4,
    sessionDuration: 60,
    primaryGoal: 'hypertrophy',
    musclePriorities: const {
      'pectorals': 5,
      'lats': 4,
      'quads': 4,
      'hamstrings': 3,
      'delts_lateral': 3,
      'triceps': 3,
      'biceps': 3,
      'calves': 2,
    },
    availableEquipment: const ['barbell', 'dumbbell', 'cable', 'machine'],
    createdAt: now,
    updatedAt: now,
  );
}

List<Exercise> _exercises() {
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
    ),
    Exercise(
      id: 'hip_thrust',
      externalId: 'ext_hip_thrust',
      name: 'Hip Thrust',
      muscleKey: 'glutes',
      primaryMuscles: const ['glutes'],
      secondaryMuscles: const [],
      equipment: 'barbell',
      difficulty: 'intermediate',
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
    ),
  ];
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
