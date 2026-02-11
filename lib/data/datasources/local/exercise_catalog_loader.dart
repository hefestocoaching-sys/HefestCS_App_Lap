import 'dart:convert';
import 'package:hcs_app_lap/core/utils/app_logger.dart';
import 'package:flutter/services.dart';
import '../../../domain/entities/exercise.dart';

class ExerciseCatalogLoader {
  static List<Exercise>? _cache;

  static bool _validateV3(Map<String, dynamic> e, int i) {
    final id = e['id'];
    if (id is! String || id.trim().isEmpty) {
      logger.warning('ExerciseCatalogV3 missing id', {'index': i});
      return false;
    }
    final name = e['name'];
    if (name is String) {
      if (name.trim().isEmpty) {
        logger.warning('ExerciseCatalogV3 missing name', {
          'index': i,
          'exerciseId': id,
        });
        return false;
      }
    } else if (name is Map) {
      final es = name['es']?.toString() ?? '';
      final en = name['en']?.toString() ?? '';
      if (es.trim().isEmpty && en.trim().isEmpty) {
        logger.warning('ExerciseCatalogV3 missing name', {
          'index': i,
          'exerciseId': id,
        });
        return false;
      }
    } else {
      logger.warning('ExerciseCatalogV3 missing name', {
        'index': i,
        'exerciseId': id,
      });
      return false;
    }
    final pm = e['primaryMuscles'];
    if (pm is! List || pm.isEmpty) {
      logger.warning('ExerciseCatalogV3 missing primaryMuscles', {
        'index': i,
        'exerciseId': id,
      });
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
        logger.error('ExerciseCatalogV3 invalid root type');
        _cache = const <Exercise>[];
        return _cache!;
      }

      final list = decoded['exercises'];
      if (list is! List) {
        logger.error('ExerciseCatalogV3 missing exercises list');
        _cache = const <Exercise>[];
        return _cache!;
      }

      final out = <Exercise>[];
      for (var i = 0; i < list.length; i++) {
        final item = list[i];
        if (item is! Map<String, dynamic>) {
          logger.warning('ExerciseCatalogV3 item is not a map', {
            'index': i,
          });
          continue;
        }
        if (!_validateV3(item, i)) continue;
        out.add(Exercise.fromMap(item));
      }

      _cache = out;
      logger.info('ExerciseCatalogV3 loaded', {
        'count': _cache!.length,
      });

      // Diagnóstico: conteo por músculo primario
      final counts = <String, int>{};
      for (final ex in _cache!) {
        final k = ex.primaryMuscles.isNotEmpty
            ? ex.primaryMuscles.first
            : ex.muscleKey;
        counts[k] = (counts[k] ?? 0) + 1;
      }
      logger.debug('ExerciseCatalogV3 by primary muscle', {
        'counts': counts,
      });

      return _cache!;
    } catch (e, st) {
      logger.error('Failed to load exercise catalog v3', e, st);
      _cache = const <Exercise>[];
      return _cache!;
    }
  }
}
