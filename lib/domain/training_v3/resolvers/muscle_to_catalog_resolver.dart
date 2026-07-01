import 'package:hcs_app_lap/core/registry/muscle_registry.dart'
    as muscle_registry;

enum MuscleGroup { chest, back, deltoids, arms, legs, glutes, calves, core }

/// Resolves the mapping between MuscleGroup (logical groups) and the exact
/// keys in exercise_catalog_gym.json.
///
/// Important: the V3 catalog uses canonical muscle keys directly.
/// Avoid expanding to legacy granular keys that no longer exist.
class MuscleToCatalogResolver {
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
    return muscle_registry.expandMuscleGroupStrict(canonicalMuscle) ??
        const <String>[];
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
  ///
  /// Legacy non-null wrapper: returns an empty string for unknown keys instead
  /// of passing raw input through.
  static String toCanonicalMuscle(String jsonKey) {
    return tryToCanonicalMuscle(jsonKey) ?? '';
  }

  /// Strict canonical conversion. Unknown keys return null.
  static String? tryToCanonicalMuscle(String jsonKey) {
    return muscle_registry.tryNormalizeMuscleKey(jsonKey);
  }
}
