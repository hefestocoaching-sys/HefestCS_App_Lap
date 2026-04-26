import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/core/enums/gender.dart';
import 'package:hcs_app_lap/core/enums/training_level.dart';
import 'package:hcs_app_lap/domain/training_v3/constants/muscle_volume_landmarks_ssot.dart';

class VolumeAdjustmentResult {
  final int vmeBase;
  final int vmrBase;
  final double sumAdjustmentsVme;
  final double sumAdjustmentsVmr;
  final double vmeCalculated;
  final double vmrCalculated;
  final double vopCalculated;
  final Map<String, double> adjustmentsVme;
  final Map<String, double> adjustmentsVmr;

  const VolumeAdjustmentResult({
    required this.vmeBase,
    required this.vmrBase,
    required this.sumAdjustmentsVme,
    required this.sumAdjustmentsVmr,
    required this.vmeCalculated,
    required this.vmrCalculated,
    required this.vopCalculated,
    required this.adjustmentsVme,
    required this.adjustmentsVmr,
  });

  GlobalVolumeAdjustments toGlobalAdjustments() => GlobalVolumeAdjustments(
    deltaVme: sumAdjustmentsVme,
    deltaVmr: sumAdjustmentsVmr,
  );
}

class VolumeAdjustmentCalculator {
  const VolumeAdjustmentCalculator._();

  static VolumeAdjustmentResult calculate({
    required TrainingLevel level,
    required Gender sex,
    required int ageYears,
    required double? heightCm,
    required double? weightKg,
    required Map<String, dynamic> extra,
    required bool usesAnabolics,
  }) {
    final (vmeBase, vmrBase) = baseBounds(level);

    final adjustmentsVme = <String, double>{
      'sex': sexVmeAdjust(sex),
      'age': ageVmeAdjust(ageYears),
      'height': heightCm == null ? 0.0 : heightVmeAdjust(heightCm),
      'weight': weightKg == null ? 0.0 : weightVmeAdjust(weightKg),
      'strengthLevel': strengthLevelVmeAdjust(
        _readString(extra, const [TrainingExtraKeys.strengthLevelClass]),
      ),
      'workCapacity': workCapacityVmeAdjust(
        _readInt(extra, const [TrainingExtraKeys.workCapacityScore]),
      ),
      'recoveryHistory': recoveryHistoryVmeAdjust(
        _readInt(extra, const [TrainingExtraKeys.recoveryHistoryScore]),
      ),
      'externalRecoverySupport': externalRecoverySupportVmeAdjust(
        _readBool(extra, const [TrainingExtraKeys.externalRecoverySupport]),
      ),
      'programNovelty': programNoveltyVmeAdjust(
        _readString(extra, const [
          TrainingExtraKeys.programNoveltyClass,
          'programNovelty',
        ]),
      ),
      'externalPhysicalStress': externalPhysicalStressVmeAdjust(
        _readString(extra, const [
          TrainingExtraKeys.externalPhysicalStressLevel,
          'physicalStress',
        ]),
      ),
      'nonPhysicalStress': nonPhysicalStressVmeAdjust(
        _readString(extra, const [
          TrainingExtraKeys.nonPhysicalStressLevel2,
          'nonPhysicalStressLevel',
          'nonPhysicalStress',
          TrainingExtraKeys.stressLevel,
        ]),
      ),
      'restQuality': restQualityVmeAdjust(
        _readString(extra, const [
          TrainingExtraKeys.restQuality2,
          'restQuality',
          TrainingExtraKeys.sleepBucket,
        ]),
      ),
      'diet': dietHabitsVmeAdjust(
        _readString(extra, const [
          TrainingExtraKeys.dietHabitsClass,
          'dietQuality',
        ]),
      ),
      'anabolics': anabolicsVmeAdjust(usesAnabolics),
    };

    final adjustmentsVmr = <String, double>{
      'sex': sexVmrAdjust(sex),
      'age': ageVmrAdjust(ageYears),
      'height': heightCm == null ? 0.0 : heightVmrAdjust(heightCm),
      'weight': weightKg == null ? 0.0 : weightVmrAdjust(weightKg),
      'strengthLevel': strengthLevelVmrAdjust(
        _readString(extra, const [TrainingExtraKeys.strengthLevelClass]),
      ),
      'workCapacity': workCapacityVmrAdjust(
        _readInt(extra, const [TrainingExtraKeys.workCapacityScore]),
      ),
      'recoveryHistory': recoveryHistoryVmrAdjust(
        _readInt(extra, const [TrainingExtraKeys.recoveryHistoryScore]),
      ),
      'externalRecoverySupport': externalRecoverySupportVmrAdjust(
        _readBool(extra, const [TrainingExtraKeys.externalRecoverySupport]),
      ),
      'programNovelty': programNoveltyVmrAdjust(
        _readString(extra, const [
          TrainingExtraKeys.programNoveltyClass,
          'programNovelty',
        ]),
      ),
      'externalPhysicalStress': externalPhysicalStressVmrAdjust(
        _readString(extra, const [
          TrainingExtraKeys.externalPhysicalStressLevel,
          'physicalStress',
        ]),
      ),
      'nonPhysicalStress': nonPhysicalStressVmrAdjust(
        _readString(extra, const [
          TrainingExtraKeys.nonPhysicalStressLevel2,
          'nonPhysicalStressLevel',
          'nonPhysicalStress',
          TrainingExtraKeys.stressLevel,
        ]),
      ),
      'restQuality': restQualityVmrAdjust(
        _readString(extra, const [
          TrainingExtraKeys.restQuality2,
          'restQuality',
          TrainingExtraKeys.sleepBucket,
        ]),
      ),
      'diet': dietHabitsVmrAdjust(
        _readString(extra, const [
          TrainingExtraKeys.dietHabitsClass,
          'dietQuality',
        ]),
      ),
      'anabolics': anabolicsVmrAdjust(usesAnabolics),
    };

    final sumAdjustmentsVme = adjustmentsVme.values.fold(0.0, (a, b) => a + b);
    final sumAdjustmentsVmr = adjustmentsVmr.values.fold(0.0, (a, b) => a + b);

    final vmeCalculated = (vmeBase + sumAdjustmentsVme)
        .clamp(1.0, double.infinity)
        .toDouble();
    final vmrCalculated = (vmrBase + sumAdjustmentsVmr)
        .clamp(vmeCalculated, double.infinity)
        .toDouble();
    final vopCalculated =
        vmeCalculated + 0.35 * (vmrCalculated - vmeCalculated);

    return VolumeAdjustmentResult(
      vmeBase: vmeBase,
      vmrBase: vmrBase,
      sumAdjustmentsVme: sumAdjustmentsVme,
      sumAdjustmentsVmr: sumAdjustmentsVmr,
      vmeCalculated: vmeCalculated,
      vmrCalculated: vmrCalculated,
      vopCalculated: vopCalculated,
      adjustmentsVme: adjustmentsVme,
      adjustmentsVmr: adjustmentsVmr,
    );
  }

  static (int vmeBase, int vmrBase) baseBounds(TrainingLevel level) {
    switch (level) {
      case TrainingLevel.beginner:
        return (6, 16);
      case TrainingLevel.intermediate:
        return (12, 24);
      case TrainingLevel.advanced:
        return (18, 32);
    }
  }

  static double sexVmeAdjust(Gender sex) => sex.isFemale ? 1.5 : 0.0;

  static double sexVmrAdjust(Gender sex) => sex.isFemale ? 3.0 : 0.0;

  static double ageVmeAdjust(int ageYears) {
    if (ageYears < 19) return -1.0;
    if (ageYears <= 29) return -0.5;
    if (ageYears <= 39) return 0.0;
    if (ageYears <= 49) return 0.5;
    return 1.0;
  }

  static double ageVmrAdjust(int ageYears) {
    if (ageYears < 19) return 2.0;
    if (ageYears <= 29) return 1.0;
    if (ageYears <= 39) return 0.0;
    if (ageYears <= 49) return -1.0;
    return -3.0;
  }

  static double heightVmeAdjust(double heightCm) {
    switch (_classifyHeight(heightCm)) {
      case _HeightClass.low:
        return 1.0;
      case _HeightClass.medium:
        return 0.5;
      case _HeightClass.high:
        return -0.5;
      case _HeightClass.veryHigh:
        return -1.0;
    }
  }

  static double heightVmrAdjust(double heightCm) {
    switch (_classifyHeight(heightCm)) {
      case _HeightClass.low:
        return 2.0;
      case _HeightClass.medium:
        return 1.0;
      case _HeightClass.high:
        return -1.0;
      case _HeightClass.veryHigh:
        return -2.0;
    }
  }

  static double weightVmeAdjust(double weightKg) {
    switch (_classifyWeight(weightKg)) {
      case _WeightClass.light:
        return 1.5;
      case _WeightClass.medium:
        return 0.5;
      case _WeightClass.semiHeavy:
        return -0.5;
      case _WeightClass.heavy:
        return -1.5;
    }
  }

  static double weightVmrAdjust(double weightKg) {
    switch (_classifyWeight(weightKg)) {
      case _WeightClass.light:
        return 3.0;
      case _WeightClass.medium:
        return 1.0;
      case _WeightClass.semiHeavy:
        return -1.0;
      case _WeightClass.heavy:
        return -3.0;
    }
  }

  static double strengthLevelVmeAdjust(String? value) {
    switch (_normalizeStrengthLevel(value)) {
      case 'veryHigh':
        return 1.0;
      case 'high':
        return 0.5;
      case 'medium':
        return 0.0;
      case 'low':
        return -0.5;
      default:
        return 0.0;
    }
  }

  static double strengthLevelVmrAdjust(String? value) {
    switch (_normalizeStrengthLevel(value)) {
      case 'veryHigh':
        return -3.0;
      case 'high':
        return -1.0;
      case 'medium':
        return 0.0;
      case 'low':
        return 1.0;
      default:
        return 0.0;
    }
  }

  static double workCapacityVmeAdjust(int? value) {
    switch (value) {
      case 5:
        return 1.0;
      case 4:
        return 0.5;
      case 3:
        return 0.0;
      case 2:
        return -0.5;
      case 1:
        return -1.0;
      default:
        return 0.0;
    }
  }

  static double workCapacityVmrAdjust(int? value) {
    switch (value) {
      case 5:
        return 2.0;
      case 4:
        return 1.0;
      case 3:
        return 0.0;
      case 2:
        return -1.0;
      case 1:
        return -2.0;
      default:
        return 0.0;
    }
  }

  static double recoveryHistoryVmeAdjust(int? value) =>
      workCapacityVmeAdjust(value);

  static double recoveryHistoryVmrAdjust(int? value) =>
      workCapacityVmrAdjust(value);

  static double externalRecoverySupportVmeAdjust(bool? value) =>
      value == true ? -1.0 : 0.0;

  static double externalRecoverySupportVmrAdjust(bool? value) =>
      value == true ? 2.0 : 0.0;

  static double programNoveltyVmeAdjust(String? value) {
    switch (_normalizeProgramNovelty(value)) {
      case 'none':
        return 1.5;
      case 'low':
        return 0.5;
      case 'intermediate':
        return 0.0;
      case 'high':
        return -0.5;
      default:
        return 0.0;
    }
  }

  static double programNoveltyVmrAdjust(String? value) {
    switch (_normalizeProgramNovelty(value)) {
      case 'none':
        return 3.0;
      case 'low':
        return 1.0;
      case 'intermediate':
        return -1.0;
      case 'high':
        return -3.0;
      default:
        return 0.0;
    }
  }

  static double externalPhysicalStressVmeAdjust(String? value) {
    switch (_normalizeExternalPhysicalStress(value)) {
      case 'high':
        return 1.5;
      case 'intermediate':
        return 1.0;
      case 'none':
        return 0.0;
      case 'low':
        return -0.5;
      default:
        return 0.0;
    }
  }

  static double externalPhysicalStressVmrAdjust(String? value) {
    switch (_normalizeExternalPhysicalStress(value)) {
      case 'high':
        return -3.0;
      case 'intermediate':
        return -2.0;
      case 'none':
        return 0.0;
      case 'low':
        return 1.0;
      default:
        return 0.0;
    }
  }

  static double nonPhysicalStressVmeAdjust(String? value) {
    switch (_normalizeLowAverageHigh(value)) {
      case 'high':
        return 0.5;
      case 'average':
        return 0.0;
      case 'low':
        return -0.5;
      default:
        return 0.0;
    }
  }

  static double nonPhysicalStressVmrAdjust(String? value) {
    switch (_normalizeLowAverageHigh(value)) {
      case 'high':
        return -2.0;
      case 'average':
        return 0.0;
      case 'low':
        return 1.0;
      default:
        return 0.0;
    }
  }

  static double restQualityVmeAdjust(String? value) =>
      nonPhysicalStressVmeAdjust(value);

  static double restQualityVmrAdjust(String? value) =>
      nonPhysicalStressVmrAdjust(value);

  static double dietHabitsVmeAdjust(String? value) {
    switch (_normalizeDiet(value)) {
      case 'deficitHigh':
        return 1.5;
      case 'deficitMedium':
        return 1.0;
      case 'deficitLow':
        return 0.5;
      case 'maintenance':
        return 0.0;
      case 'surplusLow':
        return -0.5;
      case 'surplusMedium':
        return -1.0;
      case 'surplusHigh':
        return -1.5;
      default:
        return 0.0;
    }
  }

  static double dietHabitsVmrAdjust(String? value) {
    switch (_normalizeDiet(value)) {
      case 'deficitHigh':
        return -3.0;
      case 'deficitMedium':
        return -2.0;
      case 'deficitLow':
        return -1.0;
      case 'maintenance':
        return 0.0;
      case 'surplusLow':
        return 1.0;
      case 'surplusMedium':
        return 2.0;
      case 'surplusHigh':
        return 3.0;
      default:
        return 0.0;
    }
  }

  static double anabolicsVmeAdjust(bool usesAnabolics) =>
      usesAnabolics ? -1.5 : 0.0;

  static double anabolicsVmrAdjust(bool usesAnabolics) =>
      usesAnabolics ? 3.0 : 0.0;

  static String? _readString(Map<String, dynamic> extra, List<String> keys) {
    for (final key in keys) {
      final value = extra[key];
      if (value != null) return value.toString();
    }
    return null;
  }

  static int? _readInt(Map<String, dynamic> extra, List<String> keys) {
    for (final key in keys) {
      final value = extra[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      final parsed = int.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return null;
  }

  static bool? _readBool(Map<String, dynamic> extra, List<String> keys) {
    for (final key in keys) {
      final value = extra[key];
      if (value is bool) return value;
      if (value is String) {
        final normalized = value.toLowerCase().trim();
        if (normalized == 'true' || normalized == 'yes' || normalized == 'si') {
          return true;
        }
        if (normalized == 'false' || normalized == 'no') {
          return false;
        }
      }
    }
    return null;
  }

  static _HeightClass _classifyHeight(double heightCm) {
    if (heightCm < 160) return _HeightClass.low;
    if (heightCm < 175) return _HeightClass.medium;
    if (heightCm < 190) return _HeightClass.high;
    return _HeightClass.veryHigh;
  }

  static _WeightClass _classifyWeight(double weightKg) {
    if (weightKg < 60) return _WeightClass.light;
    if (weightKg < 80) return _WeightClass.medium;
    if (weightKg < 100) return _WeightClass.semiHeavy;
    return _WeightClass.heavy;
  }

  static String _normalizeStrengthLevel(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'ma':
      case 'veryhigh':
      case 'muyalto':
      case 'muy alto':
        return 'veryHigh';
      case 'a':
      case 'high':
      case 'alto':
        return 'high';
      case 'm':
      case 'medium':
      case 'medio':
        return 'medium';
      case 'b':
      case 'low':
      case 'bajo':
        return 'low';
      default:
        return 'medium';
    }
  }

  static String _normalizeProgramNovelty(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'n':
      case 'none':
      case 'ninguna':
        return 'none';
      case 'b':
      case 'low':
      case 'baja':
        return 'low';
      case 'i':
      case 'intermediate':
      case 'intermedia':
        return 'intermediate';
      case 'a':
      case 'high':
      case 'alta':
        return 'high';
      default:
        return 'unknown';
    }
  }

  static String _normalizeExternalPhysicalStress(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'a':
      case 'high':
      case 'alto':
        return 'high';
      case 'i':
      case 'intermediate':
      case 'intermedio':
        return 'intermediate';
      case 'n':
      case 'none':
      case 'normal':
        return 'none';
      case 'b':
      case 'low':
      case 'bajo':
        return 'low';
      default:
        return 'none';
    }
  }

  static String _normalizeLowAverageHigh(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'a':
      case 'high':
      case 'alto':
        return 'high';
      case 'p':
      case 'average':
      case 'promedio':
      case 'medium':
      case 'mediano':
        return 'average';
      case 'b':
      case 'low':
      case 'bajo':
        return 'low';
      default:
        return 'average';
    }
  }

  static String _normalizeDiet(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'deficithigh':
      case 'dca':
        return 'deficitHigh';
      case 'deficitmedium':
      case 'dcm':
        return 'deficitMedium';
      case 'deficitlow':
      case 'dcb':
        return 'deficitLow';
      case 'maintenance':
      case 'iso':
      case 'mantenimiento':
        return 'maintenance';
      case 'surpluslow':
      case 'scb':
        return 'surplusLow';
      case 'surplusmedium':
      case 'scm':
        return 'surplusMedium';
      case 'surplushigh':
      case 'sca':
        return 'surplusHigh';
      default:
        return 'maintenance';
    }
  }
}

enum _HeightClass { low, medium, high, veryHigh }

enum _WeightClass { light, medium, semiHeavy, heavy }
