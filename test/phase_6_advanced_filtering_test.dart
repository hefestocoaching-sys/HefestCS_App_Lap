import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/core/enums/gender.dart';
import 'package:hcs_app_lap/core/enums/muscle_group.dart';
import 'package:hcs_app_lap/core/enums/training_goal.dart';
import 'package:hcs_app_lap/domain/entities/exercise_catalog.dart';
import 'package:hcs_app_lap/domain/entities/split_template.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/services/phase_1_data_ingestion_service.dart';
import 'package:hcs_app_lap/domain/services/phase_6_exercise_selection_service.dart';

@Skip('Legacy test: migración pendiente a training_v3')
void main() {
  group('Phase6 advanced filtering', () {
    late Phase6ExerciseSelectionService service;
    late ExerciseCatalog catalog;
    late SplitTemplate baseSplit;

    setUp(() {
      service = Phase6ExerciseSelectionService();

      // Catálogo simplificado
      catalog = ExerciseCatalog.fromJsonString('''
      [
        {"code": "back_squat", "name": "Back Squat", "muscleGroup": "quads", "equipment": ["barbell"], "isCompound": true},
        {"code": "leg_press", "name": "Leg Press", "muscleGroup": "quads", "equipment": ["machine"], "isCompound": true},
        {"code": "front_squat", "name": "Front Squat", "muscleGroup": "quads", "equipment": ["barbell"], "isCompound": true},
        {"code": "athletic_squat", "name": "Athletic Squat", "muscleGroup": "quads", "equipment": ["barbell"], "isCompound": true},
        {"code": "atlas_squat", "name": "Atlas Squat", "muscleGroup": "quads", "equipment": ["barbell"], "isCompound": true},
        {"code": "leg_extension", "name": "Leg Extension", "muscleGroup": "quads", "equipment": ["machine"], "isCompound": false},
        {"code": "hack_squat", "name": "Hack Squat", "muscleGroup": "quads", "equipment": ["machine"], "isCompound": true},
        {"code": "smith_squat", "name": "Smith Machine Squat", "muscleGroup": "quads", "equipment": ["machine"], "isCompound": true},
        {"code": "goblet_squat", "name": "Goblet Squat", "muscleGroup": "quads", "equipment": ["dumbbell"], "isCompound": true},
        {"code": "split_squat", "name": "Split Squat", "muscleGroup": "quads", "equipment": ["dumbbell"], "isCompound": true},
        {"code": "sissy_squat", "name": "Sissy Squat", "muscleGroup": "quads", "equipment": ["bodyweight"], "isCompound": false},
        {"code": "step_up", "name": "Step Up", "muscleGroup": "quads", "equipment": ["dumbbell"], "isCompound": true},
        {"code": "barbell_lunge", "name": "Barbell Lunge", "muscleGroup": "quads", "equipment": ["barbell"], "isCompound": true},
        {"code": "walking_lunge", "name": "Walking Lunge", "muscleGroup": "quads", "equipment": ["bodyweight"], "isCompound": true},
        {"code": "bulgarian_split_squat", "name": "Bulgarian Split Squat", "muscleGroup": "quads", "equipment": ["bodyweight"], "isCompound": true},
        {"code": "box_step_up", "name": "Box Step Up", "muscleGroup": "quads", "equipment": ["bodyweight"], "isCompound": true},
        {"code": "reverse_lunge", "name": "Reverse Lunge", "muscleGroup": "quads", "equipment": ["bodyweight"], "isCompound": true},
        {"code": "leg_extension_unilateral", "name": "Leg Extension Unilateral", "muscleGroup": "quads", "equipment": ["machine"], "isCompound": false},
        {"code": "leg_press_unilateral", "name": "Leg Press Unilateral", "muscleGroup": "quads", "equipment": ["machine"], "isCompound": true},
        {"code": "rdl", "name": "Romanian Deadlift", "muscleGroup": "hamstrings", "equipment": ["barbell"], "isCompound": true},
        {"code": "leg_curl", "name": "Leg Curl", "muscleGroup": "hamstrings", "equipment": ["machine"], "isCompound": false},
        {"code": "seated_leg_curl", "name": "Seated Leg Curl", "muscleGroup": "hamstrings", "equipment": ["machine"], "isCompound": false},
        {"code": "lying_leg_curl", "name": "Lying Leg Curl", "muscleGroup": "hamstrings", "equipment": ["machine"], "isCompound": false},
        {"code": "nordic_curl", "name": "Nordic Curl", "muscleGroup": "hamstrings", "equipment": ["bodyweight"], "isCompound": false},
        {"code": "glute_ham_raise", "name": "Glute-Ham Raise", "muscleGroup": "hamstrings", "equipment": ["machine"], "isCompound": true},
        {"code": "hip_thrust", "name": "Hip Thrust", "muscleGroup": "glutes", "equipment": ["barbell"], "isCompound": true},
        {"code": "glute_bridge", "name": "Glute Bridge", "muscleGroup": "glutes", "equipment": ["bodyweight"], "isCompound": true},
        {"code": "cable_abduction", "name": "Cable Abduction", "muscleGroup": "glutes", "equipment": ["cable"], "isCompound": false},
        {"code": "machine_abduction", "name": "Machine Abduction", "muscleGroup": "glutes", "equipment": ["machine"], "isCompound": false},
        {"code": "single_leg_glute_bridge", "name": "Single Leg Glute Bridge", "muscleGroup": "glutes", "equipment": ["bodyweight"], "isCompound": false},
        {"code": "cable_kickback", "name": "Cable Kickback", "muscleGroup": "glutes", "equipment": ["cable"], "isCompound": false},
        {"code": "machine_kickback", "name": "Machine Kickback", "muscleGroup": "glutes", "equipment": ["machine"], "isCompound": false},
        {"code": "smith_hip_thrust", "name": "Smith Hip Thrust", "muscleGroup": "glutes", "equipment": ["machine"], "isCompound": true},
        {"code": "frog_pumps", "name": "Frog Pumps", "muscleGroup": "glutes", "equipment": ["bodyweight"], "isCompound": false},
        {"code": "banded_glute_bridge", "name": "Banded Glute Bridge", "muscleGroup": "glutes", "equipment": ["bodyweight"], "isCompound": false},
        {"code": "deadlift", "name": "Deadlift", "muscleGroup": "back", "equipment": ["barbell"], "isCompound": true}
      ]
      ''');

      baseSplit = SplitTemplate(
        splitId: 'test',
        daysPerWeek: 3,
        dayMuscles: {
          1: ['glutes', 'hamstrings'],
          2: ['quads'],
          3: ['glutes'],
        },
        dailyVolume: {
          1: {'glutes': 6, 'hamstrings': 4},
          2: {'quads': 6},
          3: {'glutes': 4},
        },
      );
    });

    test('lesión lumbar bloquea hinge: nunca selecciona RDL/Deadlift', () {
      final profile = TrainingProfile(
        daysPerWeek: 3,
        timePerSessionMinutes: 60,
        globalGoal: TrainingGoal.hypertrophy,
        equipment: const ['barbell', 'machine', 'bodyweight'],
      );

      final context = DerivedTrainingContext(
        effectiveSleepHours: 7.5,
        effectiveAdherence: null,
        effectiveAvgRir: null,
        contraindicatedPatterns: const {'lumbar', 'hinge'},
        exerciseMustHave: const {},
        exerciseDislikes: const {},
        intensificationAllowed: true,
        intensificationMaxPerSession: 1,
        gluteSpecialization: null,
        referenceDate: DateTime(2025, 1, 1),
      );

      final res = service.selectExercises(
        profile: profile,
        baseSplit: baseSplit,
        catalog: catalog,
        derivedContext: context,
      );

      // Verificar que ningún ejercicio tipo hinge fue seleccionado
      for (final weekMap in res.selections.values) {
        for (final dayMap in weekMap.values) {
          for (final exList in dayMap.values) {
            for (final ex in exList) {
              expect(ex.code.contains('rdl'), false);
              expect(ex.code.contains('deadlift'), false);
            }
          }
        }
      }

      expect(
        res.decisions.any(
          (d) => d.category == 'filtered_by_injury_constraints',
        ),
        true,
      );
    });

    test(
      'mustHave incluye hip_thrust: se selecciona cuando glutes presente',
      () {
        final profile = TrainingProfile(
          daysPerWeek: 3,
          timePerSessionMinutes: 60,
          globalGoal: TrainingGoal.hypertrophy,
          equipment: const ['barbell', 'bodyweight'],
        );

        final context = DerivedTrainingContext(
          effectiveSleepHours: 7.5,
          effectiveAdherence: null,
          effectiveAvgRir: null,
          contraindicatedPatterns: const {},
          exerciseMustHave: const {'hip_thrust'},
          exerciseDislikes: const {},
          intensificationAllowed: true,
          intensificationMaxPerSession: 1,
          gluteSpecialization: null,
          referenceDate: DateTime(2025, 1, 1),
        );

        final res = service.selectExercises(
          profile: profile,
          baseSplit: baseSplit,
          catalog: catalog,
          derivedContext: context,
        );

        // Buscar hip_thrust en alguna semana
        var foundHipThrust = false;
        for (final weekMap in res.selections.values) {
          for (final dayMap in weekMap.values) {
            final gluteExs = dayMap[MuscleGroup.glutes] ?? [];
            if (gluteExs.any((e) => e.code == 'hip_thrust')) {
              foundHipThrust = true;
              break;
            }
          }
        }

        expect(foundHipThrust, true);
        expect(
          res.decisions.any((d) => d.category == 'must_have_applied'),
          true,
        );
      },
    );

    test('dislikes excluye back_squat: nunca aparece aunque sea candidato', () {
      final profile = TrainingProfile(
        daysPerWeek: 3,
        timePerSessionMinutes: 60,
        globalGoal: TrainingGoal.hypertrophy,
        equipment: const ['barbell', 'machine'],
      );

      final context = DerivedTrainingContext(
        effectiveSleepHours: 7.5,
        effectiveAdherence: null,
        effectiveAvgRir: null,
        contraindicatedPatterns: const {},
        exerciseMustHave: const {},
        exerciseDislikes: const {'back_squat'},
        intensificationAllowed: true,
        intensificationMaxPerSession: 1,
        gluteSpecialization: null,
        referenceDate: DateTime(2025, 1, 1),
      );

      final res = service.selectExercises(
        profile: profile,
        baseSplit: baseSplit,
        catalog: catalog,
        derivedContext: context,
      );

      // Verificar ausencia de back_squat
      for (final weekMap in res.selections.values) {
        for (final dayMap in weekMap.values) {
          for (final exList in dayMap.values) {
            for (final ex in exList) {
              expect(ex.code, isNot('back_squat'));
            }
          }
        }
      }
    });

    test('glute specialization asegura thrust + abduction en la semana', () {
      final profile = TrainingProfile(
        daysPerWeek: 3,
        timePerSessionMinutes: 60,
        globalGoal: TrainingGoal.hypertrophy,
        gender: Gender.female,
        equipment: const ['barbell', 'cable', 'bodyweight'],
      );

      final res = service.selectExercises(
        profile: profile,
        baseSplit: baseSplit,
        catalog: catalog,
      );

      // Verificar que se aplicó sesgo
      expect(
        res.decisions.any(
          (d) => d.category == 'glute_specialization_bias_applied',
        ),
        true,
      );
    });

    test('determinismo: mismos inputs → misma selección', () {
      final profile = TrainingProfile(
        daysPerWeek: 3,
        timePerSessionMinutes: 60,
        globalGoal: TrainingGoal.hypertrophy,
        equipment: const ['barbell', 'machine'],
      );

      final a = service.selectExercises(
        profile: profile,
        baseSplit: baseSplit,
        catalog: catalog,
      );
      final b = service.selectExercises(
        profile: profile,
        baseSplit: baseSplit,
        catalog: catalog,
      );

      expect(a.selections.keys, b.selections.keys);
      for (final w in a.selections.keys) {
        for (final d in a.selections[w]!.keys) {
          for (final mg in a.selections[w]![d]!.keys) {
            final aExs = a.selections[w]![d]![mg]!.map((e) => e.code).toList();
            final bExs = b.selections[w]![d]![mg]!.map((e) => e.code).toList();
            expect(aExs, bExs);
          }
        }
      }
    });
  });
}
