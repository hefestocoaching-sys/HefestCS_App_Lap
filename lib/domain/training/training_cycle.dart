import 'package:equatable/equatable.dart';
import 'package:hcs_app_lap/utils/date_helpers.dart';

/// Representa un ciclo de entrenamiento completo.
///
/// RESPONSABILIDAD:
/// - Fuente única de verdad (SSOT) para un ciclo de entrenamiento
/// - Define estructura base: split, ejercicios, objetivos
/// - El Motor de entrenamiento NO puede cambiar estructura del ciclo
/// - Solo puede ajustar: volumen, series, intensidad, rol
///
/// INVARIANTE:
/// - Un ciclo tiene vida fija (startDate → endDate)
/// - Los ejercicios base NO cambian durante su vida
/// - El motor recibe TrainingCycle como input inmutable
/// - Solo se crea un ciclo por startDate/cliente
/// - SOLO 1 ciclo con status == "active" por clientId en todo momento
class TrainingCycle extends Equatable {
  // ─────────────────────────────────────────────────────────────────────────
  // Campos originales (NO modificados)
  // ─────────────────────────────────────────────────────────────────────────

  final String cycleId;

  /// ID del cliente propietario del ciclo.
  final String clientId;

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

  // ─────────────────────────────────────────────────────────────────────────
  // Campos nuevos — Contrato Ciclo Único Activo + Freeze Snapshot
  // ─────────────────────────────────────────────────────────────────────────

  /// Estado del ciclo. Valores válidos: "active" | "completed" | "archived".
  /// REGLA CRÍTICA: Solo 1 ciclo con status == "active" por clientId.
  final String status;

  /// Volumen Objetivo de Programa por músculo (sets/semana).
  final Map<String, int> vopByMuscle;

  /// Volumen Mínimo de Retención por músculo (sets/semana).
  final Map<String, int> vmrByMuscle;

  /// Músculos primarios del ciclo.
  final List<String> primaryMuscles;

  /// Músculos secundarios del ciclo.
  final List<String> secondaryMuscles;

  /// Días disponibles para entrenar por semana.
  final int availableDays;

  /// Duración estimada de sesión en minutos.
  final int sessionDurationMinutes;

  /// Nivel de entrenamiento del cliente (ej: "principiante", "intermedio", "avanzado").
  final String trainingLevel;

  /// Snapshot inmutable del plan congelado (Week 1).
  /// Contiene: split, ejercicios por día, orden, caps, anclas.
  final Map<String, dynamic> freezePlanSnapshot;

  /// Timestamp de última actualización del ciclo.
  final DateTime updatedAt;

  // ─────────────────────────────────────────────────────────────────────────
  // Constructor
  // ─────────────────────────────────────────────────────────────────────────

  const TrainingCycle({
    required this.cycleId,
    required this.clientId,
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
    // Nuevos campos con defaults seguros
    this.status = 'active',
    this.vopByMuscle = const {},
    this.vmrByMuscle = const {},
    this.primaryMuscles = const [],
    this.secondaryMuscles = const [],
    this.availableDays = 4,
    this.sessionDurationMinutes = 60,
    this.trainingLevel = 'intermedio',
    this.freezePlanSnapshot = const {},
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  // ─────────────────────────────────────────────────────────────────────────
  // Serialización
  // ─────────────────────────────────────────────────────────────────────────

  /// Convierte a mapa JSON para persistencia.
  Map<String, dynamic> toMap() {
    return {
      'cycleId': cycleId,
      'clientId': clientId,
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
      // Nuevos campos
      'status': status,
      'vopByMuscle': vopByMuscle,
      'vmrByMuscle': vmrByMuscle,
      'primaryMuscles': primaryMuscles,
      'secondaryMuscles': secondaryMuscles,
      'availableDays': availableDays,
      'sessionDurationMinutes': sessionDurationMinutes,
      'trainingLevel': trainingLevel,
      'freezePlanSnapshot': freezePlanSnapshot,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Crea desde mapa JSON.
  factory TrainingCycle.fromMap(Map<String, dynamic> map) {
    return TrainingCycle(
      cycleId: map['cycleId'] as String? ?? '',
      clientId: map['clientId'] as String? ?? '',
      startDate: parseDateTimeOrEpoch(map['startDate']?.toString()),
      endDate: map['endDate'] != null
          ? tryParseDateTime(map['endDate']?.toString())
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
      createdAt: parseDateTimeOrEpoch(map['createdAt']?.toString()),
      // Nuevos campos con defaults seguros para retrocompatibilidad
      status: map['status'] as String? ?? 'active',
      vopByMuscle: _parseIntMap(map['vopByMuscle']),
      vmrByMuscle: _parseIntMap(map['vmrByMuscle']),
      primaryMuscles: List<String>.from(map['primaryMuscles'] as List? ?? []),
      secondaryMuscles: List<String>.from(
        map['secondaryMuscles'] as List? ?? [],
      ),
      availableDays: map['availableDays'] as int? ?? 4,
      sessionDurationMinutes: map['sessionDurationMinutes'] as int? ?? 60,
      trainingLevel: map['trainingLevel'] as String? ?? 'intermedio',
      freezePlanSnapshot: Map<String, dynamic>.from(
        map['freezePlanSnapshot'] as Map? ?? {},
      ),
      updatedAt: map['updatedAt'] != null
          ? tryParseDateTime(map['updatedAt']?.toString())
          : null,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // copyWith
  // ─────────────────────────────────────────────────────────────────────────

  /// Copia con cambios selectivos.
  TrainingCycle copyWith({
    String? cycleId,
    String? clientId,
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
    // Nuevos campos
    String? status,
    Map<String, int>? vopByMuscle,
    Map<String, int>? vmrByMuscle,
    List<String>? primaryMuscles,
    List<String>? secondaryMuscles,
    int? availableDays,
    int? sessionDurationMinutes,
    String? trainingLevel,
    Map<String, dynamic>? freezePlanSnapshot,
    DateTime? updatedAt,
  }) {
    return TrainingCycle(
      cycleId: cycleId ?? this.cycleId,
      clientId: clientId ?? this.clientId,
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
      status: status ?? this.status,
      vopByMuscle: vopByMuscle ?? this.vopByMuscle,
      vmrByMuscle: vmrByMuscle ?? this.vmrByMuscle,
      primaryMuscles: primaryMuscles ?? this.primaryMuscles,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      availableDays: availableDays ?? this.availableDays,
      sessionDurationMinutes:
          sessionDurationMinutes ?? this.sessionDurationMinutes,
      trainingLevel: trainingLevel ?? this.trainingLevel,
      freezePlanSnapshot: freezePlanSnapshot ?? this.freezePlanSnapshot,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  static Map<String, int> _parseIntMap(dynamic raw) {
    if (raw == null) return {};
    if (raw is! Map) return {};
    return Map<String, int>.from(
      raw.map((k, v) => MapEntry(k.toString(), (v as num).toInt())),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Equatable / toString
  // ─────────────────────────────────────────────────────────────────────────

  @override
  String toString() {
    return 'TrainingCycle(id=$cycleId, goal=$goal, split=$splitType, '
        'week=$currentWeek, status=$status)';
  }

  @override
  List<Object?> get props => [
    cycleId,
    clientId,
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
    status,
    vopByMuscle,
    vmrByMuscle,
    primaryMuscles,
    secondaryMuscles,
    availableDays,
    sessionDurationMinutes,
    trainingLevel,
    freezePlanSnapshot,
    updatedAt,
  ];
}
