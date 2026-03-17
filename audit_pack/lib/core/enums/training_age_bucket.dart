enum TrainingAgeBucket { lessThanOne, oneToTwo, threeToFive, moreThanFive }

extension TrainingAgeBucketX on TrainingAgeBucket {
  String get label => switch (this) {
    TrainingAgeBucket.lessThanOne => 'Menos de 1 año',
    TrainingAgeBucket.oneToTwo => '1-2 años',
    TrainingAgeBucket.threeToFive => '3-5 años',
    TrainingAgeBucket.moreThanFive => 'Más de 5 años',
  };

  /// Valor promedio representativo en años
  double get averageYears => switch (this) {
    TrainingAgeBucket.lessThanOne => 0.5,
    TrainingAgeBucket.oneToTwo => 1.5,
    TrainingAgeBucket.threeToFive => 4.0,
    TrainingAgeBucket.moreThanFive => 7.0,
  };
}

TrainingAgeBucket? parseTrainingAgeBucket(String? value) {
  if (value == null) return null;
  final normalized = value.toLowerCase().trim();

  if (normalized.contains('< 1') ||
      normalized.contains('menos de 1') ||
      normalized.contains('0-1')) {
    return TrainingAgeBucket.lessThanOne;
  }
  if (normalized.contains('1-2') || normalized.contains('1 a 2')) {
    return TrainingAgeBucket.oneToTwo;
  }
  if (normalized.contains('3-5') || normalized.contains('3 a 5')) {
    return TrainingAgeBucket.threeToFive;
  }
  if (normalized.contains('> 5') ||
      normalized.contains('más de 5') ||
      normalized.contains('5+')) {
    return TrainingAgeBucket.moreThanFive;
  }

  return null;
}
