import 'package:hcs_app_lap/domain/entities/clinical_restriction_profile.dart';
import 'package:hcs_app_lap/domain/entities/daily_meal_plan.dart';
import 'package:hcs_app_lap/domain/services/clinical_restriction_validator.dart';
import 'equivalent_definition.dart';
import 'equivalent_result.dart';

class FoodToEquivalentEngine {
  /// Tolerancias de validación P0
  static const double keyMacroTolerance = 0.10; // ±10%
  static const double secondaryMacroTolerance = 0.20; // ±20%
  static const double kcalTolerance = 0.15; // ±15%

  /// Convertir FoodItem (con datos por 100g) a equivalente
  /// con validación clínica P0
  static EquivalentResult convertFoodToEquivalent({
    required FoodItem food,
    required EquivalentDefinition target,
    ClinicalRestrictionProfile? clinicalProfile,
  }) {
    // P0: Verificar restricción clínica
    if (clinicalProfile != null) {
      final allowed = ClinicalRestrictionValidator.isFoodAllowed(
        foodName: food.name,
        profile: clinicalProfile,
      );

      if (!allowed) {
        final reason = ClinicalRestrictionValidator.explainFoodBlockage(
          foodName: food.name,
          profile: clinicalProfile,
        );

        return EquivalentResult(
          equivalentId: target.id,
          grams: 0.0,
          needsReview: true,
          estimatedMacros: {},
          blockageReason: reason,
        );
      }
    }

    // Calcular gramos necesarios basado en macro llave
    final keyMacro = target.keyMacroForGroup;
    final grams = _calculateGrams(food, target, keyMacro);

    if (grams <= 0) {
      return EquivalentResult(
        equivalentId: target.id,
        grams: grams,
        needsReview: true,
        estimatedMacros: _estimateMacros(food, grams),
        blockageReason: 'Cálculo de gramos inválido (≤0)',
      );
    }

    // Validar macros
    final validations = _validateMacros(food, target, grams, keyMacro);
    final estimatedMacros = _estimateMacros(food, grams);

    return EquivalentResult(
      equivalentId: target.id,
      grams: grams,
      needsReview: !(validations['passed'] as bool? ?? false),
      estimatedMacros: estimatedMacros,
      blockageReason: validations['reason'] as String?,
    );
  }

  /// Calcular gramos necesarios para alcanzar equivalente
  /// Fórmula: grams = (targetKeyMacro / foodKeyMacroPer100g) * 100
  static double _calculateGrams(
    FoodItem food,
    EquivalentDefinition target,
    String keyMacro,
  ) {
    final foodKeyMacroPer100g = _getKeyMacroValue(food, keyMacro);

    if (foodKeyMacroPer100g <= 0) {
      return 0.0;
    }

    final targetKeyMacro = _getKeyMacroValue(target, keyMacro);
    return (targetKeyMacro / foodKeyMacroPer100g) * 100.0;
  }

  /// Obtener valor de macro llave (proteína/carbs/grasa)
  static double _getKeyMacroValue(dynamic source, String keyMacro) {
    if (source is FoodItem) {
      // Usar macrosPer100g si está disponible (más preciso)
      if (source.macrosPer100g != null) {
        switch (keyMacro) {
          case 'protein':
            return source.macrosPer100g!['protein'] ?? 0.0;
          case 'carbs':
            return source.macrosPer100g!['carbs'] ?? 0.0;
          case 'fat':
            return source.macrosPer100g!['fat'] ?? 0.0;
          default:
            return source.macrosPer100g!['protein'] ?? 0.0;
        }
      }

      // Fallback a valores directos (backward compatible)
      switch (keyMacro) {
        case 'protein':
          return source.protein;
        case 'carbs':
          return source.carbs;
        case 'fat':
          return source.fat;
        default:
          return source.protein;
      }
    } else if (source is EquivalentDefinition) {
      switch (keyMacro) {
        case 'protein':
          return source.proteinG;
        case 'carbs':
          return source.carbG;
        case 'fat':
          return source.fatG;
        default:
          return source.proteinG;
      }
    }
    return 0.0;
  }

  /// Estimar macros para cantidad específica en gramos
  static Map<String, double> _estimateMacros(FoodItem food, double grams) {
    if (grams <= 0) return {};

    final factor = grams / 100.0;

    // Usar macrosPer100g si está disponible (más preciso)
    if (food.macrosPer100g != null) {
      final macros = food.macrosPer100g!;
      return {
        'kcal': (macros['kcal'] ?? 0.0) * factor,
        'protein': (macros['protein'] ?? 0.0) * factor,
        'fat': (macros['fat'] ?? 0.0) * factor,
        'carbs': (macros['carbs'] ?? 0.0) * factor,
      };
    }

    // Fallback a valores directos (backward compatible)
    return {
      'kcal': food.kcal * factor,
      'protein': food.protein * factor,
      'fat': food.fat * factor,
      'carbs': food.carbs * factor,
    };
  }

  /// Validar macros dentro de tolerancias
  /// Retorna {passed: bool, reason: String?}
  static Map<String, dynamic> _validateMacros(
    FoodItem food,
    EquivalentDefinition target,
    double grams,
    String keyMacro,
  ) {
    final estimated = _estimateMacros(food, grams);

    // Validar macro llave (±10%)
    final keyMacroEst =
        estimated[keyMacro == 'fat'
            ? 'fat'
            : keyMacro == 'carbs'
            ? 'carbs'
            : 'protein'] ??
        0.0;
    final keyMacroTarget = _getKeyMacroValue(target, keyMacro);
    final keyMacroDiff = (keyMacroEst - keyMacroTarget).abs() / keyMacroTarget;

    if (keyMacroDiff > keyMacroTolerance) {
      return {
        'passed': false,
        'reason':
            'Macro llave ($keyMacro) fuera de rango: '
            '${keyMacroEst.toStringAsFixed(1)}g vs ${keyMacroTarget.toStringAsFixed(1)}g '
            '(${(keyMacroDiff * 100).toStringAsFixed(1)}% diff)',
      };
    }

    // Validar secundarias (±20%)
    final secondaries = <String>[
      keyMacro == 'protein' ? 'fat' : 'protein',
      keyMacro == 'carbs' ? 'fat' : 'carbs',
    ];

    for (final secondary in secondaries) {
      if (secondary == keyMacro) continue;

      final secEst = estimated[secondary] ?? 0.0;
      final secTarget = _getKeyMacroValue(target, secondary);

      if (secTarget > 0) {
        final secDiff = (secEst - secTarget).abs() / secTarget;
        if (secDiff > secondaryMacroTolerance) {
          return {
            'passed': false,
            'reason':
                'Macro secundaria ($secondary) fuera de rango: '
                '${secEst.toStringAsFixed(1)}g vs ${secTarget.toStringAsFixed(1)}g '
                '(${(secDiff * 100).toStringAsFixed(1)}% diff)',
          };
        }
      }
    }

    // Validar kcal (±15%)
    final kcalEst = estimated['kcal'] ?? 0.0;
    final kcalTarget = target.kcal;
    final kcalDiff = (kcalEst - kcalTarget).abs() / kcalTarget;

    if (kcalDiff > kcalTolerance) {
      return {
        'passed': false,
        'reason':
            'kcal fuera de rango: '
            '${kcalEst.toStringAsFixed(0)} vs ${kcalTarget.toStringAsFixed(0)} '
            '(${(kcalDiff * 100).toStringAsFixed(1)}% diff)',
      };
    }

    return {'passed': true, 'reason': null};
  }

  /// Convertir lista de alimentos a equivalentes
  static List<EquivalentResult> convertMultiple({
    required List<FoodItem> foods,
    required List<EquivalentDefinition> targets,
    ClinicalRestrictionProfile? clinicalProfile,
  }) {
    final results = <EquivalentResult>[];

    for (final food in foods) {
      for (final target in targets) {
        results.add(
          convertFoodToEquivalent(
            food: food,
            target: target,
            clinicalProfile: clinicalProfile,
          ),
        );
      }
    }

    return results;
  }

  /// Obtener mejor equivalente para un alimento (menor needsReview)
  /// Si food tiene groupHint, prioriza definiciones del mismo grupo
  static EquivalentResult? findBestEquivalent({
    required FoodItem food,
    ClinicalRestrictionProfile? clinicalProfile,
  }) {
    final results = <EquivalentResult>[];

    // Si el alimento tiene groupHint, filtrar por grupo primero
    List<EquivalentDefinition> targets = EquivalentCatalog.v1Definitions;
    if (food.groupHint != null) {
      final matchingGroup = targets
          .where((def) => def.group == food.groupHint)
          .toList();

      // Si hay coincidencias por grupo, usarlas; si no, usar todas
      if (matchingGroup.isNotEmpty) {
        targets = matchingGroup;
      }
    }

    for (final target in targets) {
      results.add(
        convertFoodToEquivalent(
          food: food,
          target: target,
          clinicalProfile: clinicalProfile,
        ),
      );
    }

    // Filtrar no bloqueados
    final allowed = results.where((r) => !r.isBlocked).toList();
    if (allowed.isEmpty) return null;

    // Ordenar por needsReview (false primero)
    allowed.sort((a, b) {
      if (a.needsReview != b.needsReview) {
        return a.needsReview ? 1 : -1;
      }
      return 0; // Ambos válidos, usar primero
    });

    return allowed.first;
  }
}
