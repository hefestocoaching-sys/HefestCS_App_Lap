// ignore_for_file: deprecated_member_use_from_same_package
import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/core/enums/gender.dart';
import 'package:hcs_app_lap/core/enums/muscle_group.dart';
import 'package:hcs_app_lap/domain/entities/exercise_catalog.dart';
import 'package:hcs_app_lap/domain/entities/split_template.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/entities/training_session_log.dart';
import 'package:hcs_app_lap/domain/services/phase_1_data_ingestion_service.dart';
import 'package:hcs_app_lap/domain/services/phase_6_exercise_selection_service.dart';

@Skip('Legacy test: migración pendiente a training_v3')
void main() {
  group('PR-10 Especialización glúteo: swaps reales', () {
    test('cubre thrust + abduction + hinge con swap', () {
      final service = Phase6ExerciseSelectionService();
      final catalog = ExerciseCatalog.fromJsonString('''[
          {
            "code": "barbell_hip_thrust",
            "name": "Barbell Hip Thrust",
            "muscleGroup": "glutes",
            "equipment": ["barbell"],
            "isCompound": true
          },
          {
            "code": "glute_kickback",
            "name": "Glute Kickback",
            "muscleGroup": "glutes",
            "equipment": ["cable", "bodyweight"],
            "isCompound": false
          },
          {
            "code": "rdl_glute",
            "name": "RDL Glute Bias",
            "muscleGroup": "glutes",
            "equipment": ["barbell"],
            "isCompound": true
          },
          {
            "code": "zz_cable_abduction",
            "name": "Cable Abduction",
            "muscleGroup": "glutes",
            "equipment": ["cable"],
            "isCompound": false
          }
        ]''');

      final baseSplit = SplitTemplate(
        splitId: 'glute-swap',
        daysPerWeek: 2,
        dayMuscles: {
          1: ['glutes'],
          2: ['glutes'],
        },
        dailyVolume: {
          1: {'glutes': 8},
          2: {'glutes': 4},
        },
      );

      final derived = DerivedTrainingContext(
        effectiveSleepHours: 7.0,
        effectiveAdherence: 1.0,
        effectiveAvgRir: 2.0,
        contraindicatedPatterns: const {},
        exerciseMustHave: const {},
        exerciseDislikes: const {},
        intensificationAllowed: true,
        intensificationMaxPerSession: 1,
        gluteSpecialization: const GluteSpecializationContext(
          targetFrequencyPerWeek: 2,
          minSetsPerWeek: 10,
          maxSetsPerWeek: 20,
        ),
        referenceDate: DateTime.utc(2025, 12, 20),
      );

      final result = service.selectExercises(
        profile: TrainingProfile(
          id: 'glute-client',
          gender: Gender.female,
          daysPerWeek: 2,
          timePerSessionMinutes: 60,
          trainingLevel: null,
          equipment: const ['barbell', 'cable', 'bodyweight'],
        ),
        baseSplit: baseSplit,
        catalog: catalog,
        weeks: 1,
        derivedContext: derived,
        logs: const <TrainingSessionLog>[],
      );

      final gluteWeek = result.selections[1]!;
      final allGluteExercises = gluteWeek.values
          .expand((m) => m[MuscleGroup.glutes] ?? const [])
          .toList();

      bool hasTag(String tag) => allGluteExercises.any((e) {
        final code = e.code.toLowerCase();
        return code.contains(tag);
      });

      final hasThrust = hasTag('thrust');
      final hasAbduction = hasTag('abduction');
      final hasHinge = hasTag('rdl') || hasTag('deadlift');

      final swapApplied = result.decisions.any(
        (d) => d.category == 'glute_specialization_swap_applied',
      );
      final biasApplied = result.decisions.any(
        (d) => d.category == 'glute_specialization_bias_applied',
      );

      expect(
        (hasThrust && hasAbduction && hasHinge) || (swapApplied || biasApplied),
        isTrue,
        reason:
            'Se espera cobertura thrust+abduction+hinge O al menos un swap/bias. '
            'thrust=$hasThrust, abduction=$hasAbduction, hinge=$hasHinge, '
            'swapApplied=$swapApplied, biasApplied=$biasApplied',
      );
    });
  });
}
