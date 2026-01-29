enum TimePerSessionBucket {
  lessThan45,
  fortyFiveToSixty,
  sixtyToSeventyFive,
  moreThanSeventyFive,
}

extension TimePerSessionBucketX on TimePerSessionBucket {
  String get label => switch (this) {
    TimePerSessionBucket.lessThan45 => 'Menos de 45 min',
    TimePerSessionBucket.fortyFiveToSixty => '45-60 min',
    TimePerSessionBucket.sixtyToSeventyFive => '60-75 min',
    TimePerSessionBucket.moreThanSeventyFive => 'Más de 75 min',
  };

  /// Valor promedio representativo en minutos
  int get averageMinutes => switch (this) {
    TimePerSessionBucket.lessThan45 => 40,
    TimePerSessionBucket.fortyFiveToSixty => 52,
    TimePerSessionBucket.sixtyToSeventyFive => 67,
    TimePerSessionBucket.moreThanSeventyFive => 85,
  };
}

TimePerSessionBucket? parseTimePerSessionBucket(String? value) {
  if (value == null) return null;
  final normalized = value.toLowerCase().trim();

  if (normalized.contains('< 45') ||
      normalized.contains('menos de 45') ||
      normalized.contains('30') ||
      normalized.contains('40')) {
    return TimePerSessionBucket.lessThan45;
  }
  if (normalized.contains('45-60') || normalized.contains('45 a 60')) {
    return TimePerSessionBucket.fortyFiveToSixty;
  }
  if (normalized.contains('60-75') || normalized.contains('60 a 75')) {
    return TimePerSessionBucket.sixtyToSeventyFive;
  }
  if (normalized.contains('> 75') ||
      normalized.contains('más de 75') ||
      normalized.contains('90')) {
    return TimePerSessionBucket.moreThanSeventyFive;
  }

  return null;
}
