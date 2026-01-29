/// EJEMPLOS DE USO: ClinicalRestrictionValidator en Motor Nutrición
///
/// Este archivo muestra patrones de integración del validador P0
/// en el motor de nutrición para seguridad clínica.

import 'package:hcs_app_lap/domain/entities/clinical_restriction_profile.dart';
import 'package:hcs_app_lap/domain/services/clinical_restriction_validator.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// EJEMPLO 1: Validar un alimento individual antes de agregarlo al plan
/// ═══════════════════════════════════════════════════════════════════════════

void addFoodToMealPlan(String foodName, NutritionSettings nutritionSettings) {
  final profile = nutritionSettings.clinicalRestrictionProfile;

  if (ClinicalRestrictionValidator.isFoodAllowed(
    foodName: foodName,
    profile: profile,
  )) {
    // ✅ Alimento permitido: agregar al plan
    print('✅ Alimento "$foodName" permitido. Agregando...');
    // mealPlan.add(food);
  } else {
    // ❌ Alimento bloqueado: mostrar razón al usuario
    final reason = ClinicalRestrictionValidator.explainFoodBlockage(
      foodName: foodName,
      profile: profile,
    );
    print('❌ Alimento "$foodName" NO permitido: $reason');
    // UI: mostrar alerta con la razón
  }
}

// Uso:
// addFoodToMealPlan("Leche de vaca", nutritionSettings);
// → ❌ Alimento "Leche de vaca" NO permitido: Alergia a milk (activa)

// addFoodToMealPlan("Pollo", nutritionSettings);
// → ❌ Alimento "Pollo" NO permitido: Patrón dietario vegan no permite meat

// addFoodToMealPlan("Arroz blanco", nutritionSettings);
// → ✅ Alimento "Arroz blanco" permitido. Agregando...

/// ═══════════════════════════════════════════════════════════════════════════
/// EJEMPLO 2: Filtrar lista de alimentos (batch filtering)
/// ═══════════════════════════════════════════════════════════════════════════

List<String> getSafeEquivalents(
  String originalFood,
  List<String> suggestedEquivalents,
  NutritionSettings nutritionSettings,
) {
  final profile = nutritionSettings.clinicalRestrictionProfile;

  // Filtrar solo equivalentes permitidos
  final safeEquivalents = ClinicalRestrictionValidator.filterAllowedFoods(
    foodNames: suggestedEquivalents,
    profile: profile,
  );

  if (safeEquivalents.isEmpty) {
    print('⚠️ No hay equivalentes seguros para "$originalFood"');
    return [];
  }

  print('✅ Equivalentes permitidos para "$originalFood":');
  for (final equivalent in safeEquivalents) {
    print('   • $equivalent');
  }

  return safeEquivalents;
}

// Uso:
// final equivalents = getSafeEquivalents(
//   "Leche de vaca",
//   ["Leche de almendra", "Leche de coco", "Leche de soja", "Leche de avena"],
//   nutritionSettings,
// );
// → ✅ Equivalentes permitidos para "Leche de vaca":
//    • Leche de almendra  ✅ (sin alergia a almendras)
//    • Leche de coco      ✅ (sin alergia a coco)
//    • Leche de soja      ❌ (alergia a soja)
//    • Leche de avena     ✅ (sin alergia a granos)

/// ═══════════════════════════════════════════════════════════════════════════
/// EJEMPLO 3: Motor sugerencia (respetando restricciones)
/// ═══════════════════════════════════════════════════════════════════════════

class NutritionMotor {
  final NutritionSettings settings;

  NutritionMotor(this.settings);

  /// Sugerir comida respetando restricciones clínicas P0
  String suggestMeal(String mealType) {
    final profile = settings.clinicalRestrictionProfile;

    // Banco de sugerencias por tipo de comida
    final suggestions = {
      'breakfast': [
        'Avena con leche',
        'Huevos con pan',
        'Yogurt con frutas',
        'Tostadas con mantequilla',
      ],
      'lunch': [
        'Pechuga de pollo con arroz',
        'Filete de res con papas',
        'Merluza a la mantequilla',
        'Tacos de carne',
      ],
      'dinner': [
        'Sopa de verduras',
        'Pasta a la carbonara',
        'Atún a la parrilla',
        'Omelette con queso',
      ],
    };

    final options = suggestions[mealType] ?? [];

    // Filtrar opciones según restricciones P0
    final safeOptions = ClinicalRestrictionValidator.filterAllowedFoods(
      foodNames: options,
      profile: profile,
    );

    if (safeOptions.isEmpty) {
      return '⚠️ No hay opciones disponibles respetando restricciones clínicas';
    }

    // Sugerir opción aleatoria
    safeOptions.shuffle();
    return '✅ Sugerencia para $mealType: ${safeOptions.first}';
  }

  /// Validar plan de comidas completo
  Map<String, String> validateMealPlan(Map<String, List<String>> mealPlan) {
    final profile = settings.clinicalRestrictionProfile;
    final report = <String, String>{};

    for (final entry in mealPlan.entries) {
      final mealType = entry.key; // "breakfast", "lunch", etc.
      final foods = entry.value; // ["Huevos", "Pan", ...]

      // Validar cada comida
      final validFoods = ClinicalRestrictionValidator.filterAllowedFoods(
        foodNames: foods,
        profile: profile,
      );

      final blockedFoods = foods.where((f) => !validFoods.contains(f)).toList();

      if (blockedFoods.isNotEmpty) {
        report[mealType] =
            '⚠️ Alimentos bloqueados: ${blockedFoods.join(", ")}';
      } else {
        report[mealType] = '✅ Comida válida';
      }
    }

    return report;
  }
}

// Uso:
// final motor = NutritionMotor(nutritionSettings);
// print(motor.suggestMeal('breakfast'));
// → ✅ Sugerencia para breakfast: Avena con leche

// final validation = motor.validateMealPlan({
//   'breakfast': ['Huevos', 'Pan', 'Leche'],
//   'lunch': ['Pollo', 'Arroz'],
//   'dinner': ['Pasta', 'Atún'],
// });
// → {breakfast: ⚠️ Alimentos bloqueados: Leche, lunch: ✅ Comida válida, ...}

/// ═══════════════════════════════════════════════════════════════════════════
/// EJEMPLO 4: Diagnóstico para UI (explicar bloqueos al usuario)
/// ═══════════════════════════════════════════════════════════════════════════

class FoodBlockageNotifier {
  final NutritionSettings settings;

  FoodBlockageNotifier(this.settings);

  /// Mostrar explicación amigable de por qué un alimento está bloqueado
  String getUserMessage(String foodName) {
    final profile = settings.clinicalRestrictionProfile;
    final reason = ClinicalRestrictionValidator.explainFoodBlockage(
      foodName: foodName,
      profile: profile,
    );

    if (reason.isEmpty) {
      return '✅ Este alimento está permitido en tu plan nutricional';
    }

    // Mapear razones técnicas a mensajes amigables
    if (reason.contains('Alergia')) {
      return '⚠️ Tienes una alergia documentada a este alimento. No es seguro consumirlo.';
    }

    if (reason.contains('dietario')) {
      return '⚠️ Este alimento no coincide con tu patrón dietario actual.';
    }

    if (reason.contains('intolerancia')) {
      return '⚠️ Tienes intolerancia documentada a este alimento.';
    }

    return '⚠️ Este alimento no es recomendado según tu perfil clínico.';
  }

  /// Sugerir alternativa segura
  String? suggestSafeAlternative(String blockedFood) {
    final profile = settings.clinicalRestrictionProfile;

    // Banco de alternativas por alimento bloqueado
    const alternatives = {
      'Leche': ['Leche de almendra', 'Leche de coco', 'Leche de avena'],
      'Huevo': ['Sustituto de huevo', 'Tofu'],
      'Pollo': ['Pavo', 'Pechuga de res', 'Pescado'],
      'Trigo': ['Arroz', 'Maíz', 'Avena'],
      'Maní': ['Semillas de girasol', 'Almendras'],
    };

    final possibleAlternatives = alternatives[blockedFood] ?? [];

    // Filtrar solo alternativas seguras
    final safeAlternatives = ClinicalRestrictionValidator.filterAllowedFoods(
      foodNames: possibleAlternatives,
      profile: profile,
    );

    if (safeAlternatives.isNotEmpty) {
      safeAlternatives.shuffle();
      return 'Puedes probar: ${safeAlternatives.first}';
    }

    return null;
  }
}

// Uso:
// final notifier = FoodBlockageNotifier(nutritionSettings);
//
// print(notifier.getUserMessage('Leche'));
// → ⚠️ Tienes una alergia documentada a este alimento. No es seguro consumirlo.
//
// final alt = notifier.suggestSafeAlternative('Leche');
// print(alt);
// → Puedes probar: Leche de almendra

/// ═══════════════════════════════════════════════════════════════════════════
/// EJEMPLO 5: Reporte clínico para profesionales
/// ═══════════════════════════════════════════════════════════════════════════

String generateClinicalReport(
  String clientName,
  NutritionSettings nutritionSettings,
) {
  final profile = nutritionSettings.clinicalRestrictionProfile;

  final buffer = StringBuffer();

  buffer.writeln(
    '════════════════════════════════════════════════════════════',
  );
  buffer.writeln('REPORTE DE RESTRICCIONES CLÍNICAS NUTRICIONALES');
  buffer.writeln('Client: $clientName');
  buffer.writeln(
    '════════════════════════════════════════════════════════════\n',
  );

  // P0: Alergias
  buffer.writeln('🔴 ALERGIAS (P0 - BLOQUEO INMEDIATO):');
  final activeAllergies = profile.foodAllergies.entries
      .where((e) => e.value)
      .map((e) => e.key)
      .toList();

  if (activeAllergies.isEmpty) {
    buffer.writeln('  • Sin alergias documentadas');
  } else {
    for (final allergen in activeAllergies) {
      buffer.writeln('  ❌ $allergen');
    }
  }
  buffer.writeln('');

  // P0: Patrón dietario
  buffer.writeln('🟡 PATRÓN DIETARIO (P0 - RESTRICCIÓN):');
  buffer.writeln('  • ${profile.dietaryPattern}');
  buffer.writeln('');

  // P1: Intolerancias
  buffer.writeln('🟠 INTOLERANCIAS DIGESTIVAS (P1 - MONITOREO):');
  final intolerances = profile.digestiveIntolerances;
  if (intolerances.lactose.index > 0) {
    buffer.writeln('  • Lactosa: ${intolerances.lactose.name}');
  }
  if (intolerances.gluten.index > 0) {
    buffer.writeln('  • Gluten: ${intolerances.gluten.name}');
  }
  if (intolerances.fodmaps.index > 0) {
    buffer.writeln('  • FODMAPs: ${intolerances.fodmaps.name}');
  }
  buffer.writeln('');

  // P1: Condiciones clínicas
  buffer.writeln('🟠 CONDICIONES CLÍNICAS (P1 - OPTIMIZACIÓN):');
  final conditions = profile.clinicalConditions;
  final activeConditions = [
    if (conditions.diabetes) 'Diabetes',
    if (conditions.renalDisease) 'Enfermedad renal',
    if (conditions.giDisorders) 'Trastornos GI',
    if (conditions.thyroidDisorders) 'Trastornos tiroideos',
    if (conditions.hypertension) 'Hipertensión',
    if (conditions.dyslipidemia) 'Dislipidemia',
  ];

  if (activeConditions.isEmpty) {
    buffer.writeln('  • Sin condiciones clínicas relevantes');
  } else {
    for (final condition in activeConditions) {
      buffer.writeln('  • $condition');
    }
  }
  buffer.writeln('');

  // Notas adicionales
  if (profile.additionalNotes != null && profile.additionalNotes!.isNotEmpty) {
    buffer.writeln('📝 NOTAS ADICIONALES:');
    buffer.writeln('  ${profile.additionalNotes}');
    buffer.writeln('');
  }

  buffer.writeln(
    '════════════════════════════════════════════════════════════',
  );
  buffer.writeln('Generado: ${DateTime.now().toIso8601String()}');
  buffer.writeln(
    '════════════════════════════════════════════════════════════',
  );

  return buffer.toString();
}

// Uso:
// print(generateClinicalReport('Juan Pérez', nutritionSettings));
// →
// ════════════════════════════════════════════════════════════
// REPORTE DE RESTRICCIONES CLÍNICAS NUTRICIONALES
// Client: Juan Pérez
// ════════════════════════════════════════════════════════════
//
// 🔴 ALERGIAS (P0 - BLOQUEO INMEDIATO):
//   ❌ milk
//   ❌ soy
//
// 🟡 PATRÓN DIETARIO (P0 - RESTRICCIÓN):
//   • vegan
//
// 🟠 INTOLERANCIAS DIGESTIVAS (P1 - MONITOREO):
//   • Lactosa: mild
//   • FODMAPs: moderate
//
// 🟠 CONDICIONES CLÍNICAS (P1 - OPTIMIZACIÓN):
//   • Diabetes
//   • Hipertensión
//
// 📝 NOTAS ADICIONALES:
//   Alergia cruzada con polen de abedul
//
// ════════════════════════════════════════════════════════════

// LECCIÓN APRENDIDA:
// El motor puede usar estos patrones para:
// 1. Validar alimentos antes de agregarlos
// 2. Sugerir alternativas seguras
// 3. Filtrar planes de comidas
// 4. Generar reportes para profesionales
// 5. Mostrar explicaciones amigables a usuarios
