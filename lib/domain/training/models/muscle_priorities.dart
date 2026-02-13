/// Model for managing priorities of the 14 canonical muscles.
///
/// This model is the SSOT (Single Source of Truth) for muscle priorities.
/// Each muscle has a value from 1 (min) to 5 (max).
class MusclePriorities {
  /// The 14 canonical muscles in the system.
  static const List<String> canonicalMuscles = [
    'chest',
    'lats',
    'upper_back',
    'traps',
    'deltoide_anterior',
    'deltoide_lateral',
    'deltoide_posterior',
    'biceps',
    'triceps',
    'quads',
    'hamstrings',
    'glutes',
    'calves',
    'abs',
  ];

  /// Priority map (1-5 for each muscle).
  /// Default value: 3 (medium priority).
  final Map<String, int> values;

  MusclePriorities({Map<String, int>? initialValues})
    : values = _initializeValues(initialValues);

  /// Initializes all 14 muscles with default value 3.
  static Map<String, int> _initializeValues(Map<String, int>? initial) {
    final defaults = <String, int>{};
    for (final muscle in canonicalMuscles) {
      defaults[muscle] = 3;
    }

    if (initial != null) {
      defaults.addAll(initial);
    }

    return defaults;
  }

  /// Returns the priority for a muscle (defaults to 3).
  int get(String muscle) => values[muscle] ?? 3;

  /// Sets the priority for a muscle (validates 1-5).
  void set(String muscle, int priority) {
    if (!canonicalMuscles.contains(muscle)) {
      throw ArgumentError(
        'Invalid muscle: $muscle. Must be one of: $canonicalMuscles',
      );
    }
    if (priority < 1 || priority > 5) {
      throw ArgumentError('Priority must be between 1 and 5, got: $priority');
    }
    values[muscle] = priority;
  }

  /// Returns muscles sorted by priority (highest to lowest).
  List<String> getSortedByPriority() {
    final sorted = canonicalMuscles.toList();
    sorted.sort((a, b) => get(b).compareTo(get(a)));
    return sorted;
  }

  /// Returns muscles with priority >= threshold.
  List<String> getMusclesWithPriority(int threshold) {
    return canonicalMuscles.where((m) => get(m) >= threshold).toList();
  }

  /// Converts to Map for serialization.
  Map<String, dynamic> toJson() {
    return {'priorities': values};
  }

  /// Creates from deserialized Map.
  factory MusclePriorities.fromJson(Map<String, dynamic> json) {
    final priorities = (json['priorities'] as Map<String, dynamic>?)?.map(
      (k, v) => MapEntry(k, v as int),
    );
    return MusclePriorities(initialValues: priorities);
  }

  /// Creates from legacy lists (Primary/Secondary/Tertiary).
  factory MusclePriorities.fromLegacyLists({
    required String primaryString,
    required String secondaryString,
    required String tertiaryString,
  }) {
    final priorities = <String, int>{};

    final primary = primaryString.split(',').where((s) => s.trim().isNotEmpty);
    for (final muscle in primary) {
      final normalized = muscle.trim();
      if (canonicalMuscles.contains(normalized)) {
        priorities[normalized] = 5;
      }
    }

    final secondary = secondaryString
        .split(',')
        .where((s) => s.trim().isNotEmpty);
    for (final muscle in secondary) {
      final normalized = muscle.trim();
      if (canonicalMuscles.contains(normalized)) {
        priorities[normalized] = 3;
      }
    }

    final tertiary = tertiaryString
        .split(',')
        .where((s) => s.trim().isNotEmpty);
    for (final muscle in tertiary) {
      final normalized = muscle.trim();
      if (canonicalMuscles.contains(normalized)) {
        priorities[normalized] = 1;
      }
    }

    return MusclePriorities(initialValues: priorities);
  }

  /// Copy with updates.
  MusclePriorities copyWith(Map<String, int> updates) {
    final newValues = Map<String, int>.from(values);
    newValues.addAll(updates);
    return MusclePriorities(initialValues: newValues);
  }

  @override
  String toString() {
    final buffer = StringBuffer('MusclePriorities:\n');
    for (final muscle in canonicalMuscles) {
      buffer.writeln('  $muscle: ${get(muscle)}');
    }
    return buffer.toString();
  }
}
