// lib/domain/training_v3/models/training_program_v3_result.dart

import 'package:hcs_app_lap/domain/entities/training_plan_config.dart';

/// Resultado de la generación del Motor V3
///
/// Encapsula el resultado de generar un plan de entrenamiento,
/// incluyendo información sobre bloqueos, advertencias y metadata.
///
/// CASOS DE USO:
/// - Plan generado exitosamente → isBlocked = false, plan != null
/// - Plan bloqueado (fatiga alta) → isBlocked = true, blockReason != null
/// - Error técnico → isBlocked = true, blockReason con mensaje de error
class TrainingProgramV3Result {
  /// Indica si la generación fue bloqueada
  final bool isBlocked;

  /// Razón del bloqueo (si isBlocked == true)
  /// Ejemplos:
  /// - "Fatiga acumulada muy alta (PRS: 3/10). Se requiere deload."
  /// - "Datos insuficientes para generar plan personalizado."
  /// - "Error técnico: No se encontraron ejercicios disponibles."
  final String? blockReason;

  /// Sugerencias para resolver el bloqueo
  /// Ejemplos:
  /// - ["Mejorar calidad del sueño (7-9h)", "Reducir estrés"]
  /// - ["Completar datos de perfil: edad, nivel de experiencia"]
  final List<String>? suggestions;

  /// Plan de entrenamiento generado (si no está bloqueado)
  final TrainingPlanConfig? plan;

  /// Trazabilidad de decisiones (para debugging y explicabilidad)
  /// Contiene:
  /// - Decisiones de volumen por músculo
  /// - Decisiones de intensidad
  /// - Selección de ejercicios
  /// - Rationale del split elegido
  /// - Rationale de la fase de periodización
  final DecisionTrace? trace;

  /// Metadata adicional del proceso de generación
  /// Puede incluir:
  /// - Timestamp de generación
  /// - Versión del motor
  /// - Estrategia utilizada (RuleBased, Hybrid, ML)
  /// - Confianza en las decisiones
  final Map<String, dynamic>? metadata;

  const TrainingProgramV3Result({
    required this.isBlocked,
    this.blockReason,
    this.suggestions,
    this.plan,
    this.trace,
    this.metadata,
  });

  /// Factory para crear resultado bloqueado
  ///
  /// PARÁMETROS:
  /// - [reason]: Razón del bloqueo (obligatorio)
  /// - [suggestions]: Lista de sugerencias para resolver el bloqueo
  factory TrainingProgramV3Result.blocked({
    required String reason,
    List<String>? suggestions,
  }) {
    return TrainingProgramV3Result(
      isBlocked: true,
      blockReason: reason,
      suggestions: suggestions,
    );
  }

  /// Factory para crear resultado exitoso
  ///
  /// PARÁMETROS:
  /// - [plan]: Plan de entrenamiento generado (obligatorio)
  /// - [trace]: Trazabilidad de decisiones (opcional, para debugging)
  /// - [metadata]: Metadata adicional (opcional)
  factory TrainingProgramV3Result.success({
    required TrainingPlanConfig plan,
    DecisionTrace? trace,
    Map<String, dynamic>? metadata,
  }) {
    return TrainingProgramV3Result(
      isBlocked: false,
      plan: plan,
      trace: trace,
      metadata: metadata,
    );
  }

  /// Convierte el resultado a un Map (para serialización)
  Map<String, dynamic> toJson() {
    return {
      'isBlocked': isBlocked,
      'blockReason': blockReason,
      'suggestions': suggestions,
      'plan': plan?.toJson(),
      'trace': trace?.toJson(),
      'metadata': metadata,
    };
  }

  @override
  String toString() {
    if (isBlocked) {
      return 'TrainingProgramV3Result.blocked(reason: $blockReason, '
          'suggestions: $suggestions)';
    }
    return 'TrainingProgramV3Result.success(plan: ${plan?.id}, '
        'weeks: ${plan?.weeks.length})';
  }
}

/// Trazabilidad de decisiones del Motor V3
///
/// Proporciona transparencia sobre cómo se tomaron las decisiones
/// del plan de entrenamiento, facilitando debugging y explicabilidad.
///
/// CAMPOS:
/// - volumeDecisions: Decisiones de volumen por músculo (MEV/MAV/MRV)
/// - intensityDecisions: Distribución de intensidad (Heavy/Moderate/Light)
/// - exerciseSelections: Ejercicios seleccionados con scores
/// - splitRationale: Por qué se eligió el split (FullBody/Upper-Lower/PPL)
/// - phaseRationale: Por qué se eligió la fase (Accumulation/Intensification/Deload)
class DecisionTrace {
  /// Decisiones de volumen por músculo
  /// Estructura:
  /// {
  ///   'pectorals': {
  ///     'mev': 8,
  ///     'mav': 14,
  ///     'mrv': 22,
  ///     'target': 14,
  ///     'adjustmentFactors': {
  ///       'age': 0.95,
  ///       'recovery': 1.0,
  ///       'caloric': 0.85
  ///     }
  ///   },
  ///   ...
  /// }
  final Map<String, dynamic> volumeDecisions;

  /// Decisiones de intensidad
  /// Estructura:
  /// {
  ///   'distribution': {
  ///     'heavy': 0.35,
  ///     'moderate': 0.50,
  ///     'light': 0.15
  ///   },
  ///   'goal': 'hypertrophy',
  ///   'rationale': 'Distribución óptima para hipertrofia según Schoenfeld 2017'
  /// }
  final Map<String, dynamic> intensityDecisions;

  /// Selección de ejercicios
  /// Estructura:
  /// {
  ///   'pectorals': [
  ///     {
  ///       'name': 'Bench Press',
  ///       'score': 4.7,
  ///       'category': 'compound',
  ///       'rationale': 'Excelente curva de resistencia y ROM'
  ///     },
  ///     ...
  ///   ],
  ///   ...
  /// }
  final Map<String, dynamic> exerciseSelections;

  /// Rationale del split elegido
  /// Ejemplo: "Upper/Lower 4x seleccionado: 4 días disponibles, nivel intermedio, "
  ///          "permite frecuencia 2x por músculo (óptimo para hipertrofia)"
  final String splitRationale;

  /// Rationale de la fase de periodización
  /// Ejemplo: "Semana 2/4 → Fase de Acumulación: incrementar volumen +2 sets, "
  ///          "mantener RIR 2-3"
  final String phaseRationale;

  const DecisionTrace({
    required this.volumeDecisions,
    required this.intensityDecisions,
    required this.exerciseSelections,
    required this.splitRationale,
    required this.phaseRationale,
  });

  /// Convierte el trace a un Map (para serialización)
  Map<String, dynamic> toJson() {
    return {
      'volumeDecisions': volumeDecisions,
      'intensityDecisions': intensityDecisions,
      'exerciseSelections': exerciseSelections,
      'splitRationale': splitRationale,
      'phaseRationale': phaseRationale,
    };
  }

  @override
  String toString() {
    return 'DecisionTrace(\n'
        '  splitRationale: $splitRationale\n'
        '  phaseRationale: $phaseRationale\n'
        '  muscles: ${volumeDecisions.keys.join(", ")}\n'
        ')';
  }
}
