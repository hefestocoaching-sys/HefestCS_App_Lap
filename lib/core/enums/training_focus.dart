enum TrainingFocus {
  hypertrophy,
  strength,
  power,
  mixed,

  // Agregado para el Motor B
  gluteSpecialization,
}

extension TrainingFocusX on TrainingFocus {
  String get label {
    switch (this) {
      case TrainingFocus.hypertrophy:
        return 'Hipertrofia General';
      case TrainingFocus.strength:
        return 'Fuerza';
      case TrainingFocus.power:
        return 'Potencia';
      case TrainingFocus.mixed:
        return 'Híbrido';
      case TrainingFocus.gluteSpecialization:
        return 'Especialización Glúteo';
    }
  }
}
