import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/core/enums/training_level.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';

class SeriesAdjustmentEngine {
  const SeriesAdjustmentEngine();

  /// Cálculo principal
  Map<String, int> calculateBaseSeries(TrainingProfile profile) {
    final extra = profile.extra;
    final resolvedLevel =
        profile.trainingLevel ??
        parseTrainingLevel(
          (extra[TrainingExtraKeys.effectiveTrainingLevel] ??
            extra[TrainingExtraKeys.legacyTrainingLevel] ??
            extra[TrainingExtraKeys.trainingLevel])
              ?.toString(),
        );
    final base = _getBaseVolume(resolvedLevel);
    if (base.min <= 0 || base.max <= 0) {
      return {};
    }

    // Ajustes sistémicos
    double factor = 1.0;
    factor *= _sleepFactor(
      profile.avgSleepHours > 0 ? profile.avgSleepHours : null,
    );
    factor *= _stressFactor(
      extra[TrainingExtraKeys.perceivedStress] as String?,
    );
    factor *= _recoveryFactor(
      extra[TrainingExtraKeys.recoveryQuality] as String?,
    );
    factor *= (extra[TrainingExtraKeys.usesAnabolics] as bool? ?? false)
        ? 1.15
        : 1.0;
    factor *= _daysPerWeekFactor(extra[TrainingExtraKeys.daysPerWeek] as int?);

    final Map<String, int> finalSeries = {};

    // Convertir prioridades a listas
    final primary = _splitMuscles(
      extra[TrainingExtraKeys.priorityMusclesPrimary] as String?,
    );
    final secondary = _splitMuscles(
      extra[TrainingExtraKeys.priorityMusclesSecondary] as String?,
    );
    final tertiary = _splitMuscles(
      extra[TrainingExtraKeys.priorityMusclesTertiary] as String?,
    );

    // Precalcular serie base por rango (promedio del rango)
    final baseSeries = ((base.min + base.max) / 2).round();

    // Asignar valores por grupo muscular
    // CRÍTICO: Las prioridades NO afectan el volumen base
    // Solo influyen en orden, frecuencia y selección en fases posteriores
    for (final m in {...primary, ...secondary, ...tertiary}) {
      double muscleFactor = 1.0;

      // SOLO lesiones afectan el volumen
      if (_muscleIsInjured(extra[TrainingExtraKeys.injuries] as String?, m)) {
        muscleFactor *= 0.80;
      }

      final value = (baseSeries * muscleFactor * factor).round();

      if (value > 0) {
        finalSeries[m] = value;
      }
    }

    return finalSeries;
  }

  /// FALLBACK DE SEGURIDAD: Devuelve volúmenes por defecto basados solo en trainingLevel
  /// Útil cuando el perfil tiene trainingLevel pero baseVolumePerMuscle está vacío
  static Map<String, int> defaultVolumeForLevel(
    TrainingLevel level, {
    List<String>? muscles,
  }) {
    final defaultMuscles =
        muscles ??
        [
          'Pecho',
          'Espalda',
          'Hombros',
          'Bíceps',
          'Tríceps',
          'Cuádriceps',
          'Isquios',
          'Glúteos',
        ];

    final baseSeriesValue = switch (level) {
      TrainingLevel.beginner => 12,
      TrainingLevel.intermediate => 16,
      TrainingLevel.advanced => 20,
    };

    return {for (final muscle in defaultMuscles) muscle: baseSeriesValue};
  }

  // -------------------------
  // Helpers
  // -------------------------

  ({int min, int max}) _getBaseVolume(TrainingLevel? level) {
    switch (level) {
      case TrainingLevel.beginner:
        return (min: 12, max: 16);
      case TrainingLevel.intermediate:
        return (min: 14, max: 20);
      case TrainingLevel.advanced:
        return (min: 16, max: 24);
      default:
        return (min: 0, max: 0);
    }
  }

  double _sleepFactor(double? hours) {
    if (hours == null) return 1.0;
    if (hours < 6) return 0.80;
    if (hours < 7) return 0.90;
    if (hours <= 8) return 1.0;
    return 1.10;
  }

  double _stressFactor(String? stress) {
    switch (stress) {
      case 'Alto':
        return 0.80;
      case 'Medio':
        return 0.90;
      default:
        return 1.0;
    }
  }

  double _recoveryFactor(String? r) {
    switch (r) {
      case 'Mala':
        return 0.80;
      case 'Regular':
        return 0.90;
      case 'Buena':
        return 1.0;
      case 'Excelente':
        return 1.10;
      default:
        return 1.0;
    }
  }

  double _daysPerWeekFactor(int? d) {
    if (d == null) return 1.0;
    if (d <= 2) return 0.70;
    if (d <= 4) return 1.0;
    if (d <= 6) return 1.10;
    return 1.15;
  }

  List<String> _splitMuscles(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];
    return raw.split(',').map((e) => e.trim()).toList();
  }

  bool _muscleIsInjured(String? injuries, String muscle) {
    if (injuries == null) return false;
    return injuries.toLowerCase().contains(muscle.toLowerCase());
  }
}
