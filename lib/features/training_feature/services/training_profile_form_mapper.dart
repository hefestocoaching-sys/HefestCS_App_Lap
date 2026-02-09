import 'package:flutter/foundation.dart';
import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/core/enums/training_level.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';

class TrainingProfileFormInput {
  final Map<String, dynamic> extra;
  final String? daysPerWeekLabel;
  final String? timePerSessionLabel;
  final int? planDurationWeeks;
  final List<String> priorityMusclesPrimary;
  final List<String> priorityMusclesSecondary;
  final List<String> priorityMusclesTertiary;
  final List<String> equipment;
  final List<String> movementRestrictions;
  final double? avgSleepHours;
  final String? perceivedStress;
  final String? recoveryQuality;
  final bool usesAnabolics;
  final bool isCompetitor;
  final String? competitionCategory;
  final String? competitionDateIso;
  final String? prSquat;
  final String? prBench;
  final String? prDeadlift;

  const TrainingProfileFormInput({
    required this.extra,
    required this.daysPerWeekLabel,
    required this.timePerSessionLabel,
    required this.planDurationWeeks,
    required this.priorityMusclesPrimary,
    required this.priorityMusclesSecondary,
    required this.priorityMusclesTertiary,
    this.equipment = const [],
    this.movementRestrictions = const [],
    required this.avgSleepHours,
    required this.perceivedStress,
    required this.recoveryQuality,
    required this.usesAnabolics,
    required this.isCompetitor,
    required this.competitionCategory,
    required this.competitionDateIso,
    required this.prSquat,
    required this.prBench,
    required this.prDeadlift,
  });
}

class TrainingProfileFormMapper {
  TrainingProfileFormMapper._();

  static TrainingProfile apply({
    required TrainingProfile base,
    required TrainingProfileFormInput input,
  }) {
    // INICIAR CON TODOS LOS DATOS EXISTENTES del base para preservarlos
    final extra = Map<String, dynamic>.from(base.extra);

    // LUEGO SOBRESCRIBIR CON LOS NUEVOS DATOS del input
    extra.addAll(input.extra);

    final daysPerWeek = _parseDaysPerWeek(
      input.daysPerWeekLabel,
      fallback: base.daysPerWeek,
    );
    final timePerSessionMinutes = _parseMinutes(
      input.timePerSessionLabel,
      fallback: base.timePerSessionMinutes,
    );
    final blockLengthWeeks =
        input.planDurationWeeks ??
        (base.blockLengthWeeks > 0 ? base.blockLengthWeeks : 4);

    final effectiveLevelRaw =
        input.extra[TrainingExtraKeys.effectiveTrainingLevel] ??
        input.extra[TrainingExtraKeys.legacyTrainingLevel] ??
        input.extra[TrainingExtraKeys.trainingLevel];
    final trainingLevel =
        parseTrainingLevel(effectiveLevelRaw?.toString()) ?? base.trainingLevel;

    extra[TrainingExtraKeys.daysPerWeek] = daysPerWeek;
    extra[TrainingExtraKeys.timePerSession] = input.timePerSessionLabel;
    extra[TrainingExtraKeys.timePerSessionMinutes] = timePerSessionMinutes;
    extra[TrainingExtraKeys.planDurationInWeeks] = blockLengthWeeks;
    extra[TrainingExtraKeys.availableEquipment] = input.equipment;
    extra[TrainingExtraKeys.movementRestrictions] = input.movementRestrictions;
    // NO SOBRESCRIBIR avgSleepHours si ya está en extra (viene del formulario cerrado)
    if (!extra.containsKey(TrainingExtraKeys.sleepBucket)) {
      extra[TrainingExtraKeys.avgSleepHours] = input.avgSleepHours;
    }
    // NO SOBRESCRIBIR perceivedStress si ya está en extra (viene del formulario cerrado)
    if (!extra.containsKey(TrainingExtraKeys.stressLevel)) {
      extra[TrainingExtraKeys.perceivedStress] = input.perceivedStress;
    }
    // NO SOBRESCRIBIR recoveryQuality si ya está en extra (viene del formulario cerrado)
    if (!extra.containsKey(TrainingExtraKeys.recoveryQuality)) {
      extra[TrainingExtraKeys.recoveryQuality] = input.recoveryQuality;
    }
    extra[TrainingExtraKeys.usesAnabolics] = input.usesAnabolics;
    extra[TrainingExtraKeys.isCompetitor] = input.isCompetitor;
    extra[TrainingExtraKeys.competitionCategory] = input.competitionCategory;
    extra[TrainingExtraKeys.competitionDateIso] = input.competitionDateIso;
    extra[TrainingExtraKeys.priorityMusclesPrimary] = input
        .priorityMusclesPrimary
        .join(', ');
    extra[TrainingExtraKeys.priorityMusclesSecondary] = input
        .priorityMusclesSecondary
        .join(', ');
    extra[TrainingExtraKeys.priorityMusclesTertiary] = input
        .priorityMusclesTertiary
        .join(', ');
    extra[TrainingExtraKeys.prSquat] = input.prSquat;
    extra[TrainingExtraKeys.prBench] = input.prBench;
    extra[TrainingExtraKeys.prDeadlift] = input.prDeadlift;

    // COPIAR CAMPOS DEL FORMULARIO CERRADO (si están presentes en input.extra)
    // Esto asegura que los enums y valores cerrados lleguen al profile.extra
    final closedFormKeys = [
      TrainingExtraKeys.discipline,
      TrainingExtraKeys.trainingAge,
      TrainingExtraKeys.historicalFrequency,
      TrainingExtraKeys.plannedFrequency,
      TrainingExtraKeys.timePerSessionBucket,
      TrainingExtraKeys.volumeTolerance,
      TrainingExtraKeys.intensityTolerance,
      TrainingExtraKeys.restProfile,
      TrainingExtraKeys.sleepBucket,
      TrainingExtraKeys.stressLevel,
      TrainingExtraKeys.activeInjuries,
      TrainingExtraKeys.knowsPRs,
      // Nuevos campos ampliados
      TrainingExtraKeys.heightCm,
      TrainingExtraKeys.strengthLevelClass,
      TrainingExtraKeys.workCapacityScore,
      TrainingExtraKeys.recoveryHistoryScore,
      TrainingExtraKeys.externalRecoverySupport,
      TrainingExtraKeys.programNoveltyClass,
      TrainingExtraKeys.externalPhysicalStressLevel,
      TrainingExtraKeys.nonPhysicalStressLevel2,
      TrainingExtraKeys.restQuality2,
      TrainingExtraKeys.dietHabitsClass,
    ];
    for (final key in closedFormKeys) {
      if (input.extra.containsKey(key)) {
        extra[key] = input.extra[key];
      }
    }

    final profileForCalculation = base.copyWith(
      trainingLevel: trainingLevel,
      daysPerWeek: daysPerWeek,
      timePerSessionMinutes: timePerSessionMinutes,
      equipment: input.equipment.isNotEmpty ? input.equipment : base.equipment,
      avgSleepHours: input.avgSleepHours ?? base.avgSleepHours,
      perceivedStress: input.perceivedStress ?? base.perceivedStress,
      recoveryQuality: input.recoveryQuality ?? base.recoveryQuality,
      usesAnabolics: input.usesAnabolics,
      isCompetitor: input.isCompetitor,
      competitionCategory:
          input.competitionCategory ?? base.competitionCategory,
      priorityMusclesPrimary: input.priorityMusclesPrimary,
      priorityMusclesSecondary: input.priorityMusclesSecondary,
      priorityMusclesTertiary: input.priorityMusclesTertiary,
      blockLengthWeeks: blockLengthWeeks,
      prSquat: input.prSquat ?? base.prSquat,
      prBench: input.prBench ?? base.prBench,
      prDeadlift: input.prDeadlift ?? base.prDeadlift,
      extra: extra,
      date: DateTime.now(),
    );

    return profileForCalculation;
  }

  static String? optionFromTrainingLevel(TrainingLevel? level) {
    switch (level) {
      case TrainingLevel.beginner:
        return 'Principiante (0-6 meses)';
      case TrainingLevel.intermediate:
        return 'Intermedio (6m - 2 años)';
      case TrainingLevel.advanced:
        return 'Avanzado (+2 años)';
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

  static int _parseDaysPerWeek(String? value, {required int fallback}) {
    if (value == null) return fallback;
    final match = RegExp(r'\d+').firstMatch(value);
    if (match == null) return fallback;
    final parsed = int.tryParse(match.group(0)!);
    if (parsed == null) return fallback;
    final normalized = parsed.clamp(3, 6);
    if (normalized != fallback) {
      debugPrint(
        'TrainingProfileFormMapper._parseDaysPerWeek raw=$value normalized=$normalized fallback=$fallback',
      );
    }
    return normalized;
  }

  // ignore: unused_element
  static int _parseInt(String? value, {int fallback = 0}) {
    if (value == null) return fallback;
    return int.tryParse(value) ?? fallback;
  }

  static int _parseMinutes(String? label, {int fallback = 0}) {
    if (label == null) return fallback;
    final match = RegExp(r'\d+').firstMatch(label);
    if (match == null) return fallback;
    return int.tryParse(match.group(0)!) ?? fallback;
  }
}
