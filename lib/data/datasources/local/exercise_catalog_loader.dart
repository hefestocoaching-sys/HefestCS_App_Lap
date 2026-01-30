import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../../domain/entities/exercise.dart';

class ExerciseCatalogLoader {
  static List<Exercise>? _cache;

  static bool _validateV3(Map<String, dynamic> e, int i) {
    final id = e['id'];
    if (id is! String || id.trim().isEmpty) {
      debugPrint('[ExerciseCatalogV3] idx=$i: falta id');
      return false;
    }
    final name = e['name'];
    if (name is String) {
      if (name.trim().isEmpty) {
        debugPrint('[ExerciseCatalogV3] idx=$i id=$id: falta name');
        return false;
      }
    } else if (name is Map) {
      final es = name['es']?.toString() ?? '';
      final en = name['en']?.toString() ?? '';
      if (es.trim().isEmpty && en.trim().isEmpty) {
        debugPrint('[ExerciseCatalogV3] idx=$i id=$id: falta name');
        return false;
      }
    } else {
      debugPrint('[ExerciseCatalogV3] idx=$i id=$id: falta name');
      return false;
    }
    final pm = e['primaryMuscles'];
    if (pm is! List || pm.isEmpty) {
      debugPrint('[ExerciseCatalogV3] idx=$i id=$id: falta primaryMuscles');
      return false;
    }
    return true;
  }

  static Future<List<Exercise>> load() async {
    if (_cache != null && _cache!.isNotEmpty) return _cache!;

    try {
      const path = 'assets/data/exercises/exercise_catalog_gym.json';
      final jsonStr = await rootBundle.loadString(path);
      final decoded = jsonDecode(jsonStr);

      // V3: root object con { schemaVersion, lastUpdated, notes, exercises: [] }
      if (decoded is! Map<String, dynamic>) {
        debugPrint('[ExerciseCatalogV3] Root inválido: se esperaba Map');
        _cache = const <Exercise>[];
        return _cache!;
      }

      final list = decoded['exercises'];
      if (list is! List) {
        debugPrint('[ExerciseCatalogV3] Root inválido: falta exercises[]');
        _cache = const <Exercise>[];
        return _cache!;
      }

      final out = <Exercise>[];
      for (var i = 0; i < list.length; i++) {
        final item = list[i];
        if (item is! Map<String, dynamic>) {
          debugPrint('[ExerciseCatalogV3] idx=$i: no es Map');
          continue;
        }
        if (!_validateV3(item, i)) continue;
        out.add(Exercise.fromMap(item));
      }

      _cache = out;
      debugPrint('[ExerciseCatalogV3] Loaded: ${_cache!.length} exercises');

      // Diagnóstico: conteo por músculo primario
      final counts = <String, int>{};
      for (final ex in _cache!) {
        final k = ex.primaryMuscles.isNotEmpty
            ? ex.primaryMuscles.first
            : ex.muscleKey;
        counts[k] = (counts[k] ?? 0) + 1;
      }
      debugPrint('[ExerciseCatalogV3] By primary: $counts');

      return _cache!;
    } catch (e, st) {
      debugPrint('ERROR cargando catálogo v3: $e');
      debugPrint(st.toString());
      _cache = const <Exercise>[];
      return _cache!;
    }
  }
}
