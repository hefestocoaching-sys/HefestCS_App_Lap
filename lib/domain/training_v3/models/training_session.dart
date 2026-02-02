// lib/domain/training_v3/models/training_session.dart

import 'package:equatable/equatable.dart';
import 'package:hcs_app_lap/domain/training_v3/models/exercise_prescription.dart';

/// Sesión individual de entrenamiento
///
/// Representa un día de entrenamiento con:
/// - Ejercicios prescritos (orden, series, reps, RIR)
/// - Grupos musculares trabajados
/// - Duración estimada
/// - Orden de ejecución
///
/// FUNDAMENTO CIENTÍFICO:
/// - Semana 5, Imagen 60-63: Ordenamiento de ejercicios
///   (compounds primero, aislamiento después)
/// - Semana 6: Distribución de volumen por sesión
///
/// Versión: 1.0.0
class TrainingSession extends Equatable {
  // ════════════════════════════════════════════════════════════
  // IDENTIFICACIÓN
  // ════════════════════════════════════════════════════════════

  /// ID único de la sesión
  final String id;

  /// Número del día en la semana (1-7)
  /// 1 = Lunes, 2 = Martes, ..., 7 = Domingo
  final int dayNumber;

  /// Nombre descriptivo de la sesión
  /// Ejemplos: "Push Day", "Leg Day", "Upper Body", "Full Body A"
  final String name;

  // ════════════════════════════════════════════════════════════
  // CONFIGURACIÓN
  // ════════════════════════════════════════════════════════════

  /// Grupos musculares principales trabajados en esta sesión
  /// Ejemplo: ['chest', 'shoulders', 'triceps'] para Push Day
  final List<String> primaryMuscles;

  /// Duración estimada en minutos (calculada automáticamente)
  /// Fórmula: (número de ejercicios × 10 min) + descanso entre ejercicios
  final int estimatedDurationMinutes;

  // ════════════════════════════════════════════════════════════
  // EJERCICIOS
  // ════════════════════════════════════════════════════════════

  /// Lista de ejercicios prescritos en orden de ejecución
  /// Semana 5, Imagen 60-63: Ordenamiento científico
  /// 1. Compounds grandes (squat, deadlift, bench)
  /// 2. Compounds auxiliares (rows, overhead press)
  /// 3. Aislamiento primario (curls, extensions)
  /// 4. Aislamiento secundario (calves, abs)
  final List<ExercisePrescription> exercises;

  // ════════════════════════════════════════════════════════════
  // METADATA
  // ════════════════════════════════════════════════════════════

  /// Notas adicionales para esta sesión
  final String? notes;

  const TrainingSession({
    required this.id,
    required this.dayNumber,
    required this.name,
    required this.primaryMuscles,
    required this.estimatedDurationMinutes,
    required this.exercises,
    this.notes,
  });

  /// Validar que la sesión sea coherente
  bool get isValid {
    // Validar día de la semana
    if (dayNumber < 1 || dayNumber > 7) return false;

    // Validar que tenga al menos 1 ejercicio
    if (exercises.isEmpty) return false;

    // Validar que tenga al menos 1 músculo primario
    if (primaryMuscles.isEmpty) return false;

    // Validar duración razonable
    if (estimatedDurationMinutes < 20 || estimatedDurationMinutes > 180) {
      return false;
    }

    return true;
  }

  /// Calcular volumen total de la sesión (suma de todas las series)
  int get totalSets {
    return exercises.fold(0, (sum, ex) => sum + ex.sets);
  }

  /// Obtener nombre del día de la semana
  String get dayName {
    const days = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    return days[dayNumber - 1];
  }

  /// Serialización a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dayNumber': dayNumber,
      'name': name,
      'primaryMuscles': primaryMuscles,
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'notes': notes,
    };
  }

  /// Deserialización desde JSON
  factory TrainingSession.fromJson(Map<String, dynamic> json) {
    return TrainingSession(
      id: json['id'] as String,
      dayNumber: json['dayNumber'] as int,
      name: json['name'] as String,
      primaryMuscles: List<String>.from(json['primaryMuscles'] as List),
      estimatedDurationMinutes: json['estimatedDurationMinutes'] as int,
      exercises: (json['exercises'] as List)
          .map((e) => ExercisePrescription.fromJson(e as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] as String?,
    );
  }

  /// CopyWith para actualizaciones inmutables
  TrainingSession copyWith({
    String? id,
    int? dayNumber,
    String? name,
    List<String>? primaryMuscles,
    int? estimatedDurationMinutes,
    List<ExercisePrescription>? exercises,
    String? notes,
  }) {
    return TrainingSession(
      id: id ?? this.id,
      dayNumber: dayNumber ?? this.dayNumber,
      name: name ?? this.name,
      primaryMuscles: primaryMuscles ?? this.primaryMuscles,
      estimatedDurationMinutes:
          estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      exercises: exercises ?? this.exercises,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
    id,
    dayNumber,
    name,
    primaryMuscles,
    estimatedDurationMinutes,
    exercises,
    notes,
  ];

  @override
  String toString() {
    return 'TrainingSession(day: $dayNumber, name: $name, exercises: ${exercises.length}, '
        'duration: ${estimatedDurationMinutes}min)';
  }
}
