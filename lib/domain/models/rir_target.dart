/// Rango de RIR (Reps In Reserve) objetivo sin decimales
///
/// Propósito:
/// - Eliminar ambigüedad de decimales (2.5 RIR no existe)
/// - Permitir rangos (2–3 RIR) cuando hay variabilidad legítima
/// - Garantizar salida legible en planes y UI
///
/// Invariantes:
/// - min >= 0, max >= min, max <= 4
/// - isRange true cuando min != max
class RirTarget {
  final int min;
  final int max;

  const RirTarget(this.min, this.max)
    : assert(min >= 0, 'min debe ser >= 0'),
      assert(max >= min, 'max debe ser >= min'),
      assert(max <= 4, 'max debe ser <= 4');

  /// Crea RirTarget de valor único (sin rango)
  const RirTarget.single(int value)
    : min = value,
      max = value,
      assert(value >= 0, 'value debe ser >= 0'),
      assert(value <= 4, 'value debe ser <= 4');

  /// Crea RirTarget de rango
  const RirTarget.range(int minVal, int maxVal)
    : min = minVal,
      max = maxVal,
      assert(minVal >= 0, 'minVal debe ser >= 0'),
      assert(maxVal >= minVal, 'maxVal debe ser >= minVal'),
      assert(maxVal <= 4, 'maxVal debe ser <= 4');

  /// ¿Es un rango (min != max)?
  bool get isRange => min != max;

  /// Formato legible para mostrar en UI
  /// - "2" si es valor único
  /// - "2 - 3" si es rango
  ///
  /// Nota: evitamos sufijos y decimales para mantener compatibilidad
  /// con pantallas que ya muestran "RIR" como etiqueta de campo.
  String get label => isRange ? '$min - $max' : '$min';

  /// Punto medio para cálculos internos (nunca para salida)
  double get midpoint => (min + max) / 2.0;

  /// Parsea un label de RIR desde string
  /// Soporta:
  /// - "3" (valor único)
  /// - "2-3" (rango con guion normal)
  /// - "2–3" (rango con en-dash)
  /// Si el label es inválido, retorna fallback conservador RirTarget.range(2, 3)
  static RirTarget parseLabel(String label) {
    if (label.isEmpty) {
      return const RirTarget.range(2, 3);
    }

    final trimmed = label.trim();

    // Intentar valor único
    final single = int.tryParse(trimmed);
    if (single != null) {
      if (single >= 0 && single <= 4) {
        return RirTarget.single(single);
      } else {
        return const RirTarget.range(2, 3);
      }
    }

    // Intentar rango (guion normal o en-dash)
    final parts = trimmed.split(RegExp(r'-|–')).map((s) => s.trim()).toList();
    if (parts.length == 2) {
      final minVal = int.tryParse(parts[0]);
      final maxVal = int.tryParse(parts[1]);
      if (minVal != null && maxVal != null) {
        if (minVal >= 0 && maxVal >= minVal && maxVal <= 4) {
          return RirTarget.range(minVal, maxVal);
        }
      }
    }

    // Fallback conservador
    return const RirTarget.range(2, 3);
  }

  @override
  String toString() => label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RirTarget &&
          runtimeType == other.runtimeType &&
          min == other.min &&
          max == other.max;

  @override
  int get hashCode => Object.hash(min, max);
}
