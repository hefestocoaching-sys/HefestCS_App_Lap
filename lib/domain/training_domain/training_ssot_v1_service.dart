import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/core/utils/muscle_key_normalizer.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/training_domain/training_evaluation_snapshot_v1.dart';
import 'package:hcs_app_lap/domain/training_domain/training_setup_v1.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// E3 SSOT V1 SERVICE: Repositorio único para leer/escribir TrainingSetupV1 + TrainingEvaluationSnapshotV1
/// ═══════════════════════════════════════════════════════════════════════════
///
/// RESPONSABILIDAD ÚNICA:
/// - Leer/escribir setupV1 y evaluationV1 desde/hacia client.training.extra
/// - Normalizar keys musculares (lats, upper_back, etc.)
/// - Garantizar exclusividad entre Primary/Secondary/Tertiary
/// - Espejeo (compat legacy) a keys antiguas (daysPerWeek, priorityMusclesPrimary, etc.)
///
/// REGLAS DE PERSISTENCIA:
/// 1) SSOT V1 = source of truth (trainingSetupV1, trainingEvaluationSnapshotV1)
/// 2) Legacy keys = espejo (backward compatibility)
/// 3) Normalización muscular obligatoria
/// 4) Exclusividad muscular estricta
/// ═══════════════════════════════════════════════════════════════════════════

class TrainingSsotV1Service {
  /// Lee TrainingSetupV1 desde client.training.extra
  /// Retorna null si no existe o es inválido
  static TrainingSetupV1? readSetup(Client client) {
    try {
      final setupMap = client.training.extra[TrainingExtraKeys.trainingSetupV1];
      if (setupMap == null) return null;

      if (setupMap is! Map) return null;

      return TrainingSetupV1.fromJson(setupMap.cast<String, dynamic>());
    } catch (e) {
      // Si falla parse, retornar null para que caller haga fallback a legacy
      return null;
    }
  }

  /// Lee TrainingEvaluationSnapshotV1 desde client.training.extra
  /// Retorna null si no existe o es inválido
  static TrainingEvaluationSnapshotV1? readEvaluation(Client client) {
    try {
      final evalMap =
          client.training.extra[TrainingExtraKeys.trainingEvaluationSnapshotV1];
      if (evalMap == null) return null;

      if (evalMap is! Map) return null;

      return TrainingEvaluationSnapshotV1.fromJson(
        evalMap.cast<String, dynamic>(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Escribe TrainingSetupV1 y espejea a legacy keys
  /// Retorna client actualizado (inmutable)
  static Client writeSetup(Client client, TrainingSetupV1 setup) {
    final extra = Map<String, dynamic>.from(client.training.extra);

    // 1. SSOT V1 (source of truth)
    extra[TrainingExtraKeys.trainingSetupV1] = setup.toJson();

    // 2. ESPEJEO LEGACY (backward compatibility)
    extra[TrainingExtraKeys.daysPerWeek] = setup.daysPerWeek;
    extra[TrainingExtraKeys.planDurationInWeeks] = setup.planDurationInWeeks;
    extra[TrainingExtraKeys.timePerSessionMinutes] =
        setup.timePerSessionMinutes;
    extra[TrainingExtraKeys.heightCm] = setup.heightCm;
    extra[TrainingExtraKeys.weightKg] = setup.weightKg;

    return client.copyWith(training: client.training.copyWith(extra: extra));
  }

  /// Escribe TrainingEvaluationSnapshotV1 y espejea a legacy keys
  /// GARANTIZA EXCLUSIVIDAD muscular (Primary ∩ Secondary = ∅, etc.)
  /// NORMALIZA keys musculares a canónicas
  static Client writeEvaluation(
    Client client,
    TrainingEvaluationSnapshotV1 snapshot,
  ) {
    final extra = Map<String, dynamic>.from(client.training.extra);

    // 1. NORMALIZACIÓN + EXCLUSIVIDAD
    final normalized = _enforceMusclePriorityExclusivity(
      primary: snapshot.primaryMuscles,
      secondary: snapshot.secondaryMuscles,
      tertiary: snapshot.tertiaryMuscles,
    );

    // 2. Crear snapshot actualizado con músculos normalizados
    final normalizedSnapshot = TrainingEvaluationSnapshotV1(
      schemaVersion: snapshot.schemaVersion,
      createdAt: snapshot.createdAt,
      updatedAt: DateTime.now(), // Actualizar timestamp
      daysPerWeek: snapshot.daysPerWeek,
      sessionDurationMinutes: snapshot.sessionDurationMinutes,
      planDurationInWeeks: snapshot.planDurationInWeeks,
      musclePriorities: snapshot.musclePriorities,
      primaryMuscles: normalized['primary']!,
      secondaryMuscles: normalized['secondary']!,
      tertiaryMuscles: normalized['tertiary']!,
      priorityVolumeSplit: snapshot.priorityVolumeSplit,
      intensityDistribution: snapshot.intensityDistribution,
      painRules: snapshot.painRules,
      status: snapshot.status,
      regenerationPolicy: snapshot.regenerationPolicy,
      weeksToCompetition: snapshot.weeksToCompetition,
      profileArchetype: snapshot.profileArchetype,
      rampUpRequired: snapshot.rampUpRequired,
      peakPhaseWindow: snapshot.peakPhaseWindow,
    );

    // 3. SSOT V1 (source of truth)
    extra[TrainingExtraKeys.trainingEvaluationSnapshotV1] = normalizedSnapshot
        .toJson();

    // 4. ESPEJEO LEGACY (CSV strings para backward compatibility)
    extra[TrainingExtraKeys.priorityMusclesPrimary] = normalized['primary']!
        .join(',');
    extra[TrainingExtraKeys.priorityMusclesSecondary] = normalized['secondary']!
        .join(',');
    extra[TrainingExtraKeys.priorityMusclesTertiary] = normalized['tertiary']!
        .join(',');

    // También espejar daysPerWeek, sessionDuration, planDuration
    extra[TrainingExtraKeys.daysPerWeek] = normalizedSnapshot.daysPerWeek;
    extra[TrainingExtraKeys.timePerSessionMinutes] =
        normalizedSnapshot.sessionDurationMinutes;
    extra[TrainingExtraKeys.planDurationInWeeks] =
        normalizedSnapshot.planDurationInWeeks;

    return client.copyWith(training: client.training.copyWith(extra: extra));
  }

  /// NORMALIZACIÓN + EXCLUSIVIDAD MUSCULAR
  /// Reglas:
  /// 1) Normalizar TODAS las keys con normalizeMuscleKey()
  /// 2) Primary gana sobre Secondary y Tertiary
  /// 3) Secondary gana sobre Tertiary
  /// 4) Retornar sets sin duplicados
  static Map<String, List<String>> _enforceMusclePriorityExclusivity({
    required List<String> primary,
    required List<String> secondary,
    required List<String> tertiary,
  }) {
    // Normalizar + convertir a sets
    final primaryNorm = primary
        .map(normalizeMuscleKey)
        .where((k) => k.isNotEmpty)
        .toSet();
    final secondaryNorm = secondary
        .map(normalizeMuscleKey)
        .where((k) => k.isNotEmpty)
        .toSet();
    final tertiaryNorm = tertiary
        .map(normalizeMuscleKey)
        .where((k) => k.isNotEmpty)
        .toSet();

    // Resolver exclusividad:
    // 1) Primary permanece intacto
    // 2) Secondary = secondary - primary
    // 3) Tertiary = tertiary - primary - secondary
    final finalPrimary = primaryNorm;
    final finalSecondary = secondaryNorm.difference(finalPrimary);
    final finalTertiary = tertiaryNorm
        .difference(finalPrimary)
        .difference(finalSecondary);

    return {
      'primary': finalPrimary.toList()..sort(),
      'secondary': finalSecondary.toList()..sort(),
      'tertiary': finalTertiary.toList()..sort(),
    };
  }

  /// Helper: Convierte CSV string a lista normalizada (para lectura legacy)
  static List<String> _parseCsvToNormalizedList(String? csv) {
    if (csv == null || csv.trim().isEmpty) return [];

    return csv
        .split(',')
        .map((e) => normalizeMuscleKey(e.trim()))
        .where((e) => e.isNotEmpty)
        .toSet() // Eliminar duplicados
        .toList()
      ..sort();
  }

  /// Helper: Lee músculos desde legacy keys (fallback)
  static Map<String, List<String>> readLegacyMusclePriorities(Client client) {
    final primary = _parseCsvToNormalizedList(
      client.training.extra[TrainingExtraKeys.priorityMusclesPrimary]
          ?.toString(),
    );
    final secondary = _parseCsvToNormalizedList(
      client.training.extra[TrainingExtraKeys.priorityMusclesSecondary]
          ?.toString(),
    );
    final tertiary = _parseCsvToNormalizedList(
      client.training.extra[TrainingExtraKeys.priorityMusclesTertiary]
          ?.toString(),
    );

    // Aplicar exclusividad incluso en legacy
    return _enforceMusclePriorityExclusivity(
      primary: primary,
      secondary: secondary,
      tertiary: tertiary,
    );
  }
}
