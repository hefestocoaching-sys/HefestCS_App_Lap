import 'package:hcs_app_lap/nutrition_engine/equivalents/equivalent_definition.dart';
import 'package:hcs_app_lap/core/utils/app_logger.dart';

/// Engine to adapt a general distribution of equivalents to specific daily targets.
///
/// Principle: "Carb-Dominant Adaptation"
/// 1. Calculate the energy gap between the General Plan (Baseline) and the Daily Target.
/// 2. If Daily Target < Baseline: Reduce primarily Carbohydrate groups.
/// 3. If Daily Target > Baseline: Increase primarily Carbohydrate groups.
/// 4. Protein and Fat groups remain as stable as possible.
class AdaptiveEquivalentsEngine {
  /// Adapt the general equivalents map to a specific daily kcal target.
  ///
  /// [generalEquivalents]: `Map<GroupId, Quantity>` (The Baseline)
  /// [targetKcal]: The goal for this specific day.
  /// [currentWeight]: Used if we need to cross-check protein constraints (optional).
  ///
  /// Returns: A new `Map<GroupId, Quantity>` adjusted for the day.
  Map<String, double> adaptToDay(
    Map<String, double> generalEquivalents,
    double targetKcal,
  ) {
    // 1. Calculate Baseline Kcal
    double baselineKcal = 0;
    generalEquivalents.forEach((id, qty) {
      final def = EquivalentCatalog.findById(id);
      if (def != null) {
        baselineKcal += def.kcal * qty;
      }
    });

    if (baselineKcal == 0) return {}; // No baseline, no adaptation.

    // If target is very close (within 50kcal), return baseline.
    if ((baselineKcal - targetKcal).abs() < 50) {
      return Map.from(generalEquivalents);
    }

    // 2. Determine Gap
    final kcalDiff =
        targetKcal - baselineKcal; // Negative = Cut, Positive = Add

    // 3. Identify Adjustable Groups (Carbs)
    // We prioritize groups that are purely or mostly carbs.
    final carbGroups = [
      'cereales_sin_grasa',
      'cereales_con_grasa',
      'frutas',
      'azucares_sin_grasa',
      'azucares_con_grasa',
      'leguminosas', // Contains protein but often adjusted as carb source
      'leche_descremada', // Contains protein but significant liquids/carbs
      'leche_semidescremada',
      'leche_entera',
      'leche_con_azucar', // Added
    ];

    // Create mutable map
    final adapted = Map<String, double>.from(generalEquivalents);

    // 4. Distribute the Diff
    // We simply scale the carb groups proportionally to bridge the gap.
    // NOTE: This is a simplified linear approach.
    // real adaptation might need to prioritize removing "sugar" first, then "cereals", etc.
    // For V1, we scale all carb groups present in the baseline.

    double totalCarbKcalInBaseline = 0;
    for (final id in carbGroups) {
      final qty = generalEquivalents[id] ?? 0;
      if (qty > 0) {
        final def = EquivalentCatalog.findById(id);
        if (def != null) {
          totalCarbKcalInBaseline += def.kcal * qty;
        }
      }
    }

    if (totalCarbKcalInBaseline == 0) {
      // Edge case: No carbs in baseline?
      // Then we must scale EVERYTHING to meet calories, or just Proteins/Fats.
      // Fallback: Linear scale of everything.
      logger.warning(
        'AdaptiveEngine: No carbs found in baseline to adjust. Scaling everything.',
      );
      final ratio = targetKcal / baselineKcal;
      return generalEquivalents.map(
        (key, value) => MapEntry(key, value * ratio),
      );
    }

    // Calculate how much we need to start adding/removing from carbs.
    // NewCarbKcal = OldCarbKcal + Diff
    double newCarbKcalTotal = totalCarbKcalInBaseline + kcalDiff;

    // Safety: Don't go below zero carbs
    if (newCarbKcalTotal < 0) newCarbKcalTotal = 0;

    final ratio = newCarbKcalTotal / totalCarbKcalInBaseline;

    // Apply ratio to carb groups
    for (final id in carbGroups) {
      if (adapted.containsKey(id)) {
        adapted[id] = (adapted[id]! * ratio);
        // Round to nearest 0.25 to keep it clean? Or keep precise?
        // Let's keep precise for calc, but UI filters usually.
        // Let's round to 1 decimal place to avoid 3.33333333
        adapted[id] = double.parse((adapted[id]!).toStringAsFixed(2));
      }
    }

    // If we zeroed out carbs and still have a gap (gap was huge negative),
    // we technically should cut fats/proteins too.
    // Check remaining discrepancy.
    double newTotal = 0;
    adapted.forEach((id, qty) {
      final def = EquivalentCatalog.findById(id);
      if (def != null) newTotal += def.kcal * qty;
    });

    final remainingDiff = targetKcal - newTotal;

    // If discrepancy is still large (> 50kcal) and we already crushed carbs (or added infinite carbs),
    // we might accept it or scale the rest.
    // Rule: "Si o si" carb dominant. If carb adjustment isn't enough (e.g. cutting 1000kcal from a diet with only 500kcal carbs),
    // we surely must cut others.

    if (remainingDiff.abs() > 50) {
      // Secondary Adjustment: Scale everything else
      // logic: (Target - Current) distributed among non-carb groups
      // Or simpler: global scale of the result
      final secondaryRatio = targetKcal / newTotal;
      if (secondRatioIsSafe(secondaryRatio)) {
        adapted.updateAll(
          (key, val) => double.parse((val * secondaryRatio).toStringAsFixed(2)),
        );
      }
    }

    return adapted;
  }

  bool secondRatioIsSafe(double ratio) {
    return ratio > 0.5 &&
        ratio < 1.5; // Safety guard to prevent destruction of protein baseline
  }

  /// Adapt meal distribution based on the new total daily equivalents.
  ///
  /// [generalMeanEquivalents]: `Map<GroupId, Map<MealIndex, Qty>>` (Baseline distribution)
  /// [dailyTotalEquivalents]: `Map<GroupId, TotalQty>` (The adapted daily totals)
  /// [mealsCount]: Number of meals for this day.
  ///
  /// Returns: `Map<GroupId, Map<MealIndex, AdaptedQty>>`
  Map<String, Map<int, double>> adaptMeals(
    Map<String, Map<int, double>> generalMealEquivalents,
    Map<String, double> dailyTotalEquivalents,
    int mealsCount,
  ) {
    final adaptedMeals = <String, Map<int, double>>{};

    dailyTotalEquivalents.forEach((groupId, totalDailyQty) {
      final mealMap = generalMealEquivalents[groupId];
      if (mealMap == null || mealMap.isEmpty) {
        // No distribution in baseline? Distribute evenly.
        final perMeal = totalDailyQty / mealsCount;
        final newMap = <int, double>{};
        for (int i = 0; i < mealsCount; i++) {
          newMap[i] = perMeal;
        }
        adaptedMeals[groupId] = newMap;
        return;
      }

      // Calculate baseline total for this group from meals
      double baselineTotal = 0;
      mealMap.forEach((_, v) => baselineTotal += v);

      if (baselineTotal == 0) {
        // Baseline valid but empty (0). Distribute evenly if we now have qty.
        if (totalDailyQty > 0) {
          final perMeal = totalDailyQty / mealsCount;
          final newMap = <int, double>{};
          for (int i = 0; i < mealsCount; i++) {
            newMap[i] = perMeal;
          }
          adaptedMeals[groupId] = newMap;
        } else {
          adaptedMeals[groupId] = {};
        }
        return;
      }

      // Scale proportionally
      // NewMealMs = OldMealMs * (NewTotal / OldTotal)
      final ratio = totalDailyQty / baselineTotal;
      final newMap = <int, double>{};

      // Fill all meals up to mealsCount
      for (int i = 0; i < mealsCount; i++) {
        final oldVal = mealMap[i] ?? 0;
        newMap[i] = double.parse((oldVal * ratio).toStringAsFixed(2));
      }
      adaptedMeals[groupId] = newMap;
    });

    return adaptedMeals;
  }
}
