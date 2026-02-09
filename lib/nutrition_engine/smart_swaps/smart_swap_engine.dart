import 'dart:math' as math;

import 'package:hcs_app_lap/domain/entities/clinical_restriction_profile.dart';
import 'package:hcs_app_lap/domain/entities/daily_meal_plan.dart';
import 'package:hcs_app_lap/domain/services/clinical_restriction_validator.dart';

/// Smart swap engine for multi-food exchanges.
class SmartSwapEngine {
  /// Find a smart swap for multiple foods.
  static SwapResult? findMultiFoodSwap({
    required List<FoodItem> selectedFoods,
    required List<FoodItem> catalogFoods,
    ClinicalRestrictionProfile? restrictions,
    double macroTolerance = 0.15,
  }) {
    if (selectedFoods.isEmpty) return null;

    final targetMacros = _calculateTotalMacros(selectedFoods);
    final candidates = <SwapCandidate>[];

    for (final food in catalogFoods) {
      if (_isBlockedByRestrictions(food, restrictions)) continue;

      final score = _calculateMacroSimilarityScore(
        _foodToMacros(food),
        targetMacros,
      );

      if (score > 0.7) {
        candidates.add(SwapCandidate(
          foods: [food],
          score: score,
          type: SwapType.singleFood,
        ));
      }
    }

    for (int i = 0; i < catalogFoods.length; i++) {
      for (int j = i + 1; j < catalogFoods.length; j++) {
        final food1 = catalogFoods[i];
        final food2 = catalogFoods[j];

        if (_isBlockedByRestrictions(food1, restrictions)) continue;
        if (_isBlockedByRestrictions(food2, restrictions)) continue;

        final combo = [food1, food2];
        final comboMacros = _calculateTotalMacros(combo);
        final score = _calculateMacroSimilarityScore(comboMacros, targetMacros);

        if (score > 0.75) {
          candidates.add(SwapCandidate(
            foods: combo,
            score: score,
            type: SwapType.twoFoods,
          ));
        }
      }
    }

    if (candidates.isEmpty) return null;

    candidates.sort((a, b) => b.score.compareTo(a.score));
    final bestCandidate = candidates.first;

    final adjustedFoods = _adjustGramsToMatchMacros(
      bestCandidate.foods,
      targetMacros,
      macroTolerance,
    );

    if (adjustedFoods == null) return null;

    final finalMacros = _calculateTotalMacros(adjustedFoods);
    final diff = MacrosDiff(
      kcal: finalMacros.kcal - targetMacros.kcal,
      protein: finalMacros.protein - targetMacros.protein,
      carbs: finalMacros.carbs - targetMacros.carbs,
      fat: finalMacros.fat - targetMacros.fat,
    );

    return SwapResult(
      originalFoods: selectedFoods,
      swappedFoods: adjustedFoods,
      originalMacros: targetMacros,
      swappedMacros: finalMacros,
      macrosDiff: diff,
      similarityScore: bestCandidate.score,
      swapType: bestCandidate.type,
    );
  }

  static FoodMacros _calculateTotalMacros(List<FoodItem> foods) {
    double kcal = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;

    for (final food in foods) {
      kcal += food.kcal;
      protein += food.protein;
      carbs += food.carbs;
      fat += food.fat;
    }

    return FoodMacros(
      kcal: kcal,
      protein: protein,
      carbs: carbs,
      fat: fat,
    );
  }

  static FoodMacros _foodToMacros(FoodItem food) {
    return FoodMacros(
      kcal: food.kcal,
      protein: food.protein,
      carbs: food.carbs,
      fat: food.fat,
    );
  }

  static double _calculateMacroSimilarityScore(
    FoodMacros candidate,
    FoodMacros target,
  ) {
    if (target.kcal == 0) return 0.0;

    final kcalDiff = (candidate.kcal - target.kcal).abs() / target.kcal;
    final protDiff = target.protein > 0
        ? (candidate.protein - target.protein).abs() / target.protein
        : 0.0;
    final carbDiff = target.carbs > 0
        ? (candidate.carbs - target.carbs).abs() / target.carbs
        : 0.0;
    final fatDiff = target.fat > 0
        ? (candidate.fat - target.fat).abs() / target.fat
        : 0.0;

    final weightedDiff =
        (kcalDiff * 0.25 + protDiff * 0.35 + carbDiff * 0.20 + fatDiff * 0.20);

    return math.max(0.0, 1.0 - weightedDiff);
  }

  static List<FoodItem>? _adjustGramsToMatchMacros(
    List<FoodItem> foods,
    FoodMacros target,
    double tolerance,
  ) {
    if (foods.isEmpty) return null;

    if (foods.length == 1) {
      return _adjustSingleFood(foods.first, target, tolerance);
    }

    return _adjustMultipleFoods(foods, target, tolerance);
  }

  static List<FoodItem>? _adjustSingleFood(
    FoodItem food,
    FoodMacros target,
    double tolerance,
  ) {
    if (food.protein == 0 && target.protein > 0) return null;

    final scaleFactor = target.protein > 0
        ? target.protein / food.protein
        : target.kcal / food.kcal;

    final adjustedGrams = food.grams * scaleFactor;

    if (adjustedGrams < 10 || adjustedGrams > 1000) return null;

    final adjusted = food.copyWith(
      grams: adjustedGrams,
      kcal: food.kcal * scaleFactor,
      protein: food.protein * scaleFactor,
      carbs: food.carbs * scaleFactor,
      fat: food.fat * scaleFactor,
    );

    return [adjusted];
  }

  static List<FoodItem>? _adjustMultipleFoods(
    List<FoodItem> foods,
    FoodMacros target,
    double tolerance,
  ) {
    final adjusted = <FoodItem>[];
    final currentTotal = _calculateTotalMacros(foods);

    if (currentTotal.protein == 0) return null;

    for (final food in foods) {
      final proportion = food.protein / currentTotal.protein;
      final targetProteinForFood = target.protein * proportion;

      final scaleFactor = food.protein > 0
          ? targetProteinForFood / food.protein
          : 1.0;

      final adjustedGrams = food.grams * scaleFactor;

      if (adjustedGrams < 5 || adjustedGrams > 1000) return null;

      adjusted.add(food.copyWith(
        grams: adjustedGrams,
        kcal: food.kcal * scaleFactor,
        protein: food.protein * scaleFactor,
        carbs: food.carbs * scaleFactor,
        fat: food.fat * scaleFactor,
      ));
    }

    final finalMacros = _calculateTotalMacros(adjusted);
    final proteinDiff =
        (finalMacros.protein - target.protein).abs() / target.protein;
    final kcalDiff = (finalMacros.kcal - target.kcal).abs() / target.kcal;

    if (proteinDiff > tolerance || kcalDiff > tolerance) {
      return null;
    }

    return adjusted;
  }

  static bool _isBlockedByRestrictions(
    FoodItem food,
    ClinicalRestrictionProfile? restrictions,
  ) {
    if (restrictions == null) return false;

    return !ClinicalRestrictionValidator.isFoodAllowed(
      foodName: food.name,
      profile: restrictions,
    );
  }

  static List<SwapResult> generateMenuVariants({
    required List<FoodItem> currentMenu,
    required List<FoodItem> catalogFoods,
    ClinicalRestrictionProfile? restrictions,
    int variantsCount = 3,
  }) {
    final variants = <SwapResult>[];
    final usedCombinations = <String>{};

    for (int i = 0; i < currentMenu.length && variants.length < variantsCount; i++) {
      final foodToReplace = currentMenu[i];

      final swap = findMultiFoodSwap(
        selectedFoods: [foodToReplace],
        catalogFoods: catalogFoods,
        restrictions: restrictions,
      );

      if (swap == null) continue;

      final comboKey = swap.swappedFoods.map((f) => f.name).join('|');
      if (usedCombinations.contains(comboKey)) continue;

      usedCombinations.add(comboKey);
      variants.add(swap);
    }

    return variants;
  }
}

class FoodMacros {
  final double kcal;
  final double protein;
  final double carbs;
  final double fat;

  const FoodMacros({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}

class MacrosDiff {
  final double kcal;
  final double protein;
  final double carbs;
  final double fat;

  const MacrosDiff({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  bool get isWithinTolerance {
    return kcal.abs() < 50 &&
        protein.abs() < 5 &&
        carbs.abs() < 10 &&
        fat.abs() < 5;
  }
}

enum SwapType { singleFood, twoFoods, threeFoods }

class SwapCandidate {
  final List<FoodItem> foods;
  final double score;
  final SwapType type;

  const SwapCandidate({
    required this.foods,
    required this.score,
    required this.type,
  });
}

class SwapResult {
  final List<FoodItem> originalFoods;
  final List<FoodItem> swappedFoods;
  final FoodMacros originalMacros;
  final FoodMacros swappedMacros;
  final MacrosDiff macrosDiff;
  final double similarityScore;
  final SwapType swapType;

  const SwapResult({
    required this.originalFoods,
    required this.swappedFoods,
    required this.originalMacros,
    required this.swappedMacros,
    required this.macrosDiff,
    required this.similarityScore,
    required this.swapType,
  });

  String get swapTypeLabel {
    switch (swapType) {
      case SwapType.singleFood:
        return 'Intercambio simple (1 alimento)';
      case SwapType.twoFoods:
        return 'Intercambio doble (2 alimentos)';
      case SwapType.threeFoods:
        return 'Intercambio triple (3 alimentos)';
    }
  }
}
