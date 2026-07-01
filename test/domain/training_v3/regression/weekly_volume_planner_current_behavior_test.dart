import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/weekly_volume_planner.dart';

void main() {
  group('WeeklyVolumePlanner strict muscle normalization', () {
    test('week 1 normalizes aliases and discards unknown keys', () {
      final weekVolume = WeeklyVolumePlanner.buildWeekVolume(
        baseVop: const {
          'pectorals': 10,
          'chest': 12,
          'quadriceps': 14,
          'gluteos': 13,
          'deltoide_anterior': 8,
          'unknown_muscle': 12,
          'back_mid_upper': 13,
          'mysterychest': 7,
          'glute': 9,
        },
        mevByMuscle: const {
          'pectorals': 6,
          'chest': 6,
          'quadriceps': 8,
          'gluteos': 8,
          'deltoide_anterior': 5,
          'unknown_muscle': 6,
          'back_mid_upper': 6,
          'mysterychest': 5,
          'glute': 5,
        },
        mrvByMuscle: const {
          'pectorals': 20,
          'chest': 20,
          'quadriceps': 24,
          'gluteos': 22,
          'deltoide_anterior': 14,
          'unknown_muscle': 20,
          'back_mid_upper': 20,
          'mysterychest': 14,
          'glute': 18,
        },
        priorities: const {
          'pectorals': 4,
          'chest': 5,
          'quadriceps': 1,
          'gluteos': 4,
          'deltoide_anterior': 3,
          'unknown_muscle': 5,
          'back_mid_upper': 5,
          'mysterychest': 1,
          'glute': 5,
        },
        trainingLevel: 'intermediate',
        weekNumber: 1,
        phase: 'accumulation',
        feedback: const {},
      );

      expect(weekVolume, {
        'pectorals': 12,
        'quads': 14,
        'glutes': 13,
        'delts_front': 8,
      });
      expect(weekVolume.keys, isNot(contains('chest')));
      expect(weekVolume.keys, isNot(contains('quadriceps')));
      expect(weekVolume.keys, isNot(contains('gluteos')));
      expect(weekVolume.keys, isNot(contains('deltoide_anterior')));
      expect(weekVolume.keys, isNot(contains('unknown_muscle')));
      expect(weekVolume.keys, isNot(contains('back_mid_upper')));
      expect(weekVolume.keys, isNot(contains('mysterychest')));
      expect(weekVolume.keys, isNot(contains('glute')));
    });

    test('week 1 unknown-only maps return empty output', () {
      final weekVolume = WeeklyVolumePlanner.buildWeekVolume(
        baseVop: const {
          'unknown_muscle': 12,
          'back_mid_upper': 13,
          'mysterychest': 7,
          'glute': 9,
        },
        mevByMuscle: const {
          'unknown_muscle': 6,
          'back_mid_upper': 6,
          'mysterychest': 5,
          'glute': 5,
        },
        mrvByMuscle: const {
          'unknown_muscle': 20,
          'back_mid_upper': 20,
          'mysterychest': 14,
          'glute': 18,
        },
        priorities: const {
          'unknown_muscle': 5,
          'back_mid_upper': 5,
          'mysterychest': 1,
          'glute': 5,
        },
        trainingLevel: 'intermediate',
        weekNumber: 1,
        phase: 'accumulation',
        feedback: const {},
      );

      expect(weekVolume, isEmpty);
    });

    test('accumulation formula for known keys is frozen', () {
      final weekVolume = WeeklyVolumePlanner.buildWeekVolume(
        baseVop: const {'pectorals': 10},
        mevByMuscle: const {'pectorals': 6},
        mrvByMuscle: const {'pectorals': 30},
        priorities: const {'pectorals': 5},
        trainingLevel: 'intermediate',
        weekNumber: 3,
        phase: 'accumulation',
        feedback: const {},
      );

      expect(weekVolume['pectorals'], 13);
    });

    test('decision trace stores canonical keys only', () {
      const baseVop = {
        'pectorals': 10,
        'chest': 12,
        'lats': 11,
        'unknown_muscle': 12,
        'back_mid_upper': 13,
        'glute': 9,
      };
      const mevByMuscle = {
        'pectorals': 6,
        'chest': 6,
        'lats': 7,
        'unknown_muscle': 6,
        'back_mid_upper': 6,
        'glute': 5,
      };
      const mrvByMuscle = {
        'pectorals': 20,
        'chest': 21,
        'lats': 22,
        'unknown_muscle': 20,
        'back_mid_upper': 20,
        'glute': 18,
      };
      const priorities = {
        'pectorals': 4,
        'chest': 5,
        'lats': 3,
        'unknown_muscle': 5,
        'back_mid_upper': 5,
        'glute': 5,
      };

      WeeklyVolumePlanner.buildWeekVolume(
        baseVop: baseVop,
        mevByMuscle: mevByMuscle,
        mrvByMuscle: mrvByMuscle,
        priorities: priorities,
        trainingLevel: 'intermediate',
        weekNumber: 1,
        phase: 'accumulation',
        feedback: const {},
      );
      WeeklyVolumePlanner.buildWeekVolume(
        baseVop: baseVop,
        mevByMuscle: mevByMuscle,
        mrvByMuscle: mrvByMuscle,
        priorities: priorities,
        trainingLevel: 'intermediate',
        weekNumber: 3,
        phase: 'accumulation',
        feedback: const {},
      );

      final trace = WeeklyVolumePlanner.buildDecisionTrace();
      final tracedBaseVop = Map<dynamic, dynamic>.from(trace['baseVop'] as Map);
      final weekVolumes = trace['weekVolumes'] as Map<dynamic, dynamic>;
      final weekDecisions = trace['weekDecisions'] as Map<dynamic, dynamic>;
      final weekOne = weekVolumes['1'] as Map<dynamic, dynamic>;
      final weekThree = weekVolumes['3'] as Map<dynamic, dynamic>;
      final weekThreeDecisions = weekDecisions['3'] as Map<dynamic, dynamic>;

      expect(tracedBaseVop, {'pectorals': 12, 'lats': 11});
      expect(weekOne, {'pectorals': 12, 'lats': 11});
      expect(weekThree, {'pectorals': 15, 'lats': 13});
      expect(weekThreeDecisions.keys, containsAll(['pectorals', 'lats']));

      for (final raw in [
        'chest',
        'unknown_muscle',
        'back_mid_upper',
        'glute',
      ]) {
        expect(tracedBaseVop.keys, isNot(contains(raw)));
        expect(weekOne.keys, isNot(contains(raw)));
        expect(weekThree.keys, isNot(contains(raw)));
        expect(weekThreeDecisions.keys, isNot(contains(raw)));
      }
    });
  });
}
