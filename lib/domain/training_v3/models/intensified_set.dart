import 'package:equatable/equatable.dart';
import 'package:hcs_app_lap/domain/training_v3/models/exercise_set.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/intensification_techniques_engine.dart';

/// Modelo de set con técnica de intensificación aplicada
class IntensifiedSet extends Equatable {
  final ExerciseSet baseSet;
  final IntensificationTechnique technique;
  final Map<String, dynamic>? restPauseProtocol;
  final Map<String, dynamic>? dropSetProtocol;
  final Map<String, dynamic>? supersetConfig;

  const IntensifiedSet({
    required this.baseSet,
    required this.technique,
    this.restPauseProtocol,
    this.dropSetProtocol,
    this.supersetConfig,
  });

  @override
  List<Object?> get props => [
    baseSet,
    technique,
    restPauseProtocol,
    dropSetProtocol,
    supersetConfig,
  ];
}
