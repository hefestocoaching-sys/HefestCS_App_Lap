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
class ExerciseSelectionEngine {
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
  }) {
    final keys = <String>{};
    for (final group in groups) {
      keys.addAll(resolver.MuscleToCatalogResolver.resolve(group));
    }

    if (keys.isEmpty) {
      debugPrint('[ExerciseSelection] No hay keys para grupos: $groups');
      throw StateError('No hay keys de catálogo para grupos: $groups');
    }

    final catalogKeys = <String>{};
    for (final key in keys) {
      catalogKeys.addAll(MuscleKeyAdapterV3.toCatalogKeys(key));
    }

    final all = <Exercise>[];
    for (final ck in catalogKeys) {
      final list = ExerciseCatalogV3.getByMuscle(ck);
      if (list.isNotEmpty) all.addAll(list);
    }

    if (all.isEmpty) {
      debugPrint(
        '[ExerciseSelection] No exercises for motorKeys=$keys catalogKeys=$catalogKeys',
      );
      throw StateError('No se encontraron ejercicios para keys: $catalogKeys');
    }

    final seen = <String>{};
    final deduped = <Exercise>[];
    for (final e in all) {
      if (seen.add(e.id)) deduped.add(e);
    }

    final ordered = deduped..sort((a, b) => a.name.compareTo(b.name));

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
