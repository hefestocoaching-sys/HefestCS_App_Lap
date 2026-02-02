// lib/domain/training_v3/models/exercise_prescription.dart

import 'package:equatable/equatable.dart';

/// Prescripción de un ejercicio dentro de una sesión
///
/// Define todos los parámetros de ejecución para un ejercicio específico:
/// - Series, repeticiones, RIR (esfuerzo)
/// - Intensidad (heavy/moderate/light)
/// - Descanso entre series
/// - Técnicas de intensificación opcionales
///
/// FUNDAMENTO CIENTÍFICO:
/// - Semana 3, Imagen 26-35: Distribución de intensidad (35% heavy, 45% moderate, 20% light)
/// - Semana 4, Imagen 36-43: RIR (Reps in Reserve) óptimo por intensidad
///   * Heavy (5-8 reps): RIR 3-4
///   * Moderate (8-12 reps): RIR 2-3
///   * Light (12-20 reps): RIR 0-1
/// - Semana Suplementaria: Técnicas avanzadas (drop sets, rest-pause, etc.)
///
/// Versión: 1.0.0
class ExercisePrescription extends Equatable {
  // ════════════════════════════════════════════════════════════
  // IDENTIFICACIÓN
  // ════════════════════════════════════════════════════════════

  /// ID del ejercicio (referencia a exercise_catalog_gym.json)
  final String exerciseId;

  /// Nombre del ejercicio (denormalizado para facilidad de lectura)
  final String exerciseName;

  /// Orden de ejecución en la sesión (1-based)
  /// Semana 5, Imagen 60-63: Compounds primero, aislamiento después
  final int orderInSession;

  // ════════════════════════════════════════════════════════════
  // PRESCRIPCIÓN BÁSICA
  // ════════════════════════════════════════════════════════════

  /// Número de series a realizar (1-8)
  final int sets;

  /// Rango de repeticiones objetivo
  /// Ejemplo: [8, 12] = "8-12 reps"
  final List<int> repRange;

  /// RIR (Reps in Reserve) objetivo
  /// 0 = fallo muscular
  /// 1 = 1 rep en reserva
  /// 2 = 2 reps en reserva
  /// 3-4 = conservador (heavy compounds)
  /// Semana 4, Imagen 36-43
  final int targetRir;

  /// Zona de intensidad
  /// - 'heavy': 5-8 reps, RIR 3-4, carga >85% 1RM
  /// - 'moderate': 8-12 reps, RIR 2-3, carga 70-85% 1RM
  /// - 'light': 12-20 reps, RIR 0-1, carga 60-70% 1RM
  /// Semana 3, Imagen 26-35
  final String intensityZone;

  // ════════════════════════════════════════════════════════════
  // PARÁMETROS OPCIONALES
  // ════════════════════════════════════════════════════════════

  /// Descanso entre series en segundos (60-300)
  /// - Heavy: 180-300s (3-5 min)
  /// - Moderate: 90-180s (1.5-3 min)
  /// - Light: 60-90s (1-1.5 min)
  final int restSeconds;

  /// Tempo de ejecución (eccentric-pause-concentric-pause)
  /// Ejemplo: "3010" = 3s eccentric, 0s pause, 1s concentric, 0s pause
  /// null = tempo libre
  final String? tempo;

  /// Técnica de intensificación aplicada (opcional)
  /// Valores: 'drop_set', 'rest_pause', 'cluster', 'myo_reps', null
  /// Semana Suplementaria
  final String? intensificationTechnique;

  // ════════════════════════════════════════════════════════════
  // METADATA
  // ════════════════════════════════════════════════════════════

  /// Notas adicionales del coach
  final String? notes;

  const ExercisePrescription({
    required this.exerciseId,
    required this.exerciseName,
    required this.orderInSession,
    required this.sets,
    required this.repRange,
    required this.targetRir,
    required this.intensityZone,
    required this.restSeconds,
    this.tempo,
    this.intensificationTechnique,
    this.notes,
  });

  /// Validar que la prescripción sea coherente
  bool get isValid {
    // Validar sets razonable
    if (sets < 1 || sets > 8) return false;

    // Validar repRange tiene 2 elementos [min, max]
    if (repRange.length != 2) return false;
    if (repRange[0] >= repRange[1]) return false;
    if (repRange[0] < 1 || repRange[1] > 50) return false;

    // Validar RIR razonable
    if (targetRir < 0 || targetRir > 5) return false;

    // Validar intensityZone válida
    if (!['heavy', 'moderate', 'light'].contains(intensityZone)) return false;

    // Validar descanso razonable
    if (restSeconds < 30 || restSeconds > 600) return false;

    // Validar coherencia intensidad-reps-RIR
    if (intensityZone == 'heavy') {
      // Heavy: 5-8 reps, RIR 3-4
      if (repRange[1] > 8 || targetRir < 2) return false;
    } else if (intensityZone == 'moderate') {
      // Moderate: 8-12 reps, RIR 2-3
      if (repRange[0] < 6 || repRange[1] > 15) return false;
    } else if (intensityZone == 'light') {
      // Light: 12-20 reps, RIR 0-2
      if (repRange[0] < 10 || targetRir > 2) return false;
    }

    return true;
  }

  /// Obtener descripción legible de reps
  /// Ejemplo: "8-12 reps"
  String get repsDescription {
    if (repRange[0] == repRange[1]) {
      return '${repRange[0]} reps';
    }
    return '${repRange[0]}-${repRange[1]} reps';
  }

  /// Obtener descripción legible de descanso
  /// Ejemplo: "2:00" (2 minutos)
  String get restDescription {
    final minutes = restSeconds ~/ 60;
    final seconds = restSeconds % 60;
    if (minutes == 0) {
      return '${seconds}s';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Calcular volumen total del ejercicio (sets × reps promedio)
  double get estimatedVolume {
    final avgReps = (repRange[0] + repRange[1]) / 2;
    return sets * avgReps;
  }

  /// Serialización a JSON
  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'orderInSession': orderInSession,
      'sets': sets,
      'repRange': repRange,
      'targetRir': targetRir,
      'intensityZone': intensityZone,
      'restSeconds': restSeconds,
      'tempo': tempo,
      'intensificationTechnique': intensificationTechnique,
      'notes': notes,
    };
  }

  /// Deserialización desde JSON
  factory ExercisePrescription.fromJson(Map<String, dynamic> json) {
    return ExercisePrescription(
      exerciseId: json['exerciseId'] as String,
      exerciseName: json['exerciseName'] as String,
      orderInSession: json['orderInSession'] as int,
      sets: json['sets'] as int,
      repRange: List<int>.from(json['repRange'] as List),
      targetRir: json['targetRir'] as int,
      intensityZone: json['intensityZone'] as String,
      restSeconds: json['restSeconds'] as int,
      tempo: json['tempo'] as String?,
      intensificationTechnique: json['intensificationTechnique'] as String?,
      notes: json['notes'] as String?,
    );
  }

  /// CopyWith para actualizaciones inmutables
  ExercisePrescription copyWith({
    String? exerciseId,
    String? exerciseName,
    int? orderInSession,
    int? sets,
    List<int>? repRange,
    int? targetRir,
    String? intensityZone,
    int? restSeconds,
    String? tempo,
    String? intensificationTechnique,
    String? notes,
  }) {
    return ExercisePrescription(
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      orderInSession: orderInSession ?? this.orderInSession,
      sets: sets ?? this.sets,
      repRange: repRange ?? this.repRange,
      targetRir: targetRir ?? this.targetRir,
      intensityZone: intensityZone ?? this.intensityZone,
      restSeconds: restSeconds ?? this.restSeconds,
      tempo: tempo ?? this.tempo,
      intensificationTechnique:
          intensificationTechnique ?? this.intensificationTechnique,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
    exerciseId,
    exerciseName,
    orderInSession,
    sets,
    repRange,
    targetRir,
    intensityZone,
    restSeconds,
    tempo,
    intensificationTechnique,
    notes,
  ];

  @override
  String toString() {
    return 'ExercisePrescription($exerciseName: ${sets}x${repsDescription} @RIR$targetRir)';
  }
}
