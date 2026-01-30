import 'package:equatable/equatable.dart';

/// Representa un ciclo de entrenamiento completo.
///
/// RESPONSABILIDAD:
/// - Fuente única de verdad (SSOT) para un ciclo de entrenamiento
/// - Define estructura base: split, ejercicios, objetivos
/// - El Motor V2 NO puede cambiar estructura del ciclo
/// - Solo puede ajustar: volumen, series, intensidad, rol
///
/// INVARIANTE:
/// - Un ciclo tiene vida fija (startDate → endDate)
/// - Los ejercicios base NO cambian durante su vida
/// - El motor recibe TrainingCycle como input inmutable
/// - Solo se crea un ciclo por startDate/cliente
class TrainingCycle extends Equatable {
  final String cycleId;
  final DateTime startDate;
  final DateTime? endDate;
  final String goal; // ej: hipertrofia_general, gluteo_especializado, fuerza
  final List<String> priorityMuscles; // ej: [pecho, espalda, cuadriceps]
  final String splitType; // ej: torso_pierna_4d, fullbody_3d, ppl_6d
  final Map<String, List<String>>
  baseExercisesByMuscle; // ej: { pecho: [press_bancada, aperturas], ...}
  final String phaseState; // VME, VMR, DELOAD
  final int currentWeek; // semana actual del ciclo (1..N)
  final int frequency; // 2 o 3, inferida por VMR
  final DateTime createdAt;

  const TrainingCycle({
    required this.cycleId,
    required this.startDate,
    this.endDate,
    required this.goal,
    required this.priorityMuscles,
    required this.splitType,
    required this.baseExercisesByMuscle,
    required this.phaseState,
    required this.currentWeek,
    this.frequency = 2,
    required this.createdAt,
  });

  /// Convierte a mapa JSON para persistencia
  Map<String, dynamic> toMap() {
    return {
      'cycleId': cycleId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'goal': goal,
      'priorityMuscles': priorityMuscles,
      'splitType': splitType,
      'baseExercisesByMuscle': baseExercisesByMuscle,
      'phaseState': phaseState,
      'currentWeek': currentWeek,
      'frequency': frequency,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Crea desde mapa JSON
  factory TrainingCycle.fromMap(Map<String, dynamic> map) {
    return TrainingCycle(
      cycleId: map['cycleId'] as String? ?? '',
      startDate: DateTime.parse(map['startDate'] as String? ?? '2000-01-01'),
      endDate: map['endDate'] != null
          ? DateTime.parse(map['endDate'] as String)
          : null,
      goal: map['goal'] as String? ?? 'hipertrofia_general',
      priorityMuscles: List<String>.from(map['priorityMuscles'] as List? ?? []),
      splitType: map['splitType'] as String? ?? 'torso_pierna_4d',
      baseExercisesByMuscle: Map<String, List<String>>.from(
        (map['baseExercisesByMuscle'] as Map?)?.map(
              (k, v) =>
                  MapEntry(k as String, List<String>.from(v as List? ?? [])),
            ) ??
            {},
      ),
      phaseState: map['phaseState'] as String? ?? 'VME',
      currentWeek: map['currentWeek'] as int? ?? 1,
      frequency: map['frequency'] as int? ?? 2,
      createdAt: DateTime.parse(map['createdAt'] as String? ?? '2000-01-01'),
    );
  }

  /// Copia con cambios selectivos
  TrainingCycle copyWith({
    String? cycleId,
    DateTime? startDate,
    DateTime? endDate,
    String? goal,
    List<String>? priorityMuscles,
    String? splitType,
    Map<String, List<String>>? baseExercisesByMuscle,
    String? phaseState,
    int? currentWeek,
    int? frequency,
    DateTime? createdAt,
  }) {
    return TrainingCycle(
      cycleId: cycleId ?? this.cycleId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      goal: goal ?? this.goal,
      priorityMuscles: priorityMuscles ?? this.priorityMuscles,
      splitType: splitType ?? this.splitType,
      baseExercisesByMuscle:
          baseExercisesByMuscle ?? this.baseExercisesByMuscle,
      phaseState: phaseState ?? this.phaseState,
      currentWeek: currentWeek ?? this.currentWeek,
      frequency: frequency ?? this.frequency,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'TrainingCycle(id=$cycleId, goal=$goal, split=$splitType, week=$currentWeek)';
  }

  @override
  List<Object?> get props => [
    cycleId,
    startDate,
    endDate,
    goal,
    priorityMuscles,
    splitType,
    baseExercisesByMuscle,
    phaseState,
    currentWeek,
    frequency,
    createdAt,
  ];
}
