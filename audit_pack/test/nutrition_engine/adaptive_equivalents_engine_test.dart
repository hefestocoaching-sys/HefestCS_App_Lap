import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/nutrition_engine/equivalents/adaptive_equivalents_engine.dart';

void main() {
  group('AdaptiveEquivalentsEngine', () {
    late AdaptiveEquivalentsEngine engine;

    setUp(() {
      engine = AdaptiveEquivalentsEngine();
    });

    test(
      'adaptToDay should return identical map if target equals baseline',
      () {
        final baseline = {
          'vegetales': 3.0, // 3 * 25 = 75
          'frutas': 2.0, // 2 * 60 = 120
        };
        // Total approx: 75 + 120 = 195 kcal

        final adapted = engine.adaptToDay(baseline, 195.0);

        expect(adapted['vegetales'], 3.0);
        expect(adapted['frutas'], 2.0);
      },
    );

    test('adaptToDay should scale carbs up when target is higher', () {
      final baseline = {
        'vegetales': 1.0, // 25 kcal, 4g carb
        'aoa_bajo': 1.0, // 55 kcal, 0g carb (prot)
      };
      // Baseline Kcal: 25 + 55 = 80 kcal
      // Target: 105 kcal (+25 kcal)

      // Adaptation should come from Vegetables (Carb group) primarily.

      final adapted = engine.adaptToDay(baseline, 105.0);

      expect(adapted['vegetales'], greaterThan(1.0));
      expect(adapted['aoa_bajo'], 1.0); // Protein should stay stable
    });

    test('adaptToDay should fallback scale everything if no carbs found', () {
      final baseline = {
        'aoa_bajo': 2.0, // 55*2 = 110 kcal
        'grasas_sin_proteina': 1.0, // 45 kcal
      };
      // Total: 155. No carbs (aoa=prot, grasas=fat).
      // Target: 310 (Double)

      final adapted = engine.adaptToDay(baseline, 310.0);

      expect(adapted['aoa_bajo'], 4.0);
      expect(adapted['grasas_sin_proteina'], 2.0);
    });

    test('adaptMeals should scale distribution proportionally', () {
      final baselineMeals = {
        'vegetales': {0: 1.0, 1: 1.0, 2: 1.0},
      }; // Total 3.0

      final dailyTotal = {'vegetales': 4.5}; // Increased by 1.5x

      final adaptedMeals = engine.adaptMeals(baselineMeals, dailyTotal, 3);

      expect(adaptedMeals['vegetales']![0], 1.5);
      expect(adaptedMeals['vegetales']![1], 1.5);
      expect(adaptedMeals['vegetales']![2], 1.5);
    });

    test(
      'adaptMeals should distribute evenly if baseline distribution is missing',
      () {
        final baselineMeals = <String, Map<int, double>>{}; // Empty

        final dailyTotal = {'vegetales': 3.0};

        final adaptedMeals = engine.adaptMeals(baselineMeals, dailyTotal, 3);

        expect(adaptedMeals['vegetales']![0], 1.0);
        expect(adaptedMeals['vegetales']![1], 1.0);
        expect(adaptedMeals['vegetales']![2], 1.0);
      },
    );
  });
}
