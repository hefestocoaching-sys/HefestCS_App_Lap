import 'package:uuid/uuid.dart';

import 'package:hcs_app_lap/core/constants/nutrition_extra_keys.dart';
import 'package:hcs_app_lap/domain/entities/daily_macro_settings.dart';
import 'package:hcs_app_lap/domain/entities/daily_meal_plan.dart';
import 'package:hcs_app_lap/domain/entities/daily_nutrition_plan.dart';
import 'package:hcs_app_lap/domain/entities/nutrition_settings.dart';
import 'package:hcs_app_lap/nutrition_engine/planning/meal_distribution_service.dart';
import 'package:hcs_app_lap/nutrition_engine/planning/nutrition_plan_engine.dart';
import 'package:hcs_app_lap/nutrition_engine/planning/nutrition_plan_result.dart';
import 'package:hcs_app_lap/nutrition_engine/validation/nutrition_plan_validator.dart';
import 'package:hcs_app_lap/utils/nutrition_record_helpers.dart';

class NutritionPlanMigrationV3 {
  static List<PlanSnapshot> buildSnapshots({
    required NutritionSettings nutrition,
    required double bodyWeightKg,
    required int mealsPerDay,
  }) {
    final snapshots = <PlanSnapshot>[];
    final engine = NutritionPlanEngine(
      mealDistributionService: MealDistributionService(),
    );

    final normalizedGoal = _normalizeGoal(nutrition.planType);
    final legacyEquivalents = _parseLegacyEquivalents(nutrition);

    final macroRecords = readNutritionRecordList(
      nutrition.extra[NutritionExtraKeys.macrosRecords],
    );
    final mealPlanRecords = readNutritionRecordList(
      nutrition.extra[NutritionExtraKeys.mealPlanRecords],
    );

    for (final record in macroRecords) {
      final dateIso = record['dateIso']?.toString();
      if (dateIso == null || dateIso.isEmpty) continue;

      final weekly =
          parseWeeklyMacroSettings(record['weeklyMacroSettings']) ??
          nutrition.weeklyMacroSettings ??
          const <String, DailyMacroSettings>{};

      final dayKey = _dayKeyFromDateIso(dateIso);
      final dayLabel = _dayLabelFromKey(dayKey);
      final dailySettings = _resolveDailySettings(weekly, dayLabel);

      final plan = _buildPlan(
        engine: engine,
        nutrition: nutrition,
        dateIso: dateIso,
        dayKey: dayKey,
        dayLabel: dayLabel,
        bodyWeightKg: bodyWeightKg,
        mealsPerDay: mealsPerDay,
        goal: normalizedGoal,
        dailySettings: dailySettings,
        legacyEquivalents: legacyEquivalents,
        mealPlanRecords: mealPlanRecords,
      );

      snapshots.add(_snapshotFromPlan(plan));
    }

    final weeklySettings =
        nutrition.weeklyMacroSettings ?? const <String, DailyMacroSettings>{};
    for (final entry in weeklySettings.entries) {
      final dayLabel = entry.key;
      final dayKey = _normalizeDayKey(dayLabel);
      final plan = _buildPlan(
        engine: engine,
        nutrition: nutrition,
        dateIso: dayKey,
        dayKey: dayKey,
        dayLabel: dayLabel,
        bodyWeightKg: bodyWeightKg,
        mealsPerDay: mealsPerDay,
        goal: normalizedGoal,
        dailySettings: entry.value,
        legacyEquivalents: legacyEquivalents,
        mealPlanRecords: mealPlanRecords,
        isTemplate: true,
      );

      snapshots.add(_snapshotFromPlan(plan));
    }

    return snapshots;
  }

  static Map<String, _LegacyEquivalents> _parseLegacyEquivalents(
    NutritionSettings nutrition,
  ) {
    final raw = nutrition.extra[NutritionExtraKeys.equivalentsByDay];
    if (raw is! Map) return {};

    final dayEquivalentsRaw = raw['dayEquivalents'];
    final dayMealsRaw = raw['dayMealEquivalents'];

    final dayTotals = <String, Map<String, double>>{};
    if (dayEquivalentsRaw is Map) {
      for (final entry in dayEquivalentsRaw.entries) {
        dayTotals[entry.key.toString()] = _parseDoubleMap(entry.value);
      }
    }

    final dayMeals = <String, Map<int, Map<String, double>>>{};
    if (dayMealsRaw is Map) {
      for (final entry in dayMealsRaw.entries) {
        dayMeals[entry.key.toString()] = _parseMealEquivalents(entry.value);
      }
    }

    return {
      for (final key in {...dayTotals.keys, ...dayMeals.keys})
        key: _LegacyEquivalents(
          totals: dayTotals[key] ?? {},
          byMeal: dayMeals[key] ?? {},
        ),
    };
  }

  static DailyNutritionPlan _buildPlan({
    required NutritionPlanEngine engine,
    required NutritionSettings nutrition,
    required String dateIso,
    required String dayKey,
    required String dayLabel,
    required double bodyWeightKg,
    required int mealsPerDay,
    required String goal,
    required DailyMacroSettings? dailySettings,
    required Map<String, _LegacyEquivalents> legacyEquivalents,
    required List<Map<String, dynamic>> mealPlanRecords,
    bool isTemplate = false,
  }) {
    final targets = _resolveTargets(
      dailySettings: dailySettings,
      bodyWeightKg: bodyWeightKg,
    );

    final planResult = engine.buildTargets(
      kcalTargetDay: targets.kcalTarget,
      proteinTargetDay: targets.proteinTargetG,
      carbTargetDay: targets.carbTargetG,
      fatTargetDay: targets.fatTargetG,
      mealsPerDay: mealsPerDay,
      bodyWeightKg: bodyWeightKg,
      goal: goal,
      clinicalProfile: nutrition.clinicalRestrictionProfile,
    );

    final legacy = legacyEquivalents[dayKey];
    final equivalentsByMeal = legacy?.byMeal.isNotEmpty == true
        ? legacy!.byMeal
        : _equivalentsFromPlanResult(planResult);

    final equivalentsByGroup = legacy?.totals.isNotEmpty == true
        ? legacy!.totals
        : _sumEquivalentsByGroup(equivalentsByMeal);

    final meals = _resolveMeals(
      nutrition: nutrition,
      mealPlanRecords: mealPlanRecords,
      dateIso: dateIso,
      dayLabel: dayLabel,
    );

    final plan = DailyNutritionPlan(
      id: const Uuid().v4(),
      dateIso: isTemplate ? dayKey : dateIso,
      isTemplate: isTemplate,
      kcalTarget: planResult.kcalTargetDay,
      proteinTargetG: planResult.proteinTargetDay,
      carbTargetG: planResult.carbTargetDay,
      fatTargetG: planResult.fatTargetDay,
      mealTargets: planResult.mealTargets,
      equivalentsByGroup: equivalentsByGroup,
      equivalentsByMeal: equivalentsByMeal,
      meals: meals,
      createdAt: DateTime.now(),
      validationStatus: const ValidationStatus(),
      warnings: const [],
      clinicalRestrictionProfile: nutrition.clinicalRestrictionProfile,
    );

    final validation = NutritionPlanValidator.validatePlan(plan);
    return plan.copyWith(
      validationStatus: validation.status,
      warnings: validation.warnings,
    );
  }

  static _MacroTargets _resolveTargets({
    required DailyMacroSettings? dailySettings,
    required double bodyWeightKg,
  }) {
    if (dailySettings == null || bodyWeightKg <= 0) {
      return const _MacroTargets();
    }

    final protein = dailySettings.proteinSelected * bodyWeightKg;
    final fat = dailySettings.fatSelected * bodyWeightKg;
    final carbs = dailySettings.carbSelected * bodyWeightKg;

    final kcal = dailySettings.totalCalories > 0
        ? dailySettings.totalCalories
        : (protein * 4) + (fat * 9) + (carbs * 4);

    return _MacroTargets(
      kcalTarget: kcal,
      proteinTargetG: protein,
      carbTargetG: carbs,
      fatTargetG: fat,
    );
  }

  static List<Meal> _resolveMeals({
    required NutritionSettings nutrition,
    required List<Map<String, dynamic>> mealPlanRecords,
    required String dateIso,
    required String dayLabel,
  }) {
    Map<String, DailyMealPlan> plans = Map<String, DailyMealPlan>.from(
      nutrition.dailyMealPlans ?? {},
    );
    if (mealPlanRecords.isNotEmpty) {
      final record =
          nutritionRecordForDate(mealPlanRecords, dateIso) ??
          latestNutritionRecordByDate(mealPlanRecords);
      final parsed = parseDailyMealPlans(record?['dailyMealPlans']);
      if (parsed != null) {
        plans = parsed;
      }
    }

    final normalizedLabel = _normalizeDayLabel(dayLabel);
    final direct = plans[dayLabel] ?? plans[normalizedLabel];
    if (direct != null) return direct.meals;

    final normalizedPlans = {
      for (final entry in plans.entries)
        _normalizeDayLabel(entry.key): entry.value,
    };
    return normalizedPlans[normalizedLabel]?.meals ?? const [];
  }

  static DailyMacroSettings? _resolveDailySettings(
    Map<String, DailyMacroSettings> weekly,
    String dayLabel,
  ) {
    if (weekly.containsKey(dayLabel)) return weekly[dayLabel];
    final normalized = _normalizeDayLabel(dayLabel);
    for (final entry in weekly.entries) {
      if (_normalizeDayLabel(entry.key) == normalized) {
        return entry.value;
      }
    }
    return null;
  }

  static String _dayKeyFromDateIso(String dateIso) {
    final parsed = DateTime.tryParse(dateIso);
    if (parsed == null) return dateIso.toLowerCase();
    switch (parsed.weekday) {
      case DateTime.monday:
        return 'lunes';
      case DateTime.tuesday:
        return 'martes';
      case DateTime.wednesday:
        return 'miercoles';
      case DateTime.thursday:
        return 'jueves';
      case DateTime.friday:
        return 'viernes';
      case DateTime.saturday:
        return 'sabado';
      case DateTime.sunday:
        return 'domingo';
    }
    return dateIso.toLowerCase();
  }

  static String _dayLabelFromKey(String dayKey) {
    switch (_normalizeDayKey(dayKey)) {
      case 'lunes':
        return 'Lunes';
      case 'martes':
        return 'Martes';
      case 'miercoles':
        return 'Miercoles';
      case 'jueves':
        return 'Jueves';
      case 'viernes':
        return 'Viernes';
      case 'sabado':
        return 'Sabado';
      case 'domingo':
        return 'Domingo';
    }
    return dayKey;
  }

  static String _normalizeGoal(String? raw) {
    final normalized = raw?.toLowerCase().trim() ?? '';
    if (normalized.contains('hipert')) return 'hypertrophy';
    if (normalized.contains('bulk')) return 'hypertrophy';
    if (normalized.contains('cut') || normalized.contains('defin')) {
      return 'cut';
    }
    return 'maintenance';
  }

  static String _normalizeDayLabel(String dayLabel) {
    return dayLabel
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
  }

  static String _normalizeDayKey(String dayKey) {
    return _normalizeDayLabel(dayKey);
  }

  static Map<String, double> _parseDoubleMap(dynamic raw) {
    if (raw is! Map) return {};
    final result = <String, double>{};
    for (final entry in raw.entries) {
      result[entry.key.toString()] = (entry.value as num?)?.toDouble() ?? 0.0;
    }
    return result;
  }

  static Map<int, Map<String, double>> _parseMealEquivalents(dynamic raw) {
    if (raw is! Map) return {};
    final result = <int, Map<String, double>>{};
    for (final entry in raw.entries) {
      final groupId = entry.key.toString();
      if (entry.value is! Map) continue;
      for (final mealEntry in (entry.value as Map).entries) {
        final mealIndex = int.tryParse(mealEntry.key.toString());
        if (mealIndex == null) continue;
        final value = (mealEntry.value as num?)?.toDouble() ?? 0.0;
        final byMeal = result.putIfAbsent(mealIndex, () => <String, double>{});
        byMeal[groupId] = value;
      }
    }
    return result;
  }

  static Map<int, Map<String, double>> _equivalentsFromPlanResult(
    NutritionPlanResult result,
  ) {
    if (result.mealEquivalents == null) return {};
    final equivalentsByMeal = <int, Map<String, double>>{};
    for (var i = 0; i < result.mealEquivalents!.length; i++) {
      final mealEquivalents = result.mealEquivalents![i];
      equivalentsByMeal[i] = Map<String, double>.from(
        mealEquivalents.equivalents,
      );
    }
    return equivalentsByMeal;
  }

  static Map<String, double> _sumEquivalentsByGroup(
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

  static PlanSnapshot _snapshotFromPlan(DailyNutritionPlan plan) {
    return PlanSnapshot(
      planId: plan.id,
      dateIso: plan.dateIso,
      version: 1,
      data: plan.toJson(),
      createdAt: DateTime.now(),
    );
  }
}

class _LegacyEquivalents {
  final Map<String, double> totals;
  final Map<int, Map<String, double>> byMeal;

  const _LegacyEquivalents({this.totals = const {}, this.byMeal = const {}});
}

class _MacroTargets {
  final double kcalTarget;
  final double proteinTargetG;
  final double carbTargetG;
  final double fatTargetG;

  const _MacroTargets({
    this.kcalTarget = 0.0,
    this.proteinTargetG = 0.0,
    this.carbTargetG = 0.0,
    this.fatTargetG = 0.0,
  });
}
