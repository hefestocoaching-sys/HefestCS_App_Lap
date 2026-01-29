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
      case 'alimentos_origen_animal':
        return 'protein';
      case 'cereales':
      case 'frutas':
      case 'verduras':
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
    // ═══════════════════════════════════════════════════════════════════════
    // ALIMENTOS DE ORIGEN ANIMAL (AOA) - Protein llave
    // ═══════════════════════════════════════════════════════════════════════

    /// AOA Bajo aporte grasa (~7g proteína, ~1.5g grasa)
    EquivalentDefinition(
      id: 'aoa_bajo_grasa',
      group: 'alimentos_origen_animal',
      subgroup: 'bajo_aporte_grasa',
      kcal: 35.0,
      proteinG: 7.0,
      fatG: 1.5,
      carbG: 0.0,
    ),

    /// AOA Medio aporte grasa (~7g proteína, ~5g grasa)
    EquivalentDefinition(
      id: 'aoa_medio_grasa',
      group: 'alimentos_origen_animal',
      subgroup: 'medio_aporte_grasa',
      kcal: 60.0,
      proteinG: 7.0,
      fatG: 5.0,
      carbG: 0.0,
    ),

    /// AOA Alto aporte grasa (~7g proteína, ~8g grasa)
    EquivalentDefinition(
      id: 'aoa_alto_grasa',
      group: 'alimentos_origen_animal',
      subgroup: 'alto_aporte_grasa',
      kcal: 100.0,
      proteinG: 7.0,
      fatG: 8.0,
      carbG: 0.0,
    ),

    // ═══════════════════════════════════════════════════════════════════════
    // CEREALES - Carbs llave
    // ═══════════════════════════════════════════════════════════════════════

    /// Cereales sin grasa (~15g carbs, ~3g proteína)
    EquivalentDefinition(
      id: 'cereal_sin_grasa',
      group: 'cereales',
      subgroup: 'sin_grasa',
      kcal: 68.0,
      proteinG: 3.0,
      fatG: 0.5,
      carbG: 15.0,
    ),

    /// Cereales con grasa (~15g carbs, ~3g proteína, ~5g grasa)
    EquivalentDefinition(
      id: 'cereal_con_grasa',
      group: 'cereales',
      subgroup: 'con_grasa',
      kcal: 125.0,
      proteinG: 3.0,
      fatG: 5.0,
      carbG: 15.0,
    ),

    // ═══════════════════════════════════════════════════════════════════════
    // FRUTAS - Carbs llave
    // ═══════════════════════════════════════════════════════════════════════

    /// Frutas (~15g carbs, ~0.5g proteína)
    EquivalentDefinition(
      id: 'fruta_standard',
      group: 'frutas',
      subgroup: 'standard',
      kcal: 60.0,
      proteinG: 0.5,
      fatG: 0.2,
      carbG: 15.0,
    ),

    // ═══════════════════════════════════════════════════════════════════════
    // VERDURAS - Carbs llave
    // ═══════════════════════════════════════════════════════════════════════

    /// Verduras (~5g carbs, ~2g proteína) - porción generosa
    EquivalentDefinition(
      id: 'verdura_standard',
      group: 'verduras',
      subgroup: 'standard',
      kcal: 25.0,
      proteinG: 2.0,
      fatG: 0.2,
      carbG: 5.0,
    ),

    // ═══════════════════════════════════════════════════════════════════════
    // GRASAS - Fat llave
    // ═══════════════════════════════════════════════════════════════════════

    /// Grasa (~5g grasa)
    EquivalentDefinition(
      id: 'grasa_standard',
      group: 'grasas',
      subgroup: 'standard',
      kcal: 45.0,
      proteinG: 0.0,
      fatG: 5.0,
      carbG: 0.0,
    ),

    // ═══════════════════════════════════════════════════════════════════════
    // LÁCTEOS - Mixed (proteína + carbs)
    // ═══════════════════════════════════════════════════════════════════════

    /// Lácteo descremado (~8g proteína, ~12g carbs)
    EquivalentDefinition(
      id: 'lacteo_descremado',
      group: 'lacteos',
      subgroup: 'descremado',
      kcal: 85.0,
      proteinG: 8.0,
      fatG: 0.5,
      carbG: 12.0,
    ),

    /// Lácteo completo (~8g proteína, ~12g carbs, ~7g grasa)
    EquivalentDefinition(
      id: 'lacteo_completo',
      group: 'lacteos',
      subgroup: 'completo',
      kcal: 150.0,
      proteinG: 8.0,
      fatG: 7.0,
      carbG: 12.0,
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
