import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/muscle_priority_engine.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_split.dart';

void main() {
  group('MusclePriorityEngine priority fixtures regression baseline', () {
    test('fullBody with canonical priorities documents current order', () {
      final fixture = _loadFixture('muscle_priority_canonical.json');

      final order = _buildOrder(fixture);

      expect(order[1], [
        'pectorals',
        'quads',
        'lats',
        'glutes',
        'delts_lateral',
      ]);
      expect(order[2], [
        'quads',
        'lats',
        'pectorals',
        'glutes',
        'delts_lateral',
      ]);
      expect(order[3], [
        'lats',
        'pectorals',
        'quads',
        'glutes',
        'delts_lateral',
      ]);
    });

    test('fullBody with aliases documents legacy normalization', () {
      final fixture = _loadFixture('muscle_priority_alias.json');

      final order = _buildOrder(fixture);

      expect(order[1], ['pectorals', 'quads', 'delts_front', 'glutes']);
      expect(order[2], ['quads', 'pectorals', 'delts_front', 'glutes']);
      expect(_flatten(order), isNot(contains('chest')));
      expect(_flatten(order), isNot(contains('quadriceps')));
      expect(_flatten(order), isNot(contains('deltoide_anterior')));
      expect(_flatten(order), isNot(contains('gluteos')));
    });

    test('fullBody with unknowns discards non-strict muscle keys', () {
      final fixture = _loadFixture('muscle_priority_unknown.json');

      final order = _buildOrder(fixture);

      expect(order[1], isEmpty);
      expect(order[2], isEmpty);
      expect(_flatten(order), isNot(contains('unknown_muscle')));
      expect(_flatten(order), isNot(contains('back_mid_upper')));
      expect(_flatten(order), isNot(contains('mysterychest')));
      expect(_flatten(order), isNot(contains('glutes')));
      expect(_flatten(order), isNot(contains('glute')));
    });

    test('upperLower with unknowns documents allowlist filtering', () {
      final fixture = _loadFixture('muscle_priority_unknown.json');

      final order = _buildOrder(fixture, split: TrainingSplit.upperLower);

      expect(order[1], isEmpty);
      expect(order[2], isEmpty);
      expect(_flatten(order), isNot(contains('unknown_muscle')));
      expect(_flatten(order), isNot(contains('back_mid_upper')));
      expect(_flatten(order), isNot(contains('mysterychest')));
      expect(_flatten(order), isNot(contains('glute')));
    });

    test(
      'mixed priorities preserve duplicate overwrite and discard unknowns',
      () {
        final fixture = _loadFixture('muscle_priority_mixed.json');

        final order = _buildOrder(fixture);

        expect(order[1], ['pectorals', 'lats', 'quads']);
        expect(order[2], ['lats', 'pectorals', 'quads']);
        expect(order[3], ['pectorals', 'lats', 'quads']);
        expect(_flatten(order), isNot(contains('chest')));
        expect(_flatten(order), isNot(contains('quadriceps')));
        expect(_flatten(order), isNot(contains('glute')));
        expect(_flatten(order), isNot(contains('glutes')));
        expect(_flatten(order), isNot(contains('unknown_muscle')));
        expect(_flatten(order), isNot(contains('back_mid_upper')));
      },
    );

    test('pushPullLegs preserves fullBody style ordering without unknowns', () {
      final fixture = _loadFixture('muscle_priority_mixed.json');

      final order = _buildOrder(fixture, split: TrainingSplit.pushPullLegs);

      expect(order[1], ['pectorals', 'lats', 'quads']);
      expect(order[2], ['lats', 'pectorals', 'quads']);
      expect(order[3], ['pectorals', 'lats', 'quads']);
      expect(_flatten(order), isNot(contains('unknown_muscle')));
      expect(_flatten(order), isNot(contains('back_mid_upper')));
      expect(_flatten(order), isNot(contains('glute')));
    });
  });
}

Map<int, List<String>> _buildOrder(
  Map<String, dynamic> fixture, {
  TrainingSplit? split,
}) {
  return MusclePriorityEngine.buildDayMuscleOrder(
    split: split ?? _splitFromFixture(fixture),
    availableDays: (fixture['availableDays'] as num).toInt(),
    musclePriorities: _intMap(fixture['musclePriorities']),
    frequencyByMuscle: _intMap(fixture['frequencyByMuscle']),
  );
}

TrainingSplit _splitFromFixture(Map<String, dynamic> fixture) {
  return switch (fixture['split']) {
    'fullBody' => TrainingSplit.fullBody,
    'upperLower' => TrainingSplit.upperLower,
    'pushPullLegs' => TrainingSplit.pushPullLegs,
    final raw => throw StateError('Unsupported split fixture: $raw'),
  };
}

List<String> _flatten(Map<int, List<String>> order) {
  return order.values.expand((muscle) => muscle).toList();
}

Map<String, int> _intMap(dynamic raw) {
  return Map<String, dynamic>.from(
    raw as Map,
  ).map((key, value) => MapEntry(key, (value as num).toInt()));
}

Map<String, dynamic> _loadFixture(String fileName) {
  final file = File('test/fixtures/training_v3/muscle_priority/$fileName');
  final decoded = jsonDecode(file.readAsStringSync());
  return Map<String, dynamic>.from(decoded as Map);
}
