import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/core/enums/effort_intent.dart';
import 'package:hcs_app_lap/core/enums/muscle_group.dart';
import 'package:hcs_app_lap/core/enums/training_level.dart';
import 'package:hcs_app_lap/core/enums/training_phase.dart';
import 'package:hcs_app_lap/domain/entities/exercise_catalog.dart';
import 'package:hcs_app_lap/domain/entities/split_template.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/entities/volume_limits.dart';
import 'package:hcs_app_lap/domain/services/phase_1_data_ingestion_service.dart';
import 'package:hcs_app_lap/domain/services/phase_5_periodization_service.dart';
import 'package:hcs_app_lap/domain/services/phase_7_prescription_service.dart';

void main() {
  group('PR-10 Intensificación bloqueada para Beginner', () {
    test('Beginner nunca recibe técnicas aunque allowIntensification=true', () {
      final service = Phase7PrescriptionService();
      final periodization = Phase5PeriodizationResult(
        weeks: [
          PeriodizedWeek(
            weekIndex: 1,
            phase: TrainingPhase.accumulation,
            volumeFactor: 1.0,
            effortIntent: EffortIntent.base,
            repBias: RepBias.moderate,
            fatigueExpectation: 'low',
            dailyVolume: {
              1: {'biceps': 6},
            },
          ),
        ],
        decisions: const [],
      );

      final baseSplit = SplitTemplate(
        splitId: 'test',
        daysPerWeek: 1,
        dayMuscles: {
          1: ['biceps'],
        },
        dailyVolume: {
          1: {'biceps': 6},
        },
      );

      final derived = DerivedTrainingContext(
        effectiveSleepHours: 7.5,
        effectiveAdherence: 1.0,
        effectiveAvgRir: 2.5,
        contraindicatedPatterns: const {},
        exerciseMustHave: const {},
        exerciseDislikes: const {},
        intensificationAllowed: true,
        intensificationMaxPerSession: 2,
        gluteSpecialization: null,
        referenceDate: DateTime.utc(2025, 12, 20),
      );

      final selections = {
        1: {
          1: {
            MuscleGroup.biceps: [
              const ExerciseEntry(
                code: 'db_curl',
                name: 'DB Curl',
                muscleGroup: MuscleGroup.biceps,
                equipment: ['dumbbell'],
                isCompound: false,
              ),
            ],
          },
        },
      };

      final volumeLimits = {
        'biceps': const VolumeLimits(
          muscleGroup: 'biceps',
          mev: 6,
          mav: 10,
          mrv: 12,
          recommendedStartVolume: 8,
        ),
      };

      final result = service.buildPrescriptions(
        baseSplit: baseSplit,
        periodization: periodization,
        selections: selections,
        trainingLevel: TrainingLevel.beginner,
        derivedContext: derived,
        volumeLimitsByMuscle: volumeLimits,
        profile: const TrainingProfile(
          daysPerWeek: 1,
          timePerSessionMinutes: 45,
        ),
      );

      // Ninguna técnica aplicada
      final allPres = result.weekDayPrescriptions.values
          .expand((d) => d.values)
          .expand((p) => p)
          .toList();
      expect(allPres.any((p) => p.templateCode != null), isFalse);

      // DecisionTrace registra razón por beginner
      expect(
        result.decisions.any(
          (d) =>
              d.category == 'intensification_skipped_reason' &&
              (d.context['reasons'] as List?)?.contains('nivel=beginner') ==
                  true,
        ),
        isTrue,
      );
    });
  });
}
