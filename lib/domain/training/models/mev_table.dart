import 'package:hcs_app_lap/core/utils/muscle_key_normalizer.dart';

class MevTable {
  static Map<String, double> _mevByMuscle = <String, double>{};

  static void seed(Map<String, double> mevByMuscle) {
    final normalized = <String, double>{};
    mevByMuscle.forEach((key, value) {
      final muscle = normalizeMuscleKey(key);
      normalized[muscle] = value;
    });
    _mevByMuscle = normalized;
  }

  static double getMev(String muscle) {
    final key = normalizeMuscleKey(muscle);
    return _mevByMuscle[key] ?? 0.0;
  }
}