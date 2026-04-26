import 'package:hcs_app_lap/core/enums/gender.dart';
import 'package:hcs_app_lap/core/enums/training_level.dart';
import 'package:hcs_app_lap/domain/services/volume_adjustment_calculator.dart';
import 'package:hcs_app_lap/domain/training_v3/constants/muscle_volume_landmarks_ssot.dart';

enum TrainingLevelDerived { beginner, intermediate, advanced }

int toTrainingMonths({required double value, required String unit}) {
  if (unit == 'years') return (value * 12).round();
  return value.round();
}

TrainingLevelDerived deriveTrainingLevelFromMonths(int months) {
  if (months <= 12) return TrainingLevelDerived.beginner;
  if (months <= 36) return TrainingLevelDerived.intermediate;
  return TrainingLevelDerived.advanced;
}

class GlobalVolumeBounds {
  final double vmeBase;
  final double vmrBase;

  const GlobalVolumeBounds({required this.vmeBase, required this.vmrBase});
}

GlobalVolumeBounds getBaseBoundsForLevel(TrainingLevelDerived level) {
  switch (level) {
    case TrainingLevelDerived.beginner:
      return const GlobalVolumeBounds(vmeBase: 6, vmrBase: 16);
    case TrainingLevelDerived.intermediate:
      return const GlobalVolumeBounds(vmeBase: 12, vmrBase: 24);
    case TrainingLevelDerived.advanced:
      return const GlobalVolumeBounds(vmeBase: 18, vmrBase: 32);
  }
}

class TrainingVolumeComputationInput {
  final Gender? sex;
  final int ageYears;
  final double? heightCm;
  final double? weightKg;
  final String? strengthLevelClass;
  final int? workCapacityScore;
  final int? recoveryHistoryScore;
  final bool? externalRecoverySupport;
  final String? programNoveltyClass;
  final String? externalPhysicalStressLevel;
  final String? nonPhysicalStressLevel2;
  final String? restQuality2;
  final String? dietHabitsClass;
  final bool usesAnabolics;

  const TrainingVolumeComputationInput({
    required this.sex,
    required this.ageYears,
    required this.heightCm,
    required this.weightKg,
    required this.strengthLevelClass,
    required this.workCapacityScore,
    required this.recoveryHistoryScore,
    required this.externalRecoverySupport,
    required this.programNoveltyClass,
    required this.externalPhysicalStressLevel,
    required this.nonPhysicalStressLevel2,
    required this.restQuality2,
    required this.dietHabitsClass,
    required this.usesAnabolics,
  });
}

class TrainingVolumeComputationResult {
  final TrainingLevelDerived level;
  final GlobalVolumeBounds baseBounds;
  final double vmeAdjustTotal;
  final double vmrAdjustTotal;
  final double vmeCalculated;
  final double vmrCalculated;
  final double vopCalculated;

  const TrainingVolumeComputationResult({
    required this.level,
    required this.baseBounds,
    required this.vmeAdjustTotal,
    required this.vmrAdjustTotal,
    required this.vmeCalculated,
    required this.vmrCalculated,
    required this.vopCalculated,
  });

  GlobalVolumeAdjustments get globalAdjustments => GlobalVolumeAdjustments(
    deltaVme: vmeAdjustTotal,
    deltaVmr: vmrAdjustTotal,
  );
}

TrainingVolumeComputationResult computeTrainingVolume({
  required TrainingLevelDerived level,
  required TrainingVolumeComputationInput input,
}) {
  final baseBounds = getBaseBoundsForLevel(level);
  final legacyLevel = _toLegacyLevel(level);
  final calculator = VolumeAdjustmentCalculator.calculate(
    level: legacyLevel,
    sex: input.sex ?? Gender.other,
    ageYears: input.ageYears,
    heightCm: input.heightCm,
    weightKg: input.weightKg,
    extra: {
      'strengthLevelClass': input.strengthLevelClass,
      'workCapacityScore': input.workCapacityScore,
      'recoveryHistoryScore': input.recoveryHistoryScore,
      'externalRecoverySupport': input.externalRecoverySupport,
      'programNoveltyClass': input.programNoveltyClass,
      'externalPhysicalStressLevel': input.externalPhysicalStressLevel,
      'nonPhysicalStressLevel2': input.nonPhysicalStressLevel2,
      'restQuality2': input.restQuality2,
      'dietHabitsClass': input.dietHabitsClass,
    },
    usesAnabolics: input.usesAnabolics,
  );

  final vmeCalculated = calculator.vmeCalculated;
  final vmrCalculated = calculator.vmrCalculated;
  final vopCalculated = switch (level) {
    TrainingLevelDerived.beginner => vmeCalculated,
    TrainingLevelDerived.intermediate => vmeCalculated + 1,
    TrainingLevelDerived.advanced => vmeCalculated + 2,
  };

  return TrainingVolumeComputationResult(
    level: level,
    baseBounds: baseBounds,
    vmeAdjustTotal: calculator.sumAdjustmentsVme,
    vmrAdjustTotal: calculator.sumAdjustmentsVmr,
    vmeCalculated: vmeCalculated,
    vmrCalculated: vmrCalculated,
    vopCalculated: vopCalculated,
  );
}

TrainingLevel _toLegacyLevel(TrainingLevelDerived level) {
  switch (level) {
    case TrainingLevelDerived.beginner:
      return TrainingLevel.beginner;
    case TrainingLevelDerived.intermediate:
      return TrainingLevel.intermediate;
    case TrainingLevelDerived.advanced:
      return TrainingLevel.advanced;
  }
}
