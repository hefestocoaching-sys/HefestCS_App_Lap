enum TrainingDiscipline { strengthHypertrophy, endurance, teamSports, mixed }

extension TrainingDisciplineX on TrainingDiscipline {
  String get label => switch (this) {
    TrainingDiscipline.strengthHypertrophy => 'Fuerza / Hipertrofia',
    TrainingDiscipline.endurance => 'Resistencia / Cardio',
    TrainingDiscipline.teamSports => 'Deportes de Equipo',
    TrainingDiscipline.mixed => 'Mixto / General',
  };
}

TrainingDiscipline? parseTrainingDiscipline(String? value) {
  if (value == null) return null;
  final normalized = value.toLowerCase().trim();

  if (normalized.contains('fuerza') ||
      normalized.contains('hipertrofia') ||
      normalized.contains('strength') ||
      normalized.contains('hypertrophy') ||
      normalized.contains('pesas') ||
      normalized.contains('gym')) {
    return TrainingDiscipline.strengthHypertrophy;
  }

  if (normalized.contains('resistencia') ||
      normalized.contains('endurance') ||
      normalized.contains('cardio') ||
      normalized.contains('correr')) {
    return TrainingDiscipline.endurance;
  }

  if (normalized.contains('equipo') ||
      normalized.contains('team') ||
      normalized.contains('fútbol') ||
      normalized.contains('basket')) {
    return TrainingDiscipline.teamSports;
  }

  if (normalized.contains('mixto') ||
      normalized.contains('mixed') ||
      normalized.contains('general')) {
    return TrainingDiscipline.mixed;
  }

  return null;
}
