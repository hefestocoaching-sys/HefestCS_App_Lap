import 'package:hcs_app_lap/core/registry/muscle_registry.dart'
    as muscle_registry;

/// Contrato formal Fase 2 para zonas de carga por tamaño muscular.
///
/// Reglas:
/// - small -> medium + light
/// - large -> heavy + medium + light
class MuscleSizeIntensityPolicy {
  static const Set<String> _largeMuscles = {
    'pectorals',
    'lats',
    'upper_back',
    'quads',
    'hamstrings',
    'glutes',
  };

  static const Set<String> _smallMuscles = {
    'traps',
    'delts_front',
    'delts_lateral',
    'delts_rear',
    'biceps',
    'triceps',
    'calves',
    'abs',
  };

  static const Set<String> _smallAllowed = {'medium', 'light'};
  static const Set<String> _largeAllowed = {'heavy', 'medium', 'light'};

  static Set<String> allowedZonesForMuscle(String muscleKey) {
    final canonical = muscle_registry.normalize(muscleKey);
    if (canonical == null) {
      return _largeAllowed;
    }
    if (_largeMuscles.contains(canonical)) {
      return _largeAllowed;
    }
    if (_smallMuscles.contains(canonical)) {
      return _smallAllowed;
    }
    return _largeAllowed;
  }

  static bool isSmallMuscle(String muscleKey) {
    final canonical = muscle_registry.normalize(muscleKey);
    return canonical != null && _smallMuscles.contains(canonical);
  }

  static bool isLargeMuscle(String muscleKey) {
    final canonical = muscle_registry.normalize(muscleKey);
    return canonical != null && _largeMuscles.contains(canonical);
  }
}
