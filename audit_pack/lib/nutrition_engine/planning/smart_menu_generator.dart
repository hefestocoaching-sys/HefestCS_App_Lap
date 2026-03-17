import 'dart:math' as math;

import 'package:hcs_app_lap/data/repositories/food_catalog_repository.dart';
import 'package:hcs_app_lap/domain/entities/clinical_restriction_profile.dart';
import 'package:hcs_app_lap/domain/entities/daily_meal_plan.dart';
import 'package:hcs_app_lap/nutrition_engine/equivalents/equivalent_definition.dart';

class SmartMenuGenerator {
  static Future<List<Meal>> generateMenuFromEquivalents({
    required Map<int, Map<String, double>> equivalentsByMeal,
    required ClinicalRestrictionProfile clinicalProfile,
    required List<String> userPreferences,
    required List<String> excludedFoods,
    bool allowRepeats = false,
  }) async {
    final repository = FoodCatalogRepository();
    final allowedFoods = await repository.getAllowedFoods(clinicalProfile);

    final excluded = excludedFoods.map(_normalize).toSet();
    final preferences = userPreferences.map(_normalize).toSet();

    final candidates = allowedFoods
        .where((food) => !excluded.contains(_normalize(food.name)))
        .toList();

    final usedFoodIds = <String>{};
    final meals = <Meal>[];

    final sortedMeals = equivalentsByMeal.keys.toList()..sort();

    for (final mealIndex in sortedMeals) {
      final mealEquivalents = equivalentsByMeal[mealIndex] ?? {};
      final mealItems = <FoodItem>[];

      for (final entry in mealEquivalents.entries) {
        if (entry.value <= 0) continue;

        final suggestions = await suggestFoodsForEquivalent(
          equivalentGroupId: entry.key,
          equivalentCount: entry.value,
          restrictions: clinicalProfile,
          candidates: candidates,
          preferences: preferences,
        );

        FoodSuggestion? selected;
        for (final suggestion in suggestions) {
          final id = suggestion.food.foodId ?? suggestion.food.name;
          if (!allowRepeats && usedFoodIds.contains(id)) {
            continue;
          }
          selected = suggestion;
          usedFoodIds.add(id);
          break;
        }

        if (selected != null) {
          mealItems.add(_buildFoodFromSuggestion(selected));
        }
      }

      meals.add(Meal(name: _mealLabel(mealIndex), items: mealItems));
    }

    return meals;
  }

  static Future<List<FoodSuggestion>> suggestFoodsForEquivalent({
    required String equivalentGroupId,
    required double equivalentCount,
    required ClinicalRestrictionProfile restrictions,
    List<FoodItem>? candidates,
    Set<String>? preferences,
  }) async {
    final repository = FoodCatalogRepository();
    final allFoods =
        candidates ?? await repository.getAllowedFoods(restrictions);

    final def = EquivalentCatalog.findById(equivalentGroupId);
    if (def == null) return const [];

    final prefSet = preferences ?? const <String>{};

    final suggestions = <FoodSuggestion>[];

    for (final food in allFoods) {
      final scoreResult = _scoreFoodForEquivalent(
        food: food,
        definition: def,
        preferences: prefSet,
      );
      if (scoreResult == null) continue;
      suggestions.add(scoreResult);
    }

    suggestions.sort(
      (a, b) => b.compatibilityScore.compareTo(a.compatibilityScore),
    );
    return suggestions.take(8).toList();
  }

  static Future<List<Meal>> autoAdjustMenu({
    required List<Meal> currentMeals,
    required Map<String, double> targetMacros,
    required AdjustmentStrategy strategy,
  }) async {
    if (currentMeals.isEmpty) return currentMeals;

    final current = _calculateMacros(currentMeals);
    final targetProtein = targetMacros['protein'] ?? 0.0;
    final targetKcal = targetMacros['kcal'] ?? 0.0;

    final scaleFactor = targetProtein > 0
        ? targetProtein / (current['protein'] ?? 1)
        : (targetKcal > 0 ? targetKcal / (current['kcal'] ?? 1) : 1.0);

    if (scaleFactor <= 0 || scaleFactor.isNaN || scaleFactor.isInfinite) {
      return currentMeals;
    }

    return currentMeals
        .map(
          (meal) => meal.copyWith(
            items: meal.items
                .map((item) => _scaleFood(item, scaleFactor))
                .toList(),
          ),
        )
        .toList();
  }

  static FoodItem _buildFoodFromSuggestion(FoodSuggestion suggestion) {
    final food = suggestion.food;
    final macrosPer100g =
        food.macrosPer100g ??
        {
          'kcal': food.kcal,
          'protein': food.protein,
          'fat': food.fat,
          'carbs': food.carbs,
        };

    final grams = math.max(0.0, suggestion.gramsNeeded);
    final scale = grams / 100.0;

    return food.copyWith(
      grams: grams,
      kcal: (macrosPer100g['kcal'] ?? 0.0) * scale,
      protein: (macrosPer100g['protein'] ?? 0.0) * scale,
      fat: (macrosPer100g['fat'] ?? 0.0) * scale,
      carbs: (macrosPer100g['carbs'] ?? 0.0) * scale,
    );
  }

  static FoodSuggestion? _scoreFoodForEquivalent({
    required FoodItem food,
    required EquivalentDefinition definition,
    required Set<String> preferences,
  }) {
    final groupHint = _normalize(food.groupHint ?? '');
    final subgroupHint = _normalize(food.subgroupHint ?? '');
    final groupId = _normalize(definition.id);
    final groupName = _normalize(definition.group);

    var score = 0.3;
    final reasons = <String>[];

    if (groupHint.isNotEmpty &&
        (groupHint == groupId || groupHint == groupName)) {
      score += 0.4;
      reasons.add('Grupo compatible');
    }
    if (subgroupHint.isNotEmpty &&
        subgroupHint.contains(_normalize(definition.subgroup))) {
      score += 0.15;
      reasons.add('Subgrupo compatible');
    }

    if (preferences.isNotEmpty &&
        preferences.any((p) => _normalize(food.name).contains(p))) {
      score += 0.15;
      reasons.add('Preferencia del usuario');
    }

    final gramsNeeded = _gramsNeededForEquivalent(food, definition);
    if (gramsNeeded <= 0) return null;

    score = score.clamp(0.0, 1.0);

    return FoodSuggestion(
      food: food,
      gramsNeeded: gramsNeeded,
      compatibilityScore: score,
      matchReasons: reasons,
    );
  }

  static double _gramsNeededForEquivalent(
    FoodItem food,
    EquivalentDefinition def,
  ) {
    final macroKey = def.keyMacroForGroup;
    final macrosPer100g =
        food.macrosPer100g ??
        {
          'kcal': food.kcal,
          'protein': food.protein,
          'fat': food.fat,
          'carbs': food.carbs,
        };

    double target;
    if (macroKey == 'protein') {
      target = def.proteinG;
    } else if (macroKey == 'fat') {
      target = def.fatG;
    } else if (macroKey == 'carbs') {
      target = def.carbG;
    } else {
      target = def.kcal;
    }

    final foodMacro = macrosPer100g[macroKey] ?? 0.0;
    if (foodMacro <= 0) return 0.0;

    return (target / foodMacro) * 100.0;
  }

  static Map<String, double> _calculateMacros(List<Meal> meals) {
    double kcal = 0;
    double protein = 0;
    double fat = 0;
    double carbs = 0;

    for (final meal in meals) {
      for (final item in meal.items) {
        kcal += item.kcal;
        protein += item.protein;
        fat += item.fat;
        carbs += item.carbs;
      }
    }

    return {'kcal': kcal, 'protein': protein, 'fat': fat, 'carbs': carbs};
  }

  static FoodItem _scaleFood(FoodItem food, double factor) {
    return food.copyWith(
      grams: food.grams * factor,
      kcal: food.kcal * factor,
      protein: food.protein * factor,
      fat: food.fat * factor,
      carbs: food.carbs * factor,
    );
  }

  static String _mealLabel(int index) {
    const labels = [
      'Desayuno',
      'Colacion',
      'Comida',
      'Merienda',
      'Cena',
      'Snack',
    ];
    if (index >= 0 && index < labels.length) return labels[index];
    return 'Comida ${index + 1}';
  }

  static String _normalize(String input) {
    return input.toLowerCase().trim();
  }
}

class FoodSuggestion {
  final FoodItem food;
  final double gramsNeeded;
  final double compatibilityScore;
  final List<String> matchReasons;

  const FoodSuggestion({
    required this.food,
    required this.gramsNeeded,
    required this.compatibilityScore,
    required this.matchReasons,
  });
}

enum AdjustmentStrategy { minimizeChanges, optimizeVariety }
