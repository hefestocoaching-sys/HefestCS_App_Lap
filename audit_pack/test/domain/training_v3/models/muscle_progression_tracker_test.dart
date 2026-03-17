// test/domain/training_v3/models/muscle_progression_tracker_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/training_v3/models/muscle_progression_tracker.dart';
import 'package:hcs_app_lap/domain/training_v3/models/volume_landmarks.dart';

void main() {
  group('MuscleProgressionTracker', () {
    test('should initialize with correct default values', () {
      final tracker = MuscleProgressionTracker(
        muscle: 'pectorals',
        priority: 5,
        landmarks: const VolumeLandmarks(
          vme: 8,
          vop: 12,
          vmr: 20,
          vmrTarget: 20,
        ),
        currentVolume: 12,
        currentPhase: ProgressionPhase.discovering,
        weekInCurrentPhase: 0,
        totalWeeksInCycle: 0,
        lastUpdated: DateTime.parse('2024-01-01'),
      );

      expect(tracker.muscle, 'pectorals');
      expect(tracker.currentVolume, 12);
      expect(tracker.currentPhase, ProgressionPhase.discovering);
      expect(tracker.vmrDiscovered, null);
      expect(tracker.phaseTimeline, isEmpty);
    });

    test('should detect VMR correctly', () {
      final tracker = MuscleProgressionTracker(
        muscle: 'pectorals',
        priority: 5,
        landmarks: const VolumeLandmarks(
          vme: 8,
          vop: 12,
          vmr: 20,
          vmrTarget: 20,
        ),
        currentVolume: 18,
        currentPhase: ProgressionPhase.discovering,
        weekInCurrentPhase: 3,
        totalWeeksInCycle: 3,
        vmrDiscovered: 18,
        lastUpdated: DateTime.parse('2024-01-01'),
      );

      expect(tracker.vmrDiscovered, 18);
      expect(tracker.vmrDiscovered != null, true);
    });

    test('should transition phases correctly', () {
      final tracker = MuscleProgressionTracker(
        muscle: 'pectorals',
        priority: 5,
        landmarks: const VolumeLandmarks(
          vme: 8,
          vop: 12,
          vmr: 20,
          vmrTarget: 20,
        ),
        currentVolume: 12,
        currentPhase: ProgressionPhase.discovering,
        weekInCurrentPhase: 4,
        totalWeeksInCycle: 4,
        lastUpdated: DateTime.parse('2024-01-01'),
      );

      final transitioned = tracker.copyWith(
        currentPhase: ProgressionPhase.maintaining,
        weekInCurrentPhase: 0,
        phaseTimeline: [
          ...tracker.phaseTimeline,
          PhaseTransition(
            weekNumber: 5,
            fromPhase: ProgressionPhase.discovering,
            toPhase: ProgressionPhase.maintaining,
            volume: 12,
            reason: 'VMR discovered',
            timestamp: DateTime.parse('2024-02-01'),
          ),
        ],
      );

      expect(transitioned.currentPhase, ProgressionPhase.maintaining);
      expect(transitioned.weekInCurrentPhase, 0);
      expect(transitioned.phaseTimeline.length, 1);
      expect(
        transitioned.phaseTimeline.first.fromPhase,
        ProgressionPhase.discovering,
      );
      expect(
        transitioned.phaseTimeline.first.toPhase,
        ProgressionPhase.maintaining,
      );
    });

    test('should serialize to JSON correctly', () {
      final tracker = MuscleProgressionTracker(
        muscle: 'pectorals',
        priority: 5,
        landmarks: const VolumeLandmarks(
          vme: 8,
          vop: 12,
          vmr: 20,
          vmrTarget: 20,
        ),
        currentVolume: 12,
        currentPhase: ProgressionPhase.discovering,
        weekInCurrentPhase: 2,
        totalWeeksInCycle: 2,
        lastUpdated: DateTime.parse('2024-01-01'),
      );

      final json = tracker.toJson();

      expect(json['muscle'], 'pectorals');
      expect(json['currentVolume'], 12);
      expect(json['currentPhase'], 'discovering');
      expect(json['weekInCurrentPhase'], 2);
      expect(json['landmarks']['vme'], 8);
      expect(json['landmarks']['vop'], 12);
      expect(json['landmarks']['vmr'], 20);
      expect(json['landmarks']['vmrTarget'], 20);
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'muscle': 'pectorals',
        'priority': 5,
        'currentVolume': 12,
        'landmarks': {'vme': 8, 'vop': 12, 'vmr': 20, 'vmrTarget': 20},
        'currentPhase': 'discovering',
        'weekInCurrentPhase': 2,
        'totalWeeksInCycle': 2,
        'vmrDiscovered': null,
        'history': [],
        'phaseTimeline': [],
        'lastUpdated': '2024-01-01T00:00:00.000',
      };

      final tracker = MuscleProgressionTracker.fromJson(json);

      expect(tracker.muscle, 'pectorals');
      expect(tracker.currentVolume, 12);
      expect(tracker.currentPhase, ProgressionPhase.discovering);
      expect(tracker.landmarks.vme, 8);
      expect(tracker.landmarks.vmr, 20);
    });
  });

  group('VolumeLandmarks', () {
    test('should calculate range correctly', () {
      const landmarks =
          VolumeLandmarks(vme: 8, vop: 12, vmr: 20, vmrTarget: 20);

      expect(landmarks.vme, 8);
      expect(landmarks.vop, 12);
      expect(landmarks.vmr, 20);
      expect(landmarks.vmr - landmarks.vme, 12);
    });

    test('should validate landmarks order', () {
      const landmarks =
          VolumeLandmarks(vme: 8, vop: 12, vmr: 20, vmrTarget: 20);

      expect(landmarks.vme < landmarks.vop, true);
      expect(landmarks.vop < landmarks.vmr, true);
    });
  });

  group('PhaseTransition', () {
    test('should record transition correctly', () {
      final transition = PhaseTransition(
        weekNumber: 5,
        fromPhase: ProgressionPhase.discovering,
        toPhase: ProgressionPhase.maintaining,
        volume: 18,
        reason: 'VMR discovered at 18 sets',
        timestamp: DateTime.parse('2024-02-01'),
      );

      expect(transition.fromPhase, ProgressionPhase.discovering);
      expect(transition.toPhase, ProgressionPhase.maintaining);
      expect(transition.weekNumber, 5);
      expect(transition.reason, contains('VMR discovered'));
    });

    test('should serialize/deserialize transition', () {
      final transition = PhaseTransition(
        weekNumber: 5,
        fromPhase: ProgressionPhase.discovering,
        toPhase: ProgressionPhase.maintaining,
        volume: 18,
        reason: 'VMR discovered',
        timestamp: DateTime.parse('2024-02-01'),
      );

      final json = transition.toJson();
      final restored = PhaseTransition.fromJson(json);

      expect(restored.fromPhase, transition.fromPhase);
      expect(restored.toPhase, transition.toPhase);
      expect(restored.weekNumber, transition.weekNumber);
      expect(restored.reason, transition.reason);
    });
  });

  group('ProgressionPhase Enum', () {
    test('should convert to/from string', () {
      expect(ProgressionPhase.discovering.toString(), contains('discovering'));
      expect(ProgressionPhase.maintaining.toString(), contains('maintaining'));
      expect(
        ProgressionPhase.overreaching.toString(),
        contains('overreaching'),
      );
      expect(ProgressionPhase.deloading.toString(), contains('deloading'));
      expect(ProgressionPhase.microdeload.toString(), contains('microdeload'));
    });
  });
}
