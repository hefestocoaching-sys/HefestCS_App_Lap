/// Motor V3 <-> Catalogo V3 (exercise_catalog_gym.json)
///
/// MAPEO DE SINGLE SOURCE OF TRUTH (SSOT):
/// Las 14 claves canonicas del motor son las unicas claves operativas.
///
/// Las variantes legacy se aceptan solo como entrada y siempre se
/// convierten al canon interno.
///
/// MAPEOS DIRECTOS (1:1):
/// - pectorals -> ['pectorals']
/// - lats -> ['lats']
/// - upper_back -> ['upper_back']
/// - delts_front -> ['deltoide_anterior']
/// - delts_lateral -> ['deltoide_lateral']
/// - delts_rear -> ['deltoide_posterior']
/// - biceps -> ['biceps']
/// - triceps -> ['triceps']
/// - quads -> ['quadriceps']
/// - hamstrings -> ['hamstrings']
/// - glutes -> ['glutes']
/// - abs -> ['abs']
class MuscleKeyAdapterV3 {
  /// Normaliza input: trim + lower
  static String norm(String k) => k.trim().toLowerCase();

  /// Dado un muscleKey "canonico" del motor (una de las 14 claves), devuelve
  /// la/s key/s canonicas que deben consultarse.
  ///
  /// GARANTIA: Siempre retorna claves canónicas del motor V3.
  static List<String> toCatalogKeys(String motorKey) {
    final k = norm(motorKey);

    return switch (k) {
      // === MAPEOS DIRECTOS (1:1) ===
      'pectorals' => const ['pectorals'],
      'chest' => const ['pectorals'],
      'lats' => const ['lats'],
      'upper_back' => const ['upper_back'],
      'delts_front' => const ['delts_front'],
      'deltoide_anterior' => const ['delts_front'],
      'delts_lateral' => const ['delts_lateral'],
      'deltoide_lateral' => const ['delts_lateral'],
      'delts_rear' => const ['delts_rear'],
      'deltoide_posterior' => const ['delts_rear'],
      'biceps' => const ['biceps'],
      'triceps' => const ['triceps'],
      'quads' => const ['quads'],
      'quadriceps' => const ['quads'],
      'hamstrings' => const ['hamstrings'],
      'glutes' => const ['glutes'],
      'abs' => const ['abs'],

      // === MAPEOS ESPECIALES (alias de entrada) ===
      'traps' => const ['traps'],
      'traps_upper' => const ['traps'],
      'gastrocnemio' => const ['calves'],
      'soleo' => const ['calves'],
      'calves' => const ['calves'],
      'back' => const ['lats', 'upper_back'],

      // === FALLBACK ===
      _ => [k],
    };
  }

  /// Para logs/debug: agrupa keys granulares hacia un nombre "macro" amigable.
  /// Nota: NO es obligatorio para funcionalidad, solo para debugging.
  static String toMacroKey(String catalogKey) {
    final k = norm(catalogKey);

    if (k == 'traps_upper') {
      return 'traps';
    }
    if (k == 'quadriceps') {
      return 'quads';
    }
    if (k == 'deltoide_anterior') {
      return 'delts_front';
    }
    if (k == 'deltoide_lateral') {
      return 'delts_lateral';
    }
    if (k == 'deltoide_posterior') {
      return 'delts_rear';
    }
    if (k == 'gastrocnemio' || k == 'soleo') {
      return 'calves';
    }

    return k;
  }
}
