// lib/domain/training_v3/engines/ordering_engine.dart

import 'package:hcs_app_lap/domain/training_v3/data/exercise_catalog_v3.dart';
import 'package:hcs_app_lap/domain/training_v3/constants/muscle_key_registry.dart';
import 'package:hcs_app_lap/domain/training_v3/models/exercise_prescription.dart';
import 'package:hcs_app_lap/domain/training_v3/models/planned_exercise.dart';
import 'package:hcs_app_lap/core/utils/muscle_key_normalizer.dart';
import 'package:hcs_app_lap/domain/policies/structural_exercise_order_contract.dart';

/// Motor de ordenamiento científico de ejercicios
///
/// Implementa las reglas científicas de la Semana 5 (Imagen 60-63):
/// - Compounds grandes primero (squat, deadlift, bench)
/// - Compounds auxiliares segundo (rows, overhead press)
/// - Aislamiento primario tercero (curls, extensions)
/// - Aislamiento secundario último (calves, abs)
///
/// FUNDAMENTO CIENTÍFICO:
/// - Semana 5, Imagen 60-63: Orden óptimo de ejercicios
/// - Regla: Ejercicios que requieren más técnica/fuerza primero
/// - Fatiga acumulada reduce rendimiento en ejercicios tardíos
///
/// REFERENCIAS:
/// - Simão et al. (2012): Exercise order effects
/// - Spiering et al. (2008): Influence of exercise order
///
/// Versión: 1.0.0
class OrderingEngine {
  static const List<String> _slotOrder = [
    'A',
    'B1',
    'B2',
    'C1',
    'C2',
    'D1',
    'D2',
  ];

  // P0.1 Rule E Constants
  static const Set<String> _majorMuscles = {
    'pectorals',
    'lats',
    'upper_back',
    'traps',
    'glutes',
    'quads',
    'hamstrings',
  };

  /// P0.1 Table mapping logic
  static int _pdfOrderIndex({
    required String muscleKey,
    required String exerciseId,
    required String zone,
  }) {
    final canonicalMuscleKey = normalizeMuscleKey(muscleKey);
    final type = ExerciseCatalogV3.getTypeById(exerciseId);
    final isCompound = (type == 'compound');
    final isMajor = _majorMuscles.contains(canonicalMuscleKey);

    return StructuralExerciseOrderContract.structuralIndex(
      isLargeMuscle: isMajor,
      isCompound: isCompound,
      intensityZone: zone,
    );
  }

  /// P0.1 Evaluates Rule E index directly on prescriptions
  static void orderSessionExercises(
    List<ExercisePrescription> sessionExercises,
  ) {
    sessionExercises.sort((a, b) {
      final indexA = _pdfOrderIndex(
        muscleKey: a.directTargetMuscleKey,
        exerciseId: a.exerciseId,
        zone: a.intensityZone,
      );
      final indexB = _pdfOrderIndex(
        muscleKey: b.directTargetMuscleKey,
        exerciseId: b.exerciseId,
        zone: b.intensityZone,
      );
      return indexA.compareTo(indexB);
    });
  }

  /// P0-A Evaluates Rule E index directly on planned exercises.
  /// Uses the actual intensity zone inferred from each exercise's set
  /// prescriptions instead of a blanket medium fallback.
  static void orderPlannedExercises(List<PlannedExercise> sessionExercises) {
    sessionExercises.sort((a, b) {
      final slotA = (a.slotLabel ?? '').toUpperCase();
      final slotB = (b.slotLabel ?? '').toUpperCase();
      final slotIndexA = _slotOrder.indexOf(slotA);
      final slotIndexB = _slotOrder.indexOf(slotB);
      if (slotIndexA >= 0 || slotIndexB >= 0) {
        final aResolved = slotIndexA >= 0 ? slotIndexA : 1 << 20;
        final bResolved = slotIndexB >= 0 ? slotIndexB : 1 << 20;
        if (aResolved != bResolved) {
          return aResolved.compareTo(bResolved);
        }
      }

      final indexA = _pdfOrderIndex(
        muscleKey: a.muscleKey,
        exerciseId: a.exerciseId,
        zone: _intensityZoneFromPrescription(a.sets),
      );
      final indexB = _pdfOrderIndex(
        muscleKey: b.muscleKey,
        exerciseId: b.exerciseId,
        zone: _intensityZoneFromPrescription(b.sets),
      );
      return indexA.compareTo(indexB);
    });
  }

  /// Infers the intensity zone from a list of set prescriptions.
  /// Uses average repsMax: ≤8 → heavy, ≤15 → medium, >15 → light.
  static String _intensityZoneFromPrescription(List<SetPrescription> sets) {
    if (sets.isEmpty) return IntensityZone.medium;
    final avgMax =
        sets.map((s) => s.repsMax).reduce((a, b) => a + b) / sets.length;
    if (avgMax <= 8) return IntensityZone.heavy;
    if (avgMax <= 15) return IntensityZone.medium;
    return IntensityZone.light;
  }

  /// Ordena ejercicios científicamente
  ///
  /// ALGORITMO:
  /// 1. Clasificar por categoría (compound grande/auxiliar/isolation)
  /// 2. Dentro de cada categoría, ordenar por fatiga sistémica (mayor primero)
  /// 3. Retornar lista ordenada
  ///
  /// PARÁMETROS:
  /// - [exercises]: Lista de IDs de ejercicios a ordenar
  /// - [exerciseData]: Metadata de ejercicios (tipo, fatiga, etc.)
  ///
  /// RETORNA:
  /// - List&lt;String&gt;: IDs ordenados científicamente
  static List<String> orderExercises({
    required List<String> exercises,
    required Map<String, Map<String, dynamic>> exerciseData,
  }) {
    // PASO 1: Clasificar por categoría
    final bigCompounds = <String>[];
    final auxCompounds = <String>[];
    final primaryIsolation = <String>[];
    final secondaryIsolation = <String>[];

    for (final exerciseId in exercises) {
      final data = exerciseData[exerciseId];
      if (data == null) continue;

      final category = _categorizeExercise(data);

      switch (category) {
        case 'big_compound':
          bigCompounds.add(exerciseId);
          break;
        case 'aux_compound':
          auxCompounds.add(exerciseId);
          break;
        case 'primary_isolation':
          primaryIsolation.add(exerciseId);
          break;
        case 'secondary_isolation':
          secondaryIsolation.add(exerciseId);
          break;
      }
    }

    // PASO 2: Dentro de cada categoría, ordenar por fatiga
    _sortByFatigue(bigCompounds, exerciseData);
    _sortByFatigue(auxCompounds, exerciseData);
    _sortByFatigue(primaryIsolation, exerciseData);
    _sortByFatigue(secondaryIsolation, exerciseData);

    // PASO 3: Concatenar en orden científico
    return [
      ...bigCompounds,
      ...auxCompounds,
      ...primaryIsolation,
      ...secondaryIsolation,
    ];
  }

  /// Categoriza un ejercicio según criterios científicos
  ///
  /// FUENTE: Semana 5, Imagen 60-63
  ///
  /// CATEGORÍAS:
  /// - big_compound: Squat, deadlift, bench press (alta fatiga, multi-articular)
  /// - aux_compound: Rows, overhead press, lunges (moderada fatiga)
  /// - primary_isolation: Curls, extensions, lateral raises
  /// - secondary_isolation: Calves, abs, forearms
  static String _categorizeExercise(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final fatigue = (data['systemic_fatigue'] as num?)?.toDouble() ?? 5.0;
    final primaryMuscles =
        (data['primary_muscles'] as List?)?.cast<String>() ?? [];

    if (type == 'compound') {
      // Big compounds: fatiga alta (>7)
      if (fatigue >= 7.0) {
        return 'big_compound';
      } else {
        return 'aux_compound';
      }
    } else {
      // Isolation: separar por grupo muscular
      if (_isSecondaryMuscle(primaryMuscles)) {
        return 'secondary_isolation';
      } else {
        return 'primary_isolation';
      }
    }
  }

  /// Verifica si es músculo secundario (calves, abs, forearms)
  static bool _isSecondaryMuscle(List<String> muscles) {
    final secondary = ['calves', 'abs', 'forearms'];
    return muscles.any((m) => secondary.contains(m));
  }

  /// Ordena ejercicios por fatiga (mayor primero)
  static void _sortByFatigue(
    List<String> exercises,
    Map<String, Map<String, dynamic>> exerciseData,
  ) {
    exercises.sort((a, b) {
      final fatigueA =
          (exerciseData[a]?['systemic_fatigue'] as num?)?.toDouble() ?? 5.0;
      final fatigueB =
          (exerciseData[b]?['systemic_fatigue'] as num?)?.toDouble() ?? 5.0;
      return fatigueB.compareTo(fatigueA); // Descendente
    });
  }

  /// Valida que el orden sea científicamente correcto
  ///
  /// REGLA: Compounds deben estar antes de isolation
  static bool isOrderValid({
    required List<String> orderedExercises,
    required Map<String, Map<String, dynamic>> exerciseData,
  }) {
    bool seenIsolation = false;

    for (final exerciseId in orderedExercises) {
      final type = exerciseData[exerciseId]?['type'] as String?;

      if (type == 'isolation') {
        seenIsolation = true;
      } else if (type == 'compound' && seenIsolation) {
        // ERROR: Compound después de isolation
        return false;
      }
    }

    return true;
  }

  /// Obtiene índice de prioridad de un ejercicio (menor = primero)
  ///
  /// USADO PARA: Sorting custom
  static int getPriorityIndex(Map<String, dynamic> exerciseData) {
    final category = _categorizeExercise(exerciseData);

    switch (category) {
      case 'big_compound':
        return 1;
      case 'aux_compound':
        return 2;
      case 'primary_isolation':
        return 3;
      case 'secondary_isolation':
        return 4;
      default:
        return 5;
    }
  }
}
