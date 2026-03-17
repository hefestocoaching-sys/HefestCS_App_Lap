import 'package:hcs_app_lap/domain/entities/clinical_restriction_profile.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// Validador de Restricciones Clínicas — Filtrado de Alimentos P0
/// ═══════════════════════════════════════════════════════════════════════════
/// Responsabilidad ÚNICA: Determinar si un alimento es permitido según
/// restricciones clínicas P0.
///
/// REGLAS P0 (SIEMPRE BLOQUEAN):
/// 1. Alergias alimentarias (IgE mediadas) → bloquean completamente
/// 2. Patrones dietarios (omnívoro, vegetariano, vegano, etc.) → bloquean por principios
/// 3. Condiciones clínicas severas (renal disease, diabetes severa) → bloquean específicas
///
/// NO IMPLEMENTAR (futuro):
/// - Recomendaciones P1/P2
/// - Equivalentes
/// - Menús
/// - Optimizaciones automáticas
class ClinicalRestrictionValidator {
  /// Alimentos prohibidos por alergia: mapa de {allergen: alimentos}
  static const Map<String, List<String>> allergenFoodList = {
    'milk': ['leche', 'yogur', 'queso', 'mantequilla', 'crema', 'lacteos'],
    'egg': ['huevo', 'huevos', 'mayonesa'],
    'fish': ['pez', 'pez', 'trucha', 'salmón', 'abadejo'],
    'shellfish': [
      'camarón',
      'langosta',
      'cangrejo',
      'ostra',
      'mejillón',
      'marisco',
    ],
    'peanuts': ['cacahuete', 'maní'],
    'treeNuts': ['almendra', 'nuez', 'avellana', 'pistacho', 'castaña'],
    'wheat': ['trigo', 'harina de trigo', 'pan', 'pasta', 'cereal de trigo'],
    'soy': ['soja', 'soja', 'edamame', 'tofu', 'salsa de soja'],
    'sesame': ['sésamo', 'ajonjolí', 'tahini'],
  };

  /// Alimentos permitidos por patrón dietario
  static const Map<String, Set<String>> dietaryPatternAllowedKeywords = {
    'vegetarian': {
      'vegetables',
      'verdura',
      'fruta',
      'grano',
      'legumbre',
      'lacteos',
      'huevo',
    },
    'vegan': {
      'vegetables',
      'verdura',
      'fruta',
      'grano',
      'legumbre',
      'tofu',
      'soja',
    },
    'pescatarian': {
      'vegetables',
      'verdura',
      'fruta',
      'grano',
      'legumbre',
      'fish',
      'pescado',
      'marisco',
      'lacteos',
      'huevo',
    },
    'omnivore': {}, // Sin restricciones por patrón dietario
    'halal': {}, // Sin restricciones implementadas (futuro)
    'kosher': {}, // Sin restricciones implementadas (futuro)
  };

  /// ¿Es permitido este alimento bajo restricciones clínicas?
  /// Devuelve true si el alimento PUEDE ser consumido, false si debe bloquearse.
  ///
  /// Evaluación:
  /// 1. Verificar alergias → si hay alergia, retornar false inmediatamente
  /// 2. Verificar patrón dietario → si no coincide, retornar false
  /// 3. Verificar intolerancias digestivas → solo registrar, no bloquear (P1)
  /// 4. Verificar condiciones clínicas → solo registrar, no bloquear (P1)
  /// 5. Verificar medicamentos → solo registrar, no bloquear (P1)
  ///
  static bool isFoodAllowed({
    required String foodName,
    required ClinicalRestrictionProfile profile,
  }) {
    if (foodName.trim().isEmpty) return true; // Alimento desconocido = permitir

    final normalizedFood = foodName.toLowerCase().trim();

    // ═══════════════════════════════════════════════════════════════════════
    // P0 BLOQUEO: ALERGIAS ALIMENTARIAS
    // ═══════════════════════════════════════════════════════════════════════
    for (final allergen in profile.foodAllergies.entries) {
      if (!allergen.value) continue; // Esta alergia no está activa

      final foods = allergenFoodList[allergen.key] ?? [];
      for (final food in foods) {
        if (normalizedFood.contains(food.toLowerCase())) {
          return false; // ❌ ALERGIA ACTIVA: BLOQUEAR
        }
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // P0 BLOQUEO: PATRÓN DIETARIO
    // ═══════════════════════════════════════════════════════════════════════
    if (profile.dietaryPattern != 'omnivore') {
      final allowed =
          dietaryPatternAllowedKeywords[profile.dietaryPattern] ?? {};
      if (allowed.isNotEmpty) {
        final matches = allowed.any(
          (keyword) => normalizedFood.contains(keyword.toLowerCase()),
        );
        if (!matches) {
          // Heurística: si contiene "carne", "pollo", "res", "cerdo" → bloquear vegetarianos/veganos
          if ((profile.dietaryPattern == 'vegetarian' ||
                  profile.dietaryPattern == 'vegan') &&
              (normalizedFood.contains('carne') ||
                  normalizedFood.contains('pollo') ||
                  normalizedFood.contains('res') ||
                  normalizedFood.contains('cerdo') ||
                  normalizedFood.contains('meat'))) {
            return false; // ❌ CARNE EN VEGETARIANO: BLOQUEAR
          }

          // Si vegan: bloquear lácteos y huevos
          if (profile.dietaryPattern == 'vegan' &&
              (normalizedFood.contains('leche') ||
                  normalizedFood.contains('huevo') ||
                  normalizedFood.contains('dairy'))) {
            return false; // ❌ LÁCTEO/HUEVO EN VEGAN: BLOQUEAR
          }
        }
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // P1 (NO IMPLEMENTAR AÚN): INTOLERANCIAS DIGESTIVAS
    // ═══════════════════════════════════════════════════════════════════════
    // if (profile.digestiveIntolerances.lactose != DigestiveSeverity.none) {
    //   if (normalizedFood.contains('lactose') || normalizedFood.contains('leche')) {
    //     // Registrar, no bloquear (P1)
    //   }
    // }

    // ═══════════════════════════════════════════════════════════════════════
    // P1 (NO IMPLEMENTAR AÚN): CONDICIONES CLÍNICAS
    // ═══════════════════════════════════════════════════════════════════════
    // if (profile.clinicalConditions.diabetes) {
    //   if (normalizedFood.contains('azúcar')) {
    //     // Registrar, no bloquear (P1 + recomendación)
    //   }
    // }

    // ✅ PERMITIR: No hay restricciones P0 que lo bloqueen
    return true;
  }

  /// Filtro batch: retorna solo los alimentos permitidos
  static List<String> filterAllowedFoods({
    required List<String> foodNames,
    required ClinicalRestrictionProfile profile,
  }) {
    return foodNames
        .where((food) => isFoodAllowed(foodName: food, profile: profile))
        .toList();
  }

  /// Diagnóstico: ¿por qué está bloqueado este alimento?
  /// Devuelve cadena descriptiva o vacía si está permitido.
  static String explainFoodBlockage({
    required String foodName,
    required ClinicalRestrictionProfile profile,
  }) {
    if (isFoodAllowed(foodName: foodName, profile: profile)) {
      return ''; // Permitido
    }

    final normalizedFood = foodName.toLowerCase().trim();

    // Verificar alergias
    for (final allergen in profile.foodAllergies.entries) {
      if (!allergen.value) continue;
      final foods = allergenFoodList[allergen.key] ?? [];
      for (final food in foods) {
        if (normalizedFood.contains(food.toLowerCase())) {
          return 'Alergia activa: ${allergen.key}';
        }
      }
    }

    // Verificar patrón dietario
    if (profile.dietaryPattern != 'omnivore') {
      if (normalizedFood.contains('carne') ||
          normalizedFood.contains('pollo') ||
          normalizedFood.contains('res')) {
        return 'Patrón dietario: ${profile.dietaryPattern} (sin carnes)';
      }
      if ((profile.dietaryPattern == 'vegan') &&
          (normalizedFood.contains('leche') ||
              normalizedFood.contains('huevo'))) {
        return 'Patrón dietario: ${profile.dietaryPattern} (sin lácteos ni huevos)';
      }
    }

    return 'Motivo desconocido';
  }
}
