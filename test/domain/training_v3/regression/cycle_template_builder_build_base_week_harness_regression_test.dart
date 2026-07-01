import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/domain/training_v3/data/exercise_catalog_v3.dart';
import 'package:hcs_app_lap/domain/training_v3/models/client_profile.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/intensity_distribution_engine.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_session.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_split.dart';
import 'package:hcs_app_lap/domain/training_v3/models/user_profile.dart';
import 'package:hcs_app_lap/domain/training_v3/services/cycle_template_builder.dart';
import 'package:hcs_app_lap/core/registry/muscle_registry.dart'
    as muscle_registry;

// Lightweight, restored harness for buildBaseWeek regression testing.
// It intentionally mirrors the original harness behavior but uses
// safe normalization for reporting.

const _fixtureNames = <String>[
  'cycle_template_builder_canonical.json',
  'cycle_template_builder_alias.json',
  'cycle_template_builder_unknown.json',
  'cycle_template_builder_group.json',
  'cycle_template_builder_mixed.json',
  'cycle_template_builder_block_pairing.json',
  'cycle_template_builder_training_week_snapshot.json',
];

Map<String, int> _computeNormalizedTargetVolume(Map<String, int> src) {
  final out = <String, int>{};
  for (final entry in src.entries) {
    final norm = muscle_registry.tryNormalizeMuscleKey(entry.key);
    if (norm != null) {
      out[norm] = (out[norm] ?? 0) + entry.value;
      continue;
    }
    final expanded = muscle_registry.expandMuscleGroupStrict(entry.key);
    if (expanded != null && expanded.isNotEmpty) {
      for (final m in expanded) {
        out[m] = (out[m] ?? 0) + entry.value;
      }
      continue;
    }
    out[entry.key] = (out[entry.key] ?? 0) + entry.value;
  }
  return out;
}

Map<String, List<String>> _normalizedPoolKeys(
  Map<String, List<String>> source,
) {
  return source.map((key, value) {
    final norm = muscle_registry.tryNormalizeMuscleKey(key) ?? key;
    final expanded = muscle_registry.expandMuscleGroupStrict(key);
    if (expanded != null && expanded.isNotEmpty) {
      return MapEntry(expanded.join(','), List<String>.from(value));
    }
    return MapEntry(norm, List<String>.from(value));
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_installHarnessCatalog);

  group('CycleTemplateBuilder buildBaseWeek harness regression', () {
    for (final fixtureName in _fixtureNames) {
      test(fixtureName, () {
        final fixture = _loadFixture(fixtureName);
        final cases = List<Map<String, dynamic>>.from(
          (fixture['cases'] as List).map(
            (raw) => Map<String, dynamic>.from(raw as Map),
          ),
        );

        for (final fixtureCase in cases) {
          final expected = Map<String, dynamic>.from(
            fixtureCase['expected'] as Map,
          );
          final actual = _runCase(
            Map<String, dynamic>.from(fixtureCase['input'] as Map),
          );

          expect(
            _matchesSubset(actual, expected),
            isTrue,
            reason:
                '${fixtureCase['id'] as String}\nACTUAL: ${jsonEncode(actual)}\nEXPECTED: ${jsonEncode(expected)}',
          );
        }
      });
    }
  });
}

Map<String, dynamic> _runCase(Map<String, dynamic> input) {
  final userProfile = _userProfile(input);
  final clientProfile = _clientProfile(input);
  final targetVolumeByMuscle = _intMap(input['targetVolumeByMuscle']);
  final mesocyclePoolByMuscle = _stringListMap(
    input['mesocycleExercisePoolByMuscle'],
  );

  try {
    final result = CycleTemplateBuilder.buildBaseWeek(
      userProfile: userProfile,
      clientProfile: clientProfile,
      targetVolumeByMuscle: targetVolumeByMuscle,
      mesocycleExercisePoolByMuscle: mesocyclePoolByMuscle,
      dayMusclePriorityOrder: _dayPriorityOrder(input),
      intensityProfilePercentSplit: _intensitySplit(input),
      weeklyIntensityTargetsByMuscle: _weeklyIntensityTargets(input),
      availableDays: (input['availableDays'] as num).toInt(),
      split: _splitFrom(input['split'] as String?),
      backFocus: input['backFocus'] as String?,
    );

    if (!result.success) {
      return <String, dynamic>{
        'outcome': 'failure',
        'error': result.error,
        'normalizedTargetVolumeByMuscle': _computeNormalizedTargetVolume(
          targetVolumeByMuscle,
        ),
        'normalizedPoolKeysByMuscle': _normalizedPoolKeys(
          mesocyclePoolByMuscle,
        ),
        'warnings': ExerciseCatalogV3.getCatalogWarnings(),
      };
    }

    final sessions = result.sessions ?? const <TrainingSession>[];
    return <String, dynamic>{
      'outcome': 'success',
      'weekId': null,
      'weekName': null,
      'normalizedTargetVolumeByMuscle': _computeNormalizedTargetVolume(
        targetVolumeByMuscle,
      ),
      'daysCount': sessions.length,
      'sessionsCount': sessions.length,
      'totalExercises': sessions.fold<int>(
        0,
        (sum, session) => sum + session.exercises.length,
      ),
      'warnings': ExerciseCatalogV3.getCatalogWarnings(),
      'sessions': sessions.map(_snapshotSession).toList(),
    };
  } catch (error) {
    return <String, dynamic>{
      'outcome': 'failure',
      'error': error.toString(),
      'normalizedTargetVolumeByMuscle': _computeNormalizedTargetVolume(
        targetVolumeByMuscle,
      ),
      'normalizedPoolKeysByMuscle': _normalizedPoolKeys(mesocyclePoolByMuscle),
      'warnings': ExerciseCatalogV3.getCatalogWarnings(),
    };
  }
}

Map<String, dynamic> _snapshotSession(TrainingSession session) {
  return <String, dynamic>{
    'id': session.id,
    'dayNumber': session.dayNumber,
    'name': session.name,
    'primaryMuscles': session.primaryMuscles,
    'estimatedDurationMinutes': session.estimatedDurationMinutes,
    'totalSets': session.totalSets,
    'exerciseCount': session.exercises.length,
    'structureMetadata': session.structureMetadata,
    'exerciseIds': session.exercises
        .map((exercise) => exercise.exerciseId)
        .toList(),
    'muscleKeys': session.exercises
        .map((exercise) => exercise.muscleKey)
        .toList(),
    'primaryMusclesByExercise': session.exercises
        .map((exercise) => exercise.primaryMuscle)
        .toList(),
    'blockLabels': session.exercises
        .map((exercise) => exercise.blockLabel)
        .toList(),
    'slotLabels': session.exercises
        .map((exercise) => exercise.slotLabel)
        .toList(),
    'pairGroupIds': session.exercises
        .map((exercise) => exercise.pairGroupId)
        .toList(),
    'isMainLift': session.exercises
        .map((exercise) => exercise.isMainLift)
        .toList(),
    'setCounts': session.exercises
        .map((exercise) => exercise.sets.length)
        .toList(),
    'loadCategories': session.exercises
        .map(
          (exercise) => ExerciseCatalogV3.getLoadCategory(exercise.exerciseId),
        )
        .toList(),
    'movementPatterns': session.exercises
        .map(
          (exercise) =>
              ExerciseCatalogV3.getMovementPattern(exercise.exerciseId),
        )
        .toList(),
  };
}

Map<String, int> _intMap(dynamic raw) {
  final source = Map<String, dynamic>.from(raw as Map);
  return source.map((key, value) => MapEntry(key, (value as num).toInt()));
}

Map<String, List<String>> _stringListMap(dynamic raw) {
  final source = Map<String, dynamic>.from(raw as Map);
  return source.map(
    (key, value) => MapEntry(key, List<String>.from(value as List)),
  );
}

Map<int, List<String>>? _dayPriorityOrder(Map<String, dynamic> input) {
  final raw = input['dayMusclePriorityOrder'];
  if (raw is! Map) return null;
  return raw.map(
    (key, value) =>
        MapEntry(int.parse(key.toString()), List<String>.from(value as List)),
  );
}

Map<String, double> _intensitySplit(Map<String, dynamic> input) {
  final raw = input['intensityProfilePercentSplit'];
  if (raw is! Map) {
    return const <String, double>{'heavy': 20, 'medium': 60, 'light': 20};
  }
  return raw.map(
    (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
  );
}

Map<String, IntensityDistribution>? _weeklyIntensityTargets(
  Map<String, dynamic> input,
) {
  final raw = input['weeklyIntensityTargetsByMuscle'];
  if (raw is! Map) return null;
  return raw.map((key, value) {
    final values = Map<String, dynamic>.from(value as Map);
    return MapEntry(
      key.toString(),
      IntensityDistribution(
        heavySets: (values['heavySets'] as num?)?.toInt() ?? 0,
        mediumSets: (values['mediumSets'] as num?)?.toInt() ?? 0,
        lightSets: (values['lightSets'] as num?)?.toInt() ?? 0,
      ),
    );
  });
}

TrainingSplit _splitFrom(String? value) {
  return switch (value) {
    'fullBody' || 'full_body' => TrainingSplit.fullBody,
    'pushPullLegs' || 'push_pull_legs' => TrainingSplit.pushPullLegs,
    _ => TrainingSplit.upperLower,
  };
}

Map<String, dynamic> _loadFixture(String fileName) {
  final file = File(
    'test/fixtures/training_v3/cycle_template_builder/$fileName',
  );
  final decoded = jsonDecode(file.readAsStringSync());
  return Map<String, dynamic>.from(decoded as Map);
}

bool _matchesSubset(dynamic actual, dynamic expected) {
  if (expected is Map) {
    if (actual is! Map) return false;
    for (final entry in expected.entries) {
      if (!actual.containsKey(entry.key)) return false;
      if (!_matchesSubset(actual[entry.key], entry.value)) return false;
    }
    return true;
  }

  if (expected is List) {
    if (actual is! List || actual.length < expected.length) return false;
    for (var index = 0; index < expected.length; index++) {
      if (!_matchesSubset(actual[index], expected[index])) return false;
    }
    return true;
  }

  return actual == expected;
}

void _installHarnessCatalog() {
  final exercises = _buildHarnessExercises();
  // ignore: deprecated_member_use
  ExerciseCatalogV3.loadFromExercises(exercises);

  for (final exercise in exercises) {
    final metadata = ExerciseCatalogV3.getMetadataById(exercise.id);
    if (metadata == null) continue;
    metadata
      ..['category'] =
          exercise.loadCategory == 'light' &&
              exercise.movementPattern.contains('raise')
          ? 'isolation'
          : 'compound'
      ..['movementPattern'] = exercise.movementPattern
      ..['loadCategory'] = exercise.loadCategory
      ..['fatigueScore'] = exercise.fatigueScore
      ..['stimulusScore'] = exercise.stimulusScore
      ..['allowedIntensityZones'] = exercise.allowedIntensityZones
      ..['equivalenceGroup'] = exercise.equivalenceGroup
      ..['slotRoles'] = const <String>['A', 'B1', 'B2', 'C1', 'C2', 'D1', 'D2']
      ..['heavyRole'] = exercise.loadCategory == 'heavy'
          ? 'primary'
          : 'forbidden'
      ..['aEligibility'] = exercise.loadCategory == 'heavy'
          ? 'primary'
          : 'secondary'
      ..['secondaryHeavyEligibility'] = exercise.loadCategory != 'heavy'
      ..['exerciseOrderClass'] = exercise.loadCategory == 'heavy' ? 1 : 9
      ..['conflictPatterns'] = <String>[]
      ..['rotationGroup'] = exercise.equivalenceGroup
      ..['angleTag'] = exercise.movementPattern
      ..['variantTier'] = 1
      ..['canPromoteToHeavyNextBlock'] = exercise.loadCategory != 'heavy'
      ..['canDemoteToMediumNextBlock'] = true;
  }
}

List<Exercise> _buildHarnessExercises() {
  return <Exercise>[
    _exercise(
      id: 'pec_press_barbell',
      muscleKey: 'pectorals',
      name: 'Pec Press Barbell',
      movementPattern: 'horizontal_push',
      loadCategory: 'heavy',
      fatigueScore: 3,
      stimulusScore: 100,
      equivalenceGroup: 'pec_press',
    ),
    _exercise(
      id: 'pec_fly_dumbbell',
      muscleKey: 'pectorals',
      name: 'Pec Fly Dumbbell',
      movementPattern: 'horizontal_fly',
      loadCategory: 'medium',
      fatigueScore: 2,
      stimulusScore: 92,
      equivalenceGroup: 'pec_fly',
    ),
    _exercise(
      id: 'lat_pulldown_wide',
      muscleKey: 'lats',
      name: 'Lat Pulldown Wide',
      movementPattern: 'vertical_pull',
      loadCategory: 'heavy',
      fatigueScore: 3,
      stimulusScore: 98,
      equivalenceGroup: 'lat_pull',
    ),
    _exercise(
      id: 'lat_row_chest_supported',
      muscleKey: 'lats',
      name: 'Lat Row Chest Supported',
      movementPattern: 'horizontal_pull',
      loadCategory: 'medium',
      fatigueScore: 2,
      stimulusScore: 89,
      equivalenceGroup: 'lat_row',
    ),
    _exercise(
      id: 'quad_squat_barbell',
      muscleKey: 'quads',
      name: 'Quad Squat Barbell',
      movementPattern: 'squat',
      loadCategory: 'heavy',
      fatigueScore: 4,
      stimulusScore: 99,
      equivalenceGroup: 'quad_squat',
    ),
    _exercise(
      id: 'quad_extension_machine',
      muscleKey: 'quads',
      name: 'Quad Extension Machine',
      movementPattern: 'knee_extension',
      loadCategory: 'medium',
      fatigueScore: 2,
      stimulusScore: 88,
      equivalenceGroup: 'quad_extension',
    ),
    _exercise(
      id: 'glute_bridge_barbell',
      muscleKey: 'glutes',
      name: 'Glute Bridge Barbell',
      movementPattern: 'hip_thrust',
      loadCategory: 'heavy',
      fatigueScore: 3,
      stimulusScore: 97,
      equivalenceGroup: 'glute_thrust',
    ),
    _exercise(
      id: 'glute_hinge_cable',
      muscleKey: 'glutes',
      name: 'Glute Hinge Cable',
      movementPattern: 'hip_hinge',
      loadCategory: 'medium',
      fatigueScore: 2,
      stimulusScore: 87,
      equivalenceGroup: 'glute_hinge',
    ),
    _exercise(
      id: 'front_press_dumbbell',
      muscleKey: 'delts_front',
      name: 'Front Press Dumbbell',
      movementPattern: 'vertical_push',
      loadCategory: 'heavy',
      fatigueScore: 3,
      stimulusScore: 95,
      equivalenceGroup: 'front_press',
    ),
    _exercise(
      id: 'front_raise_cable',
      muscleKey: 'delts_front',
      name: 'Front Raise Cable',
      movementPattern: 'front_raise',
      loadCategory: 'medium',
      fatigueScore: 2,
      stimulusScore: 84,
      equivalenceGroup: 'front_raise',
    ),
    _exercise(
      id: 'rear_delt_raise_dumbbell',
      muscleKey: 'delts_rear',
      name: 'Rear Delt Raise Dumbbell',
      movementPattern: 'rear_raise',
      loadCategory: 'medium',
      fatigueScore: 2,
      stimulusScore: 83,
      equivalenceGroup: 'rear_delt_raise',
    ),
    _exercise(
      id: 'triceps_pushdown_cable',
      muscleKey: 'triceps',
      name: 'Triceps Pushdown Cable',
      movementPattern: 'pushdown',
      loadCategory: 'light',
      fatigueScore: 1,
      stimulusScore: 78,
      equivalenceGroup: 'triceps_pushdown',
    ),
    _exercise(
      id: 'biceps_curl_dumbbell',
      muscleKey: 'biceps',
      name: 'Biceps Curl Dumbbell',
      movementPattern: 'curl',
      loadCategory: 'light',
      fatigueScore: 1,
      stimulusScore: 76,
      equivalenceGroup: 'biceps_curl',
    ),
    _exercise(
      id: 'calf_raise_machine',
      muscleKey: 'calves',
      name: 'Calf Raise Machine',
      movementPattern: 'calf_raise',
      loadCategory: 'light',
      fatigueScore: 1,
      stimulusScore: 70,
      equivalenceGroup: 'calf_raise',
    ),
    _exercise(
      id: 'abs_crunch_mat',
      muscleKey: 'abs',
      name: 'Abs Crunch Mat',
      movementPattern: 'crunch',
      loadCategory: 'light',
      fatigueScore: 1,
      stimulusScore: 68,
      equivalenceGroup: 'abs_crunch',
    ),
    _exercise(
      id: 'unknown_muscle_raise',
      muscleKey: 'unknown_muscle',
      name: 'Unknown Muscle Raise',
      movementPattern: 'unknown_raise',
      loadCategory: 'light',
      fatigueScore: 2,
      stimulusScore: 50,
      equivalenceGroup: 'unknown_muscle_raise',
    ),
    _exercise(
      id: 'back_mid_upper_row',
      muscleKey: 'back_mid_upper',
      name: 'Back Mid Upper Row',
      movementPattern: 'unknown_row',
      loadCategory: 'medium',
      fatigueScore: 2,
      stimulusScore: 52,
      equivalenceGroup: 'back_mid_upper_row',
    ),
    _exercise(
      id: 'mysterychest_press',
      muscleKey: 'mysterychest',
      name: 'Mystery Chest Press',
      movementPattern: 'unknown_press',
      loadCategory: 'heavy',
      fatigueScore: 3,
      stimulusScore: 54,
      equivalenceGroup: 'mysterychest_press',
    ),
    _exercise(
      id: 'back_pulldown_raw',
      muscleKey: 'back',
      name: 'Back Pulldown Raw',
      movementPattern: 'raw_back_pull',
      loadCategory: 'heavy',
      fatigueScore: 3,
      stimulusScore: 55,
      equivalenceGroup: 'back_raw_pull',
    ),
    _exercise(
      id: 'shoulders_press_raw',
      muscleKey: 'shoulders',
      name: 'Shoulders Press Raw',
      movementPattern: 'raw_shoulder_press',
      loadCategory: 'heavy',
      fatigueScore: 3,
      stimulusScore: 56,
      equivalenceGroup: 'shoulders_raw_press',
    ),
    _exercise(
      id: 'arms_curl_raw',
      muscleKey: 'arms',
      name: 'Arms Curl Raw',
      movementPattern: 'raw_arms_curl',
      loadCategory: 'light',
      fatigueScore: 1,
      stimulusScore: 49,
      equivalenceGroup: 'arms_raw_curl',
    ),
    _exercise(
      id: 'legs_squat_raw',
      muscleKey: 'legs',
      name: 'Legs Squat Raw',
      movementPattern: 'raw_legs_squat',
      loadCategory: 'heavy',
      fatigueScore: 4,
      stimulusScore: 57,
      equivalenceGroup: 'legs_raw_squat',
    ),
  ];
}

Exercise _exercise({
  required String id,
  required String muscleKey,
  required String name,
  required String movementPattern,
  required String loadCategory,
  required int fatigueScore,
  required int stimulusScore,
  required String equivalenceGroup,
}) {
  return Exercise(
    id: id,
    externalId: id,
    name: name,
    muscleKey: muscleKey,
    equipment: 'barbell',
    difficulty: movementPattern,
    primaryMuscles: <String>[muscleKey],
    secondaryMuscles: const <String>[],
    tertiaryMuscles: const <String>[],
    movementPattern: movementPattern,
    loadCategory: loadCategory,
    fatigueScore: fatigueScore,
    stimulusScore: stimulusScore,
    allowedIntensityZones: const <String, bool>{
      'heavy': true,
      'medium': true,
      'light': true,
    },
    equivalenceGroup: equivalenceGroup,
  );
}

UserProfile _userProfile(Map<String, dynamic> input) {
  final priorities = input['musclePriorities'] is Map
      ? Map<String, dynamic>.from(
          input['musclePriorities'] as Map,
        ).map((key, value) => MapEntry(key, (value as num).toInt()))
      : const <String, int>{};

  return UserProfile(
    id: input['userId']?.toString() ?? 'cycle_template_builder_harness',
    name: input['userName']?.toString() ?? 'Cycle Template Harness',
    email: input['email']?.toString() ?? 'harness@test.local',
    age: (input['age'] as num?)?.toInt() ?? 30,
    gender: input['gender']?.toString() ?? 'male',
    heightCm: (input['heightCm'] as num?)?.toDouble() ?? 180.0,
    weightKg: (input['weightKg'] as num?)?.toDouble() ?? 80,
    yearsTraining: (input['yearsTraining'] as num?)?.toDouble() ?? 4,
    trainingLevel: input['trainingLevel']?.toString() ?? 'intermediate',
    consecutiveWeeks: (input['consecutiveWeeks'] as num?)?.toInt() ?? 4,
    availableDays: (input['availableDays'] as num).toInt(),
    sessionDuration: (input['sessionDuration'] as num?)?.toInt() ?? 90,
    primaryGoal: input['primaryGoal']?.toString() ?? 'hypertrophy',
    musclePriorities: priorities,
    availableEquipment: const <String>[],
    createdAt: DateTime(2026, 5, 29),
    updatedAt: DateTime(2026, 5, 29),
  );
}

ClientProfile _clientProfile(Map<String, dynamic> input) {
  return ClientProfile(
    age: (input['age'] as num?)?.toInt() ?? 30,
    experience: input['trainingLevel']?.toString() ?? 'intermediate',
    recoveryCapacity: (input['recoveryCapacity'] as num?)?.toDouble() ?? 7.0,
    caloricBalance: (input['caloricBalance'] as num?)?.toDouble() ?? 0.0,
    geneticResponse: (input['geneticResponse'] as num?)?.toDouble() ?? 1.0,
  );
}
