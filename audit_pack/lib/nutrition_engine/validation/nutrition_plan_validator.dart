import 'package:hcs_app_lap/domain/entities/daily_meal_plan.dart';
import 'package:hcs_app_lap/domain/entities/daily_nutrition_plan.dart';
import 'package:hcs_app_lap/domain/services/clinical_restriction_validator.dart';

class NutritionPlanValidator {
  static const double defaultTolerance = 0.05;

  static ValidationResult validatePlan(
    DailyNutritionPlan plan, {
    double tolerance = defaultTolerance,
  }) {
    final warnings = <ValidationWarning>[];

    final macrosFromEquivalents = plan.calculateMacrosFromEquivalents();
    final targetMacros = plan.targetMacros;

    final macrosVsEquivalentsOk = _macrosAreClose(
      macrosFromEquivalents,
      targetMacros,
      tolerance,
    );
    if (!macrosVsEquivalentsOk) {
      warnings.add(
        const ValidationWarning(
          level: WarningLevel.error,
          message:
              'Los equivalentes asignados no cubren los objetivos de macronutrientes',
          suggestion: 'Ajustar equivalentes automaticamente',
        ),
      );
    }

    bool equivalentsVsMealsOk = true;
    if (plan.meals.isNotEmpty) {
      final macrosFromMeals = plan.calculateMacrosFromMeals();
      equivalentsVsMealsOk = _macrosAreClose(
        macrosFromMeals,
        macrosFromEquivalents,
        tolerance,
      );
      if (!equivalentsVsMealsOk) {
        warnings.add(
          const ValidationWarning(
            level: WarningLevel.warning,
            message: 'El menu no coincide con los equivalentes asignados',
            suggestion: 'Regenerar menu desde equivalentes',
          ),
        );
      }
    }

    bool allMealsHaveMinProtein = true;
    if (plan.meals.isNotEmpty && plan.mealTargets.isNotEmpty) {
      final count = plan.meals.length < plan.mealTargets.length
          ? plan.meals.length
          : plan.mealTargets.length;
      for (var i = 0; i < count; i++) {
        final meal = plan.meals[i];
        final proteinG = _calculateProteinInMeal(meal);
        final minProtein = plan.mealTargets[i].minProteinPerMeal;
        if (minProtein <= 0) continue;
        if (proteinG + 1e-6 < minProtein) {
          allMealsHaveMinProtein = false;
          warnings.add(
            ValidationWarning(
              level: WarningLevel.warning,
              message:
                  'Comida ${i + 1} tiene ${proteinG.toStringAsFixed(1)}g proteina '
                  '(minimo: ${minProtein.toStringAsFixed(1)}g)',
              suggestion: 'Agregar alimento proteico',
            ),
          );
        }
      }
    }

    warnings.addAll(_validateClinicalRestrictions(plan));

    final coherenceScore = _calculateCoherenceScore(warnings);
    final status = ValidationStatus(
      macrosVsEquivalentsOk: macrosVsEquivalentsOk,
      equivalentsVsMealsOk: equivalentsVsMealsOk,
      allMealsHaveMinProtein: allMealsHaveMinProtein,
      coherenceScore: coherenceScore,
    );

    return ValidationResult(
      isValid: warnings.where((w) => w.level == WarningLevel.error).isEmpty,
      warnings: warnings,
      coherenceScore: coherenceScore,
      status: status,
    );
  }

  static bool _macrosAreClose(
    Map<String, double> actual,
    Map<String, double> target,
    double tolerance,
  ) {
    for (final key in const ['kcal', 'protein', 'carbs', 'fat']) {
      final actualValue = actual[key] ?? 0.0;
      final targetValue = target[key] ?? 0.0;
      final diff = (actualValue - targetValue).abs();
      final allowedDiff = targetValue.abs() * tolerance;
      if (diff > allowedDiff) return false;
    }
    return true;
  }

  static double _calculateProteinInMeal(Meal meal) {
    double protein = 0.0;
    for (final item in meal.items) {
      protein += item.protein;
    }
    return protein;
  }

  static List<ValidationWarning> _validateClinicalRestrictions(
    DailyNutritionPlan plan,
  ) {
    final profile = plan.clinicalRestrictionProfile;
    if (profile == null) return const [];

    final warnings = <ValidationWarning>[];
    for (final meal in plan.meals) {
      for (final item in meal.items) {
        if (ClinicalRestrictionValidator.isFoodAllowed(
          foodName: item.name,
          profile: profile,
        )) {
          continue;
        }
        warnings.add(
          ValidationWarning(
            level: WarningLevel.warning,
            message: 'Alimento restringido: ${item.name}',
            suggestion: ClinicalRestrictionValidator.explainFoodBlockage(
              foodName: item.name,
              profile: profile,
            ),
          ),
        );
      }
    }
    return warnings;
  }

  static double _calculateCoherenceScore(List<ValidationWarning> warnings) {
    var score = 1.0;
    for (final warning in warnings) {
      switch (warning.level) {
        case WarningLevel.error:
          score -= 0.3;
          break;
        case WarningLevel.warning:
          score -= 0.1;
          break;
        case WarningLevel.info:
          score -= 0.05;
          break;
      }
    }
    if (score < 0) return 0.0;
    if (score > 1) return 1.0;
    return score;
  }
}
