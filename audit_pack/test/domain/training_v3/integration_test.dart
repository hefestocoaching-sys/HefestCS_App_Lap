// test/domain/training_v3/integration_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/domain/training_v3/models/user_profile.dart';
import 'package:hcs_app_lap/domain/training_v3/services/motor_v3_orchestrator.dart';

/// Test de integración completo del Motor V3
///
/// Valida el pipeline end-to-end:
/// 1. UserProfile → generateProgram → TrainingProgram
/// 2. Validaciones científicas aplicadas
/// 3. Programa generado es coherente
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Motor V3 Integration Test', () {
    test('debe generar programa completo desde perfil de usuario', () async {
      // GIVEN: Usuario novice con 4 días disponibles
      final userProfile = UserProfile(
        id: 'test_user',
        name: 'Test User',
        email: 'test@example.com',
        age: 25,
        gender: 'male',
        heightCm: 175,
        weightKg: 75,
        trainingLevel: 'novice',
        yearsTraining: 1,
        availableDays: 4,
        sessionDuration: 60,
        primaryGoal: 'hypertrophy',
        musclePriorities: const {
          'chest': 5,
          'lats': 5,
          'upper_back': 5,
          'traps': 3,
          'quads': 4,
          'hamstrings': 3,
          'deltoide_lateral': 4,
          'deltoide_anterior': 3,
          'biceps': 3,
          'triceps': 3,
        },
        availableEquipment: const [
          'barbell',
          'dumbbell',
          'machine',
          'bench',
          'rack',
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // WHEN: Generar programa
      final result = await MotorV3Orchestrator.generateProgram(
        userProfile: userProfile,
        phase: 'accumulation',
        durationWeeks: 4,
        exercises: _getMockExercises(),
      );

      // THEN: Debe ser exitoso
      expect(result['success'], isTrue, reason: 'Errores: ${result['errors']}');
      expect(result['program'], isNotNull);
      expect(result['errors'], isEmpty);

      final program = result['program'];

      // Validar split correcto (4 días → Upper/Lower)
      expect(program.split.daysPerWeek, equals(4));
      expect(program.split.type, equals('upper_lower'));

      // Validar volumen calculado
      expect(program.weeklyVolumeByMuscle, isNotEmpty);
      expect(program.weeklyVolumeByMuscle['chest'], greaterThan(0));
    });

    test('debe retornar errores si perfil es inválido', () async {
      // GIVEN: Perfil inválido (días = 0)
      final invalidProfile = UserProfile(
        id: 'test_user',
        name: 'Test User',
        email: 'test@example.com',
        age: 25,
        gender: 'male',
        heightCm: 175,
        weightKg: 75,
        trainingLevel: 'novice',
        yearsTraining: 1,
        availableDays: 0, // INVÁLIDO
        sessionDuration: 60,
        primaryGoal: 'hypertrophy',
        musclePriorities: const {},
        availableEquipment: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // WHEN/THEN: Debe lanzar error
      expect(
        () async => await MotorV3Orchestrator.generateProgram(
          userProfile: invalidProfile,
          phase: 'accumulation',
          durationWeeks: 4,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('debe calcular quality score del programa', () async {
      final userProfile = UserProfile(
        id: 'test_user',
        name: 'Test User',
        email: 'test@example.com',
        age: 25,
        gender: 'male',
        heightCm: 175,
        weightKg: 75,
        trainingLevel: 'intermediate',
        yearsTraining: 3,
        availableDays: 4,
        sessionDuration: 60,
        primaryGoal: 'hypertrophy',
        musclePriorities: const {
          'chest': 5,
          'lats': 5,
          'upper_back': 5,
          'traps': 3,
          'quads': 5,
          'hamstrings': 4,
          'deltoide_lateral': 5,
          'deltoide_anterior': 4,
        },
        availableEquipment: const ['barbell', 'dumbbell'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = await MotorV3Orchestrator.generateProgram(
        userProfile: userProfile,
        phase: 'accumulation',
        durationWeeks: 4,
        exercises: _getMockExercises(),
      );

      expect(result['success'], isTrue, reason: 'Errores: ${result['errors']}');
      expect(result['program'], isNotNull);

      final program = result['program'];
      final quality = MotorV3Orchestrator.calculateProgramQuality(
        program: program,
        profile: userProfile,
      );

      expect(quality['overall_score'], isA<double>());
      expect(quality['overall_score'], greaterThanOrEqualTo(0.0));
      expect(quality['overall_score'], lessThanOrEqualTo(1.0));
      expect(quality['quality_level'], isA<String>());
    });
  });
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
      muscleKey: 'traps_upper',
      primaryMuscles: ['traps_upper'],
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
      muscleKey: 'gastrocnemio',
      primaryMuscles: ['gastrocnemio'],
      secondaryMuscles: [],
      equipment: 'machine',
      difficulty: 'beginner',
    ),
    Exercise(
      id: 'seated_calf_raise',
      externalId: 'ext_seated_calf_raise',
      name: 'Seated Calf Raise',
      muscleKey: 'soleo',
      primaryMuscles: ['soleo'],
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
