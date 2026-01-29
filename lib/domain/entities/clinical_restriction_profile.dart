import 'package:hcs_app_lap/domain/entities/clinical_conditions.dart';
import 'package:hcs_app_lap/domain/entities/digestive_intolerances.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// Perfil Clínico Computable P0 — SSOT para motor de nutrición
/// ═══════════════════════════════════════════════════════════════════════════
/// Contiene SOLO campos cerrados, no strings libres.
/// Motor de nutrición lee esta clase para filtrar alimentos y reglas.
///
/// GARANTÍAS:
/// - Null-safe: NUNCA null, siempre tiene defaults seguros
/// - Computable: SOLO booleanos y enums controlados
/// - Serializable: fromMap/toMap preservan integridad
/// - Backward-compatible: Si no existe, se crea default automáticamente
class ClinicalRestrictionProfile {
  /// Alergias alimentarias (alergias IgE mediadas, P0 máxima prioridad)
  /// Keys canónicas: milk, egg, fish, shellfish, peanuts, treeNuts, wheat, soy, sesame
  final Map<String, bool> foodAllergies;

  /// Intolerancias digestivas (no IgE, severidad variable)
  final DigestiveIntolerances digestiveIntolerances;

  /// Condiciones clínicas que impactan nutrición
  final ClinicalConditions clinicalConditions;

  /// Patrón dietario por creencias/religión/preferencia
  /// Values: omnivore, vegetarian, vegan, pescatarian, halal, kosher
  final String dietaryPattern;

  /// Medicamentos que interactúan con nutrientes (P0 relevancia)
  /// Keys canónicas: warfarin, metformin, levothyroxine, antacids, etc.
  final Map<String, bool> relevantMedications;

  /// Notas clínicas adicionales (degradación de legacy fields)
  final String? additionalNotes;

  const ClinicalRestrictionProfile({
    required this.foodAllergies,
    required this.digestiveIntolerances,
    required this.clinicalConditions,
    required this.dietaryPattern,
    required this.relevantMedications,
    this.additionalNotes,
  });

  /// Defaults seguros: sin alergias, sin intolerancias, sin patologías, omnívoro
  factory ClinicalRestrictionProfile.defaults() {
    return ClinicalRestrictionProfile(
      foodAllergies: {
        'milk': false,
        'egg': false,
        'fish': false,
        'shellfish': false,
        'peanuts': false,
        'treeNuts': false,
        'wheat': false,
        'soy': false,
        'sesame': false,
      },
      digestiveIntolerances: DigestiveIntolerances.defaults(),
      clinicalConditions: ClinicalConditions.defaults(),
      dietaryPattern: 'omnivore',
      relevantMedications: {},
      additionalNotes: null,
    );
  }

  /// Deserialización segura desde Map (nunca falla)
  factory ClinicalRestrictionProfile.fromMap(Map<String, dynamic> map) {
    // Parse foodAllergies con defaults seguros
    final Map<String, bool> foodAllergies = {};
    final allergiesRaw = map['foodAllergies'];
    if (allergiesRaw is Map) {
      allergiesRaw.forEach((key, value) {
        if (key is String && value is bool) {
          foodAllergies[key] = value;
        }
      });
    }
    // Asegurar que todas las claves canónicas existan
    const canonicalAllergies = [
      'milk',
      'egg',
      'fish',
      'shellfish',
      'peanuts',
      'treeNuts',
      'wheat',
      'soy',
      'sesame',
    ];
    for (final allergen in canonicalAllergies) {
      foodAllergies.putIfAbsent(allergen, () => false);
    }

    // Parse dietaryPattern con validación
    String dietaryPattern = map['dietaryPattern'] as String? ?? 'omnivore';
    const validPatterns = [
      'omnivore',
      'vegetarian',
      'vegan',
      'pescatarian',
      'halal',
      'kosher',
    ];
    if (!validPatterns.contains(dietaryPattern)) {
      dietaryPattern = 'omnivore'; // Fallback seguro
    }

    // Parse medications
    final Map<String, bool> medications = {};
    final medicationsRaw = map['relevantMedications'];
    if (medicationsRaw is Map) {
      medicationsRaw.forEach((key, value) {
        if (key is String && value is bool) {
          medications[key] = value;
        }
      });
    }

    return ClinicalRestrictionProfile(
      foodAllergies: foodAllergies,
      digestiveIntolerances: map['digestiveIntolerances'] is Map
          ? DigestiveIntolerances.fromMap(
              Map<String, dynamic>.from(map['digestiveIntolerances'] as Map),
            )
          : DigestiveIntolerances.defaults(),
      clinicalConditions: map['clinicalConditions'] is Map
          ? ClinicalConditions.fromMap(
              Map<String, dynamic>.from(map['clinicalConditions'] as Map),
            )
          : ClinicalConditions.defaults(),
      dietaryPattern: dietaryPattern,
      relevantMedications: medications,
      additionalNotes: map['additionalNotes'] as String?,
    );
  }

  /// Serialización segura a Map
  Map<String, dynamic> toMap() {
    return {
      'foodAllergies': foodAllergies,
      'digestiveIntolerances': digestiveIntolerances.toMap(),
      'clinicalConditions': clinicalConditions.toMap(),
      'dietaryPattern': dietaryPattern,
      'relevantMedications': relevantMedications,
      'additionalNotes': additionalNotes,
    };
  }

  ClinicalRestrictionProfile copyWith({
    Map<String, bool>? foodAllergies,
    DigestiveIntolerances? digestiveIntolerances,
    ClinicalConditions? clinicalConditions,
    String? dietaryPattern,
    Map<String, bool>? relevantMedications,
    String? additionalNotes,
  }) {
    return ClinicalRestrictionProfile(
      foodAllergies: foodAllergies ?? this.foodAllergies,
      digestiveIntolerances:
          digestiveIntolerances ?? this.digestiveIntolerances,
      clinicalConditions: clinicalConditions ?? this.clinicalConditions,
      dietaryPattern: dietaryPattern ?? this.dietaryPattern,
      relevantMedications: relevantMedications ?? this.relevantMedications,
      additionalNotes: additionalNotes ?? this.additionalNotes,
    );
  }

  /// Conveniencia: ¿tiene alguna alergia activa?
  bool hasActiveFoodAllergies() =>
      foodAllergies.values.any((isActive) => isActive);

  /// Conveniencia: ¿tiene alguna intolerancia activa?
  bool hasActiveDigestiveIntolerances() =>
      digestiveIntolerances.lactose != DigestiveSeverity.none ||
      digestiveIntolerances.gluten != DigestiveSeverity.none ||
      digestiveIntolerances.fodmaps != DigestiveSeverity.none;

  /// Conveniencia: ¿tiene alguna condición clínica?
  bool hasActiveClinicalConditions() =>
      clinicalConditions.diabetes ||
      clinicalConditions.renalDisease ||
      clinicalConditions.giDisorders ||
      clinicalConditions.thyroidDisorders ||
      clinicalConditions.hypertension ||
      clinicalConditions.dyslipidemia;

  /// Conveniencia: ¿No es omnívoro?
  bool hasRestrictedDietaryPattern() => dietaryPattern != 'omnivore';

  @override
  String toString() {
    return 'ClinicalRestrictionProfile('
        'allergies: $hasActiveFoodAllergies, '
        'intolerances: $hasActiveDigestiveIntolerances, '
        'conditions: $hasActiveClinicalConditions, '
        'diet: $dietaryPattern)';
  }
}
