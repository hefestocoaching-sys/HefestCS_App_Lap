import 'package:hcs_app_lap/core/enums/training_phase.dart';

class WeekPlan {
  final int weekNumber;
  final TrainingPhase phase;
  final Map<String, dynamic> metadata;

  WeekPlan({
    required this.weekNumber,
    required this.phase,
    this.metadata = const {},
  });

  // --- CORRECCIÓN: Agregamos el getter que faltaba ---
  double get volumeFactor {
    switch (phase) {
      case TrainingPhase.accumulation:
        return 0.8; // Shock
      case TrainingPhase.intensification:
        return 0.7;
      case TrainingPhase.deload:
        return 0.5;
    }
  }

  Map<String, dynamic> toMap() => {
    'weekNumber': weekNumber,
    'phase': phase.name,
    'metadata': metadata,
  };

  factory WeekPlan.fromMap(Map<String, dynamic> map) {
    return WeekPlan(
      weekNumber: map['weekNumber'] as int? ?? 1,
      phase: TrainingPhase.values.firstWhere(
        (p) => p.name == map['phase'],
        orElse: () => TrainingPhase.accumulation,
      ),
      metadata: map['metadata'] as Map<String, dynamic>? ?? {},
    );
  }
}
