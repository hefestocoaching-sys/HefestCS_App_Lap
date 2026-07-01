import 'dart:convert';
import 'package:hcs_app_lap/core/utils/app_logger.dart';
import 'package:flutter/services.dart';
import 'package:hcs_app_lap/domain/entities/exercise.dart';

class ExerciseCatalogLoader {
  @Deprecated(
    'Legacy wrapper kept for compatibility; runtime SSOT is ExerciseCatalogV3.',
  )
  static List<Exercise>? _cache;

  static bool _validateV3(Map<String, dynamic> e, int i) {
    final id = e['id'];
    if (id is! String || id.trim().isEmpty) {
      logger.warning('ExerciseCatalogV3: Entry missing id', {'index': i});
      return false;
    }
    final name = e['name'];
    if (name is String) {
      if (name.trim().isEmpty) {
        logger.warning('ExerciseCatalogV3: Entry missing name', {
          'index': i,
          'id': id,
        });
        return false;
      }
    } else if (name is Map) {
      final es = name['es']?.toString() ?? '';
      final en = name['en']?.toString() ?? '';
      if (es.trim().isEmpty && en.trim().isEmpty) {
        logger.warning('ExerciseCatalogV3: Entry missing name', {
          'index': i,
          'id': id,
        });
        return false;
      }
    } else {
      logger.warning('ExerciseCatalogV3: Entry missing name', {
        'index': i,
        'id': id,
      });
      return false;
    }
    final pm = e['primaryMuscles'];
    if (pm is! List || pm.isEmpty) {
      logger.warning('ExerciseCatalogV3: Entry missing primaryMuscles', {
        'index': i,
        'id': id,
      });
      return false;
    }
    return true;
  }

  static Future<List<Exercise>> load() async {
    if (_cache != null && _cache!.isNotEmpty) return _cache!;

    const path =
        'assets/data/training_v3/catalog/exercise_catalog_v3_runtime.json';
    final jsonStr = await rootBundle.loadString(path);
    final decoded = jsonDecode(jsonStr);

    if (decoded is! Map<String, dynamic>) {
      throw StateError(
        'ExerciseCatalogV3 runtime root invalid: expected object',
      );
    }

    final list = decoded['exercises'];
    if (list is! List) {
      throw StateError(
        'ExerciseCatalogV3 runtime invalid: missing exercises[]',
      );
    }

    final out = <Exercise>[];
    for (var i = 0; i < list.length; i++) {
      final item = list[i];
      if (item is! Map<String, dynamic>) {
        throw StateError(
          'ExerciseCatalogV3 runtime invalid entry type at index=$i',
        );
      }
      if (!_validateV3(item, i)) {
        throw StateError(
          'ExerciseCatalogV3 runtime invalid mandatory fields at index=$i',
        );
      }
      out.add(Exercise.fromMap(item));
    }

    _cache = out;
    logger.info('ExerciseCatalogV3 runtime loaded', {'count': _cache!.length});
    return _cache!;
  }
}
