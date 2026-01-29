enum TrainingLevel {
  beginner,
  intermediate,
  advanced;

  startsWith(String s) {}
}

extension TrainingLevelX on TrainingLevel {
  String get label => switch (this) {
    TrainingLevel.beginner => 'Principiante',
    TrainingLevel.intermediate => 'Intermedio',
    TrainingLevel.advanced => 'Avanzado',
  };
}

TrainingLevel? parseTrainingLevel(String? value) {
  if (value == null) return null;
  final normalized = value.toLowerCase().trim();
  final compact = normalized.replaceAll(RegExp(r'[^a-z0-9áéíóúñ]'), '');
  final asciiCompact = compact
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ñ', 'n');
  if ([
    'beginner',
    'principiante',
    'recreativo',
    'novato',
    'principiante06meses',
  ].contains(asciiCompact)) {
    return TrainingLevel.beginner;
  }
  if ([
    'intermediate',
    'intermedio',
    'amateur',
    'medio',
    'intermedio6m2anos',
  ].contains(asciiCompact)) {
    return TrainingLevel.intermediate;
  }
  if ([
    'advanced',
    'avanzado',
    'competidor',
    'avanzado2anos',
  ].contains(asciiCompact)) {
    return TrainingLevel.advanced;
  }
  return null;
}
