// lib/domain/training_v3/models/training_program.dart

import 'package:equatable/equatable.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_session.dart';
import 'package:hcs_app_lap/domain/training_v3/models/split_config.dart';

/// Programa de entrenamiento completo generado por Motor V3
///
/// Representa un mesociclo completo (4-6 semanas) con:
/// - Configuración de split (días, distribución muscular)
/// - Sesiones individuales con ejercicios prescritos
/// - Volumen total por músculo
/// - Fase de entrenamiento (acumulación/intensificación/deload)
///
/// FUNDAMENTO CIENTÍFICO:
/// - Semana 7, Imagen 89-95: Periodización por fases
/// - Semana 6: Split determina frecuencia por músculo
/// - Semana 1-2: Volumen total debe estar en rango VME-MRV
///
/// Versión: 1.0.0
class TrainingProgram extends Equatable {
  // ════════════════════════════════════════════════════════════
  // IDENTIFICACIÓN
  // ════════════════════════════════════════════════════════════

  /// ID único del programa
  final String id;

  /// ID del usuario al que pertenece
  final String userId;

  /// Nombre descriptivo del programa
  final String name;

  // ════════════════════════════════════════════════════════════
  // CONFIGURACIÓN
  // ════════════════════════════════════════════════════════════

  /// Configuración del split (Full Body, Upper/Lower, PPL, etc.)
  /// Semana 6, Imagen 64-69
  final SplitConfig split;

  /// Fase del programa
  /// - 'accumulation': Volumen alto, intensidad moderada (4-6 semanas)
  /// - 'intensification': Volumen moderado, intensidad alta (2-3 semanas)
  /// - 'deload': Volumen reducido 40-60%, recuperación (1 semana)
  /// Semana 7, Imagen 89-95
  final String phase;

  /// Duración en semanas (4-6 para accumulation, 2-3 para intensification, 1 para deload)
  final int durationWeeks;

  /// Semana actual dentro del programa (1-based)
  final int currentWeek;

  // ════════════════════════════════════════════════════════════
  // SESIONES
  // ════════════════════════════════════════════════════════════

  /// Sesiones de entrenamiento (una por día de la semana)
  /// Longitud = split.daysPerWeek
  final List<TrainingSession> sessions;

  // ════════════════════════════════════════════════════════════
  // VOLUMEN
  // ════════════════════════════════════════════════════════════

  /// Volumen semanal por músculo (sets totales directos + indirectos)
  /// Ejemplo: {'chest': 16.2, 'quads': 14.5, 'biceps': 8.3}
  /// Los valores incluyen contribución parcial de ejercicios secundarios
  /// Semana 1-2: Cada músculo debe estar entre VME-MRV
  final Map<String, double> weeklyVolumeByMuscle;

  // ════════════════════════════════════════════════════════════
  // METADATA
  // ════════════════════════════════════════════════════════════

  /// Fecha de inicio del programa
  final DateTime startDate;

  /// Fecha estimada de finalización
  final DateTime estimatedEndDate;

  /// Fecha de creación del programa
  final DateTime createdAt;

  /// Notas adicionales del coach
  final String? notes;

  const TrainingProgram({
    required this.id,
    required this.userId,
    required this.name,
    required this.split,
    required this.phase,
    required this.durationWeeks,
    this.currentWeek = 1,
    required this.sessions,
    required this.weeklyVolumeByMuscle,
    required this.startDate,
    required this.estimatedEndDate,
    required this.createdAt,
    this.notes,
  });

  /// Validar que el programa sea coherente
  bool get isValid {
    // Validar número de sesiones coincide con días del split
    if (sessions.length != split.daysPerWeek) return false;

    // Validar semana actual dentro del rango
    if (currentWeek < 1 || currentWeek > durationWeeks) return false;

    // Validar fase válida
    if (!['accumulation', 'intensification', 'deload'].contains(phase)) {
      return false;
    }

    // Validar duración según fase
    if (phase == 'accumulation' && (durationWeeks < 4 || durationWeeks > 6)) {
      return false;
    }
    if (phase == 'intensification' &&
        (durationWeeks < 2 || durationWeeks > 3)) {
      return false;
    }
    if (phase == 'deload' && durationWeeks != 1) return false;

    return true;
  }

  /// Calcular volumen total semanal (suma de todos los músculos)
  double get totalWeeklyVolume {
    return weeklyVolumeByMuscle.values.fold(0.0, (sum, vol) => sum + vol);
  }

  /// Calcular número total de ejercicios en el programa
  int get totalExercises {
    return sessions.fold(0, (sum, session) => sum + session.exercises.length);
  }

  /// Verificar si el programa está completo
  bool get isCompleted => currentWeek > durationWeeks;

  /// Obtener progreso como porcentaje (0.0-1.0)
  double get progress => (currentWeek - 1) / durationWeeks;

  /// Serialización a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'split': split.toJson(),
      'phase': phase,
      'durationWeeks': durationWeeks,
      'currentWeek': currentWeek,
      'sessions': sessions.map((s) => s.toJson()).toList(),
      'weeklyVolumeByMuscle': weeklyVolumeByMuscle,
      'startDate': startDate.toIso8601String(),
      'estimatedEndDate': estimatedEndDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'notes': notes,
    };
  }

  /// Deserialización desde JSON
  factory TrainingProgram.fromJson(Map<String, dynamic> json) {
    return TrainingProgram(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      split: SplitConfig.fromJson(json['split'] as Map<String, dynamic>),
      phase: json['phase'] as String,
      durationWeeks: json['durationWeeks'] as int,
      currentWeek: json['currentWeek'] as int? ?? 1,
      sessions: (json['sessions'] as List)
          .map((s) => TrainingSession.fromJson(s as Map<String, dynamic>))
          .toList(),
      weeklyVolumeByMuscle: Map<String, double>.from(
        (json['weeklyVolumeByMuscle'] as Map).map(
          (k, v) => MapEntry(k as String, (v as num).toDouble()),
        ),
      ),
      startDate: DateTime.parse(json['startDate'] as String),
      estimatedEndDate: DateTime.parse(json['estimatedEndDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      notes: json['notes'] as String?,
    );
  }

  /// CopyWith para actualizaciones inmutables
  TrainingProgram copyWith({
    String? id,
    String? userId,
    String? name,
    SplitConfig? split,
    String? phase,
    int? durationWeeks,
    int? currentWeek,
    List<TrainingSession>? sessions,
    Map<String, double>? weeklyVolumeByMuscle,
    DateTime? startDate,
    DateTime? estimatedEndDate,
    DateTime? createdAt,
    String? notes,
  }) {
    return TrainingProgram(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      split: split ?? this.split,
      phase: phase ?? this.phase,
      durationWeeks: durationWeeks ?? this.durationWeeks,
      currentWeek: currentWeek ?? this.currentWeek,
      sessions: sessions ?? this.sessions,
      weeklyVolumeByMuscle: weeklyVolumeByMuscle ?? this.weeklyVolumeByMuscle,
      startDate: startDate ?? this.startDate,
      estimatedEndDate: estimatedEndDate ?? this.estimatedEndDate,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    name,
    split,
    phase,
    durationWeeks,
    currentWeek,
    sessions,
    weeklyVolumeByMuscle,
    startDate,
    estimatedEndDate,
    createdAt,
    notes,
  ];

  @override
  String toString() {
    return 'TrainingProgram(id: $id, name: $name, phase: $phase, '
        'week: $currentWeek/$durationWeeks, sessions: ${sessions.length})';
  }
}
