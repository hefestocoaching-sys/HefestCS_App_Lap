enum Gender { male, female, other }

extension GenderX on Gender {
  String get label => switch (this) {
    Gender.male => 'Hombre',
    Gender.female => 'Mujer',
    Gender.other => 'Otro',
  };

  bool get isMale => this == Gender.male;
  bool get isFemale => this == Gender.female;
}

/// Helpers para convertir cadenas variadas en el enum.
Gender? parseGender(String? value) {
  if (value == null) return null;
  final normalized = value.toLowerCase().trim();
  if ([
    'male',
    'masculino',
    'hombre',
    'm',
  ].contains(normalized)) {
    return Gender.male;
  }
  if ([
    'female',
    'femenino',
    'mujer',
    'f',
  ].contains(normalized)) {
    return Gender.female;
  }
  return Gender.other;
}
