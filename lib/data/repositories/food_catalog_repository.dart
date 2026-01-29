import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hcs_app_lap/domain/entities/clinical_restriction_profile.dart';
import 'package:hcs_app_lap/domain/entities/daily_meal_plan.dart';
import 'package:hcs_app_lap/domain/services/clinical_restriction_validator.dart';

/// Repositorio de catálogo de alimentos desde assets
/// Carga foods_v1_es_mx.json y filtra con restricciones clínicas P0
class FoodCatalogRepository {
  static const String _assetPath = 'assets/data/foods_v1_es_mx.json';

  List<FoodItem>? _cachedFoods;

  /// Cargar todos los alimentos del catálogo (sin filtrar)
  Future<List<FoodItem>> getAllFoods() async {
    if (_cachedFoods != null) {
      return _cachedFoods!;
    }

    final jsonString = await rootBundle.loadString(_assetPath);
    final Map<String, dynamic> data = json.decode(jsonString);

    final List<dynamic> foodsJson = data['foods'] as List<dynamic>;

    _cachedFoods = foodsJson.map((foodJson) {
      final Map<String, dynamic> food = foodJson as Map<String, dynamic>;
      final Map<String, dynamic> macros =
          food['macrosPer100g'] as Map<String, dynamic>;

      // Convertir macrosPer100g a formato esperado por FoodItem
      final macrosPer100gConverted = <String, double>{
        'kcal': _toDouble(macros['kcal']),
        'protein': _toDouble(macros['protein_g']),
        'fat': _toDouble(macros['fat_g']),
        'carbs': _toDouble(macros['carb_g']),
      };

      return FoodItem(
        name: food['name'] as String,
        grams: 100.0, // Por defecto 100g (datos del catálogo son per 100g)
        kcal: _toDouble(macros['kcal']),
        protein: _toDouble(macros['protein_g']),
        fat: _toDouble(macros['fat_g']),
        carbs: _toDouble(macros['carb_g']),
        foodId: food['foodId'] as String?,
        macrosPer100g: macrosPer100gConverted,
        groupHint: food['groupHint'] as String?,
        subgroupHint: food['subgroupHint'] as String?,
        // v1.1 Schema: Soporte para preparationState, yieldFactor, baseFoodId
        preparationState: food['preparationState'] as String? ?? 'cooked',
        yieldFactor: food['yieldFactor'] != null
            ? _toDouble(food['yieldFactor'])
            : null,
        baseFoodId: food['baseFoodId'] as String?,
      );
    }).toList();

    return _cachedFoods!;
  }

  /// Buscar alimento por ID
  Future<FoodItem?> getFoodById(String foodId) async {
    final foods = await getAllFoods();
    try {
      return foods.firstWhere((food) => food.foodId == foodId);
    } catch (_) {
      return null;
    }
  }

  /// Obtener alimentos permitidos según perfil clínico P0
  /// Aplica ClinicalRestrictionValidator antes de retornar
  Future<List<FoodItem>> getAllowedFoods(
    ClinicalRestrictionProfile profile,
  ) async {
    final allFoods = await getAllFoods();

    return allFoods.where((food) {
      return ClinicalRestrictionValidator.isFoodAllowed(
        foodName: food.name,
        profile: profile,
      );
    }).toList();
  }

  /// Limpiar caché (útil para testing o recarga)
  void clearCache() {
    _cachedFoods = null;
  }

  /// Resuelve el alimento para consumo (preferir cocido, estilo SMAE)
  ///
  /// Si el alimento ya está cocido → retorna sin cambios
  /// Si está crudo y tiene baseFoodId cocido → retorna versión cocida
  /// Si está crudo sin versión cocida → aplica yieldFactor para convertir macros
  ///
  /// IMPORTANTE: Los gramos se mantienen constantes (usuario especifica gramos cocidos)
  /// El yieldFactor ajusta las macros para reflejar densidad nutricional cocida
  Future<FoodItem> resolveConsumableFood(FoodItem food) async {
    // Si ya está cocido, retornar directamente
    if (food.preparationState == 'cooked') {
      return food;
    }

    // Buscar versión cocida explícita en catálogo
    if (food.baseFoodId != null) {
      final cookedVersion = await getFoodById(food.baseFoodId!);
      if (cookedVersion != null && cookedVersion.preparationState == 'cooked') {
        // Transferir gramos del usuario a versión cocida
        return cookedVersion.copyWith(grams: food.grams);
      }
    }

    // Si no hay versión cocida pero tiene yieldFactor, convertir macros
    if (food.yieldFactor != null && food.yieldFactor! > 0) {
      // yieldFactor representa: 100g crudo → (yieldFactor * 100)g cocido
      // Ejemplo: arroz yieldFactor=2.5 → 100g crudo = 250g cocido
      // Para mismos gramos cocidos, densidad nutricional = macros_crudas / yieldFactor
      final adjustedMacros = <String, double>{
        'kcal': (food.macrosPer100g!['kcal'] ?? 0.0) / food.yieldFactor!,
        'protein': (food.macrosPer100g!['protein'] ?? 0.0) / food.yieldFactor!,
        'fat': (food.macrosPer100g!['fat'] ?? 0.0) / food.yieldFactor!,
        'carbs': (food.macrosPer100g!['carbs'] ?? 0.0) / food.yieldFactor!,
      };

      return food.copyWith(
        preparationState: 'cooked',
        macrosPer100g: adjustedMacros,
        // Recalcular macros totales basado en gramos y nuevas macrosPer100g
        kcal: adjustedMacros['kcal']! * food.grams / 100.0,
        protein: adjustedMacros['protein']! * food.grams / 100.0,
        fat: adjustedMacros['fat']! * food.grams / 100.0,
        carbs: adjustedMacros['carbs']! * food.grams / 100.0,
      );
    }

    // Si es crudo sin yieldFactor ni baseFoodId, retornar sin cambios
    // (puede ser alimento que no requiere cocción)
    return food;
  }

  /// Obtener solo alimentos en estado cocido (ready-to-consume)
  /// Útil para UI de selección de alimentos
  Future<List<FoodItem>> getCookedFoods() async {
    final allFoods = await getAllFoods();
    return allFoods.where((f) => f.preparationState == 'cooked').toList();
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
