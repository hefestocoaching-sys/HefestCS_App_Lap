class FoodItem {
  final String name;
  final double grams;
  final double kcal;
  final double protein;
  final double fat;
  final double carbs;

  // Extensión para integración con catálogo
  final String? foodId;
  final Map<String, double>? macrosPer100g;
  final String? groupHint;
  final String? subgroupHint;

  // Extensión para soporte cocido/crudo (v1.1)
  final String preparationState; // 'raw' | 'cooked'
  final double?
  yieldFactor; // Factor de conversión crudo→cocido (ej. 2.5 para arroz)
  final String? baseFoodId; // ID del alimento base (si es versión cocida)

  const FoodItem({
    required this.name,
    required this.grams,
    required this.kcal,
    required this.protein,
    required this.fat,
    required this.carbs,
    this.foodId,
    this.macrosPer100g,
    this.groupHint,
    this.subgroupHint,
    this.preparationState = 'cooked', // Default: alimento listo para consumo
    this.yieldFactor,
    this.baseFoodId,
  });

  FoodItem copyWith({
    String? name,
    double? grams,
    double? kcal,
    double? protein,
    double? fat,
    double? carbs,
    String? foodId,
    Map<String, double>? macrosPer100g,
    String? groupHint,
    String? subgroupHint,
    String? preparationState,
    double? yieldFactor,
    String? baseFoodId,
  }) {
    return FoodItem(
      name: name ?? this.name,
      grams: grams ?? this.grams,
      kcal: kcal ?? this.kcal,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      carbs: carbs ?? this.carbs,
      foodId: foodId ?? this.foodId,
      macrosPer100g: macrosPer100g ?? this.macrosPer100g,
      groupHint: groupHint ?? this.groupHint,
      subgroupHint: subgroupHint ?? this.subgroupHint,
      preparationState: preparationState ?? this.preparationState,
      yieldFactor: yieldFactor ?? this.yieldFactor,
      baseFoodId: baseFoodId ?? this.baseFoodId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'grams': _safeNum(grams),
      'kcal': _safeNum(kcal),
      'protein': _safeNum(protein),
      'fat': _safeNum(fat),
      'carbs': _safeNum(carbs),
      if (foodId != null) 'foodId': foodId,
      if (macrosPer100g != null) 'macrosPer100g': macrosPer100g,
      if (groupHint != null) 'groupHint': groupHint,
      if (subgroupHint != null) 'subgroupHint': subgroupHint,
      'preparationState': preparationState,
      if (yieldFactor != null) 'yieldFactor': yieldFactor,
      if (baseFoodId != null) 'baseFoodId': baseFoodId,
    };
  }

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      name: json['name'] as String,
      grams: _safeNum(json['grams'] as num?),
      kcal: _safeNum(json['kcal'] as num?),
      protein: _safeNum(json['protein'] as num?),
      fat: _safeNum(json['fat'] as num?),
      carbs: _safeNum(json['carbs'] as num?),
      foodId: json['foodId'] as String?,
      macrosPer100g: json['macrosPer100g'] != null
          ? Map<String, double>.from(json['macrosPer100g'] as Map)
          : null,
      groupHint: json['groupHint'] as String?,
      subgroupHint: json['subgroupHint'] as String?,
      preparationState: json['preparationState'] as String? ?? 'cooked',
      yieldFactor: json['yieldFactor'] != null
          ? _safeNum(json['yieldFactor'] as num?)
          : null,
      baseFoodId: json['baseFoodId'] as String?,
    );
  }
}

double _safeNum(num? value) {
  if (value == null) return 0.0;
  final d = value.toDouble();
  if (d.isNaN || d.isInfinite) return 0.0;
  return d;
}

class Meal {
  final String name; // e.g., 'Desayuno', 'Almuerzo'
  final List<FoodItem> items;

  const Meal({required this.name, required this.items});

  Meal copyWith({String? name, List<FoodItem>? items}) {
    return Meal(name: name ?? this.name, items: items ?? this.items);
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'items': items.map((x) => x.toJson()).toList()};
  }

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      name: json['name'] as String,
      items: List<FoodItem>.from(
        (json['items'] as List<dynamic>).map<FoodItem>(
          (x) => FoodItem.fromJson(x as Map<String, dynamic>),
        ),
      ),
    );
  }
}

class DailyMealPlan {
  final String dayKey; // 'Lunes'...'Domingo', or a specific date
  final List<Meal> meals; // Desayuno, Almuerzo, Cena, etc.

  const DailyMealPlan({required this.dayKey, required this.meals});

  DailyMealPlan copyWith({String? dayKey, List<Meal>? meals}) {
    return DailyMealPlan(
      dayKey: dayKey ?? this.dayKey,
      meals: meals ?? this.meals,
    );
  }

  Map<String, dynamic> toJson() {
    return {'dayKey': dayKey, 'meals': meals.map((x) => x.toJson()).toList()};
  }

  factory DailyMealPlan.fromJson(Map<String, dynamic> json) {
    return DailyMealPlan(
      dayKey: json['dayKey'] as String,
      meals: List<Meal>.from(
        (json['meals'] as List<dynamic>).map<Meal>(
          (x) => Meal.fromJson(x as Map<String, dynamic>),
        ),
      ),
    );
  }
}
