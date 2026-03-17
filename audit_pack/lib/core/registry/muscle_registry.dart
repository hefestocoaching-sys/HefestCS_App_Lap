// SSOT (Single Source of Truth) para músculos canónicos.
// Este archivo es el ÚNICO lugar donde se definen los 14 músculos individuales.
// Todas las normalizaciones y expansiones deben usar este registro.

const Set<String> canonicalMuscles = {
  'pectorals',
  'lats',
  'upper_back',
  'traps',
  'delts_front',
  'delts_lateral',
  'delts_rear',
  'biceps',
  'triceps',
  'quads',
  'hamstrings',
  'glutes',
  'calves',
  'abs',
};

/// Normaliza una clave de músculo arbitraria a canónica.
///
/// REGLA CRÍTICA: NUNCA devuelve un string fuera de CANONICAL_MUSCLES.
/// Si la entrada no coincide con ningún canónico, retorna null.
///
/// ENTRADA: Puede ser:
/// - Canónica: 'chest', 'lats', etc.
/// - Española: 'pecho', 'espalda', 'hombro'
/// - Grupo legacy: 'back', 'shoulders', 'legs', 'arms'
/// - Variantes: 'bicep' → 'biceps', 'cuádriceps' → 'quads'
///
/// SALIDA: Exactamente una de las 14 claves canónicas o null.
String? normalize(String rawKey) {
  if (rawKey.isEmpty) return null;

  // Preprocessing: camelCase → spaces, lower, trim
  final pre = rawKey
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .replaceAll('_', ' ')
      .toLowerCase()
      .trim();

  // Diacrítiques
  const accents = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
    'ñ': 'n',
  };
  final buffer = StringBuffer();
  for (final rune in pre.runes) {
    final ch = String.fromCharCode(rune);
    buffer.write(accents[ch] ?? ch);
  }
  final normalized = buffer.toString().trim();

  // Map: variantes → canónico
  const aliases = {
    // Canónico directo
    'pectorals': 'pectorals',
    'chest': 'pectorals',
    'pecho': 'pectorals',
    'pectoral': 'pectorals',
    'pectorales': 'pectorals',

    'lats': 'lats',
    'dorsal ancho': 'lats',
    'latissimus': 'lats',
    'dorsal': 'lats',

    'upper back': 'upper_back',
    'upper_back': 'upper_back',
    'espalda alta': 'upper_back',
    'romboides': 'upper_back',

    'traps': 'traps',
    'trapecios': 'traps',
    'trapecio': 'traps',
    'trapezius': 'traps',
    'trapezio': 'traps',
    // Trapecio (subpartes -> traps)
    'traps upper': 'traps',
    'traps middle': 'traps',
    'traps lower': 'traps',
    'trap upper': 'traps',
    'trap middle': 'traps',
    'trap lower': 'traps',
    'traps_upper': 'traps',
    'traps_middle': 'traps',
    'traps_lower': 'traps',
    'trapsupper': 'traps',

    'delts_front': 'delts_front',
    'delts front': 'delts_front',
    'deltoide anterior': 'delts_front',
    'deltoide_anterior': 'delts_front',
    'deltoides anterior': 'delts_front',
    'front delt anterior': 'delts_front',
    'hombro anterior': 'delts_front',
    'deltoide frontal': 'delts_front',

    'delts_lateral': 'delts_lateral',
    'delts lateral': 'delts_lateral',
    'deltoide lateral': 'delts_lateral',
    'deltoide_lateral': 'delts_lateral',
    'deltoides lateral': 'delts_lateral',
    'side delt lateral': 'delts_lateral',
    'hombro lateral': 'delts_lateral',

    'delts_rear': 'delts_rear',
    'delts rear': 'delts_rear',
    'deltoide posterior': 'delts_rear',
    'deltoide_posterior': 'delts_rear',
    'deltoides posterior': 'delts_rear',
    'rear delt posterior': 'delts_rear',
    'hombro posterior': 'delts_rear',

    'biceps': 'biceps',
    'bicep': 'biceps',
    'bicepses': 'biceps',
    'biceps braquial': 'biceps',

    'triceps': 'triceps',
    'tricep': 'triceps',
    'tricepses': 'triceps',
    'triceps braquial': 'triceps',

    'quads': 'quads',
    'quad': 'quads',
    'cuadriceps': 'quads',
    'cuádriceps': 'quads',
    'quadriceps': 'quads',
    'cuadricep': 'quads',
    'muslo anterior': 'quads',
    'femorales anteriores': 'quads',

    'hamstrings': 'hamstrings',
    'hamstring': 'hamstrings',
    'isquios': 'hamstrings',
    'isquiosurales': 'hamstrings',
    'isquiotibiales': 'hamstrings',
    'muslo posterior': 'hamstrings',
    'femorales posteriores': 'hamstrings',

    'glutes': 'glutes',
    'glute': 'glutes',
    'gluteo': 'glutes',
    'glúteo': 'glutes',
    'gluteos': 'glutes',
    'glúteos': 'glutes',
    'nalgas': 'glutes',
    'gluteo maximo': 'glutes',

    'calves': 'calves',
    'calf': 'calves',
    'pantorrilla': 'calves',
    'pantorrillas': 'calves',
    'gemelo': 'calves',
    'gemelos': 'calves',
    'gastrocnemio': 'calves',
    'soleo': 'calves',
    // Pantorrilla (variantes en inglés)
    'gastrocnemius': 'calves',
    'soleus': 'calves',

    'abs': 'abs',
    'abdomen': 'abs',
    'abdominales': 'abs',
    'obliques': 'abs',
    'core': 'abs',
  };

  final canonical = aliases[normalized];
  if (canonical != null && canonicalMuscles.contains(canonical)) {
    return canonical;
  }

  return null;
}

/// Expande un grupo de músculos (legacy) a claves canónicas.
///
/// ENTRADA: Grupo como 'back', 'shoulders', 'legs', 'arms'
/// SALIDA: List con claves canónicas individuales
///
/// GARANTIA: Todos los elementos retornados estan en canonicalMuscles
List<String> expandGroup(String groupKey) {
  final norm = normalize(groupKey);

  // Si ya es canónico individual, retornar directo
  if (norm != null && canonicalMuscles.contains(norm)) {
    return [norm];
  }

  // Grupos explícitos legacy
  const groups = {
    'back': ['lats', 'upper_back'],
    'espalda': ['lats', 'upper_back'],
    'back_group': ['lats', 'upper_back'],

    'shoulders': ['delts_front', 'delts_lateral', 'delts_rear'],
    'hombros': ['delts_front', 'delts_lateral', 'delts_rear'],
    'hombro': ['delts_front', 'delts_lateral', 'delts_rear'],
    'shoulders_group': ['delts_front', 'delts_lateral', 'delts_rear'],

    'legs': ['quads', 'hamstrings', 'glutes', 'calves'],
    'piernas': ['quads', 'hamstrings', 'glutes', 'calves'],
    'legs_group': ['quads', 'hamstrings', 'glutes', 'calves'],

    'arms': ['biceps', 'triceps'],
    'brazos': ['biceps', 'triceps'],
    'arms_group': ['biceps', 'triceps'],
  };

  final normalized = groupKey.toLowerCase().trim();
  final expanded = groups[normalized];

  if (expanded != null) {
    // Validation: all must be canonical
    assert(
      expanded.every(canonicalMuscles.contains),
      'Expanded group contains non-canonical muscles',
    );
    return List.unmodifiable(expanded);
  }

  // Si no es grupo conocido, retornar lista vacía
  return const [];
}

/// Valida si una clave está en el conjunto canónico.
bool isCanonical(String key) => canonicalMuscles.contains(key);

/// Retorna la lista ordenada de todos los 14 músculos canónicos.
List<String> getAllCanonical() => canonicalMuscles.toList()..sort();
