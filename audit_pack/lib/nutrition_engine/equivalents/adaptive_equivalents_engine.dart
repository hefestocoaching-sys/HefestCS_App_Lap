import 'package:hcs_app_lap/nutrition_engine/equivalents/equivalent_definition.dart';

/// Motor de adaptación de equivalentes SMAE.
///
/// Principio "Carb-Dominant Adaptation":
/// - Proteínas y grasas se copian idénticas de la tabla maestra a todos los días.
/// - Solo los grupos de carbohidratos se ajustan según el target del día.
/// - Orden de reducción: azúcares → cereales con grasa → frutas
///   → cereales sin grasa → leguminosas (último recurso).
/// - Orden de aumento: cereales sin grasa → frutas → cereales con grasa.
class AdaptiveEquivalentsEngine {
  // ─── Grupos que se pueden ajustar (solo carb) ──────────────────────────
  static const _reduceOrder = [
    'azucares_con_grasa',
    'azucares_sin_grasa',
    'cereales_con_grasa',
    'frutas',
    'cereales_sin_grasa',
    'leguminosas',
  ];

  static const _addOrder = [
    'cereales_sin_grasa',
    'frutas',
    'cereales_con_grasa',
  ];

  // ─── MÉTODO PRINCIPAL ──────────────────────────────────────────────────

  /// Adapta la tabla maestra al target de carbohidratos del día.
  ///
  /// [masterEquivs]  : tabla que llenó el nutricionista (tabla general).
  /// [masterCarbG]   : gramos de carb totales que representa esa tabla.
  /// [targetCarbG]   : gramos de carb del día a adaptar.
  ///
  /// Proteínas, grasas, vegetales y leches se copian sin cambios.
  /// Solo los grupos de carbohidrato se tocan.
  Map<String, double> adaptToDayMacros({
    required Map<String, double> masterEquivs,
    required double masterCarbG,
    required double targetCarbG,
  }) {
    final diff =
        masterCarbG - targetCarbG; // positivo = recortar, negativo = agregar

    // Diferencia < 5 g de carb → no vale la pena tocar nada
    if (diff.abs() < 5) return Map.from(masterEquivs);

    final adapted = Map<String, double>.from(masterEquivs);

    if (diff > 0) {
      // ── RECORTAR carb ──────────────────────────────────────────────────
      double toRemove = diff;
      for (final groupId in _reduceOrder) {
        if (toRemove < 0.5) break;
        final qty = adapted[groupId] ?? 0;
        if (qty <= 0) continue;
        final def = EquivalentCatalog.findById(groupId);
        if (def == null || def.carbG <= 0) continue;
        final groupCarbG = def.carbG * qty;
        if (groupCarbG <= toRemove) {
          adapted[groupId] = 0;
          toRemove -= groupCarbG;
        } else {
          adapted[groupId] = _roundHalf(qty - (toRemove / def.carbG));
          toRemove = 0;
        }
      }
    } else {
      // ── AGREGAR carb ───────────────────────────────────────────────────
      double toAdd = diff.abs();
      for (final groupId in _addOrder) {
        if (toAdd < 0.5) break;
        final def = EquivalentCatalog.findById(groupId);
        if (def == null || def.carbG <= 0) continue;
        final equivsToAdd = _roundHalf(toAdd / def.carbG);
        adapted[groupId] = (adapted[groupId] ?? 0) + equivsToAdd;
        toAdd -= equivsToAdd * def.carbG;
      }
    }

    return adapted;
  }

  // ─── MÉTODO LEGACY (mantener compatibilidad con código existente) ──────

  /// @deprecated Usar [adaptToDayMacros] que trabaja con gramos de carb reales.
  /// Este método se conserva para que el código existente no rompa mientras
  /// se migra. Internamente convierte kcal a carb estimado y llama al nuevo.
  Map<String, double> adaptToDay(
    Map<String, double> generalEquivalents,
    double targetKcal,
  ) {
    // Calcular kcal y carb de la tabla maestra
    double masterKcal = 0;
    double masterCarbG = 0;
    generalEquivalents.forEach((id, qty) {
      final def = EquivalentCatalog.findById(id);
      if (def != null) {
        masterKcal += def.kcal * qty;
        masterCarbG += def.carbG * qty;
      }
    });

    if (masterKcal == 0) return {};
    if ((masterKcal - targetKcal).abs() < 30) {
      return Map.from(generalEquivalents);
    }

    // Estimar carb target proporcional a la diferencia de kcal
    // (asume que la diferencia calórica viene 100% de carb — principio carb-dominant)
    final kcalDiff = masterKcal - targetKcal;
    final carbDiffG = kcalDiff / 4.0; // 1g carb = 4 kcal
    final targetCarbG = (masterCarbG - carbDiffG)
        .clamp(0, double.infinity)
        .toDouble();

    return adaptToDayMacros(
      masterEquivs: generalEquivalents,
      masterCarbG: masterCarbG,
      targetCarbG: targetCarbG,
    );
  }

  // ─── DISTRIBUCIÓN POR COMIDA ───────────────────────────────────────────

  /// Distribuye los equivalentes diarios adaptados entre las comidas,
  /// respetando las proporciones que el nutricionista definió en la tabla maestra.
  ///
  /// Si no hay distribución manual para un grupo, se reparte equitativamente.
  Map<String, Map<int, double>> adaptMeals(
    Map<String, Map<int, double>> generalMealEquivalents,
    Map<String, double> dailyTotalEquivalents,
    int mealsCount,
  ) {
    final adaptedMeals = <String, Map<int, double>>{};

    dailyTotalEquivalents.forEach((groupId, totalDailyQty) {
      final mealMap = generalMealEquivalents[groupId];

      if (mealMap == null || mealMap.isEmpty) {
        // Sin distribución manual → equitativo
        final perMeal = _roundHalf(totalDailyQty / mealsCount);
        adaptedMeals[groupId] = {
          for (int i = 0; i < mealsCount; i++) i: perMeal,
        };
        return;
      }

      double baselineTotal = 0;
      mealMap.forEach((_, v) => baselineTotal += v);

      if (baselineTotal == 0) {
        if (totalDailyQty > 0) {
          final perMeal = _roundHalf(totalDailyQty / mealsCount);
          adaptedMeals[groupId] = {
            for (int i = 0; i < mealsCount; i++) i: perMeal,
          };
        } else {
          adaptedMeals[groupId] = {};
        }
        return;
      }

      // Escalar proporcionalmente respetando la distribución del nutricionista
      final ratio = totalDailyQty / baselineTotal;
      final newMap = <int, double>{};
      for (int i = 0; i < mealsCount; i++) {
        final oldVal = mealMap[i] ?? 0;
        newMap[i] = _roundHalf(oldVal * ratio);
      }
      adaptedMeals[groupId] = newMap;
    });

    return adaptedMeals;
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────
  double _roundHalf(double v) => (v * 2).round() / 2.0;
}
