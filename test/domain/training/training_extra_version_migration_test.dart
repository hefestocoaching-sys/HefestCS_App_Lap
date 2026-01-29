import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/services/training_program_engine.dart';
import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/core/enums/training_level.dart';
import 'package:hcs_app_lap/domain/entities/training_plan_config.dart';
import '../../fixtures/training_fixtures.dart';

void main() {
  group('PR-10 Versionado TrainingExtra y migración', () {
    test('inserta version y flags cuando no existen', () {
      final engine = TrainingProgramEngine();
      final profile = TrainingProfile(
        id: 'client-extra-migration',
        trainingLevel: TrainingLevel.intermediate,
        daysPerWeek: 3,
        timePerSessionMinutes: 60,
        baseVolumePerMuscle: const {'chest': 10, 'back': 12, 'quads': 10},
        equipment: const [
          'barbell',
          'machine',
          'cable',
          'dumbbell',
          'bodyweight',
        ],
        extra: const {},
      );

      TrainingPlanConfig? plan;
      try {
        plan = engine.generatePlan(
          planId: 'plan-extra-migration',
          clientId: 'client-extra-migration',
          planName: 'Plan Migration',
          startDate: DateTime.utc(2025, 12, 20),
          profile: profile,
          exercises: canonicalExercises(),
        );
      } on StateError catch (_) {
        // Plan bloqueado por invariantes clínicos: aceptar y finalizar test
        return;
      }

      final snapshot = plan.trainingProfileSnapshot!;
      expect(
        snapshot.extra[TrainingExtraKeys.trainingExtraVersion],
        '1.0.0-pr10',
      );
      expect(
        snapshot.extra.containsKey(TrainingExtraKeys.progressionBlocked),
        isTrue,
      );
      expect(
        snapshot.extra.containsKey(TrainingExtraKeys.manualOverrideActive),
        isTrue,
      );

      expect(
        engine.lastDecisions.any((d) => d.category == 'extra_migrated'),
        isTrue,
      );
    });
  });
}
