import 'package:hcs_app_lap/core/utils/muscle_key_normalizer.dart';

class AntagonistPairingEngine {
  static bool areAntagonists(String a, String b) {
    final left = _normalize(a);
    final right = _normalize(b);

    const pairs = <String, Set<String>>{
      'pectorals': {'lats', 'upper_back'},
      'lats': {'pectorals'},
      'upper_back': {'pectorals'},
      'biceps': {'triceps'},
      'triceps': {'biceps'},
      'quads': {'hamstrings'},
      'hamstrings': {'quads'},
    };

    return pairs[left]?.contains(right) ?? false;
  }

  static String _normalize(String key) {
    final normalized = normalizeMuscleKey(key);
    if (normalized == 'traps_upper') {
      return 'traps';
    }
    return normalized;
  }
}
