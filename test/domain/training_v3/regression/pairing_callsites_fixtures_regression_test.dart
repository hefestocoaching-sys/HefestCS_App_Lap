import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/policies/pairing_contract.dart';
import 'package:hcs_app_lap/domain/training_v3/data/interference_matrix.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/antagonist_pairing_engine.dart';
import 'package:hcs_app_lap/core/registry/muscle_registry.dart'
    as muscle_registry;

void main() {
  group('Pairing call sites D1R8 fixtures', () {
    for (final fixtureName in _fixtureNames) {
      test(fixtureName, () {
        final fixture = _loadFixture(fixtureName);
        final cases = List<Map<String, dynamic>>.from(
          (fixture['cases'] as List).map(
            (raw) => Map<String, dynamic>.from(raw as Map),
          ),
        );

        for (final fixtureCase in cases) {
          final input = Map<String, dynamic>.from(fixtureCase['input'] as Map);
          final actual = _snapshot(input);
          final expected = Map<String, dynamic>.from(
            fixtureCase['expected'] as Map,
          );

          expect(actual, expected, reason: fixtureCase['id'] as String);
        }
      });
    }

    test(
      'CycleTemplateBuilder still normalizes glute before strict helpers',
      () {
        final actual = _snapshot({
          'firstPrimaryMuscle': 'glute',
          'secondPrimaryMuscle': 'quads',
        });

        expect(actual['directHelpers'], {
          'pairingType': 'none',
          'isAllowedBiserie': false,
          'areAntagonists': false,
        });
        expect(actual['normalization'], containsPair('first', 'glutes'));
        expect(
          actual['cycleTemplateProxy'],
          containsPair('pairingType', 'synergy'),
        );
      },
    );

    test('CycleTemplateBuilder proxy keeps group behavior observable', () {
      final actual = _snapshot({
        'firstPrimaryMuscle': 'back',
        'secondPrimaryMuscle': 'pectorals',
      });

      expect(actual['directHelpers'], {
        'pairingType': 'antagonist',
        'isAllowedBiserie': true,
        'areAntagonists': true,
      });
      expect(actual['normalization'], containsPair('first', 'back'));
      expect(
        actual['cycleTemplateProxy'],
        containsPair('orderedMuscles', ['back', 'pectorals']),
      );
    });
  });
}

const _fixtureNames = <String>[
  'pairing_callsites_cycle_template_canonical.json',
  'pairing_callsites_cycle_template_alias.json',
  'pairing_callsites_cycle_template_unknown.json',
  'pairing_callsites_cycle_template_group.json',
  'pairing_callsites_cycle_template_mixed.json',
  'pairing_callsites_biserie_cases.json',
  'pairing_callsites_order_cases.json',
];

Map<String, dynamic> _snapshot(Map<String, dynamic> input) {
  final firstRaw = input['firstPrimaryMuscle'] as String;
  final secondRaw = input['secondPrimaryMuscle'] as String;
  final dayRaw = input['dayMuscles'] is List
      ? List<String>.from(input['dayMuscles'] as List)
      : <String>[firstRaw, secondRaw];
  final primaryRaw = input['primaryMuscle'] as String? ?? firstRaw;

  final normalizedFirst =
      muscle_registry.tryNormalizeMuscleKey(firstRaw) ?? firstRaw;
  final normalizedSecond =
      muscle_registry.tryNormalizeMuscleKey(secondRaw) ?? secondRaw;
  final normalizedDay = dayRaw
      .map((d) => muscle_registry.tryNormalizeMuscleKey(d) ?? d)
      .toList();
  final primaryMuscle =
      muscle_registry.tryNormalizeMuscleKey(primaryRaw) ?? primaryRaw;
  final orderedMuscles = _orderMusclesByBlockPriority(
    normalizedDay,
    primaryMuscle: primaryMuscle,
  );
  final blockPlan = _buildDayBlockMusclePlan(
    orderedMuscles,
    primaryMuscle: primaryMuscle,
  );

  return <String, dynamic>{
    'normalization': <String, dynamic>{
      'first': normalizedFirst,
      'second': normalizedSecond,
      'dayMuscles': normalizedDay,
      'primaryMuscle': primaryMuscle,
    },
    'directHelpers': _helperSnapshot(firstRaw, secondRaw),
    'cycleTemplateProxy': <String, dynamic>{
      ..._helperSnapshot(normalizedFirst, normalizedSecond),
      'isLowInterference': _isLowInterference(
        normalizedFirst,
        normalizedSecond,
      ),
      'orderedMuscles': orderedMuscles,
      'blockPlan': blockPlan,
    },
  };
}

Map<String, dynamic> _helperSnapshot(String first, String second) {
  final type = PairingContract.classify(
    firstPrimaryMuscle: first,
    secondPrimaryMuscle: second,
  );
  return <String, dynamic>{
    'pairingType': type.name,
    'isAllowedBiserie': PairingContract.isAllowedBiserie(
      firstPrimaryMuscle: first,
      secondPrimaryMuscle: second,
    ),
    'areAntagonists': AntagonistPairingEngine.areAntagonists(first, second),
  };
}

List<String> _orderMusclesByBlockPriority(
  List<String> muscles, {
  required String primaryMuscle,
}) {
  return List<String>.from(muscles)..sort((a, b) {
    if (a == primaryMuscle) return -1;
    if (b == primaryMuscle) return 1;
    final aIsAntagonist = AntagonistPairingEngine.areAntagonists(
      primaryMuscle,
      a,
    );
    final bIsAntagonist = AntagonistPairingEngine.areAntagonists(
      primaryMuscle,
      b,
    );
    if (aIsAntagonist && !bIsAntagonist) return -1;
    if (!aIsAntagonist && bIsAntagonist) return 1;
    final aIsLow = _isLowInterference(primaryMuscle, a);
    final bIsLow = _isLowInterference(primaryMuscle, b);
    if (aIsLow && !bIsLow) return -1;
    if (!aIsLow && bIsLow) return 1;
    return 0;
  });
}

Map<String, List<String>> _buildDayBlockMusclePlan(
  List<String> orderedMuscles, {
  required String primaryMuscle,
}) {
  final plan = <String, List<String>>{
    'A': <String>[],
    'B': <String>[],
    'C': <String>[],
    'D': <String>[],
  };
  if (orderedMuscles.isEmpty) return plan;

  final remaining = <String>[...orderedMuscles];
  remaining.remove(primaryMuscle);
  plan['A']!.add(primaryMuscle);

  final bCandidates = remaining.where((m) {
    return PairingContract.isAllowedBiserie(
          firstPrimaryMuscle: primaryMuscle,
          secondPrimaryMuscle: m,
        ) &&
        (AntagonistPairingEngine.areAntagonists(primaryMuscle, m) ||
            _isLowInterference(primaryMuscle, m));
  }).toList();
  for (final muscle in bCandidates.take(2)) {
    plan['B']!.add(muscle);
    remaining.remove(muscle);
  }

  final cCandidates = remaining.where((m) {
    if (_isAccessoryMuscle(m)) return false;
    return !plan['B']!.any((b) => AntagonistPairingEngine.areAntagonists(b, m));
  }).toList();
  for (final muscle in cCandidates.take(2)) {
    plan['C']!.add(muscle);
    remaining.remove(muscle);
  }

  plan['D']!.addAll(remaining);
  return plan;
}

bool _isLowInterference(String a, String b) {
  final lowA = InterferenceMatrix.lowInterference[a] ?? const <String>[];
  final lowB = InterferenceMatrix.lowInterference[b] ?? const <String>[];
  return lowA.contains(b) || lowB.contains(a);
}

bool _isAccessoryMuscle(String muscle) {
  return muscle == 'calves' ||
      muscle == 'abs' ||
      muscle == 'biceps' ||
      muscle == 'triceps' ||
      muscle == 'traps';
}

Map<String, dynamic> _loadFixture(String fileName) {
  final file = File('test/fixtures/training_v3/pairing_callsites/$fileName');
  final decoded = jsonDecode(file.readAsStringSync());
  return Map<String, dynamic>.from(decoded as Map);
}
