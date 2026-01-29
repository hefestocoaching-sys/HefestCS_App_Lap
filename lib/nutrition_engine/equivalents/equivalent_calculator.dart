import '../planning/meal_targets.dart';

class MealEquivalents {
  final Map<String, double> equivalents; // grupo -> número de equivalentes
  final Map<String, double> gramsByFood; // alimento -> gramos cocidos
  final List<String> warnings; // guardrails culinarios

  const MealEquivalents({
    required this.equivalents,
    required this.gramsByFood,
    this.warnings = const [],
  });
}

/// Calculadora básica v1 basada en SMAE
/// Usa porción base (baseGramsRaw) del equivalente y factores de cocción (yield)
class EquivalentCalculator {
  // Mapa de equivalentes (kcal y macros por equivalente)
  static const Map<String, Map<String, double>> _equivalents = {
    'vegetales': {
      'kcal': 25,
      'protein': 2,
      'fat': 0,
      'carb': 4,
      'baseGramsRaw': 100,
    },
    'frutas': {
      'kcal': 60,
      'protein': 0,
      'fat': 0,
      'carb': 15,
      'baseGramsRaw': 100,
    },
    'cereales_sin_grasa': {
      'kcal': 70,
      'protein': 2,
      'fat': 0,
      'carb': 15,
      'baseGramsRaw': 30,
    },
    'cereales_con_grasa': {
      'kcal': 115,
      'protein': 2,
      'fat': 5,
      'carb': 15,
      'baseGramsRaw': 30,
    },
    'aoa_muy_bajo_grasa': {
      'kcal': 40,
      'protein': 7,
      'fat': 1,
      'carb': 0,
      'baseGramsRaw': 30,
    },
    'aoa_bajo_grasa': {
      'kcal': 55,
      'protein': 7,
      'fat': 3,
      'carb': 0,
      'baseGramsRaw': 30,
    },
    'aoa_moderado_grasa': {
      'kcal': 75,
      'protein': 7,
      'fat': 5,
      'carb': 0,
      'baseGramsRaw': 30,
    },
    'aoa_alto_grasa': {
      'kcal': 100,
      'protein': 7,
      'fat': 8,
      'carb': 0,
      'baseGramsRaw': 30,
    },
    'aceites_sin_proteina': {
      'kcal': 45,
      'protein': 0,
      'fat': 5,
      'carb': 0,
      'baseGramsRaw': 5,
    },
  };

  // Factores de cocción (raw->cooked). Si no existe, asumir cocido (yield = 1.0)
  static const Map<String, double> _cookingYields = {
    'pollo_pechuga': 0.75,
    'arroz_blanco': 2.7,
    'aceite_vegetal': 1.0,
  };

  MealEquivalents calculateForMeal({
    required double proteinG,
    required double carbG,
    required double fatG,
  }) {
    // Calcular equivalentes por grupo
    final aoaEq = proteinG / (_equivalents['aoa_bajo_grasa']!['protein']!);
    final cerealEq = carbG / (_equivalents['cereales_sin_grasa']!['carb']!);
    final aceiteEq = fatG / (_equivalents['aceites_sin_proteina']!['fat']!);

    // Calcular gramos usando porción base y yield
    // AOA (pollo): baseGramsRaw = 30g, yield = 0.75
    final aoaBaseGrams = _equivalents['aoa_bajo_grasa']!['baseGramsRaw']!;
    final aoaYield = _cookingYields['pollo_pechuga'] ?? 1.0;
    final polloGramsRaw = aoaEq * aoaBaseGrams;
    final polloGramsCooked = polloGramsRaw * aoaYield;

    // Cereal (arroz): baseGramsRaw = 30g, yield = 2.7
    final cerealBaseGrams =
        _equivalents['cereales_sin_grasa']!['baseGramsRaw']!;
    final cerealYield = _cookingYields['arroz_blanco'] ?? 1.0;
    final arrozGramsRaw = cerealEq * cerealBaseGrams;
    final arrozGramsCooked = arrozGramsRaw * cerealYield;

    // Aceite: baseGramsRaw = 5g, yield = 1.0 (listo)
    final aceiteBaseGrams =
        _equivalents['aceites_sin_proteina']!['baseGramsRaw']!;
    final aceiteYield = _cookingYields['aceite_vegetal'] ?? 1.0;
    final aceiteGramsRaw = aceiteEq * aceiteBaseGrams;
    final aceiteGramsCooked = aceiteGramsRaw * aceiteYield;

    // Guardrails culinarios
    final warnings = <String>[];
    if (arrozGramsCooked > 300) {
      warnings.add(
        'Cereales >300g cocidos/comida (${arrozGramsCooked.toStringAsFixed(0)}g)',
      );
    }
    if (aceiteGramsCooked > 15) {
      warnings.add(
        'Grasas >${15}g/comida (${aceiteGramsCooked.toStringAsFixed(0)}g)',
      );
    }

    return MealEquivalents(
      equivalents: {
        'aoa_bajo_grasa': _round1(aoaEq),
        'cereales_sin_grasa': _round1(cerealEq),
        'aceites_sin_proteina': _round1(aceiteEq),
      },
      gramsByFood: {
        'Pechuga de pollo': _round1(polloGramsCooked),
        'Arroz blanco': _round1(arrozGramsCooked),
        'Aceite vegetal': _round1(aceiteGramsCooked),
      },
      warnings: warnings,
    );
  }

  MealEquivalents calculateFromMealTargets(MealTargets meal) {
    return calculateForMeal(
      proteinG: meal.proteinG,
      carbG: meal.carbG,
      fatG: meal.fatG,
    );
  }

  List<MealEquivalents> calculateForMeals(List<MealTargets> meals) {
    return meals.map(calculateFromMealTargets).toList();
  }

  double _round1(double v) => double.parse(v.toStringAsFixed(1));
}
