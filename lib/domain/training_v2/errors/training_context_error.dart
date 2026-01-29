class TrainingContextError {
  final String code;
  final String message;
  final Map<String, dynamic> details;

  const TrainingContextError({
    required this.code,
    required this.message,
    this.details = const {},
  });

  @override
  String toString() => 'TrainingContextError($code): $message';
}

class MissingCriticalTrainingDataError extends TrainingContextError {
  const MissingCriticalTrainingDataError({
    required super.message,
    super.details = const {},
  }) : super(code: 'missing_critical_training_data');
}
