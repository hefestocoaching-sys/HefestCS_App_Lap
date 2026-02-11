import 'package:hcs_app_lap/domain/entities/clinical_restriction_profile.dart';
import 'package:hcs_app_lap/domain/entities/digestive_intolerances.dart';
import 'package:hcs_app_lap/domain/entities/clinical_conditions.dart';

import 'daily_macro_settings.dart';
import 'daily_meal_plan.dart';

class NutritionSettings {
  final String? planType; // "Mensual", etc.
  final DateTime? planStartDate;
  final DateTime? planEndDate;
  final int? kcal;
  final Map<String, int>? dailyKcal;

  /// Tus ajustes por día (manteniendo tu modelo):
  final Map<String, DailyMacroSettings>? weeklyMacroSettings;

  /// Mapa de planes de comidas diarios, usando el día como clave (ej. "Lunes")
  final Map<String, DailyMealPlan>? dailyMealPlans;

  /// Perfil clínico computable P0 (motor de nutrición)
  /// Si no existe, defaults seguros (sin restricciones)
  final ClinicalRestrictionProfile clinicalRestrictionProfile;

  final Map<String, dynamic> extra;

  const NutritionSettings({
    this.planType,
    this.planStartDate,
    this.planEndDate,
    this.kcal,
    this.dailyKcal,
    this.weeklyMacroSettings,
    this.dailyMealPlans,
    ClinicalRestrictionProfile? clinicalRestrictionProfile,
    this.extra = const {},
  }) : clinicalRestrictionProfile =
           clinicalRestrictionProfile ??
           const ClinicalRestrictionProfile(
             foodAllergies: {
               'milk': false,
               'egg': false,
               'fish': false,
               'shellfish': false,
               'peanuts': false,
               'treeNuts': false,
               'wheat': false,
               'soy': false,
               'sesame': false,
             },
             digestiveIntolerances: DigestiveIntolerances(),
             clinicalConditions: ClinicalConditions(),
             dietaryPattern: 'omnivore',
             relevantMedications: {},
           );

  NutritionSettings copyWith({
    String? planType,
    DateTime? planStartDate,
    DateTime? planEndDate,
    int? kcal,
    Map<String, int>? dailyKcal,
    Map<String, DailyMacroSettings>? weeklyMacroSettings,
    Map<String, DailyMealPlan>? dailyMealPlans,
    ClinicalRestrictionProfile? clinicalRestrictionProfile,
    Map<String, dynamic>? extra,
  }) {
    return NutritionSettings(
      planType: planType ?? this.planType,
      planStartDate: planStartDate ?? this.planStartDate,
      planEndDate: planEndDate ?? this.planEndDate,
      kcal: kcal ?? this.kcal,
      dailyKcal: dailyKcal ?? this.dailyKcal,
      weeklyMacroSettings: weeklyMacroSettings ?? this.weeklyMacroSettings,
      dailyMealPlans: dailyMealPlans ?? this.dailyMealPlans,
      clinicalRestrictionProfile:
          clinicalRestrictionProfile ?? this.clinicalRestrictionProfile,
      extra: extra ?? this.extra,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'planType': planType,
      'planStartDate': planStartDate?.toIso8601String(),
      'planEndDate': planEndDate?.toIso8601String(),
      'kcal': kcal,
      'dailyKcal': dailyKcal,
      'weeklyMacroSettings': weeklyMacroSettings?.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'dailyMealPlans': dailyMealPlans?.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'clinicalRestrictionProfile': clinicalRestrictionProfile.toMap(),
      'extra': extra,
    };
  }

  factory NutritionSettings.fromJson(Map<String, dynamic> json) {
    // Normalización de clinicalRestrictionProfile
    ClinicalRestrictionProfile clinicalRestrictionProfile;
    if (json['clinicalRestrictionProfile'] is Map) {
      clinicalRestrictionProfile = ClinicalRestrictionProfile.fromMap(
        Map<String, dynamic>.from(json['clinicalRestrictionProfile'] as Map),
      );
    } else {
      // Si no existe, usar defaults
      clinicalRestrictionProfile = ClinicalRestrictionProfile.defaults();
    }

    return NutritionSettings(
      planType: json['planType'] as String?,
      planStartDate: json['planStartDate'] != null
          ? DateTime.parse(json['planStartDate'] as String)
          : null,
      planEndDate: json['planEndDate'] != null
          ? DateTime.parse(json['planEndDate'] as String)
          : null,
      kcal: json['kcal'] as int?,
      dailyKcal: json['dailyKcal'] != null
          ? Map<String, int>.from(json['dailyKcal'] as Map)
          : null,
      weeklyMacroSettings: json['weeklyMacroSettings'] != null
          ? Map<String, DailyMacroSettings>.from(
              (json['weeklyMacroSettings'] as Map).map(
                (key, value) => MapEntry(
                  key as String,
                  DailyMacroSettings.fromJson(value as Map<String, dynamic>),
                ),
              ),
            )
          : null,
      dailyMealPlans: json['dailyMealPlans'] != null
          ? Map<String, DailyMealPlan>.from(
              (json['dailyMealPlans'] as Map).map(
                (key, value) => MapEntry(
                  key as String,
                  DailyMealPlan.fromJson(value as Map<String, dynamic>),
                ),
              ),
            )
          : null,
      clinicalRestrictionProfile: clinicalRestrictionProfile,
      extra: Map<String, dynamic>.from(json['extra'] as Map? ?? {}),
    );
  }

  @override
  String toString() {
    return '''NutritionSettings(planType: $planType, planStartDate: $planStartDate, planEndDate: $planEndDate, kcal: $kcal, 
    dailyKcal: $dailyKcal, weeklyMacroSettings: $weeklyMacroSettings, dailyMealPlans: $dailyMealPlans, 
    clinicalRestrictionProfile: $clinicalRestrictionProfile, extra: $extra)''';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NutritionSettings &&
          runtimeType == other.runtimeType &&
          planType == other.planType &&
          planStartDate == other.planStartDate &&
          planEndDate == other.planEndDate &&
          kcal == other.kcal &&
          dailyKcal == other.dailyKcal &&
          weeklyMacroSettings == other.weeklyMacroSettings &&
          dailyMealPlans == other.dailyMealPlans &&
          clinicalRestrictionProfile == other.clinicalRestrictionProfile &&
          extra == other.extra;

  @override
  int get hashCode =>
      planType.hashCode ^
      planStartDate.hashCode ^
      planEndDate.hashCode ^
      kcal.hashCode ^
      dailyKcal.hashCode ^
      weeklyMacroSettings.hashCode ^
      dailyMealPlans.hashCode ^
      clinicalRestrictionProfile.hashCode ^
      extra.hashCode;
}
