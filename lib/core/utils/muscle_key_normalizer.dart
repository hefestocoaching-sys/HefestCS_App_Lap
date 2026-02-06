import 'package:flutter/foundation.dart';
import 'package:hcs_app_lap/core/constants/muscle_keys.dart';
import 'package:hcs_app_lap/core/registry/muscle_registry.dart' as registry;

/// DELEGADO AL SSOT: Usa registry.normalize() para garantía de canónico.
///
/// PARTE 1 A6: Normaliza TODAS las variantes clínicas/UI a claves canónicas
/// que usa el motor internamente.
///
/// EJEMPLOS:
/// - deltoide_anterior → deltoide_anterior (canónico)
/// - hombro anterior → deltoide_anterior
/// - espalda_alta → upper_back
/// - dorsal / lats → lats
///
/// NO inventa músculos nuevos. Solo mapea variantes a las 14 claves canónicas.
/// Para grupos, retorna el token estándar canónico ("back", "shoulders", etc.).
String normalizeMuscleKey(String raw) {
  // Usar MuscleRegistry como SSOT
  final canonical = registry.normalize(raw);
  if (canonical != null) {
    // Log temporal para debugging (TAREA A6)
    if (raw.toLowerCase() != canonical) {
      debugPrint('[VOP][Normalizer] "$raw" → "$canonical"');
    }
    return canonical;
  }

  // Fallback: legacy behavior para claves no canónicas (grupos)
  // Usar registry para validar grupo expansión
  final expanded = registry.expandGroup(raw);
  if (expanded.isNotEmpty) {
    // Es un grupo válido, retornar el TOKEN CANÓNICO del grupo
    // P0: Mapear variantes españolas a tokens estándar ingleses
    final groupToken = _mapGroupVariantToCanonicalToken(raw);
    debugPrint(
      '[VOP][Normalizer] Grupo "$raw" → $groupToken (expande a ${expanded.join(", ")})',
    );
    return groupToken;
  }

  // Si no es nada conocido, retornar como-está (log advertencia)
  debugPrint('⚠️  [VOP][Normalizer] Clave desconocida: "$raw"');
  return raw.toLowerCase();
}

/// Mapea variantes de grupo a tokens canónicos estándar.
/// P0 REGLA: "Espalda" y variantes → "back"; "Hombros" y variantes → "shoulders"
String _mapGroupVariantToCanonicalToken(String raw) {
  final lower = raw.toLowerCase().trim();

  // Grupo Espalda
  if (lower == 'espalda' ||
      lower == 'back' ||
      lower == 'back_group' ||
      lower == 'espalda_group') {
    return 'back';
  }

  // Grupo Hombros
  if (lower == 'hombros' ||
      lower == 'hombro' ||
      lower == 'shoulders' ||
      lower == 'shoulders_group') {
    return 'shoulders';
  }

  // Grupo Piernas
  if (lower == 'piernas' || lower == 'legs' || lower == 'legs_group') {
    return 'legs';
  }

  // Grupo Brazos
  if (lower == 'brazos' || lower == 'arms' || lower == 'arms_group') {
    return 'arms';
  }

  // Fallback: retornar lowercase directamente
  return lower;
}

/// Normaliza un mapa completo de VOP legacy hacia las 14 claves canónicas
///
/// ENTRADA: Map con keys UI (español, variaciones, grupos legacy) y valores
/// SALIDA: Mapa con claves canónicas (14) y valores int
///
/// COMPORTAMIENTO:
/// - Aplica regla P0 de espalda/hombro para evitar doble conteo
/// - Expande grupos a músculos individuales
/// - Filtra cualquier key no canónica
Map<String, int> normalizeVopMapToInternal(Map<dynamic, dynamic> raw) {
  // Wrapper legacy: mantener compatibilidad con llamadas existentes
  return normalizeLegacyVopToCanonical(raw);
}

/// Normaliza y migra VOP legacy a claves canónicas sin doble conteo
/// Regla P0: "back" solo se expande a grupo si no existen lats/traps
Map<String, int> normalizeLegacyVopToCanonical(Map<dynamic, dynamic> raw) {
  final tmp = <String, int>{};

  // 1) parse + normalize keys (sin expandir aún)
  raw.forEach((k, v) {
    final keyStr = k.toString();
    final norm = normalizeMuscleKey(keyStr);

    int? value;
    if (v is num) value = v.toInt();
    if (v is Map && v['total'] is num) value = (v['total'] as num).toInt();
    if (value == null || value <= 0) return;

    tmp[norm] = (tmp[norm] ?? 0) + value;
  });

  // 2) Regla P0 back/shoulders sin doble conteo
  final hasLats = tmp.containsKey('lats');
  final hasTraps = tmp.containsKey('traps');
  if (tmp.containsKey('back')) {
    final backVal = tmp.remove('back') ?? 0;
    if (hasLats || hasTraps) {
      tmp['upper_back'] = (tmp['upper_back'] ?? 0) + backVal;
    } else {
      tmp['back_group'] = (tmp['back_group'] ?? 0) + backVal;
    }
  }

  final hasAnyDelt =
      tmp.containsKey('deltoide_anterior') ||
      tmp.containsKey('deltoide_lateral') ||
      tmp.containsKey('deltoide_posterior');

  if (tmp.containsKey('shoulders')) {
    final shVal = tmp.remove('shoulders') ?? 0;
    if (hasAnyDelt) {
      tmp['deltoide_lateral'] = (tmp['deltoide_lateral'] ?? 0) + shVal;
    } else {
      tmp['shoulders_group'] = (tmp['shoulders_group'] ?? 0) + shVal;
    }
  }

  // 3) Expandir grupos si quedaron
  final expanded = expandGroupsToIndividualMuscles(tmp);

  // 4) Filtrar SOLO canónicas (14)
  final out = <String, int>{};
  for (final e in expanded.entries) {
    if (e.value <= 0) { continue; }
    // Filtrar tokens _group que no fueron expandidos (no debería ocurrir con new logic)
    if (e.key == 'back_group' ||
        e.key == 'shoulders_group' ||
        e.key == 'legs_group' ||
        e.key == 'arms_group') {
      continue;
    }
    // P0: Filtrar también tokens estándar de grupo que no fueron expandidos
    if (e.key == 'back' ||
        e.key == 'shoulders' ||
        e.key == 'legs' ||
        e.key == 'arms') {
      continue;
    }
    if (MuscleKeys.isCanonical(e.key)) out[e.key] = e.value;
  }
  return out;
}

/// Expande grupos UI a músculos internos individuales
///
/// ENTRADA: Map con keys que pueden incluir grupos (_group suffix)
/// SALIDA: Map con keys solo de músculos individuales
///
/// Ejemplo: {'espalda_group': 20} → {'dorsal_ancho': 10, 'romboides': 5, 'trapecio_medio': 5}
Map<String, int> expandGroupsToIndividualMuscles(Map<String, int> vop) {
  final result = <String, int>{};

  const groupExpansion = {
    'back_group': ['lats', 'upper_back', 'traps'],
    'shoulders_group': [
      'deltoide_anterior',
      'deltoide_lateral',
      'deltoide_posterior',
    ],
    'legs_group': ['quads', 'hamstrings', 'glutes', 'calves'],
    'arms_group': ['biceps', 'triceps'],
  };

  vop.forEach((k, v) {
    if (groupExpansion.containsKey(k)) {
      final muscles = groupExpansion[k]!;
      final per = v ~/ muscles.length;
      var rem = v % muscles.length;
      for (final m in muscles) {
        final add = per + (rem > 0 ? 1 : 0);
        result[m] = (result[m] ?? 0) + add;
        if (rem > 0) rem--;
      }
    } else {
      result[k] = (result[k] ?? 0) + v;
    }
  });

  return result;
}
