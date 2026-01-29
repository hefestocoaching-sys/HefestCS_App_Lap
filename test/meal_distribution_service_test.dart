import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/nutrition_engine/planning/meal_distribution_config.dart';
import 'package:hcs_app_lap/nutrition_engine/planning/meal_distribution_service.dart';

void main() {
  group('MealDistributionService', () {
    test('3 comidas, proteína suficiente cumple umbral y suma objetivos', () {
      final service = MealDistributionService();
      final config = MealDistributionConfig(mealsPerDay: 3);

      final meals = service.distributeDay(
        kcalTarget: 2400,
        proteinTargetG: 180,
        carbTargetG: 250,
        fatTargetG: 70,
        bodyWeightKg: 80,
        config: config,
      );

      // Umbral proteína por comida: 0.25 * 80 = 20g
      expect(meals.every((m) => m.proteinG >= 20), true);
      expect(meals.every((m) => m.needsReview == false), true);

      // Sumas deben cuadrar (tolerancia mínima por redondeo manejada internamente)
      final totalProtein = meals.fold<double>(0, (p, m) => p + m.proteinG);
      final totalCarb = meals.fold<double>(0, (p, m) => p + m.carbG);
      final totalFat = meals.fold<double>(0, (p, m) => p + m.fatG);
      final totalKcal = meals.fold<double>(0, (p, m) => p + m.kcal);

      expect(totalProtein, closeTo(180, 0.1));
      expect(totalCarb, closeTo(250, 0.1));
      expect(totalFat, closeTo(70, 0.1));
      expect(totalKcal, closeTo(2400, 1));
    });

    test('6 comidas, proteína diaria insuficiente marca needsReview', () {
      final service = MealDistributionService();
      final config = MealDistributionConfig(mealsPerDay: 6);

      final meals = service.distributeDay(
        kcalTarget: 1800,
        proteinTargetG: 60, // insuficiente para 6 comidas con umbral 0.25 g/kg
        carbTargetG: 200,
        fatTargetG: 50,
        bodyWeightKg: 80, // umbral 20g por comida, total requerido 120g
        config: config,
      );

      expect(meals.every((m) => m.needsReview), true);
      expect(
        meals.every(
          (m) =>
              m.note ==
              'Proteína diaria insuficiente para cumplir umbral por comida con 6 comidas',
        ),
        true,
      );
    });
  });
}
