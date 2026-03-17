import 'package:hcs_app_lap/domain/training_v3/models/muscle_progress_state.dart';

/// Estado longitudinal del ciclo de entrenamiento Motor V3.
///
/// Registra en qué semana del ciclo se encuentra el cliente,
/// qué fase está activa y los índices de fatiga/recuperación.

class TrainingPlanMeta {
  final int weekOfCycle;
  final int weekOfPhase;
  final int weekOfMicrocycle;

  final String phase;

  final bool overreachEnabled;

  final double fatigueIndex;
  final double recoveryIndex;

  final Map<String, MuscleProgressState> muscleState;

  const TrainingPlanMeta({
    required this.weekOfCycle,
    required this.weekOfPhase,
    required this.weekOfMicrocycle,
    required this.phase,
    required this.overreachEnabled,
    required this.fatigueIndex,
    required this.recoveryIndex,
    required this.muscleState,
  });

  Map<String, dynamic> toMap() => {
    'weekOfCycle': weekOfCycle,
    'weekOfPhase': weekOfPhase,
    'weekOfMicrocycle': weekOfMicrocycle,
    'phase': phase,
    'overreachEnabled': overreachEnabled,
    'fatigueIndex': fatigueIndex,
    'recoveryIndex': recoveryIndex,
    'muscleState': muscleState.map((k, v) => MapEntry(k, v.toMap())),
  };

  factory TrainingPlanMeta.fromMap(Map<String, dynamic> map) =>
      TrainingPlanMeta(
        weekOfCycle: (map['weekOfCycle'] as num?)?.toInt() ?? 1,
        weekOfPhase: (map['weekOfPhase'] as num?)?.toInt() ?? 1,
        weekOfMicrocycle: (map['weekOfMicrocycle'] as num?)?.toInt() ?? 1,
        phase: map['phase'] as String? ?? 'adaptation',
        overreachEnabled: map['overreachEnabled'] as bool? ?? false,
        fatigueIndex: (map['fatigueIndex'] as num?)?.toDouble() ?? 0.0,
        recoveryIndex: (map['recoveryIndex'] as num?)?.toDouble() ?? 0.0,
        muscleState: ((map['muscleState'] as Map?) ?? const {}).map(
          (k, v) => MapEntry(
            k.toString(),
            MuscleProgressState.fromMap(Map<String, dynamic>.from(v as Map)),
          ),
        ),
      );

  TrainingPlanMeta copyWith({
    int? weekOfCycle,
    int? weekOfPhase,
    int? weekOfMicrocycle,
    String? phase,
    bool? overreachEnabled,
    double? fatigueIndex,
    double? recoveryIndex,
    Map<String, MuscleProgressState>? muscleState,
  }) => TrainingPlanMeta(
    weekOfCycle: weekOfCycle ?? this.weekOfCycle,
    weekOfPhase: weekOfPhase ?? this.weekOfPhase,
    weekOfMicrocycle: weekOfMicrocycle ?? this.weekOfMicrocycle,
    phase: phase ?? this.phase,
    overreachEnabled: overreachEnabled ?? this.overreachEnabled,
    fatigueIndex: fatigueIndex ?? this.fatigueIndex,
    recoveryIndex: recoveryIndex ?? this.recoveryIndex,
    muscleState: muscleState ?? this.muscleState,
  );
}
