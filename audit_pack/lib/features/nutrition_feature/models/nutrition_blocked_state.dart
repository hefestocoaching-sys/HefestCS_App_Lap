class NutritionBlockedState {
  final bool isBlocked;
  final List<String> missingFields;
  final String userMessage;

  const NutritionBlockedState({
    required this.isBlocked,
    required this.missingFields,
    required this.userMessage,
  });

  const NutritionBlockedState.unblocked()
      : isBlocked = false,
        missingFields = const [],
        userMessage = '';

  factory NutritionBlockedState.blocked(List<String> missingFields) {
    final fields = List<String>.from(missingFields);
    final message = fields.isEmpty
        ? ''
        : 'Completa los siguientes datos antes de calcular: ${fields.join(', ')}';
    return NutritionBlockedState(
      isBlocked: true,
      missingFields: List.unmodifiable(fields),
      userMessage: message,
    );
  }
}
