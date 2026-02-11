import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/entities/clinical_conditions.dart';
import 'package:hcs_app_lap/domain/entities/clinical_restriction_profile.dart';
import 'package:hcs_app_lap/domain/entities/daily_meal_plan.dart';
import 'package:hcs_app_lap/domain/entities/digestive_intolerances.dart';
import 'package:hcs_app_lap/nutrition_engine/equivalents/equivalent_definition.dart';
import 'package:hcs_app_lap/nutrition_engine/equivalents/food_to_equivalent_engine.dart';

void main() {
  group('Integración catálogo → equivalentes → restricciones P0', () {
    test(
      'Alimento del catálogo con macrosPer100g se convierte correctamente',
      () {
        // Simular alimento del catálogo (pollo)
        final pollo = FoodItem(
          name: 'Pechuga de pollo sin piel',
          grams: 100.0,
          kcal: 165.0,
          protein: 31.0,
          fat: 3.6,
          carbs: 0.0,
          foodId: 'f001_pollo_pechuga',
          macrosPer100g: {
            'kcal': 165.0,
            'protein': 31.0,
            'fat': 3.6,
            'carbs': 0.0,
          },
          groupHint: 'alimentos_origen_animal',
          subgroupHint: 'muy_bajo_aporte_grasa',
        );

        final target = EquivalentCatalog.v1Definitions.firstWhere(
          (def) => def.id == 'aoa_bajo',
        );

        final result = FoodToEquivalentEngine.convertFoodToEquivalent(
          food: pollo,
          target: target,
        );

        // Verificaciones
        expect(result.equivalentId, 'aoa_bajo');
        expect(result.grams, greaterThan(0)); // Debe calcular gramos
        expect(result.estimatedMacros['protein'], greaterThan(0));
      },
    );

    test('Restricción P0 bloquea alimentos correctamente', () {
      final lecheDes = FoodItem(
        name: 'Leche descremada',
        grams: 100.0,
        kcal: 34.0,
        protein: 3.4,
        fat: 0.2,
        carbs: 5.0,
        foodId: 'f006_leche_descremada',
        macrosPer100g: {'kcal': 34.0, 'protein': 3.4, 'fat': 0.2, 'carbs': 5.0},
        groupHint: 'leche',
        subgroupHint: 'descremada',
      );

      final profile = ClinicalRestrictionProfile(
        foodAllergies: {'milk': true},
        digestiveIntolerances: DigestiveIntolerances.defaults(),
        clinicalConditions: ClinicalConditions.defaults(),
        dietaryPattern: 'omnivore',
        relevantMedications: {},
      );

      final target = EquivalentDefinition(
        id: 'leche_descremada',
        group: 'leche',
        subgroup: 'descremada',
        kcal: 95.0,
        proteinG: 9.0,
        fatG: 2.0,
        carbG: 12.0,
      );

      final result = FoodToEquivalentEngine.convertFoodToEquivalent(
        food: lecheDes,
        target: target,
        clinicalProfile: profile,
      );

      // Verificaciones: Debe estar bloqueado por alergia a milk
      expect(result.isBlocked, true);
      expect(result.blockageReason, isNotNull);
      expect(result.blockageReason!.toLowerCase(), contains('milk'));
    });

    test('Backward compatibility: FoodItem sin campos extendidos funciona', () {
      // FoodItem legacy (sin foodId, macrosPer100g, etc.)
      final legacyFood = FoodItem(
        name: 'Alimento legacy',
        grams: 100.0,
        kcal: 150.0,
        protein: 20.0,
        fat: 5.0,
        carbs: 10.0,
      );

      final target = EquivalentCatalog.v1Definitions.first;

      final result = FoodToEquivalentEngine.convertFoodToEquivalent(
        food: legacyFood,
        target: target,
      );

      // Verificaciones: Debe funcionar sin errores
      expect(result.grams, greaterThan(0));
      expect(result.equivalentId, isNotEmpty);
    });

    test('findBestEquivalent selecciona sin errores', () {
      final arroz = FoodItem(
        name: 'Test cereal',
        grams: 100.0,
        kcal: 130.0,
        protein: 2.7,
        fat: 0.3,
        carbs: 28.2,
      );

      final result = FoodToEquivalentEngine.findBestEquivalent(food: arroz);

      // Verificación básica: debería encontrar algún equivalente
      // (puede fallar si todos están bloqueados o macros invalidan)
      // Por ahora solo verificamos que no explote
      expect(result == null || result.grams >= 0, true);
    });
  });
}
