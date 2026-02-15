// test/domain/training_v3/models/muscle_decision_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/training_v3/models/muscle_decision.dart';
import 'package:hcs_app_lap/domain/training_v3/models/muscle_progression_tracker.dart';

void main() {
  group('MuscleDecision', () {
    test('should create increase decision correctly', () {
      const decision = MuscleDecision(
        muscle: 'pectorals',
        action: VolumeAction.increase,
        newVolume: 14,
        newPhase: ProgressionPhase.discovering,
        reason: 'Good response, increasing by 2 sets',
        confidence: 0.9,
      );

      expect(decision.action, VolumeAction.increase);
      expect(decision.newVolume, 14);
      expect(decision.reason, contains('increasing'));
      expect(decision.confidence, 0.9);
    });

    test('should create deload decision correctly', () {
      const decision = MuscleDecision(
        muscle: 'quadriceps',
        action: VolumeAction.deload,
        newVolume: 10,
        newPhase: ProgressionPhase.deloading,
        reason: 'High fatigue, entering deload phase',
        confidence: 0.8,
      );

      expect(decision.action, VolumeAction.deload);
      expect(decision.newVolume, 10);
      expect(decision.newPhase, ProgressionPhase.deloading);
    });

    test('should create maintain decision correctly', () {
      const decision = MuscleDecision(
        muscle: 'lats',
        action: VolumeAction.maintain,
        newVolume: 16,
        newPhase: ProgressionPhase.maintaining,
        reason: 'Stable performance, maintaining volume',
        confidence: 0.7,
      );

      expect(decision.action, VolumeAction.maintain);
      expect(decision.newVolume, 16);
    });

    test('should detect VMR discovery', () {
      const decision = MuscleDecision(
        muscle: 'hamstrings',
        action: VolumeAction.maintain,
        newVolume: 18,
        newPhase: ProgressionPhase.maintaining,
        reason: 'VMR discovered',
        confidence: 0.9,
        vmrDiscovered: 18,
      );

      expect(decision.vmrDiscovered, 18);
      expect(decision.vmrDiscovered != null, true);
    });

    test('should detect microdeload requirement', () {
      const decision = MuscleDecision(
        muscle: 'triceps',
        action: VolumeAction.microdeload,
        newVolume: 10,
        newPhase: ProgressionPhase.microdeload,
        reason: '6 weeks since last microdeload',
        confidence: 0.8,
        requiresMicrodeload: true,
        weeksToMicrodeload: 0,
      );

      expect(decision.requiresMicrodeload, true);
      expect(decision.weeksToMicrodeload, 0);
      expect(decision.action, VolumeAction.microdeload);
    });

    test('should serialize to JSON correctly', () {
      const decision = MuscleDecision(
        muscle: 'pectorals',
        action: VolumeAction.increase,
        newVolume: 14,
        newPhase: ProgressionPhase.discovering,
        reason: 'Good response',
        confidence: 0.85,
      );

      final json = decision.toJson();

      expect(json['muscle'], 'pectorals');
      expect(json['action'], 'increase');
      expect(json['newVolume'], 14);
      expect(json['newPhase'], 'discovering');
      expect(json['confidence'], 0.85);
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'muscle': 'quadriceps',
        'action': 'deload',
        'newVolume': 10,
        'newPhase': 'deloading',
        'reason': 'High fatigue',
        'confidence': 0.8,
        'vmrDiscovered': null,
        'requiresMicrodeload': false,
        'weeksToMicrodeload': null,
        'isNewCycle': false,
        'exercisesToReplace': [],
      };

      final decision = MuscleDecision.fromJson(json);

      expect(decision.muscle, 'quadriceps');
      expect(decision.action, VolumeAction.deload);
      expect(decision.newVolume, 10);
      expect(decision.newPhase, ProgressionPhase.deloading);
    });
  });

  group('VolumeAction Enum', () {
    test('should have all required actions', () {
      expect(VolumeAction.values.contains(VolumeAction.increase), true);
      expect(VolumeAction.values.contains(VolumeAction.maintain), true);
      expect(VolumeAction.values.contains(VolumeAction.decrease), true);
      expect(VolumeAction.values.contains(VolumeAction.deload), true);
      expect(VolumeAction.values.contains(VolumeAction.microdeload), true);
      expect(VolumeAction.values.contains(VolumeAction.adjust), true);
    });

    test('should convert to/from string', () {
      expect(VolumeAction.increase.toString(), contains('increase'));
      expect(VolumeAction.deload.toString(), contains('deload'));
      expect(VolumeAction.microdeload.toString(), contains('microdeload'));
    });
  });

  group('MuscleDecision Edge Cases', () {
    test('should keep defaults for optional fields', () {
      const decision = MuscleDecision(
        muscle: 'biceps',
        action: VolumeAction.maintain,
        newVolume: 12,
        newPhase: ProgressionPhase.maintaining,
        reason: 'Maintaining',
        confidence: 0.75,
      );

      expect(decision.requiresMicrodeload, false);
      expect(decision.isNewCycle, false);
      expect(decision.exercisesToReplace, isEmpty);
    });
  });
}
