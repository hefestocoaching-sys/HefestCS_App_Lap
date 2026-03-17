import 'package:meta/meta.dart';

@immutable
class WeeklyDecision {
  final int weekNumber;

  /// "increase" | "maintain" | "deload"
  final Map<String, String> actionByMuscle;

  /// sets directos nuevos por músculo (objetivo semanal)
  final Map<String, int> newDirectSetsByMuscle;

  /// heavy/medium/light por músculo (sets enteros)
  final Map<String, Map<String, int>> stimulusSetsByMuscle;

  /// rir targets por músculo
  final Map<String, Map<String, int>> rirTargetsByMuscle;

  /// insights human-readable por músculo (para coach/cliente)
  final Map<String, String> insightByMuscle;

  const WeeklyDecision({
    required this.weekNumber,
    required this.actionByMuscle,
    required this.newDirectSetsByMuscle,
    required this.stimulusSetsByMuscle,
    required this.rirTargetsByMuscle,
    required this.insightByMuscle,
  });
}
