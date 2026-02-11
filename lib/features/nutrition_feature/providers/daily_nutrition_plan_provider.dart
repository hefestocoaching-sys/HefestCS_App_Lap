import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:hcs_app_lap/data/repositories/nutrition_plan_repository.dart';
import 'package:hcs_app_lap/domain/entities/daily_nutrition_plan.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/features/nutrition_feature/providers/nutrition_plan_engine_provider.dart';

final dailyNutritionPlanProvider =
    FutureProvider.family<DailyNutritionPlan?, String>((ref, dateIso) async {
      final client = ref.watch(clientsProvider).value?.activeClient;
      if (client == null) return null;

      final repo = ref.watch(nutritionPlanRepositoryProvider);
      final stored = await repo.loadPlanForDate(dateIso);
      if (stored != null) return stored;

      final result = ref.watch(nutritionPlanResultProvider);
      if (result == null) return null;

      final equivalentsByMeal = <int, Map<String, double>>{};
      if (result.mealEquivalents != null) {
        for (var i = 0; i < result.mealEquivalents!.length; i++) {
          final entry = result.mealEquivalents![i];
          equivalentsByMeal[i] = Map<String, double>.from(entry.equivalents);
        }
      }

      final equivalentsByGroup = _sumEquivalentsByGroup(equivalentsByMeal);

      final plan = DailyNutritionPlan(
        id: const Uuid().v4(),
        dateIso: dateIso,
        isTemplate: false,
        kcalTarget: result.kcalTargetDay,
        proteinTargetG: result.proteinTargetDay,
        carbTargetG: result.carbTargetDay,
        fatTargetG: result.fatTargetDay,
        mealTargets: result.mealTargets,
        equivalentsByGroup: equivalentsByGroup,
        equivalentsByMeal: equivalentsByMeal,
        meals: const [],
        createdAt: DateTime.now(),
        validationStatus: const ValidationStatus(),
        warnings: const [],
        clinicalRestrictionProfile: client.nutrition.clinicalRestrictionProfile,
      );

      return plan;
    });

final dailyNutritionPlanSaveProvider = Provider<DailyNutritionPlanSaver>((ref) {
  return DailyNutritionPlanSaver(ref);
});

class DailyNutritionPlanSaver {
  DailyNutritionPlanSaver(this._ref);

  final Ref _ref;

  Future<void> save(DailyNutritionPlan plan) async {
    await _ref.read(nutritionPlanRepositoryProvider).savePlan(plan);
    _ref.invalidate(dailyNutritionPlanProvider(plan.dateIso));
  }
}

Map<String, double> _sumEquivalentsByGroup(
  Map<int, Map<String, double>> equivalentsByMeal,
) {
  final totals = <String, double>{};
  for (final meal in equivalentsByMeal.values) {
    for (final entry in meal.entries) {
      totals[entry.key] = (totals[entry.key] ?? 0) + entry.value;
    }
  }
  return totals;
}
