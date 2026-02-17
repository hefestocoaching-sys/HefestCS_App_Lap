/// Motor V3 ↔ Catálogo V3 (exercise_catalog_gym.json)
/// Source of truth: las keys que EXISTEN en el JSON.
/// El catálogo V3 actual se normaliza a 14 claves canónicas.
/// Este adaptador mantiene compatibilidad con aliases legacy.
class MuscleKeyAdapterV3 {
  /// Normaliza input: trim + lower
  static String norm(String k) => k.trim().toLowerCase();

  /// Dado un muscleKey “macro” del motor, devuelve las keys reales del catálogo
  /// que deben consultarse.
  static List<String> toCatalogKeys(String motorKey) {
    final k = norm(motorKey);

    // Catálogo V3 actual (normalizado a canónicas):
    // calves, upper_back y traps existen como claves directas.
    switch (k) {
      case 'calves':
      case 'pantorrillas':
      case 'gemelos':
        return const ['calves'];

      case 'upper_back':
        return const ['upper_back'];

      case 'traps':
      case 'trapecios':
      case 'trapecio':
      case 'trapezius':
        return const ['traps'];

      // Mantener directo cuando ya coincide con el catálogo
      // (según logs: chest, lats, deltoide_*, biceps, triceps, quads, hamstrings, glutes, abs)
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
