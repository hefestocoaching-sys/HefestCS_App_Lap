enum InjuryRegion {
  shoulder,
  elbow,
  wrist,
  lowerBack,
  hip,
  knee,
  ankle,
  neck,
  upperBack,
}

extension InjuryRegionX on InjuryRegion {
  String get label => switch (this) {
    InjuryRegion.shoulder => 'Hombro',
    InjuryRegion.elbow => 'Codo',
    InjuryRegion.wrist => 'Muñeca',
    InjuryRegion.lowerBack => 'Espalda Baja',
    InjuryRegion.hip => 'Cadera',
    InjuryRegion.knee => 'Rodilla',
    InjuryRegion.ankle => 'Tobillo',
    InjuryRegion.neck => 'Cuello',
    InjuryRegion.upperBack => 'Espalda Alta',
  };
}

InjuryRegion? parseInjuryRegion(String? value) {
  if (value == null) return null;
  final normalized = value.toLowerCase().trim();

  if (normalized.contains('hombro') || normalized.contains('shoulder')) {
    return InjuryRegion.shoulder;
  }
  if (normalized.contains('codo') || normalized.contains('elbow')) {
    return InjuryRegion.elbow;
  }
  if (normalized.contains('muñeca') || normalized.contains('wrist')) {
    return InjuryRegion.wrist;
  }
  if (normalized.contains('espalda baja') ||
      normalized.contains('lower back') ||
      normalized.contains('lumbar')) {
    return InjuryRegion.lowerBack;
  }
  if (normalized.contains('cadera') || normalized.contains('hip')) {
    return InjuryRegion.hip;
  }
  if (normalized.contains('rodilla') || normalized.contains('knee')) {
    return InjuryRegion.knee;
  }
  if (normalized.contains('tobillo') || normalized.contains('ankle')) {
    return InjuryRegion.ankle;
  }
  if (normalized.contains('cuello') ||
      normalized.contains('neck') ||
      normalized.contains('cervical')) {
    return InjuryRegion.neck;
  }
  if (normalized.contains('espalda alta') ||
      normalized.contains('upper back') ||
      normalized.contains('dorsal')) {
    return InjuryRegion.upperBack;
  }

  return null;
}
