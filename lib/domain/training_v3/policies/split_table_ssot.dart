import 'package:hcs_app_lap/core/registry/muscle_registry.dart';

/// Single Source of Truth for Split Logic and Muscle Groupings.
/// Defines priorities, conflicts, and standard combinations.
class SplitTableSSOT {
  /// Priority for distributing muscles (Higher = Distributed first).
  /// Primary muscles get first pick of days.
  static const Map<String, int> musclePriorities = {
    // Tier 1: Big Compound Movers (Primary)
    'pectorals': 2,
    'lats': 2,
    'quads': 2,
    'glutes': 2,
    'hamstrings': 2, // Often heavy
    'delts_front': 2, // Push primary
    // Tier 2: Secondary / Smaller Components
    'upper_back': 1,
    'delts_lateral': 1,
    'delts_rear': 1,
    'triceps': 1,
    'biceps': 1,

    // Tier 3: Accessories / Isolation preferred
    'traps': 0,
    'calves': 0,
    'abs': 0,
  };

  /// Returns the priority of a muscle (default 0).
  static int getPriority(String muscle) {
    final normalized = normalize(muscle);
    return musclePriorities[normalized] ?? 0;
  }

  /// Rules for which muscles should NOT be trained on consecutive days if possible.
  /// (Simplified for V3: same muscle recovery, but also functional interference)
  static bool hasInterference(String muscleA, String muscleB) {
    // TODO: Implement advanced interference logic if needed.
    // For now, checks equality.
    return muscleA == muscleB;
  }

  /// Recommended Pattern for 4-day Split (Upper/Lower).
  /// Used as a fallback or template guide.
  static const Map<String, List<String>> upperLowerTemplate = {
    'upper': [
      'pectorals',
      'lats',
      'upper_back',
      'delts_front',
      'delts_lateral',
      'delts_rear',
      'biceps',
      'triceps',
      'traps',
    ],
    'lower': ['quads', 'hamstrings', 'glutes', 'calves', 'abs'],
  };

  /// Recommended Pattern for 6-day Split (Push/Pull/Legs).
  static const Map<String, List<String>> pplTemplate = {
    'push': ['pectorals', 'delts_front', 'delts_lateral', 'triceps', 'abs'],
    'pull': ['lats', 'upper_back', 'delts_rear', 'biceps', 'traps'],
    'legs': ['quads', 'hamstrings', 'glutes', 'calves'],
  };

  /// Recommended Pattern for 5-day PPL hybrid split.
  /// Day 4 is a torso emphasis day, not an upper/lower fallback.
  static const Map<String, List<String>> ppl5Template = {
    'push': ['pectorals', 'delts_front', 'delts_lateral', 'triceps'],
    'pull': ['lats', 'upper_back', 'delts_rear', 'biceps', 'traps'],
    'legs_a': ['quads', 'hamstrings', 'glutes', 'calves'],
    'torso': [
      'pectorals',
      'lats',
      'upper_back',
      'traps',
      'delts_front',
      'delts_lateral',
      'delts_rear',
      'biceps',
      'triceps',
      'abs',
    ],
    'legs_b': ['quads', 'hamstrings', 'glutes', 'calves'],
  };

  /// Recommended Pattern for 6-day PPL split.
  static const Map<String, List<String>> ppl6Template = {
    'push_a': ['pectorals', 'delts_front', 'delts_lateral', 'triceps'],
    'pull_a': ['lats', 'upper_back', 'delts_rear', 'biceps', 'traps'],
    'legs_a': ['quads', 'hamstrings', 'glutes', 'calves'],
    'push_b': ['pectorals', 'delts_front', 'delts_lateral', 'triceps'],
    'pull_b': ['lats', 'upper_back', 'delts_rear', 'biceps', 'traps'],
    'legs_b': ['quads', 'hamstrings', 'glutes', 'calves'],
  };
}
