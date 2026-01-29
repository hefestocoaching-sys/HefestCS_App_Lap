enum IntensityTolerance { low, medium, high }

extension IntensityToleranceX on IntensityTolerance {
  String get label => switch (this) {
    IntensityTolerance.low => 'Baja (Casi nunca)',
    IntensityTolerance.medium => 'Media (1-2 veces/semana)',
    IntensityTolerance.high => 'Alta (3+ veces/semana)',
  };
}

IntensityTolerance? parseIntensityTolerance(String? value) {
  if (value == null) return null;
  final normalized = value.toLowerCase().trim();

  if (normalized.contains('baja') ||
      normalized.contains('low') ||
      normalized.contains('nunca')) {
    return IntensityTolerance.low;
  }
  if (normalized.contains('media') ||
      normalized.contains('medium') ||
      normalized.contains('1-2')) {
    return IntensityTolerance.medium;
  }
  if (normalized.contains('alta') ||
      normalized.contains('high') ||
      normalized.contains('3+')) {
    return IntensityTolerance.high;
  }

  return null;
}
