import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/weekly_volume_planner.dart';

void main() {
  group('WeeklyVolumePlanner fixtures regression baseline', () {
    test('canonical week 1 returns base VOP and preserves keys', () {
      final fixture = _loadFixture('weekly_volume_canonical.json');

      final weekOne = _buildWeek(fixture, weekNumber: 1);

      expect(weekOne, {'pectorals': 10, 'lats': 12, 'quads': 14, 'glutes': 13});
    });

    test('canonical accumulation progression is frozen for weeks 2 to 4', () {
      final fixture = _loadFixture('weekly_volume_canonical.json');

      final weekTwo = _buildWeek(fixture, weekNumber: 2);
      final weekThree = _buildWeek(fixture, weekNumber: 3);
      final weekFour = _buildWeek(fixture, weekNumber: 4);

      expect(weekTwo, {'pectorals': 10, 'lats': 12, 'quads': 14, 'glutes': 13});
      expect(weekThree, {
        'pectorals': 13,
        'lats': 14,
        'quads': 15,
        'glutes': 15,
      });
      expect(weekFour, {
        'pectorals': 13,
        'lats': 14,
        'quads': 15,
        'glutes': 15,
      });
    });

    test('aliases normalize to canonical keys', () {
      final fixture = _loadFixture('weekly_volume_alias.json');

      final weekOne = _buildWeek(fixture, weekNumber: 1);
      final weekThree = _buildWeek(fixture, weekNumber: 3);

      expect(
        weekOne.keys,
        containsAll(['pectorals', 'quads', 'glutes', 'delts_front']),
      );
      expect(weekOne.keys, isNot(contains('chest')));
      expect(weekOne.keys, isNot(contains('quadriceps')));
      expect(weekOne.keys, isNot(contains('gluteos')));
      expect(weekOne.keys, isNot(contains('deltoide_anterior')));
      expect(weekThree, {
        'pectorals': 13,
        'quads': 15,
        'glutes': 15,
        'delts_front': 10,
      });
    });

    test('unknowns are discarded', () {
      final fixture = _loadFixture('weekly_volume_unknown.json');

      final weekOne = _buildWeek(fixture, weekNumber: 1);
      final weekThree = _buildWeek(fixture, weekNumber: 3);

      expect(weekOne, isEmpty);
      expect(weekThree, isEmpty);
    });

    test('mixed fixture normalizes aliases and discards unknowns', () {
      final fixture = _loadFixture('weekly_volume_mixed.json');

      final weekOne = _buildWeek(fixture, weekNumber: 1);
      final weekThree = _buildWeek(fixture, weekNumber: 3);

      expect(weekOne.keys, containsAll(['pectorals', 'lats', 'quads']));
      expect(weekOne['pectorals'], 11);
      expect(weekOne.keys, isNot(contains('chest')));
      expect(weekOne.keys, isNot(contains('unknown_muscle')));
      expect(weekOne.keys, isNot(contains('glute')));
      expect(weekOne.keys, isNot(contains('back_mid_upper')));
      expect(weekThree, {'pectorals': 14, 'lats': 14, 'quads': 15});
    });

    test('MEV and MRV boundaries are frozen', () {
      final fixture = _loadFixture('weekly_volume_progression_cases.json');

      final weekOne = _buildWeek(fixture, weekNumber: 1);
      final weekTwo = _buildWeek(fixture, weekNumber: 2);
      final weekThree = _buildWeek(fixture, weekNumber: 3);
      final weekFour = _buildWeek(fixture, weekNumber: 4);

      expect(weekOne['calves'], 4);
      expect(weekTwo['calves'], 8);
      expect(weekThree['calves'], 8);
      expect(weekFour['calves'], 8);

      expect(weekTwo['glutes'], 19);
      expect(weekThree['glutes'], 19);
      expect(weekFour['glutes'], 19);

      expect(weekThree['pectorals'], 13);
      expect(weekThree['lats'], 12);
      expect(weekThree['quads'], 11);
    });

    test('intensification and deload phase formulas are frozen', () {
      final fixture = _loadFixture('weekly_volume_progression_cases.json');
      final phaseCases = Map<String, dynamic>.from(
        fixture['phaseCases'] as Map,
      );

      final intensification = _buildWeek(
        Map<String, dynamic>.from(phaseCases['intensification'] as Map),
        phase: 'intensification',
        trainingLevel: fixture['trainingLevel'] as String,
      );
      final deload = _buildWeek(
        Map<String, dynamic>.from(phaseCases['deload'] as Map),
        phase: 'deload',
        trainingLevel: fixture['trainingLevel'] as String,
      );

      expect(intensification, {'lats': 13});
      expect(deload, {'lats': 12});
    });

    test('decision trace stores canonical keys and drops raw inputs', () {
      final fixture = _loadFixture('weekly_volume_mixed.json');

      _buildWeek(fixture, weekNumber: 1);
      _buildWeek(fixture, weekNumber: 3);

      final trace = WeeklyVolumePlanner.buildDecisionTrace();
      final baseVop = Map<String, dynamic>.from(trace['baseVop'] as Map);
      final weekVolumes = Map<dynamic, dynamic>.from(
        trace['weekVolumes'] as Map,
      );
      final weekDecisions = Map<dynamic, dynamic>.from(
        trace['weekDecisions'] as Map,
      );
      final weekOne = Map<dynamic, dynamic>.from(weekVolumes['1'] as Map);
      final weekThree = Map<dynamic, dynamic>.from(weekVolumes['3'] as Map);
      final weekThreeDecisions = Map<dynamic, dynamic>.from(
        weekDecisions['3'] as Map,
      );

      expect(baseVop, {'pectorals': 11, 'lats': 12, 'quads': 14});
      expect(weekOne, {'pectorals': 11, 'lats': 12, 'quads': 14});
      expect(weekThree, {'pectorals': 14, 'lats': 14, 'quads': 15});
      expect(
        weekThreeDecisions['pectorals'],
        contains('Accumulation (P5): +3 sets'),
      );
      expect(
        weekThreeDecisions['lats'],
        contains('Accumulation (P3-4): +2 sets'),
      );
      expect(
        weekThreeDecisions['quads'],
        contains('Accumulation (P2): +1 set'),
      );
      for (final raw in [
        'chest',
        'quadriceps',
        'unknown_muscle',
        'glute',
        'back_mid_upper',
      ]) {
        expect(baseVop.keys, isNot(contains(raw)));
        expect(weekOne.keys, isNot(contains(raw)));
        expect(weekThree.keys, isNot(contains(raw)));
        expect(weekThreeDecisions.keys, isNot(contains(raw)));
      }
    });
  });
}

Map<String, int> _buildWeek(
  Map<String, dynamic> fixture, {
  int? weekNumber,
  String? phase,
  String? trainingLevel,
}) {
  return WeeklyVolumePlanner.buildWeekVolume(
    baseVop: _intMap(fixture['baseVop']),
    mevByMuscle: _intMap(fixture['mevByMuscle']),
    mrvByMuscle: _intMap(fixture['mrvByMuscle']),
    priorities: _intMap(fixture['priorities']),
    trainingLevel: trainingLevel ?? fixture['trainingLevel'] as String,
    weekNumber: weekNumber ?? (fixture['weekNumber'] as num).toInt(),
    phase: phase ?? fixture['phase'] as String? ?? 'accumulation',
    feedback: fixture['feedback'] is Map
        ? Map<String, dynamic>.from(fixture['feedback'] as Map)
        : const <String, dynamic>{},
  );
}

Map<String, int> _intMap(dynamic raw) {
  return Map<String, dynamic>.from(
    raw as Map,
  ).map((key, value) => MapEntry(key, (value as num).toInt()));
}

Map<String, dynamic> _loadFixture(String fileName) {
  final file = File('test/fixtures/training_v3/weekly_volume/$fileName');
  final decoded = jsonDecode(file.readAsStringSync());
  return Map<String, dynamic>.from(decoded as Map);
}
