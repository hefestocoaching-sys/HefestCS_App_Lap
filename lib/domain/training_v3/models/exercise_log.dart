// lib/domain/training_v3/models/exercise_log.dart

import 'package:equatable/equatable.dart';
import 'package:hcs_app_lap/domain/training_v3/models/set_log.dart';

/// Log de un ejercicio individual dentro de una sesión
///
/// Representa lo que REALMENTE se hizo en un ejercicio específico.
/// Permite comparar:
/// - Sets planeados vs sets reales
/// - Carga progresión (¿aumentó peso vs última vez?)
/// - RPE real vs esperado
///
/// FUNDAMENTO CIENTÍFICO:
/// - Semana 7, Imagen 96-105: Sistema reactivo
/// - Progresión de carga: Si RPE < target → aumentar peso próxima vez
/// - Si RPE > target → mantener peso o reducir
///
/// Versión: 1.0.0
class ExerciseLog extends Equatable {
  // ════════════════════════════════════════════════════════════
  // IDENTIFICACIÓN
  // ════════════════════════════════════════════════════════════

  /// ID único del log de ejercicio
  final String id;

  /// ID del ejercicio (referencia a exercise_catalog_gym.json)
  final String exerciseId;

  /// Nombre del ejercicio (denormalizado)
  final String exerciseName;

  /// ID de la prescripción planeada (referencia a ExercisePrescription)
  final String plannedPrescriptionId;

  // ════════════════════════════════════════════════════════════
  // PLAN VS REALIDAD
  // ════════════════════════════════════════════════════════════

  /// Número de sets planeados
  final int plannedSets;

  /// Sets realmente ejecutados (lista de SetLog)
  final List<SetLog> sets;

  /// RIR planeado
  final int plannedRir;

  /// RPE promedio de todas las series
  /// Calculado automáticamente del promedio de sets[].rpe
  final double averageRpe;

  // ════════════════════════════════════════════════════════════
  // FEEDBACK
  // ════════════════════════════════════════════════════════════

  /// ¿Se completaron todos los sets planeados?
  final bool completed;

  /// Razón de no completar (si completed = false)
  /// Ejemplos: "fatiga", "técnica mala", "dolor", "tiempo"
  final String? incompletionReason;

  /// Notas del atleta sobre este ejercicio
  final String? notes;

  const ExerciseLog({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.plannedPrescriptionId,
    required this.plannedSets,
    required this.sets,
    required this.plannedRir,
    required this.averageRpe,
    required this.completed,
    this.incompletionReason,
    this.notes,
  });

  /// Validar que el log sea coherente
  bool get isValid {
    // Validar que tenga al menos 1 set
    if (sets.isEmpty) return false;

    // Validar plannedSets razonable
    if (plannedSets < 1 || plannedSets > 10) return false;

    // Validar plannedRir razonable
    if (plannedRir < 0 || plannedRir > 5) return false;

    // Validar averageRpe razonable
    if (averageRpe < 1 || averageRpe > 10) return false;

    // Si no completado, debe haber razón
    if (!completed &&
        (incompletionReason == null || incompletionReason!.isEmpty)) {
      return false;
    }

    return true;
  }

  /// Verificar si hubo progresión de carga vs sesión anterior
  /// (requiere comparación externa, aquí solo indicamos si aumentó peso)
  bool didProgressLoad(ExerciseLog? previousLog) {
    if (previousLog == null) return false;

    // Comparar peso promedio de sets
    final currentAvgWeight =
        sets.fold(0.0, (sum, s) => sum + s.weight) / sets.length;
    final previousAvgWeight =
        previousLog.sets.fold(0.0, (sum, s) => sum + s.weight) /
        previousLog.sets.length;

    return currentAvgWeight > previousAvgWeight;
  }

  /// Calcular volumen total del ejercicio (sets × reps × peso)
  double get totalVolume {
    return sets.fold(0.0, (sum, s) => sum + (s.reps * s.weight));
  }

  /// Serialización a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'plannedPrescriptionId': plannedPrescriptionId,
      'plannedSets': plannedSets,
      'sets': sets.map((s) => s.toJson()).toList(),
      'plannedRir': plannedRir,
      'averageRpe': averageRpe,
      'completed': completed,
      'incompletionReason': incompletionReason,
      'notes': notes,
    };
  }

  /// Deserialización desde JSON
  factory ExerciseLog.fromJson(Map<String, dynamic> json) {
    return ExerciseLog(
      id: json['id'] as String,
      exerciseId: json['exerciseId'] as String,
      exerciseName: json['exerciseName'] as String,
      plannedPrescriptionId: json['plannedPrescriptionId'] as String,
      plannedSets: json['plannedSets'] as int,
      sets: (json['sets'] as List)
          .map((s) => SetLog.fromJson(s as Map<String, dynamic>))
          .toList(),
      plannedRir: json['plannedRir'] as int,
      averageRpe: (json['averageRpe'] as num).toDouble(),
      completed: json['completed'] as bool,
      incompletionReason: json['incompletionReason'] as String?,
      notes: json['notes'] as String?,
    );
  }

  /// CopyWith para actualizaciones inmutables
  ExerciseLog copyWith({
    String? id,
    String? exerciseId,
    String? exerciseName,
    String? plannedPrescriptionId,
    int? plannedSets,
    List<SetLog>? sets,
    int? plannedRir,
    double? averageRpe,
    bool? completed,
    String? incompletionReason,
    String? notes,
  }) {
    return ExerciseLog(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      plannedPrescriptionId:
          plannedPrescriptionId ?? this.plannedPrescriptionId,
      plannedSets: plannedSets ?? this.plannedSets,
      sets: sets ?? this.sets,
      plannedRir: plannedRir ?? this.plannedRir,
      averageRpe: averageRpe ?? this.averageRpe,
      completed: completed ?? this.completed,
      incompletionReason: incompletionReason ?? this.incompletionReason,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
    id,
    exerciseId,
    exerciseName,
    plannedPrescriptionId,
    plannedSets,
    sets,
    plannedRir,
    averageRpe,
    completed,
    incompletionReason,
    notes,
  ];

  @override
  String toString() {
    return 'ExerciseLog($exerciseName: ${sets.length}/$plannedSets sets, avgRPE: ${averageRpe.toStringAsFixed(1)})';
  }
}
