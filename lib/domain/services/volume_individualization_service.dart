import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/core/constants/training_interview_legacy_keys.dart';
import 'package:hcs_app_lap/core/enums/training_level.dart';
import 'package:hcs_app_lap/core/enums/gender.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/services/athlete_context_resolver.dart';
import 'package:hcs_app_lap/domain/services/volume_adjustment_calculator.dart';

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
    final vopIndividual =
        mevIndividual + 0.35 * (mrvIndividual - mevIndividual);

    return VolumeBounds(
      mevBase: mevBase,
      mrvBase: mrvBase,
      mevAdjustTotal: mevAdjust,
      mrvAdjustTotal: mrvAdjust,
      mevIndividual: mevIndividual,
      mrvIndividual: mrvIndividual,
      vopIndividual: vopIndividual,
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
        return (6, 16);
      case TrainingLevel.intermediate:
        return (12, 24);
      case TrainingLevel.advanced:
        return (18, 32);
    }
  }

  // ==================== MEV ADJUSTMENTS ====================

  double _getMevGenderAdjust(Gender gender) {
    return VolumeAdjustmentCalculator.sexVmeAdjust(gender);
  }

  double _getMevAgeAdjust(int ageYears) {
    return VolumeAdjustmentCalculator.ageVmeAdjust(ageYears);
  }

  double _getMevHeightAdjust(double heightCm) {
    return VolumeAdjustmentCalculator.heightVmeAdjust(heightCm);
  }

  double _getMevWeightAdjust(double weightKg) {
    return VolumeAdjustmentCalculator.weightVmeAdjust(weightKg);
  }

  double _getMevStrengthLevelAdjust(Map<String, dynamic> extra) {
    final level =
        extra[TrainingExtraKeys.strengthLevelClass]?.toString() ??
        extra[TrainingInterviewLegacyKeys.strengthLevelClass]?.toString();
    return VolumeAdjustmentCalculator.strengthLevelVmeAdjust(level);
  }

  double _getMevWorkCapacityAdjust(Map<String, dynamic> extra) {
    final score =
        extra[TrainingExtraKeys.workCapacityScore] as int? ??
        (extra[TrainingInterviewLegacyKeys.workCapacity] as num?)?.toInt() ??
        (extra[TrainingInterviewLegacyKeys.workCapacityScore] as num?)?.toInt();
    return VolumeAdjustmentCalculator.workCapacityVmeAdjust(score);
  }

  double _getMevRecoveryHistoryAdjust(Map<String, dynamic> extra) {
    final score =
        extra[TrainingExtraKeys.recoveryHistoryScore] as int? ??
        (extra[TrainingInterviewLegacyKeys.recoveryHistory] as num?)?.toInt() ??
        (extra[TrainingInterviewLegacyKeys.recoveryHistoryScore] as num?)
            ?.toInt();
    return VolumeAdjustmentCalculator.recoveryHistoryVmeAdjust(score);
  }

  double _getMevExternalRecoverySupportAdjust(Map<String, dynamic> extra) {
    final hasSupport =
        extra[TrainingExtraKeys.externalRecoverySupport] as bool? ??
        (extra[TrainingInterviewLegacyKeys.externalRecovery] as bool?);
    return VolumeAdjustmentCalculator.externalRecoverySupportVmeAdjust(
      hasSupport,
    );
  }

  double _getMevProgramNoveltyAdjust(Map<String, dynamic> extra) {
    final novelty =
        extra[TrainingExtraKeys.programNoveltyClass]?.toString() ??
        extra[TrainingInterviewLegacyKeys.programNovelty]?.toString();
    return VolumeAdjustmentCalculator.programNoveltyVmeAdjust(novelty);
  }

  double _getMevExternalPhysicalStressAdjust(Map<String, dynamic> extra) {
    final stress =
        extra[TrainingExtraKeys.externalPhysicalStressLevel]?.toString() ??
        extra[TrainingInterviewLegacyKeys.physicalStress]?.toString();
    return VolumeAdjustmentCalculator.externalPhysicalStressVmeAdjust(stress);
  }

  String? _resolveNonPhysicalStressLevel(Map<String, dynamic> extra) {
    final direct =
        extra[TrainingExtraKeys.nonPhysicalStressLevel2]?.toString() ??
        extra[TrainingInterviewLegacyKeys.nonPhysicalStressLevel2]
            ?.toString() ??
        extra[TrainingInterviewLegacyKeys.nonPhysicalStressLevel]?.toString();
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
    final direct =
        extra[TrainingExtraKeys.restQuality2]?.toString() ??
        extra[TrainingInterviewLegacyKeys.restQuality2]?.toString() ??
        extra[TrainingInterviewLegacyKeys.restQuality]?.toString();
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
    return VolumeAdjustmentCalculator.nonPhysicalStressVmeAdjust(
      _resolveNonPhysicalStressLevel(extra),
    );
  }

  double _getMevRestQualityAdjust(Map<String, dynamic> extra) {
    return VolumeAdjustmentCalculator.restQualityVmeAdjust(
      _resolveRestQuality(extra),
    );
  }

  double _getMevDietHabitsAdjust(Map<String, dynamic> extra) {
    final diet =
        extra[TrainingExtraKeys.dietHabitsClass]?.toString() ??
        extra[TrainingInterviewLegacyKeys.dietQuality]?.toString();
    return VolumeAdjustmentCalculator.dietHabitsVmeAdjust(diet);
  }

  double _getMevAnabolicsAdjust(bool usesAnabolics) {
    return VolumeAdjustmentCalculator.anabolicsVmeAdjust(usesAnabolics);
  }

  // ==================== MRV ADJUSTMENTS ====================

  double _getMrvGenderAdjust(Gender gender) {
    return VolumeAdjustmentCalculator.sexVmrAdjust(gender);
  }

  double _getMrvAgeAdjust(int ageYears) {
    return VolumeAdjustmentCalculator.ageVmrAdjust(ageYears);
  }

  double _getMrvHeightAdjust(double heightCm) {
    return VolumeAdjustmentCalculator.heightVmrAdjust(heightCm);
  }

  double _getMrvWeightAdjust(double weightKg) {
    return VolumeAdjustmentCalculator.weightVmrAdjust(weightKg);
  }

  double _getMrvStrengthLevelAdjust(Map<String, dynamic> extra) {
    final level =
        extra[TrainingExtraKeys.strengthLevelClass]?.toString() ??
        extra[TrainingInterviewLegacyKeys.strengthLevelClass]?.toString();
    return VolumeAdjustmentCalculator.strengthLevelVmrAdjust(level);
  }

  double _getMrvWorkCapacityAdjust(Map<String, dynamic> extra) {
    final score =
        extra[TrainingExtraKeys.workCapacityScore] as int? ??
        (extra[TrainingInterviewLegacyKeys.workCapacity] as num?)?.toInt() ??
        (extra[TrainingInterviewLegacyKeys.workCapacityScore] as num?)?.toInt();
    return VolumeAdjustmentCalculator.workCapacityVmrAdjust(score);
  }

  double _getMrvRecoveryHistoryAdjust(Map<String, dynamic> extra) {
    final score =
        extra[TrainingExtraKeys.recoveryHistoryScore] as int? ??
        (extra[TrainingInterviewLegacyKeys.recoveryHistory] as num?)?.toInt() ??
        (extra[TrainingInterviewLegacyKeys.recoveryHistoryScore] as num?)
            ?.toInt();
    return VolumeAdjustmentCalculator.recoveryHistoryVmrAdjust(score);
  }

  double _getMrvExternalRecoverySupportAdjust(Map<String, dynamic> extra) {
    final hasSupport =
        extra[TrainingExtraKeys.externalRecoverySupport] as bool? ??
        (extra[TrainingInterviewLegacyKeys.externalRecovery] as bool?);
    return VolumeAdjustmentCalculator.externalRecoverySupportVmrAdjust(
      hasSupport,
    );
  }

  double _getMrvProgramNoveltyAdjust(Map<String, dynamic> extra) {
    final novelty =
        extra[TrainingExtraKeys.programNoveltyClass]?.toString() ??
        extra[TrainingInterviewLegacyKeys.programNovelty]?.toString();
    return VolumeAdjustmentCalculator.programNoveltyVmrAdjust(novelty);
  }

  double _getMrvExternalPhysicalStressAdjust(Map<String, dynamic> extra) {
    final stress =
        extra[TrainingExtraKeys.externalPhysicalStressLevel]?.toString() ??
        extra[TrainingInterviewLegacyKeys.physicalStress]?.toString();
    return VolumeAdjustmentCalculator.externalPhysicalStressVmrAdjust(stress);
  }

  double _getMrvNonPhysicalStressAdjust(Map<String, dynamic> extra) {
    return VolumeAdjustmentCalculator.nonPhysicalStressVmrAdjust(
      _resolveNonPhysicalStressLevel(extra),
    );
  }

  double _getMrvRestQualityAdjust(Map<String, dynamic> extra) {
    return VolumeAdjustmentCalculator.restQualityVmrAdjust(
      _resolveRestQuality(extra),
    );
  }

  double _getMrvDietHabitsAdjust(Map<String, dynamic> extra) {
    final diet =
        extra[TrainingExtraKeys.dietHabitsClass]?.toString() ??
        extra[TrainingInterviewLegacyKeys.dietQuality]?.toString();
    return VolumeAdjustmentCalculator.dietHabitsVmrAdjust(diet);
  }

  double _getMrvAnabolicsAdjust(bool usesAnabolics) {
    return VolumeAdjustmentCalculator.anabolicsVmrAdjust(usesAnabolics);
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

  /// VOP individualizado final (base + ajustes)
  final double vopIndividual;

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
    required this.vopIndividual,
    required this.contributionsMev,
    required this.contributionsMrv,
  });

  @override
  String toString() {
    return 'VolumeBounds('
        'MEV: $mevBase + ${mevAdjustTotal.toStringAsFixed(1)} = ${mevIndividual.toStringAsFixed(1)}, '
        'MRV: $mrvBase + ${mrvAdjustTotal.toStringAsFixed(1)} = ${mrvIndividual.toStringAsFixed(1)}, '
        'VOP: ${vopIndividual.toStringAsFixed(1)}'
        ')';
  }
}
