// test/domain/training_v3/integration_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/training_v3/models/user_profile.dart';
import 'package:hcs_app_lap/domain/training_v3/services/motor_v3_orchestrator.dart';

/// Test de integración completo del Motor V3
///
/// Valida el pipeline end-to-end:
/// 1. UserProfile → generateProgram → TrainingProgram
/// 2. Validaciones científicas aplicadas
/// 3. Programa generado es coherente
void main() {
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
        musclePriorities: {
          'chest': 5,
          'back': 5,
          'quads': 4,
          'hamstrings': 3,
          'shoulders': 4,
          'biceps': 3,
          'triceps': 3,
        },
        injuryHistory: {},
        availableEquipment: ['barbell', 'dumbbell', 'machine', 'bench', 'rack'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // WHEN: Generar programa
      final result = await MotorV3Orchestrator.generateProgram(
        userProfile: userProfile,
        phase: 'accumulation',
        durationWeeks: 4,
      );

      // THEN: Debe ser exitoso
      expect(result['success'], isTrue);
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
        musclePriorities: {},
        injuryHistory: {},
        availableEquipment: [],
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
        availableDays: 6,
        sessionDuration: 60,
        primaryGoal: 'hypertrophy',
        musclePriorities: {
          'chest': 5,
          'back': 5,
          'quads': 5,
          'hamstrings': 4,
          'shoulders': 5,
        },
        injuryHistory: {},
        availableEquipment: ['barbell', 'dumbbell'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = await MotorV3Orchestrator.generateProgram(
        userProfile: userProfile,
        phase: 'accumulation',
        durationWeeks: 4,
      );

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
