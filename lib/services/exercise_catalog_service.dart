import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:hcs_app_lap/core/utils/muscle_key_normalizer.dart';
import 'package:hcs_app_lap/core/constants/muscle_keys.dart';
import 'package:hcs_app_lap/domain/entities/exercise_entity.dart';

class ExerciseCatalogService {
  static final ExerciseCatalogService _instance = ExerciseCatalogService._();
  ExerciseCatalogService._();
  factory ExerciseCatalogService() => _instance;

  final Map<String, ExerciseEntity> _byId = {};
  final Map<String, List<ExerciseEntity>> _byEquivalenceGroup = {};
  final Map<String, List<ExerciseEntity>> _byPrimaryMuscle = {};
  bool _loaded = false;
  bool _loadAttempted = false;
  String? lastLoadError;

  bool get isLoaded => _loaded;
  bool get hasData => _byId.isNotEmpty;

  Future<void> ensureLoaded() async {
    // Si ya se intentó cargar exitosamente, no reintentar
    if (_loaded) return;
    // Si ya se intentó y falló, no reintentar
    if (_loadAttempted) return;
    _loadAttempted = true;

    try {
      await _loadFromAssets();
      _loaded = true;
      lastLoadError = null;
      debugPrint(
        '✓ ExerciseCatalogService: Successfully loaded exercise catalog',
      );
    } catch (e) {
      lastLoadError = e.toString();
      debugPrint('⚠️ ExerciseCatalogService: Error loading exercises: $e');
      // NO relanzar el error - continuar sin datos en lugar de fallar
      _loaded = false;
    }
  }

  Future<void> _loadFromAssets() async {
    final jsonStr = await rootBundle.loadString(
      'assets/data/exercise_catalog_gym.json',
    );

    final decoded = jsonDecode(jsonStr);

    // ✅ V3 CANÓNICO: root Map con exercises[]
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Exercise catalog root is not a Map');
    }

    final rawExercises = decoded['exercises'];

    if (rawExercises is! List) {
      throw Exception('Exercise catalog missing "exercises" list');
    }

    // Limpiar estado previo
    _byId.clear();
    _byEquivalenceGroup.clear();
    _byPrimaryMuscle.clear();

    int successCount = 0;
    int skippedCount = 0;
    int failedCount = 0;

    for (final raw in rawExercises) {
      if (raw is! Map<String, dynamic>) {
        skippedCount++;
        continue;
      }

      try {
        final ex = ExerciseEntity.fromJson(raw);
        if (ex.id.isEmpty || ex.nameEs.isEmpty) {
          skippedCount++;
          debugPrint('[Catalog] Skipped exercise: empty id or name');
          continue;
        }

        _byId[ex.id] = ex;
        _byEquivalenceGroup.putIfAbsent(ex.equivalenceGroup, () => []).add(ex);

        final keys = _canonicalKeysFor(ex);
        if (keys.isEmpty) {
          debugPrint(
            '[Catalog] No canonical keys for ${ex.id} (${ex.primaryMuscle})',
          );
        }
        for (final key in keys) {
          _byPrimaryMuscle.putIfAbsent(key, () => []).add(ex);
        }
        successCount++;
      } catch (e) {
        failedCount++;
        debugPrint('[Catalog] Failed exercise ${raw['id']}: $e');
      }
    }

    debugPrint(
      '[Catalog] Parsed: $successCount success, $skippedCount skipped, $failedCount failed',
    );

    if (_byId.isEmpty) {
      throw Exception('No exercises loaded after parsing');
    }

    debugPrint('[Catalog] Loaded $successCount exercises');
  }

  ExerciseEntity? getById(String id) => _byId[id];

  List<ExerciseEntity> getByEquivalenceGroup(String group) {
    return List.unmodifiable(_byEquivalenceGroup[group] ?? const []);
  }

  List<ExerciseEntity> getByPrimaryMuscle(String muscle) {
    return _lookupByMuscle(muscle);
  }

  List<ExerciseEntity> getByPrimaryMuscleWithFallback(
    String muscle,
    String? fallbackMuscle,
  ) {
    final primary = _lookupByMuscle(muscle);
    if (primary.isNotEmpty || fallbackMuscle == null) return primary;
    return _lookupByMuscle(fallbackMuscle);
  }

  List<ExerciseEntity> _lookupByMuscle(String muscle) {
    final seen = <String>{};
    final out = <ExerciseEntity>[];
    final canonicalKeys = normalizeLegacyVopToCanonical({muscle: 1}).keys;
    for (final key in canonicalKeys) {
      for (final ex in _byPrimaryMuscle[key] ?? const []) {
        if (seen.add(ex.id)) out.add(ex);
      }
    }
    return List.unmodifiable(out);
  }

  Set<String> _canonicalKeysFor(ExerciseEntity ex) {
    final normalized = normalizeMuscleKey(ex.primaryMuscle);
    if (MuscleKeys.isCanonical(normalized)) return {normalized};
    final canonical = normalizeLegacyVopToCanonical({normalized: 1}).keys;
    if (canonical.isNotEmpty) return canonical.toSet();
    return {normalized};
  }
}
