import 'package:equatable/equatable.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_plan_config.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_week.dart';

class TrainingPlan extends Equatable {
  final String id;
  final String clientId;
  final DateTime startDate;
  final List<TrainingWeek> weeks;
  final String? split;
  final String? phase;

  const TrainingPlan({
    required this.id,
    required this.clientId,
    required this.startDate,
    required this.weeks,
    this.split,
    this.phase,
  });

  factory TrainingPlan.fromConfig(TrainingPlanConfig config) {
    return TrainingPlan(
      id: config.id,
      clientId: config.clientId,
      startDate: config.startDate,
      weeks: config.weeks.whereType<TrainingWeek>().toList(),
      split: config.split,
      phase: config.phase,
    );
  }

  @override
  List<Object?> get props => [id, clientId, startDate, weeks, split, phase];
}
