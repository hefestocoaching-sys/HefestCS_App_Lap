import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/training/training_cycle.dart';
import 'package:hcs_app_lap/domain/training/validation/vop_validator.dart';

void main() {
  group('VopValidator strict muscle normalization', () {
    test('canonical keys validate without blocking', () {
      expect(
        () => VopValidator.validate(
          cycle: _cycleWithBase(const {
            'pectorals': ['bench_press'],
          }),
          directVopByMuscle: const {},
          plannedExercises: const [
            VopPlannedExercise(
              stimulusContribution: {'pectorals': 1.0},
              plannedSets: 4,
            ),
          ],
        ),
        returnsNormally,
      );
    });

    test('supported aliases validate without blocking', () {
      expect(
        () => VopValidator.validate(
          cycle: _cycleWithBase(const {
            'chest': ['bench_press'],
            'quadriceps': ['squat'],
            'deltoide_anterior': ['overhead_press'],
          }),
          directVopByMuscle: const {},
          plannedExercises: const [
            VopPlannedExercise(
              stimulusContribution: {
                'chest': 1.0,
                'quadriceps': 1.0,
                'deltoide_anterior': 1.0,
              },
              plannedSets: 4,
            ),
          ],
        ),
        returnsNormally,
      );
    });

    test('unknown stimulus keys do not block validation', () {
      expect(
        () => VopValidator.validate(
          cycle: _cycleWithBase(const {
            'pectorals': ['bench_press'],
          }),
          directVopByMuscle: const {'pectorals': 4.0},
          plannedExercises: const [
            VopPlannedExercise(
              stimulusContribution: {
                'unknown_muscle': 10.0,
                'UNKNOWN_MUSCLE': 10.0,
              },
              plannedSets: 4,
            ),
          ],
        ),
        returnsNormally,
      );
    });

    test('unknown base muscles do not block validation', () {
      expect(
        () => VopValidator.validate(
          cycle: _cycleWithBase(const {
            'unknown_muscle': ['mystery_lift'],
            'glute': ['legacy_glute_bridge'],
            'back_mid_upper': ['legacy_row'],
          }),
          directVopByMuscle: const {'pectorals': 4.0},
          plannedExercises: const [
            VopPlannedExercise(
              stimulusContribution: {'pectorals': 1.0},
              plannedSets: 4,
            ),
          ],
        ),
        returnsNormally,
      );
    });

    test(
      'unknown raw and lowercase fallback keys are not surfaced publicly',
      () {
        expect(
          () => VopValidator.validate(
            cycle: _cycleWithBase(const {
              'unknown_muscle': ['mystery_lift'],
              'back_mid_upper': ['legacy_row'],
            }),
            directVopByMuscle: const {'pectorals': 4.0},
            plannedExercises: const [
              VopPlannedExercise(
                stimulusContribution: {
                  'MysteryChest': 10.0,
                  'mysterychest': 10.0,
                },
                plannedSets: 4,
              ),
            ],
          ),
          returnsNormally,
        );
      },
    );

    test('unknowns preserve non-blocking validator behavior', () {
      expect(
        () => VopValidator.validate(
          cycle: _cycleWithBase(const {
            'unknown_muscle': ['mystery_lift'],
            'pectorals': ['bench_press'],
          }),
          directVopByMuscle: const {},
          plannedExercises: const [
            VopPlannedExercise(
              stimulusContribution: {'unknown_muscle': 99.0, 'pectorals': 1.0},
              plannedSets: 4,
            ),
          ],
        ),
        returnsNormally,
      );
    });
  });
}

TrainingCycle _cycleWithBase(Map<String, List<String>> baseExercisesByMuscle) {
  final startDate = DateTime.utc(2026);

  return TrainingCycle(
    cycleId: 'test-cycle',
    clientId: 'test-client',
    startDate: startDate,
    goal: 'hypertrophy',
    priorityMuscles: const [],
    splitType: 'test_split',
    baseExercisesByMuscle: baseExercisesByMuscle,
    phaseState: 'VME',
    currentWeek: 1,
    createdAt: startDate,
  );
}
