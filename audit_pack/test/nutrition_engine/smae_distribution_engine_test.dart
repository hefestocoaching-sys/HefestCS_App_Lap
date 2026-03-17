import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/nutrition_engine/equivalents/smae_distribution_engine.dart';

void main() {
  group('SmaeDistributionEngine', () {
    late SmaeDistributionEngine engine;

    setUp(() {
      engine = SmaeDistributionEngine();
    });

    test('cumple delta kcal <= 5% en caso base', () {
      final result = engine.distribute(
        kcalTarget: 2200,
        proteinTargetG: 150,
        carbTargetG: 260,
        fatTargetG: 70,
        mealsPerDay: 4,
      );

      expect(result.deltaKcalPct <= 0.05, isTrue);
      expect(result.withinTolerance, isTrue);
      expect(
        result.totalsByGroup.values.fold<double>(0, (a, b) => a + b),
        greaterThan(0),
      );
    });

    test('distribuye equivalentes para el numero correcto de comidas', () {
      const meals = 5;
      final result = engine.distribute(
        kcalTarget: 2100,
        proteinTargetG: 140,
        carbTargetG: 240,
        fatTargetG: 65,
        mealsPerDay: meals,
      );

      for (final entry in result.mealsByGroup.entries) {
        expect(entry.value.length, meals);
      }
    });

    test('respeta exclusion por grupo', () {
      final result = engine.distribute(
        kcalTarget: 2000,
        proteinTargetG: 140,
        carbTargetG: 220,
        fatTargetG: 60,
        mealsPerDay: 4,
        excludedGroups: const {'aoa'},
      );

      final hasAoa = result.totalsByGroup.keys.any((groupId) {
        return groupId.startsWith('aoa_') &&
            (result.totalsByGroup[groupId] ?? 0) > 0;
      });

      expect(hasAoa, isFalse);
    });

    test('expone warnings cuando cobertura requerida no se cumple', () {
      final result = engine.distribute(
        kcalTarget: 1800,
        proteinTargetG: 120,
        carbTargetG: 200,
        fatTargetG: 55,
        mealsPerDay: 4,
        excludedGroups: const {'vegetales', 'frutas'},
      );

      expect(result.warnings.isNotEmpty, isTrue);
      expect(result.coverage['vegetales'], isFalse);
      expect(result.coverage['frutas'], isFalse);
    });
  });
}
