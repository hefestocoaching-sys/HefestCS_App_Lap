import 'package:equatable/equatable.dart';
import 'package:hcs_app_lap/core/enums/muscle_group.dart';
import 'package:hcs_app_lap/domain/models/rir_target.dart';
import 'rep_range.dart';

class ExercisePrescription extends Equatable {
  final String id;
  final String sessionId;
  final MuscleGroup muscleGroup;
  final String exerciseCode;
  final String label;
  final String exerciseName;
  final int sets;
  final RepRange repRange;
  final String rir;
  final int restMinutes;
  final bool allowFailureOnLastSet;
  final String? notes;
  final int order;
  final String? templateCode;
  final String? supersetGroup;
  final String? slotLabel;

  const ExercisePrescription({
    required this.id,
    required this.sessionId,
    required this.muscleGroup,
    required this.exerciseCode,
    required this.label,
    required this.exerciseName,
    required this.sets,
    required this.repRange,
    required this.rir,
    required this.restMinutes,
    this.allowFailureOnLastSet = false,
    this.notes,
    this.order = 0,
    this.templateCode,
    this.supersetGroup,
    this.slotLabel,
  });

  String get reps => repRange.toString();

  /// Convierte el campo `rir` (String) a RirTarget para uso interno
  /// Mantiene compatibilidad con formato legible ("3", "2-3", etc.)
  RirTarget get rirTarget => RirTarget.parseLabel(rir);

  /// Crea una copia con un nuevo RirTarget, convirtiendo a String label
  ExercisePrescription copyWithRirTarget(RirTarget rirTarget) {
    return copyWith(rir: rirTarget.label);
  }

  ExercisePrescription copyWith({
    String? id,
    String? sessionId,
    MuscleGroup? muscleGroup,
    String? exerciseCode,
    String? label,
    String? exerciseName,
    int? sets,
    RepRange? repRange,
    String? rir,
    int? restMinutes,
    bool? allowFailureOnLastSet,
    String? notes,
    int? order,
    String? templateCode,
    String? supersetGroup,
    String? slotLabel,
  }) {
    return ExercisePrescription(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      exerciseCode: exerciseCode ?? this.exerciseCode,
      label: label ?? this.label,
      exerciseName: exerciseName ?? this.exerciseName,
      sets: sets ?? this.sets,
      repRange: repRange ?? this.repRange,
      rir: rir ?? this.rir,
      restMinutes: restMinutes ?? this.restMinutes,
      allowFailureOnLastSet:
          allowFailureOnLastSet ?? this.allowFailureOnLastSet,
      notes: notes ?? this.notes,
      order: order ?? this.order,
      templateCode: templateCode ?? this.templateCode,
      supersetGroup: supersetGroup ?? this.supersetGroup,
      slotLabel: slotLabel ?? this.slotLabel,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'muscleGroup': muscleGroup.name,
    'exerciseCode': exerciseCode,
    'label': label,
    'exerciseName': exerciseName,
    'sets': sets,
    'repRange': repRange.toJson(),
    'rir': rir,
    'restMinutes': restMinutes,
    'allowFailureOnLastSet': allowFailureOnLastSet,
    'notes': notes,
    'order': order,
    'templateCode': templateCode,
    'supersetGroup': supersetGroup,
    'slotLabel': slotLabel,
  };

  factory ExercisePrescription.fromJson(Map<String, dynamic> json) {
    return ExercisePrescription(
      id: json['id'] as String? ?? '',
      sessionId: json['sessionId'] as String? ?? '',
      muscleGroup: MuscleGroup.values.firstWhere(
        (e) => e.name == json['muscleGroup'],
        orElse: () => MuscleGroup.fullBody,
      ),
      exerciseCode: json['exerciseCode'] as String? ?? '',
      label: json['label'] as String? ?? 'A',
      exerciseName: json['exerciseName'] as String? ?? 'Ejercicio',
      sets: json['sets'] as int? ?? 0,
      repRange: RepRange.fromJson(json['repRange'] ?? {}),
      rir: json['rir'] as String? ?? '2',
      restMinutes: json['restMinutes'] as int? ?? 2,
      allowFailureOnLastSet: json['allowFailureOnLastSet'] as bool? ?? false,
      notes: json['notes'] as String?,
      order: json['order'] as int? ?? 0,
      templateCode: json['templateCode'] as String?,
      supersetGroup: json['supersetGroup'] as String?,
      slotLabel: json['slotLabel'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, exerciseCode, sets, repRange, rir, order];
}
