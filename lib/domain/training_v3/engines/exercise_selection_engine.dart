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

  /// Calcula score científico del ejercicio (0.0-10.0)
  ///
  /// FUENTE: Semana 5, Imagen 50-55
  ///
  /// CRITERIOS (peso total = 100%):
  /// 1. ROM (25%): Mayor ROM = mejor hipertrofia
  /// 2. Ángulo (20%): Ángulo óptimo de tracción
  /// 3. Estabilidad (15%): Menos estabilización = más foco
  /// 4. Curva de resistencia (15%): Tensión constante
  /// 5. Fatiga (15%): Menor fatiga sistémica = más sets
  /// 6. Riesgo de lesión (10%): Seguridad
  static double _calculateExerciseScore(
    Map<String, dynamic> exercise,
    String targetMuscle,
  ) {
    double score = 0.0;

    // Criterio 1: ROM (0-10, peso 25%)
    final rom = (exercise['rom'] as num?)?.toDouble() ?? 5.0;
    score += rom * 0.25;

    // Criterio 2: Ángulo (0-10, peso 20%)
    final angle = (exercise['angle_quality'] as num?)?.toDouble() ?? 5.0;
    score += angle * 0.20;

    // Criterio 3: Estabilidad (0-10, peso 15%)
    final stability =
        (exercise['stability_requirement'] as num?)?.toDouble() ?? 5.0;
    // Invertir: menor estabilidad = mejor (más foco en músculo)
    score += (10 - stability) * 0.15;

    // Criterio 4: Curva de resistencia (0-10, peso 15%)
    final resistance =
        (exercise['resistance_curve'] as num?)?.toDouble() ?? 5.0;
    score += resistance * 0.15;

    // Criterio 5: Fatiga (0-10, peso 15%)
    final fatigue = (exercise['systemic_fatigue'] as num?)?.toDouble() ?? 5.0;
    // Invertir: menor fatiga = mejor
    score += (10 - fatigue) * 0.15;

    // Criterio 6: Riesgo lesión (0-10, peso 10%)
    final injury = (exercise['injury_risk'] as num?)?.toDouble() ?? 5.0;
    // Invertir: menor riesgo = mejor
    score += (10 - injury) * 0.10;

    return score;
  }

  /// Balancea compounds vs isolation (2:1 ratio)
  ///
  /// FUENTE: Semana 5, Imagen 56-59
  ///
  /// REGLA: 2/3 compounds, 1/3 isolation
  static List<Map<String, dynamic>> _balanceCompoundsAndIsolation(
    List<Map<String, dynamic>> scoredExercises,
    int targetCount,
  ) {
    final compounds = scoredExercises
        .where((e) => (e['data'] as Map)['type'] == 'compound')
        .toList();
    final isolation = scoredExercises
        .where((e) => (e['data'] as Map)['type'] == 'isolation')
        .toList();

    // Calcular proporción
    final compoundCount = ((targetCount * 2) / 3).round();
    final isolationCount = targetCount - compoundCount;

    // Seleccionar mejores
    final selectedCompounds = compounds.take(compoundCount).toList();
    final selectedIsolation = isolation.take(isolationCount).toList();

    return [...selectedCompounds, ...selectedIsolation];
  }

  /// Verifica si el ejercicio entrena el músculo objetivo
  ///
  /// Soporta nombres compuestos:
  /// - 'deltoide anterior'/'deltoide frontal' → 'deltoide_anterior'
  /// - 'deltoide lateral' → 'deltoide_lateral'
  /// - 'deltoide posterior' → 'deltoide_posterior'
  /// - 'pectoral superior' → 'chest' (mapea a grupo padre)
  /// - 'trapecio superior'/'medio'/'inferior' → 'traps'
  static bool _isExerciseForMuscle(
    Map<String, dynamic> exercise,
    String muscle,
  ) {
    final primaryMuscles =
        (exercise['primary_muscles'] as List?)?.cast<String>() ?? [];
    final secondaryMuscles =
        (exercise['secondary_muscles'] as List?)?.cast<String>() ?? [];

    // Normalizar músculo objetivo
    final normalizedTarget = _normalizeMuscleNameForExercise(muscle);

    // Buscar coincidencias (directo o normalizado)
    for (final pm in primaryMuscles) {
      if (_muscleMatches(pm, normalizedTarget, muscle)) return true;
    }

    for (final sm in secondaryMuscles) {
      if (_muscleMatches(sm, normalizedTarget, muscle)) return true;
    }

    return false;
  }

  /// Verifica si un músculo del ejercicio coincide con el target
  static bool _muscleMatches(
    String exerciseMuscle,
    String normalizedTarget,
    String originalTarget,
  ) {
    // Comparación directa
    if (exerciseMuscle == normalizedTarget ||
        exerciseMuscle == originalTarget) {
      return true;
    }

    // Normalizar el músculo del ejercicio también
    final normalizedExercise = _normalizeMuscleNameForExercise(exerciseMuscle);
    if (normalizedExercise == normalizedTarget) {
      return true;
    }

    // Coincidencia parcial para grupos musculares compuestos
    // Ej: ejercicio='deltoide_anterior', target='deltoids' → true
    if (exerciseMuscle.contains(normalizedTarget) ||
        normalizedTarget.contains(exerciseMuscle)) {
      return true;
    }

    return false;
  }

  /// Normaliza nombres de músculos a formato canónico
  ///
  /// MAPEO COMPLETO:
  /// - 'deltoide frontal', 'deltoide anterior' → 'deltoide_anterior'
  /// - 'deltoide lateral', 'deltoide medio' → 'deltoide_lateral'
  /// - 'deltoide posterior', 'deltoide trasero' → 'deltoide_posterior'
  /// - 'pectoral superior', 'pecho superior' → 'chest' (padre)
  /// - 'trapecio superior', 'trapecio medio', 'trapecio inferior' → 'traps' (padre)
  /// - Nombres en español → inglés canónico
  static String _normalizeMuscleNameForExercise(String muscle) {
    final normalized = muscle.toLowerCase().trim();

    // === DELTOIDE COMPUESTO (3 porciones) ===
    if (normalized.contains('deltoide')) {
      if (normalized.contains('anterior') ||
          normalized.contains('frontal') ||
          normalized.contains('front')) {
        return 'deltoide_anterior';
      }
      if (normalized.contains('lateral') ||
          normalized.contains('medio') ||
          normalized.contains('lateral')) {
        return 'deltoide_lateral';
      }
      if (normalized.contains('posterior') ||
          normalized.contains('trasero') ||
          normalized.contains('rear')) {
        return 'deltoide_posterior';
      }
      // Genérico 'deltoide' → 'deltoids' (padre)
      return 'deltoids';
    }

    if (normalized.contains('shoulder') || normalized.contains('hombro')) {
      if (normalized.contains('front') ||
          normalized.contains('anterior') ||
          normalized.contains('frontal')) {
        return 'deltoide_anterior';
      }
      if (normalized.contains('lateral') ||
          normalized.contains('side') ||
          normalized.contains('medio')) {
        return 'deltoide_lateral';
      }
      if (normalized.contains('rear') ||
          normalized.contains('posterior') ||
          normalized.contains('trasero')) {
        return 'deltoide_posterior';
      }
      return 'deltoids';
    }

    // === PECTORAL COMPUESTO ===
    if (normalized.contains('pectoral') ||
        normalized.contains('pecho') ||
        normalized.contains('chest')) {
      if (normalized.contains('superior') ||
          normalized.contains('upper') ||
          normalized.contains('clavicular')) {
        return 'chest'; // Mapear a grupo padre por ahora
      }
      return 'chest';
    }

    // === TRAPECIO COMPUESTO ===
    if (normalized.contains('trapecio') || normalized.contains('trap')) {
      // Todas las porciones → 'traps' (padre)
      return 'traps';
    }

    // === ESPALDA ===
    if (normalized.contains('dorsal') || normalized.contains('lat')) {
      return 'lats';
    }

    if (normalized.contains('espalda alta') ||
        normalized.contains('upper back')) {
      return 'upper_back';
    }

    // === PIERNAS ===
    if (normalized.contains('cuadriceps') || normalized.contains('quad')) {
      return 'quads';
    }

    if (normalized.contains('femoral') || normalized.contains('hamstring')) {
      return 'hamstrings';
    }

    if (normalized.contains('gluteo') || normalized.contains('glute')) {
      return 'glutes';
    }

    if (normalized.contains('pantorrilla') ||
        normalized.contains('calf') ||
        normalized.contains('calve')) {
      return 'calves';
    }

    // === BRAZOS ===
    if (normalized.contains('bicep') || normalized.contains('bícep')) {
      return 'biceps';
    }

    if (normalized.contains('tricep') || normalized.contains('trícep')) {
      return 'triceps';
    }

    // === CORE ===
    if (normalized.contains('abdomen') ||
        normalized.contains('abs') ||
        normalized.contains('core')) {
      return 'abs';
    }

    // Si no se reconoce, registrar warning y mapear a grupo genérico si es posible
    if (!_isCanonicalMuscle(normalized)) {
      debugPrint(
        '⚠️ [ExerciseSelection] Músculo no reconocido: "$muscle" → usando nombre original',
      );
    }

    return normalized;
  }

  /// Verifica si el músculo está en la lista de 14 canónicos
  static bool _isCanonicalMuscle(String muscle) {
    const canonicalMuscles = {
      'chest', 'lats', 'upper_back', 'traps',
      'deltoide_anterior', 'deltoide_lateral', 'deltoide_posterior',
      'deltoids', // Padre de deltoide
      'biceps', 'triceps',
      'quads', 'hamstrings', 'glutes', 'calves',
      'abs',
    };

    return canonicalMuscles.contains(muscle);
  }

  /// Verifica si tiene el equipamiento necesario
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

  /// Verifica si el ejercicio está contraindicado por lesión
  ///
  /// EJEMPLO:
  /// - Lesión de hombro → evitar overhead press
  /// - Lesión de rodilla → evitar squats profundos
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
