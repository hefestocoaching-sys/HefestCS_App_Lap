/// SSOT: 14 Músculos Canónicos Basados en Evidencia Científica
///
/// Fuente: docs/scientific-foundation/01-volume.md (Schoenfeld et al. 2017)
///
/// Validación: Este archivo DEBE contener exactamente 14 constantes
/// correspondientes a los músculos validados científicamente.
///
/// NO AÑADIR claves genéricas como 'back' o 'shoulders' a la lista canónica.
/// Usar claves anatómicas específicas (lats, traps, upper_back, deltoide_*).
class MuscleKeys {
  // ═══════════════════════════════════════════════════════════════
  // TORSO SUPERIOR (7 músculos)
  // ═══════════════════════════════════════════════════════════════
  static const pectorals = 'pectorals';
  static const lats = 'lats';
  static const upperBack = 'upper_back';
  static const traps = 'traps';
  static const deltsFront = 'delts_front';
  static const deltsLateral = 'delts_lateral';
  static const deltsRear = 'delts_rear';

  // ═══════════════════════════════════════════════════════════════
  // BRAZOS (2 músculos)
  // ═══════════════════════════════════════════════════════════════
  static const biceps = 'biceps';
  static const triceps = 'triceps';

  // ═══════════════════════════════════════════════════════════════
  // PIERNAS (4 músculos)
  // ═══════════════════════════════════════════════════════════════
  static const quads = 'quads';
  static const hamstrings = 'hamstrings';
  static const glutes = 'glutes';
  static const calves = 'calves';

  // ═══════════════════════════════════════════════════════════════
  // CORE (1 músculo)
  // ═══════════════════════════════════════════════════════════════
  static const abs = 'abs';

  // Compatibilidad legacy (NO canónico, solo para mapeo UI/normalización)
  static const back = 'back'; // Se expande a: lats + upper_back
  static const shoulders = 'shoulders'; // Se expande a: deltoide_*

  /// Lista canónica de TODOS los músculos (SSOT)
  /// Total: 14 músculos individuales
  static const all = <String>{
    // Torso superior (7)
    pectorals,
    lats,
    'upper_back',
    traps,
    'delts_front',
    'delts_lateral',
    'delts_rear',
    // Brazos (2)
    biceps,
    triceps,
    // Piernas (4)
    quads,
    hamstrings,
    glutes,
    calves,
    // Core (1)
    abs,
  };

  /// Valida si una key es canónica (14 músculos individuales)
  static bool isCanonical(String k) => all.contains(k);

  /// Validación estricta: DEBE ser exactamente 14 músculos
  ///
  /// Si este assert falla, significa que se violó el SSOT.
  /// Revisar documentación científica antes de modificar.
  static void validate() {
    assert(
      all.length == 14,
      '🚨 SSOT VIOLATION 🚨\n'
      'MuscleKeys.all debe contener EXACTAMENTE 14 músculos canónicos.\n'
      'Actual: ${all.length}\n'
      'Músculos: $all\n'
      'Ver docs/scientific-foundation/01-volume.md para evidencia científica.',
    );
  }

  /// Expande un grupo a músculos canónicos
  static Set<String> expandGroup(String groupName) {
    switch (groupName) {
      case 'back_group':
        return const {'lats', 'upper_back'};
      case 'shoulders_group':
        return const {'delts_front', 'delts_lateral', 'delts_rear'};
      case 'legs_group':
        return const {'quads', 'hamstrings', 'glutes', 'calves'};
      case 'arms_group':
        return const {'biceps', 'triceps'};
      default:
        return const {};
    }
  }

  // Alias legacy para compatibilidad
  static const chest = pectorals;
  static const deltoideAnterior = deltsFront;
  static const deltoideLateral = deltsLateral;
  static const deltoidePosterior = deltsRear;
  static const quadriceps = quads;

  const MuscleKeys._();
}
