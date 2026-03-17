/// Patrón de movimiento biomecánico fundamental
enum MovementPattern {
  /// Empuje horizontal (ej: press banca, push-ups)
  horizontalPush,

  /// Empuje vertical (ej: press militar, overhead press)
  verticalPush,

  /// Jalón vertical (ej: pull-ups, lat pulldown)
  verticalPull,

  /// Remo horizontal (ej: barbell row, cable row)
  horizontalPull,

  /// Patrón de bisagra/hinge (ej: deadlift, RDL, good mornings)
  hinge,

  /// Patrón de sentadilla (ej: squat, leg press)
  squat,

  /// Unilateral pierna (ej: lunges, split squat, step-ups)
  unilateral,

  /// Extensión de tríceps (ej: triceps extension, dips)
  tricepsExtension,

  /// Flexión de bíceps (ej: biceps curl, hammer curl)
  bicepsFlexion,

  /// Elevación lateral (ej: lateral raises, cable lateral raises)
  lateralRaise,

  /// Deltoides posterior/rear delt (ej: face pulls, reverse fly)
  rearDelt,

  /// Pantorrilla (ej: calf raise)
  calf,

  /// Core/abdomen (ej: planks, crunches, leg raises)
  core,

  /// Glúteo específico (ej: hip thrust, glute bridge)
  gluteIsolation,

  /// Cuádriceps específico (ej: leg extension)
  quadIsolation,

  /// Isquio específico (ej: leg curl)
  hamstringIsolation,

  /// Accesorio general
  accessory,
}

MovementPattern? parseMovementPattern(String? value) {
  if (value == null || value.isEmpty) return null;
  try {
    return MovementPattern.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
    );
  } catch (_) {
    return null;
  }
}

extension MovementPatternExtension on MovementPattern {
  String get label {
    switch (this) {
      case MovementPattern.horizontalPush:
        return 'Empuje Horizontal';
      case MovementPattern.verticalPush:
        return 'Empuje Vertical';
      case MovementPattern.verticalPull:
        return 'Jalón Vertical';
      case MovementPattern.horizontalPull:
        return 'Remo Horizontal';
      case MovementPattern.hinge:
        return 'Bisagra/Hinge';
      case MovementPattern.squat:
        return 'Sentadilla';
      case MovementPattern.unilateral:
        return 'Unilateral Pierna';
      case MovementPattern.tricepsExtension:
        return 'Extensión Tríceps';
      case MovementPattern.bicepsFlexion:
        return 'Flexión Bíceps';
      case MovementPattern.lateralRaise:
        return 'Elevación Lateral';
      case MovementPattern.rearDelt:
        return 'Deltoides Posterior';
      case MovementPattern.calf:
        return 'Pantorrilla';
      case MovementPattern.core:
        return 'Core/Abdomen';
      case MovementPattern.gluteIsolation:
        return 'Glúteo Aislado';
      case MovementPattern.quadIsolation:
        return 'Cuádriceps Aislado';
      case MovementPattern.hamstringIsolation:
        return 'Isquio Aislado';
      case MovementPattern.accessory:
        return 'Accesorio';
    }
  }
}
