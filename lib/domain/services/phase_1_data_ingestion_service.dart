// ignore_for_file: deprecated_member_use_from_same_package
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/entities/training_history.dart';
import 'package:hcs_app_lap/domain/entities/training_feedback.dart';
import 'package:hcs_app_lap/domain/entities/decision_trace.dart';
import 'package:hcs_app_lap/domain/entities/training_session_log.dart';
import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/domain/entities/manual_override.dart';
import 'package:hcs_app_lap/domain/training_v2/models/training_context.dart';
import 'package:hcs_app_lap/core/constants/training_interview_keys.dart';
import 'package:hcs_app_lap/core/enums/performance_trend.dart';

/// Resultado de la Fase 1: Ingestión y validación de datos
class Phase1Result {
  final TrainingProfile profile;
  final TrainingHistory? history;
  final TrainingFeedback? latestFeedback;
  final List<DecisionTrace> decisions;
  final DerivedTrainingContext derivedContext;
  final bool isValid;
  final List<String> missingData;
  final List<String> warnings;
  final ManualOverride? manualOverride;

  const Phase1Result({
    required this.profile,
    this.history,
    this.latestFeedback,
    required this.decisions,
    required this.derivedContext,
    required this.isValid,
    this.missingData = const [],
    this.warnings = const [],
    this.manualOverride,
  });

  bool get hasHistory => history != null && history!.hasData;
  bool get hasFeedback => latestFeedback != null;
  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasCriticalIssues => !isValid || missingData.isNotEmpty;
}

/// Fase 1: Ingestión y validación de datos del perfil de entrenamiento.
///
/// V2: Ahora usa TrainingContext en lugar de TrainingProfile para aprovechar
/// los 30 campos de la entrevista científica 2025.
///
/// Responsabilidades:
/// - Validar que los datos mínimos estén presentes
/// - Normalizar valores (ej: valores nulos a defaults conservadores)
/// - Detectar inconsistencias o datos faltantes
/// - Registrar todas las decisiones en DecisionTrace
///
/// REGLA DE ORO: Si faltan datos → asumir valores conservadores.
class Phase1DataIngestionService {
  /// Valida e ingesta el TrainingContext V2 junto con datos históricos
  Phase1Result ingestAndValidate({
    required TrainingContext context,
    TrainingHistory? history,
    TrainingFeedback? latestFeedback,
    DateTime? referenceDate,
  }) {
    final decisions = <DecisionTrace>[];
    final warnings = <String>[];
    final missingData = <String>[];

    // Fecha de referencia para determinismo temporal
    final effectiveReferenceDate = referenceDate ?? context.asOfDate;

    // 0. Validar manual overrides si existen
    ManualOverride? override;
    if (context.manualOverrides.isNotEmpty) {
      override = ManualOverride.fromMap(context.manualOverrides);
      final overrideWarnings = override.validate();
      warnings.addAll(overrideWarnings);

      if (override.hasAnyOverride) {
        decisions.add(
          DecisionTrace.info(
            phase: 'manual_override',
            category: 'override_detected',
            description: 'Overrides manuales del coach detectados y validados',
            context: {
              'volumeOverrides': override.volumeOverrides?.keys.toList(),
              'priorityOverrides': override.priorityOverrides?.keys.toList(),
              'rirTargetOverride': override.rirTargetOverride,
              'allowIntensification': override.allowIntensification,
              'intensificationMaxPerWeek': override.intensificationMaxPerWeek,
              'validationWarnings': overrideWarnings.length,
            },
            action: 'Overrides serán aplicados en fases 3, 4, 5, 7',
          ),
        );
      }
    } else {
      override = const ManualOverride();
    }

    // 1. Validar datos críticos del perfil (meta)
    if (context.meta.daysPerWeek <= 0 ||
        context.meta.timePerSessionMinutes <= 0) {
      decisions.add(
        DecisionTrace.critical(
          phase: 'Phase1DataIngestionV2',
          category: 'profile_validation',
          description:
              'Contexto inválido: daysPerWeek=${context.meta.daysPerWeek}, '
              'timePerSessionMinutes=${context.meta.timePerSessionMinutes}',
          context: {
            'daysPerWeek': context.meta.daysPerWeek,
            'timePerSessionMinutes': context.meta.timePerSessionMinutes,
          },
          action: 'No se puede generar plan sin días y tiempo por sesión',
        ),
      );
      missingData.add('daysPerWeek o timePerSessionMinutes');
    } else {
      decisions.add(
        DecisionTrace.info(
          phase: 'Phase1DataIngestionV2',
          category: 'profile_validation',
          description:
              'Contexto válido: ${context.meta.daysPerWeek} días/semana, '
              '${context.meta.timePerSessionMinutes} min/sesión',
        ),
      );
    }

    // 2. Validar nivel de entrenamiento
    if (context.meta.level == null) {
      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase1DataIngestionV2',
          category: 'missing_data',
          description: 'Nivel de entrenamiento no especificado',
          action: 'Se asumirá nivel principiante (conservador)',
        ),
      );
      warnings.add('Nivel de entrenamiento no especificado');
      missingData.add('trainingLevel');
    }

    // 3. Validar objetivo de entrenamiento
    decisions.add(
      DecisionTrace.info(
        phase: 'Phase1DataIngestionV2',
        category: 'goal_analysis',
        description: 'Objetivo global: ${context.meta.goal.name}',
        context: {
          'goal': context.meta.goal.name,
          'focus': context.meta.focus?.name ?? 'no especificado',
        },
      ),
    );

    // ═════════════════════════════════════════════════════════════
    // 4. VALIDAR CAMPOS V2 (2025) - NUEVO
    // ═════════════════════════════════════════════════════════════

    _validateTrainingInterviewV2(
      context.interview,
      decisions,
      warnings,
      missingData,
    );

    // 5. Validar datos de recuperación (V2 usa campos mejorados)
    _validateRecoveryDataV2(context, decisions, warnings);

    // 6. Validar prioridades musculares
    _validateMusclePriorities(context.priorities, decisions, warnings);

    // 7. Validar constraints (lesiones, equipamiento)
    _validateConstraints(context.constraints, decisions, warnings);

    // 8. Validar historial si existe
    if (history != null && history.hasData) {
      decisions.add(
        DecisionTrace.info(
          phase: 'Phase1DataIngestionV2',
          category: 'history_analysis',
          description:
              'Historial disponible: ${history.totalSessions} sesiones, '
              'adherencia promedio ${(history.averageAdherence * 100).toStringAsFixed(1)}%',
          context: {
            'totalSessions': history.totalSessions,
            'completedSessions': history.completedSessions,
            'averageAdherence': history.averageAdherence,
            'averageRpe': history.averageRpe,
          },
        ),
      );

      // Verificar adherencia baja
      if (history.averageAdherence < 0.7) {
        decisions.add(
          DecisionTrace.warning(
            phase: 'Phase1DataIngestionV2',
            category: 'adherence_low',
            description:
                'Adherencia histórica baja (${(history.averageAdherence * 100).toStringAsFixed(1)}%)',
            action: 'Considerar plan más flexible o reducir volumen',
          ),
        );
        warnings.add('Adherencia histórica baja');
      }
    } else {
      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase1DataIngestionV2',
          category: 'missing_data',
          description: 'No hay historial de entrenamiento disponible',
          action: 'Se usarán valores conservadores sin referencia histórica',
        ),
      );
      warnings.add('Sin historial de entrenamiento');
    }

    // 9. Validar feedback reciente
    if (latestFeedback != null) {
      decisions.add(
        DecisionTrace.info(
          phase: 'Phase1DataIngestionV2',
          category: 'feedback_analysis',
          description:
              'Feedback disponible: fatiga=${latestFeedback.fatigue.toStringAsFixed(1)}, '
              'adherencia=${(latestFeedback.adherence * 100).toStringAsFixed(1)}%',
          context: {
            'fatigue': latestFeedback.fatigue,
            'soreness': latestFeedback.soreness,
            'motivation': latestFeedback.motivation,
            'adherence': latestFeedback.adherence,
            'sleepHours': latestFeedback.sleepHours,
            'stressLevel': latestFeedback.stressLevel,
          },
        ),
      );
    } else {
      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase1DataIngestionV2',
          category: 'missing_data',
          description: 'No hay feedback reciente disponible',
          action: 'Se usarán datos de entrevista V2 (PRS, RIR, RPE)',
        ),
      );
      warnings.add('Sin feedback reciente (usando datos V2)');
    }

    // 10. Validar farmacología (importante para ajustes de volumen)
    if (context.athlete.usesAnabolics) {
      decisions.add(
        DecisionTrace.info(
          phase: 'Phase1DataIngestionV2',
          category: 'pharmacology',
          description: 'Cliente usa farmacología anabólica',
          action: 'Se aplicarán ajustes de volumen (+10-15% MRV)',
        ),
      );
    }

    // Derivar contexto reusable para fases 2-8 (V2)
    final derivedContext = _buildDerivedContextV2(
      context: context,
      history: history,
      latestFeedback: latestFeedback,
      decisions: decisions,
      referenceDate: effectiveReferenceDate,
    );

    // 11. Decisión final de validación
    final isValid =
        context.meta.daysPerWeek > 0 &&
        context.meta.timePerSessionMinutes > 0 &&
        missingData.isEmpty;

    if (!isValid) {
      decisions.add(
        DecisionTrace.critical(
          phase: 'Phase1DataIngestionV2',
          category: 'validation_result',
          description:
              'Validación fallida: ${missingData.length} campos críticos faltantes',
          context: {'missingData': missingData},
          action: 'Requiere completar datos antes de generar plan',
        ),
      );
    } else if (warnings.isNotEmpty) {
      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase1DataIngestionV2',
          category: 'validation_result',
          description:
              'Validación con advertencias: ${warnings.length} puntos de atención',
          context: {'warnings': warnings},
          action: 'Se procederá con valores conservadores',
        ),
      );
    } else {
      decisions.add(
        DecisionTrace.info(
          phase: 'Phase1DataIngestionV2',
          category: 'validation_result',
          description:
              'Validación exitosa V2: todos los datos necesarios presentes',
        ),
      );
    }

    // NOTA: Phase1Result sigue usando TrainingProfile para compatibilidad
    // Se convierte TrainingContext → TrainingProfile internamente
    final legacyProfile = _contextToProfile(context);

    return Phase1Result(
      profile: legacyProfile,
      history: history,
      latestFeedback: latestFeedback,
      decisions: decisions,
      derivedContext: derivedContext,
      isValid: isValid,
      missingData: missingData,
      warnings: warnings,
      manualOverride: override,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // MÉTODOS PRIVADOS V2 (NUEVOS)
  // ═══════════════════════════════════════════════════════════════

  /// Valida campos de entrevista V2 (2025)
  void _validateTrainingInterviewV2(
    TrainingInterviewSnapshot interview,
    List<DecisionTrace> decisions,
    List<String> warnings,
    List<String> missingData,
  ) {
    decisions.add(
      DecisionTrace.info(
        phase: 'Phase1DataIngestionV2',
        category: 'interview_v2_analysis',
        description: 'Analizando entrevista científica V2 (30 campos)',
        context: {
          'avgWeeklySetsPerMuscle': interview.avgWeeklySetsPerMuscle,
          'consecutiveWeeksTraining': interview.consecutiveWeeksTraining,
          'perceivedRecoveryStatus': interview.perceivedRecoveryStatus,
          'averageRIR': interview.averageRIR,
          'averageSessionRPE': interview.averageSessionRPE,
          'performanceTrend':
              interview.performanceTrend?.name ?? 'no especificado',
        },
      ),
    );

    // Validar volumen histórico
    if (interview.avgWeeklySetsPerMuscle < 8) {
      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase1DataIngestionV2',
          category: 'volume_concern',
          description:
              'Volumen histórico bajo (${interview.avgWeeklySetsPerMuscle} sets/semana/músculo)',
          action: 'Considerar si es principiante o sub-entrenado',
        ),
      );
      warnings.add('Volumen histórico bajo');
    } else if (interview.avgWeeklySetsPerMuscle > 20) {
      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase1DataIngestionV2',
          category: 'volume_concern',
          description:
              'Volumen histórico muy alto (${interview.avgWeeklySetsPerMuscle} sets/semana/músculo)',
          action: 'Verificar tolerancia real o riesgo de overreaching',
        ),
      );
      warnings.add('Volumen histórico muy alto');
    }

    // Validar consistencia
    if (interview.consecutiveWeeksTraining < 4) {
      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase1DataIngestionV2',
          category: 'consistency_concern',
          description:
              'Baja consistencia (${interview.consecutiveWeeksTraining} semanas consecutivas)',
          action: 'Usar programa más conservador para reducir riesgo de lesión',
        ),
      );
      warnings.add('Baja consistencia reciente');
    }

    // Validar recuperación percibida (PRS)
    if (interview.perceivedRecoveryStatus < 5) {
      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase1DataIngestionV2',
          category: 'recovery_concern',
          description:
              'PRS bajo (${interview.perceivedRecoveryStatus}/10) - fatiga acumulada',
          action: 'Reducir volumen o programar deload',
        ),
      );
      warnings.add('Fatiga acumulada (PRS bajo)');
    }

    // Validar RIR promedio
    if (interview.averageRIR < 1.0) {
      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase1DataIngestionV2',
          category: 'intensity_concern',
          description:
              'RIR muy bajo (${interview.averageRIR}) - entrenando muy cerca del fallo',
          action: 'Puede estar acumulando fatiga excesiva',
        ),
      );
      warnings.add('Intensidad demasiado alta (RIR <1)');
    } else if (interview.averageRIR > 4.0) {
      decisions.add(
        DecisionTrace.info(
          phase: 'Phase1DataIngestionV2',
          category: 'intensity_analysis',
          description:
              'RIR alto (${interview.averageRIR}) - entrenando muy conservador',
          action: 'Puede aumentar intensidad para mejores resultados',
        ),
      );
    }

    // Validar RPE promedio
    if (interview.averageSessionRPE > 8) {
      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase1DataIngestionV2',
          category: 'intensity_concern',
          description:
              'RPE muy alto (${interview.averageSessionRPE}/10) - sesiones muy demandantes',
          action: 'Reducir volumen o intensidad para evitar burnout',
        ),
      );
      warnings.add('Sesiones muy demandantes (RPE >8)');
    }

    // Validar campos recommended (opcionales)
    if (interview.maxWeeklySetsBeforeOverreaching != null) {
      decisions.add(
        DecisionTrace.info(
          phase: 'Phase1DataIngestionV2',
          category: 'mrv_individual',
          description:
              'MRV individual observado: ${interview.maxWeeklySetsBeforeOverreaching} sets/semana',
          action: 'Usaremos este valor para calcular MRV personalizado',
        ),
      );
    }

    if (interview.deloadFrequencyWeeks != null) {
      decisions.add(
        DecisionTrace.info(
          phase: 'Phase1DataIngestionV2',
          category: 'deload_frequency',
          description:
              'Frecuencia de deload: cada ${interview.deloadFrequencyWeeks} semanas',
          action: 'Programaremos deloads según este patrón',
        ),
      );
    }

    if (interview.performanceTrend != null) {
      if (interview.performanceTrend == PerformanceTrend.declining) {
        decisions.add(
          DecisionTrace.warning(
            phase: 'Phase1DataIngestionV2',
            category: 'performance_declining',
            description: 'Rendimiento declinando - señal de fatiga acumulada',
            action: 'Programar deload inmediato o reducir volumen',
          ),
        );
        warnings.add('Rendimiento declinando');
      } else if (interview.performanceTrend == PerformanceTrend.improving) {
        decisions.add(
          DecisionTrace.info(
            phase: 'Phase1DataIngestionV2',
            category: 'performance_improving',
            description: 'Rendimiento mejorando - programa efectivo',
            action: 'Mantener enfoque actual, considerar progresión gradual',
          ),
        );
      }
    }
  }

  /// Valida datos de recuperación usando campos V2
  void _validateRecoveryDataV2(
    TrainingContext context,
    List<DecisionTrace> decisions,
    List<String> warnings,
  ) {
    final interview = context.interview;

    // Validar sueño
    if (interview.avgSleepHours < 6.0) {
      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase1DataIngestionV2',
          category: 'recovery_concern',
          description: 'Sueño insuficiente (${interview.avgSleepHours}h < 6h)',
          action: 'Reducir volumen por mala recuperación',
        ),
      );
      warnings.add('Sueño insuficiente');
    } else if (interview.avgSleepHours >= 8.0) {
      decisions.add(
        DecisionTrace.info(
          phase: 'Phase1DataIngestionV2',
          category: 'recovery_optimal',
          description: 'Sueño óptimo (${interview.avgSleepHours}h >= 8h)',
          action: 'Puede tolerar volumen más alto',
        ),
      );
    }

    // Validar DOMS (opcional)
    if (interview.soreness48hAverage != null &&
        interview.soreness48hAverage! > 7) {
      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase1DataIngestionV2',
          category: 'recovery_concern',
          description:
              'DOMS alto (${interview.soreness48hAverage}/10) a las 48h',
          action: 'Considerar reducir volumen o mejorar recuperación',
        ),
      );
      warnings.add('DOMS persistente');
    }

    // Validar pausas recientes
    if (interview.periodBreaksLast12Months != null &&
        interview.periodBreaksLast12Months! >= 3) {
      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase1DataIngestionV2',
          category: 'consistency_concern',
          description:
              'Múltiples pausas (${interview.periodBreaksLast12Months} pausas >2 semanas en 12 meses)',
          action: 'Adherencia puede ser problema - programa más flexible',
        ),
      );
      warnings.add('Múltiples pausas recientes');
    }
  }

  /// Valida prioridades musculares (V2)
  void _validateMusclePriorities(
    PrioritiesSnapshot priorities,
    List<DecisionTrace> decisions,
    List<String> warnings,
  ) {
    final totalPriorities =
        priorities.primary.length +
        priorities.secondary.length +
        priorities.tertiary.length;

    if (totalPriorities == 0) {
      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase1DataIngestionV2',
          category: 'muscle_priorities',
          description: 'No se especificaron prioridades musculares',
          action: 'Se usará enfoque balanceado (full-body)',
        ),
      );
      warnings.add('Sin prioridades musculares');
    } else {
      decisions.add(
        DecisionTrace.info(
          phase: 'Phase1DataIngestionV2',
          category: 'muscle_priorities',
          description:
              'Prioridades definidas: '
              '${priorities.primary.length} primarias, '
              '${priorities.secondary.length} secundarias, '
              '${priorities.tertiary.length} terciarias',
          context: {
            'primary': priorities.primary,
            'secondary': priorities.secondary,
            'tertiary': priorities.tertiary,
          },
        ),
      );
    }

    // Advertir si hay demasiadas prioridades primarias
    if (priorities.primary.length > 4) {
      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase1DataIngestionV2',
          category: 'muscle_priorities',
          description:
              'Demasiadas prioridades primarias (${priorities.primary.length} > 4)',
          action: 'Difícil distribuir volumen efectivo entre tantos grupos',
        ),
      );
      warnings.add('Demasiadas prioridades primarias');
    }
  }

  /// Valida constraints (lesiones, equipamiento)
  void _validateConstraints(
    ConstraintsSnapshot constraints,
    List<DecisionTrace> decisions,
    List<String> warnings,
  ) {
    // Validar lesiones activas
    if (constraints.activeInjuries.isNotEmpty) {
      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase1DataIngestionV2',
          category: 'active_injuries',
          description:
              'Lesiones activas detectadas: ${constraints.activeInjuries.join(', ')}',
          action: 'Se evitarán ejercicios contraindicados',
          context: {'injuries': constraints.activeInjuries},
        ),
      );
      warnings.add('Lesiones activas');
    }

    // Validar restricciones de movimiento
    if (constraints.movementRestrictions.isNotEmpty) {
      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase1DataIngestionV2',
          category: 'movement_restrictions',
          description:
              'Restricciones de movimiento: ${constraints.movementRestrictions.join(', ')}',
          action: 'Se evitarán patrones de movimiento restringidos',
        ),
      );
    }

    // Validar equipamiento disponible
    if (constraints.availableEquipment.isEmpty) {
      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase1DataIngestionV2',
          category: 'equipment_missing',
          description: 'No se especificó equipamiento disponible',
          action: 'Se asumirá gym comercial completo',
        ),
      );
      warnings.add('Equipamiento no especificado');
    } else {
      decisions.add(
        DecisionTrace.info(
          phase: 'Phase1DataIngestionV2',
          category: 'equipment_available',
          description:
              'Equipamiento disponible: ${constraints.availableEquipment.length} items',
          context: {'equipment': constraints.availableEquipment},
        ),
      );
    }
  }

  /// Construye DerivedTrainingContext desde TrainingContext V2
  DerivedTrainingContext _buildDerivedContextV2({
    required TrainingContext context,
    required TrainingHistory? history,
    required TrainingFeedback? latestFeedback,
    required List<DecisionTrace> decisions,
    required DateTime referenceDate,
  }) {
    // Usar datos V2 directamente
    final effectiveSleep =
        latestFeedback?.sleepHours ?? context.interview.avgSleepHours;

    double? effectiveAdherence;
    if (history != null && history.hasData) {
      effectiveAdherence = history.averageAdherence;
    }

    // Usar averageRIR de V2 si existe
    final effectiveAvgRir =
        latestFeedback?.avgRir ?? context.interview.averageRIR;

    // Parsear constraints
    final contraindicatedPatterns = context.constraints.activeInjuries.toSet();

    // TODO: Parsear exercise preferences (mustHave, dislikes) desde context.manualOverrides
    final exerciseMustHave = <String>{};
    final exerciseDislikes = <String>{};

    // Intensification desde manualOverrides
    final intensificationAllowed =
        context.manualOverrides['allowIntensification'] as bool? ?? true;
    final intensificationMaxPerSession =
        context.manualOverrides['intensificationMaxPerWeek'] as int? ?? 1;

    decisions.add(
      DecisionTrace.info(
        phase: 'Phase1DataIngestionV2',
        category: 'derived_context_v2',
        description: 'Contexto derivado V2 construido',
        context: {
          'effectiveSleepHours': effectiveSleep,
          'effectiveAdherence': effectiveAdherence,
          'effectiveAvgRir': effectiveAvgRir,
          'contraindicatedPatterns': contraindicatedPatterns.length,
        },
      ),
    );

    return DerivedTrainingContext(
      effectiveSleepHours: effectiveSleep,
      effectiveAdherence: effectiveAdherence,
      effectiveAvgRir: effectiveAvgRir,
      contraindicatedPatterns: contraindicatedPatterns,
      exerciseMustHave: exerciseMustHave,
      exerciseDislikes: exerciseDislikes,
      intensificationAllowed: intensificationAllowed,
      intensificationMaxPerSession: intensificationMaxPerSession,
      gluteSpecialization: null, // TODO: Derivar de context si aplica
      referenceDate: referenceDate,
    );
  }

  /// Convierte TrainingContext → TrainingProfile (compatibilidad legacy)
  TrainingProfile _contextToProfile(TrainingContext context) {
    final baseExtra = <String, dynamic>{};

    // Meta
    baseExtra[TrainingExtraKeys.trainingLevel] = context.meta.level?.name;
    baseExtra[TrainingExtraKeys.daysPerWeek] = context.meta.daysPerWeek;
    baseExtra[TrainingExtraKeys.timePerSessionMinutes] =
        context.meta.timePerSessionMinutes;

    // Interview
    baseExtra[TrainingInterviewKeys.yearsTrainingContinuous] =
        context.interview.yearsTrainingContinuous;
    baseExtra[TrainingInterviewKeys.avgSleepHours] =
        context.interview.avgSleepHours;
    baseExtra[TrainingInterviewKeys.sessionDurationMinutes] =
        context.interview.sessionDurationMinutes;
    baseExtra[TrainingInterviewKeys.restBetweenSetsSeconds] =
        context.interview.restBetweenSetsSeconds;

    // V2 fields
    baseExtra[TrainingInterviewKeys.avgWeeklySetsPerMuscle] =
        context.interview.avgWeeklySetsPerMuscle;
    baseExtra[TrainingInterviewKeys.consecutiveWeeksTraining] =
        context.interview.consecutiveWeeksTraining;
    baseExtra[TrainingInterviewKeys.perceivedRecoveryStatus] =
        context.interview.perceivedRecoveryStatus;
    baseExtra[TrainingInterviewKeys.averageRIR] = context.interview.averageRIR;
    baseExtra[TrainingInterviewKeys.averageSessionRPE] =
        context.interview.averageSessionRPE;

    // Priorities
    baseExtra[TrainingExtraKeys.priorityMusclesPrimary] =
        context.priorities.primary;
    baseExtra[TrainingExtraKeys.priorityMusclesSecondary] =
        context.priorities.secondary;
    baseExtra[TrainingExtraKeys.priorityMusclesTertiary] =
        context.priorities.tertiary;

    // Constraints
    baseExtra['activeInjuries'] = context.constraints.activeInjuries;

    // Athlete
    baseExtra['athlete.gender'] = context.athlete.gender?.name;
    baseExtra['athlete.ageYears'] = context.athlete.ageYears;
    baseExtra['athlete.heightCm'] = context.athlete.heightCm;
    baseExtra['athlete.weightKg'] = context.athlete.weightKg;
    baseExtra['athlete.usesAnabolics'] = context.athlete.usesAnabolics;
    baseExtra['athlete.isCompetitor'] = context.athlete.isCompetitor;

    // Energy
    baseExtra['energy.state'] = context.energy.state;
    baseExtra['energy.deltaKcalMinusGet'] = context.energy.deltaKcalMinusGet;
    baseExtra['energy.magnitude'] = context.energy.magnitude;

    // Manual overrides
    baseExtra[TrainingExtraKeys.manualOverrides] = context.manualOverrides;

    final profile = TrainingProfile(
      trainingLevel: context.meta.level,
      globalGoal: context.meta.goal,
      trainingFocus: context.meta.focus,
      daysPerWeek: context.meta.daysPerWeek,
      timePerSessionMinutes: context.meta.timePerSessionMinutes,
      extra: baseExtra,
    );

    return profile.normalizedFromExtra();
  }

  // ═══════════════════════════════════════════════════════════════
  // MÉTODOS LEGACY (mantener para compatibilidad)
  // ═══════════════════════════════════════════════════════════════

  DerivedTrainingContext _buildDerivedContext({
    required TrainingProfile profile,
    required TrainingHistory? history,
    required TrainingFeedback? latestFeedback,
    required List<DecisionTrace> decisions,
    required DateTime referenceDate,
  }) {
    final extra = profile.extra;

    // 1) Materializar datos de entrevista
    final interviewInjuries = extra[TrainingExtraKeys.injuries];
    final interviewPreferences = extra[TrainingExtraKeys.trainingPreferences];
    final interviewBarriers = extra[TrainingExtraKeys.barriers];
    final gluteSpecRaw = extra[TrainingExtraKeys.gluteSpecializationProfile];
    final logsRaw = extra[TrainingExtraKeys.trainingSessionLogRecords];
    final logs = readTrainingSessionLogs(logsRaw);

    final contraindicatedPatterns = <String>{};
    _parseInjuries(interviewInjuries, contraindicatedPatterns);

    final exerciseMustHave = <String>{};
    final exerciseDislikes = <String>{};
    final intensification = _parsePreferences(
      interviewPreferences,
      exerciseMustHave,
      exerciseDislikes,
    );

    final gluteSpec = _parseGluteSpec(gluteSpecRaw);

    decisions.add(
      DecisionTrace.info(
        phase: 'Phase1DataIngestion',
        category: 'interview_parsed',
        description:
            'Entrevista materializada (lesiones, preferencias, barreras)',
        context: {
          'injuriesType': interviewInjuries.runtimeType.toString(),
          'preferencesType': interviewPreferences.runtimeType.toString(),
          'barriersType': interviewBarriers.runtimeType.toString(),
        },
      ),
    );

    // 2) Derivar métricas efectivas
    final effectiveSleep = latestFeedback?.sleepHours ?? profile.avgSleepHours;

    double? effectiveAdherence;
    if (history != null && history.hasData) {
      effectiveAdherence = history.averageAdherence;
    } else if (logs.isNotEmpty) {
      final expected = profile.daysPerWeek > 0 ? profile.daysPerWeek : 1;
      final ratio = logs.length / expected;
      effectiveAdherence = ratio.clamp(0.0, 1.0);
    }

    double? effectiveAvgRir;
    if (latestFeedback?.avgRir != null) {
      effectiveAvgRir = latestFeedback!.avgRir;
    } else {
      final allRpe = <double>[];
      for (final log in logs) {
        for (final entry in log.entries) {
          if (entry.rpe != null && entry.rpe!.isNotEmpty) {
            allRpe.addAll(entry.rpe!.whereType<double>());
          }
        }
      }
      if (allRpe.isNotEmpty) {
        final meanRpe = allRpe.reduce((a, b) => a + b) / allRpe.length;
        effectiveAvgRir = (10 - meanRpe).clamp(0.0, 5.0);
      }
    }

    decisions.add(
      DecisionTrace.info(
        phase: 'Phase1DataIngestion',
        category: 'derived_metrics',
        description: 'Métricas efectivas derivadas',
        context: {
          'effectiveSleepHours': effectiveSleep,
          'effectiveAdherence': effectiveAdherence,
          'effectiveAvgRir': effectiveAvgRir,
        },
      ),
    );

    if (contraindicatedPatterns.isNotEmpty) {
      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase1DataIngestion',
          category: 'injury_constraints',
          description:
              'Patrones contraindicados por lesiones: ${contraindicatedPatterns.join(', ')}',
          context: {
            'contraindicatedPatterns': contraindicatedPatterns.toList(),
          },
        ),
      );
    }

    if (gluteSpec != null) {
      decisions.add(
        DecisionTrace.info(
          phase: 'Phase1DataIngestion',
          category: 'glute_specialization_detected',
          description: 'Perfil de especialización de glúteo detectado',
          context: gluteSpec.toJson(),
        ),
      );
    }

    return DerivedTrainingContext(
      effectiveSleepHours: effectiveSleep,
      effectiveAdherence: effectiveAdherence,
      effectiveAvgRir: effectiveAvgRir,
      contraindicatedPatterns: contraindicatedPatterns,
      exerciseMustHave: exerciseMustHave,
      exerciseDislikes: exerciseDislikes,
      intensificationAllowed: intensification.allowed,
      intensificationMaxPerSession: intensification.maxPerSession,
      gluteSpecialization: gluteSpec,
      referenceDate: referenceDate,
    );
  }

  void _parseInjuries(dynamic injuries, Set<String> contraindicatedPatterns) {
    if (injuries is List) {
      for (final item in injuries) {
        if (item is Map) {
          final pattern = item['pattern']?.toString();
          final severity = _parseDouble(item['severity']);
          if (pattern != null && pattern.isNotEmpty && severity >= 3) {
            contraindicatedPatterns.add(pattern);
          }
        } else if (item != null) {
          final text = item.toString();
          if (text.isNotEmpty) {
            contraindicatedPatterns.add(text);
          }
        }
      }
    } else if (injuries is Map) {
      final severity = _parseDouble(injuries['severity']);
      final pattern = injuries['pattern']?.toString();
      if (pattern != null && pattern.isNotEmpty && severity >= 3) {
        contraindicatedPatterns.add(pattern);
      }
    } else if (injuries is String && injuries.isNotEmpty) {
      contraindicatedPatterns.add(injuries);
    }
  }

  _IntensificationPref _parsePreferences(
    dynamic preferences,
    Set<String> mustHave,
    Set<String> dislikes,
  ) {
    var allowed = true;
    var maxPerSession = 1;

    if (preferences is Map) {
      final mustRaw = preferences['mustHave'];
      final dislikeRaw = preferences['dislikes'];
      if (mustRaw is List) {
        mustHave.addAll(
          mustRaw.map((e) => e.toString()).where((e) => e.isNotEmpty),
        );
      }
      if (dislikeRaw is List) {
        dislikes.addAll(
          dislikeRaw.map((e) => e.toString()).where((e) => e.isNotEmpty),
        );
      }
      if (preferences['intensificationAllowed'] is bool) {
        allowed = preferences['intensificationAllowed'] as bool;
      }
      if (preferences['intensificationMaxPerSession'] is num) {
        maxPerSession = (preferences['intensificationMaxPerSession'] as num)
            .toInt();
      }
    } else if (preferences is String && preferences.isNotEmpty) {
      final lower = preferences.toLowerCase();
      if (lower.contains('sin intensificacion')) {
        allowed = false;
      }
      final mustIndex = lower.indexOf('must:');
      if (mustIndex != -1) {
        final part = preferences.substring(mustIndex + 5);
        mustHave.addAll(
          part.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty),
        );
      }
      final avoidIndex = lower.indexOf('avoid:');
      if (avoidIndex != -1) {
        final part = preferences.substring(avoidIndex + 6);
        dislikes.addAll(
          part.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty),
        );
      }
    }

    return _IntensificationPref(allowed: allowed, maxPerSession: maxPerSession);
  }

  GluteSpecializationContext? _parseGluteSpec(dynamic raw) {
    if (raw is! Map) return null;
    final freq = (raw['targetFrequencyPerWeek'] ?? raw['frequency']) as num?;
    final minSets = raw['minSetsPerWeek'] as num?;
    final maxSets = raw['maxSetsPerWeek'] as num?;
    if (freq == null && minSets == null && maxSets == null) return null;
    return GluteSpecializationContext(
      targetFrequencyPerWeek: freq?.toInt(),
      minSetsPerWeek: minSets?.toInt(),
      maxSetsPerWeek: maxSets?.toInt(),
    );
  }

  double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  void _validateRecoveryData(
    TrainingProfile profile,
    List<DecisionTrace> decisions,
    List<String> warnings,
    List<String> missingData,
  ) {
    // Validar sueño
    if (profile.avgSleepHours < 6.0) {
      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase1DataIngestion',
          category: 'recovery_concern',
          description: 'Sueño insuficiente (${profile.avgSleepHours}h < 6h)',
          action: 'Reducir volumen por mala recuperación',
        ),
      );
      warnings.add('Sueño insuficiente');
    }

    // Validar estrés
    if (profile.perceivedStress != null) {
      decisions.add(
        DecisionTrace.info(
          phase: 'Phase1DataIngestion',
          category: 'recovery_data',
          description: 'Estrés percibido: ${profile.perceivedStress}',
        ),
      );
    }

    // Validar dolor muscular
    if (profile.sorenessLevel != null && profile.sorenessLevel! > 7.0) {
      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase1DataIngestion',
          category: 'recovery_concern',
          description:
              'Nivel de dolor muscular alto (${profile.sorenessLevel}/10)',
          action: 'Considerar fase de deload o reducción de volumen',
        ),
      );
      warnings.add('DOMS alto');
    }

    // Validar motivación
    if (profile.motivationLevel != null && profile.motivationLevel! < 5.0) {
      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase1DataIngestion',
          category: 'psychological_concern',
          description: 'Motivación baja (${profile.motivationLevel}/10)',
          action: 'Considerar plan más variado o reducir frecuencia',
        ),
      );
      warnings.add('Motivación baja');
    }
  }

  void _validateBaseVolume(
    TrainingProfile profile,
    List<DecisionTrace> decisions,
    List<String> warnings,
  ) {
    if (profile.baseVolumePerMuscle.isEmpty) {
      decisions.add(
        DecisionTrace.warning(
          phase: 'Phase1DataIngestion',
          category: 'volume_config',
          description: 'No se especificó volumen base por músculo',
          action: 'Se calcularán valores basados en nivel y objetivo',
        ),
      );
      warnings.add('Sin volumen base configurado');
    } else {
      final totalWeeklyVolume = profile.baseVolumePerMuscle.values.fold<int>(
        0,
        (sum, vol) => sum + vol,
      );

      decisions.add(
        DecisionTrace.info(
          phase: 'Phase1DataIngestion',
          category: 'volume_config',
          description: 'Volumen base total: $totalWeeklyVolume series/semana',
          context: {
            'volumePerMuscle': profile.baseVolumePerMuscle,
            'totalVolume': totalWeeklyVolume,
          },
        ),
      );

      // Verificar si el volumen parece excesivo para el tiempo disponible
      final minutesPerWeek =
          profile.daysPerWeek * profile.timePerSessionMinutes;
      final estimatedMinutesNeeded = totalWeeklyVolume * 4; // ~4 min por serie

      if (estimatedMinutesNeeded > minutesPerWeek * 1.2) {
        decisions.add(
          DecisionTrace.warning(
            phase: 'Phase1DataIngestion',
            category: 'time_constraint',
            description:
                'Volumen base requiere más tiempo del disponible '
                '(~$estimatedMinutesNeeded min vs $minutesPerWeek min)',
            action: 'Se ajustará volumen al tiempo disponible',
          ),
        );
        warnings.add('Volumen excede tiempo disponible');
      }
    }
  }
}

/// Contexto derivado NO persistente, construido en Fase 1 y pasado a fases 2-8.
class DerivedTrainingContext {
  final double effectiveSleepHours;
  final double? effectiveAdherence;
  final double? effectiveAvgRir;
  final Set<String> contraindicatedPatterns;
  final Set<String> exerciseMustHave;
  final Set<String> exerciseDislikes;
  final bool intensificationAllowed;
  final int intensificationMaxPerSession;
  final GluteSpecializationContext? gluteSpecialization;

  /// Fecha de referencia para determinismo temporal.
  /// NO debe usar DateTime.now(), sino derivarse del inicio del plan o semana actual.
  final DateTime referenceDate;

  const DerivedTrainingContext({
    required this.effectiveSleepHours,
    required this.effectiveAdherence,
    required this.effectiveAvgRir,
    required this.contraindicatedPatterns,
    required this.exerciseMustHave,
    required this.exerciseDislikes,
    required this.intensificationAllowed,
    required this.intensificationMaxPerSession,
    required this.gluteSpecialization,
    required this.referenceDate,
  });
}

/// Perfil de especialización de glúteo (opcional).
class GluteSpecializationContext {
  final int? targetFrequencyPerWeek;
  final int? minSetsPerWeek;
  final int? maxSetsPerWeek;

  const GluteSpecializationContext({
    this.targetFrequencyPerWeek,
    this.minSetsPerWeek,
    this.maxSetsPerWeek,
  });

  Map<String, dynamic> toJson() => {
    'targetFrequencyPerWeek': targetFrequencyPerWeek,
    'minSetsPerWeek': minSetsPerWeek,
    'maxSetsPerWeek': maxSetsPerWeek,
  };
}

/// Helper interno para parseo de preferencias de intensificación.
class _IntensificationPref {
  final bool allowed;
  final int maxPerSession;

  const _IntensificationPref({
    required this.allowed,
    required this.maxPerSession,
  });
}
