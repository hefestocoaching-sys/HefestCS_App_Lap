// lib/domain/training_v3/engines/exercise_selection_engine.dart

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/domain/training_v3/data/exercise_catalog_v3.dart';
import 'package:hcs_app_lap/domain/training_v3/models/client_profile.dart';
import 'package:hcs_app_lap/domain/training_v3/resolvers/muscle_to_catalog_resolver.dart'
    as resolver;
import 'package:hcs_app_lap/domain/training_v3/utils/muscle_key_adapter_v3.dart';
import 'package:hcs_app_lap/core/registry/muscle_registry.dart'
    as muscle_registry;

/// Motor de selección inteligente de ejercicios
///
/// Implementa las reglas científicas de la Semana 5 (26 imágenes):
/// - 6 criterios de scoring: ROM, ángulo, estabilidad, curva de resistencia, fatiga, lesión
/// - Priorizar compounds sobre isolation
/// - Considerar equipamiento disponible
/// - Evitar ejercicios contraindicados por lesiones
///
/// FUNDAMENTO CIENTÍFICO:
/// - Semana 5, Imagen 44-49: Criterios de selección
/// - Semana 5, Imagen 50-55: Scoring de ejercicios
/// - Semana 5, Imagen 56-59: Priorización compound/isolation
///
/// REFERENCIAS:
/// - Schoenfeld (2010): Exercise selection for muscle hypertrophy
/// - Contreras et al. (2020): Exercise variation and muscle activation
///
/// Versión: 2.0.0 - Con normalización de músculos compuestos
class SelectedExerciseResult {
  final Exercise exercise;
  final int sets;
  final String notes;

  SelectedExerciseResult({
    required this.exercise,
    required this.sets,
    this.notes = '',
  });
}

class ExerciseSelectionEngine {
  // P0.1 SSOT CONSTANTS
  static const int _maxSetsPerExercise = 5;
  static const int _maxExercisesPerMusclePerSession = 2;

  static String normalizeMuscleKey(String raw) {
    final key = raw.trim().toLowerCase();
    if (key.isEmpty) return key;
    return muscle_registry.normalize(key) ?? key;
  }

  /// P0.1 Selection Rule: selects exercises and distributes sets respecting hard caps
  static List<SelectedExerciseResult> selectExercisesForMuscle({
    required List<Exercise> pool,
    required int targetSets,
  }) {
    if (pool.isEmpty || targetSets <= 0) return [];

    final exerciseCount = (targetSets / _maxSetsPerExercise)
        .ceil()
        .clamp(1, _maxExercisesPerMusclePerSession)
        .toInt();

    final selected = pool.take(exerciseCount).toList();

    int baseSets = targetSets ~/ selected.length;
    int extraSets = targetSets % selected.length;

    int totalAssigned = 0;
    final results = <SelectedExerciseResult>[];

    for (int i = 0; i < selected.length; i++) {
      int assigned = baseSets + (extraSets > 0 ? 1 : 0);
      if (extraSets > 0) extraSets--;

      if (assigned > _maxSetsPerExercise) {
        assigned = _maxSetsPerExercise;
      }

      totalAssigned += assigned;

      String notes = '';
      if (i == selected.length - 1) {
        int unassigned = targetSets - totalAssigned;
        if (unassigned > 0) {
          throw StateError(
            '[V3][P0.1][UNASSIGNED_SETS] CRITICAL: target=$targetSets assigned=$totalAssigned unassigned=$unassigned. '
            'Volume cap exceeded: max 5 sets/exercise × 2 exercises = 10 sets/session. '
            'Request: ${pool.length} exercises but only 2 available slots.',
          );
        }
      }

      results.add(
        SelectedExerciseResult(
          exercise: selected[i],
          sets: assigned,
          notes: notes,
        ),
      );
    }

    return results;
  }

  static List<String> selectExercises({
    required String targetMuscle,
    required Map<String, Map<String, dynamic>> availableExercises,
    required List<String> availableEquipment,
    required Map<String, String> injuryHistory,
    required int targetExerciseCount,
    String? intensityZone,
    String? preferredMovementPattern,
    Set<String> recentExerciseIds = const <String>{},
    Set<String> restrictedExerciseIds = const <String>{},
  }) {
    // P0.2: NORMALIZACIÓN CANÓNICA
    // Convertir la clave canónica del motor a las claves REALES del catálogo
    final catalogKeys = MuscleKeyAdapterV3.toCatalogKeys(targetMuscle);

    debugPrint(
      '[ExerciseSelection][selectExercises] motor_muscle="$targetMuscle" → catalogKeys=$catalogKeys',
    );

    List<String> normalizeEquipment(dynamic raw) {
      if (raw is List) {
        return raw
            .map((e) => e?.toString().trim().toLowerCase() ?? '')
            .where((e) => e.isNotEmpty)
            .toList();
      }
      final single = raw?.toString().trim().toLowerCase() ?? '';
      return single.isEmpty ? const <String>[] : <String>[single];
    }

    bool hasEquipmentMatch(Map<String, dynamic> exercise) {
      final equipment = normalizeEquipment(exercise['equipment']);
      if (availableEquipment.isEmpty || equipment.isEmpty) return true;
      final available = availableEquipment
          .map((e) => e.trim().toLowerCase())
          .toSet();
      return equipment.any(available.contains);
    }

    bool isInjurySafe(Map<String, dynamic> exercise) {
      if (injuryHistory.isEmpty) return true;
      final stressed =
          (exercise['stressed_joints'] as List?)?.cast<String>() ?? [];
      return !stressed.any(injuryHistory.containsKey);
    }

    bool targetsMuscle(Map<String, dynamic> exercise) {
      final primary =
          (exercise['primaryMuscles'] as List?)?.cast<String>() ??
          (exercise['primary_muscles'] as List?)?.cast<String>() ??
          const <String>[];
      return primary.any((p) => catalogKeys.contains(p));
    }

    bool intensityCompatible(String id) {
      final zone = intensityZone;
      if (zone == null || zone.trim().isEmpty) return true;
      return ExerciseCatalogV3.allowsZone(id, zone);
    }

    final candidates = availableExercises.entries.where((entry) {
      final id = entry.key;
      final data = entry.value;
      if (restrictedExerciseIds.contains(id)) return false;
      return targetsMuscle(data) &&
          hasEquipmentMatch(data) &&
          isInjurySafe(data) &&
          intensityCompatible(id);
    }).toList();

    debugPrint(
      '[ExerciseSelection][selectExercises] catalogKeys=$catalogKeys found=${candidates.length} candidates',
    );

    int readInt(Map<String, dynamic> data, String key, int fallback) {
      final raw = data[key];
      if (raw is int) return raw;
      if (raw is num) return raw.round();
      return int.tryParse(raw?.toString() ?? '') ?? fallback;
    }

    String readPattern(Map<String, dynamic> data, String fallbackId) {
      final fromData = data['movementPattern']?.toString().trim().toLowerCase();
      if (fromData != null && fromData.isNotEmpty) return fromData;
      return ExerciseCatalogV3.getMovementPattern(fallbackId);
    }

    final preferredPattern = preferredMovementPattern?.trim().toLowerCase();

    candidates.sort((a, b) {
      final stimulusA = readInt(
        a.value,
        'stimulusScore',
        ExerciseCatalogV3.getStimulusScore(a.key),
      );
      final stimulusB = readInt(
        b.value,
        'stimulusScore',
        ExerciseCatalogV3.getStimulusScore(b.key),
      );
      final byStimulus = stimulusB.compareTo(stimulusA);
      if (byStimulus != 0) return byStimulus;

      final fatigueA = readInt(
        a.value,
        'fatigueScore',
        ExerciseCatalogV3.getFatigueScore(a.key),
      );
      final fatigueB = readInt(
        b.value,
        'fatigueScore',
        ExerciseCatalogV3.getFatigueScore(b.key),
      );
      final byFatigue = fatigueA.compareTo(fatigueB);
      if (byFatigue != 0) return byFatigue;

      if (preferredPattern != null && preferredPattern.isNotEmpty) {
        final matchA = readPattern(a.value, a.key) == preferredPattern;
        final matchB = readPattern(b.value, b.key) == preferredPattern;
        if (matchA != matchB) return matchA ? -1 : 1;
      }

      final recentA = recentExerciseIds.contains(a.key);
      final recentB = recentExerciseIds.contains(b.key);
      if (recentA != recentB) return recentA ? 1 : -1;

      return a.key.compareTo(b.key);
    });

    if (candidates.isNotEmpty) {
      final count = min(targetExerciseCount, candidates.length);
      final selected = candidates.sublist(0, count).map((e) => e.key).toList();
      debugPrint(
        '[ExerciseSelection][selectExercises] selected=${selected.length}/$targetExerciseCount exercises for muscle="$targetMuscle"',
      );
      return selected;
    }

    throw StateError(
      '[ExerciseSelection][STRICT_NO_FALLBACK] No candidates for muscle="$targetMuscle" '
      'catalogKeys=$catalogKeys intensityZone=${intensityZone ?? 'any'} '
      'equipment=${availableEquipment.join(',')} injuries=${injuryHistory.keys.join(',')}',
    );
  }

  /// Selecciona ejercicios reales del catálogo por grupos musculares
  ///
  /// CONTRATO:
  /// - Resuelve grupos lógicos a keys reales del JSON
  /// - Retorna ejercicios reales del catálogo
  /// - Si no hay ejercicios, lanza StateError
  static List<Exercise> selectExercisesByGroups({
    required List<resolver.MuscleGroup> groups,
    required int targetSets,
    required ClientProfile profile,
    bool limitToTargetSets = true,
    String? intensityZone,
    List<String> availableEquipment = const <String>[],
    Set<String> restrictedExerciseIds = const <String>{},
    Set<String> recentExerciseIds = const <String>{},
    String? preferredMovementPattern,
  }) {
    final keys = <String>{};
    for (final group in groups) {
      keys.addAll(resolver.MuscleToCatalogResolver.resolve(group));
    }

    if (keys.isEmpty) {
      throw StateError(
        '[ExerciseSelection][STRICT] No hay keys para grupos: $groups',
      );
    }

    debugPrint(
      '[ExerciseSelection] 🔍 Buscando ejercicios para groups=$groups → motorKeys=$keys',
    );

    final catalogKeys = <String>{};
    for (final key in keys) {
      catalogKeys.addAll(MuscleKeyAdapterV3.toCatalogKeys(key));
    }

    debugPrint(
      '[ExerciseSelection] 🔍 Después adapter: catalogKeys=$catalogKeys',
    );

    final all = <Exercise>[];
    for (final ck in catalogKeys) {
      final list = ExerciseCatalogV3.getByMuscle(ck);
      debugPrint('[ExerciseSelection]   ck="$ck": ${list.length} exercises');
      if (list.isNotEmpty) all.addAll(list);
    }

    if (all.isEmpty) {
      throw StateError(
        '[ExerciseSelection][STRICT_NO_FALLBACK] No exercises for groups=$groups '
        'motorKeys=$keys catalogKeys=$catalogKeys',
      );
    }

    final seen = <String>{};
    final deduped = <Exercise>[];
    for (final e in all) {
      if (seen.add(e.id)) deduped.add(e);
    }

    bool hasEquipment(Exercise ex) {
      if (availableEquipment.isEmpty) return true;
      final exEquipment = ex.equipment.trim().toLowerCase();
      if (exEquipment.isEmpty) return true;
      final available = availableEquipment
          .map((e) => e.trim().toLowerCase())
          .toSet();
      return available.contains(exEquipment);
    }

    bool zoneOk(Exercise ex) {
      final zone = intensityZone;
      if (zone == null || zone.trim().isEmpty) return true;
      return ExerciseCatalogV3.allowsZone(ex.id, zone);
    }

    final preferredPattern = preferredMovementPattern?.trim().toLowerCase();
    final filtered = deduped.where((ex) {
      if (restrictedExerciseIds.contains(ex.id)) return false;
      if (!hasEquipment(ex)) return false;
      if (!zoneOk(ex)) return false;
      return true;
    }).toList();

    filtered.sort((a, b) {
      final byStimulus = ExerciseCatalogV3.getStimulusScore(
        b.id,
      ).compareTo(ExerciseCatalogV3.getStimulusScore(a.id));
      if (byStimulus != 0) return byStimulus;

      final byFatigue = ExerciseCatalogV3.getFatigueScore(
        a.id,
      ).compareTo(ExerciseCatalogV3.getFatigueScore(b.id));
      if (byFatigue != 0) return byFatigue;

      if (preferredPattern != null && preferredPattern.isNotEmpty) {
        final aMatch =
            ExerciseCatalogV3.getMovementPattern(a.id) == preferredPattern;
        final bMatch =
            ExerciseCatalogV3.getMovementPattern(b.id) == preferredPattern;
        if (aMatch != bMatch) return aMatch ? -1 : 1;
      }

      final aRecent = recentExerciseIds.contains(a.id);
      final bRecent = recentExerciseIds.contains(b.id);
      if (aRecent != bRecent) return aRecent ? 1 : -1;

      return a.id.compareTo(b.id);
    });

    if (filtered.isEmpty) {
      throw StateError(
        '[ExerciseSelection][STRICT_NO_FALLBACK] No filtered exercises remain for '
        'groups=$groups zone=${intensityZone ?? 'any'} equipment=$availableEquipment',
      );
    }

    final ordered = filtered;

    if (!limitToTargetSets) {
      return ordered.toList();
    }

    final exerciseCount = max(1, min(ordered.length, (targetSets / 3).ceil()));
    return ordered.sublist(0, exerciseCount);
  }

  static List<Exercise> selectDeterministicCandidates({
    required List<Exercise> pool,
    required String muscleKey,
    required String intensityZone,
    String? requiredSlotRole,
    Set<String> allowedMovementPatterns = const <String>{},
    List<String> availableEquipment = const <String>[],
    Set<String> restrictedExerciseIds = const <String>{},
    Set<String> recentExerciseIds = const <String>{},
    String? preferredMovementPattern,
  }) {
    final normalizedZone = intensityZone.trim().toLowerCase();
    if (normalizedZone.isEmpty) {
      throw StateError(
        '[ExerciseSelection][STRICT_ZONE_REQUIRED] intensityZone is required for deterministic selection',
      );
    }

    final normalizedMuscle = normalizeMuscleKey(muscleKey);
    final preferredPattern = preferredMovementPattern?.trim().toLowerCase();
    final normalizedSlot = requiredSlotRole?.trim().toUpperCase();
    final normalizedAllowedPatterns = allowedMovementPatterns
        .map((pattern) => pattern.trim().toLowerCase())
        .where((pattern) => pattern.isNotEmpty)
        .toSet();
    final available = availableEquipment
        .map((e) => e.trim().toLowerCase())
        .toSet();

    int compatibilityScore(Exercise ex) {
      var score = 0;
      if (normalizedSlot != null &&
          normalizedSlot.isNotEmpty &&
          ExerciseCatalogV3.supportsSlot(ex.id, normalizedSlot)) {
        score += 100;
      }

      final pattern = ExerciseCatalogV3.getMovementPattern(ex.id);
      if (normalizedAllowedPatterns.isNotEmpty &&
          normalizedAllowedPatterns.contains(pattern)) {
        score += 80;
      }

      if (ExerciseCatalogV3.allowsZone(ex.id, normalizedZone)) {
        score += 60;
      }

      return score;
    }

    final filtered = pool.where((ex) {
      if (restrictedExerciseIds.contains(ex.id)) return false;
      if (!ex.primaryMuscles.any(
        (m) => normalizeMuscleKey(m) == normalizedMuscle,
      )) {
        return false;
      }
      if (!ExerciseCatalogV3.allowsZone(ex.id, normalizedZone)) return false;
      if (!ex.allowsZone(normalizedZone)) return false;
      if (normalizedSlot != null &&
          normalizedSlot.isNotEmpty &&
          !ExerciseCatalogV3.supportsSlot(ex.id, normalizedSlot)) {
        return false;
      }
      final movementPattern = ExerciseCatalogV3.getMovementPattern(ex.id);
      if (normalizedAllowedPatterns.isNotEmpty &&
          !normalizedAllowedPatterns.contains(movementPattern)) {
        return false;
      }
      final exEquipment = ex.equipment.trim().toLowerCase();
      if (available.isNotEmpty &&
          exEquipment.isNotEmpty &&
          !available.contains(exEquipment)) {
        return false;
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      final byCompatibility = compatibilityScore(
        b,
      ).compareTo(compatibilityScore(a));
      if (byCompatibility != 0) return byCompatibility;

      final byOrderClass = ExerciseCatalogV3.getExerciseOrderClass(
        a.id,
      ).compareTo(ExerciseCatalogV3.getExerciseOrderClass(b.id));
      if (byOrderClass != 0) return byOrderClass;

      final byStimulus = ExerciseCatalogV3.getStimulusScore(
        b.id,
      ).compareTo(ExerciseCatalogV3.getStimulusScore(a.id));
      if (byStimulus != 0) return byStimulus;

      final byFatigue = ExerciseCatalogV3.getFatigueScore(
        a.id,
      ).compareTo(ExerciseCatalogV3.getFatigueScore(b.id));
      if (byFatigue != 0) return byFatigue;

      if (preferredPattern != null && preferredPattern.isNotEmpty) {
        final aMatch =
            ExerciseCatalogV3.getMovementPattern(a.id) == preferredPattern;
        final bMatch =
            ExerciseCatalogV3.getMovementPattern(b.id) == preferredPattern;
        if (aMatch != bMatch) return aMatch ? -1 : 1;
      }

      final aRecent = recentExerciseIds.contains(a.id);
      final bRecent = recentExerciseIds.contains(b.id);
      if (aRecent != bRecent) return aRecent ? 1 : -1;

      final byVariantTier = ExerciseCatalogV3.getVariantTier(
        a.id,
      ).compareTo(ExerciseCatalogV3.getVariantTier(b.id));
      if (byVariantTier != 0) return byVariantTier;

      return a.id.compareTo(b.id);
    });

    if (filtered.isNotEmpty) {
      return filtered;
    }

    // Fallback controlado: explorar equivalentes únicamente dentro de
    // equivalenceGroup y compatibles con zona objetivo.
    final fallback = <Exercise>[];
    final seen = <String>{};
    for (final source in pool) {
      final sourceMuscleMatches = source.primaryMuscles.any(
        (m) => normalizeMuscleKey(m) == normalizedMuscle,
      );
      if (!sourceMuscleMatches) continue;

      final candidates = ExerciseCatalogV3.findEquivalentExercisesForZone(
        source: source,
        zone: normalizedZone,
        muscleKey: normalizedMuscle,
        excludeIds: {...restrictedExerciseIds, ...recentExerciseIds},
      );
      for (final candidate in candidates) {
        if (restrictedExerciseIds.contains(candidate.id)) continue;
        if (!candidate.primaryMuscles.any(
          (m) => normalizeMuscleKey(m) == normalizedMuscle,
        )) {
          continue;
        }
        if (!ExerciseCatalogV3.allowsZone(candidate.id, normalizedZone)) {
          continue;
        }
        if (!candidate.allowsZone(normalizedZone)) continue;
        if (normalizedSlot != null &&
            normalizedSlot.isNotEmpty &&
            !ExerciseCatalogV3.supportsSlot(candidate.id, normalizedSlot)) {
          continue;
        }
        final movementPattern = ExerciseCatalogV3.getMovementPattern(
          candidate.id,
        );
        if (normalizedAllowedPatterns.isNotEmpty &&
            !normalizedAllowedPatterns.contains(movementPattern)) {
          continue;
        }
        final exEquipment = candidate.equipment.trim().toLowerCase();
        if (available.isNotEmpty &&
            exEquipment.isNotEmpty &&
            !available.contains(exEquipment)) {
          continue;
        }
        if (seen.add(candidate.id)) {
          fallback.add(candidate);
        }
      }
    }

    fallback.sort((a, b) {
      final byCompatibility = compatibilityScore(
        b,
      ).compareTo(compatibilityScore(a));
      if (byCompatibility != 0) return byCompatibility;

      final byOrderClass = ExerciseCatalogV3.getExerciseOrderClass(
        a.id,
      ).compareTo(ExerciseCatalogV3.getExerciseOrderClass(b.id));
      if (byOrderClass != 0) return byOrderClass;

      final byStimulus = ExerciseCatalogV3.getStimulusScore(
        b.id,
      ).compareTo(ExerciseCatalogV3.getStimulusScore(a.id));
      if (byStimulus != 0) return byStimulus;

      final byFatigue = ExerciseCatalogV3.getFatigueScore(
        a.id,
      ).compareTo(ExerciseCatalogV3.getFatigueScore(b.id));
      if (byFatigue != 0) return byFatigue;

      if (preferredPattern != null && preferredPattern.isNotEmpty) {
        final aMatch =
            ExerciseCatalogV3.getMovementPattern(a.id) == preferredPattern;
        final bMatch =
            ExerciseCatalogV3.getMovementPattern(b.id) == preferredPattern;
        if (aMatch != bMatch) return aMatch ? -1 : 1;
      }

      final byVariantTier = ExerciseCatalogV3.getVariantTier(
        a.id,
      ).compareTo(ExerciseCatalogV3.getVariantTier(b.id));
      if (byVariantTier != 0) return byVariantTier;

      return a.id.compareTo(b.id);
    });

    if (fallback.isNotEmpty) {
      return fallback;
    }

    throw StateError(
      '[ExerciseSelection][STRICT_NO_ZONE_CANDIDATES] '
      'muscle=$normalizedMuscle zone=$normalizedZone pool=${pool.length} '
      'restricted=${restrictedExerciseIds.length} recent=${recentExerciseIds.length}',
    );
  }

  /// Metodo refactorizado pero no integrado en flujo actual
  ///
  /// Verifica si tiene el equipamiento necesario
  /*
  static bool _hasRequiredEquipment(
    Map<String, dynamic> exercise,
    List<String> available,
  ) {
    final required = _normalizeEquipment(exercise['equipment']);
    if (required.isEmpty) return true;
    return required.every((eq) => available.contains(eq));
  }

  static List<String> _normalizeEquipment(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (value is String) {
      final normalized = value.trim();
      return normalized.isEmpty ? const <String>[] : <String>[normalized];
    }
    return const <String>[];
  }
  */

  /// Metodo refactorizado pero no integrado en flujo actual
  ///
  /// Verifica si el ejercicio esta contraindicado por lesion
  ///
  /// EJEMPLO:
  /// - Lesión de hombro → evitar overhead press
  /// - Lesión de rodilla → evitar squats profundos
  /*
  static bool _isContraindicatedByInjury(
    Map<String, dynamic> exercise,
    Map<String, String> injuries,
  ) {
    if (injuries.isEmpty) return false;

    final stressedJoints =
        (exercise['stressed_joints'] as List?)?.cast<String>() ?? [];

    // Si el ejercicio estresa una articulación lesionada, contraindicar
    for (final joint in stressedJoints) {
      if (injuries.containsKey(joint)) {
        return true;
      }
    }

    return false;
  }
  */

  /// Obtiene variaciones de un ejercicio
  ///
  /// USADO PARA: Exercise swap cuando hay fatiga o estancamiento
  static List<String> getExerciseVariations(
    String exerciseId,
    Map<String, Map<String, dynamic>> exerciseDatabase,
  ) {
    final baseExercise = exerciseDatabase[exerciseId];
    if (baseExercise == null) return [];

    final baseMuscles =
        (baseExercise['primary_muscles'] as List?)?.cast<String>() ?? [];
    final baseType = baseExercise['type'] as String?;

    // Buscar ejercicios similares (mismo músculo + tipo)
    return exerciseDatabase.entries
        .where((e) => e.key != exerciseId)
        .where((e) => _hasSameMuscles(e.value, baseMuscles))
        .where((e) => e.value['type'] == baseType)
        .map((e) => e.key)
        .take(3)
        .toList();
  }

  static bool _hasSameMuscles(
    Map<String, dynamic> exercise,
    List<String> targetMuscles,
  ) {
    final muscles =
        (exercise['primary_muscles'] as List?)?.cast<String>() ?? [];
    return muscles.any((m) => targetMuscles.contains(m));
  }
}
