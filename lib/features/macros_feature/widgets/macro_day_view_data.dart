import 'package:flutter/foundation.dart';
import 'package:hcs_app_lap/domain/entities/daily_macro_settings.dart';

@immutable
class MacroDayViewData {
  final String dayName;
  final String subtitle;
  final DailyMacroSettings settings;
  final bool isBase;
  final bool isCustom;
  final double weightKg;
  final double targetKcal;
  final double maintenanceKcal;
  final double kcalDeltaFromMaintenance;
  final double kcalDeltaPercentFromMaintenance;
  final double proteinGrams;
  final double fatGrams;
  final double carbsGrams;
  final double proteinKcal;
  final double fatKcal;
  final double carbsKcal;
  final double totalMacroKcal;
  final double proteinPercent;
  final double fatPercent;
  final double carbsPercent;
  final bool hasNegativeCarbs;

  const MacroDayViewData({
    required this.dayName,
    required this.subtitle,
    required this.settings,
    required this.isBase,
    required this.isCustom,
    required this.weightKg,
    required this.targetKcal,
    required this.maintenanceKcal,
    required this.kcalDeltaFromMaintenance,
    required this.kcalDeltaPercentFromMaintenance,
    required this.proteinGrams,
    required this.fatGrams,
    required this.carbsGrams,
    required this.proteinKcal,
    required this.fatKcal,
    required this.carbsKcal,
    required this.totalMacroKcal,
    required this.proteinPercent,
    required this.fatPercent,
    required this.carbsPercent,
    required this.hasNegativeCarbs,
  });

  String get statusLabel {
    if (isBase) return 'BASE';
    if (isCustom) return 'CUSTOM';
    return 'HEREDADO';
  }

  bool get isInherited => !isBase && !isCustom;

  factory MacroDayViewData.fromSettings({
    required String dayName,
    required DailyMacroSettings settings,
    required bool isBase,
    required double weightKg,
    required double targetKcal,
    required double maintenanceKcal,
    String subtitle = 'Plan diario',
  }) {
    final safeWeight = weightKg > 0 ? weightKg : 70.0;
    final safeMaintenanceKcal = maintenanceKcal > 0
        ? maintenanceKcal
        : targetKcal;
    final proteinGrams = settings.proteinSelected * safeWeight;
    final fatGrams = settings.fatSelected * safeWeight;

    final proteinKcal = proteinGrams * 4;
    final fatKcal = fatGrams * 9;
    final remainingKcal = targetKcal - proteinKcal - fatKcal;
    final carbsGrams = remainingKcal / 4;
    final carbsKcal = carbsGrams * 4;
    final kcalDeltaFromMaintenance = targetKcal - safeMaintenanceKcal;
    final kcalDeltaPercentFromMaintenance = safeMaintenanceKcal > 0
        ? (kcalDeltaFromMaintenance / safeMaintenanceKcal) * 100
        : 0.0;

    final safeTotal = targetKcal > 0
        ? targetKcal
        : (proteinKcal + fatKcal + (carbsKcal > 0 ? carbsKcal : 0));

    double percent(double kcal) {
      if (safeTotal <= 0) return 0;
      return (kcal / safeTotal) * 100;
    }

    return MacroDayViewData(
      dayName: dayName,
      subtitle: subtitle,
      settings: settings,
      isBase: isBase,
      isCustom: settings.isCustomizedFromBase || settings.isCustom,
      weightKg: safeWeight,
      targetKcal: targetKcal,
      maintenanceKcal: safeMaintenanceKcal,
      kcalDeltaFromMaintenance: kcalDeltaFromMaintenance,
      kcalDeltaPercentFromMaintenance: kcalDeltaPercentFromMaintenance,
      proteinGrams: proteinGrams,
      fatGrams: fatGrams,
      carbsGrams: carbsGrams,
      proteinKcal: proteinKcal,
      fatKcal: fatKcal,
      carbsKcal: carbsKcal,
      totalMacroKcal: proteinKcal + fatKcal + carbsKcal,
      proteinPercent: percent(proteinKcal),
      fatPercent: percent(fatKcal),
      carbsPercent: percent(carbsKcal),
      hasNegativeCarbs: carbsGrams < 0,
    );
  }
}

@immutable
class MacroWeekInsightData {
  final double weeklyMaintenanceKcal;
  final double weeklyTargetKcal;
  final double weeklyDeltaKcal;
  final double averageDailyDeltaKcal;
  final double monthlyDeltaKcal;
  final double estimatedMonthlyWeightChangeKg;

  const MacroWeekInsightData({
    required this.weeklyMaintenanceKcal,
    required this.weeklyTargetKcal,
    required this.weeklyDeltaKcal,
    required this.averageDailyDeltaKcal,
    required this.monthlyDeltaKcal,
    required this.estimatedMonthlyWeightChangeKg,
  });

  bool get isDeficit => weeklyDeltaKcal < -75;
  bool get isSurplus => weeklyDeltaKcal > 75;
  bool get isMaintenance => !isDeficit && !isSurplus;

  double get weeklyDeficitKcal =>
      weeklyDeltaKcal < 0 ? weeklyDeltaKcal.abs() : 0;
  double get weeklySurplusKcal => weeklyDeltaKcal > 0 ? weeklyDeltaKcal : 0;

  factory MacroWeekInsightData.fromDays(List<MacroDayViewData> days) {
    final weeklyMaintenance = days.fold<double>(
      0,
      (sum, day) => sum + day.maintenanceKcal,
    );

    final weeklyTarget = days.fold<double>(
      0,
      (sum, day) => sum + day.targetKcal,
    );

    final weeklyDelta = weeklyTarget - weeklyMaintenance;
    final averageDailyDelta = days.isEmpty ? 0.0 : weeklyDelta / days.length;
    final monthlyDelta = weeklyDelta * 4.33;
    final estimatedMonthlyWeightChangeKg = monthlyDelta / 7700;

    return MacroWeekInsightData(
      weeklyMaintenanceKcal: weeklyMaintenance,
      weeklyTargetKcal: weeklyTarget,
      weeklyDeltaKcal: weeklyDelta,
      averageDailyDeltaKcal: averageDailyDelta,
      monthlyDeltaKcal: monthlyDelta,
      estimatedMonthlyWeightChangeKg: estimatedMonthlyWeightChangeKg,
    );
  }
}
