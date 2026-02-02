// lib/domain/training_v3/models/workout_log.dart

import 'package:equatable/equatable.dart';
import 'package:hcs_app_lap/domain/training_v3/models/exercise_log.dart';

/// Log completo de una sesión de entrenamiento realizada
///
/// Representa lo que REALMENTE pasó en el gimnasio (vs lo que estaba prescrito).
/// Este modelo es CRÍTICO para el sistema reactivo, ya que permite:
/// - Comparar plan vs realidad
/// - Detectar fatiga acumulada
/// - Ajustar cargas en sesiones futuras
/// - Trigger de deload cuando sea necesario
///
/// FUNDAMENTO CIENTÍFICO:
/// - Semana 7, Imagen 96-105: Sistema reactivo (comparación plan vs realidad)
/// - Autoregulación: Si RPE real > RPE planeado → reducir carga
/// - Si adherencia < 80% → investigar causas (fatiga, vida, técnica)
///
/// Versión: 1.0.0
class WorkoutLog extends Equatable {
  // ════════════════════════════════════════════════════════════
  // IDENTIFICACIÓN
  // ════════════════════════════════════════════════════════════

  /// ID único del log
  final String id;

  /// ID del usuario
  final String userId;

  /// ID del programa al que pertenece
  final String programId;

  /// ID de la sesión planeada (referencia a TrainingSession)
  final String plannedSessionId;

  /// Fecha y hora de inicio del entrenamiento
  final DateTime startTime;

  /// Fecha y hora de finalización
  final DateTime endTime;

  // ════════════════════════════════════════════════════════════
  // EJERCICIOS REALIZADOS
  // ════════════════════════════════════════════════════════════

  /// Logs de ejercicios realizados (orden de ejecución)
  final List<ExerciseLog> exerciseLogs;

  // ════════════════════════════════════════════════════════════
  // MÉTRICAS SUBJETIVAS (POST-ENTRENAMIENTO)
  // ════════════════════════════════════════════════════════════

  /// RPE de la sesión completa (1-10)
  /// 1-3 = fácil, 4-6 = moderado, 7-8 = duro, 9-10 = extremo
  final double sessionRpe;

  /// Percepción de recuperación ANTES de la sesión (1-10)
  /// 1-3 = muy fatigado, 4-6 = moderado, 7-10 = bien recuperado
  /// Semana 7: Si PRS < 5 → considerar reducir volumen
  final double perceivedRecoveryStatus;

  /// Nivel de dolor muscular (DOMS) ANTES de la sesión (0-10)
  /// 0 = sin dolor, 3-5 = moderado, 6-8 = alto, 9-10 = debilitante
  final double muscleSoreness;

  // ════════════════════════════════════════════════════════════
  // COMPARACIÓN PLAN VS REALIDAD
  // ════════════════════════════════════════════════════════════

  /// Adherencia al plan (porcentaje de sets completados)
  /// Calculado automáticamente: (sets completados / sets planeados)
  /// Semana 7: Si adherencia < 80% por 2 semanas → deload
  final double adherencePercentage;

  /// ¿Se completó la sesión como estaba planeada?
  final bool completed;

  /// Razón de no completar (si completed = false)
  /// Ejemplos: "fatiga excesiva", "falta de tiempo", "dolor", "técnica mala"
  final String? incompletionReason;

  // ════════════════════════════════════════════════════════════
  // METADATA
  // ════════════════════════════════════════════════════════════

  /// Notas adicionales del atleta
  final String? notes;

  /// Timestamp de creación del log
  final DateTime createdAt;

  const WorkoutLog({
    required this.id,
    required this.userId,
    required this.programId,
    required this.plannedSessionId,
    required this.startTime,
    required this.endTime,
    required this.exerciseLogs,
    required this.sessionRpe,
    required this.perceivedRecoveryStatus,
    required this.muscleSoreness,
    required this.adherencePercentage,
    required this.completed,
    this.incompletionReason,
    this.notes,
    required this.createdAt,
  });

  /// Validar que el log sea coherente
  bool get isValid {
    // Validar que endTime > startTime
    if (endTime.isBefore(startTime)) return false;

    // Validar RPE razonable
    if (sessionRpe < 1 || sessionRpe > 10) return false;

    // Validar PRS razonable
    if (perceivedRecoveryStatus < 1 || perceivedRecoveryStatus > 10)
      return false;

    // Validar DOMS razonable
    if (muscleSoreness < 0 || muscleSoreness > 10) return false;

    // Validar adherencia 0-100%
    if (adherencePercentage < 0 || adherencePercentage > 100) return false;

    // Si no completado, debe haber razón
    if (!completed &&
        (incompletionReason == null || incompletionReason!.isEmpty)) {
      return false;
    }

    // Validar que tenga al menos 1 ejercicio
    if (exerciseLogs.isEmpty) return false;

    return true;
  }

  /// Duración de la sesión en minutos
  int get durationMinutes {
    return endTime.difference(startTime).inMinutes;
  }

  /// Calcular número total de sets realizados
  int get totalSets {
    return exerciseLogs.fold(0, (sum, log) => sum + log.sets.length);
  }

  /// Calcular número total de sets planeados (para comparación)
  int get totalPlannedSets {
    return exerciseLogs.fold(0, (sum, log) => sum + log.plannedSets);
  }

  /// Verificar si hay señales de fatiga alta
  /// Semana 7: Trigger de deload si fatiga alta persistente
  bool get showsFatigueSignals {
    // RPE muy alto (>8.5) + PRS bajo (<5) + DOMS alto (>6)
    if (sessionRpe > 8.5 && perceivedRecoveryStatus < 5 && muscleSoreness > 6) {
      return true;
    }

    // Adherencia baja (<70%) + PRS bajo
    if (adherencePercentage < 70 && perceivedRecoveryStatus < 5) {
      return true;
    }

    return false;
  }

  /// Serialización a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'programId': programId,
      'plannedSessionId': plannedSessionId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'exerciseLogs': exerciseLogs.map((e) => e.toJson()).toList(),
      'sessionRpe': sessionRpe,
      'perceivedRecoveryStatus': perceivedRecoveryStatus,
      'muscleSoreness': muscleSoreness,
      'adherencePercentage': adherencePercentage,
      'completed': completed,
      'incompletionReason': incompletionReason,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Deserialización desde JSON
  factory WorkoutLog.fromJson(Map<String, dynamic> json) {
    return WorkoutLog(
      id: json['id'] as String,
      userId: json['userId'] as String,
      programId: json['programId'] as String,
      plannedSessionId: json['plannedSessionId'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      exerciseLogs: (json['exerciseLogs'] as List)
          .map((e) => ExerciseLog.fromJson(e as Map<String, dynamic>))
          .toList(),
      sessionRpe: (json['sessionRpe'] as num).toDouble(),
      perceivedRecoveryStatus: (json['perceivedRecoveryStatus'] as num)
          .toDouble(),
      muscleSoreness: (json['muscleSoreness'] as num).toDouble(),
      adherencePercentage: (json['adherencePercentage'] as num).toDouble(),
      completed: json['completed'] as bool,
      incompletionReason: json['incompletionReason'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// CopyWith para actualizaciones inmutables
  WorkoutLog copyWith({
    String? id,
    String? userId,
    String? programId,
    String? plannedSessionId,
    DateTime? startTime,
    DateTime? endTime,
    List<ExerciseLog>? exerciseLogs,
    double? sessionRpe,
    double? perceivedRecoveryStatus,
    double? muscleSoreness,
    double? adherencePercentage,
    bool? completed,
    String? incompletionReason,
    String? notes,
    DateTime? createdAt,
  }) {
    return WorkoutLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      programId: programId ?? this.programId,
      plannedSessionId: plannedSessionId ?? this.plannedSessionId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      exerciseLogs: exerciseLogs ?? this.exerciseLogs,
      sessionRpe: sessionRpe ?? this.sessionRpe,
      perceivedRecoveryStatus:
          perceivedRecoveryStatus ?? this.perceivedRecoveryStatus,
      muscleSoreness: muscleSoreness ?? this.muscleSoreness,
      adherencePercentage: adherencePercentage ?? this.adherencePercentage,
      completed: completed ?? this.completed,
      incompletionReason: incompletionReason ?? this.incompletionReason,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    programId,
    plannedSessionId,
    startTime,
    endTime,
    exerciseLogs,
    sessionRpe,
    perceivedRecoveryStatus,
    muscleSoreness,
    adherencePercentage,
    completed,
    incompletionReason,
    notes,
    createdAt,
  ];

  @override
  String toString() {
    return 'WorkoutLog(id: $id, duration: ${durationMinutes}min, '
        'adherence: ${adherencePercentage.toStringAsFixed(1)}%, '
        'RPE: $sessionRpe, PRS: $perceivedRecoveryStatus)';
  }
}
