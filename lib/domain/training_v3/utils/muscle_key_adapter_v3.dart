// Motor V3 <-> Catalogo V3 runtime
// assets/data/training_v3/catalog/exercise_catalog_v3_runtime.json
//
// MAPEO DE SINGLE SOURCE OF TRUTH (SSOT):
// Las 14 claves canonicas del motor son las unicas claves operativas.
//
// Las variantes legacy se aceptan solo como entrada y siempre se
// convierten al canon interno.
//
// MAPEOS DIRECTOS (1:1):
// - pectorals -> ['pectorals']
// - lats -> ['lats']
// - upper_back -> ['upper_back']
// - delts_front -> ['delts_front']
// - delts_lateral -> ['delts_lateral']
// - delts_rear -> ['delts_rear']
// - biceps -> ['biceps']
// - triceps -> ['triceps']
// - quads -> ['quads']
// - hamstrings -> ['hamstrings']
// - glutes -> ['glutes']
// - abs -> ['abs']
import 'package:hcs_app_lap/core/registry/muscle_registry.dart'
    as muscle_registry;

class MuscleKeyAdapterV3 {
  /// Normaliza input: trim + lower
  static String norm(String k) => k.trim().toLowerCase();

  /// Dado un muscleKey "canonico" del motor (una de las 14 claves), devuelve
  /// la/s key/s canonicas que deben consultarse.
  ///
  /// GARANTIA: Siempre retorna claves canónicas del motor V3.
  static List<String> toCatalogKeys(String motorKey) {
    return toCatalogKeysStrict(motorKey);
  }

  /// Strict catalog conversion. Unknown keys return an empty list.
  static List<String> toCatalogKeysStrict(String motorKey) {
    final legacy = _legacySpecialCatalogKeys(motorKey);
    if (legacy != null) return legacy;

    return muscle_registry.expandMuscleGroupStrict(motorKey) ??
        const <String>[];
  }

  /// Para logs/debug: agrupa keys granulares hacia un nombre "macro" amigable.
  /// Nota: NO es obligatorio para funcionalidad, solo para debugging.
  static String toMacroKey(String catalogKey) {
    return tryToMacroKey(catalogKey) ?? '';
  }

  /// Strict macro conversion. Unknown keys return null.
  static String? tryToMacroKey(String catalogKey) {
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

    return muscle_registry.tryNormalizeMuscleKey(k);
  }

  static List<String>? _legacySpecialCatalogKeys(String motorKey) {
    final k = norm(motorKey);
    return switch (k) {
      'traps_upper' => const ['traps'],
      _ => null,
    };
  }
}
