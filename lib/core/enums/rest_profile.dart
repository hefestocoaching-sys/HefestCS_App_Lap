enum RestProfile { short, moderate, long, veryLong }

extension RestProfileX on RestProfile {
  String get label => switch (this) {
    RestProfile.short => 'Menos de 60 segundos',
    RestProfile.moderate => '60-120 segundos',
    RestProfile.long => '2-3 minutos',
    RestProfile.veryLong => 'Más de 3 minutos',
  };

  /// Valor promedio representativo en segundos
  int get averageSeconds => switch (this) {
    RestProfile.short => 45,
    RestProfile.moderate => 90,
    RestProfile.long => 150,
    RestProfile.veryLong => 240,
  };
}

RestProfile? parseRestProfile(String? value) {
  if (value == null) return null;
  final normalized = value.toLowerCase().trim();

  if (normalized.contains('< 60') ||
      normalized.contains('menos de 60') ||
      normalized.contains('30 segundos') ||
      normalized.contains('45 segundos')) {
    return RestProfile.short;
  }
  if (normalized.contains('60-120') ||
      normalized.contains('60 segundos') ||
      normalized.contains('90 segundos')) {
    return RestProfile.moderate;
  }
  if (normalized.contains('2-3') ||
      normalized.contains('2 minutos') ||
      normalized.contains('3 minutos')) {
    return RestProfile.long;
  }
  if (normalized.contains('> 3') ||
      normalized.contains('más de 3') ||
      normalized.contains('5 minutos')) {
    return RestProfile.veryLong;
  }

  return null;
}
