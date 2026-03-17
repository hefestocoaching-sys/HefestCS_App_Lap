/// Tipo de sesión de entrenamiento en un split
enum DayType {
  /// Tren superior completo
  upper,

  /// Tren inferior completo
  lower,

  /// Día de empuje (pecho/hombros/tríceps)
  push,

  /// Día de jalón (espalda/bíceps)
  pull,

  /// Día de piernas
  legs,

  /// Día mixto (upper + lower)
  mixed,

  /// Día de accesorios/pump/hipertrofia específica
  accessories,

  /// Cuerpo completo
  fullbody,
}

DayType? parseDayType(String? value) {
  if (value == null || value.isEmpty) return null;
  try {
    return DayType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
    );
  } catch (_) {
    return null;
  }
}

extension DayTypeExtension on DayType {
  String get label {
    switch (this) {
      case DayType.upper:
        return 'Tren Superior';
      case DayType.lower:
        return 'Tren Inferior';
      case DayType.push:
        return 'Push (Empuje)';
      case DayType.pull:
        return 'Pull (Jalón)';
      case DayType.legs:
        return 'Piernas';
      case DayType.mixed:
        return 'Mixto';
      case DayType.accessories:
        return 'Accesorios';
      case DayType.fullbody:
        return 'Cuerpo Completo';
    }
  }
}
