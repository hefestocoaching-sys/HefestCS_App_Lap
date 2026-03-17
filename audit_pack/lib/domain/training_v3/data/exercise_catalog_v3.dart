import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hcs_app_lap/core/registry/muscle_registry.dart'
    as muscle_registry;
import 'package:hcs_app_lap/domain/entities/exercise.dart';

class ExerciseCatalogV3 {
  static final Map<String, List<Exercise>> _exercisesByMuscle = {};
  static final Map<String, List<Exercise>> _filteredExercisesByMuscle = {};
  static final Map<String, String> _exerciseTypeById = {};
  static final Map<String, Exercise> _exercisesById = {};
  static final Map<String, Map<String, dynamic>> _metadataById = {};
  static bool _baseLoaded = false;

  static String _normalizeKey(String rawKey) {
    final k = rawKey.trim().toLowerCase();
    if (k.isEmpty) return k;
    return muscle_registry.normalize(k) ?? k;
  }

  static void loadFromExercises(List<Exercise> exercises) {
    _filteredExercisesByMuscle.clear();

    for (final exercise in exercises) {
      _exercisesById[exercise.id] = exercise;
      _exerciseTypeById.putIfAbsent(exercise.id, () => 'compound');
      final keys = exercise.primaryMuscles.isNotEmpty
          ? exercise.primaryMuscles
          : (exercise.muscleKey.isNotEmpty ? [exercise.muscleKey] : const []);
      for (final rawKey in keys) {
        final key = _normalizeKey(rawKey);
        if (key.isEmpty) continue;
        final bucket = _filteredExercisesByMuscle.putIfAbsent(
          key,
          () => <Exercise>[],
        );
        if (!bucket.any((e) => e.id == exercise.id)) {
          bucket.add(exercise);
        }
      }
    }

    debugPrint(
      '[ExerciseCatalogV3] Filter loaded from list: ${_filteredExercisesByMuscle.length} keys',
    );
  }

  static Future<void> ensureLoaded() async {
    if (_baseLoaded) return;

    const path = 'assets/data/exercises/exercise_catalog_gym.json';
    try {
      final jsonStr = await rootBundle.loadString(path);
      final decoded = jsonDecode(jsonStr);
      if (decoded is! Map<String, dynamic>) {
        throw StateError('[ExerciseCatalogV3] Root inválido: se esperaba Map');
      }

      final list = decoded['exercises'];
      if (list is! List) {
        throw StateError(
          '[ExerciseCatalogV3] Root inválido: falta exercises[]',
        );
      }

      for (final item in list) {
        if (item is! Map<String, dynamic>) continue;
        final primary = item['primaryMuscles'];
        if (primary is! List || primary.isEmpty) continue;

        final exercise = Exercise.fromMap(item);
        final exerciseId = exercise.id;
        final type = item['category']?.toString() ?? 'compound';
        _exerciseTypeById[exerciseId] = type;
        _exercisesById[exerciseId] = exercise;
        _metadataById[exerciseId] = item;

        for (final rawKey in primary) {
          final key = rawKey?.toString() ?? '';
          if (key.isEmpty) continue;
          final normalizedKey = _normalizeKey(key);
          if (normalizedKey.isEmpty) continue;
          final bucket = _exercisesByMuscle.putIfAbsent(
            normalizedKey,
            () => <Exercise>[],
          );
          if (!bucket.any((e) => e.id == exercise.id)) {
            bucket.add(exercise);
          }
        }
      }

      _baseLoaded = true;
      debugPrint(
        '[ExerciseCatalogV3] Loaded keys: ${_exercisesByMuscle.length}',
      );
      debugPrintCatalogStatus();
    } catch (e) {
      debugPrint('ERROR cargando ExerciseCatalogV3: $e');
      _baseLoaded = true;
    }
  }

  static List<Exercise> getByMuscleKeys(List<String> keys) {
    final out = <Exercise>[];
    for (final key in keys) {
      final bucket = getByMuscle(key);
      if (bucket.isNotEmpty) {
        out.addAll(bucket);
      }
    }
    return out;
  }

  static List<Exercise> getByMuscle(String muscleKey) {
    final k = _normalizeKey(muscleKey);
    final filtered = _filteredExercisesByMuscle[k];
    if (filtered != null && filtered.isNotEmpty) return filtered;
    return _exercisesByMuscle[k] ?? const <Exercise>[];
  }

  static List<Exercise> getAllExercises() {
    final seen = <String>{};
    final out = <Exercise>[];
    for (final bucket in _exercisesByMuscle.values) {
      for (final exercise in bucket) {
        if (seen.add(exercise.id)) {
          out.add(exercise);
        }
      }
    }
    return out;
  }

  static Exercise? getById(String exerciseId) {
    return _exercisesById[exerciseId];
  }

  static String getTypeById(String exerciseId) {
    return _exerciseTypeById[exerciseId] ?? 'compound';
  }

  static Map<String, dynamic>? getMetadataById(String exerciseId) {
    return _metadataById[exerciseId];
  }

  static Map<String, bool> getAllowedIntensityZones(String exerciseId) {
    final metadata = _metadataById[exerciseId];
    final raw = metadata?['allowedIntensityZones'];
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), v == true));
    }
    return const {'heavy': true, 'medium': true, 'light': true};
  }

  static String? getEquivalenceGroup(String exerciseId) {
    return _metadataById[exerciseId]?['equivalenceGroup']?.toString();
  }

  static List<Exercise> getExercisesByIds(List<String> ids) {
    final out = <Exercise>[];
    for (final id in ids) {
      final exercise = _exercisesById[id];
      if (exercise != null) {
        out.add(exercise);
      }
    }
    return out;
  }

  /// Retorna lista de muscle keys disponibles en el catálogo
  static List<String> getAvailableKeys() {
    return _exercisesByMuscle.keys.toList()..sort();
  }

  /// Retorna resumen de disponibilidad de ejercicios por muscle key
  static Map<String, int> getKeySummary() {
    final summary = <String, int>{};
    _exercisesByMuscle.forEach((key, exercises) {
      summary[key] = exercises.length;
    });
    return summary;
  }

  /// Debug: imprime disponibilidad completa del catálogo
  static void debugPrintCatalogStatus() {
    debugPrint('[ExerciseCatalogV3] ═══════════════════════════════════');
    debugPrint('[ExerciseCatalogV3] CATALOG STATUS');
    debugPrint('[ExerciseCatalogV3] Base loaded: $_baseLoaded');
    debugPrint(
      '[ExerciseCatalogV3] Filter active keys: ${_filteredExercisesByMuscle.length}',
    );
    debugPrint(
      '[ExerciseCatalogV3] Total unique keys: ${_exercisesByMuscle.length}',
    );
    final summary = getKeySummary();
    summary.forEach((key, count) {
      debugPrint('[ExerciseCatalogV3]   - $key: $count exercises');
    });
    debugPrint('[ExerciseCatalogV3] ═══════════════════════════════════');
  }
}
