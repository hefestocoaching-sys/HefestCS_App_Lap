import 'package:hcs_app_lap/utils/mets_data.dart';

/// Modelo auxiliar para la UI de seleccion de formulas TMB.
class TMBFormulaInfo {
  final String key;
  final String population;
  final String requires;
  final String equation;
  final double value;
  final bool requiresLBM;
  final bool isObesityFormula;

  const TMBFormulaInfo({
    required this.key,
    required this.population,
    required this.requires,
    this.equation = '',
    required this.value,
    this.requiresLBM = false,
    this.isObesityFormula = false,
  });
}

/// Modelo que representa una actividad fisica realizada por el usuario en un dia especifico.
class UserActivity {
  final String day;
  final MetActivity metActivity;
  final double metValue;
  int durationMinutes;

  UserActivity({
    required this.day,
    required this.metActivity,
    required this.metValue,
    required this.durationMinutes,
  });

  double get metMinutes => metValue * durationMinutes;

  Map<String, dynamic> toJson() => {
    'day': day,
    'category': metActivity.category,
    'activityName': metActivity.activityName,
    'metValue': metValue,
    'durationMinutes': durationMinutes,
  };

  factory UserActivity.fromJson(Map<String, dynamic> json) {
    MetActivity resolved = metLibrary.first;
    final rawCategory = json['category']?.toString();
    final rawName = json['activityName']?.toString();
    for (final activity in metLibrary) {
      if (rawName != null &&
          activity.activityName == rawName &&
          (rawCategory == null || activity.category == rawCategory)) {
        resolved = activity;
        break;
      }
    }

    final rawMet = json['metValue'];
    final metValue = rawMet is num
        ? rawMet.toDouble()
        : (double.tryParse(rawMet?.toString() ?? '') ??
              resolved.metOptions.first);
    final rawDuration = json['durationMinutes'];
    final duration = rawDuration is num
        ? rawDuration.toInt()
        : (int.tryParse(rawDuration?.toString() ?? '') ?? 0);

    return UserActivity(
      day: json['day']?.toString() ?? '',
      metActivity: resolved,
      metValue: metValue,
      durationMinutes: duration,
    );
  }
}
