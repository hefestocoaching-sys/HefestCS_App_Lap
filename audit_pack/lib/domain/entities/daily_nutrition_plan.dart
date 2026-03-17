import 'package:flutter/foundation.dart';
import 'package:hcs_app_lap/domain/entities/clinical_restriction_profile.dart';
import 'package:hcs_app_lap/domain/entities/daily_meal_plan.dart';
import 'package:hcs_app_lap/nutrition_engine/equivalents/equivalent_definition.dart';
import 'package:hcs_app_lap/nutrition_engine/planning/meal_targets.dart';
import 'package:hcs_app_lap/nutrition_engine/validation/nutrition_plan_validator.dart';

class DailyNutritionPlan {
  final String id;
  final String dateIso;
  final bool isTemplate;
  final double kcalTarget;
  final double proteinTargetG;
  final double carbTargetG;
  final double fatTargetG;
  final List<MealTargets> mealTargets;
  final Map<String, double> equivalentsByGroup;
  final Map<int, Map<String, double>> equivalentsByMeal;
  final List<Meal> meals;
  final DateTime createdAt;
  final DateTime? lastModifiedAt;
  final ValidationStatus validationStatus;
  final List<ValidationWarning> warnings;
  final ClinicalRestrictionProfile? clinicalRestrictionProfile;

  const DailyNutritionPlan({
    required this.id,
    required this.dateIso,
    required this.isTemplate,
    required this.kcalTarget,
    required this.proteinTargetG,
    required this.carbTargetG,
    required this.fatTargetG,
    required this.mealTargets,
    required this.equivalentsByGroup,
    required this.equivalentsByMeal,
    required this.meals,
    required this.createdAt,
    this.lastModifiedAt,
    this.validationStatus = const ValidationStatus(),
    this.warnings = const [],
    this.clinicalRestrictionProfile,
  });

  DailyNutritionPlan copyWith({
    String? id,
    String? dateIso,
    bool? isTemplate,
    double? kcalTarget,
    double? proteinTargetG,
    double? carbTargetG,
    double? fatTargetG,
    List<MealTargets>? mealTargets,
    Map<String, double>? equivalentsByGroup,
    Map<int, Map<String, double>>? equivalentsByMeal,
    List<Meal>? meals,
    DateTime? createdAt,
    DateTime? lastModifiedAt,
    ValidationStatus? validationStatus,
    List<ValidationWarning>? warnings,
    ClinicalRestrictionProfile? clinicalRestrictionProfile,
  }) {
    return DailyNutritionPlan(
      id: id ?? this.id,
      dateIso: dateIso ?? this.dateIso,
      isTemplate: isTemplate ?? this.isTemplate,
      kcalTarget: kcalTarget ?? this.kcalTarget,
      proteinTargetG: proteinTargetG ?? this.proteinTargetG,
      carbTargetG: carbTargetG ?? this.carbTargetG,
      fatTargetG: fatTargetG ?? this.fatTargetG,
      mealTargets: mealTargets ?? this.mealTargets,
      equivalentsByGroup: equivalentsByGroup ?? this.equivalentsByGroup,
      equivalentsByMeal: equivalentsByMeal ?? this.equivalentsByMeal,
      meals: meals ?? this.meals,
      createdAt: createdAt ?? this.createdAt,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      validationStatus: validationStatus ?? this.validationStatus,
      warnings: warnings ?? this.warnings,
      clinicalRestrictionProfile:
          clinicalRestrictionProfile ?? this.clinicalRestrictionProfile,
    );
  }

  Map<String, double> get targetMacros => {
    'kcal': kcalTarget,
    'protein': proteinTargetG,
    'carbs': carbTargetG,
    'fat': fatTargetG,
  };

  bool get isCoherent {
    return validationStatus.macrosVsEquivalentsOk &&
        validationStatus.equivalentsVsMealsOk &&
        validationStatus.allMealsHaveMinProtein;
  }

  Map<String, double> calculateMacrosFromEquivalents() {
    final totals = <String, double>{
      'kcal': 0.0,
      'protein': 0.0,
      'carbs': 0.0,
      'fat': 0.0,
    };

    final effectiveTotals = equivalentsByGroup.isNotEmpty
        ? equivalentsByGroup
        : _sumEquivalentsByGroup(equivalentsByMeal);

    for (final entry in effectiveTotals.entries) {
      final resolvedId = _normalizeEquivalentId(entry.key);
      final def = EquivalentCatalog.findById(resolvedId);
      if (def == null) continue;
      totals['kcal'] = (totals['kcal'] ?? 0) + def.kcal * entry.value;
      totals['protein'] = (totals['protein'] ?? 0) + def.proteinG * entry.value;
      totals['carbs'] = (totals['carbs'] ?? 0) + def.carbG * entry.value;
      totals['fat'] = (totals['fat'] ?? 0) + def.fatG * entry.value;
    }

    return totals;
  }

  Map<String, double> calculateMacrosFromMeals() {
    double kcal = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;

    for (final meal in meals) {
      for (final item in meal.items) {
        kcal += item.kcal;
        protein += item.protein;
        carbs += item.carbs;
        fat += item.fat;
      }
    }

    return {'kcal': kcal, 'protein': protein, 'carbs': carbs, 'fat': fat};
  }

  ValidationResult validate({double tolerance = 0.05}) {
    return NutritionPlanValidator.validatePlan(this, tolerance: tolerance);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dateIso': dateIso,
      'isTemplate': isTemplate,
      'kcalTarget': _safeNum(kcalTarget),
      'proteinTargetG': _safeNum(proteinTargetG),
      'carbTargetG': _safeNum(carbTargetG),
      'fatTargetG': _safeNum(fatTargetG),
      'mealTargets': mealTargets.map((t) => t.toJson()).toList(),
      'equivalentsByGroup': _doubleMapToJson(equivalentsByGroup),
      'equivalentsByMeal': _equivalentsByMealToJson(equivalentsByMeal),
      'meals': meals.map((m) => m.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      if (lastModifiedAt != null)
        'lastModifiedAt': lastModifiedAt!.toIso8601String(),
      'validationStatus': validationStatus.toJson(),
      'warnings': warnings.map((w) => w.toJson()).toList(),
      if (clinicalRestrictionProfile != null)
        'clinicalRestrictionProfile': clinicalRestrictionProfile!.toMap(),
    };
  }

  factory DailyNutritionPlan.fromJson(Map<String, dynamic> json) {
    return DailyNutritionPlan(
      id: json['id'] as String,
      dateIso: json['dateIso'] as String,
      isTemplate: json['isTemplate'] as bool? ?? false,
      kcalTarget: _safeNum(json['kcalTarget'] as num?),
      proteinTargetG: _safeNum(json['proteinTargetG'] as num?),
      carbTargetG: _safeNum(json['carbTargetG'] as num?),
      fatTargetG: _safeNum(json['fatTargetG'] as num?),
      mealTargets: (json['mealTargets'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((t) => MealTargets.fromJson(Map<String, dynamic>.from(t)))
          .toList(),
      equivalentsByGroup: _parseDoubleMap(json['equivalentsByGroup']),
      equivalentsByMeal: _parseEquivalentsByMeal(json['equivalentsByMeal']),
      meals: (json['meals'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((m) => Meal.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastModifiedAt: json['lastModifiedAt'] != null
          ? DateTime.parse(json['lastModifiedAt'] as String)
          : null,
      validationStatus: json['validationStatus'] is Map
          ? ValidationStatus.fromJson(
              Map<String, dynamic>.from(json['validationStatus'] as Map),
            )
          : const ValidationStatus(),
      warnings: (json['warnings'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((w) => ValidationWarning.fromJson(Map<String, dynamic>.from(w)))
          .toList(),
      clinicalRestrictionProfile: json['clinicalRestrictionProfile'] is Map
          ? ClinicalRestrictionProfile.fromMap(
              Map<String, dynamic>.from(
                json['clinicalRestrictionProfile'] as Map,
              ),
            )
          : null,
    );
  }

  static Map<String, double> _sumEquivalentsByGroup(
    Map<int, Map<String, double>> byMeal,
  ) {
    final totals = <String, double>{};
    for (final mealEntry in byMeal.values) {
      for (final entry in mealEntry.entries) {
        totals[entry.key] = (totals[entry.key] ?? 0) + entry.value;
      }
    }
    return totals;
  }

  static Map<String, dynamic> _doubleMapToJson(Map<String, double> input) {
    return input.map((key, value) => MapEntry(key, _safeNum(value)));
  }

  static Map<String, dynamic> _equivalentsByMealToJson(
    Map<int, Map<String, double>> input,
  ) {
    final result = <String, dynamic>{};
    for (final entry in input.entries) {
      result[entry.key.toString()] = _doubleMapToJson(entry.value);
    }
    return result;
  }

  static Map<String, double> _parseDoubleMap(dynamic raw) {
    if (raw is! Map) return {};
    final result = <String, double>{};
    for (final entry in raw.entries) {
      result[entry.key.toString()] = _safeNum(entry.value as num?);
    }
    return result;
  }

  static Map<int, Map<String, double>> _parseEquivalentsByMeal(dynamic raw) {
    if (raw is! Map) return {};
    final result = <int, Map<String, double>>{};
    for (final entry in raw.entries) {
      final mealIndex = int.tryParse(entry.key.toString());
      if (mealIndex == null) continue;
      result[mealIndex] = _parseDoubleMap(entry.value);
    }
    return result;
  }

  static double _safeNum(num? value) {
    if (value == null) return 0.0;
    final v = value.toDouble();
    if (v.isNaN || v.isInfinite) return 0.0;
    return v;
  }

  static String _normalizeEquivalentId(String id) {
    const legacy = {
      'aoa_bajo_grasa': 'aoa_bajo',
      'aceites_sin_proteina': 'grasas_sin_proteina',
    };
    return legacy[id] ?? id;
  }
}

class PlanSnapshot {
  final String planId;
  final String dateIso;
  final int version;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  const PlanSnapshot({
    required this.planId,
    required this.dateIso,
    required this.version,
    required this.data,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'planId': planId,
      'dateIso': dateIso,
      'version': version,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PlanSnapshot.fromJson(Map<String, dynamic> json) {
    return PlanSnapshot(
      planId: json['planId'] as String,
      dateIso: json['dateIso'] as String,
      version: json['version'] as int? ?? 1,
      data: Map<String, dynamic>.from(json['data'] as Map? ?? {}),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

enum WarningLevel { error, warning, info }

class ValidationWarning {
  final WarningLevel level;
  final String message;
  final String? suggestion;
  final VoidCallback? quickFix;

  const ValidationWarning({
    required this.level,
    required this.message,
    this.suggestion,
    this.quickFix,
  });

  Map<String, dynamic> toJson() {
    return {
      'level': level.name,
      'message': message,
      if (suggestion != null) 'suggestion': suggestion,
    };
  }

  factory ValidationWarning.fromJson(Map<String, dynamic> json) {
    return ValidationWarning(
      level: WarningLevel.values.firstWhere(
        (level) => level.name == json['level'],
        orElse: () => WarningLevel.info,
      ),
      message: json['message'] as String? ?? '',
      suggestion: json['suggestion'] as String?,
    );
  }
}

class ValidationStatus {
  final bool macrosVsEquivalentsOk;
  final bool equivalentsVsMealsOk;
  final bool allMealsHaveMinProtein;
  final double coherenceScore;

  const ValidationStatus({
    this.macrosVsEquivalentsOk = true,
    this.equivalentsVsMealsOk = true,
    this.allMealsHaveMinProtein = true,
    this.coherenceScore = 1.0,
  });

  ValidationStatus copyWith({
    bool? macrosVsEquivalentsOk,
    bool? equivalentsVsMealsOk,
    bool? allMealsHaveMinProtein,
    double? coherenceScore,
  }) {
    return ValidationStatus(
      macrosVsEquivalentsOk:
          macrosVsEquivalentsOk ?? this.macrosVsEquivalentsOk,
      equivalentsVsMealsOk: equivalentsVsMealsOk ?? this.equivalentsVsMealsOk,
      allMealsHaveMinProtein:
          allMealsHaveMinProtein ?? this.allMealsHaveMinProtein,
      coherenceScore: coherenceScore ?? this.coherenceScore,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'macrosVsEquivalentsOk': macrosVsEquivalentsOk,
      'equivalentsVsMealsOk': equivalentsVsMealsOk,
      'allMealsHaveMinProtein': allMealsHaveMinProtein,
      'coherenceScore': coherenceScore,
    };
  }

  factory ValidationStatus.fromJson(Map<String, dynamic> json) {
    return ValidationStatus(
      macrosVsEquivalentsOk: json['macrosVsEquivalentsOk'] as bool? ?? true,
      equivalentsVsMealsOk: json['equivalentsVsMealsOk'] as bool? ?? true,
      allMealsHaveMinProtein: json['allMealsHaveMinProtein'] as bool? ?? true,
      coherenceScore: (json['coherenceScore'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

class ValidationResult {
  final bool isValid;
  final List<ValidationWarning> warnings;
  final double coherenceScore;
  final ValidationStatus status;

  const ValidationResult({
    required this.isValid,
    required this.warnings,
    required this.coherenceScore,
    required this.status,
  });
}
