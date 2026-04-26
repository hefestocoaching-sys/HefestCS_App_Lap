/// Contrato base de orden estructural Fase 2.
///
/// Jerarquía declarada:
/// 1) prioridad muscular
/// 2) pesado (heavy)
/// 3) estructura 1-12
/// 4) tamaño muscular
class StructuralExerciseOrderContract {
  static int structuralIndex({
    required bool isLargeMuscle,
    required bool isCompound,
    required String intensityZone,
  }) {
    final zone = intensityZone.trim().toLowerCase();

    if (isLargeMuscle && isCompound) {
      if (zone == 'heavy') return 1;
      if (zone == 'medium') return 2;
      return 5;
    }
    if (!isLargeMuscle && isCompound) {
      if (zone == 'heavy') return 3;
      if (zone == 'medium') return 4;
      return 6;
    }
    if (isLargeMuscle && !isCompound) {
      if (zone == 'heavy') return 7;
      if (zone == 'medium') return 8;
      return 11;
    }

    if (zone == 'heavy') return 9;
    if (zone == 'medium') return 10;
    return 12;
  }
}
