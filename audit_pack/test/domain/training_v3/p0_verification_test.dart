import 'dart:io';
import 'package:flutter/foundation.dart'; // added
import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/domain/training_v3/models/user_profile.dart';
import 'package:hcs_app_lap/domain/training_v3/services/motor_v3_orchestrator.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_plan_config.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_week.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_session.dart';
import 'package:hcs_app_lap/domain/training_v3/models/client_profile.dart';
import 'package:hcs_app_lap/domain/training_v3/data/exercise_catalog_v3.dart';
import 'package:hcs_app_lap/domain/training_v3/services/cycle_template_builder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Motor V3 P0 Verification', () {
    late UserProfile userProfile;

    setUp(() {
      userProfile = UserProfile(
        id: 'p0_test_user',
        name: 'P0 Tester',
        email: 'test@example.com',
        age: 30,
        gender: 'male',
        heightCm: 180,
        weightKg: 80,
        trainingLevel: 'intermediate',
        yearsTraining: 3,
        availableDays: 4, // Upper/Lower split
        sessionDuration: 60,
        primaryGoal: 'hypertrophy',
        musclePriorities: const {'chest': 5, 'quads': 5},
        availableEquipment: const ['barbell', 'dumbbell', 'machine'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    test('Strict Frozen Exercises: Verify P0 Logic', () async {
      final logFile = File('error_log.txt');
      if (await logFile.exists()) await logFile.delete();

      try {
        // Test 1: Catalog Loading
        debugPrint('Loading Exercises...');
        final exercises = _getMockExercises();
        ExerciseCatalogV3.loadFromExercises(exercises);
        debugPrint('Catalog Loaded. Count: ${exercises.length}');

        // Test 2: CycleTemplateBuilder
        debugPrint('Testing CycleTemplateBuilder...');
        // Correct types: double for recovery/calories
        const clientProfile = ClientProfile(
          age: 30,
          experience: 'intermediate',
          recoveryCapacity: 7.0,
          caloricBalance: 200.0,
          geneticResponse: 1.0,
        );

        final volumeTargets = {
          'chest': 10,
          'quads': 10,
          'deltoids': 10,
          'back': 10,
          'hamstrings': 10,
          'calves': 10,
          'abs': 0,
        };

        final mesocyclePoolByMuscle = <String, List<String>>{};
        for (final exercise in exercises) {
          for (final muscle in exercise.primaryMuscles) {
            mesocyclePoolByMuscle
                .putIfAbsent(muscle, () => <String>[])
                .add(exercise.id);
          }
        }

        final templateResult = CycleTemplateBuilder.buildBaseWeek(
          userProfile: userProfile,
          clientProfile: clientProfile,
          targetVolumeByMuscle: volumeTargets,
          mesocycleExercisePoolByMuscle: mesocyclePoolByMuscle,
          availableDays: 4,
        );

        if (!templateResult.success) {
          fail('Template build failed: ${templateResult.error}');
        }

        final sessions = templateResult.sessions!;

        expect(
          sessions.length,
          4,
          reason: 'CycleTemplateBuilder failed to generate 4 sessions',
        );

        // Test 3: Orchestrator Full Run
        debugPrint('Testing Orchestrator...');
        final result = await MotorV3Orchestrator.generateProgram(
          userProfile: userProfile,
          phase: 'accumulation',
          durationWeeks: 4,
          exercises: exercises,
        );

        if (result['success'] != true) {
          throw Exception('Generation Failed: ${result['errors']}');
        }

        final config = result['config'] as TrainingPlanConfig;
        final week1 = config.weeks[0] as TrainingWeek;
        final week2 = config.weeks[1] as TrainingWeek;

        final w1s1 = week1.sessions.first as TrainingSession;
        final w2s1 = week2.sessions.first as TrainingSession;

        // P0 Checks
        expect(
          w1s1.exercises.length,
          w2s1.exercises.length,
          reason: 'Exercise count mismatch',
        );

        for (int i = 0; i < w1s1.exercises.length; i++) {
          final ex1 = w1s1.exercises[i];
          final ex2 = w2s1.exercises[i];

          if (ex1.exerciseId != ex2.exerciseId) {
            throw Exception(
              'Frozen Violation: Ex $i ${ex1.exerciseId} != ${ex2.exerciseId}',
            );
          }

          // Sets should increase linearly or stay same
          // Linear progression: +2 sets per week usually distributed?
          // If 'accumulation', sets should go up for priority muscles.
          // Chest is P5.
          // But individual exercise sets might not increase every week if volume is added elsewhere?
          // Just check logic isn't broken (sets > 0).
          expect(
            ex2.sets,
            greaterThanOrEqualTo(ex1.sets),
            reason: 'Sets decreased!',
          );
        }
      } catch (e, s) {
        await logFile.writeAsString('ERROR: $e\nSTACK: $s');
        rethrow;
      }
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
      secondaryMuscles: ['triceps'],
      equipment: 'barbell',
      difficulty: 'intermediate',
    ),
    Exercise(
      id: 'squat',
      externalId: 'ext_squat',
      name: 'Squat',
      muscleKey: 'quads',
      primaryMuscles: ['quads'],
      secondaryMuscles: ['glutes'],
      equipment: 'barbell',
      difficulty: 'intermediate',
    ),
    Exercise(
      id: 'press',
      externalId: 'p',
      name: 'Press',
      muscleKey: 'deltoids',
      primaryMuscles: ['deltoids'],
      secondaryMuscles: [],
      equipment: 'barbell',
      difficulty: 'beginner',
    ),
    Exercise(
      id: 'curl',
      externalId: 'c',
      name: 'Curl',
      muscleKey: 'biceps',
      primaryMuscles: ['biceps'],
      secondaryMuscles: [],
      equipment: 'dumbbell',
      difficulty: 'beginner',
    ),
    Exercise(
      id: 'ext',
      externalId: 'e',
      name: 'Ext',
      muscleKey: 'triceps',
      primaryMuscles: ['triceps'],
      secondaryMuscles: [],
      equipment: 'cable',
      difficulty: 'beginner',
    ),
    Exercise(
      id: 'row',
      externalId: 'r',
      name: 'Row',
      muscleKey: 'back',
      primaryMuscles: ['back'],
      secondaryMuscles: [],
      equipment: 'cable',
      difficulty: 'beginner',
    ),
    Exercise(
      id: 'leg_curl',
      externalId: 'lc',
      name: 'Leg Curl',
      muscleKey: 'hamstrings',
      primaryMuscles: ['hamstrings'],
      secondaryMuscles: [],
      equipment: 'machine',
      difficulty: 'beginner',
    ),
    Exercise(
      id: 'hip_thrust',
      externalId: 'ht',
      name: 'Hip Thrust',
      muscleKey: 'glutes',
      primaryMuscles: ['glutes'],
      secondaryMuscles: [],
      equipment: 'barbell',
      difficulty: 'intermediate',
    ),
    Exercise(
      id: 'calf_raise',
      externalId: 'cr',
      name: 'Calf Raise',
      muscleKey: 'calves',
      primaryMuscles: ['calves', 'gastrocnemio'],
      secondaryMuscles: [],
      equipment: 'machine',
      difficulty: 'beginner',
    ),
    Exercise(
      id: 'crunch',
      externalId: 'ab',
      name: 'Crunch',
      muscleKey: 'abs',
      primaryMuscles: ['abs'],
      secondaryMuscles: [],
      equipment: 'bodyweight',
      difficulty: 'beginner',
    ),
  ];
}
