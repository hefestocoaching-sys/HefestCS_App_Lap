String muscleLabelEs(String raw) {
  final id = raw.trim().toLowerCase();

  const map = <String, String>{
    // Canónico (14 keys individuales)
    'chest': 'Pectoral',
    'lats': 'Dorsales',
    'upper_back': 'Espalda alta',
    'traps': 'Trapecio',
    'deltoide_anterior': 'Deltoide anterior',
    'deltoide_lateral': 'Deltoide lateral',
    'deltoide_posterior': 'Deltoide posterior',
    'biceps': 'Bíceps',
    'triceps': 'Tríceps',
    'quads': 'Cuádriceps',
    'hamstrings': 'Isquiosurales',
    'glutes': 'Glúteo',
    'calves': 'Pantorrilla',
    'abs': 'Abdomen',
    // Legacy (no canónico, para compatibilidad UI)
    'back': 'Espalda',
    'shoulders': 'Hombro',
    // Alternativas ES → canon (usadas por normalizer)
    'pectoral': 'Pectoral',
    'dorsal_ancho': 'Dorsales',
    'romboides': 'Espalda alta',
    'trapecio_superior': 'Trapecio',
    'trapecio_medio': 'Espalda alta',
    'gastrocnemio': 'Pantorrilla',
    'soleo': 'Pantorrilla',
    'cuadriceps': 'Cuádriceps',
    'isquiosurales': 'Isquiosurales',
    'gluteo': 'Glúteo',
    'abdomen': 'Abdomen',
  };

  return map[id] ??
      (id.isEmpty ? raw : (id[0].toUpperCase() + id.substring(1)));
}

String roleLabelEs(String raw) {
  final r = raw.trim().toLowerCase();
  if (r == 'primary' || r == 'primario') return 'Primario';
  if (r == 'secondary' || r == 'secundario') return 'Secundario';
  if (r == 'tertiary' || r == 'terciario') return 'Terciario';
  return raw;
}
