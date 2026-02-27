/// Motor V3 <-> Catalogo V3 (exercise_catalog_gym.json)
/// 
/// MAPEO DE SINGLE SOURCE OF TRUTH (SSOT):
/// Las 14 claves canonicas del motor se mapean a las claves REALES del JSON.
///
/// MAPEOS CRITICOS (mismatch de motor -> catalog):
/// - traps (motor) -> ['traps_upper'] (catalog)
/// - calves (motor) -> ['gastrocnemio', 'soleo'] (catalog, granular)
///
/// MAPEOS DIRECTOS (1:1):
/// - pectorals -> ['pectorals']
/// - lats -> ['lats']
/// - upper_back -> ['upper_back']
/// - deltoide_anterior -> ['deltoide_anterior']
/// - deltoide_lateral -> ['deltoide_lateral']
/// - deltoide_posterior -> ['deltoide_posterior']
/// - biceps -> ['biceps']
/// - triceps -> ['triceps']
/// - quadriceps -> ['quadriceps']
/// - hamstrings -> ['hamstrings']
/// - glutes -> ['glutes']
/// - abs -> ['abs']
class MuscleKeyAdapterV3 {
  /// Normaliza input: trim + lower
  static String norm(String k) => k.trim().toLowerCase();

  /// Dado un muscleKey "canonico" del motor (una de las 14 claves), devuelve
  /// las keys REALES del catalogo JSON que deben consultarse.
  ///
  /// GARANTIA: Siempre retorna keys que existen en exercise_catalog_gym.json
  /// bajo el campo primaryMuscles.
  static List<String> toCatalogKeys(String motorKey) {
    final k = norm(motorKey);

    return switch (k) {
      // === MAPEOS DIRECTOS (1:1) ===
      'pectorals' => const ['pectorals'],
      'lats' => const ['lats'],
      'upper_back' => const ['upper_back'],
      'deltoide_anterior' => const ['deltoide_anterior'],
      'deltoide_lateral' => const ['deltoide_lateral'],
      'deltoide_posterior' => const ['deltoide_posterior'],
      'biceps' => const ['biceps'],
      'triceps' => const ['triceps'],
      'quadriceps' => const ['quadriceps'],
      'hamstrings' => const ['hamstrings'],
      'glutes' => const ['glutes'],
      'abs' => const ['abs'],

      // === MAPEOS ESPECIALES (motor -> catalog con transformacion) ===
      // Trapecio: motor solo usa 'traps', pero JSON tiene 'traps_upper/middle/lower'
      'traps' => const ['traps_upper'],

      // Pantorrillas: motor usa 'calves', JSON tiene 'gastrocnemio' y 'soleo'
      'calves' => const ['gastrocnemio', 'soleo'],

      // === FALLBACK ===
      _ => [k],
    };
  }

  /// Para logs/debug: agrupa keys granulares hacia un nombre "macro" amigable.
  /// Nota: NO es obligatorio para funcionalidad, solo para debugging.
  static String toMacroKey(String catalogKey) {
    final k = norm(catalogKey);

    if (k == 'gastrocnemio' || k == 'soleo') {
      return 'calves';
    }
    if (k.startsWith('traps_')) {
      return 'traps';
    }

    return k;
  }
}
