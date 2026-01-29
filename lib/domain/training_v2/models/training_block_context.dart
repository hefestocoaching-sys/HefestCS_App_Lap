import 'package:equatable/equatable.dart';
import 'package:hcs_app_lap/domain/entities/training_macro_plan.dart';

class TrainingBlockContext extends Equatable {
  final PhaseType phaseType;
  final LoadProfile loadProfile;
  final int blockWeekIndex; // 1..durationWeeks
  final int blockDurationWeeks;
  final bool autoAdjustEnabled;

  const TrainingBlockContext({
    required this.phaseType,
    required this.loadProfile,
    required this.blockWeekIndex,
    required this.blockDurationWeeks,
    required this.autoAdjustEnabled,
  });

  @override
  List<Object?> get props => [
    phaseType,
    loadProfile,
    blockWeekIndex,
    blockDurationWeeks,
    autoAdjustEnabled,
  ];
}
