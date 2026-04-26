import 'package:hcs_app_lap/core/registry/muscle_registry.dart'
    as muscle_registry;

/// Política explícita de zonas de intensidad permitidas por músculo.
///
/// Regla base:
/// - Los músculos grandes conservan heavy + medium + light.
/// - Los músculos con cobertura heavy inconsistente o ausente se degradan a
///   medium + light para evitar asignaciones inválidas.
///
/// Nota de auditoría:
/// - lats se trata como no-heavy de forma conservadora porque en la ruta V3
///   actual hay contextos reales donde el catálogo no entrega cobertura heavy.
class MuscleIntensityPolicy {
  static const Set<String> allZones = {'heavy', 'medium', 'light'};
  static const Set<String> midLightOnly = {'medium', 'light'};
  static const Set<String> lightOnly = {'light'};

  static const Map<String, Set<String>> _allowedZonesByMuscle = {
    'pectorals': allZones,
    'lats': midLightOnly,
    'upper_back': allZones,
    'quads': allZones,
    'glutes': allZones,
    'hamstrings': allZones,
    'traps': midLightOnly,
    'biceps': midLightOnly,
    'triceps': midLightOnly,
    'delts_lateral': midLightOnly,
    'delts_rear': midLightOnly,
    'calves': midLightOnly,
    'abs': lightOnly,
  };

  static Set<String> allowedZonesForMuscle(String muscleKey) {
    final canonical =
        muscle_registry.normalize(muscleKey) ?? muscleKey.trim().toLowerCase();
    if (canonical.isEmpty) return allZones;
    return _allowedZonesByMuscle[canonical] ?? allZones;
  }

  static bool allowsZone(String muscleKey, String zone) {
    return allowedZonesForMuscle(muscleKey).contains(zone.trim().toLowerCase());
  }

  static Map<String, Set<String>> get policyByMuscle => _allowedZonesByMuscle;
}
