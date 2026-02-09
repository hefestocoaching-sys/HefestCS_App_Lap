import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/core/enums/training_level.dart';
import 'package:hcs_app_lap/core/enums/gender.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/services/athlete_context_resolver.dart';

/// Clasificación de altura
enum HeightClass {
  low, // Bajo (<160 cm)
  medium, // Medio (160-175 cm)
  high, // Alto (175-190 cm)
  veryHigh, // Muy Alto (>=190 cm)
}

/// Clasificación de peso corporal
enum WeightClass {
  light, // Ligero (<60 kg)
  medium, // Medio (60-80 kg)
  semiheavy, // Semi-Pesado (80-100 kg)
  heavy, // Pesado (>=100 kg)
}

/// Servicio para calcular los límites de volumen individualizados (MEV/MRV)
/// basados en las tablas aditivas del PDF de individualización
class VolumeIndividualizationService {
  const VolumeIndividualizationService();

  /// Calcula los límites de volumen MEV y MRV individualizados
  VolumeBounds computeBounds({
    required TrainingLevel level,
    required AthleteContext athlete,
    required Map<String, dynamic> trainingExtra,
  }) {
    // VALIDACIÓN: Asegurar que trainingExtra no esté vacío
    if (trainingExtra.isEmpty) {
      throw StateError(
        'TrainingExtra está vacío. El TrainingProfile debe contener datos de entrenamiento. '
        'Asegúrate de que la Evaluación Entrenamiento se guardó correctamente.',
      );
    }

    // 1. Calcular MEV y MRV base según nivel de entrenamiento
    final (mevBase, mrvBase) = _getBaseBounds(level);

    // 2. Maps de contribuciones
    final contributionsMev = <String, double>{};
    final contributionsMrv = <String, double>{};

    // 3. Calcular ajustes aditivos MEV
    contributionsMev['gender'] = _getMevGenderAdjust(athlete.sex);
    contributionsMev['age'] = _getMevAgeAdjust(athlete.ageYears);
    contributionsMev['height'] = athlete.heightCm != null
        ? _getMevHeightAdjust(athlete.heightCm!)
        : 0.0;
    contributionsMev['weight'] = athlete.weightKg != null
        ? _getMevWeightAdjust(athlete.weightKg!)
        : 0.0;
    contributionsMev['strengthLevel'] = _getMevStrengthLevelAdjust(
      trainingExtra,
    );
    contributionsMev['workCapacity'] = _getMevWorkCapacityAdjust(trainingExtra);
    contributionsMev['recoveryHistory'] = _getMevRecoveryHistoryAdjust(
      trainingExtra,
    );
    contributionsMev['recoverySupport'] = _getMevExternalRecoverySupportAdjust(
      trainingExtra,
    );
    contributionsMev['novelty'] = _getMevProgramNoveltyAdjust(trainingExtra);
    contributionsMev['physicalStress'] = _getMevExternalPhysicalStressAdjust(
      trainingExtra,
    );
    contributionsMev['nonPhysicalStress'] = _getMevNonPhysicalStressAdjust(
      trainingExtra,
    );
    contributionsMev['restQuality'] = _getMevRestQualityAdjust(trainingExtra);
    contributionsMev['diet'] = _getMevDietHabitsAdjust(trainingExtra);
    contributionsMev['anabolics'] = _getMevAnabolicsAdjust(
      athlete.usesAnabolics,
    );

    // 4. Calcular ajustes aditivos MRV
    contributionsMrv['gender'] = _getMrvGenderAdjust(athlete.sex);
    contributionsMrv['age'] = _getMrvAgeAdjust(athlete.ageYears);
    contributionsMrv['height'] = athlete.heightCm != null
        ? _getMrvHeightAdjust(athlete.heightCm!)
        : 0.0;
    contributionsMrv['weight'] = athlete.weightKg != null
        ? _getMrvWeightAdjust(athlete.weightKg!)
        : 0.0;
    contributionsMrv['strengthLevel'] = _getMrvStrengthLevelAdjust(
      trainingExtra,
    );
    contributionsMrv['workCapacity'] = _getMrvWorkCapacityAdjust(trainingExtra);
    contributionsMrv['recoveryHistory'] = _getMrvRecoveryHistoryAdjust(
      trainingExtra,
    );
    contributionsMrv['recoverySupport'] = _getMrvExternalRecoverySupportAdjust(
      trainingExtra,
    );
    contributionsMrv['novelty'] = _getMrvProgramNoveltyAdjust(trainingExtra);
    contributionsMrv['physicalStress'] = _getMrvExternalPhysicalStressAdjust(
      trainingExtra,
    );
    contributionsMrv['nonPhysicalStress'] = _getMrvNonPhysicalStressAdjust(
      trainingExtra,
    );
    contributionsMrv['restQuality'] = _getMrvRestQualityAdjust(trainingExtra);
    contributionsMrv['diet'] = _getMrvDietHabitsAdjust(trainingExtra);
    contributionsMrv['anabolics'] = _getMrvAnabolicsAdjust(
      athlete.usesAnabolics,
    );

    // 5. Calcular totales
    final mevAdjust = contributionsMev.values.fold(0.0, (sum, v) => sum + v);
    final mrvAdjust = contributionsMrv.values.fold(0.0, (sum, v) => sum + v);

    // 6. Calcular valores individualizados finales
    final mevIndividual = mevBase + mevAdjust;
    final mrvIndividual = mrvBase + mrvAdjust;

    return VolumeBounds(
      mevBase: mevBase,
      mrvBase: mrvBase,
      mevAdjustTotal: mevAdjust,
      mrvAdjustTotal: mrvAdjust,
      mevIndividual: mevIndividual,
      mrvIndividual: mrvIndividual,
      contributionsMev: contributionsMev,
      contributionsMrv: contributionsMrv,
    );
  }

  /// Método helper para crear AthleteContext desde TrainingProfile
  /// Útil cuando no se tiene acceso al Client completo
  AthleteContext buildAthleteContextFromProfile(TrainingProfile profile) {
    // Extraer edad desde profile (asumiendo que está calculada)
    final ageYears = profile.age ?? 30; // fallback razonable

    // Extraer sexo
    final sex = profile.gender ?? Gender.male; // fallback

    // Extraer altura desde extra o usar valor del profile
    final heightCmRaw = profile.extra[TrainingExtraKeys.heightCm];
    final heightCm = heightCmRaw is int
        ? heightCmRaw.toDouble()
        : (heightCmRaw is double ? heightCmRaw : 170.0);

    // Extraer peso desde profile
    final weightKg = profile.bodyWeight ?? 70.0;

    // Extraer usesAnabolics
    final usesAnabolics = profile.usesAnabolics;

    return AthleteContext(
      ageYears: ageYears,
      sex: sex,
      heightCm: heightCm,
      weightKg: weightKg,
      usesAnabolics: usesAnabolics,
    );
  }

  // ==================== BASE BOUNDS ====================

  (int mevBase, int mrvBase) _getBaseBounds(TrainingLevel level) {
    switch (level) {
      case TrainingLevel.beginner:
        // MEV: 6-8 → promedio 7
        // MRV: 10-12 → promedio 11
        return (7, 11);
      case TrainingLevel.intermediate:
        // MEV: 8-10 → promedio 9
        // MRV: 14-18 → promedio 16
        return (9, 16);
      case TrainingLevel.advanced:
        // MEV: 10-12 → promedio 11
        // MRV: 18-22 → promedio 20
        return (11, 20);
    }
  }

  // ==================== CLASIFICACIÓN ====================

  /// Clasifica altura en categorías según rangos antropométricos
  HeightClass _classifyHeight(double heightCm) {
    if (heightCm < 160) return HeightClass.low;
    if (heightCm < 175) return HeightClass.medium;
    if (heightCm < 190) return HeightClass.high;
    return HeightClass.veryHigh;
  }

  /// Clasifica peso corporal en categorías
  WeightClass _classifyWeight(double weightKg) {
    if (weightKg < 60) return WeightClass.light;
    if (weightKg < 80) return WeightClass.medium;
    if (weightKg < 100) return WeightClass.semiheavy;
    return WeightClass.heavy;
  }

  // ==================== MEV ADJUSTMENTS ====================

  double _getMevGenderAdjust(Gender gender) {
    return gender.isFemale ? 1.5 : 0.0; // mujer = +1.5, hombre = 0
  }

  double _getMevAgeAdjust(int ageYears) {
    if (ageYears < 20) return 0.5;
    if (ageYears >= 20 && ageYears <= 29) return 0.0;
    if (ageYears >= 30 && ageYears <= 39) return -0.5;
    if (ageYears >= 40) return -1.0;
    return 0.0;
  }

  double _getMevHeightAdjust(double heightCm) {
    final heightClass = _classifyHeight(heightCm);
    switch (heightClass) {
      case HeightClass.low:
        return -0.5;
      case HeightClass.medium:
        return 0.0;
      case HeightClass.high:
        return 0.5;
      case HeightClass.veryHigh:
        return 1.0;
    }
  }

  double _getMevWeightAdjust(double weightKg) {
    final weightClass = _classifyWeight(weightKg);
    switch (weightClass) {
      case WeightClass.light:
        return -0.5;
      case WeightClass.medium:
        return 0.0;
      case WeightClass.semiheavy:
        return 0.5;
      case WeightClass.heavy:
        return 1.0;
    }
  }

  double _getMevStrengthLevelAdjust(Map<String, dynamic> extra) {
    final level = extra[TrainingExtraKeys.strengthLevelClass] as String?;
    if (level == null) {
      throw StateError(
        'Falta: strengthLevelClass. Este campo debe completarse en Evaluación Entrenamiento.',
      );
    }
    switch (level) {
      case 'B':
        return -1.0; // Bajo
      case 'M':
        return -0.5; // Medio
      case 'A':
        return 0.0; // Alto
      case 'MA':
        return 0.5; // Muy Alto
      default:
        return 0.0;
    }
  }

  double _getMevWorkCapacityAdjust(Map<String, dynamic> extra) {
    final score = extra[TrainingExtraKeys.workCapacityScore] as int?;
    if (score == null) {
      throw StateError(
        'Falta: workCapacityScore. Completa la evaluación de capacidad de trabajo.',
      );
    }
    switch (score) {
      case 1:
        return -1.0;
      case 2:
        return -0.5;
      case 3:
        return 0.0;
      case 4:
        return 0.5;
      case 5:
        return 1.0;
      default:
        return 0.0;
    }
  }

  double _getMevRecoveryHistoryAdjust(Map<String, dynamic> extra) {
    final score = extra[TrainingExtraKeys.recoveryHistoryScore] as int?;
    if (score == null) {
      throw StateError(
        'Falta: recoveryHistoryScore. Completa la evaluación de historial de recuperación.',
      );
    }
    switch (score) {
      case 1:
        return -1.0;
      case 2:
        return -0.5;
      case 3:
        return 0.0;
      case 4:
        return 0.5;
      case 5:
        return 1.0;
      default:
        return 0.0;
    }
  }

  double _getMevExternalRecoverySupportAdjust(Map<String, dynamic> extra) {
    final hasSupport =
        extra[TrainingExtraKeys.externalRecoverySupport] as bool?;
    if (hasSupport == null) return 0.0;
    return hasSupport ? 0.5 : 0.0;
  }

  double _getMevProgramNoveltyAdjust(Map<String, dynamic> extra) {
    final novelty = extra[TrainingExtraKeys.programNoveltyClass] as String?;
    if (novelty == null) return 0.0;
    switch (novelty) {
      case 'N':
        return -1.0; // Nulo
      case 'B':
        return -0.5; // Bajo
      case 'I':
        return 0.0; // Intermedio
      case 'A':
        return 0.5; // Alto
      default:
        return 0.0;
    }
  }

  double _getMevExternalPhysicalStressAdjust(Map<String, dynamic> extra) {
    final stress =
        extra[TrainingExtraKeys.externalPhysicalStressLevel] as String?;
    if (stress == null) return 0.0;
    switch (stress) {
      case 'B':
        return 0.5; // Bajo
      case 'N':
        return 0.0; // Normal
      case 'I':
        return -0.5; // Intermedio
      case 'A':
        return -1.0; // Alto
      default:
        return 0.0;
    }
  }

  String? _resolveNonPhysicalStressLevel(Map<String, dynamic> extra) {
    final direct = extra[TrainingExtraKeys.nonPhysicalStressLevel2] as String?;
    if (direct != null) return direct;
    final fallback = extra[TrainingExtraKeys.stressLevel] as String?;
    switch (fallback) {
      case 'low':
        return 'B';
      case 'moderate':
        return 'P';
      case 'high':
        return 'A';
      default:
        return null;
    }
  }

  String? _resolveRestQuality(Map<String, dynamic> extra) {
    final direct = extra[TrainingExtraKeys.restQuality2] as String?;
    if (direct != null) return direct;
    final fallback = extra[TrainingExtraKeys.sleepBucket] as String?;
    switch (fallback) {
      case 'moreThanEight':
      case 'sevenToEight':
        return 'A';
      case 'sixToSeven':
        return 'P';
      case 'lessThan6':
        return 'B';
      default:
        return null;
    }
  }

  double _getMevNonPhysicalStressAdjust(Map<String, dynamic> extra) {
    final stress = _resolveNonPhysicalStressLevel(extra);
    if (stress == null) return 0.0;
    switch (stress) {
      case 'B':
        return 0.5; // Bajo
      case 'P':
        return 0.0; // Promedio
      case 'A':
        return -0.5; // Alto
      default:
        return 0.0;
    }
  }

  double _getMevRestQualityAdjust(Map<String, dynamic> extra) {
    final quality = _resolveRestQuality(extra);
    if (quality == null) return 0.0;
    switch (quality) {
      case 'A':
        return 0.5; // Alta
      case 'P':
        return 0.0; // Promedio
      case 'B':
        return -0.5; // Baja
      default:
        return 0.0;
    }
  }

  double _getMevDietHabitsAdjust(Map<String, dynamic> extra) {
    final diet = extra[TrainingExtraKeys.dietHabitsClass] as String?;
    if (diet == null) return 0.0;
    switch (diet) {
      case 'ISO':
        return 0.0; // Isocalórico
      case 'DCB':
        return -0.5; // Déficit Bajo
      case 'DCM':
        return -1.0; // Déficit Medio
      case 'DCA':
        return -1.5; // Déficit Alto
      case 'SCB':
        return 0.5; // Superávit Bajo
      case 'SCM':
        return 1.0; // Superávit Medio
      case 'SCA':
        return 1.5; // Superávit Alto
      default:
        return 0.0;
    }
  }

  double _getMevAnabolicsAdjust(bool usesAnabolics) {
    return usesAnabolics ? -1.5 : 0.0;
  }

  // ==================== MRV ADJUSTMENTS ====================

  double _getMrvGenderAdjust(Gender gender) {
    return gender.isFemale ? 3.0 : 0.0; // mujer = +3.0, hombre = 0
  }

  double _getMrvAgeAdjust(int ageYears) {
    if (ageYears < 20) return 1.0;
    if (ageYears >= 20 && ageYears <= 29) return 0.0;
    if (ageYears >= 30 && ageYears <= 39) return -1.0;
    if (ageYears >= 40) return -2.0;
    return 0.0;
  }

  double _getMrvHeightAdjust(double heightCm) {
    final heightClass = _classifyHeight(heightCm);
    switch (heightClass) {
      case HeightClass.low:
        return -1.0;
      case HeightClass.medium:
        return 0.0;
      case HeightClass.high:
        return 1.0;
      case HeightClass.veryHigh:
        return 2.0;
    }
  }

  double _getMrvWeightAdjust(double weightKg) {
    final weightClass = _classifyWeight(weightKg);
    switch (weightClass) {
      case WeightClass.light:
        return -1.0;
      case WeightClass.medium:
        return 0.0;
      case WeightClass.semiheavy:
        return 1.0;
      case WeightClass.heavy:
        return 2.0;
    }
  }

  double _getMrvStrengthLevelAdjust(Map<String, dynamic> extra) {
    final level = extra[TrainingExtraKeys.strengthLevelClass] as String?;
    if (level == null) return 0.0;
    switch (level) {
      case 'B':
        return -2.0; // Bajo
      case 'M':
        return -1.0; // Medio
      case 'A':
        return 0.0; // Alto
      case 'MA':
        return 1.0; // Muy Alto
      default:
        return 0.0;
    }
  }

  double _getMrvWorkCapacityAdjust(Map<String, dynamic> extra) {
    final score = extra[TrainingExtraKeys.workCapacityScore] as int?;
    if (score == null) return 0.0;
    switch (score) {
      case 1:
        return -2.0;
      case 2:
        return -1.0;
      case 3:
        return 0.0;
      case 4:
        return 1.0;
      case 5:
        return 2.0;
      default:
        return 0.0;
    }
  }

  double _getMrvRecoveryHistoryAdjust(Map<String, dynamic> extra) {
    final score = extra[TrainingExtraKeys.recoveryHistoryScore] as int?;
    if (score == null) return 0.0;
    switch (score) {
      case 1:
        return -2.0;
      case 2:
        return -1.0;
      case 3:
        return 0.0;
      case 4:
        return 1.0;
      case 5:
        return 2.0;
      default:
        return 0.0;
    }
  }

  double _getMrvExternalRecoverySupportAdjust(Map<String, dynamic> extra) {
    final hasSupport =
        extra[TrainingExtraKeys.externalRecoverySupport] as bool?;
    if (hasSupport == null) return 0.0;
    return hasSupport ? 1.0 : 0.0;
  }

  double _getMrvProgramNoveltyAdjust(Map<String, dynamic> extra) {
    final novelty = extra[TrainingExtraKeys.programNoveltyClass] as String?;
    if (novelty == null) return 0.0;
    switch (novelty) {
      case 'N':
        return -2.0; // Nulo
      case 'B':
        return -1.0; // Bajo
      case 'I':
        return 0.0; // Intermedio
      case 'A':
        return 1.0; // Alto
      default:
        return 0.0;
    }
  }

  double _getMrvExternalPhysicalStressAdjust(Map<String, dynamic> extra) {
    final stress =
        extra[TrainingExtraKeys.externalPhysicalStressLevel] as String?;
    if (stress == null) return 0.0;
    switch (stress) {
      case 'B':
        return 1.0; // Bajo
      case 'N':
        return 0.0; // Normal
      case 'I':
        return -1.0; // Intermedio
      case 'A':
        return -2.0; // Alto
      default:
        return 0.0;
    }
  }

  double _getMrvNonPhysicalStressAdjust(Map<String, dynamic> extra) {
    final stress = _resolveNonPhysicalStressLevel(extra);
    if (stress == null) return 0.0;
    switch (stress) {
      case 'B':
        return 1.0; // Bajo
      case 'P':
        return 0.0; // Promedio
      case 'A':
        return -1.0; // Alto
      default:
        return 0.0;
    }
  }

  double _getMrvRestQualityAdjust(Map<String, dynamic> extra) {
    final quality = _resolveRestQuality(extra);
    if (quality == null) return 0.0;
    switch (quality) {
      case 'A':
        return 1.0; // Alta
      case 'P':
        return 0.0; // Promedio
      case 'B':
        return -1.0; // Baja
      default:
        return 0.0;
    }
  }

  double _getMrvDietHabitsAdjust(Map<String, dynamic> extra) {
    final diet = extra[TrainingExtraKeys.dietHabitsClass] as String?;
    if (diet == null) return 0.0;
    switch (diet) {
      case 'ISO':
        return 0.0; // Isocalórico
      case 'DCB':
        return -1.0; // Déficit Bajo
      case 'DCM':
        return -2.0; // Déficit Medio
      case 'DCA':
        return -3.0; // Déficit Alto
      case 'SCB':
        return 1.0; // Superávit Bajo
      case 'SCM':
        return 2.0; // Superávit Medio
      case 'SCA':
        return 3.0; // Superávit Alto
      default:
        return 0.0;
    }
  }

  double _getMrvAnabolicsAdjust(bool usesAnabolics) {
    return usesAnabolics ? 3.0 : 0.0;
  }
}

/// Resultado del cálculo de límites de volumen individualizados
class VolumeBounds {
  /// MEV base según nivel de entrenamiento
  final int mevBase;

  /// MRV base según nivel de entrenamiento
  final int mrvBase;

  /// Suma total de ajustes MEV (puede ser negativa)
  final double mevAdjustTotal;

  /// Suma total de ajustes MRV (puede ser negativa)
  final double mrvAdjustTotal;

  /// MEV individualizado final (base + ajustes)
  final double mevIndividual;

  /// MRV individualizado final (base + ajustes)
  final double mrvIndividual;

  /// Contribuciones individuales por factor (MEV)
  final Map<String, double> contributionsMev;

  /// Contribuciones individuales por factor (MRV)
  final Map<String, double> contributionsMrv;

  const VolumeBounds({
    required this.mevBase,
    required this.mrvBase,
    required this.mevAdjustTotal,
    required this.mrvAdjustTotal,
    required this.mevIndividual,
    required this.mrvIndividual,
    required this.contributionsMev,
    required this.contributionsMrv,
  });

  @override
  String toString() {
    return 'VolumeBounds('
        'MEV: $mevBase + ${mevAdjustTotal.toStringAsFixed(1)} = ${mevIndividual.toStringAsFixed(1)}, '
        'MRV: $mrvBase + ${mrvAdjustTotal.toStringAsFixed(1)} = ${mrvIndividual.toStringAsFixed(1)}'
        ')';
  }
}
