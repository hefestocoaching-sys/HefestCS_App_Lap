import 'package:hcs_app_lap/core/registry/muscle_registry.dart'
    as muscle_registry;

class MevTable {
  static Map<String, double> _mevByMuscle = <String, double>{};

  static void seed(Map<String, double> mevByMuscle) {
    final normalized = <String, double>{};
    mevByMuscle.forEach((key, value) {
      final muscle = muscle_registry.tryNormalizeMuscleKey(key);
      if (muscle == null) return;
      normalized[muscle] = value;
    });
    _mevByMuscle = normalized;
  }

  static double getMev(String muscle) {
    final key = muscle_registry.tryNormalizeMuscleKey(muscle);
    if (key == null) return 0.0;
    return _mevByMuscle[key] ?? 0.0;
  }
}
