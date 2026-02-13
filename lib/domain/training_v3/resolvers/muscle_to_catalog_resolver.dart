enum MuscleGroup { chest, back, deltoids, arms, legs, glutes, calves, core }

/// Resolves the mapping between MuscleGroup (logical groups) and the exact
/// keys in exercise_catalog_gym.json.
///
/// Important: this resolver expands canonical muscles into JSON variants
/// (example: traps -> [traps_upper, traps_middle, traps_lower]).
class MuscleToCatalogResolver {
  static const Map<MuscleGroup, List<String>> _groupToKeysMap = {
    MuscleGroup.chest: ['pectorals'],

    MuscleGroup.back: [
      'lats',
      'upper_back',
      'traps_upper',
      'traps_middle',
      'traps_lower',
    ],

    MuscleGroup.deltoids: [
      'deltoide_anterior',
      'deltoide_lateral',
      'deltoide_posterior',
    ],

    MuscleGroup.arms: ['biceps', 'triceps'],

    MuscleGroup.legs: ['quadriceps', 'hamstrings'],

    MuscleGroup.glutes: ['glutes'],

    MuscleGroup.calves: ['gastrocnemio', 'soleo'],

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
    switch (canonicalMuscle) {
      case 'chest':
        return ['pectorals'];
      case 'lats':
        return ['lats'];
      case 'upper_back':
        return ['upper_back'];
      case 'traps':
        return ['traps_upper', 'traps_middle', 'traps_lower'];
      case 'deltoide_anterior':
        return ['deltoide_anterior'];
      case 'deltoide_lateral':
        return ['deltoide_lateral'];
      case 'deltoide_posterior':
        return ['deltoide_posterior'];
      case 'biceps':
        return ['biceps'];
      case 'triceps':
        return ['triceps'];
      case 'quads':
        return ['quadriceps'];
      case 'hamstrings':
        return ['hamstrings'];
      case 'glutes':
        return ['glutes'];
      case 'calves':
        return ['gastrocnemio', 'soleo'];
      case 'abs':
        return ['abs'];
      default:
        return [canonicalMuscle];
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
    if (jsonKey == 'pectorals') return 'chest';
    if (jsonKey.startsWith('traps_')) return 'traps';
    if (jsonKey == 'quadriceps') return 'quads';
    if (jsonKey == 'gastrocnemio' || jsonKey == 'soleo') return 'calves';
    return jsonKey;
  }
}
