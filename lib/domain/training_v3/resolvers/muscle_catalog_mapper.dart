/// Mapeo canonico entre muscle IDs del motor y del catalogo JSON.
class MuscleCatalogMapper {
  /// Mapeo: Motor V3 muscle ID -> Catalog JSON muscle IDs.
  static const Map<String, List<String>> motorToCatalog = {
    'pectorals': ['pectorals'],
    'lats': ['lats'],
    'upper_back': ['upper_back'],
    'traps': ['traps'],
    'delts_front': ['delts_front'],
    'delts_lateral': ['delts_lateral'],
    'delts_rear': ['delts_rear'],
    'biceps': ['biceps'],
    'triceps': ['triceps'],
    'quads': ['quads'],
    'hamstrings': ['hamstrings'],
    'glutes': ['glutes'],
    'calves': ['calves'],
    'abs': ['abs'],
  };

  /// Convierte un muscle ID del motor V3 a IDs del catalogo JSON.
  static List<String> getCatalogIds(String motorMuscleId) {
    final catalogIds = motorToCatalog[motorMuscleId];
    if (catalogIds == null) {
      return [motorMuscleId];
    }
    return catalogIds;
  }

  /// Convierte multiples muscle IDs del motor a catalog IDs.
  static List<String> getCatalogIdsMultiple(List<String> motorMuscleIds) {
    return motorMuscleIds.expand((id) => getCatalogIds(id)).toSet().toList();
  }

  /// Verifica si un muscle ID del catalogo corresponde a un motor ID.
  static bool catalogIdMatchesMotor(String catalogId, String motorId) {
    final catalogIds = motorToCatalog[motorId];
    if (catalogIds == null) {
      return catalogId == motorId;
    }
    return catalogIds.contains(catalogId);
  }
}
