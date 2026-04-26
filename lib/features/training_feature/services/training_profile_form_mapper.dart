import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/core/constants/training_interview_legacy_keys.dart';
import 'package:hcs_app_lap/core/enums/gender.dart';
import 'package:hcs_app_lap/core/enums/training_level.dart';
import 'package:hcs_app_lap/core/utils/muscle_key_normalizer.dart';
import 'package:hcs_app_lap/core/registry/muscle_registry.dart'
    as muscle_registry;
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/features/training_feature/domain/training_volume_computation_helper.dart';

class TrainingInterviewFormValues {
  final Gender? sex;
  final double? heightCm;
  final double? weightKg;
  final int? ageYears;
  final int? trainingMonths;
  final TrainingLevelDerived? trainingLevelDerived;
  final String? strengthLevelClass;
  final int? workCapacityScore;
  final int? recoveryHistoryScore;
  final bool? externalRecoverySupport;
  final String? programNoveltyClass;
  final String? externalPhysicalStressLevel;
  final String? nonPhysicalStressLevel2;
  final String? restQuality2;
  final String? dietHabitsClass;
  final bool? usesAnabolics;
  final Set<String> injuryRegions;
  final Map<String, String> injuryPatternByRegion;
  final String? injurySeverity;
  final String? injuryStatus;
  final String? backFocus;
  final List<String> priorityMusclesPrimary;
  final List<String> priorityMusclesSecondary;
  final List<String> priorityMusclesTertiary;

  const TrainingInterviewFormValues({
    required this.sex,
    required this.heightCm,
    required this.weightKg,
    required this.ageYears,
    required this.trainingMonths,
    required this.trainingLevelDerived,
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
    required this.injuryRegions,
    required this.injuryPatternByRegion,
    required this.injurySeverity,
    required this.injuryStatus,
    required this.backFocus,
    required this.priorityMusclesPrimary,
    required this.priorityMusclesSecondary,
    required this.priorityMusclesTertiary,
  });
}

class TrainingProfileFormMapper {
  TrainingProfileFormMapper._();

  static TrainingInterviewFormValues valuesFromProfile(
    TrainingProfile profile,
  ) {
    final extra = profile.extra;

    final heightCm = _readDouble(extra, [
      TrainingExtraKeys.heightCm,
      TrainingInterviewLegacyKeys.heightCm,
    ]);
    final weightKg = _readDouble(extra, [
      TrainingExtraKeys.weightKg,
      TrainingInterviewLegacyKeys.weightKg,
    ]);
    final ageYears = _readInt(extra, [TrainingExtraKeys.ageYears]);

    final monthsFromCanonical = _readInt(extra, [
      TrainingExtraKeys.trainingMonths,
    ]);
    final yearsFromCanonical = _readInt(extra, [
      TrainingExtraKeys.trainingYears,
    ]);
    final legacyYearsContinuous = _readInt(extra, [
      TrainingInterviewLegacyKeys.yearsTrainingContinuous,
    ]);
    final trainingMonths =
        monthsFromCanonical ??
        (yearsFromCanonical != null
            ? yearsFromCanonical * 12
            : legacyYearsContinuous != null
            ? legacyYearsContinuous * 12
            : null);
    final trainingLevelDerived =
        _readTrainingLevelDerived(extra) ??
        (trainingMonths == null
            ? null
            : deriveTrainingLevelFromMonths(trainingMonths));

    final strengthLevelClass = _readString(extra, [
      TrainingExtraKeys.strengthLevelClass,
      TrainingInterviewLegacyKeys.strengthLevelClass,
    ]);
    final workCapacityScore = _readInt(extra, [
      TrainingExtraKeys.workCapacityScore,
      TrainingInterviewLegacyKeys.workCapacityScore,
      TrainingInterviewLegacyKeys.workCapacity,
    ]);
    final recoveryHistoryScore = _readInt(extra, [
      TrainingExtraKeys.recoveryHistoryScore,
      TrainingInterviewLegacyKeys.recoveryHistoryScore,
      TrainingInterviewLegacyKeys.recoveryHistory,
    ]);
    final externalRecoverySupport = _readBool(extra, [
      TrainingExtraKeys.externalRecoverySupport,
      TrainingInterviewLegacyKeys.externalRecoverySupport,
      TrainingInterviewLegacyKeys.externalRecovery,
    ]);
    final programNoveltyClass = _readString(extra, [
      TrainingExtraKeys.programNoveltyClass,
      TrainingInterviewLegacyKeys.programNoveltyClass,
      TrainingInterviewLegacyKeys.programNovelty,
    ]);
    final externalPhysicalStressLevel = _readString(extra, [
      TrainingExtraKeys.externalPhysicalStressLevel,
      TrainingInterviewLegacyKeys.externalPhysicalStressLevel,
      TrainingInterviewLegacyKeys.physicalStress,
    ]);
    final nonPhysicalStressLevel2 = _readString(extra, [
      TrainingExtraKeys.nonPhysicalStressLevel2,
      TrainingInterviewLegacyKeys.nonPhysicalStressLevel2,
      TrainingInterviewLegacyKeys.nonPhysicalStressLevel,
      TrainingInterviewLegacyKeys.nonPhysicalStress,
    ]);
    final restQuality2 = _readString(extra, [
      TrainingExtraKeys.restQuality2,
      TrainingInterviewLegacyKeys.restQuality2,
      TrainingInterviewLegacyKeys.restQuality,
    ]);
    final dietHabitsClass = _readString(extra, [
      TrainingExtraKeys.dietHabitsClass,
      TrainingInterviewLegacyKeys.dietHabitsClass,
      TrainingInterviewLegacyKeys.dietQuality,
    ]);
    final usesAnabolics =
        _readBool(extra, [
          TrainingExtraKeys.usesAnabolics,
          TrainingInterviewLegacyKeys.usesAnabolics,
        ]) ??
        profile.usesAnabolics;

    final injuryData = _readInjuryData(extra);
    final backFocus = _readString(extra, [TrainingExtraKeys.backFocus]);

    final primaryMuscles = _parseMuscleList(
      profile.priorityMusclesPrimary.isNotEmpty
          ? profile.priorityMusclesPrimary
          : extra[TrainingExtraKeys.priorityMusclesPrimary],
    );
    final secondaryMuscles = _parseMuscleList(
      profile.priorityMusclesSecondary.isNotEmpty
          ? profile.priorityMusclesSecondary
          : extra[TrainingExtraKeys.priorityMusclesSecondary],
    );
    final tertiaryMuscles = _parseMuscleList(
      profile.priorityMusclesTertiary.isNotEmpty
          ? profile.priorityMusclesTertiary
          : extra[TrainingExtraKeys.priorityMusclesTertiary],
    );

    return TrainingInterviewFormValues(
      sex: profile.gender,
      heightCm: heightCm,
      weightKg: weightKg,
      ageYears: ageYears,
      trainingMonths: trainingMonths,
      trainingLevelDerived: trainingLevelDerived,
      strengthLevelClass: strengthLevelClass,
      workCapacityScore: workCapacityScore,
      recoveryHistoryScore: recoveryHistoryScore,
      externalRecoverySupport: externalRecoverySupport,
      programNoveltyClass: programNoveltyClass,
      externalPhysicalStressLevel: externalPhysicalStressLevel,
      nonPhysicalStressLevel2: nonPhysicalStressLevel2,
      restQuality2: restQuality2,
      dietHabitsClass: dietHabitsClass,
      usesAnabolics: usesAnabolics,
      injuryRegions: injuryData.$1,
      injuryPatternByRegion: injuryData.$2,
      injurySeverity: injuryData.$3,
      injuryStatus: injuryData.$4,
      backFocus: backFocus,
      priorityMusclesPrimary: primaryMuscles,
      priorityMusclesSecondary: secondaryMuscles,
      priorityMusclesTertiary: tertiaryMuscles,
    );
  }

  static TrainingProfile apply({
    required TrainingProfile base,
    required TrainingInterviewFormValues input,
    required TrainingVolumeComputationResult volume,
  }) {
    final extra = Map<String, dynamic>.from(base.extra);
    _purgeInterviewLegacyPayload(extra);

    if (input.heightCm != null && input.heightCm! > 0) {
      extra[TrainingExtraKeys.heightCm] = input.heightCm;
    }
    if (input.weightKg != null && input.weightKg! > 0) {
      extra[TrainingExtraKeys.weightKg] = input.weightKg;
    }
    if (input.ageYears != null && input.ageYears! > 0) {
      extra[TrainingExtraKeys.ageYears] = input.ageYears;
    }

    if (input.trainingMonths != null && input.trainingMonths! > 0) {
      extra[TrainingExtraKeys.trainingMonths] = input.trainingMonths;
      extra[TrainingExtraKeys.trainingYears] = (input.trainingMonths! / 12)
          .floor();
    }

    final effectiveLevel = _trainingLevelName(volume.level);
    extra[TrainingExtraKeys.effectiveTrainingLevel] = effectiveLevel;
    extra[TrainingExtraKeys.trainingLevelDerived] = effectiveLevel;
    extra[TrainingExtraKeys.trainingLevel] = effectiveLevel;

    if (input.strengthLevelClass != null) {
      extra[TrainingExtraKeys.strengthLevelClass] = input.strengthLevelClass;
    }
    if (input.workCapacityScore != null) {
      extra[TrainingExtraKeys.workCapacityScore] = input.workCapacityScore;
    }
    if (input.recoveryHistoryScore != null) {
      extra[TrainingExtraKeys.recoveryHistoryScore] =
          input.recoveryHistoryScore;
    }
    if (input.externalRecoverySupport != null) {
      extra[TrainingExtraKeys.externalRecoverySupport] =
          input.externalRecoverySupport;
    }
    if (input.programNoveltyClass != null) {
      extra[TrainingExtraKeys.programNoveltyClass] = input.programNoveltyClass;
    }
    if (input.externalPhysicalStressLevel != null) {
      extra[TrainingExtraKeys.externalPhysicalStressLevel] =
          input.externalPhysicalStressLevel;
    }
    if (input.nonPhysicalStressLevel2 != null) {
      extra[TrainingExtraKeys.nonPhysicalStressLevel2] =
          input.nonPhysicalStressLevel2;
    }
    if (input.restQuality2 != null) {
      extra[TrainingExtraKeys.restQuality2] = input.restQuality2;
    }
    if (input.dietHabitsClass != null) {
      extra[TrainingExtraKeys.dietHabitsClass] = input.dietHabitsClass;
    }
    if (input.usesAnabolics != null) {
      extra[TrainingExtraKeys.usesAnabolics] = input.usesAnabolics;
    }

    final injuryRegions = input.injuryRegions.toList()..sort();
    if (injuryRegions.isEmpty) {
      extra.remove(TrainingExtraKeys.activeInjuries);
      extra.remove(TrainingExtraKeys.injuries);
      extra.remove(TrainingExtraKeys.detailedInjuryHistory);
    } else {
      extra[TrainingExtraKeys.activeInjuries] = injuryRegions;
      extra[TrainingExtraKeys.injuries] = injuryRegions;
      extra[TrainingExtraKeys.detailedInjuryHistory] = {
        for (final region in injuryRegions)
          region: {
            if (input.injuryPatternByRegion[region] != null)
              'pattern': input.injuryPatternByRegion[region],
            if (input.injurySeverity != null) 'severity': input.injurySeverity,
            if (input.injuryStatus != null) 'status': input.injuryStatus,
          },
      };
    }

    if (input.injurySeverity != null) {
      extra[TrainingExtraKeys.injurySeverity] = input.injurySeverity;
    } else {
      extra.remove(TrainingExtraKeys.injurySeverity);
    }
    if (input.injuryStatus != null) {
      extra[TrainingExtraKeys.injuryStatus] = input.injuryStatus;
    } else {
      extra.remove(TrainingExtraKeys.injuryStatus);
    }

    if (input.backFocus != null && input.backFocus!.isNotEmpty) {
      extra[TrainingExtraKeys.backFocus] = input.backFocus;
    } else {
      extra.remove(TrainingExtraKeys.backFocus);
    }

    extra[TrainingExtraKeys.priorityMusclesPrimary] = List<String>.from(
      input.priorityMusclesPrimary,
    );
    extra[TrainingExtraKeys.priorityMusclesSecondary] = List<String>.from(
      input.priorityMusclesSecondary,
    );
    extra[TrainingExtraKeys.priorityMusclesTertiary] = List<String>.from(
      input.priorityMusclesTertiary,
    );

    extra[TrainingExtraKeys.vmeBase] = volume.baseBounds.vmeBase;
    extra[TrainingExtraKeys.vmrBase] = volume.baseBounds.vmrBase;
    extra[TrainingExtraKeys.vmeAdjustTotal] = volume.vmeAdjustTotal;
    extra[TrainingExtraKeys.vmrAdjustTotal] = volume.vmrAdjustTotal;
    extra[TrainingExtraKeys.deltaVmeGlobal] = volume.vmeAdjustTotal;
    extra[TrainingExtraKeys.deltaVmrGlobal] = volume.vmrAdjustTotal;
    extra[TrainingExtraKeys.vmeCalculated] = volume.vmeCalculated;
    extra[TrainingExtraKeys.vmrCalculated] = volume.vmrCalculated;
    extra[TrainingExtraKeys.vopCalculated] = volume.vopCalculated;
    extra[TrainingExtraKeys.mevIndividual] = volume.vmeCalculated;
    extra[TrainingExtraKeys.mrvIndividual] = volume.vmrCalculated;
    extra.remove(TrainingExtraKeys.mevByMuscle);
    extra.remove(TrainingExtraKeys.mrvByMuscle);

    return base.copyWith(
      gender: input.sex ?? base.gender,
      age: input.ageYears ?? base.age,
      bodyWeight: input.weightKg ?? base.bodyWeight,
      usesAnabolics: input.usesAnabolics ?? base.usesAnabolics,
      trainingLevel: _toLegacyTrainingLevel(volume.level),
      yearsTrainingContinuous: ((input.trainingMonths ?? 0) / 12).floor(),
      priorityMusclesPrimary: List<String>.from(input.priorityMusclesPrimary),
      priorityMusclesSecondary: List<String>.from(
        input.priorityMusclesSecondary,
      ),
      priorityMusclesTertiary: List<String>.from(input.priorityMusclesTertiary),
      extra: extra,
      date: DateTime.now(),
    );
  }

  static String? optionFromTrainingLevel(TrainingLevel? level) {
    switch (level) {
      case TrainingLevel.beginner:
        return 'Principiante';
      case TrainingLevel.intermediate:
        return 'Intermedio';
      case TrainingLevel.advanced:
        return 'Avanzado';
      default:
        return null;
    }
  }

  static String? optionFromMinutes(int minutes) {
    if (minutes <= 0) return null;
    if (minutes <= 30) return '30 min';
    if (minutes <= 45) return '45 min';
    if (minutes <= 60) return '60 min';
    if (minutes <= 75) return '75 min';
    return '90 min+';
  }

  static void _purgeInterviewLegacyPayload(Map<String, dynamic> extra) {
    extra.remove(TrainingExtraKeys.legacyTrainingLevel);
    extra.remove(TrainingInterviewLegacyKeys.yearsTrainingContinuous);
    extra.remove(TrainingInterviewLegacyKeys.avgSleepHours);
    extra.remove(TrainingInterviewLegacyKeys.sessionDurationMinutes);
    extra.remove(TrainingInterviewLegacyKeys.restBetweenSetsSeconds);
    extra.remove(TrainingInterviewLegacyKeys.workCapacity);
    extra.remove(TrainingInterviewLegacyKeys.recoveryHistory);
    extra.remove(TrainingInterviewLegacyKeys.externalRecovery);
    extra.remove(TrainingInterviewLegacyKeys.programNovelty);
    extra.remove(TrainingInterviewLegacyKeys.physicalStress);
    extra.remove(TrainingInterviewLegacyKeys.nonPhysicalStress);
    extra.remove(TrainingInterviewLegacyKeys.restQuality);
    extra.remove(TrainingInterviewLegacyKeys.dietQuality);
    extra.remove(TrainingInterviewLegacyKeys.yearsTraining);
    extra.remove(TrainingInterviewLegacyKeys.sessionDuration);
    extra.remove(TrainingInterviewLegacyKeys.restBetweenSets);
    extra.remove(TrainingInterviewLegacyKeys.workCapacityScore);
    extra.remove(TrainingInterviewLegacyKeys.recoveryHistoryScore);
    extra.remove(TrainingInterviewLegacyKeys.externalRecoverySupport);
    extra.remove(TrainingInterviewLegacyKeys.programNoveltyClass);
    extra.remove(TrainingInterviewLegacyKeys.externalPhysicalStressLevel);
    extra.remove(TrainingInterviewLegacyKeys.nonPhysicalStressLevel);
    extra.remove(TrainingInterviewLegacyKeys.nonPhysicalStressLevel2);
    extra.remove(TrainingInterviewLegacyKeys.restQuality2);
    extra.remove(TrainingInterviewLegacyKeys.dietHabitsClass);
    extra.remove(TrainingInterviewLegacyKeys.strengthLevelClass);
    extra.remove(TrainingInterviewLegacyKeys.heightCm);
    extra.remove(TrainingInterviewLegacyKeys.weightKg);
    extra.remove(TrainingInterviewLegacyKeys.usesAnabolics);
    extra.remove(TrainingInterviewLegacyKeys.avgWeeklySetsPerMuscle);
    extra.remove(TrainingInterviewLegacyKeys.consecutiveWeeksTraining);
    extra.remove(TrainingInterviewLegacyKeys.perceivedRecoveryStatus);
    extra.remove(TrainingInterviewLegacyKeys.averageRIR);
    extra.remove(TrainingInterviewLegacyKeys.averageSessionRPE);
    extra.remove(TrainingInterviewLegacyKeys.maxWeeklySetsBeforeOverreaching);
    extra.remove(TrainingInterviewLegacyKeys.deloadFrequencyWeeks);
    extra.remove(TrainingInterviewLegacyKeys.soreness48hAverage);
    extra.remove(TrainingInterviewLegacyKeys.periodBreaksLast12Months);
    extra.remove(TrainingInterviewLegacyKeys.performanceTrend);
    extra.remove(TrainingExtraKeys.injuryRegion);
    extra.remove(TrainingExtraKeys.injuryPattern);
    extra.remove(TrainingExtraKeys.injurySeverity);
    extra.remove(TrainingExtraKeys.injuryStatus);
  }

  static TrainingLevel _toLegacyTrainingLevel(TrainingLevelDerived level) {
    switch (level) {
      case TrainingLevelDerived.beginner:
        return TrainingLevel.beginner;
      case TrainingLevelDerived.intermediate:
        return TrainingLevel.intermediate;
      case TrainingLevelDerived.advanced:
        return TrainingLevel.advanced;
    }
  }

  static String _trainingLevelName(TrainingLevelDerived level) {
    switch (level) {
      case TrainingLevelDerived.beginner:
        return TrainingLevel.beginner.name;
      case TrainingLevelDerived.intermediate:
        return TrainingLevel.intermediate.name;
      case TrainingLevelDerived.advanced:
        return TrainingLevel.advanced.name;
    }
  }

  static List<String> _parseMuscleList(dynamic rawValue) {
    final normalized = <String>{};

    if (rawValue is List) {
      for (final item in rawValue) {
        normalized.addAll(_canonicalMusclesFromRaw(item.toString()));
      }
      final out = normalized.toList()..sort();
      return out;
    }
    if (rawValue is String) {
      for (final item in rawValue.split(',')) {
        normalized.addAll(_canonicalMusclesFromRaw(item.trim()));
      }
      final out = normalized.toList()..sort();
      return out;
    }
    return const [];
  }

  static List<String> _canonicalMusclesFromRaw(String raw) {
    final normalized = normalizeMuscleKey(raw);
    final canonical = muscle_registry.normalize(normalized);
    if (canonical != null) {
      return [canonical];
    }

    final expanded = muscle_registry.expandGroup(normalized);
    if (expanded.isNotEmpty) {
      return expanded;
    }

    return const [];
  }

  static (Set<String>, Map<String, String>, String?, String?) _readInjuryData(
    Map<String, dynamic> extra,
  ) {
    final regions = <String>{};
    final patterns = <String, String>{};
    String? severity;
    String? status;

    final detailed = extra[TrainingExtraKeys.detailedInjuryHistory];
    if (detailed is Map) {
      detailed.forEach((key, value) {
        final region = key.toString();
        if (region.isEmpty) return;
        regions.add(region);
        if (value is Map) {
          final pattern = value['pattern']?.toString();
          if (pattern != null && pattern.isNotEmpty) {
            patterns[region] = pattern;
          }
          severity ??= value['severity']?.toString();
          status ??= value['status']?.toString();
        }
      });
    }

    final injuryList = _parseRegionList(
      extra[TrainingExtraKeys.activeInjuries] ??
          extra[TrainingExtraKeys.injuries],
    );
    regions.addAll(injuryList);

    final legacyRegion = _readString(extra, [TrainingExtraKeys.injuryRegion]);
    if (legacyRegion != null && legacyRegion.isNotEmpty) {
      regions.add(legacyRegion);
      final pattern = _readString(extra, [TrainingExtraKeys.injuryPattern]);
      if (pattern != null) patterns[legacyRegion] = pattern;
      severity ??= _readString(extra, [TrainingExtraKeys.injurySeverity]);
      status ??= _readString(extra, [TrainingExtraKeys.injuryStatus]);
    }

    return (regions, patterns, severity, status);
  }

  static Set<String> _parseRegionList(dynamic rawValue) {
    if (rawValue is List) {
      return rawValue
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toSet();
    }
    if (rawValue is String) {
      return rawValue
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet();
    }
    return <String>{};
  }

  static int? _readInt(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  static double? _readDouble(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is double) return value;
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value.replaceAll(',', '.').trim());
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  static bool? _readBool(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
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

  static String? _readString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  static TrainingLevelDerived? _readTrainingLevelDerived(
    Map<String, dynamic> extra,
  ) {
    final value = _readString(extra, [
      TrainingExtraKeys.trainingLevelDerived,
      TrainingExtraKeys.effectiveTrainingLevel,
      TrainingExtraKeys.trainingLevel,
      TrainingInterviewLegacyKeys.trainingLevel,
    ]);
    if (value == null) return null;
    switch (value.toLowerCase().trim()) {
      case 'beginner':
      case 'principiante':
        return TrainingLevelDerived.beginner;
      case 'intermediate':
      case 'intermedio':
        return TrainingLevelDerived.intermediate;
      case 'advanced':
      case 'avanzado':
        return TrainingLevelDerived.advanced;
      default:
        return null;
    }
  }
}
