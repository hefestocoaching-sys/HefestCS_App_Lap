import 'dart:math';

import 'package:hcs_app_lap/core/enums/training_phase.dart';
import 'package:hcs_app_lap/domain/entities/exercise_entity.dart';
import 'package:hcs_app_lap/domain/entities/rep_range.dart';
import 'package:hcs_app_lap/services/exercise_catalog_service.dart';

class ExerciseBlock {
  final String label; // A, B1, B2, C1, C2
  final ExerciseEntity exercise;
  final int sets;
  final RepRange repRange;
  final String rir;
  final String color; // white / blue
  final bool isUnilateral;

  const ExerciseBlock({
    required this.label,
    required this.exercise,
    required this.sets,
    required this.repRange,
    required this.rir,
    required this.color,
    required this.isUnilateral,
  });
}

class TrainingPlanBuilder {
  final ExerciseCatalogService _catalog;

  TrainingPlanBuilder({ExerciseCatalogService? catalog})
    : _catalog = catalog ?? ExerciseCatalogService();

  /// Construye bloques A/B/C para un día, sin recalcular VOP.
  /// [vopByMuscle] debe contener series por músculo **para ese día**.
  List<ExerciseBlock> buildSession({
    required int dayIndex,
    required List<String> targetMuscles,
    required Map<String, int> vopByMuscle,
    required int sessionDuration,
    required TrainingPhase phase,
  }) {
    final blocks = <ExerciseBlock>[];
    if (targetMuscles.isEmpty || vopByMuscle.isEmpty) return blocks;

    // Ranking de músculos grandes para priorizar bloque A
    const bigMuscles = {
      'Pecho',
      'Espalda',
      'Pierna (Cuádriceps)',
      'Pierna (Isquios)',
      'Glúteo',
    };

    String? pickA;
    int maxSets = -1;
    for (final m in targetMuscles) {
      final sets = vopByMuscle[m] ?? 0;
      if (sets > maxSets || (sets == maxSets && bigMuscles.contains(m))) {
        maxSets = sets;
        pickA = m;
      }
    }

    // Helper para elegir ejercicios del catálogo
    ExerciseEntity chooseExercise(
      String muscleUi, {
      bool preferUnilateral = false,
    }) {
      final pool = _lookupExercises(muscleUi);
      if (pool.isEmpty) {
        return ExerciseEntity(
          id: 'placeholder_$muscleUi',
          nameEs: muscleUi,
          primaryMuscle: muscleUi,
          secondaryMuscles: const [],
          movementPattern: muscleUi,
          equivalenceGroup: muscleUi,
          equipment: const [],
        );
      }
      if (preferUnilateral) {
        final uni = pool.firstWhere(
          (e) => _isUnilateralName(e.nameEs),
          orElse: () => pool.first,
        );
        return uni;
      }
      return pool.first;
    }

    // Bloque A
    if (pickA != null && (vopByMuscle[pickA] ?? 0) > 0) {
      final setsA = max(3, min(5, vopByMuscle[pickA]!));
      final exA = chooseExercise(pickA, preferUnilateral: false);
      blocks.add(
        ExerciseBlock(
          label: 'A',
          exercise: exA,
          sets: setsA,
          repRange: const RepRange(6, 8),
          rir: '2-3',
          color: 'white',
          isUnilateral: _isUnilateralName(exA.nameEs),
        ),
      );
      vopByMuscle[pickA] = max(0, vopByMuscle[pickA]! - setsA);
    }

    // Resto de músculos para bloques B/C
    final remainingMuscles = List<String>.from(targetMuscles)
      ..remove(pickA)
      ..addAll(pickA != null ? [pickA] : const []); // si queda volumen residual

    final needsUnilateral = _shouldForceUnilateral(phase, dayIndex);
    bool unilateralPlaced = blocks.any((b) => b.isUnilateral);

    for (final muscle in remainingMuscles) {
      final sets = vopByMuscle[muscle] ?? 0;
      if (sets <= 0) continue;

      final isBBlock = blocks.where((b) => b.label.startsWith('B')).length < 2;
      final isCBlock =
          !isBBlock && blocks.where((b) => b.label.startsWith('C')).length < 2;
      if (!isBBlock && !isCBlock) break; // límite de 5 bloques

      final preferUnilateral = needsUnilateral && !unilateralPlaced;
      final ex = chooseExercise(muscle, preferUnilateral: preferUnilateral);
      unilateralPlaced = unilateralPlaced || _isUnilateralName(ex.nameEs);

      final bucket = _bucketForSets(sets);
      final label = isBBlock
          ? 'B${blocks.where((b) => b.label.startsWith('B')).length + 1}'
          : 'C${blocks.where((b) => b.label.startsWith('C')).length + 1}';

      blocks.add(
        ExerciseBlock(
          label: label,
          exercise: ex,
          sets: bucket.sets,
          repRange: bucket.repRange,
          rir: bucket.rir,
          color: label.startsWith('A') ? 'white' : 'blue',
          isUnilateral: _isUnilateralName(ex.nameEs),
        ),
      );
    }

    return blocks;
  }

  _BucketConfig _bucketForSets(int sets) {
    if (sets >= 5) {
      return const _BucketConfig(sets: 5, repRange: RepRange(6, 8), rir: '2-3');
    }
    if (sets >= 3) {
      return const _BucketConfig(
        sets: 3,
        repRange: RepRange(8, 12),
        rir: '1-2',
      );
    }
    return const _BucketConfig(sets: 2, repRange: RepRange(12, 15), rir: '1-2');
  }

  List<ExerciseEntity> _lookupExercises(String muscleUi) {
    // Mapeo básico UI -> catálogo (español)
    const map = {
      'Pecho': ['Pectoral', 'Pecho'],
      'Espalda': ['Espalda', 'Dorsal Ancho', 'Dorsales', 'Espalda Alta'],
      'Hombro': ['Hombro', 'Deltoide', 'Deltoides'],
      'Bíceps': ['Bíceps', 'Biceps'],
      'Tríceps': ['Tríceps', 'Triceps'],
      'Pierna (Cuádriceps)': ['Cuádriceps', 'Quadriceps', 'Pierna'],
      'Pierna (Isquios)': ['Isquiosurales', 'Isquiotibiales', 'Femoral'],
      'Glúteo': ['Glúteo', 'Gluteo'],
      'Pantorrilla': ['Pantorrilla', 'Gemelos', 'Soleo', 'Gastrocnemio'],
      'Abdomen': ['Abdomen', 'Core'],
    };

    final keys = map[muscleUi] ?? [muscleUi];
    final seen = <String>{};
    final out = <ExerciseEntity>[];
    for (final key in keys) {
      for (final ex in _catalog.getByPrimaryMuscleWithFallback(
        key,
        _fallbackForKey(key),
      )) {
        if (seen.add(ex.id)) out.add(ex);
      }
    }
    return out;
  }

  String? _fallbackForKey(String key) {
    switch (key) {
      case 'Espalda':
        return 'lats';
      case 'Hombro':
        return 'deltoide_lateral';
      case 'Pantorrilla':
        return 'calves';
      default:
        return null;
    }
  }

  bool _isUnilateralName(String name) {
    final n = name.toLowerCase();
    return n.contains('unilateral') ||
        n.contains('alterno') ||
        n.contains('alternado') ||
        n.contains('1 brazo') ||
        n.contains('una mano') ||
        n.contains('una pierna') ||
        n.contains('bulgar') ||
        n.contains('split squat');
  }

  bool _shouldForceUnilateral(TrainingPhase phase, int dayIndex) {
    if (phase.isAccumulation) return true;
    // pequeñas heurísticas de cobertura
    return dayIndex % 2 == 0; // forzar algunos días si no hay más datos
  }
}

class _BucketConfig {
  final int sets;
  final RepRange repRange;
  final String rir;

  const _BucketConfig({
    required this.sets,
    required this.repRange,
    required this.rir,
  });
}
