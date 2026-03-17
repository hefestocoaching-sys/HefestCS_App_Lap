enum VolumeTolerance { low, medium, high }

extension VolumeToleranceX on VolumeTolerance {
  String get label => switch (this) {
    VolumeTolerance.low => 'Baja',
    VolumeTolerance.medium => 'Media',
    VolumeTolerance.high => 'Alta',
  };

  /// Multiplicador para ajustar el volumen base de series
  double get multiplier => switch (this) {
    VolumeTolerance.low => 0.85,
    VolumeTolerance.medium => 1.0,
    VolumeTolerance.high => 1.1,
  };
}

VolumeTolerance? parseVolumeTolerance(String? value) {
  if (value == null) return null;
  final normalized = value.toLowerCase().trim();

  if (normalized.contains('baja') || normalized.contains('low')) {
    return VolumeTolerance.low;
  }
  if (normalized.contains('media') ||
      normalized.contains('medium') ||
      normalized.contains('moderada')) {
    return VolumeTolerance.medium;
  }
  if (normalized.contains('alta') || normalized.contains('high')) {
    return VolumeTolerance.high;
  }

  return null;
}
