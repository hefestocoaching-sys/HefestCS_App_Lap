import 'package:equatable/equatable.dart';
import 'package:hcs_app_lap/core/enums/gender.dart';
import 'package:hcs_app_lap/core/enums/training_focus.dart';
import 'package:hcs_app_lap/core/enums/training_goal.dart';
import 'package:hcs_app_lap/core/enums/training_level.dart';
import 'package:hcs_app_lap/core/enums/training_interview_enums.dart';
import 'package:hcs_app_lap/core/enums/performance_trend.dart';
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

/// Entrevista de entrenamiento normalizada V2 (2025)
/// Basado en investigación de Israetel, Schoenfeld, Helms, NSCA 2024-2025
class TrainingInterviewSnapshot extends Equatable {
  // ════════════════════════════════════════════════════════════════
  // MANDATORY FIELDS - Requeridos para motor V2
  // ════════════════════════════════════════════════════════════════

  // HISTORIAL
  /// Años entrenando de forma continua (sin pausas >3 meses)
  final int yearsTrainingContinuous;

  /// Duración promedio de sesión en minutos
  final int sessionDurationMinutes;

  /// Descanso entre sets en segundos
  final int restBetweenSetsSeconds;

  /// Horas de sueño promedio por noche
  final double avgSleepHours;

  // VOLUMEN (NUEVOS V2)
  /// Sets promedio por músculo por semana
  /// Ejemplo: 12 = entrena pecho con 12 sets totales/semana
  /// Rango típico: 8-25 sets
  final int avgWeeklySetsPerMuscle;

  /// Semanas consecutivas entrenando sin pausas >1 semana
  /// Usado para evaluar consistencia
  final int consecutiveWeeksTraining;

  // RECUPERACIÓN (NUEVOS V2)
  /// Perceived Recovery Status (1-10)
  /// 1 = Completamente fatigado, 10 = Completamente recuperado
  final int perceivedRecoveryStatus;

  /// Nivel de estrés diario (1-10)
  /// 1 = Sin estrés, 10 = Estrés extremo
  final int stressLevel;

  // READINESS (NUEVOS V2)
  /// Reps In Reserve promedio (0-5)
  /// 0 = Fallo muscular, 5 = Muy fácil
  /// CRÍTICO para autoregulación por RIR
  final double averageRIR;

  /// Rating of Perceived Exertion promedio (1-10)
  /// Esfuerzo percibido al final de sesión
  final int averageSessionRPE;

  // ════════════════════════════════════════════════════════════════
  // LEGACY FIELDS - Compatibilidad V1
  // ════════════════════════════════════════════════════════════════

  // Escalas 1-5
  final int workCapacity;
  final int recoveryHistory;
  final bool externalRecovery;

  // Enums (si existen)
  final ProgramNovelty? programNovelty;
  final InterviewStressLevel? physicalStress;
  final InterviewStressLevel? nonPhysicalStress;
  final InterviewRestQuality? restQuality;
  final DietQuality? dietQuality;

  // ════════════════════════════════════════════════════════════════
  // RECOMMENDED FIELDS V2 - Mejoran precisión (nullable)
  // ════════════════════════════════════════════════════════════════

  /// Máximo sets/semana antes de overreaching (usado para MRV individual)
  final int? maxWeeklySetsBeforeOverreaching;

  /// Frecuencia de deload en semanas
  final int? deloadFrequencyWeeks;

  /// Resting Heart Rate (bpm, medido por la mañana)
  final int? restingHeartRate;

  /// Heart Rate Variability (ms, RMSSD)
  final double? heartRateVariability;

  /// DOMS promedio a las 48h (1-10)
  final int? soreness48hAverage;

  /// Pausas >2 semanas en últimos 12 meses
  final int? periodBreaksLast12Months;

  /// Tasa de completitud de sesiones (0.0-1.0)
  final double? sessionCompletionRate;

  /// Tendencia de rendimiento actual
  final PerformanceTrend? performanceTrend;

  // ════════════════════════════════════════════════════════════════
  // OPTIONAL FIELDS - Personal Records
  // ════════════════════════════════════════════════════════════════

  /// Personal Records (opcionales)
  final int? prSquatKg;
  final int? prBenchKg;
  final int? prDeadliftKg;

  const TrainingInterviewSnapshot({
    // Mandatory
    required this.yearsTrainingContinuous,
    required this.sessionDurationMinutes,
    required this.restBetweenSetsSeconds,
    required this.avgSleepHours,
    required this.avgWeeklySetsPerMuscle,
    required this.consecutiveWeeksTraining,
    required this.perceivedRecoveryStatus,
    required this.stressLevel,
    required this.averageRIR,
    required this.averageSessionRPE,
    // Legacy
    required this.workCapacity,
    required this.recoveryHistory,
    required this.externalRecovery,
    required this.programNovelty,
    required this.physicalStress,
    required this.nonPhysicalStress,
    required this.restQuality,
    required this.dietQuality,
    // Recommended V2
    this.maxWeeklySetsBeforeOverreaching,
    this.deloadFrequencyWeeks,
    this.restingHeartRate,
    this.heartRateVariability,
    this.soreness48hAverage,
    this.periodBreaksLast12Months,
    this.sessionCompletionRate,
    this.performanceTrend,
    // Optional
    this.prSquatKg,
    this.prBenchKg,
    this.prDeadliftKg,
  });

  @override
  List<Object?> get props => [
    yearsTrainingContinuous,
    sessionDurationMinutes,
    restBetweenSetsSeconds,
    avgSleepHours,
    avgWeeklySetsPerMuscle,
    consecutiveWeeksTraining,
    perceivedRecoveryStatus,
    stressLevel,
    averageRIR,
    averageSessionRPE,
    workCapacity,
    recoveryHistory,
    externalRecovery,
    programNovelty,
    physicalStress,
    nonPhysicalStress,
    restQuality,
    dietQuality,
    maxWeeklySetsBeforeOverreaching,
    deloadFrequencyWeeks,
    restingHeartRate,
    heartRateVariability,
    soreness48hAverage,
    periodBreaksLast12Months,
    sessionCompletionRate,
    performanceTrend,
    prSquatKg,
    prBenchKg,
    prDeadliftKg,
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
