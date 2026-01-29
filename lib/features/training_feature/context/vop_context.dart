import 'package:hcs_app_lap/core/constants/muscle_keys.dart';
import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/core/utils/muscle_key_normalizer.dart';
import 'package:hcs_app_lap/domain/training/vop_snapshot.dart';

/// Contexto de solo lectura para el VOP (SSOT).
/// - Nunca infiere ni recalcula
/// - Usa `training.extra['vopSnapshot']`
/// - Puede migrar una sola vez desde mapas legacy
class VopContext {
  final VopSnapshot snapshot;

  const VopContext(this.snapshot);

  int? getSetsFor(String muscleInternal) =>
      snapshot.setsByMuscle[muscleInternal];

  bool get hasData => !snapshot.isEmpty;

  // ──────────────────────────────
  // Lectura / Migración
  // ──────────────────────────────

  /// Lee snapshot canónico desde training.extra.
  static VopSnapshot? read(Map<String, dynamic>? extra) {
    if (extra == null) return null;
    final raw = extra[TrainingExtraKeys.vopSnapshot];
    if (raw is Map<String, dynamic>) {
      try {
        final snapshot = VopSnapshot.fromMap(raw);
        if (!snapshot.isEmpty) return snapshot;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Migra desde mapas legacy (finalTargetSetsByMuscleUi/targetSetsByMuscle*).
  static VopSnapshot? migrateFromLegacy(Map<String, dynamic>? extra) {
    if (extra == null) return null;

    final legacy =
        extra[TrainingExtraKeys.finalTargetSetsByMuscleUi] ??
        extra['targetSetsByMuscle'] ??
        extra[TrainingExtraKeys.targetSetsByMuscleUi];

    if (legacy is! Map) return null;

    final normalizedRaw = normalizeVopMapToInternal(legacy);
    final expanded = expandGroupsToIndividualMuscles(normalizedRaw);

    // Filtrar solo keys canónicas (inglés)
    final normalized = <String, int>{};
    expanded.forEach((k, v) {
      if (v > 0 && MuscleKeys.isCanonical(k)) {
        normalized[k] = v;
      }
    });

    if (normalized.isEmpty) return null;

    return VopSnapshot(
      setsByMuscle: normalized,
      updatedAt: DateTime.now(),
      source: 'migration',
    );
  }

  /// Devuelve contexto listo para usar.
  /// Si ya existe snapshot pero está incompleto/stale, intenta migrar desde legacy
  /// y hace upgrade si el migrado es más completo.
  static VopContext? ensure(Map<String, dynamic> extra) {
    final existing = read(extra);

    // Siempre intentar migración desde legacy para upgrade determinístico
    final migrated = migrateFromLegacy(extra);

    // Caso A: no existe snapshot -> si hay migrado, persistirlo
    if (existing == null || existing.isEmpty) {
      if (migrated != null && !migrated.isEmpty) {
        extra[TrainingExtraKeys.vopSnapshot] = migrated.toMap();
        return VopContext(migrated);
      }
      return null;
    }

    // Caso B: existe snapshot -> si migrado es MÁS COMPLETO, hacer upgrade
    if (migrated != null && !migrated.isEmpty) {
      final existingCount = existing.setsByMuscle.length;
      final migratedCount = migrated.setsByMuscle.length;

      // Upgrade por completitud (evita quedar atrapado con snapshots de 10 keys)
      if (migratedCount > existingCount) {
        extra[TrainingExtraKeys.vopSnapshot] = migrated.toMap();
        return VopContext(migrated);
      }
    }

    // Caso C: snapshot existente es el SSOT
    return VopContext(existing);
  }

  /// Persiste snapshot canónico en una copia de extra.
  static Map<String, dynamic> writeSnapshot(
    Map<String, dynamic> extra,
    VopSnapshot snapshot,
  ) {
    final out = Map<String, dynamic>.from(extra);
    out[TrainingExtraKeys.vopSnapshot] = snapshot.toMap();
    return out;
  }
}
