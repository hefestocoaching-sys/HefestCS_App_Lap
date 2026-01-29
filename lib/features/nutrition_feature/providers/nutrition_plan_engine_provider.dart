import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/core/constants/nutrition_extra_keys.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/features/nutrition_feature/providers/dietary_provider.dart';
import 'package:hcs_app_lap/nutrition_engine/planning/meal_distribution_service.dart';
import 'package:hcs_app_lap/nutrition_engine/planning/nutrition_plan_engine.dart';
import 'package:hcs_app_lap/nutrition_engine/planning/nutrition_plan_result.dart';

final nutritionPlanEngineProvider = Provider<NutritionPlanEngine>((ref) {
  return NutritionPlanEngine(
    mealDistributionService: MealDistributionService(),
  );
});

final nutritionPlanResultProvider = Provider<NutritionPlanResult?>((ref) {
  final client = ref.watch(clientsProvider).value?.activeClient;
  if (client == null) return null;

  final engine = ref.watch(nutritionPlanEngineProvider);
  final dietaryState = ref.watch(dietaryProvider);

  final bodyWeightKg = client.latestAnthropometryRecord?.weightKg ?? 0.0;

  // Obtener mealsPerDay de forma segura (puede estar guardado como String o num)
  int mealsPerDay = 4;
  try {
    final raw = client.nutrition.extra[NutritionExtraKeys.preferredMealsPerDay];
    if (raw != null && raw.toString().isNotEmpty) {
      if (raw is num) {
        mealsPerDay = raw.toInt();
      } else if (raw is String) {
        mealsPerDay = int.tryParse(raw) ?? 4;
      }
    }
  } catch (_) {
    mealsPerDay = 4;
  }

  final clinicalProfile = client.nutrition.clinicalRestrictionProfile;

  // Objetivos diarios desde estado actual o fallback
  double kcalTarget = dietaryState.finalKcal > 0
      ? dietaryState.finalKcal
      : (client.nutrition.kcal?.toDouble() ?? 0.0);

  double proteinTarget = 0;
  double fatTarget = 0;
  double carbTarget = 0;
  bool usedFallback = false;

  // Intentar usar weeklyMacroSettings si existen
  final weekly = client.nutrition.weeklyMacroSettings;
  if (weekly != null && weekly.isNotEmpty) {
    final first = weekly.values.first;
    proteinTarget = first.proteinSelected * bodyWeightKg;
    fatTarget = first.fatSelected * bodyWeightKg;
    carbTarget = first.carbSelected * bodyWeightKg;
    if (kcalTarget <= 0 && first.totalCalories > 0) {
      kcalTarget = first.totalCalories;
    }
  }

  final goal = _normalizeGoal(client.nutrition.planType);

  if (proteinTarget <= 0 || fatTarget <= 0 || carbTarget <= 0) {
    usedFallback = true;
    final proteinPerKg = goal == 'hypertrophy' ? 1.8 : 1.6;
    const fatPerKg = 0.8;

    proteinTarget = bodyWeightKg > 0 ? bodyWeightKg * proteinPerKg : 0;
    fatTarget = bodyWeightKg > 0 ? bodyWeightKg * fatPerKg : 0;

    final proteinKcal = proteinTarget * 4;
    final fatKcal = fatTarget * 9;

    if (kcalTarget <= 0) {
      final fallbackCarbKcal = bodyWeightKg > 0 ? bodyWeightKg * 3 * 4 : 0;
      kcalTarget = proteinKcal + fatKcal + fallbackCarbKcal;
    }

    final carbKcal = (kcalTarget - proteinKcal - fatKcal).clamp(
      0,
      double.infinity,
    );
    carbTarget = carbKcal / 4;
  }

  final result = engine.buildTargets(
    kcalTargetDay: kcalTarget,
    proteinTargetDay: proteinTarget,
    carbTargetDay: carbTarget,
    fatTargetDay: fatTarget,
    mealsPerDay: mealsPerDay,
    bodyWeightKg: bodyWeightKg,
    goal: goal,
    clinicalProfile: clinicalProfile,
  );

  final noteParts = <String>[];
  if (usedFallback) {
    noteParts.add(
      'Fallback macros v1 (goal: $goal, protein ${(goal == 'hypertrophy' ? 1.8 : 1.6).toStringAsFixed(1)} g/kg, fat 0.8 g/kg)',
    );
  }
  if (result.note != null && result.note!.isNotEmpty) {
    noteParts.add(result.note!);
  }

  return NutritionPlanResult(
    kcalTargetDay: result.kcalTargetDay,
    proteinTargetDay: result.proteinTargetDay,
    carbTargetDay: result.carbTargetDay,
    fatTargetDay: result.fatTargetDay,
    mealsPerDay: result.mealsPerDay,
    mtOrProteinThresholdMet: result.mtOrProteinThresholdMet,
    minProteinPerMeal: result.minProteinPerMeal,
    proteinFactor: result.proteinFactor,
    needsReview: result.needsReview,
    note: noteParts.isEmpty ? null : noteParts.join(' | '),
    mealTargets: result.mealTargets,
    mealEquivalents: result.mealEquivalents,
  );
});

String _normalizeGoal(String? raw) {
  final normalized = raw?.toLowerCase().trim() ?? '';
  if (normalized.contains('hipert')) return 'hypertrophy';
  if (normalized.contains('bulk')) return 'hypertrophy';
  if (normalized.contains('cut') || normalized.contains('defin')) return 'cut';
  return 'maintenance';
}
