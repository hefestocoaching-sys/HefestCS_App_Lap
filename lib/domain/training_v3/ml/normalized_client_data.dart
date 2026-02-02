import 'package:equatable/equatable.dart';

/// Datos normalizados y enriquecidos del cliente.
///
/// Esta clase representa la CAPA 1 del Motor V3 Unificado.
/// Extrae, normaliza y enriquece datos desde ClientDataSnapshot.
///
/// VERSION: v1.0.0
/// FECHA: 2 de febrero de 2026
///
/// PROPÓSITO:
/// - Normalizar datos de múltiples fuentes con prioridad
/// - Calcular campos derivados y clasificaciones
/// - Aplicar ajustes según Israetel (altura, peso, sueño, experiencia)
/// - Servir como input para motor de entrenamiento V3
///
/// GARANTÍAS:
/// - Inmutable (Equatable)
/// - Todos los campos calculados documentados
/// - Trazabilidad de fuentes de datos
class NormalizedClientData extends Equatable {
  // =========================================================================
  // A) DEMOGRAPHICS
  // =========================================================================

  /// Edad en años
  /// Prioridad: TrainingProfile.age > ClientProfile (calculado)
  final int? age;

  /// Género ('male', 'female', 'other')
  final String? gender;

  /// Categoría de edad según Israetel
  /// 'youth' (<18), 'adult' (18-40), 'middle' (40-60), 'senior' (>60)
  final String? ageCategory;

  // =========================================================================
  // B) ANTHROPOMETRICS ⭐⭐⭐
  // =========================================================================

  /// Altura en centímetros
  /// ⭐ CRÍTICO: AnthropometryRecord.heightCm > TrainingProfile.extra['height']
  final double? heightCm;

  /// Peso en kilogramos
  /// Prioridad: AnthropometryRecord.weightKg > TrainingProfile.bodyWeight
  final double? weightKg;

  /// Índice de masa corporal (calculado)
  final double? bmi;

  /// Clasificación de altura según Israetel
  /// 'very_short' (<160), 'short' (160-170), 'average' (170-180),
  /// 'tall' (180-190), 'very_tall' (>190)
  final String? heightClass;

  /// Clasificación de peso según Israetel
  /// 'underweight' (<18.5 BMI), 'normal' (18.5-25), 'overweight' (25-30),
  /// 'obese' (>30)
  final String? weightClass;

  /// Ajuste VME por altura (multiplicador)
  /// Israetel: Personas altas (+10% si >185cm), bajas (-10% si <165cm)
  final double heightAdjustmentVME;

  /// Ajuste VMR por altura (multiplicador)
  final double heightAdjustmentVMR;

  /// Ajuste VME por peso (multiplicador)
  /// Basado en masa muscular estimada
  final double weightAdjustmentVME;

  /// Ajuste VMR por peso (multiplicador)
  final double weightAdjustmentVMR;

  // =========================================================================
  // C) PHYSICAL CAPACITY
  // =========================================================================

  /// Clasificación de fuerza desde PRs usando Wilks/IPF
  /// 'class_III', 'class_II', 'class_I', 'master', 'elite'
  final String? strengthClass;

  /// Capacidad de trabajo (1-5)
  /// TrainingInterviewKeys.workCapacity o estimado desde logs
  final int? workCapacity;

  /// Capacidad de recuperación (1-5)
  /// TrainingInterviewKeys.recoveryHistory o estimado
  final int? recoveryCapacity;

  // =========================================================================
  // D) RECOVERY PROFILE
  // =========================================================================

  /// Horas de sueño promedio (últimas 4 semanas de DailyTracking)
  final double? avgSleepHours;

  /// Categoría de sueño
  /// '<5h', '5-7h', '7-9h', '>9h'
  final String? sleepCategory;

  /// Estrés físico (1-5)
  /// TrainingInterviewKeys.physicalStress o estimado
  final int? physicalStress;

  /// Estrés no físico (1-5)
  /// TrainingInterviewKeys.nonPhysicalStress
  final int? nonPhysicalStress;

  /// HRV promedio (últimas 4 semanas)
  /// Heart Rate Variability - indicador de recuperación
  final double? avgHRV;

  /// RHR promedio (últimas 4 semanas)
  /// Resting Heart Rate
  final double? avgRHR;

  /// Ajuste VME por sueño (multiplicador)
  /// Israetel: -20% si <6h, -10% si 6-7h, normal si 7-9h, +5% si >9h
  final double sleepAdjustmentVME;

  /// Ajuste VMR por sueño (multiplicador)
  final double sleepAdjustmentVMR;

  /// Ajuste VME por estrés (multiplicador)
  /// -15% si estrés alto (>7)
  final double stressAdjustmentVME;

  /// Ajuste VMR por estrés (multiplicador)
  final double stressAdjustmentVMR;

  // =========================================================================
  // E) TRAINING EXPERIENCE
  // =========================================================================

  /// Nivel efectivo calculado (más preciso que declarado)
  /// Basado en: años + fuerza + volumen tolerado
  final String? effectiveLevel;

  /// Subpoblación según Israetel
  /// 'novice', 'beginner', 'intermediate', 'advanced', 'elite', 'master'
  final String? subpopulation;

  /// Novedad del programa (0.0-1.0)
  /// Comparando plan actual vs anteriores
  /// 1.0 = completamente nuevo, 0.0 = idéntico
  final double programNovelty;

  /// Ajuste VME por experiencia (multiplicador)
  /// Principiantes: -20%, Intermedios: 0%, Avanzados: +15%
  final double experienceAdjustmentVME;

  /// Ajuste VMR por experiencia (multiplicador)
  final double experienceAdjustmentVMR;

  /// Ajuste VME por novedad del programa (multiplicador)
  /// -15% si programa nuevo (>0.7 novelty)
  final double noveltyAdjustmentVME;

  /// Ajuste VMR por novedad del programa (multiplicador)
  final double noveltyAdjustmentVMR;

  // =========================================================================
  // F) HISTORICAL VOLUME ⭐⭐⭐ (ML)
  // =========================================================================

  /// Límites de volumen observados por músculo
  /// Map<String, ObservedVolumeLimits>
  /// Calculado desde logs de sesiones (últimas 8 semanas)
  final Map<String, ObservedVolumeLimits> observedLimitsByMuscle;

  // =========================================================================
  // G) PHARMACOLOGY
  // =========================================================================

  /// Usa anabólicos
  final bool usesAnabolics;

  /// Ajuste VMR por anabólicos (multiplicador)
  /// Israetel: +15% MRV si usa anabólicos
  final double anabolicsAdjustmentVMR;

  // =========================================================================
  // H) REST & RECOVERY
  // =========================================================================

  /// Descanso entre series (segundos)
  final int? restBetweenSetsSeconds;

  /// Ajuste por descanso entre series (multiplicador)
  /// Israetel: 1.8x si <120s (menos descanso → más fatiga)
  final double restAdjustmentFatigue;

  // =========================================================================
  // CONSTRUCTOR
  // =========================================================================

  const NormalizedClientData({
    // Demographics
    this.age,
    this.gender,
    this.ageCategory,
    // Anthropometrics
    this.heightCm,
    this.weightKg,
    this.bmi,
    this.heightClass,
    this.weightClass,
    this.heightAdjustmentVME = 1.0,
    this.heightAdjustmentVMR = 1.0,
    this.weightAdjustmentVME = 1.0,
    this.weightAdjustmentVMR = 1.0,
    // Physical Capacity
    this.strengthClass,
    this.workCapacity,
    this.recoveryCapacity,
    // Recovery Profile
    this.avgSleepHours,
    this.sleepCategory,
    this.physicalStress,
    this.nonPhysicalStress,
    this.avgHRV,
    this.avgRHR,
    this.sleepAdjustmentVME = 1.0,
    this.sleepAdjustmentVMR = 1.0,
    this.stressAdjustmentVME = 1.0,
    this.stressAdjustmentVMR = 1.0,
    // Training Experience
    this.effectiveLevel,
    this.subpopulation,
    this.programNovelty = 0.0,
    this.experienceAdjustmentVME = 1.0,
    this.experienceAdjustmentVMR = 1.0,
    this.noveltyAdjustmentVME = 1.0,
    this.noveltyAdjustmentVMR = 1.0,
    // Historical Volume
    this.observedLimitsByMuscle = const {},
    // Pharmacology
    this.usesAnabolics = false,
    this.anabolicsAdjustmentVMR = 1.0,
    // Rest & Recovery
    this.restBetweenSetsSeconds,
    this.restAdjustmentFatigue = 1.0,
  });

  @override
  List<Object?> get props => [
        age,
        gender,
        ageCategory,
        heightCm,
        weightKg,
        bmi,
        heightClass,
        weightClass,
        heightAdjustmentVME,
        heightAdjustmentVMR,
        weightAdjustmentVME,
        weightAdjustmentVMR,
        strengthClass,
        workCapacity,
        recoveryCapacity,
        avgSleepHours,
        sleepCategory,
        physicalStress,
        nonPhysicalStress,
        avgHRV,
        avgRHR,
        sleepAdjustmentVME,
        sleepAdjustmentVMR,
        stressAdjustmentVME,
        stressAdjustmentVMR,
        effectiveLevel,
        subpopulation,
        programNovelty,
        experienceAdjustmentVME,
        experienceAdjustmentVMR,
        noveltyAdjustmentVME,
        noveltyAdjustmentVMR,
        observedLimitsByMuscle,
        usesAnabolics,
        anabolicsAdjustmentVMR,
        restBetweenSetsSeconds,
        restAdjustmentFatigue,
      ];

  // =========================================================================
  // HELPERS
  // =========================================================================

  /// Ajuste VME total (producto de todos los ajustes)
  double get totalVMEAdjustment {
    return heightAdjustmentVME *
        weightAdjustmentVME *
        sleepAdjustmentVME *
        stressAdjustmentVME *
        experienceAdjustmentVME *
        noveltyAdjustmentVME;
  }

  /// Ajuste VMR total (producto de todos los ajustes)
  double get totalVMRAdjustment {
    return heightAdjustmentVMR *
        weightAdjustmentVMR *
        sleepAdjustmentVMR *
        stressAdjustmentVMR *
        experienceAdjustmentVMR *
        noveltyAdjustmentVMR *
        anabolicsAdjustmentVMR;
  }

  /// Indica si hay suficientes datos para cálculos Israetel
  bool get hasMinimalData {
    return heightCm != null && weightKg != null && age != null;
  }

  /// Indica si hay datos de sueño promedio
  bool get hasSleepData => avgSleepHours != null;

  /// Indica si hay datos históricos de volumen
  bool get hasVolumeHistory => observedLimitsByMuscle.isNotEmpty;
}

/// Límites de volumen observados para un músculo específico.
///
/// Calculado desde logs de sesiones (ML).
class ObservedVolumeLimits extends Equatable {
  /// Nombre del músculo
  final String muscleName;

  /// VME observado (sets/semana)
  /// Mínimo efectivo de volumen que genera adaptación
  final double? observedMEV;

  /// VMÁ observado (sets/semana)
  /// Máximo adaptativo de volumen (máximo estímulo sin fatiga excesiva)
  final double? observedMAV;

  /// VMR observado (sets/semana)
  /// Máximo recuperable de volumen
  final double? observedMRV;

  /// Confianza en los datos (0.0-1.0)
  /// Basado en cantidad de semanas de datos
  final double confidence;

  const ObservedVolumeLimits({
    required this.muscleName,
    this.observedMEV,
    this.observedMAV,
    this.observedMRV,
    this.confidence = 0.0,
  });

  @override
  List<Object?> get props => [
        muscleName,
        observedMEV,
        observedMAV,
        observedMRV,
        confidence,
      ];

  /// Indica si hay suficiente confianza en los datos
  bool get isReliable => confidence >= 0.5;
}
