import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hcs_app_lap/domain/entities/exercise.dart';

class ExerciseCatalogV3 {
  static final Map<String, List<Exercise>> _exercisesByMuscle = {};
  static final Map<String, String> _exerciseTypeById = {};
  static bool _loaded = false;

  static Future<void> ensureLoaded() async {
    if (_loaded) return;

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
        final type = item['type']?.toString() ?? 'compound';
        _exerciseTypeById[exerciseId] = type;

        for (final rawKey in primary) {
          final key = rawKey?.toString() ?? '';
          if (key.isEmpty) continue;
          final bucket = _exercisesByMuscle.putIfAbsent(
            key,
            () => <Exercise>[],
          );
          bucket.add(exercise);
        }
      }

      _loaded = true;
      debugPrint(
        '[ExerciseCatalogV3] Loaded keys: ${_exercisesByMuscle.length}',
      );
    } catch (e) {
      debugPrint('ERROR cargando ExerciseCatalogV3: $e');
      _loaded = true;
    }
  }

  static List<Exercise> getByMuscleKeys(List<String> keys) {
    final out = <Exercise>[];
    for (final key in keys) {
      final bucket = _exercisesByMuscle[key];
      if (bucket != null && bucket.isNotEmpty) {
        out.addAll(bucket);
      }
    }
    return out;
  }

  static List<Exercise> getByMuscle(String muscleKey) {
    final k = muscleKey.trim().toLowerCase();
    return _exercisesByMuscle[k] ?? const <Exercise>[];
  }

  static String getTypeById(String exerciseId) {
    return _exerciseTypeById[exerciseId] ?? 'compound';
  }
}
