class EquivalentDefinition {
  final String id; // ej. aoa_bajo_grasa
  final String group; // ej. alimentos_origen_animal
  final String subgroup; // ej. bajo_aporte_grasa
  final double kcal; // por equivalente
  final double proteinG; // gramos proteína
  final double fatG; // gramos grasas
  final double carbG; // gramos carbohidratos

  const EquivalentDefinition({
    required this.id,
    required this.group,
    required this.subgroup,
    required this.kcal,
    required this.proteinG,
    required this.fatG,
    required this.carbG,
  });

  /// Macro llave por grupo (para cálculo de conversión)
  /// AOA → proteína | Cereales/Frutas → carbohidratos | Grasas → lípidos
  String get keyMacroForGroup {
    switch (group.toLowerCase()) {
      case 'aoa':
        return 'protein';
      case 'cereales_tuberculos':
      case 'frutas':
      case 'vegetales':
      case 'leguminosas':
      case 'azucares':
      case 'leches':
        return 'carbs';
      case 'grasas':
        return 'fat';
      default:
        return 'protein';
    }
  }
}

/// Catálogo estático v1 de equivalentes
/// Basado en SMAE + nomenclatura SSOT canónica
class EquivalentCatalog {
  static const List<EquivalentDefinition> v1Definitions = [
    // Datos sincronizados con assets/data/equivalents_v1.json
    EquivalentDefinition(
      id: 'vegetales',
      group: 'vegetales',
      subgroup: 'general',
      kcal: 25.0,
      proteinG: 2.0,
      fatG: 0.0,
      carbG: 4.0,
    ),
    EquivalentDefinition(
      id: 'frutas',
      group: 'frutas',
      subgroup: 'general',
      kcal: 60.0,
      proteinG: 0.0,
      fatG: 0.0,
      carbG: 15.0,
    ),
    EquivalentDefinition(
      id: 'cereales_sin_grasa',
      group: 'cereales_tuberculos',
      subgroup: 'sin_grasa',
      kcal: 70.0,
      proteinG: 2.0,
      fatG: 0.0,
      carbG: 15.0,
    ),
    EquivalentDefinition(
      id: 'cereales_con_grasa',
      group: 'cereales_tuberculos',
      subgroup: 'con_grasa',
      kcal: 115.0,
      proteinG: 2.0,
      fatG: 5.0,
      carbG: 15.0,
    ),
    EquivalentDefinition(
      id: 'leguminosas',
      group: 'leguminosas',
      subgroup: 'general',
      kcal: 120.0,
      proteinG: 8.0,
      fatG: 1.0,
      carbG: 20.0,
    ),
    EquivalentDefinition(
      id: 'aoa_muy_bajo',
      group: 'aoa',
      subgroup: 'muy_bajo',
      kcal: 40.0,
      proteinG: 7.0,
      fatG: 1.0,
      carbG: 0.0,
    ),
    EquivalentDefinition(
      id: 'aoa_bajo',
      group: 'aoa',
      subgroup: 'bajo',
      kcal: 55.0,
      proteinG: 7.0,
      fatG: 3.0,
      carbG: 0.0,
    ),
    EquivalentDefinition(
      id: 'aoa_moderado',
      group: 'aoa',
      subgroup: 'moderado',
      kcal: 75.0,
      proteinG: 7.0,
      fatG: 5.0,
      carbG: 0.0,
    ),
    EquivalentDefinition(
      id: 'aoa_alto',
      group: 'aoa',
      subgroup: 'alto',
      kcal: 100.0,
      proteinG: 7.0,
      fatG: 8.0,
      carbG: 0.0,
    ),
    EquivalentDefinition(
      id: 'leche_descremada',
      group: 'leches',
      subgroup: 'descremada',
      kcal: 95.0,
      proteinG: 9.0,
      fatG: 2.0,
      carbG: 12.0,
    ),
    EquivalentDefinition(
      id: 'leche_semidescremada',
      group: 'leches',
      subgroup: 'semidescremada',
      kcal: 110.0,
      proteinG: 9.0,
      fatG: 4.0,
      carbG: 12.0,
    ),
    EquivalentDefinition(
      id: 'leche_entera',
      group: 'leches',
      subgroup: 'entera',
      kcal: 150.0,
      proteinG: 8.0,
      fatG: 8.0,
      carbG: 12.0,
    ),
    EquivalentDefinition(
      id: 'grasas_sin_proteina',
      group: 'grasas',
      subgroup: 'sin_proteina',
      kcal: 45.0,
      proteinG: 0.0,
      fatG: 5.0,
      carbG: 0.0,
    ),
    EquivalentDefinition(
      id: 'grasas_con_proteina',
      group: 'grasas',
      subgroup: 'con_proteina',
      kcal: 70.0,
      proteinG: 3.0,
      fatG: 5.0,
      carbG: 3.0,
    ),
    EquivalentDefinition(
      id: 'azucares_sin_grasa',
      group: 'azucares',
      subgroup: 'sin_grasa',
      kcal: 40.0,
      proteinG: 0.0,
      fatG: 0.0,
      carbG: 10.0,
    ),
    EquivalentDefinition(
      id: 'azucares_con_grasa',
      group: 'azucares',
      subgroup: 'con_grasa',
      kcal: 85.0,
      proteinG: 0.0,
      fatG: 5.0,
      carbG: 10.0,
    ),
    EquivalentDefinition(
      id: 'libres_energia',
      group: 'libres',
      subgroup: 'energia',
      kcal: 0.0,
      proteinG: 0.0,
      fatG: 0.0,
      carbG: 0.0,
    ),
    EquivalentDefinition(
      id: 'alcohol',
      group: 'alcohol',
      subgroup: 'general',
      kcal: 140.0,
      proteinG: 0.0,
      fatG: 0.0,
      carbG: 0.0,
    ),
  ];

  /// Buscar definición por ID
  static EquivalentDefinition? findById(String id) {
    try {
      return v1Definitions.firstWhere((def) => def.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Buscar definiciones por grupo
  static List<EquivalentDefinition> findByGroup(String group) {
    return v1Definitions
        .where((def) => def.group.toLowerCase() == group.toLowerCase())
        .toList();
  }

  /// Obtener todos los IDs disponibles
  static List<String> getAllIds() {
    return v1Definitions.map((def) => def.id).toList();
  }
}
