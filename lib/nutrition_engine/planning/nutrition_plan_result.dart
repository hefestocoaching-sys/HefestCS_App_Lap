import 'package:hcs_app_lap/nutrition_engine/planning/meal_targets.dart';
import 'package:hcs_app_lap/nutrition_engine/equivalents/equivalent_calculator.dart';
import 'package:hcs_app_lap/nutrition_engine/equivalents/smae_distribution_engine.dart';

class NutritionPlanResult {
  final double kcalTargetDay;
  final double proteinTargetDay;
  final double carbTargetDay;
  final double fatTargetDay;
  final int mealsPerDay;

  final bool mtOrProteinThresholdMet;
  final double minProteinPerMeal;
  final double proteinFactor;
  final bool needsReview;
  final String? note;

  final List<MealTargets> mealTargets;
  final List<MealEquivalents>? mealEquivalents;
  final SmaeDistributionResult? smaeDistribution;

  const NutritionPlanResult({
    required this.kcalTargetDay,
    required this.proteinTargetDay,
    required this.carbTargetDay,
    required this.fatTargetDay,
    required this.mealsPerDay,
    required this.mtOrProteinThresholdMet,
    required this.minProteinPerMeal,
    required this.proteinFactor,
    required this.needsReview,
    required this.note,
    required this.mealTargets,
    this.mealEquivalents,
    this.smaeDistribution,
  });
}
