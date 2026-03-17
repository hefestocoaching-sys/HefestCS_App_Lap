import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/core/constants/nutrition_extra_keys.dart';
import 'package:hcs_app_lap/data/migrations/nutrition_plan_migration_v3.dart';
import 'package:hcs_app_lap/domain/entities/daily_macro_settings.dart';
import 'package:hcs_app_lap/domain/entities/nutrition_settings.dart';

void main() {
  test('Migration builds snapshots from legacy macro records', () {
    const mondaySettings = DailyMacroSettings(
      proteinSelected: 2.0,
      dayOfWeek: 'Lunes',
    );

    final nutrition = NutritionSettings(
      weeklyMacroSettings: {'Lunes': mondaySettings},
      extra: {
        NutritionExtraKeys.macrosRecords: [
          {
            'dateIso': '2026-02-10',
            'weeklyMacroSettings': {'Lunes': mondaySettings.toJson()},
          },
        ],
        NutritionExtraKeys.equivalentsByDay: {
          'dayEquivalents': {
            'lunes': {'vegetales': 1.0},
          },
          'dayMealEquivalents': {},
        },
      },
    );

    final snapshots = NutritionPlanMigrationV3.buildSnapshots(
      nutrition: nutrition,
      bodyWeightKg: 80.0,
      mealsPerDay: 4,
    );

    expect(snapshots, isNotEmpty);
    expect(
      snapshots.any((snapshot) => snapshot.dateIso == '2026-02-10'),
      isTrue,
    );
  });
}
