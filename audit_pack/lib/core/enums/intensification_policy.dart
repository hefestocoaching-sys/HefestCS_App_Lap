/// Política de intensificación manual/automática del motor
/// - off: No se aplica intensificación automática (default seguro)
/// - coachOnly: Solo disponible bajo criterios; requiere decisión manual del entrenador
enum IntensificationPolicy {
  /// Sin intensificación automática. Patrón seguro de acumulación/deload.
  off,

  /// Solo disponible si se cumplen criterios (nivel avanzado, fatiga baja, adherencia alta, etc).
  /// Requiere confirmación manual del entrenador. No aplicar drop sets/rest-pause automáticamente.
  coachOnly,
}

extension IntensificationPolicyExt on IntensificationPolicy {
  bool get isOff => this == IntensificationPolicy.off;
  bool get isCoachOnly => this == IntensificationPolicy.coachOnly;

  String get name {
    switch (this) {
      case IntensificationPolicy.off:
        return 'off';
      case IntensificationPolicy.coachOnly:
        return 'coachOnly';
    }
  }
}
