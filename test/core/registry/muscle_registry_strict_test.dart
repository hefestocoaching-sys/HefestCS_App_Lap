import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/core/registry/muscle_registry.dart' as registry;

void main() {
  const canonicalMuscles = [
    'pectorals',
    'lats',
    'upper_back',
    'traps',
    'delts_front',
    'delts_lateral',
    'delts_rear',
    'biceps',
    'triceps',
    'quads',
    'hamstrings',
    'glutes',
    'calves',
    'abs',
  ];

  group('MuscleRegistry strict API', () {
    test('canonical list is exact and ordered', () {
      expect(registry.canonicalMuscles.toList(), canonicalMuscles);
    });

    test('tryNormalizeMuscleKey returns canonical keys unchanged', () {
      for (final key in canonicalMuscles) {
        expect(registry.tryNormalizeMuscleKey(key), key);
      }
    });

    test('tryNormalizeMuscleKey resolves expected aliases', () {
      const aliases = {
        'chest': 'pectorals',
        'pectorales': 'pectorals',
        'quadriceps': 'quads',
        'quads': 'quads',
        'deltoide_anterior': 'delts_front',
        'deltoide_lateral': 'delts_lateral',
        'deltoide_posterior': 'delts_rear',
        'gluteos': 'glutes',
        'abdomen': 'abs',
      };

      for (final entry in aliases.entries) {
        expect(registry.tryNormalizeMuscleKey(entry.key), entry.value);
      }
    });

    test('tryNormalizeMuscleKey returns null for unknown keys', () {
      const unknownKeys = [
        '',
        ' ',
        'glute',
        'back_mid_upper',
        'unknown_muscle',
        'deltoides_random',
      ];

      for (final key in unknownKeys) {
        expect(registry.tryNormalizeMuscleKey(key), isNull);
      }
    });

    test('normalizeMuscleKeyOrThrow returns canonical key or throws', () {
      expect(registry.normalizeMuscleKeyOrThrow('chest'), 'pectorals');

      expect(
        () => registry.normalizeMuscleKeyOrThrow('unknown_muscle'),
        throwsA(
          isA<registry.UnknownMuscleKeyException>()
              .having((error) => error.rawValue, 'rawValue', 'unknown_muscle')
              .having(
                (error) => error.toString(),
                'toString',
                contains('unknown_muscle'),
              ),
        ),
      );
    });

    test('expandMuscleGroupStrict expands recognized groups', () {
      expect(registry.expandMuscleGroupStrict('back'), ['lats', 'upper_back']);
      expect(registry.expandMuscleGroupStrict('shoulders'), [
        'delts_front',
        'delts_lateral',
        'delts_rear',
      ]);
      expect(registry.expandMuscleGroupStrict('arms'), ['biceps', 'triceps']);
      expect(registry.expandMuscleGroupStrict('legs'), [
        'quads',
        'hamstrings',
        'glutes',
        'calves',
      ]);
    });

    test('expandMuscleGroupStrict handles individual aliases', () {
      expect(registry.expandMuscleGroupStrict('chest'), ['pectorals']);
      expect(registry.expandMuscleGroupStrict('deltoide_lateral'), [
        'delts_lateral',
      ]);
    });

    test('expandMuscleGroupStrict returns null for unknown keys', () {
      final expanded = registry.expandMuscleGroupStrict('unknown_muscle');

      expect(expanded, isNull);
      expect(expanded, isNot(contains('unknown_muscle')));
    });

    test('isCanonicalMuscleKey only accepts exact canonical keys', () {
      expect(registry.isCanonicalMuscleKey('pectorals'), isTrue);
      expect(registry.isCanonicalMuscleKey('chest'), isFalse);
      expect(registry.isCanonicalMuscleKey(' Pectorals '), isFalse);
    });
  });
}
