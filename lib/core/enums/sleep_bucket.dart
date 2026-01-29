enum SleepBucket { lessThan6, sixToSeven, sevenToEight, moreThanEight }

extension SleepBucketX on SleepBucket {
  String get label => switch (this) {
    SleepBucket.lessThan6 => 'Menos de 6 horas',
    SleepBucket.sixToSeven => '6-7 horas',
    SleepBucket.sevenToEight => '7-8 horas',
    SleepBucket.moreThanEight => 'Más de 8 horas',
  };

  /// Valor promedio representativo en horas
  double get averageHours => switch (this) {
    SleepBucket.lessThan6 => 5.5,
    SleepBucket.sixToSeven => 6.5,
    SleepBucket.sevenToEight => 7.5,
    SleepBucket.moreThanEight => 8.5,
  };
}

SleepBucket? parseSleepBucket(String? value) {
  if (value == null) return null;
  final normalized = value.toLowerCase().trim();

  if (normalized.contains('menos') ||
      normalized.contains('< 6') ||
      normalized.contains('less than 6')) {
    return SleepBucket.lessThan6;
  }
  if (normalized.contains('6-7') || normalized.contains('6 a 7')) {
    return SleepBucket.sixToSeven;
  }
  if (normalized.contains('7-8') || normalized.contains('7 a 8')) {
    return SleepBucket.sevenToEight;
  }
  if (normalized.contains('más') ||
      normalized.contains('> 8') ||
      normalized.contains('more than 8')) {
    return SleepBucket.moreThanEight;
  }

  return null;
}
