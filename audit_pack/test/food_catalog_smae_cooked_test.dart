import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/data/repositories/food_catalog_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FoodCatalogRepository repository;

  setUp(() {
    repository = FoodCatalogRepository();
  });

  tearDown(() {
    repository.clearCache();
  });

  group('Food Catalog v1.1 - SMAE Cooked Foods Support', () {
    test('Arroz cocido debe tener macros de cocido (130 kcal/100g)', () async {
      final arrozCocido = await repository.getFoodById('arroz_blanco_cocido');

      expect(arrozCocido, isNotNull);
      expect(arrozCocido!.preparationState, 'cooked');
      expect(arrozCocido.macrosPer100g!['kcal']!.round(), 130);
      expect(arrozCocido.macrosPer100g!['carbs']!.round(), 28);
    });

    test('Arroz crudo debe tener yieldFactor 2.5', () async {
      final arrozCrudo = await repository.getFoodById('arroz_blanco_crudo');

      expect(arrozCrudo, isNotNull);
      expect(arrozCrudo!.preparationState, 'raw');
      expect(arrozCrudo.yieldFactor, 2.5);
      expect(arrozCrudo.macrosPer100g!['kcal']!.round(), 365);
    });

    test('Pollo cocido debe tener macros de cocido (165 kcal/100g)', () async {
      final polloCocido = await repository.getFoodById(
        'pechuga_pollo_cocida_sin_piel',
      );

      expect(polloCocido, isNotNull);
      expect(polloCocido!.preparationState, 'cooked');
      expect(polloCocido.macrosPer100g!['kcal']!.round(), 165);
      expect(polloCocido.macrosPer100g!['protein']!.round(), 31);
    });

    test('Pollo crudo debe tener yieldFactor 0.75', () async {
      final polloCrudo = await repository.getFoodById(
        'pechuga_pollo_cruda_sin_piel',
      );

      expect(polloCrudo, isNotNull);
      expect(polloCrudo!.preparationState, 'raw');
      expect(polloCrudo.yieldFactor, 0.75);
    });

    test(
      'Aceite oliva debe ser cooked (ready-to-consume, sin yieldFactor)',
      () async {
        final aceite = await repository.getFoodById('aceite_oliva');

        expect(aceite, isNotNull);
        expect(aceite!.preparationState, 'cooked');
        expect(aceite.yieldFactor, isNull); // No requiere conversión
        expect(aceite.macrosPer100g!['kcal']!.round(), 884);
      },
    );

    test(
      'resolveConsumableFood: alimento cocido retorna sin cambios',
      () async {
        final arrozCocido = await repository.getFoodById('arroz_blanco_cocido');
        final resolved = await repository.resolveConsumableFood(arrozCocido!);

        expect(resolved.preparationState, 'cooked');
        expect(resolved.foodId, 'arroz_blanco_cocido');
        expect(resolved.macrosPer100g!['kcal']!.round(), 130);
      },
    );

    test(
      'resolveConsumableFood: arroz crudo 100g → convierte macros con yieldFactor',
      () async {
        final arrozCrudo = await repository.getFoodById('arroz_blanco_crudo');
        final arrozCrudo100g = arrozCrudo!.copyWith(grams: 100.0);

        final resolved = await repository.resolveConsumableFood(arrozCrudo100g);

        expect(resolved.preparationState, 'cooked');
        expect(resolved.grams, 100.0); // Gramos se mantienen
        // Macros per 100g ajustadas: 365 / 2.5 = 146 kcal (aprox)
        expect(resolved.macrosPer100g!['kcal']!.round(), 146);
        expect(resolved.macrosPer100g!['carbs']!.round(), 32); // 80 / 2.5
      },
    );

    test('getCookedFoods debe retornar solo alimentos cocidos', () async {
      final cookedFoods = await repository.getCookedFoods();

      expect(cookedFoods.isNotEmpty, true);
      expect(cookedFoods.every((f) => f.preparationState == 'cooked'), true);

      // Verificar que incluye pollo, arroz, aceite cocidos
      final foodIds = cookedFoods.map((f) => f.foodId).toList();
      expect(foodIds.contains('pechuga_pollo_cocida_sin_piel'), true);
      expect(foodIds.contains('arroz_blanco_cocido'), true);
      expect(foodIds.contains('aceite_oliva'), true);
    });

    test(
      'SMAE Equivalencia: 53g arroz cocido ≈ 1 equivalente cereales',
      () async {
        final arrozCocido = await repository.getFoodById('arroz_blanco_cocido');
        final arrozCocido53g = arrozCocido!.copyWith(grams: 53.0);

        // 53g arroz cocido × 130 kcal/100g = 68.9 kcal
        // SMAE: 1 equivalente cereales ≈ 70 kcal
        final kcalPorcion = arrozCocido53g.macrosPer100g!['kcal']! * 53 / 100;
        expect(kcalPorcion.round(), 69); // ≈ 70 kcal SMAE
      },
    );

    test(
      'SMAE Equivalencia: 30g pollo cocido ≈ 1 equivalente AOA bajo grasa',
      () async {
        final polloCocido = await repository.getFoodById(
          'pechuga_pollo_cocida_sin_piel',
        );
        final polloCocido30g = polloCocido!.copyWith(grams: 30.0);

        // 30g pollo cocido × 165 kcal/100g = 49.5 kcal
        // SMAE: 1 equivalente AOA bajo grasa ≈ 40-55 kcal
        final kcalPorcion = polloCocido30g.macrosPer100g!['kcal']! * 30 / 100;
        expect(kcalPorcion.round(), 50); // ≈ 40-55 kcal SMAE
      },
    );

    test(
      'Backward Compatibility: FoodItem sin preparationState se asume cooked',
      () async {
        final allFoods = await repository.getAllFoods();

        // Todos los alimentos cargados deben tener preparationState
        expect(allFoods.every((f) => f.preparationState.isNotEmpty), true);
      },
    );
  });
}
