import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/core/enums/muscle_group.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/landmark_engine.dart';

void main() {
  group('LandmarkEngine current behavior baseline', () {
    test('parseByCanonicalKey keeps canonical keys', () {
      final raw = _loadLandmarks('canonical_landmarks_extra.json');

      final parsed = LandmarkEngine.parseByCanonicalKey(raw);

      expect(
        parsed.keys,
        containsAll(['pectorals', 'lats', 'quads', 'glutes']),
      );
      expect(parsed['pectorals']!.vme, 10);
      expect(parsed['pectorals']!.vop, 14);
      expect(parsed['pectorals']!.vmr, 20);
      expect(parsed['pectorals']!.vmrExtended, 22);
    });

    test('parseByCanonicalKey normalizes supported aliases today', () {
      final raw = _loadLandmarks('alias_landmarks_extra.json');

      final parsed = LandmarkEngine.parseByCanonicalKey(raw);

      expect(
        parsed.keys,
        containsAll(['pectorals', 'quads', 'delts_front', 'glutes']),
      );
      expect(parsed.keys, isNot(contains('chest')));
      expect(parsed.keys, isNot(contains('quadriceps')));
      expect(parsed.keys, isNot(contains('deltoide_anterior')));
      expect(parsed.keys, isNot(contains('gluteos')));
      expect(parsed['delts_front']!.vop, 8);
    });

    test('parseByCanonicalKey discards non-strict unknown keys', () {
      final raw = _loadLandmarks('unknown_landmarks_extra.json');

      final parsed = LandmarkEngine.parseByCanonicalKey(raw);

      expect(parsed.keys, isNot(contains('unknown_muscle')));
      expect(parsed.keys, isNot(contains('back_mid_upper')));
      expect(parsed.keys, isNot(contains('mysterychest')));
      expect(parsed.keys, isNot(contains('glutes')));
      expect(parsed.keys, isNot(contains('glute')));
    });

    test('serializeByCanonicalKey normalizes enum canonical keys today', () {
      final serialized = LandmarkEngine.serializeByCanonicalKey({
        MuscleGroup.chest: const Landmarks(vme: 10, vop: 14, vmr: 20),
        MuscleGroup.quads: const Landmarks(vme: 12, vop: 18, vmr: 24),
        MuscleGroup.shoulderAnterior: const Landmarks(vme: 5, vop: 8, vmr: 10),
      });

      expect(
        serialized.keys,
        containsAll(['pectorals', 'quads', 'delts_front']),
      );
      expect(serialized.keys, isNot(contains('chest')));
      expect(serialized.keys, isNot(contains('deltoide_anterior')));
      expect(serialized['pectorals']!['vop'], 14);
    });

    test(
      'extractVopByCanonicalKey normalizes aliases and discards unknowns',
      () {
        final raw = _loadLandmarks('mixed_landmarks_extra.json');

        final vopByMuscle = LandmarkEngine.extractVopByCanonicalKey(raw);

        expect(vopByMuscle['pectorals'], 15);
        expect(vopByMuscle['quads'], 18);
        expect(vopByMuscle['delts_front'], 8);
        expect(vopByMuscle.keys, isNot(contains('glutes')));
        expect(vopByMuscle.keys, isNot(contains('unknown_muscle')));
        expect(vopByMuscle.keys, isNot(contains('back_mid_upper')));
        expect(vopByMuscle.keys, isNot(contains('mysterychest')));
        expect(vopByMuscle.keys, isNot(contains('chest')));
        expect(vopByMuscle.keys, isNot(contains('glute')));
      },
    );
  });
}

Map<String, dynamic> _loadLandmarks(String fileName) {
  final file = File('test/fixtures/training_v3/landmarks/$fileName');
  final decoded = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return Map<String, dynamic>.from(
    decoded[TrainingExtraKeys.muscleLandmarks] as Map,
  );
}
