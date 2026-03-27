import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:hcs_app_lap/core/constants/nutrition_extra_keys.dart';
import 'package:hcs_app_lap/data/repositories/nutrition_plan_repository.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/daily_nutrition_plan.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/features/nutrition_feature/providers/nutrition_plan_engine_provider.dart';
import 'package:hcs_app_lap/utils/date_helpers.dart';
import 'package:hcs_app_lap/utils/nutrition_record_helpers.dart';

final dailyNutritionPlanProvider =
    FutureProvider.family<DailyNutritionPlan?, String>((ref, dateIso) async {
      final client = ref.watch(clientsProvider).value?.activeClient;
      if (client == null) return null;

      final repo = ref.watch(nutritionPlanRepositoryProvider);
      final stored = await repo.loadPlanForDate(dateIso);
      if (stored != null) return stored;

      final result = ref.watch(nutritionPlanResultProvider);
      if (result == null) return null;

      final macroTargets = _resolveTargetsFromLatestMacroRecord(
        client,
        dateIso,
      );

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
        kcalTarget: macroTargets['kcal'] ?? result.kcalTargetDay,
        proteinTargetG: macroTargets['protein'] ?? result.proteinTargetDay,
        carbTargetG: macroTargets['carb'] ?? result.carbTargetDay,
        fatTargetG: macroTargets['fat'] ?? result.fatTargetDay,
        mealTargets: result.mealTargets,
        equivalentsByGroup: equivalentsByGroup,
        equivalentsByMeal: equivalentsByMeal,
        meals: const [],
        createdAt: DateTime.now(),
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

Map<String, double> _resolveTargetsFromLatestMacroRecord(
  Client client,
  String dateIso,
) {
  final macroRecords = readNutritionRecordList(
    client.nutrition.extra[NutritionExtraKeys.macrosRecords],
  );
  final targetDate = DateTime.tryParse(dateIso);
  final macroRecord =
      nutritionRecordForDate(macroRecords, dateIso) ??
      _latestMacroRecordForWeekday(macroRecords, targetDate?.weekday) ??
      latestNutritionRecordByDate(macroRecords);
  final weekly = parseWeeklyMacroSettings(macroRecord?['weeklyMacroSettings']);
  if (weekly == null || weekly.isEmpty) return const {};

  final dayKey = _dayKeyFromDateIso(dateIso);
  final day = _resolveDaySettings(weekly, dayKey);
  if (day == null) return const {};

  final weight = client.lastWeight ?? 70.0;
  final protein = day.proteinSelected * weight;
  final fat = day.fatSelected * weight;
  final carb = day.carbSelected * weight;
  final kcal = day.totalCalories > 0
      ? day.totalCalories
      : (protein * 4) + (carb * 4) + (fat * 9);

  return {'kcal': kcal, 'protein': protein, 'carb': carb, 'fat': fat};
}

Map<String, dynamic>? _latestMacroRecordForWeekday(
  List<Map<String, dynamic>> records,
  int? weekday,
) {
  if (weekday == null) return null;

  Map<String, dynamic>? latest;
  String? latestIso;

  for (final record in records) {
    final iso = _normalizeDateIso(record['dateIso']);
    if (iso == null) continue;
    final parsed = DateTime.tryParse(iso);
    if (parsed == null || parsed.weekday != weekday) continue;

    if (latestIso == null || iso.compareTo(latestIso) > 0) {
      latest = record;
      latestIso = iso;
    }
  }

  return latest;
}

dynamic _resolveDaySettings(Map<String, dynamic> weekly, String dayKey) {
  final normalizedTarget = _normalizeDayKey(dayKey);
  for (final entry in weekly.entries) {
    if (_normalizeDayKey(entry.key) == normalizedTarget) {
      return entry.value;
    }
  }
  return null;
}

String _normalizeDayKey(String raw) {
  return raw
      .toLowerCase()
      .trim()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u');
}

String? _normalizeDateIso(dynamic raw) {
  if (raw == null) return null;
  final s = raw.toString().trim();
  if (s.isEmpty) return null;
  final dt = DateTime.tryParse(s);
  if (dt != null) return dateIsoFrom(dt);
  final match = RegExp(r'^(\d{4}-\d{2}-\d{2})').firstMatch(s);
  if (match != null) {
    final parsed = DateTime.tryParse(match.group(1)!);
    if (parsed != null) return dateIsoFrom(parsed);
  }
  return null;
}

String _dayKeyFromDateIso(String dateIso) {
  final parsed = DateTime.tryParse(dateIso);
  if (parsed == null) return 'lunes';
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
  return 'lunes';
}
