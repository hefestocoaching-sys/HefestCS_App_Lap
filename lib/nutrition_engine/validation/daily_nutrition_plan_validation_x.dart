import 'package:hcs_app_lap/domain/entities/daily_nutrition_plan.dart';
import 'package:hcs_app_lap/nutrition_engine/validation/nutrition_plan_validator.dart';

extension DailyNutritionPlanValidationX on DailyNutritionPlan {
  ValidationResult validate({
    double tolerance = NutritionPlanValidator.defaultTolerance,
  }) {
    return NutritionPlanValidator.validatePlan(this, tolerance: tolerance);
  }

  ValidationResult validateWith({
    double tolerance = NutritionPlanValidator.defaultTolerance,
  }) {
    return NutritionPlanValidator.validatePlan(this, tolerance: tolerance);
  }
}
