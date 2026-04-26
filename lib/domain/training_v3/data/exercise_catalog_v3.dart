import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hcs_app_lap/core/registry/muscle_registry.dart'
    as muscle_registry;
import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/domain/training_v3/models/exercise_catalog_v3_entry.dart';

class ExerciseCatalogV3 {
  static const String runtimeCatalogPath =
      'assets/data/training_v3/catalog/exercise_catalog_v3_runtime.json';
  static const String patternRegistryPath =
      'assets/data/training_v3/catalog/exercise_pattern_registry_v3.json';
  static const String muscleZoneDefaultsPath =
      'assets/data/training_v3/catalog/exercise_muscle_zone_defaults_v3.json';
  static const String slotConflictRulesPath =
      'assets/data/training_v3/catalog/exercise_slot_conflict_rules_v3.json';
  static const String mediaLibraryPath =
      'assets/data/training_v3/catalog/exercise_media_library_v3.json';

  static final Map<String, ExerciseCatalogV3Entry> _entriesById =
      <String, ExerciseCatalogV3Entry>{};
  static final Map<String, Exercise> _exercisesById = <String, Exercise>{};
  static final Map<String, Map<String, dynamic>> _metadataById =
      <String, Map<String, dynamic>>{};
  static final Map<String, List<Exercise>> _exercisesByMuscle =
      <String, List<Exercise>>{};

  static final Map<String, List<Exercise>> _testFilteredExercisesByMuscle =
      <String, List<Exercise>>{};

  static Map<String, dynamic> _patternRegistry = <String, dynamic>{};
  static Map<String, dynamic> _muscleZoneDefaults = <String, dynamic>{};
  static Map<String, dynamic> _slotConflictRules = <String, dynamic>{};
  static Map<String, dynamic> _mediaLibrary = <String, dynamic>{};

  static final Set<String> _registeredPatterns = <String>{};
  static final Set<String> _validSlots = <String>{};
  static final List<String> _validationWarnings = <String>[];

  static bool _baseLoaded = false;

  static String _normalizeMuscleKey(String rawKey) {
    final normalized = muscle_registry.normalize(rawKey.trim().toLowerCase());
    if (normalized != null) return normalized;
    return rawKey.trim().toLowerCase();
  }

  static Future<void> ensureLoaded() async {
    if (_baseLoaded) return;

    final runtimeRaw = await _loadRequiredJson(runtimeCatalogPath);
    final patternsRaw = await _loadRequiredJson(patternRegistryPath);
    final defaultsRaw = await _loadRequiredJson(muscleZoneDefaultsPath);
    final slotRulesRaw = await _loadRequiredJson(slotConflictRulesPath);
    final mediaRaw = await _loadRequiredJson(mediaLibraryPath);

    _patternRegistry = patternsRaw;
    _muscleZoneDefaults = defaultsRaw;
    _slotConflictRules = slotRulesRaw;
    _mediaLibrary = mediaRaw;

    _bootstrapRegistries();

    final exercisesRaw = runtimeRaw['exercises'];
    if (exercisesRaw is! List) {
      throw StateError(
        '[ExerciseCatalogV3] Invalid runtime catalog: missing exercises[] in $runtimeCatalogPath',
      );
    }

    _entriesById.clear();
    _exercisesById.clear();
    _metadataById.clear();
    _exercisesByMuscle.clear();
    _validationWarnings.clear();

    for (final raw in exercisesRaw) {
      if (raw is! Map) {
        throw StateError('[ExerciseCatalogV3] Invalid exercise row type: $raw');
      }
      final map = Map<String, dynamic>.from(raw);
      final entry = ExerciseCatalogV3Entry.fromMap(map);
      _validateEntryOrThrow(entry);
      _entriesById[entry.id] = entry;

      final exercise = _toRuntimeExercise(entry);
      _exercisesById[entry.id] = exercise;
      _metadataById[entry.id] = entry.toMap();

      for (final muscle in entry.primaryMuscles) {
        final key = _normalizeMuscleKey(muscle);
        final bucket = _exercisesByMuscle.putIfAbsent(key, () => <Exercise>[]);
        bucket.add(exercise);
      }

      _validateMediaWarningOnly(entry);
    }

    _baseLoaded = true;

    debugPrint(
      '[ExerciseCatalogV3] Loaded runtime catalog V3 entries=${_entriesById.length} keys=${_exercisesByMuscle.length}',
    );
  }

  static Future<Map<String, dynamic>> _loadRequiredJson(String path) async {
    try {
      final jsonStr = await rootBundle.loadString(path);
      final decoded = jsonDecode(jsonStr);
      if (decoded is! Map) {
        throw StateError('Root is not a JSON object');
      }
      return Map<String, dynamic>.from(decoded);
    } catch (error) {
      throw StateError(
        '[ExerciseCatalogV3] Failed loading asset $path: $error',
      );
    }
  }

  static void _bootstrapRegistries() {
    _registeredPatterns
      ..clear()
      ..addAll(_extractPatternKeys(_patternRegistry));

    _validSlots
      ..clear()
      ..addAll(_extractValidSlots(_slotConflictRules));

    if (_validSlots.isEmpty) {
      throw StateError(
        '[ExerciseCatalogV3] Missing validSlots in $slotConflictRulesPath',
      );
    }
  }

  static Set<String> _extractPatternKeys(Map<String, dynamic> registry) {
    final out = <String>{};
    final patterns = registry['patterns'];
    if (patterns is Map) {
      for (final key in patterns.keys) {
        final normalized = key.toString().trim().toLowerCase();
        if (normalized.isNotEmpty) out.add(normalized);
      }
    }
    return out;
  }

  static Set<String> _extractValidSlots(Map<String, dynamic> rules) {
    final out = <String>{};
    final sessionContract = rules['sessionContract'];
    if (sessionContract is Map) {
      final validSlots = sessionContract['validSlots'];
      if (validSlots is List) {
        for (final slot in validSlots) {
          final normalized = slot?.toString().trim().toUpperCase() ?? '';
          if (normalized.isNotEmpty) out.add(normalized);
        }
      }
    }
    return out;
  }

  static Exercise _toRuntimeExercise(ExerciseCatalogV3Entry entry) {
    return Exercise(
      id: entry.id,
      externalId: entry.id,
      name: entry.name,
      muscleKey: entry.primaryMuscles.first,
      equipment: entry.equipment.isNotEmpty ? entry.equipment.first : '',
      difficulty: entry.movementPattern,
      gifUrl: entry.media?.gifPath ?? '',
      primaryMuscles: entry.primaryMuscles,
      secondaryMuscles: entry.secondaryMuscles,
      tertiaryMuscles: entry.tertiaryMuscles,
      stimulusContribution: entry.stimulusContribution,
      movementPattern: entry.movementPattern,
      loadCategory: entry.loadCategory,
      fatigueScore: entry.fatigueScore,
      stimulusScore: entry.stimulusScore,
      allowedIntensityZones: entry.allowedIntensityZones,
      equivalenceGroup: entry.equivalenceGroup,
    );
  }

  static void _validateEntryOrThrow(ExerciseCatalogV3Entry entry) {
    if (entry.movementPattern.trim().isEmpty) {
      throw StateError(
        '[ExerciseCatalogV3] ${entry.id} missing movementPattern',
      );
    }
    if (entry.slotRoles.isEmpty) {
      throw StateError('[ExerciseCatalogV3] ${entry.id} missing slotRoles');
    }
    if (entry.allowedZones.isEmpty) {
      throw StateError('[ExerciseCatalogV3] ${entry.id} missing allowedZones');
    }
    if (entry.exerciseOrderClass <= 0) {
      throw StateError(
        '[ExerciseCatalogV3] ${entry.id} invalid exerciseOrderClass',
      );
    }

    final heavyAllowed = entry.allowedIntensityZones['heavy'] == true;
    if (entry.heavyRole == 'forbidden' && heavyAllowed) {
      throw StateError(
        '[ExerciseCatalogV3] ${entry.id} heavyRole=forbidden contradicts allowedIntensityZones.heavy=true',
      );
    }
    if ((entry.heavyRole == 'primary' || entry.heavyRole == 'secondary') &&
        !heavyAllowed) {
      throw StateError(
        '[ExerciseCatalogV3] ${entry.id} heavyRole=${entry.heavyRole} contradicts allowedIntensityZones.heavy=false',
      );
    }

    for (final muscle in entry.primaryMuscles) {
      final normalized = muscle_registry.normalize(muscle);
      if (normalized == null) {
        throw StateError(
          '[ExerciseCatalogV3] ${entry.id} unknown primaryMuscle=$muscle',
        );
      }
    }

    if (!_registeredPatterns.contains(entry.movementPattern)) {
      throw StateError(
        '[ExerciseCatalogV3] ${entry.id} movementPattern=${entry.movementPattern} not present in pattern registry',
      );
    }

    for (final slot in entry.slotRoles) {
      final normalized = slot.toUpperCase();
      if (!_validSlots.contains(normalized)) {
        throw StateError(
          '[ExerciseCatalogV3] ${entry.id} invalid slotRole=$slot',
        );
      }
    }

    final allowsA = entry.slotRoles.contains('A');
    if (entry.aEligibility == 'primary' && !allowsA) {
      throw StateError(
        '[ExerciseCatalogV3] ${entry.id} aEligibility=primary but slotRoles does not include A',
      );
    }

    final conflictsOk = entry.conflictPatterns.every(
      (p) => p.trim().isNotEmpty,
    );
    if (!conflictsOk) {
      throw StateError(
        '[ExerciseCatalogV3] ${entry.id} invalid conflictPatterns format',
      );
    }
    if (entry.pairingClass.trim().isEmpty) {
      throw StateError(
        '[ExerciseCatalogV3] ${entry.id} invalid pairingClass format',
      );
    }
  }

  static void _validateMediaWarningOnly(ExerciseCatalogV3Entry entry) {
    final gifPath = entry.media?.gifPath;
    if (gifPath == null || gifPath.isEmpty) return;

    final normalizedPath = gifPath.replaceAll('\\', '/');
    final isValidPrefix = normalizedPath.startsWith(
      'assets/media/exercises/gifs/',
    );
    if (!isValidPrefix) {
      _validationWarnings.add(
        '[ExerciseCatalogV3][WARN_MEDIA] ${entry.id} gifPath out of expected prefix: $gifPath',
      );
    }
  }

  @Deprecated(
    'Test-only filter. Runtime must use full SSOT catalog from assets.',
  )
  static void loadFromExercises(List<Exercise> exercises) {
    _testFilteredExercisesByMuscle.clear();
    for (final exercise in exercises) {
      final keys = exercise.primaryMuscles.isNotEmpty
          ? exercise.primaryMuscles
          : (exercise.muscleKey.isNotEmpty
                ? <String>[exercise.muscleKey]
                : const <String>[]);
      for (final raw in keys) {
        final key = _normalizeMuscleKey(raw);
        final bucket = _testFilteredExercisesByMuscle.putIfAbsent(
          key,
          () => <Exercise>[],
        );
        if (!bucket.any((current) => current.id == exercise.id)) {
          bucket.add(exercise);
        }
      }
      _exercisesById.putIfAbsent(exercise.id, () => exercise);
      _metadataById.putIfAbsent(
        exercise.id,
        () => <String, dynamic>{
          'id': exercise.id,
          'name': exercise.name,
          'primaryMuscles': exercise.primaryMuscles,
          'secondaryMuscles': exercise.secondaryMuscles,
          'movementPattern': exercise.movementPattern,
          'loadCategory': exercise.loadCategory,
          'fatigueScore': exercise.fatigueScore,
          'stimulusScore': exercise.stimulusScore,
          'allowedIntensityZones': exercise.allowedIntensityZones,
          'equivalenceGroup': exercise.equivalenceGroup,
          'equipment': exercise.equipment.isEmpty
              ? const <String>[]
              : <String>[exercise.equipment],
          'slotRoles': const <String>[],
        },
      );
    }
  }

  static bool get isLoaded => _baseLoaded;

  static Map<String, dynamic> get patternRegistry => _patternRegistry;

  static Map<String, dynamic> get muscleZoneDefaults => _muscleZoneDefaults;

  static Map<String, dynamic> get slotConflictRules => _slotConflictRules;

  static Map<String, dynamic> get mediaLibrary => _mediaLibrary;

  static List<String> getCatalogWarnings() =>
      List<String>.from(_validationWarnings);

  static List<Exercise> getByMuscleKeys(List<String> keys) {
    final out = <Exercise>[];
    final seen = <String>{};
    for (final key in keys) {
      for (final exercise in getByMuscle(key)) {
        if (seen.add(exercise.id)) out.add(exercise);
      }
    }
    return out;
  }

  static List<Exercise> getByMuscle(String muscleKey) {
    final key = _normalizeMuscleKey(muscleKey);
    final filtered = _testFilteredExercisesByMuscle[key];
    if (filtered != null && filtered.isNotEmpty) {
      return List<Exercise>.from(filtered);
    }
    return List<Exercise>.from(_exercisesByMuscle[key] ?? const <Exercise>[]);
  }

  static List<Exercise> getAllExercises() {
    final source = _testFilteredExercisesByMuscle.isNotEmpty
        ? _testFilteredExercisesByMuscle.values
        : _exercisesByMuscle.values;
    final seen = <String>{};
    final out = <Exercise>[];
    for (final bucket in source) {
      for (final exercise in bucket) {
        if (seen.add(exercise.id)) out.add(exercise);
      }
    }
    return out;
  }

  static List<String> getAvailableKeys() {
    final keys = _testFilteredExercisesByMuscle.isNotEmpty
        ? _testFilteredExercisesByMuscle.keys
        : _exercisesByMuscle.keys;
    return keys.toList()..sort();
  }

  static Map<String, int> getKeySummary() {
    final source = _testFilteredExercisesByMuscle.isNotEmpty
        ? _testFilteredExercisesByMuscle
        : _exercisesByMuscle;
    return <String, int>{
      for (final entry in source.entries) entry.key: entry.value.length,
    };
  }

  static Exercise? getById(String exerciseId) => _exercisesById[exerciseId];

  static Map<String, dynamic>? getMetadataById(String exerciseId) =>
      _metadataById[exerciseId];

  static List<Exercise> getExercisesByIds(List<String> ids) {
    final out = <Exercise>[];
    for (final id in ids) {
      final exercise = _exercisesById[id];
      if (exercise != null) out.add(exercise);
    }
    return out;
  }

  static String getTypeById(String exerciseId) {
    final category = _metadataById[exerciseId]?['category']?.toString();
    return (category == null || category.isEmpty) ? 'compound' : category;
  }

  static String getMovementPattern(String exerciseId) {
    final pattern = _metadataById[exerciseId]?['movementPattern']?.toString();
    if (pattern == null || pattern.trim().isEmpty) return 'unknown';
    return pattern.trim().toLowerCase();
  }

  static Map<String, bool> getAllowedIntensityZones(String exerciseId) {
    final raw = _metadataById[exerciseId]?['allowedIntensityZones'];
    if (raw is! Map) {
      return const <String, bool>{
        'heavy': false,
        'medium': false,
        'light': false,
      };
    }

    bool toBool(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      final normalized = value?.toString().trim().toLowerCase();
      return normalized == 'true' ||
          normalized == '1' ||
          normalized == 'yes' ||
          normalized == 'si';
    }

    return <String, bool>{
      'heavy': toBool(raw['heavy']),
      'medium': toBool(raw['medium']),
      'light': toBool(raw['light']),
    };
  }

  static bool allowsZone(String exerciseId, String zone) {
    final normalizedZone = zone.trim().toLowerCase();
    return getAllowedIntensityZones(exerciseId)[normalizedZone] == true;
  }

  static String getLoadCategory(String exerciseId) {
    final raw = _metadataById[exerciseId]?['loadCategory']
        ?.toString()
        .trim()
        .toLowerCase();
    if (raw == null || raw.isEmpty) return 'light';
    if (raw == 'moderate') return 'medium';
    if (raw == 'heavy' || raw == 'medium' || raw == 'light') return raw;
    return 'light';
  }

  static int getFatigueScore(String exerciseId) {
    final raw = _metadataById[exerciseId]?['fatigueScore'];
    if (raw is int) return raw;
    if (raw is num) return raw.round();
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  static int getStimulusScore(String exerciseId) {
    final raw = _metadataById[exerciseId]?['stimulusScore'];
    if (raw is int) return raw;
    if (raw is num) return raw.round();
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  static String? getEquivalenceGroup(String exerciseId) {
    final group = _metadataById[exerciseId]?['equivalenceGroup']?.toString();
    if (group == null || group.trim().isEmpty) return null;
    return group.trim();
  }

  static int getExerciseOrderClass(String exerciseId) {
    final raw = _metadataById[exerciseId]?['exerciseOrderClass'];
    if (raw is int) return raw;
    if (raw is num) return raw.round();
    return int.tryParse(raw?.toString() ?? '') ?? 999;
  }

  static List<String> getSlotRoles(String exerciseId) {
    final raw = _metadataById[exerciseId]?['slotRoles'];
    if (raw is! List) return const <String>[];
    return raw
        .map((slot) => slot?.toString().trim().toUpperCase() ?? '')
        .where((slot) => slot.isNotEmpty)
        .toList(growable: false);
  }

  static bool supportsSlot(String exerciseId, String slotRole) {
    final normalized = slotRole.trim().toUpperCase();
    return getSlotRoles(exerciseId).contains(normalized);
  }

  static bool isAEligible(String exerciseId) {
    final eligibility = _metadataById[exerciseId]?['aEligibility']
        ?.toString()
        .trim()
        .toLowerCase();
    final allowsA = supportsSlot(exerciseId, 'A');
    if (!allowsA) return false;
    return eligibility == 'primary' ||
        eligibility == 'secondary' ||
        eligibility == 'optional';
  }

  static bool getSecondaryHeavyEligibility(String exerciseId) {
    final raw = _metadataById[exerciseId]?['secondaryHeavyEligibility'];
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    final normalized = raw?.toString().trim().toLowerCase();
    return normalized == 'true' ||
        normalized == '1' ||
        normalized == 'yes' ||
        normalized == 'si';
  }

  static String getHeavyRole(String exerciseId) {
    final raw = _metadataById[exerciseId]?['heavyRole']
        ?.toString()
        .trim()
        .toLowerCase();
    if (raw == null || raw.isEmpty) return 'forbidden';
    return raw;
  }

  static List<String> getConflictPatterns(String exerciseId) {
    final raw = _metadataById[exerciseId]?['conflictPatterns'];
    if (raw is! List) return const <String>[];
    return raw
        .map((pattern) => pattern?.toString().trim().toLowerCase() ?? '')
        .where((pattern) => pattern.isNotEmpty)
        .toList(growable: false);
  }

  static String getRotationGroup(String exerciseId) {
    return _metadataById[exerciseId]?['rotationGroup']?.toString() ?? '';
  }

  static String getAngleTag(String exerciseId) {
    return _metadataById[exerciseId]?['angleTag']?.toString() ?? '';
  }

  static int getVariantTier(String exerciseId) {
    final raw = _metadataById[exerciseId]?['variantTier'];
    if (raw is int) return raw;
    if (raw is num) return raw.round();
    return int.tryParse(raw?.toString() ?? '') ?? 99;
  }

  static bool canPromoteToHeavyNextBlock(String exerciseId) {
    final raw = _metadataById[exerciseId]?['canPromoteToHeavyNextBlock'];
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    final normalized = raw?.toString().trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }

  static bool canDemoteToMediumNextBlock(String exerciseId) {
    final raw = _metadataById[exerciseId]?['canDemoteToMediumNextBlock'];
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    final normalized = raw?.toString().trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }

  static bool isPatternRegistered(String pattern) {
    return _registeredPatterns.contains(pattern.trim().toLowerCase());
  }

  static List<String> allowedPatternsForSlot(String slotRole) {
    final normalizedSlot = slotRole.trim().toUpperCase();
    final patterns = _patternRegistry['patterns'];
    if (patterns is! Map) return const <String>[];
    final out = <String>[];

    for (final entry in patterns.entries) {
      final pattern = entry.key.toString().trim().toLowerCase();
      final details = entry.value;
      if (details is! Map) continue;

      final slots = details['defaultSlotRoles'];
      if (slots is! List) continue;
      final supports = slots.any(
        (slot) => slot?.toString().trim().toUpperCase() == normalizedSlot,
      );
      if (supports) out.add(pattern);
    }

    out.sort();
    return out;
  }

  static List<Exercise> findEquivalentExercisesForZone({
    required Exercise source,
    required String zone,
    String? muscleKey,
    Set<String>? excludeIds,
  }) {
    final eqGroup = getEquivalenceGroup(source.id);
    if (eqGroup == null || eqGroup.isEmpty) return const <Exercise>[];

    final normalizedMuscle = muscleKey == null || muscleKey.trim().isEmpty
        ? null
        : _normalizeMuscleKey(muscleKey);
    final blocked = excludeIds ?? const <String>{};
    final sourcePattern = getMovementPattern(source.id);

    final out = <Exercise>[];
    for (final exercise in getAllExercises()) {
      if (exercise.id == source.id || blocked.contains(exercise.id)) continue;
      if (getEquivalenceGroup(exercise.id) != eqGroup) continue;
      if (!allowsZone(exercise.id, zone)) continue;
      if (getMovementPattern(exercise.id) != sourcePattern) continue;

      if (normalizedMuscle != null) {
        final matchesMuscle = exercise.primaryMuscles.any(
          (muscle) => _normalizeMuscleKey(muscle) == normalizedMuscle,
        );
        if (!matchesMuscle) continue;
      }

      out.add(exercise);
    }

    out.sort((left, right) {
      final byStimulus = getStimulusScore(
        right.id,
      ).compareTo(getStimulusScore(left.id));
      if (byStimulus != 0) return byStimulus;

      final byFatigue = getFatigueScore(
        left.id,
      ).compareTo(getFatigueScore(right.id));
      if (byFatigue != 0) return byFatigue;

      final byOrderClass = getExerciseOrderClass(
        left.id,
      ).compareTo(getExerciseOrderClass(right.id));
      if (byOrderClass != 0) return byOrderClass;

      return left.id.compareTo(right.id);
    });

    return out;
  }

  static void debugPrintCatalogStatus() {
    debugPrint('[ExerciseCatalogV3] ===== Runtime Status =====');
    debugPrint(
      '[ExerciseCatalogV3] loaded=$_baseLoaded entries=${_entriesById.length}',
    );
    debugPrint(
      '[ExerciseCatalogV3] keys=${getAvailableKeys().length} warnings=${_validationWarnings.length}',
    );
  }
}
