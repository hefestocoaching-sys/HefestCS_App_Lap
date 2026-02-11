import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:hcs_app_lap/core/constants/nutrition_extra_keys.dart';
import 'package:hcs_app_lap/data/migrations/nutrition_plan_migration_v3.dart';
import 'package:hcs_app_lap/domain/entities/daily_nutrition_plan.dart';
import 'package:hcs_app_lap/domain/entities/nutrition_settings.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';

class NutritionPlanRepository {
  NutritionPlanRepository(this._ref);

  final Ref _ref;

  Future<void> savePlan(DailyNutritionPlan plan) async {
    final client = _ref.read(clientsProvider).value?.activeClient;
    if (client == null) return;

    final records = _getNutritionRecords(client.nutrition);
    final version = _getNextVersion(records, plan.id);

    final snapshot = PlanSnapshot(
      planId: plan.id,
      dateIso: plan.dateIso,
      version: version,
      data: plan.toJson(),
      createdAt: DateTime.now(),
    );

    final updatedRecords = [...records, snapshot];

    await _ref.read(clientsProvider.notifier).updateActiveClient((current) {
      final mergedExtra = Map<String, dynamic>.from(current.nutrition.extra);
      mergedExtra[NutritionExtraKeys.nutritionPlansV3] = updatedRecords
          .map((record) => record.toJson())
          .toList();

      return current.copyWith(
        nutrition: current.nutrition.copyWith(
          extra: mergedExtra,
          nutritionPlansV3: updatedRecords,
        ),
      );
    });
  }

  Future<DailyNutritionPlan?> loadPlanForDate(String dateIso) async {
    final client = _ref.read(clientsProvider).value?.activeClient;
    if (client == null) return null;

    final records = await _ensureMigratedRecords(client.nutrition);

    final exactMatch = records.where((r) => r.dateIso == dateIso).toList();
    if (exactMatch.isNotEmpty) {
      exactMatch.sort((a, b) => b.version.compareTo(a.version));
      return DailyNutritionPlan.fromJson(exactMatch.first.data);
    }

    final dayOfWeek = _dayOfWeekKey(dateIso);
    final template = records.where((r) => r.dateIso == dayOfWeek).toList();
    if (template.isNotEmpty) {
      template.sort((a, b) => b.version.compareTo(a.version));
      final base = DailyNutritionPlan.fromJson(template.first.data);
      return base.copyWith(
        id: const Uuid().v4(),
        dateIso: dateIso,
        isTemplate: false,
      );
    }

    return null;
  }

  Future<void> saveAsTemplate(DailyNutritionPlan plan, String dayOfWeek) async {
    final template = plan.copyWith(
      id: const Uuid().v4(),
      dateIso: dayOfWeek,
      isTemplate: true,
    );
    await savePlan(template);
  }

  List<PlanSnapshot> _getNutritionRecords(NutritionSettings nutrition) {
    return nutrition.nutritionPlansV3 ??
        _parseNutritionRecords(
          nutrition.extra[NutritionExtraKeys.nutritionPlansV3],
        );
  }

  int _getNextVersion(List<PlanSnapshot> records, String planId) {
    final versions = records
        .where((record) => record.planId == planId)
        .map((record) => record.version)
        .toList();
    if (versions.isEmpty) return 1;
    versions.sort();
    return versions.last + 1;
  }

  Future<List<PlanSnapshot>> _ensureMigratedRecords(
    NutritionSettings nutrition,
  ) async {
    final existing = _getNutritionRecords(nutrition);
    if (existing.isNotEmpty) return existing;

    final client = _ref.read(clientsProvider).value?.activeClient;
    if (client == null) return existing;

    final mealsPerDay = _resolveMealsPerDay(client.nutrition.extra);
    final bodyWeightKg = client.lastWeight ?? 0.0;

    final migrated = NutritionPlanMigrationV3.buildSnapshots(
      nutrition: client.nutrition,
      bodyWeightKg: bodyWeightKg,
      mealsPerDay: mealsPerDay,
    );

    if (migrated.isEmpty) return existing;

    await _ref.read(clientsProvider.notifier).updateActiveClient((current) {
      final mergedExtra = Map<String, dynamic>.from(current.nutrition.extra);
      mergedExtra[NutritionExtraKeys.nutritionPlansV3] = migrated
          .map((record) => record.toJson())
          .toList();

      return current.copyWith(
        nutrition: current.nutrition.copyWith(
          extra: mergedExtra,
          nutritionPlansV3: migrated,
        ),
      );
    });

    return migrated;
  }

  static List<PlanSnapshot> _parseNutritionRecords(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((entry) => PlanSnapshot.fromJson(Map<String, dynamic>.from(entry)))
        .toList();
  }

  static int _resolveMealsPerDay(Map<String, dynamic> extra) {
    final raw = extra[NutritionExtraKeys.preferredMealsPerDay];
    if (raw == null) return 4;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString()) ?? 4;
  }

  static String _dayOfWeekKey(String dateIso) {
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
}

final nutritionPlanRepositoryProvider = Provider<NutritionPlanRepository>((
  ref,
) {
  return NutritionPlanRepository(ref);
});
