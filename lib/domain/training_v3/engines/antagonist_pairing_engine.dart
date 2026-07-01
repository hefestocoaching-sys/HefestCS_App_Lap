import 'package:hcs_app_lap/core/registry/muscle_registry.dart'
    as muscle_registry;

class AntagonistPairingEngine {
  static const Map<String, Set<String>> _pairs = {
    'pectorals': {'lats', 'upper_back'},
    'lats': {'pectorals'},
    'upper_back': {'pectorals'},
    'biceps': {'triceps'},
    'triceps': {'biceps'},
    'quads': {'hamstrings'},
    'hamstrings': {'quads'},
  };

  static bool areAntagonists(String a, String b) {
    final leftMuscles = _resolveMusclesStrict(a);
    final rightMuscles = _resolveMusclesStrict(b);

    if (leftMuscles.isEmpty || rightMuscles.isEmpty) {
      return false;
    }

    for (final left in leftMuscles) {
      for (final right in rightMuscles) {
        if (_pairs[left]?.contains(right) ?? false) {
          return true;
        }
      }
    }

    return false;
  }

  static List<String> _resolveMusclesStrict(String raw) {
    final canonical = muscle_registry.tryNormalizeMuscleKey(raw);
    if (canonical != null) {
      return [canonical];
    }

    final expanded = muscle_registry.expandMuscleGroupStrict(raw);
    if (expanded != null) {
      return expanded;
    }

    return const [];
  }
}
