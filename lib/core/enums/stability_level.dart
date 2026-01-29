enum StabilityLevel { high, moderate, low }

extension StabilityLevelX on StabilityLevel {
  String get label => switch (this) {
        StabilityLevel.high => 'Alta',
        StabilityLevel.moderate => 'Media',
        StabilityLevel.low => 'Baja',
      };
}
