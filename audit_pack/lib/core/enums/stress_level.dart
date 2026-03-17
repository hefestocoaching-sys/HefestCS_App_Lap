enum StressLevel { low, moderate, high }

extension StressLevelX on StressLevel {
  String get label => switch (this) {
    StressLevel.low => 'Bajo',
    StressLevel.moderate => 'Moderado',
    StressLevel.high => 'Alto',
  };
}

StressLevel? parseStressLevel(String? value) {
  if (value == null) return null;
  final normalized = value.toLowerCase().trim();

  if (normalized.contains('bajo') || normalized.contains('low')) {
    return StressLevel.low;
  }
  if (normalized.contains('moderado') ||
      normalized.contains('moderate') ||
      normalized.contains('medio')) {
    return StressLevel.moderate;
  }
  if (normalized.contains('alto') || normalized.contains('high')) {
    return StressLevel.high;
  }

  return null;
}
