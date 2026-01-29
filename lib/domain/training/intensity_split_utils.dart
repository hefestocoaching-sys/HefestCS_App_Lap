// lib/domain/training/intensity_split_utils.dart

/// Split redondeado y conservador:
/// - heavy y medium se redondean
/// - light absorbe el residuo para que heavy+medium+light = totalSets (en enteros)
Map<String, int> splitByIntensity({
  required double totalSets,
  required Map<String, double> intensitySplit,
}) {
  final heavyRatio = intensitySplit['heavy'] ?? 0.0;
  final mediumRatio = intensitySplit['medium'] ?? 0.0;
  final lightRatio = intensitySplit['light'] ?? 0.0;

  // Guardrail simple: si no suma ~1, normaliza suavemente para evitar drift.
  final sum = heavyRatio + mediumRatio + lightRatio;
  final normalizedHeavy = sum > 0 ? heavyRatio / sum : 0.3;
  final normalizedLight = sum > 0 ? lightRatio / sum : 0.3;

  final total = totalSets.isFinite ? totalSets : 0.0;

  // Redondear heavy y light, y ajustar residuo en medium (regla clínica)
  final heavy = (total * normalizedHeavy).round();
  final light = (total * normalizedLight).round();
  final medium = total.round() - heavy - light;

  final safeMedium = medium < 0 ? 0 : medium;
  final diff = total.round() - heavy - light - safeMedium;

  return {
    'heavy': heavy,
    'medium': safeMedium + diff, // cualquier ajuste extra va a medium
    'light': light,
  };
}
