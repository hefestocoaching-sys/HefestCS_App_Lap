import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/training_v3/resolvers/muscle_to_catalog_resolver.dart';

void main() {
  group('MuscleToCatalogResolver strict behavior', () {
    test('expands canonical muscle keys', () {
      expect(MuscleToCatalogResolver.expandMuscleKey('pectorals'), [
        'pectorals',
      ]);
      expect(MuscleToCatalogResolver.expandMuscleKey('quads'), ['quads']);
      expect(MuscleToCatalogResolver.expandMuscleKey('delts_lateral'), [
        'delts_lateral',
      ]);
    });

    test('expands supported aliases to canonical keys', () {
      expect(MuscleToCatalogResolver.expandMuscleKey('chest'), ['pectorals']);
      expect(MuscleToCatalogResolver.expandMuscleKey('quadriceps'), ['quads']);
      expect(MuscleToCatalogResolver.expandMuscleKey('deltoide_anterior'), [
        'delts_front',
      ]);
    });

    test('expands supported groups deterministically', () {
      expect(MuscleToCatalogResolver.expandMuscleKey('back'), [
        'lats',
        'upper_back',
      ]);
      expect(MuscleToCatalogResolver.expandMuscleKey('shoulders'), [
        'delts_front',
        'delts_lateral',
        'delts_rear',
      ]);
      expect(MuscleToCatalogResolver.expandMuscleKey('arms'), [
        'biceps',
        'triceps',
      ]);
      expect(MuscleToCatalogResolver.expandMuscleKey('legs'), [
        'quads',
        'hamstrings',
        'glutes',
        'calves',
      ]);
    });

    test('unknown keys do not pass raw through', () {
      expect(
        MuscleToCatalogResolver.expandMuscleKey('unknown_muscle'),
        isEmpty,
      );
      expect(
        MuscleToCatalogResolver.expandMuscleKey('back_mid_upper'),
        isEmpty,
      );
      expect(MuscleToCatalogResolver.expandMuscleKey('glute'), isEmpty);
      expect(
        MuscleToCatalogResolver.expandMuscleKey('unknown_muscle'),
        isNot(contains('unknown_muscle')),
      );
      expect(
        MuscleToCatalogResolver.expandMuscleKey('back_mid_upper'),
        isNot(contains('back_mid_upper')),
      );
      expect(
        MuscleToCatalogResolver.expandMuscleKey('glute'),
        isNot(contains('glute')),
      );
    });

    test('canonical conversion is strict', () {
      expect(MuscleToCatalogResolver.toCanonicalMuscle('chest'), 'pectorals');
      expect(
        MuscleToCatalogResolver.tryToCanonicalMuscle('quadriceps'),
        'quads',
      );
      expect(
        MuscleToCatalogResolver.tryToCanonicalMuscle('unknown_muscle'),
        isNull,
      );
      expect(
        MuscleToCatalogResolver.toCanonicalMuscle('unknown_muscle'),
        isEmpty,
      );
      expect(
        MuscleToCatalogResolver.toCanonicalMuscle('unknown_muscle'),
        isNot('unknown_muscle'),
      );
    });
  });
}
