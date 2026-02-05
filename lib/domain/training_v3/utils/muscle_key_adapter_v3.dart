/// Motor V3 ↔ Catálogo V3 (exercise_catalog_gym.json)
/// Source of truth: las keys que EXISTEN en el JSON.
/// Este adaptador permite que el motor use macros (calves, traps)
/// y el catálogo use keys granulares (gastrocnemio/soleo, traps_upper/middle/lower).
class MuscleKeyAdapterV3 {
  /// Normaliza input: trim + lower
  static String norm(String k) => k.trim().toLowerCase();

  /// Dado un muscleKey “macro” del motor, devuelve las keys reales del catálogo
  /// que deben consultarse.
  static List<String> toCatalogKeys(String motorKey) {
    final k = norm(motorKey);

    // Catálogo real (confirmado por JSON):
    // calves NO existe -> gastrocnemio + soleo
    // traps NO existe -> traps_upper + traps_middle + traps_lower
    switch (k) {
      case 'calves':
      case 'pantorrillas':
      case 'gemelos':
        return const ['gastrocnemio', 'soleo'];

      case 'traps':
      case 'trapecios':
      case 'trapecio':
      case 'trapezius':
        return const ['traps_upper', 'traps_middle', 'traps_lower'];

      // Mantener directo cuando ya coincide con el catálogo
      // (según logs: chest, lats, upper_back, deltoide_*, biceps, triceps, quads, hamstrings, glutes, abs)
      default:
        return [k];
    }
  }

  /// Para logs/debug: agrupa keys granulares hacia una macro “amigable”
  /// (solo donde aplica). NO es obligatorio para funcionalidad, pero ayuda.
  static String toMacroKey(String catalogKey) {
    final k = norm(catalogKey);
    if (k == 'gastrocnemio' || k == 'soleo') return 'calves';
    if (k.startsWith('traps_')) return 'traps';
    return k;
  }
}
