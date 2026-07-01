import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/muscle_priority_engine.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_split.dart';

void main() {
  group('MusclePriorityEngine current behavior baseline', () {
    test(
      'normalizes supported aliases and discards unknowns in full body split',
      () {
        final order = MusclePriorityEngine.buildDayMuscleOrder(
          split: TrainingSplit.fullBody,
          availableDays: 1,
          musclePriorities: const {
            'chest': 5,
            'unknown_muscle': 5,
            'glute': 4,
            'quadriceps': 3,
            'back_mid_upper': 2,
          },
          frequencyByMuscle: const {
            'chest': 1,
            'unknown_muscle': 1,
            'glute': 1,
            'quadriceps': 1,
            'back_mid_upper': 1,
          },
        );

        expect(order[1], ['pectorals', 'quads']);
        expect(order[1], isNot(contains('unknown_muscle')));
        expect(order[1], isNot(contains('back_mid_upper')));
        expect(order[1], isNot(contains('glute')));
        expect(order[1], isNot(contains('glutes')));
      },
    );

    test(
      'upper lower split filters unknowns that are not in split allowlists',
      () {
        final order = MusclePriorityEngine.buildDayMuscleOrder(
          split: TrainingSplit.upperLower,
          availableDays: 2,
          musclePriorities: const {
            'chest': 5,
            'unknown_muscle': 5,
            'glute': 4,
            'quadriceps': 3,
            'back_mid_upper': 2,
          },
          frequencyByMuscle: const {
            'chest': 1,
            'unknown_muscle': 1,
            'glute': 1,
            'quadriceps': 1,
            'back_mid_upper': 1,
          },
        );

        expect(order[1], ['pectorals']);
        expect(order[2], ['quads']);
        expect(order[1], isNot(contains('unknown_muscle')));
        expect(order[2], isNot(contains('unknown_muscle')));
        expect(order[1], isNot(contains('back_mid_upper')));
        expect(order[2], isNot(contains('back_mid_upper')));
        expect(order[1], isNot(contains('glute')));
        expect(order[2], isNot(contains('glute')));
      },
    );

    test('rotates primary muscles deterministically across days', () {
      final order = MusclePriorityEngine.buildDayMuscleOrder(
        split: TrainingSplit.fullBody,
        availableDays: 3,
        musclePriorities: const {
          'pectorals': 5,
          'lats': 5,
          'quads': 5,
          'biceps': 2,
        },
        frequencyByMuscle: const {
          'pectorals': 1,
          'lats': 1,
          'quads': 1,
          'biceps': 1,
        },
      );

      expect(order[1], ['lats', 'pectorals', 'quads', 'biceps']);
      expect(order[2], ['pectorals', 'quads', 'lats', 'biceps']);
      expect(order[3], ['quads', 'lats', 'pectorals', 'biceps']);
    });
  });
}
