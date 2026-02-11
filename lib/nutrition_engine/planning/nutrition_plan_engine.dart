import 'dart:math' as math;

import '../equivalents/equivalent_calculator.dart';
import 'meal_distribution_config.dart';
import 'meal_distribution_service.dart';
import 'meal_targets.dart';
import 'nutrition_plan_result.dart';
import 'package:hcs_app_lap/domain/entities/clinical_restriction_profile.dart';
import 'package:hcs_app_lap/domain/entities/daily_nutrition_plan.dart';
import 'package:uuid/uuid.dart';

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
            minProteinPerMeal: minProteinPerMeal,
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

  DailyNutritionPlan buildDailyPlan({
    required String dateIso,
    required double kcalTargetDay,
    required double proteinTargetDay,
    required double carbTargetDay,
    required double fatTargetDay,
    required int mealsPerDay,
    required double bodyWeightKg,
    required String goal,
    ClinicalRestrictionProfile? clinicalProfile,
    bool isTemplate = false,
  }) {
    final result = buildTargets(
      kcalTargetDay: kcalTargetDay,
      proteinTargetDay: proteinTargetDay,
      carbTargetDay: carbTargetDay,
      fatTargetDay: fatTargetDay,
      mealsPerDay: mealsPerDay,
      bodyWeightKg: bodyWeightKg,
      goal: goal,
      clinicalProfile: clinicalProfile,
    );

    final equivalentsByMeal = <int, Map<String, double>>{};
    if (result.mealEquivalents != null) {
      for (var i = 0; i < result.mealEquivalents!.length; i++) {
        equivalentsByMeal[i] = Map<String, double>.from(
          result.mealEquivalents![i].equivalents,
        );
      }
    }

    final equivalentsByGroup = <String, double>{};
    for (final meal in equivalentsByMeal.values) {
      for (final entry in meal.entries) {
        equivalentsByGroup[entry.key] =
            (equivalentsByGroup[entry.key] ?? 0) + entry.value;
      }
    }

    return DailyNutritionPlan(
      id: const Uuid().v4(),
      dateIso: dateIso,
      isTemplate: isTemplate,
      kcalTarget: result.kcalTargetDay,
      proteinTargetG: result.proteinTargetDay,
      carbTargetG: result.carbTargetDay,
      fatTargetG: result.fatTargetDay,
      mealTargets: result.mealTargets,
      equivalentsByGroup: equivalentsByGroup,
      equivalentsByMeal: equivalentsByMeal,
      meals: const [],
      createdAt: DateTime.now(),
      clinicalRestrictionProfile: clinicalProfile,
    );
  }
}
