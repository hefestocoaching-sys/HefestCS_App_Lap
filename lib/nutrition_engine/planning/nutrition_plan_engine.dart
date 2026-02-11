import 'dart:math' as math;

import '../equivalents/equivalent_calculator.dart';
import 'meal_distribution_config.dart';
import 'meal_distribution_service.dart';
import 'meal_targets.dart';
import 'nutrition_plan_result.dart';
import 'package:hcs_app_lap/domain/entities/clinical_restriction_profile.dart';

class NutritionPlanEngine {
  final MealDistributionService mealDistributionService;

  const NutritionPlanEngine({required this.mealDistributionService});

  /// Calcula el factor de proteína (g/kg) según objetivo nutricional.
  /// - Hipertrofia: 0.4 g/kg
  /// - Mantenimiento y pérdida: 0.3 g/kg
  double _proteinFactorByGoal(String goal) {
    final normalized = goal.toLowerCase().trim();
    if (normalized.contains('hipert') || normalized.contains('bulk')) {
      return 0.4;
    }
    // Mantenimiento, pérdida, definen, cut, etc.
    return 0.3;
  }

  NutritionPlanResult buildTargets({
    required double kcalTargetDay,
    required double proteinTargetDay,
    required double carbTargetDay,
    required double fatTargetDay,
    required int mealsPerDay,
    required double bodyWeightKg,
    required String goal,
    ClinicalRestrictionProfile?
    clinicalProfile, // Reservado v1 (no usado todavía)
  }) {
    final proteinFactor = _proteinFactorByGoal(goal);
    final minProteinPerMeal = math.max(bodyWeightKg * proteinFactor, 25.0);
    final config = MealDistributionConfig(
      mealsPerDay: mealsPerDay,
      minProteinPerMealPerKg: proteinFactor,
      minProteinPerMealAbsolute: minProteinPerMeal,
    );

    final meals = mealDistributionService.distributeDay(
      kcalTarget: kcalTargetDay,
      proteinTargetG: proteinTargetDay,
      carbTargetG: carbTargetDay,
      fatTargetG: fatTargetDay,
      bodyWeightKg: bodyWeightKg,
      config: config,
    );

    // Propagar needsReview en MealTargets si aplica
    final allMealsMeetThreshold = meals.every(
      (m) => m.proteinG >= minProteinPerMeal,
    );
    final serviceNeedsReview = meals.any((m) => m.needsReview);

    final mealTargets = meals
        .map(
          (m) => MealTargets(
            mealIndex: m.mealIndex,
            kcal: m.kcal,
            proteinG: m.proteinG,
            carbG: m.carbG,
            fatG: m.fatG,
            needsReview: (!allMealsMeetThreshold) || m.needsReview,
            note: m.note,
          ),
        )
        .toList();

    // Flags clínicos definitivos
    final mtOrProteinThresholdMet = allMealsMeetThreshold;
    final needsReview = !allMealsMeetThreshold || serviceNeedsReview;

    String? note;
    if (!allMealsMeetThreshold) {
      note =
          'Una o más comidas no alcanzan el umbral de proteína por comida '
          '(${proteinFactor.toStringAsFixed(1)} g/kg, mínimo 25 g).';
    } else {
      final noteFromMeals = meals
          .firstWhere(
            (m) => m.note != null && m.note!.isNotEmpty,
            orElse: () => const MealTargets(
              mealIndex: -1,
              kcal: 0,
              proteinG: 0,
              carbG: 0,
              fatG: 0,
              needsReview: false,
            ),
          )
          .note;
      if (noteFromMeals != null) {
        note = noteFromMeals;
      }
    }

    final equivalents = EquivalentCalculator().calculateForMeals(mealTargets);

    return NutritionPlanResult(
      kcalTargetDay: kcalTargetDay,
      proteinTargetDay: proteinTargetDay,
      carbTargetDay: carbTargetDay,
      fatTargetDay: fatTargetDay,
      mealsPerDay: mealsPerDay,
      mtOrProteinThresholdMet: mtOrProteinThresholdMet,
      minProteinPerMeal: minProteinPerMeal,
      needsReview: needsReview,
      note: note,
      mealTargets: mealTargets,
      mealEquivalents: equivalents,
      proteinFactor: proteinFactor,
    );
  }
}
