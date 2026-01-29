/// Utilidad para hacer deep merge de mapas anidados.
///
/// El merge shallow `{...oldExtra, ...newExtra}` pierde Maps anidados
/// como `mevByMuscle`, `mrvByMuscle`, `targetSetsByMuscle` cuando el
/// Motor V2 los genera.
///
/// Esta función hace merge recursivo:
/// - Si un valor es Map en ambos, hace merge recursivo.
/// - Si solo existe en uno, lo preserva.
/// - Los escalares de incoming sobrescriben a base.
library;

/// Hace merge profundo de dos mapas, preservando Maps anidados.
///
/// Ejemplo:
/// ```dart
/// final base = {'a': 1, 'nested': {'x': 10}};
/// final incoming = {'b': 2, 'nested': {'y': 20}};
/// final result = deepMerge(base, incoming);
/// // result = {'a': 1, 'b': 2, 'nested': {'x': 10, 'y': 20}}
/// ```
Map<String, dynamic> deepMerge(
  Map<String, dynamic> base,
  Map<String, dynamic> incoming,
) {
  final result = Map<String, dynamic>.from(base);

  for (final entry in incoming.entries) {
    final key = entry.key;
    final value = entry.value;

    if (value is Map && result[key] is Map) {
      // Ambos son Maps: merge recursivo
      result[key] = deepMerge(
        Map<String, dynamic>.from(result[key] as Map),
        Map<String, dynamic>.from(value),
      );
    } else {
      // Escalar o solo uno es Map: incoming sobrescribe
      result[key] = value;
    }
  }

  return result;
}

/// Extensión para hacer deep merge directamente en un Map.
extension DeepMergeExtension on Map<String, dynamic> {
  /// Retorna un nuevo Map con deep merge de [other].
  Map<String, dynamic> deepMergeWith(Map<String, dynamic> other) {
    return deepMerge(this, other);
  }
}
