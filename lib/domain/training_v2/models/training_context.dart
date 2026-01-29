import 'package:equatable/equatable.dart';
import 'package:hcs_app_lap/core/enums/gender.dart';
import 'package:hcs_app_lap/core/enums/training_focus.dart';
import 'package:hcs_app_lap/core/enums/training_goal.dart';
import 'package:hcs_app_lap/core/enums/training_level.dart';
import 'package:hcs_app_lap/core/enums/training_interview_enums.dart';
import 'package:hcs_app_lap/domain/entities/athlete_longitudinal_state.dart';
import 'package:hcs_app_lap/domain/training_v2/models/training_block_context.dart';

/// Contrato canónico e inmutable para el Motor de Entrenamiento v2.
/// El motor v2 NO debe leer Client/extra/UI directamente.
/// TODO lo que necesite debe venir aquí.
class TrainingContext extends Equatable {
  final DateTime asOfDate;
  final int schemaVersion;

  final AthleteSnapshot athlete;
  final TrainingMetaSnapshot meta;
  final TrainingInterviewSnapshot interview;
  final EnergyAvailabilitySnapshot energy;
  final ConstraintsSnapshot constraints;
  final PrioritiesSnapshot priorities;

  /// Contexto de bloque macro (periodización) si existe un macroplan.
  final TrainingBlockContext? blockContext;

  /// Perfiles de intensidad (light/medium/heavy con min/max/rir por plan).
  /// Format: {'light': {'min': 55, 'max': 65, 'rir': 4}, ...}
  final Map<String, Map<String, num>> intensityProfiles;

  /// Estado longitudinal (prior) para aprendizaje local por cliente.
  final AthleteLongitudinalState longitudinal;

  /// Manual overrides (TrainingExtraKeys.manualOverrides) ya normalizados.
  final Map<String, dynamic> manualOverrides;

  const TrainingContext({
    required this.asOfDate,
    required this.schemaVersion,
    required this.athlete,
    required this.meta,
    required this.interview,
    required this.energy,
    required this.constraints,
    required this.priorities,
    required this.longitudinal,
    required this.manualOverrides,
    required this.intensityProfiles,
    this.blockContext,
  });

  @override
  List<Object?> get props => [
    asOfDate,
    schemaVersion,
    athlete,
    meta,
    interview,
    energy,
    constraints,
    priorities,
    longitudinal,
    manualOverrides,
    intensityProfiles,
    blockContext,
  ];
}

/// Snapshot biológico mínimo para prescripción y clamps.
class AthleteSnapshot extends Equatable {
  final Gender? gender;
  final int? ageYears;
  final double? heightCm;
  final double? weightKg;

  final bool usesAnabolics;
  final bool isCompetitor;

  const AthleteSnapshot({
    required this.gender,
    required this.ageYears,
    required this.heightCm,
    required this.weightKg,
    required this.usesAnabolics,
    required this.isCompetitor,
  });

  @override
  List<Object?> get props => [
    gender,
    ageYears,
    heightCm,
    weightKg,
    usesAnabolics,
    isCompetitor,
  ];
}

/// Meta de entrenamiento y restricciones operativas del plan (frecuencia, etc.)
class TrainingMetaSnapshot extends Equatable {
  final TrainingGoal goal;
  final TrainingFocus? focus;
  final TrainingLevel? level;

  final int daysPerWeek;
  final int timePerSessionMinutes;

  const TrainingMetaSnapshot({
    required this.goal,
    required this.focus,
    required this.level,
    required this.daysPerWeek,
    required this.timePerSessionMinutes,
  });

  @override
  List<Object?> get props => [
    goal,
    focus,
    level,
    daysPerWeek,
    timePerSessionMinutes,
  ];
}

/// Entrevista de entrenamiento normalizada (fuente para VME/VMR, readiness y clamps).
class TrainingInterviewSnapshot extends Equatable {
  // Cuantitativos base
  final int yearsTrainingContinuous;
  final int sessionDurationMinutes;
  final int restBetweenSetsSeconds;
  final double avgSleepHours;

  // Escalas 1-5
  final int workCapacity; // TrainingInterviewKeys.workCapacity
  final int recoveryHistory; // TrainingInterviewKeys.recoveryHistory
  final bool externalRecovery; // TrainingInterviewKeys.externalRecovery

  // Enums (si existen)
  final ProgramNovelty? programNovelty;
  final InterviewStressLevel? physicalStress;
  final InterviewStressLevel? nonPhysicalStress;
  final InterviewRestQuality? restQuality;
  final DietQuality? dietQuality;

  const TrainingInterviewSnapshot({
    required this.yearsTrainingContinuous,
    required this.sessionDurationMinutes,
    required this.restBetweenSetsSeconds,
    required this.avgSleepHours,
    required this.workCapacity,
    required this.recoveryHistory,
    required this.externalRecovery,
    required this.programNovelty,
    required this.physicalStress,
    required this.nonPhysicalStress,
    required this.restQuality,
    required this.dietQuality,
  });

  @override
  List<Object?> get props => [
    yearsTrainingContinuous,
    sessionDurationMinutes,
    restBetweenSetsSeconds,
    avgSleepHours,
    workCapacity,
    recoveryHistory,
    externalRecovery,
    programNovelty,
    physicalStress,
    nonPhysicalStress,
    restQuality,
    dietQuality,
  ];
}

/// Señal derivada (NO "nutrición"), solo disponibilidad energética para recuperación.
/// Se deriva de NutritionExtraKeys.evaluationRecords si existe.
class EnergyAvailabilitySnapshot extends Equatable {
  final int? dailyKcal;
  final int? dailyGet;
  final int? deltaKcalMinusGet;

  /// deficit / maintenance / surplus
  final String state;

  /// Magnitud absoluta del delta (|kcal-get|)
  final int magnitude;

  const EnergyAvailabilitySnapshot({
    required this.dailyKcal,
    required this.dailyGet,
    required this.deltaKcalMinusGet,
    required this.state,
    required this.magnitude,
  });

  factory EnergyAvailabilitySnapshot.unknown() {
    return const EnergyAvailabilitySnapshot(
      dailyKcal: null,
      dailyGet: null,
      deltaKcalMinusGet: null,
      state: 'unknown',
      magnitude: 0,
    );
  }

  @override
  List<Object?> get props => [
    dailyKcal,
    dailyGet,
    deltaKcalMinusGet,
    state,
    magnitude,
  ];
}

/// Lesiones, restricciones de movimiento y/o de equipamiento.
class ConstraintsSnapshot extends Equatable {
  final List<String> movementRestrictions;
  final List<String> availableEquipment;

  /// TrainingExtraKeys.activeInjuries (UI usa InjuryRegion enum -> guardado como String)
  final List<String> activeInjuries;

  const ConstraintsSnapshot({
    required this.movementRestrictions,
    required this.availableEquipment,
    required this.activeInjuries,
  });

  @override
  List<Object?> get props => [
    movementRestrictions,
    availableEquipment,
    activeInjuries,
  ];
}

/// Prioridades musculares ya normalizadas para el motor.
class PrioritiesSnapshot extends Equatable {
  final List<String> primary;
  final List<String> secondary;
  final List<String> tertiary;

  const PrioritiesSnapshot({
    required this.primary,
    required this.secondary,
    required this.tertiary,
  });

  @override
  List<Object?> get props => [primary, secondary, tertiary];
}
