import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/policies/pairing_contract.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/antagonist_pairing_engine.dart';

void main() {
  group('Pairing helpers D1-C7 strict fixtures', () {
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
          final first = input['firstPrimaryMuscle'] as String;
          final second = input['secondPrimaryMuscle'] as String;

          final actual = _snapshot(first: first, second: second);
          final expected = Map<String, dynamic>.from(
            fixtureCase['expected'] as Map,
          );

          expect(actual, expected, reason: fixtureCase['id'] as String);
        }
      });
    }

    test('glute is strict unknown and does not pair as glutes', () {
      final actual = _snapshot(first: 'glute', second: 'quads');

      expect(actual['pairingContract'], {
        'type': 'none',
        'isAllowedBiserie': false,
      });
      expect(actual['antagonistPairingEngine'], {'areAntagonists': false});
    });

    test('group behavior is strict and consistent for antagonists', () {
      final actual = _snapshot(first: 'back', second: 'pectorals');

      expect(actual['pairingContract'], {
        'type': 'antagonist',
        'isAllowedBiserie': true,
      });
      expect(actual['antagonistPairingEngine'], {'areAntagonists': true});
    });

    test('strict unknowns do not pass through into pairing rules', () {
      final unknowns = ['unknown_muscle', 'back_mid_upper', 'mysterychest'];

      for (final unknown in unknowns) {
        final actual = _snapshot(first: unknown, second: 'lats');

        expect(actual['pairingContract'], {
          'type': 'none',
          'isAllowedBiserie': false,
        });
        expect(actual['antagonistPairingEngine'], {'areAntagonists': false});
      }
    });

    test('isAllowedBiserie preserves allowed and rejected pairing types', () {
      expect(
        PairingContract.isAllowedBiserie(
          firstPrimaryMuscle: 'pectorals',
          secondPrimaryMuscle: 'lats',
        ),
        isTrue,
      );
      expect(
        PairingContract.isAllowedBiserie(
          firstPrimaryMuscle: 'pectorals',
          secondPrimaryMuscle: 'triceps',
        ),
        isTrue,
      );
      expect(
        PairingContract.isAllowedBiserie(
          firstPrimaryMuscle: 'pectorals',
          secondPrimaryMuscle: 'calves',
        ),
        isTrue,
      );
      expect(
        PairingContract.isAllowedBiserie(
          firstPrimaryMuscle: 'pectorals',
          secondPrimaryMuscle: 'chest',
        ),
        isFalse,
      );
      expect(
        PairingContract.isAllowedBiserie(
          firstPrimaryMuscle: 'unknown_muscle',
          secondPrimaryMuscle: 'lats',
        ),
        isFalse,
      );
    });
  });
}

const _fixtureNames = <String>[
  'pairing_helpers_canonical.json',
  'pairing_helpers_alias.json',
  'pairing_helpers_unknown.json',
  'pairing_helpers_mixed.json',
  'pairing_helpers_group_cases.json',
  'pairing_helpers_symmetry_cases.json',
  'pairing_helpers_interference_cases.json',
];

Map<String, dynamic> _snapshot({
  required String first,
  required String second,
}) {
  final type = PairingContract.classify(
    firstPrimaryMuscle: first,
    secondPrimaryMuscle: second,
  );
  final isAllowedBiserie = PairingContract.isAllowedBiserie(
    firstPrimaryMuscle: first,
    secondPrimaryMuscle: second,
  );
  final areAntagonists = AntagonistPairingEngine.areAntagonists(first, second);

  return <String, dynamic>{
    'pairingContract': <String, dynamic>{
      'type': type.name,
      'isAllowedBiserie': isAllowedBiserie,
    },
    'antagonistPairingEngine': <String, dynamic>{
      'areAntagonists': areAntagonists,
    },
  };
}

Map<String, dynamic> _loadFixture(String fileName) {
  final file = File('test/fixtures/training_v3/pairing_helpers/$fileName');
  final decoded = jsonDecode(file.readAsStringSync());
  return Map<String, dynamic>.from(decoded as Map);
}
