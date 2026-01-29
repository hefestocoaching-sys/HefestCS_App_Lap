import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/core/enums/gender.dart';
import 'package:hcs_app_lap/core/enums/training_goal.dart';
import 'package:hcs_app_lap/core/enums/training_level.dart';
import 'package:hcs_app_lap/core/enums/muscle_group.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/services/phase_1_data_ingestion_service.dart'
    show DerivedTrainingContext;
import 'package:hcs_app_lap/domain/services/phase_2_readiness_evaluation_service.dart';

void main() {
  group('Phase2 local readiness', () {
    late Phase2ReadinessEvaluationService service;

    setUp(() {
      service = Phase2ReadinessEvaluationService();
    });

    DerivedTrainingContext ctxWith({
      Set<String> patterns = const {},
      double effectiveSleep = 7.5,
      double? adherence,
      double? avgRir,
    }) {
      return DerivedTrainingContext(
        effectiveSleepHours: effectiveSleep,
        effectiveAdherence: adherence,
        effectiveAvgRir: avgRir,
        contraindicatedPatterns: patterns,
        exerciseMustHave: const {},
        exerciseDislikes: const {},
        intensificationAllowed: true,
        intensificationMaxPerSession: 1,
        gluteSpecialization: null,
        referenceDate: DateTime(2025, 1, 1),
      );
    }

    test(
      'lesión lumbar bloquea hinge (hamstrings/glutes) aunque global good',
      () {
        final profile = TrainingProfile(
          daysPerWeek: 4,
          timePerSessionMinutes: 60,
          avgSleepHours: 8.0,
          globalGoal: TrainingGoal.hypertrophy,
          trainingLevel: TrainingLevel.intermediate,
        );

        final ctx = ctxWith(patterns: {'lumbar'});

        final result = service.evaluateReadinessWithContext(
          profile: profile,
          derivedContext: ctx,
        );

        expect(
          result.readinessLevel == ReadinessLevel.good ||
              result.readinessLevel == ReadinessLevel.excellent,
          true,
        );
        expect(
          result.readinessByMuscle[MuscleGroup.hamstrings],
          ReadinessLevel.low,
        );
        expect(
          result.readinessByMuscle[MuscleGroup.glutes],
          ReadinessLevel.low,
        );
      },
    );

    test('mujer vs hombre: glúteo con mayor readiness local (bump)', () {
      final male = TrainingProfile(
        gender: Gender.male,
        daysPerWeek: 4,
        timePerSessionMinutes: 60,
        avgSleepHours: 8.0,
        globalGoal: TrainingGoal.hypertrophy,
      );
      final female = male.copyWith(gender: Gender.female);

      final resultMale = service.evaluateReadinessWithContext(profile: male);
      final resultFemale = service.evaluateReadinessWithContext(
        profile: female,
      );

      final gluteMale = resultMale.readinessByMuscle[MuscleGroup.glutes]!;
      final gluteFemale = resultFemale.readinessByMuscle[MuscleGroup.glutes]!;

      // Mujer debería ser >= que hombre localmente (nunca menor)
      int rank(ReadinessLevel l) => ReadinessLevel.values.indexOf(l);
      expect(rank(gluteFemale) >= rank(gluteMale), true);
    });

    test('determinismo: mismos inputs generan mismo readinessByMuscle', () {
      final profile = TrainingProfile(
        daysPerWeek: 3,
        timePerSessionMinutes: 45,
        avgSleepHours: 7.0,
        globalGoal: TrainingGoal.generalFitness,
      );
      final ctx = ctxWith(patterns: {'shoulder'});

      final a = service.evaluateReadinessWithContext(
        profile: profile,
        derivedContext: ctx,
      );
      final b = service.evaluateReadinessWithContext(
        profile: profile,
        derivedContext: ctx,
      );

      expect(a.readinessByMuscle, b.readinessByMuscle);
      expect(a.readinessLevel, b.readinessLevel);
      expect(a.volumeAdjustmentFactor, b.volumeAdjustmentFactor);
    });
  });
}
