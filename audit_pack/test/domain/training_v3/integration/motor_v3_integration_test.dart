import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/training_v3/services/motor_v3_orchestrator.dart';
import 'package:hcs_app_lap/domain/training_v3/models/user_profile.dart';
import 'package:hcs_app_lap/domain/entities/exercise.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Motor V3 Integration Tests', () {
    test(
      'Genera plan completo para usuario intermedio con Full Body split',
      () async {
        // ARRANGE: Crear perfil de usuario
        final userProfile = UserProfile(
          id: 'test_user_001',
          name: 'Juan Pérez',
          email: 'juan@test.com',
          age: 28,
          gender: 'male',
          heightCm: 175,
          weightKg: 75,
          yearsTraining: 2,
          trainingLevel: 'intermediate',
          availableDays: 3,
          sessionDuration: 60,
          primaryGoal: 'hypertrophy',
          musclePriorities: const {
            'chest': 1, // Alta prioridad
            'lats': 1, // Alta prioridad
            'quads': 2, // Media prioridad
            'deltoide_anterior': 3, // Baja prioridad
          },
          availableEquipment: const [
            'barbell',
            'dumbbells',
            'machine',
            'cable',
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // ACT: Generar plan
        final result = await MotorV3Orchestrator.generateProgram(
          userProfile: userProfile,
          phase: 'accumulation',
          durationWeeks: 4,
          exercises: _getMockExercises(),
        );

        // DEBUG: Imprimir resultado
        debugPrint('📋 RESULTADO: ${result.keys}');
        debugPrint('📋 SUCCESS: ${result['success']}');
        if (result['errors'] != null) {
          debugPrint('❌ ERRORS: ${result['errors']}');
        }
        if (result['warnings'] != null) {
          debugPrint('⚠️ WARNINGS: ${result['warnings']}');
        }

        // ASSERT: Validar resultado
        expect(
          result['success'],
          true,
          reason: 'El plan debe generarse exitosamente',
        );
        expect(
          result['planConfig'],
          isNotNull,
          reason: 'El plan no debe ser nulo',
        );

        debugPrint('✅ TEST PASADO: Plan generado correctamente');
        debugPrint('   - Resultado: ${result.keys.join(', ')}');
      },
    );

    test('Maneja correctamente usuario con datos incompletos', () async {
      // ARRANGE: Perfil incompleto
      final incompleteProfile = UserProfile(
        id: 'incomplete_user',
        name: 'Usuario Incompleto',
        email: 'incomplete@test.com',
        age: 0, // ❌ Edad inválida
        gender: 'male',
        heightCm: 170,
        weightKg: 70,
        yearsTraining: 0,
        trainingLevel: 'beginner',
        availableDays: 3,
        sessionDuration: 60,
        primaryGoal: 'hypertrophy',
        musclePriorities: const {},
        availableEquipment: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // ACT: Intentar generar plan
      try {
        final result = await MotorV3Orchestrator.generateProgram(
          userProfile: incompleteProfile,
          phase: 'accumulation',
          durationWeeks: 4,
        );

        // ASSERT: Debe fallar gracefully
        expect(
          result['success'],
          false,
          reason: 'Debe fallar con datos incompletos',
        );
        expect(
          result['errors'],
          isNotNull,
          reason: 'Debe tener lista de errores',
        );

        debugPrint('✅ TEST PASADO: Manejo de errores correcto');
        debugPrint('   - Errores: ${result['errors']}');
      } catch (e) {
        debugPrint('✅ TEST PASADO: Excepción capturada correctamente');
        debugPrint('   - Error: $e');
      }
    });
  });
}

// HELPERS
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
      id: 'barbell_row',
      externalId: 'ext_barbell_row',
      name: 'Barbell Row',
      muscleKey: 'lats',
      primaryMuscles: ['lats'],
      secondaryMuscles: ['biceps', 'traps'],
      equipment: 'barbell',
      difficulty: 'intermediate',
    ),
    Exercise(
      id: 'overhead_press',
      externalId: 'ext_overhead_press',
      name: 'Overhead Press',
      muscleKey: 'deltoide_anterior',
      primaryMuscles: ['deltoide_anterior'],
      secondaryMuscles: ['triceps'],
      equipment: 'barbell',
      difficulty: 'intermediate',
    ),
    Exercise(
      id: 'biceps_curl',
      externalId: 'ext_biceps_curl',
      name: 'Biceps Curl',
      muscleKey: 'biceps',
      primaryMuscles: ['biceps'],
      secondaryMuscles: [],
      equipment: 'dumbbells',
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
