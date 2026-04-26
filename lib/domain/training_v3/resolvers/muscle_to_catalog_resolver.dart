enum MuscleGroup { chest, back, deltoids, arms, legs, glutes, calves, core }

/// Resolves the mapping between MuscleGroup (logical groups) and the exact
/// keys in exercise_catalog_gym.json.
///
/// Important: the V3 catalog uses canonical muscle keys directly.
/// Avoid expanding to legacy granular keys that no longer exist.
class MuscleToCatalogResolver {
  static const Map<String, String> _legacyToCanonical = {
    'chest': 'pectorals',
    'quadriceps': 'quads',
    'deltoide_anterior': 'delts_front',
    'deltoide_lateral': 'delts_lateral',
    'deltoide_posterior': 'delts_rear',
  };

  static const Map<MuscleGroup, List<String>> _groupToKeysMap = {
    MuscleGroup.chest: ['pectorals'],

    MuscleGroup.back: ['lats', 'upper_back', 'traps'],

    MuscleGroup.deltoids: ['delts_front', 'delts_lateral', 'delts_rear'],

    MuscleGroup.arms: ['biceps', 'triceps'],

    MuscleGroup.legs: ['quads', 'hamstrings'],

    MuscleGroup.glutes: ['glutes'],

    MuscleGroup.calves: ['calves'],

    MuscleGroup.core: ['abs'],
  };

  /// Resolves a MuscleGroup to its JSON keys.
  static List<String> resolveGroup(MuscleGroup group) {
    return _groupToKeysMap[group] ?? [];
  }

  /// Backward-compatible alias for existing call sites.
  static List<String> resolve(MuscleGroup group) => resolveGroup(group);

  /// Expands a canonical muscle to its JSON keys.
  static List<String> expandMuscleKey(String canonicalMuscle) {
    final normalized = _toCanonical(canonicalMuscle);

    switch (normalized) {
      case 'pectorals':
        return ['pectorals'];
      case 'lats':
        return ['lats'];
      case 'upper_back':
        return ['upper_back'];
      case 'traps':
        return ['traps'];
      case 'delts_front':
        return ['delts_front'];
      case 'delts_lateral':
        return ['delts_lateral'];
      case 'delts_rear':
        return ['delts_rear'];
      case 'biceps':
        return ['biceps'];
      case 'triceps':
        return ['triceps'];
      case 'quads':
        return ['quads'];
      case 'hamstrings':
        return ['hamstrings'];
      case 'glutes':
        return ['glutes'];
      case 'calves':
        return ['calves'];
      case 'abs':
        return ['abs'];
      default:
        return [normalized];
    }
  }

  /// Expands multiple canonical muscles to JSON keys.
  static List<String> expandMuscleKeys(List<String> canonicalMuscles) {
    final expanded = <String>[];
    for (final muscle in canonicalMuscles) {
      expanded.addAll(expandMuscleKey(muscle));
    }
    return expanded.toSet().toList();
  }

  /// Converts a JSON key to its canonical muscle (for logging).
  static String toCanonicalMuscle(String jsonKey) {
    return _toCanonical(jsonKey);
  }

  static String _toCanonical(String key) {
    final normalized = key.trim().toLowerCase();
    return _legacyToCanonical[normalized] ?? normalized;
  }
}
