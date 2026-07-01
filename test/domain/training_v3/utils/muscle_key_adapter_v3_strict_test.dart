import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/training_v3/utils/muscle_key_adapter_v3.dart';

void main() {
  group('MuscleKeyAdapterV3 strict catalog keys', () {
    test('toCatalogKeys handles canonical keys', () {
      expect(MuscleKeyAdapterV3.toCatalogKeys('pectorals'), ['pectorals']);
      expect(MuscleKeyAdapterV3.toCatalogKeys('quads'), ['quads']);
      expect(MuscleKeyAdapterV3.toCatalogKeys('delts_lateral'), [
        'delts_lateral',
      ]);
    });

    test('toCatalogKeys handles aliases', () {
      expect(MuscleKeyAdapterV3.toCatalogKeys('chest'), ['pectorals']);
      expect(MuscleKeyAdapterV3.toCatalogKeys('quadriceps'), ['quads']);
      expect(MuscleKeyAdapterV3.toCatalogKeys('deltoide_anterior'), [
        'delts_front',
      ]);
      expect(MuscleKeyAdapterV3.toCatalogKeys('gastrocnemio'), ['calves']);
      expect(MuscleKeyAdapterV3.toCatalogKeys('soleo'), ['calves']);
    });

    test('toCatalogKeys handles groups', () {
      expect(MuscleKeyAdapterV3.toCatalogKeys('back'), ['lats', 'upper_back']);
      expect(MuscleKeyAdapterV3.toCatalogKeys('shoulders'), [
        'delts_front',
        'delts_lateral',
        'delts_rear',
      ]);
      expect(MuscleKeyAdapterV3.toCatalogKeys('arms'), ['biceps', 'triceps']);
      expect(MuscleKeyAdapterV3.toCatalogKeys('legs'), [
        'quads',
        'hamstrings',
        'glutes',
        'calves',
      ]);
    });

    test('toCatalogKeys supports existing special legacy alias', () {
      expect(MuscleKeyAdapterV3.toCatalogKeys('traps_upper'), ['traps']);
    });

    test('toCatalogKeys unknown does not pass raw through', () {
      expect(MuscleKeyAdapterV3.toCatalogKeys('unknown_muscle'), isEmpty);
      expect(MuscleKeyAdapterV3.toCatalogKeys('back_mid_upper'), isEmpty);
      expect(MuscleKeyAdapterV3.toCatalogKeys('glute'), isEmpty);
      expect(
        MuscleKeyAdapterV3.toCatalogKeys('unknown_muscle'),
        isNot(contains('unknown_muscle')),
      );
    });

    test('macro conversion handles canonical keys and aliases', () {
      expect(MuscleKeyAdapterV3.tryToMacroKey('pectorals'), 'pectorals');
      expect(MuscleKeyAdapterV3.tryToMacroKey('chest'), 'pectorals');
      expect(MuscleKeyAdapterV3.tryToMacroKey('quadriceps'), 'quads');
      expect(
        MuscleKeyAdapterV3.tryToMacroKey('deltoide_anterior'),
        'delts_front',
      );
      expect(MuscleKeyAdapterV3.tryToMacroKey('traps_upper'), 'traps');
      expect(MuscleKeyAdapterV3.toMacroKey('gastrocnemio'), 'calves');
    });

    test('macro conversion unknown does not pass raw through', () {
      expect(MuscleKeyAdapterV3.tryToMacroKey('unknown_muscle'), isNull);
      expect(MuscleKeyAdapterV3.toMacroKey('unknown_muscle'), isEmpty);
      expect(
        MuscleKeyAdapterV3.toMacroKey('unknown_muscle'),
        isNot('unknown_muscle'),
      );
    });
  });
}
