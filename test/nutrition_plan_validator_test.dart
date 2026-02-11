import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/entities/daily_nutrition_plan.dart';
import 'package:hcs_app_lap/nutrition_engine/validation/nutrition_plan_validator.dart';

void main() {
  test('Macro coherence validation passes when targets match equivalents', () {
    final plan = DailyNutritionPlan(
      id: 'plan-1',
      dateIso: '2026-02-10',
      isTemplate: false,
      kcalTarget: 110.0,
      proteinTargetG: 14.0,
      carbTargetG: 0.0,
      fatTargetG: 6.0,
      mealTargets: const [],
      equivalentsByGroup: const {'aoa_bajo': 2.0},
      equivalentsByMeal: const {},
      meals: const [],
      createdAt: DateTime(2026, 2, 10),
    );

    final result = NutritionPlanValidator.validatePlan(plan);

    expect(result.isValid, isTrue);
    expect(result.status.macrosVsEquivalentsOk, isTrue);
    expect(result.warnings, isEmpty);
  });
}
