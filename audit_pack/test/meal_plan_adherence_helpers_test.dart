import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/utils/nutrition_record_helpers.dart';
import 'package:hcs_app_lap/domain/entities/daily_meal_plan.dart';
import 'package:hcs_app_lap/domain/entities/nutrition_adherence_log.dart';

void main() {
  test('parseDailyMealPlans handles Map and DailyMealPlan instances', () {
    final raw = {
      'Lunes': {
        'dayKey': 'Lunes',
        'meals': [
          {'name': 'Desayuno', 'items': []},
        ],
      },
      'Martes': const DailyMealPlan(dayKey: 'Martes', meals: []),
    };

    final parsed = parseDailyMealPlans(raw);
    expect(parsed != null, true);
    expect(parsed!['Lunes'] is DailyMealPlan, true);
    expect(parsed['Lunes']!.dayKey, 'Lunes');
    expect(parsed['Martes'] is DailyMealPlan, true);
  });

  test('adherence logs: read, latest with timestamps and upsert behavior', () {
    final rawLogs = [
      {
        'dateIso': '2025-12-27T09:00:00Z',
        'targetCalories': 2000,
        'actualCalories': 1800,
        'adherencePct': 90,
        'createdAtIso': '2025-12-27T09:01:00Z',
      },
      {
        'dateIso': '2025-12-28',
        'targetCalories': 2100,
        'actualCalories': 2100,
        'adherencePct': 100,
        'createdAtIso': '2025-12-28T10:00:00Z',
      },
    ];

    final logs = readNutritionAdherenceLogs(rawLogs);
    expect(logs.length, 2);

    final latest = latestNutritionAdherenceLogByDate(logs);
    expect(latest != null, true);
    expect(latest!.dateIso, '2025-12-28');

    final logFor27 = nutritionAdherenceLogForDate(logs, '2025-12-27');
    expect(logFor27 != null, true);

    // Upsert: replace 2025-12-28 record
    const newLog = NutritionAdherenceLog(
      dateIso: '2025-12-28',
      targetCalories: 2200,
      actualCalories: 2000,
      adherencePct: 91.0,
      notes: 'Updated',
      createdAtIso: '2025-12-28T11:00:00Z',
    );

    final updated = upsertNutritionAdherenceLogByDate(logs, newLog);
    expect(updated.length, 2);
    final replaced = nutritionAdherenceLogForDate(updated, '2025-12-28');
    expect(replaced != null, true);
    expect(replaced!.targetCalories, 2200);
  });
}
