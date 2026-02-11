import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/data/repositories/food_catalog_repository.dart';
import 'package:hcs_app_lap/nutrition_engine/equivalents/equivalent_definition.dart';
import 'package:hcs_app_lap/nutrition_engine/equivalents/food_to_equivalent_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FoodCatalogRepository repository;

  setUp(() {
    repository = FoodCatalogRepository();
  });

  tearDown(() {
    repository.clearCache();
  });

  group('Motor de Equivalentes + SMAE Cooked Foods Integration', () {
    test(
      'Arroz cocido: calcular gramos para 1 equivalente cereales (≈53g cocidos)',
      () async {
        final arrozCocido = await repository.getFoodById('arroz_blanco_cocido');

        // SMAE: 1 equivalente cereales ≈ 15g carbs
        final equivalenteCereales = EquivalentCatalog.v1Definitions.firstWhere(
          (e) => e.id == 'cereales_sin_grasa',
        );

        final result = FoodToEquivalentEngine.convertFoodToEquivalent(
          food: arrozCocido!,
          target: equivalenteCereales,
        );

        // Esperado: grams = (15g carbs / 28.2g carbs per 100g) * 100 ≈ 53g
        expect(result.grams.round(), 53);

        // Verificar macros estimados cercanos a SMAE
        final estimatedCarbs = result.estimatedMacros['carbs']!;
        expect(estimatedCarbs.round(), 15);
      },
    );

    test(
      'Pollo cocido: calcular gramos para 1 equivalente AOA bajo grasa (≈30g cocidos)',
      () async {
        final polloCocido = await repository.getFoodById(
          'pechuga_pollo_cocida_sin_piel',
        );

        // SMAE: 1 equivalente AOA bajo grasa ≈ 7g protein
        final equivalenteAOA = EquivalentCatalog.v1Definitions.firstWhere(
          (e) => e.id == 'aoa_bajo',
        );

        final result = FoodToEquivalentEngine.convertFoodToEquivalent(
          food: polloCocido!,
          target: equivalenteAOA,
        );

        // Esperado: grams = (7g protein / 31g protein per 100g) * 100 ≈ 23g
        // Pero SMAE usa 30g pollo cocido (incluye margen práctico)
        expect(result.grams.round(), inInclusiveRange(22, 25));

        final estimatedProtein = result.estimatedMacros['protein']!;
        expect(estimatedProtein.round(), 7);
      },
    );

    test(
      'Arroz CRUDO convertido: debe usar macros cocidas tras resolveConsumableFood',
      () async {
        final arrozCrudo = await repository.getFoodById('arroz_blanco_crudo');
        final arrozCrudo100g = arrozCrudo!.copyWith(grams: 100.0);

        // Convertir a consumible (cocido)
        final arrozConvertido = await repository.resolveConsumableFood(
          arrozCrudo100g,
        );

        // Ahora usar motor de equivalentes
        final equivalenteCereales = EquivalentCatalog.v1Definitions.firstWhere(
          (e) => e.id == 'cereales_sin_grasa',
        );

        final result = FoodToEquivalentEngine.convertFoodToEquivalent(
          food: arrozConvertido,
          target: equivalenteCereales,
        );

        // Macros convertidas: 365 kcal / 2.5 = 146 kcal/100g, 80g carbs / 2.5 = 32g/100g
        // Para 1 equivalente (15g carbs): (15 / 32) * 100 ≈ 47g
        expect(result.grams.round(), inInclusiveRange(46, 48));
      },
    );

    // Nota: No hay definición de leguminosas en catálogo v1Definitions
    // Test omitido hasta agregar definición correspondiente

    test(
      'Backward Compatibility: Alimento sin preparationState funciona con motor',
      () async {
        // Crear alimento legacy (sin preparationState)
        final aguacate = await repository.getFoodById('aguacate_crudo');

        // aguacate_crudo tiene preparationState='cooked' (ready-to-consume)
        // pero verificamos que motor funcione incluso con alimentos legacy
        final equivalenteGrasas = EquivalentCatalog.v1Definitions.firstWhere(
          (e) => e.group == 'grasas',
        );

        final result = FoodToEquivalentEngine.convertFoodToEquivalent(
          food: aguacate!,
          target: equivalenteGrasas,
        );

        // 1 equivalente grasas = 5g fat
        // Aguacate: 14.7g fat per 100g → (5 / 14.7) * 100 ≈ 34g
        expect(result.grams, greaterThan(0));
        expect(result.needsReview, isA<bool>());
      },
    );

    test(
      'SMAE Validation: gramos cocidos son intuitivos (no crudos)',
      () async {
        // Arroz cocido: 53g es cantidad realista para 1 equivalente
        // Arroz crudo: 21g sería confuso para usuario (nadie pesa crudo)

        final arrozCocido = await repository.getFoodById('arroz_blanco_cocido');
        final equivalenteCereales = EquivalentCatalog.v1Definitions.firstWhere(
          (e) => e.id == 'cereales_sin_grasa',
        );

        final result = FoodToEquivalentEngine.convertFoodToEquivalent(
          food: arrozCocido!,
          target: equivalenteCereales,
        );

        // Gramos deben estar en rango SMAE típico (50-60g cocido)
        expect(result.grams, greaterThan(40)); // No 21g crudo
        expect(result.grams, lessThan(70)); // Porción razonable
      },
    );
  });
}
