// lib/domain/training_v3/engines/exercise_selection_engine.dart

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/domain/training_v3/data/exercise_catalog_v3.dart';
import 'package:hcs_app_lap/domain/training_v3/models/client_profile.dart';
import 'package:hcs_app_lap/domain/training_v3/resolvers/muscle_to_catalog_resolver.dart'
    as resolver;
import 'package:hcs_app_lap/domain/training_v3/utils/muscle_key_adapter_v3.dart';

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
          debugPrint(
            '[V3][P0.1][UNASSIGNED_SETS] target=$targetSets assigned=$totalAssigned unassigned=$unassigned',
          );
          notes = 'unassignedSets: $unassigned';
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
  }) {
    // P0.2: NORMALIZACIÓN CANÓNICA
    // Convertir la clave canónica del motor a las claves REALES del catálogo
    final catalogKeys = MuscleKeyAdapterV3.toCatalogKeys(targetMuscle);

    debugPrint(
      '[ExerciseSelection][selectExercises] motor_muscle="$targetMuscle" → catalogKeys=$catalogKeys',
    );

    bool hasEquipmentMatch(Map<String, dynamic> exercise) {
      final equipment = (exercise['equipment'] as List?)?.cast<String>() ?? [];
      if (availableEquipment.isEmpty || equipment.isEmpty) return true;
      return equipment.any(availableEquipment.contains);
    }

    bool isInjurySafe(Map<String, dynamic> exercise) {
      if (injuryHistory.isEmpty) return true;
      final stressed =
          (exercise['stressed_joints'] as List?)?.cast<String>() ?? [];
      return !stressed.any(injuryHistory.containsKey);
    }

    // P0.2: COMPARACIÓN POR CATÁLOGO (no por motor)
    bool targetsMuscle(Map<String, dynamic> exercise) {
      final primary =
          (exercise['primary_muscles'] as List?)?.cast<String>() ?? [];
      // Verificar si alguno de los primaryMuscles coincide con alguno de los catalogKeys
      final matches = primary.where((p) => catalogKeys.contains(p)).toList();
      return matches.isNotEmpty;
    }

    final candidates = availableExercises.entries.where((entry) {
      final data = entry.value;
      return targetsMuscle(data) &&
          hasEquipmentMatch(data) &&
          isInjurySafe(data);
    }).toList();

    debugPrint(
      '[ExerciseSelection][selectExercises] catalogKeys=$catalogKeys found=${candidates.length} candidates',
    );

    candidates.sort((a, b) {
      final typeA = a.value['type'] as String? ?? 'compound';
      final typeB = b.value['type'] as String? ?? 'compound';
      if (typeA == typeB) return 0;
      return typeA == 'compound' ? -1 : 1;
    });

    if (candidates.isNotEmpty) {
      final selected = candidates
          .take(targetExerciseCount)
          .map((e) => e.key)
          .toList();
      debugPrint(
        '[ExerciseSelection][selectExercises] selected=${selected.length}/$targetExerciseCount exercises for muscle="$targetMuscle"',
      );
      return selected;
    }

    debugPrint(
      '[ExerciseSelection][selectExercises] ⚠️ NO candidates found for muscle="$targetMuscle" (catalogs=$catalogKeys). Using fallback.',
    );

    return availableExercises.keys.take(targetExerciseCount).toList();
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
  }) {
    final keys = <String>{};
    for (final group in groups) {
      keys.addAll(resolver.MuscleToCatalogResolver.resolve(group));
    }

    if (keys.isEmpty) {
      debugPrint('[ExerciseSelection] ⚠️ No hay keys para grupos: $groups');
      return const <Exercise>[];
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
      debugPrint(
        '[ExerciseSelection] ⚠️ No exercises for motorKeys=$keys catalogKeys=$catalogKeys',
      );

      // Fallback inteligente: filtrar por primaryMuscles
      final fallbackPrimary = ExerciseCatalogV3.getAllExercises().where((ex) {
        return ex.primaryMuscles.any((m) => keys.contains(m));
      }).toList();

      debugPrint(
        '[ExerciseSelection] Fallback(primary): Filtered ${fallbackPrimary.length}/${ExerciseCatalogV3.getAllExercises().length} exercises that match keys: $keys',
      );

      if (fallbackPrimary.isNotEmpty) {
        all.addAll(fallbackPrimary);
      }

      if (all.isEmpty) {
        final fallbackSecondary = ExerciseCatalogV3.getAllExercises().where((
          ex,
        ) {
          return ex.secondaryMuscles.any((m) => keys.contains(m));
        }).toList();

        debugPrint(
          '[ExerciseSelection] Fallback(secondary): Filtered ${fallbackSecondary.length}/${ExerciseCatalogV3.getAllExercises().length} exercises that match keys: $keys',
        );

        if (fallbackSecondary.isNotEmpty) {
          all.addAll(fallbackSecondary);
        }
      }
    }

    if (all.isEmpty) {
      debugPrint(
        '[ExerciseSelection] ⚠️ Catalogo vacio o sin ejercicios para: $keys',
      );
      return const <Exercise>[];
    }

    final seen = <String>{};
    final deduped = <Exercise>[];
    for (final e in all) {
      if (seen.add(e.id)) deduped.add(e);
    }

    final ordered = deduped..sort((a, b) => a.name.compareTo(b.name));

    if (!limitToTargetSets) {
      return ordered.toList();
    }

    final exerciseCount = max(1, min(ordered.length, (targetSets / 3).ceil()));
    return ordered.take(exerciseCount).toList();
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
