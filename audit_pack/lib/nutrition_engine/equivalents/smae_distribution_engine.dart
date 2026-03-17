import 'package:hcs_app_lap/core/utils/app_logger.dart';
import 'package:hcs_app_lap/nutrition_engine/equivalents/equivalent_definition.dart';
import 'package:hcs_app_lap/nutrition_engine/planning/meal_targets.dart';

class SmaeDistributionResult {
  final Map<String, double> totalsByGroup;
  final Map<String, Map<int, double>> mealsByGroup;
  final Map<String, double> achieved;
  final Map<String, bool> coverage;
  final List<String> warnings;
  final double deltaKcal;
  final double deltaKcalPct;
  final bool withinTolerance;

  const SmaeDistributionResult({
    required this.totalsByGroup,
    required this.mealsByGroup,
    required this.achieved,
    required this.coverage,
    required this.warnings,
    required this.deltaKcal,
    required this.deltaKcalPct,
    required this.withinTolerance,
  });

  Map<String, dynamic> toMap() {
    final mealsEncoded = <String, dynamic>{};
    for (final entry in mealsByGroup.entries) {
      mealsEncoded[entry.key] = entry.value.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }

    return {
      'totalsByGroup': totalsByGroup,
      'mealsByGroup': mealsEncoded,
      'achieved': achieved,
      'coverage': coverage,
      'warnings': warnings,
      'deltaKcal': deltaKcal,
      'deltaKcalPct': deltaKcalPct,
      'withinTolerance': withinTolerance,
    };
  }

  factory SmaeDistributionResult.fromMap(Map<String, dynamic> map) {
    final rawMeals = map['mealsByGroup'];
    final parsedMeals = <String, Map<int, double>>{};
    if (rawMeals is Map) {
      for (final groupEntry in rawMeals.entries) {
        if (groupEntry.value is! Map) continue;
        final mealMap = <int, double>{};
        for (final mealEntry in (groupEntry.value as Map).entries) {
          final mealIndex = int.tryParse(mealEntry.key.toString());
          if (mealIndex == null) continue;
          mealMap[mealIndex] = (mealEntry.value as num?)?.toDouble() ?? 0.0;
        }
        parsedMeals[groupEntry.key.toString()] = mealMap;
      }
    }

    return SmaeDistributionResult(
      totalsByGroup: _parseDoubleMap(map['totalsByGroup']),
      mealsByGroup: parsedMeals,
      achieved: _parseDoubleMap(map['achieved']),
      coverage: _parseBoolMap(map['coverage']),
      warnings:
          (map['warnings'] as List?)?.map((e) => e.toString()).toList() ??
          const <String>[],
      deltaKcal: (map['deltaKcal'] as num?)?.toDouble() ?? 0.0,
      deltaKcalPct: (map['deltaKcalPct'] as num?)?.toDouble() ?? 0.0,
      withinTolerance: map['withinTolerance'] as bool? ?? false,
    );
  }

  static Map<String, double> _parseDoubleMap(dynamic raw) {
    if (raw is! Map) return {};
    final out = <String, double>{};
    for (final entry in raw.entries) {
      out[entry.key.toString()] = (entry.value as num?)?.toDouble() ?? 0.0;
    }
    return out;
  }

  static Map<String, bool> _parseBoolMap(dynamic raw) {
    if (raw is! Map) return {};
    final out = <String, bool>{};
    for (final entry in raw.entries) {
      out[entry.key.toString()] = entry.value == true;
    }
    return out;
  }
}

class SmaeDistributionEngine {
  static const double _tolerancePct = 0.05;
  static const List<String> _requiredCoverage = [
    'vegetales',
    'frutas',
    'cereales_tuberculos',
    'aoa',
    'grasas',
  ];

  SmaeDistributionResult distribute({
    required double kcalTarget,
    required double proteinTargetG,
    required double carbTargetG,
    required double fatTargetG,
    required int mealsPerDay,
    List<MealTargets>? mealTargets,
    Set<String> excludedEquivalentIds = const {},
    Set<String> excludedGroups = const {},
  }) {
    final filteredDefs = EquivalentCatalog.v1Definitions.where((def) {
      return !excludedEquivalentIds.contains(def.id) &&
          !excludedGroups.contains(def.group);
    }).toList();

    final warnings = <String>[];
    if (filteredDefs.isEmpty) {
      warnings.add('No hay equivalentes disponibles después de restricciones.');
      return const SmaeDistributionResult(
        totalsByGroup: {},
        mealsByGroup: {},
        achieved: {'kcal': 0, 'protein': 0, 'carb': 0, 'fat': 0},
        coverage: {},
        warnings: ['No hay equivalentes disponibles después de restricciones.'],
        deltaKcal: 0,
        deltaKcalPct: 1,
        withinTolerance: false,
      );
    }

    final byId = {for (final def in filteredDefs) def.id: def};
    final totalsByGroup = <String, double>{
      for (final def in filteredDefs) def.id: 0.0,
    };

    double remainProtein = proteinTargetG;
    double remainCarb = carbTargetG;
    double remainFat = fatTargetG;

    final proteinPriority = _sortedByMacro(filteredDefs, 'protein');
    final carbPriority = _sortedByMacro(filteredDefs, 'carb');
    final fatPriority = _sortedByMacro(filteredDefs, 'fat');

    _greedyAssign(
      defs: proteinPriority,
      totalsByGroup: totalsByGroup,
      neededMacro: remainProtein,
      macroSelector: (d) => d.proteinG,
      fractionStep: 0.5,
    );
    final afterProtein = _computeAchieved(totalsByGroup, byId);
    remainProtein = (proteinTargetG - (afterProtein['protein'] ?? 0)).clamp(
      0,
      99999,
    );
    remainCarb = (carbTargetG - (afterProtein['carb'] ?? 0)).clamp(0, 99999);
    remainFat = (fatTargetG - (afterProtein['fat'] ?? 0)).clamp(0, 99999);

    _greedyAssign(
      defs: carbPriority,
      totalsByGroup: totalsByGroup,
      neededMacro: remainCarb,
      macroSelector: (d) => d.carbG,
      fractionStep: 0.5,
    );
    final afterCarb = _computeAchieved(totalsByGroup, byId);
    remainFat = (fatTargetG - (afterCarb['fat'] ?? 0)).clamp(0, 99999);

    _greedyAssign(
      defs: fatPriority,
      totalsByGroup: totalsByGroup,
      neededMacro: remainFat,
      macroSelector: (d) => d.fatG,
      fractionStep: 0.5,
    );

    _residualAdjust(
      defs: filteredDefs,
      totalsByGroup: totalsByGroup,
      kcalTarget: kcalTarget,
      byId: byId,
    );

    final achieved = _computeAchieved(totalsByGroup, byId);
    final achievedKcal = achieved['kcal'] ?? 0;
    final deltaKcal = achievedKcal - kcalTarget;
    final deltaPct = kcalTarget > 0 ? (deltaKcal.abs() / kcalTarget) : 0.0;
    final withinTolerance = deltaPct <= _tolerancePct;

    if (!withinTolerance) {
      warnings.add(
        'Delta kcal fuera de tolerancia: ${(deltaPct * 100).toStringAsFixed(1)}% (objetivo ±5%).',
      );
    }

    final coverage = _computeCoverage(totalsByGroup, byId);
    for (final group in _requiredCoverage) {
      if (excludedGroups.contains(group)) continue;
      if (!(coverage[group] ?? false)) {
        warnings.add('Cobertura insuficiente del grupo: $group.');
      }
    }

    final mealsByGroup = _distributeMeals(
      totalsByGroup: totalsByGroup,
      byId: byId,
      mealsPerDay: mealsPerDay,
      mealTargets: mealTargets,
    );

    logger.info('SMAE v2 distribution completed', {
      'kcalTarget': kcalTarget,
      'kcalAchieved': achievedKcal,
      'deltaPct': deltaPct,
      'warnings': warnings.length,
    });

    return SmaeDistributionResult(
      totalsByGroup: totalsByGroup,
      mealsByGroup: mealsByGroup,
      achieved: achieved,
      coverage: coverage,
      warnings: warnings,
      deltaKcal: deltaKcal,
      deltaKcalPct: deltaPct,
      withinTolerance: withinTolerance,
    );
  }

  List<EquivalentDefinition> _sortedByMacro(
    List<EquivalentDefinition> defs,
    String macro,
  ) {
    final sorted = [...defs];
    sorted.sort((a, b) {
      final aValue = _macroValue(a, macro);
      final bValue = _macroValue(b, macro);
      if (aValue == bValue) return a.kcal.compareTo(b.kcal);
      return bValue.compareTo(aValue);
    });
    return sorted;
  }

  double _macroValue(EquivalentDefinition def, String macro) {
    switch (macro) {
      case 'protein':
        return def.proteinG;
      case 'carb':
        return def.carbG;
      case 'fat':
        return def.fatG;
      default:
        return 0;
    }
  }

  void _greedyAssign({
    required List<EquivalentDefinition> defs,
    required Map<String, double> totalsByGroup,
    required double neededMacro,
    required double Function(EquivalentDefinition) macroSelector,
    required double fractionStep,
  }) {
    if (neededMacro <= 0) return;

    var remaining = neededMacro;
    for (final def in defs) {
      final macroPerEq = macroSelector(def);
      if (macroPerEq <= 0) continue;
      if (remaining <= 0) break;

      final rawNeeded = remaining / macroPerEq;
      final rounded = _roundToStep(rawNeeded, fractionStep);
      if (rounded <= 0) continue;

      totalsByGroup[def.id] = (totalsByGroup[def.id] ?? 0) + rounded;
      remaining = (remaining - (rounded * macroPerEq)).clamp(0, 99999);
    }
  }

  void _residualAdjust({
    required List<EquivalentDefinition> defs,
    required Map<String, double> totalsByGroup,
    required double kcalTarget,
    required Map<String, EquivalentDefinition> byId,
  }) {
    final achieved = _computeAchieved(totalsByGroup, byId);
    var delta = kcalTarget - (achieved['kcal'] ?? 0);

    if (delta.abs() <= (kcalTarget * _tolerancePct)) return;

    if (delta > 0) {
      final energyDense = [...defs]..sort((a, b) => b.kcal.compareTo(a.kcal));
      for (final def in energyDense) {
        if (delta <= 0) break;
        if (def.kcal <= 0) continue;
        final addEq = _roundToStep(delta / def.kcal, 0.5);
        if (addEq <= 0) continue;
        totalsByGroup[def.id] = (totalsByGroup[def.id] ?? 0) + addEq;
        delta -= addEq * def.kcal;
      }
    } else {
      final removeFirst = [...defs]..sort((a, b) => b.kcal.compareTo(a.kcal));
      var over = delta.abs();
      for (final def in removeFirst) {
        if (over <= 0) break;
        final current = totalsByGroup[def.id] ?? 0;
        if (current <= 0) continue;
        final removableEq = _roundToStep(over / def.kcal, 0.5);
        final removeEq = removableEq > current ? current : removableEq;
        if (removeEq <= 0) continue;
        totalsByGroup[def.id] = (current - removeEq).clamp(0, 99999);
        over -= removeEq * def.kcal;
      }
    }
  }

  Map<String, double> _computeAchieved(
    Map<String, double> totalsByGroup,
    Map<String, EquivalentDefinition> byId,
  ) {
    double kcal = 0;
    double protein = 0;
    double carb = 0;
    double fat = 0;

    for (final entry in totalsByGroup.entries) {
      final qty = entry.value;
      if (qty <= 0) continue;
      final def = byId[entry.key];
      if (def == null) continue;
      kcal += def.kcal * qty;
      protein += def.proteinG * qty;
      carb += def.carbG * qty;
      fat += def.fatG * qty;
    }

    return {'kcal': kcal, 'protein': protein, 'carb': carb, 'fat': fat};
  }

  Map<String, bool> _computeCoverage(
    Map<String, double> totalsByGroup,
    Map<String, EquivalentDefinition> byId,
  ) {
    final covered = <String, bool>{
      for (final group in _requiredCoverage) group: false,
    };
    for (final entry in totalsByGroup.entries) {
      if (entry.value <= 0) continue;
      final def = byId[entry.key];
      if (def == null) continue;
      covered[def.group] = true;
    }
    return covered;
  }

  Map<String, Map<int, double>> _distributeMeals({
    required Map<String, double> totalsByGroup,
    required Map<String, EquivalentDefinition> byId,
    required int mealsPerDay,
    List<MealTargets>? mealTargets,
  }) {
    final safeMeals = mealsPerDay <= 0 ? 1 : mealsPerDay;

    final proteinWeights = _extractMacroWeights(
      safeMeals,
      mealTargets,
      selector: (m) => m.proteinG,
    );
    final carbWeights = _extractMacroWeights(
      safeMeals,
      mealTargets,
      selector: (m) => m.carbG,
    );
    final fatWeights = _extractMacroWeights(
      safeMeals,
      mealTargets,
      selector: (m) => m.fatG,
    );

    final out = <String, Map<int, double>>{};
    for (final entry in totalsByGroup.entries) {
      final qty = entry.value;
      if (qty <= 0) continue;
      final def = byId[entry.key];
      if (def == null) continue;

      List<double> weights;
      if (def.proteinG >= def.carbG && def.proteinG >= def.fatG) {
        weights = proteinWeights;
      } else if (def.carbG >= def.fatG) {
        weights = carbWeights;
      } else {
        weights = fatWeights;
      }

      final mealMap = <int, double>{};
      double accumulated = 0;
      for (var i = 0; i < safeMeals; i++) {
        final value = i == safeMeals - 1
            ? _roundToStep((qty - accumulated).clamp(0, 99999), 0.5)
            : _roundToStep(qty * weights[i], 0.5);
        mealMap[i] = value;
        accumulated += value;
      }

      out[entry.key] = mealMap;
    }

    return out;
  }

  List<double> _extractMacroWeights(
    int mealsPerDay,
    List<MealTargets>? mealTargets, {
    required double Function(MealTargets target) selector,
  }) {
    if (mealTargets == null || mealTargets.isEmpty) {
      return List<double>.filled(mealsPerDay, 1 / mealsPerDay);
    }

    final base = List<double>.filled(mealsPerDay, 0);
    for (var i = 0; i < mealsPerDay; i++) {
      final target = i < mealTargets.length ? mealTargets[i] : null;
      base[i] = target == null ? 0 : selector(target);
    }

    final sum = base.fold<double>(0, (a, b) => a + b);
    if (sum <= 0) {
      return List<double>.filled(mealsPerDay, 1 / mealsPerDay);
    }

    return base.map((value) => value / sum).toList();
  }

  double _roundToStep(double value, double step) {
    if (step <= 0) return value;
    return (value / step).round() * step;
  }
}
