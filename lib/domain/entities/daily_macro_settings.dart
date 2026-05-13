import 'package:flutter/material.dart';
import 'package:hcs_app_lap/utils/macro_ranges.dart';
import 'package:hcs_app_lap/core/enums/day_type.dart';

enum MacroType { protein, fat, carb }

@immutable
class DailyMacroSettings {
  final String goalType;

  // Proteínas (g/kg)
  final double proteinMin;
  final double proteinMax;
  final double proteinSelected;

  // Grasas (g/kg)
  final double fatMin;
  final double fatMax;
  final double fatSelected;

  // Carbos (g/kg)
  final double carbMin;
  final double carbMax;
  final double carbSelected;

  // Colores para UI
  final Color proteinColor;
  final Color fatColor;
  final Color carbColor;

  // Totales (kcal)
  final double totalCalories;

  // Etiquetas de selección mostradas en UI
  final String proteinType;
  final String lipidRange;

  // Día (etiqueta para week)
  final String dayOfWeek;

  // Si este día fue customizado manualmente (false = hereda de Lunes)
  final bool isCustomizedFromBase;

  // Nombres de los rangos seleccionados (ej: "Hipertrofia", "Salud")
  final String proteinRangeName;
  final String fatRangeName;

  // Configuración del día de entrenamiento y estados custom
  final bool isCustom;
  final DayType? dayType;

  const DailyMacroSettings({
    this.goalType = 'Mantenimiento',
    this.proteinMin = 1.6,
    this.proteinMax = 2.2,
    this.proteinSelected = 1.8,
    this.fatMin = 0.6,
    this.fatMax = 1.0,
    this.fatSelected = 0.8,
    this.carbMin = 2.0,
    this.carbMax = 5.0,
    this.carbSelected = 3.0,
    this.proteinColor = Colors.white,
    this.fatColor = Colors.white,
    this.carbColor = Colors.white,
    this.totalCalories = 0.0,
    this.proteinType = 'Estándar (1.8 g/kg)',
    this.lipidRange = 'Moderado (0.8-1.0 g/kg)',
    this.dayOfWeek = '',
    this.isCustomizedFromBase = false,
    this.proteinRangeName = '',
    this.fatRangeName = '',
    this.isCustom = false,
    this.dayType,
  });

  static const Map<String, Map<String, double>> rangesByGoal = {
    'Pérdida de grasa': {
      'proteinMin': 1.8,
      'proteinMax': 2.5,
      'fatMin': 0.6,
      'fatMax': 1.0,
      'carbMin': 1.5,
      'carbMax': 4.0,
    },
    'Hipertrofia': {
      'proteinMin': 1.6,
      'proteinMax': 2.2,
      'fatMin': 0.8,
      'fatMax': 1.2,
      'carbMin': 3.0,
      'carbMax': 7.0,
    },
    'Mantenimiento': {
      'proteinMin': 1.6,
      'proteinMax': 2.0,
      'fatMin': 0.8,
      'fatMax': 1.0,
      'carbMin': 2.0,
      'carbMax': 5.0,
    },
  };

  static DailyMacroSettings defaultFor({
    required String goalType,
    required double weightKg,
    double? maintenanceKcal,
  }) {
    final ranges = rangesByGoal[goalType] ?? rangesByGoal['Mantenimiento']!;
    final effectiveWeight = weightKg > 0 ? weightKg : 70.0;

    final proteinMin = ranges['proteinMin']!;
    final proteinMax = ranges['proteinMax']!;
    final proteinSelected = (proteinMin + proteinMax) / 2;

    final fatMin = ranges['fatMin']!;
    final fatMax = ranges['fatMax']!;
    final fatSelected = (fatMin + fatMax) / 2;

    final carbMin = ranges['carbMin']!;
    final carbMax = ranges['carbMax']!;
    double carbSelected;

    double totalCalories;

    if (maintenanceKcal != null && maintenanceKcal > 0) {
      totalCalories = maintenanceKcal;
      final proteinKcal = proteinSelected * effectiveWeight * 4;
      final fatKcal = fatSelected * effectiveWeight * 9;
      final carbKcal = totalCalories - proteinKcal - fatKcal;
      carbSelected = (carbKcal / 4) / effectiveWeight;
    } else {
      // Fallback si no hay kcal de mantenimiento, calcular desde g/kg
      carbSelected = (carbMin + carbMax) / 2;
      final proteinKcal = proteinSelected * effectiveWeight * 4;
      final fatKcal = fatSelected * effectiveWeight * 9;
      final carbKcal = carbSelected * effectiveWeight * 4;
      totalCalories = proteinKcal + fatKcal + carbKcal;
    }

    // Asegurar que los carbos estén en el rango válido
    carbSelected = carbSelected.clamp(carbMin, carbMax);

    // Encontrar el nombre del rango de proteína
    String proteinRangeName = MacroRanges.protein.keys.first;
    for (final entry in MacroRanges.protein.entries) {
      if (proteinSelected >= entry.value.min &&
          proteinSelected <= entry.value.max) {
        proteinRangeName = entry.key;
        break;
      }
    }

    // Encontrar el nombre del rango de grasas
    String fatRangeName = MacroRanges.lipids.keys.first;
    for (final entry in MacroRanges.lipids.entries) {
      if (fatSelected >= entry.value.min && fatSelected <= entry.value.max) {
        fatRangeName = entry.key;
        break;
      }
    }

    return DailyMacroSettings(
      goalType: goalType,
      proteinMin: proteinMin,
      proteinMax: proteinMax,
      proteinSelected: proteinSelected,
      fatMin: fatMin,
      fatMax: fatMax,
      fatSelected: fatSelected,
      carbMin: carbMin,
      carbMax: carbMax,
      carbSelected: carbSelected,
      totalCalories: totalCalories,
      proteinType: 'Recomendado (${proteinSelected.toStringAsFixed(1)} g/kg)',
      lipidRange: 'Recomendado (${fatSelected.toStringAsFixed(1)} g/kg)',
      proteinRangeName: proteinRangeName,
      fatRangeName: fatRangeName,
    );
  }

  DailyMacroSettings copyWith({
    String? goalType,
    double? proteinMin,
    double? proteinMax,
    double? proteinSelected,
    double? fatMin,
    double? fatMax,
    double? fatSelected,
    double? carbMin,
    double? carbMax,
    double? carbSelected,
    Color? proteinColor,
    Color? fatColor,
    Color? carbColor,
    double? totalCalories,
    String? proteinType,
    String? lipidRange,
    String? dayOfWeek,
    bool? isCustomizedFromBase,
    String? proteinRangeName,
    String? fatRangeName,
    bool? isCustom,
    DayType? dayType,
  }) {
    return DailyMacroSettings(
      goalType: goalType ?? this.goalType,
      proteinMin: proteinMin ?? this.proteinMin,
      proteinMax: proteinMax ?? this.proteinMax,
      proteinSelected: proteinSelected ?? this.proteinSelected,
      fatMin: fatMin ?? this.fatMin,
      fatMax: fatMax ?? this.fatMax,
      fatSelected: fatSelected ?? this.fatSelected,
      carbMin: carbMin ?? this.carbMin,
      carbMax: carbMax ?? this.carbMax,
      carbSelected: carbSelected ?? this.carbSelected,
      proteinColor: proteinColor ?? this.proteinColor,
      fatColor: fatColor ?? this.fatColor,
      carbColor: carbColor ?? this.carbColor,
      totalCalories: totalCalories ?? this.totalCalories,
      proteinType: proteinType ?? this.proteinType,
      lipidRange: lipidRange ?? this.lipidRange,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      isCustomizedFromBase: isCustomizedFromBase ?? this.isCustomizedFromBase,
      proteinRangeName: proteinRangeName ?? this.proteinRangeName,
      fatRangeName: fatRangeName ?? this.fatRangeName,
      isCustom: isCustom ?? this.isCustom,
      dayType: dayType ?? this.dayType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'goalType': goalType,
      'proteinMin': proteinMin,
      'proteinMax': proteinMax,
      'proteinSelected': proteinSelected,
      'fatMin': fatMin,
      'fatMax': fatMax,
      'fatSelected': fatSelected,
      'carbMin': carbMin,
      'carbMax': carbMax,
      'carbSelected': carbSelected,
      'proteinColor': proteinColor.toARGB32(),
      'fatColor': fatColor.toARGB32(),
      'carbColor': carbColor.toARGB32(),
      'totalCalories': totalCalories,
      'proteinType': proteinType,
      'lipidRange': lipidRange,
      'dayOfWeek': dayOfWeek,
      'isCustomizedFromBase': isCustomizedFromBase,
      'proteinRangeName': proteinRangeName,
      'fatRangeName': fatRangeName,
      'isCustom': isCustom,
      'dayType': dayType?.name,
    };
  }

  factory DailyMacroSettings.fromJson(Map<String, dynamic> json) {
    return DailyMacroSettings(
      goalType: json['goalType'] as String? ?? 'Mantenimiento',
      proteinMin: (json['proteinMin'] as num? ?? 1.6).toDouble(),
      proteinMax: (json['proteinMax'] as num? ?? 2.2).toDouble(),
      proteinSelected: (json['proteinSelected'] as num? ?? 1.8).toDouble(),
      fatMin: (json['fatMin'] as num? ?? 0.6).toDouble(),
      fatMax: (json['fatMax'] as num? ?? 1.0).toDouble(),
      fatSelected: (json['fatSelected'] as num? ?? 0.8).toDouble(),
      carbMin: (json['carbMin'] as num? ?? 2.0).toDouble(),
      carbMax: (json['carbMax'] as num? ?? 5.0).toDouble(),
      carbSelected: (json['carbSelected'] as num? ?? 3.0).toDouble(),
      proteinColor: json['proteinColor'] != null
          ? Color(json['proteinColor'] as int)
          : Colors.white,
      fatColor: json['fatColor'] != null
          ? Color(json['fatColor'] as int)
          : Colors.white,
      carbColor: json['carbColor'] != null
          ? Color(json['carbColor'] as int)
          : Colors.white,
      totalCalories: (json['totalCalories'] as num? ?? 0.0).toDouble(),
      proteinType: json['proteinType'] as String? ?? 'Estándar (1.8 g/kg)',
      lipidRange: json['lipidRange'] as String? ?? 'Moderado (0.8-1.0 g/kg)',
      dayOfWeek: json['dayOfWeek'] as String? ?? '',
      isCustomizedFromBase: json['isCustomizedFromBase'] as bool? ?? false,
      proteinRangeName: json['proteinRangeName'] as String? ?? '',
      fatRangeName: json['fatRangeName'] as String? ?? '',
      isCustom: json['isCustom'] as bool? ?? false,
      dayType: json['dayType'] != null
          ? DayType.values.firstWhere(
              (e) => e.name == json['dayType'],
              orElse: () => DayType.values.first,
            )
          : null,
    );
  }
}
