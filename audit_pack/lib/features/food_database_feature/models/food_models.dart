class FoodSearchResult {
  final int id;
  final String description;
  final String? brandOwner;
  // AGREGADO: Lista de nutrientes para poder extraer macros en la búsqueda
  final List<FoodNutrient>? foodNutrients;

  FoodSearchResult({
    required this.id,
    required this.description,
    this.brandOwner,
    this.foodNutrients,
  });

  factory FoodSearchResult.fromJson(Map<String, dynamic> json) {
    return FoodSearchResult(
      id: json['fdcId'] as int? ?? 0,
      description: json['description'] as String? ?? 'Sin descripción',
      brandOwner: json['brandOwner'] as String?,
      // Mapeo seguro de la lista de nutrientes
      foodNutrients: (json['foodNutrients'] as List<dynamic>?)
          ?.map((e) => FoodNutrient.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// AGREGADO: Clase para manejar los nutrientes individuales (Proteína, Grasa, etc.)
class FoodNutrient {
  final String? nutrientName;
  final double? value;
  final String? unitName;

  FoodNutrient({
    this.nutrientName,
    this.value,
    this.unitName,
  });

  factory FoodNutrient.fromJson(Map<String, dynamic> json) {
    return FoodNutrient(
      nutrientName: json['nutrientName'] as String?,
      // A veces viene como 'value' o 'amount'
      value: (json['value'] as num?)?.toDouble() ?? (json['amount'] as num?)?.toDouble(),
      unitName: json['unitName'] as String?,
    );
  }
}

// Mantenemos FoodDetails por si lo usas en otra parte para ver detalles extendidos
class FoodDetails {
  final int id;
  final String description;
  final String? brandOwner;
  final double servingSize;
  final String? servingSizeUnit;
  final List<FoodNutrient>? foodNutrients;

  FoodDetails({
    required this.id,
    required this.description,
    this.brandOwner,
    this.servingSize = 100.0,
    this.servingSizeUnit,
    this.foodNutrients,
  });

  factory FoodDetails.fromJson(Map<String, dynamic> json) {
    return FoodDetails(
      id: json['fdcId'] as int? ?? 0,
      description: json['description'] as String? ?? '',
      brandOwner: json['brandOwner'] as String?,
      servingSize: (json['servingSize'] as num?)?.toDouble() ?? 100.0,
      servingSizeUnit: json['servingSizeUnit'] as String?,
      foodNutrients: (json['foodNutrients'] as List<dynamic>?)
          ?.map((e) => FoodNutrient.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}