import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/domain/entities/training_plan_config.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/landmark_engine.dart';

void main() {
  group('LandmarkEngine TrainingProfile.extra regression baseline', () {
    test('canonical profile extra keeps canonical landmark keys', () {
      final profile = _profileFromExtraFixture(
        'profile_extra_landmarks_canonical.json',
      );

      final parsed = LandmarkEngine.parseByCanonicalKey(
        _muscleLandmarks(profile.extra),
      );
      final vopByMuscle = LandmarkEngine.extractVopByCanonicalKey(
        _muscleLandmarks(profile.extra),
      );

      expect(
        parsed.keys,
        containsAll(['pectorals', 'lats', 'quads', 'glutes']),
      );
      expect(parsed['pectorals']!.vme, 10);
      expect(parsed['pectorals']!.vop, 14);
      expect(parsed['pectorals']!.vmr, 20);
      expect(parsed['pectorals']!.vmrExtended, 22);
      expect(vopByMuscle['pectorals'], 14);
      expect(vopByMuscle['lats'], 12);
      expect(vopByMuscle['quads'], 18);
      expect(vopByMuscle['glutes'], 15);
    });

    test('alias profile extra documents legacy alias normalization', () {
      final profile = _profileFromExtraFixture(
        'profile_extra_landmarks_alias.json',
      );

      final parsed = LandmarkEngine.parseByCanonicalKey(
        _muscleLandmarks(profile.extra),
      );

      expect(
        parsed.keys,
        containsAll(['pectorals', 'quads', 'delts_front', 'glutes']),
      );
      expect(parsed.keys, isNot(contains('chest')));
      expect(parsed.keys, isNot(contains('quadriceps')));
      expect(parsed.keys, isNot(contains('deltoide_anterior')));
      expect(parsed.keys, isNot(contains('gluteos')));
      expect(parsed['pectorals']!.vop, 14);
      expect(parsed['quads']!.vop, 18);
      expect(parsed['delts_front']!.vop, 8);
      expect(parsed['glutes']!.vop, 15);
    });

    test('unknown profile extra discards non-strict muscle keys', () {
      final profile = _profileFromExtraFixture(
        'profile_extra_landmarks_unknown.json',
      );

      final parsed = LandmarkEngine.parseByCanonicalKey(
        _muscleLandmarks(profile.extra),
      );
      final vopByMuscle = LandmarkEngine.extractVopByCanonicalKey(
        _muscleLandmarks(profile.extra),
      );

      expect(parsed.keys, isNot(contains('unknown_muscle')));
      expect(parsed.keys, isNot(contains('back_mid_upper')));
      expect(parsed.keys, isNot(contains('mysterychest')));
      expect(parsed.keys, isNot(contains('glutes')));
      expect(parsed.keys, isNot(contains('glute')));
      expect(vopByMuscle.keys, isNot(contains('unknown_muscle')));
      expect(vopByMuscle.keys, isNot(contains('back_mid_upper')));
      expect(vopByMuscle.keys, isNot(contains('mysterychest')));
      expect(vopByMuscle.keys, isNot(contains('glutes')));
      expect(vopByMuscle.keys, isNot(contains('glute')));
    });

    test('mixed profile extra keeps valid keys and discards unknowns', () {
      final profile = _profileFromExtraFixture(
        'profile_extra_landmarks_mixed.json',
      );

      final parsed = LandmarkEngine.parseByCanonicalKey(
        _muscleLandmarks(profile.extra),
      );
      final vopByMuscle = LandmarkEngine.extractVopByCanonicalKey(
        _muscleLandmarks(profile.extra),
      );

      expect(parsed.keys, containsAll(['pectorals', 'quads', 'delts_front']));
      expect(parsed.keys, isNot(contains('glutes')));
      expect(parsed.keys, isNot(contains('unknown_muscle')));
      expect(parsed.keys, isNot(contains('back_mid_upper')));
      expect(parsed.keys, isNot(contains('chest')));
      expect(parsed.keys, isNot(contains('glute')));
      expect(parsed['pectorals']!.vme, 11);
      expect(parsed['pectorals']!.vop, 15);
      expect(parsed['pectorals']!.vmr, 21);
      expect(vopByMuscle['pectorals'], 15);
      expect(vopByMuscle.keys, isNot(contains('unknown_muscle')));
      expect(vopByMuscle.keys, isNot(contains('back_mid_upper')));
      expect(vopByMuscle.keys, isNot(contains('glute')));
    });

    test('frozen plan snapshot exposes profile extra landmarks', () {
      final plan = _loadFrozenPlanConfig(
        'frozen_plan_config_with_training_profile_snapshot.json',
      );
      final extra = plan.trainingProfileSnapshotExtra!;
      final landmarks = _muscleLandmarks(extra);

      final vopByMuscle = LandmarkEngine.extractVopByCanonicalKey(landmarks);

      expect(plan.trainingProfileSnapshot, isNotNull);
      expect(extra[TrainingExtraKeys.muscleLandmarks], isA<Map>());
      expect(vopByMuscle['pectorals'], 15);
      expect(vopByMuscle['quads'], 18);
      expect(vopByMuscle['delts_front'], 8);
      expect(vopByMuscle.keys, isNot(contains('glutes')));
      expect(vopByMuscle.keys, isNot(contains('unknown_muscle')));
      expect(vopByMuscle.keys, isNot(contains('back_mid_upper')));
      expect(vopByMuscle.keys, isNot(contains('glute')));
    });
  });
}

TrainingProfile _profileFromExtraFixture(String fileName) {
  final extra = _loadProfileExtra(fileName);
  return TrainingProfile.fromJson({
    'id': 'fixture-profile',
    'date': '2026-01-01T00:00:00.000Z',
    'trainingLevel': 'intermediate',
    'daysPerWeek': extra['daysPerWeek'],
    'timePerSessionMinutes': extra['timePerSessionMinutes'],
    'sessionDurationMinutes': extra['timePerSessionMinutes'],
    'restBetweenSetsSeconds': 120,
    'equipment': const ['barbell', 'dumbbell', 'machine', 'cable'],
    'movementRestrictions': const <String>[],
    'priorityMusclesPrimary': extra['priorityMusclesPrimary'],
    'priorityMusclesSecondary': extra['priorityMusclesSecondary'],
    'priorityMusclesTertiary': extra['priorityMusclesTertiary'],
    'baseVolumePerMuscle': extra[TrainingExtraKeys.vopSnapshot] is Map
        ? (extra[TrainingExtraKeys.vopSnapshot]
                  as Map<String, dynamic>)['totalSetsByMuscle'] ??
              const <String, int>{}
        : const <String, int>{},
    'seriesDistribution': const <String, dynamic>{},
    'pastVolumeTolerance': const <String, dynamic>{},
    'blockLengthWeeks': extra['planDurationInWeeks'],
    'currentWeekIndex': 0,
    'extra': extra,
  });
}

Map<String, dynamic> _loadProfileExtra(String fileName) {
  return _loadJson('test/fixtures/training_v3/profile_extra/$fileName');
}

TrainingPlanConfig _loadFrozenPlanConfig(String fileName) {
  return TrainingPlanConfig.fromJson(
    _loadJson('test/fixtures/training_v3/frozen_plan/$fileName'),
  );
}

Map<String, dynamic> _muscleLandmarks(Map<String, dynamic> extra) {
  return Map<String, dynamic>.from(
    extra[TrainingExtraKeys.muscleLandmarks] as Map,
  );
}

Map<String, dynamic> _loadJson(String path) {
  final decoded = jsonDecode(File(path).readAsStringSync());
  return Map<String, dynamic>.from(decoded as Map);
}
