import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/domain/training_v3/data/exercise_catalog_v3.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/exercise_selection_engine.dart';

void main() {
  group('ExerciseSelectionEngine D1-C5 strict fixtures', () {
    setUpAll(() {
      // ignore: deprecated_member_use
      ExerciseCatalogV3.loadFromExercises(_allExercises);
    });

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
          final actual = _runFixtureCase(fixtureCase, expected);

          expect(actual, expected, reason: fixtureCase['id'] as String);
        }
      });
    }

    test('strict deterministic selection drops invalid requested muscles', () {
      for (final invalidMuscle in [
        'glute',
        'unknown_muscle',
        'back_mid_upper',
        'mysterychest',
      ]) {
        final selected = ExerciseSelectionEngine.selectDeterministicCandidates(
          pool: _allExercises,
          muscleKey: invalidMuscle,
          intensityZone: 'medium',
        );

        expect(selected, isEmpty, reason: invalidMuscle);
        expect(
          selected.map((exercise) => exercise.id),
          isNot(contains('raw_unknown_high')),
          reason: invalidMuscle,
        );
      }
    });

    test('strict deterministic selection preserves canonical and aliases', () {
      final canonical = ExerciseSelectionEngine.selectDeterministicCandidates(
        pool: _allExercises,
        muscleKey: 'pectorals',
        intensityZone: 'medium',
      ).map((exercise) => exercise.id).toList();
      final chestAlias = ExerciseSelectionEngine.selectDeterministicCandidates(
        pool: _allExercises,
        muscleKey: 'chest',
        intensityZone: 'medium',
      ).map((exercise) => exercise.id).toList();
      final gluteosAlias =
          ExerciseSelectionEngine.selectDeterministicCandidates(
            pool: _allExercises,
            muscleKey: 'gluteos',
            intensityZone: 'medium',
          ).map((exercise) => exercise.id).toList();

      expect(canonical, ['pec_high', 'pec_mid', 'pec_low']);
      expect(chestAlias, canonical);
      expect(gluteosAlias, ['glute_high']);
    });

    test('selectExercises still rejects glute without generic fallback', () {
      expect(
        () => ExerciseSelectionEngine.selectExercises(
          targetMuscle: 'glute',
          availableExercises: _availableExerciseDatabase(),
          availableEquipment: const <String>[],
          injuryHistory: const <String, String>{},
          targetExerciseCount: 2,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            contains('[ExerciseSelection][STRICT_NO_FALLBACK]'),
          ),
        ),
      );
    });

    test('getExerciseVariations normalizes aliases and drops unknown raws', () {
      final variations = ExerciseSelectionEngine.getExerciseVariations(
        'base_chest_alias',
        <String, Map<String, dynamic>>{
          'base_chest_alias': <String, dynamic>{
            'primary_muscles': <String>['chest'],
            'type': 'press',
          },
          'canonical_pectorals_candidate': <String, dynamic>{
            'primary_muscles': <String>['pectorals'],
            'type': 'press',
          },
          'raw_unknown_candidate': <String, dynamic>{
            'primary_muscles': <String>['unknown_muscle'],
            'type': 'press',
          },
          'wrong_type_candidate': <String, dynamic>{
            'primary_muscles': <String>['pectorals'],
            'type': 'fly',
          },
        },
      );

      final unknownBaseVariations =
          ExerciseSelectionEngine.getExerciseVariations(
            'raw_unknown_base',
            <String, Map<String, dynamic>>{
              'raw_unknown_base': <String, dynamic>{
                'primary_muscles': <String>['unknown_muscle'],
                'type': 'press',
              },
              'raw_unknown_candidate': <String, dynamic>{
                'primary_muscles': <String>['unknown_muscle'],
                'type': 'press',
              },
            },
          );

      expect(variations, ['canonical_pectorals_candidate']);
      expect(unknownBaseVariations, isEmpty);
    });
  });
}

const _fixtureNames = <String>[
  'exercise_selection_canonical.json',
  'exercise_selection_alias.json',
  'exercise_selection_unknown.json',
  'exercise_selection_mixed.json',
  'exercise_selection_equipment_constraints.json',
  'exercise_selection_priority_cases.json',
  'exercise_selection_catalog_edge_cases.json',
];

Map<String, dynamic> _runFixtureCase(
  Map<String, dynamic> fixtureCase,
  Map<String, dynamic> expected,
) {
  final input = Map<String, dynamic>.from(fixtureCase['input'] as Map);

  try {
    return switch (fixtureCase['api'] as String) {
      'selectExercises' => _runSelectExercises(input),
      'selectDeterministicCandidates' => _runSelectDeterministicCandidates(
        input,
      ),
      'selectExercisesForMuscle' => _runSelectExercisesForMuscle(input),
      final api => throw UnsupportedError('Unsupported fixture api: $api'),
    };
  } catch (error) {
    final errorContains = expected['errorContains'] as String?;
    if (errorContains == null) rethrow;
    expect(error.toString(), contains(errorContains));
    return <String, dynamic>{
      'outcome': 'throws',
      'errorContains': errorContains,
    };
  }
}

Map<String, dynamic> _runSelectExercises(Map<String, dynamic> input) {
  final selected = ExerciseSelectionEngine.selectExercises(
    targetMuscle: input['targetMuscle'] as String,
    availableExercises: _availableExerciseDatabase(),
    availableEquipment: _stringList(input['availableEquipment']),
    injuryHistory: _stringMap(input['injuryHistory']),
    targetExerciseCount: (input['targetExerciseCount'] as num).toInt(),
    intensityZone: input['intensityZone'] as String?,
    preferredMovementPattern: input['preferredMovementPattern'] as String?,
    recentExerciseIds: _stringSet(input['recentExerciseIds']),
    restrictedExerciseIds: _stringSet(input['restrictedExerciseIds']),
  );

  return <String, dynamic>{'outcome': 'success', 'selectedIds': selected};
}

Map<String, dynamic> _runSelectDeterministicCandidates(
  Map<String, dynamic> input,
) {
  final selected = ExerciseSelectionEngine.selectDeterministicCandidates(
    pool: _poolForVariant(input['poolVariant'] as String?),
    muscleKey: input['muscleKey'] as String,
    intensityZone: input['intensityZone'] as String,
    availableEquipment: _stringList(input['availableEquipment']),
    restrictedExerciseIds: _stringSet(input['restrictedExerciseIds']),
    recentExerciseIds: _stringSet(input['recentExerciseIds']),
    preferredMovementPattern: input['preferredMovementPattern'] as String?,
    allowedMovementPatterns: _stringSet(input['allowedMovementPatterns']),
  );

  return <String, dynamic>{
    'outcome': 'success',
    'selectedIds': selected.map((exercise) => exercise.id).toList(),
  };
}

Map<String, dynamic> _runSelectExercisesForMuscle(Map<String, dynamic> input) {
  final poolIds = _stringSet(input['poolIds']);
  final selected = ExerciseSelectionEngine.selectExercisesForMuscle(
    pool: _allExercises
        .where((exercise) => poolIds.contains(exercise.id))
        .toList(),
    targetSets: (input['targetSets'] as num).toInt(),
  );

  return <String, dynamic>{
    'outcome': 'success',
    'selected': selected
        .map(
          (result) => <String, dynamic>{
            'id': result.exercise.id,
            'sets': result.sets,
            'notes': result.notes,
          },
        )
        .toList(),
  };
}

List<Exercise> _poolForVariant(String? variant) {
  return switch (variant) {
    'canonical_only' => _canonicalExercises,
    'with_raw_unknown' => _allExercises,
    null || '' => _canonicalExercises,
    final value => throw UnsupportedError('Unsupported poolVariant: $value'),
  };
}

Map<String, Map<String, dynamic>> _availableExerciseDatabase() {
  return <String, Map<String, dynamic>>{
    for (final exercise in _canonicalExercises)
      exercise.id: <String, dynamic>{
        'id': exercise.id,
        'name': exercise.name,
        'primaryMuscles': exercise.primaryMuscles,
        'equipment': exercise.equipment.isEmpty
            ? const <String>[]
            : <String>[exercise.equipment],
        'movementPattern': exercise.movementPattern,
        'fatigueScore': exercise.fatigueScore,
        'stimulusScore': exercise.stimulusScore,
        'stressedJoints': const <String>[],
      },
  };
}

final _canonicalExercises = <Exercise>[
  _exercise(
    id: 'pec_high',
    name: 'Barbell bench press',
    primaryMuscles: const ['pectorals'],
    equipment: 'barbell',
    movementPattern: 'horizontal_push',
    fatigueScore: 3,
    stimulusScore: 95,
  ),
  _exercise(
    id: 'pec_mid',
    name: 'Dumbbell press',
    primaryMuscles: const ['pectorals'],
    equipment: 'dumbbell',
    movementPattern: 'horizontal_push',
    fatigueScore: 2,
    stimulusScore: 88,
  ),
  _exercise(
    id: 'pec_low',
    name: 'Machine chest press',
    primaryMuscles: const ['pectorals'],
    equipment: 'machine',
    movementPattern: 'horizontal_push',
    fatigueScore: 1,
    stimulusScore: 70,
  ),
  _exercise(
    id: 'lat_high',
    name: 'Cable pulldown',
    primaryMuscles: const ['lats'],
    equipment: 'cable',
    movementPattern: 'vertical_pull',
    fatigueScore: 2,
    stimulusScore: 92,
  ),
  _exercise(
    id: 'lat_mid',
    name: 'Machine row',
    primaryMuscles: const ['lats'],
    equipment: 'machine',
    movementPattern: 'horizontal_pull',
    fatigueScore: 2,
    stimulusScore: 86,
  ),
  _exercise(
    id: 'quad_high',
    name: 'Back squat',
    primaryMuscles: const ['quads'],
    equipment: 'barbell',
    movementPattern: 'squat',
    fatigueScore: 4,
    stimulusScore: 94,
  ),
  _exercise(
    id: 'quad_mid',
    name: 'Leg extension',
    primaryMuscles: const ['quads'],
    equipment: 'machine',
    movementPattern: 'knee_extension',
    fatigueScore: 2,
    stimulusScore: 82,
  ),
  _exercise(
    id: 'glute_high',
    name: 'Hip thrust',
    primaryMuscles: const ['glutes'],
    equipment: 'barbell',
    movementPattern: 'hip_extension',
    fatigueScore: 3,
    stimulusScore: 91,
  ),
  _exercise(
    id: 'delt_front_high',
    name: 'Dumbbell shoulder press',
    primaryMuscles: const ['delts_front'],
    equipment: 'dumbbell',
    movementPattern: 'vertical_push',
    fatigueScore: 2,
    stimulusScore: 84,
  ),
  _exercise(
    id: 'abs_high',
    name: 'Cable crunch',
    primaryMuscles: const ['abs'],
    equipment: 'cable',
    movementPattern: 'trunk_flexion',
    fatigueScore: 1,
    stimulusScore: 75,
  ),
  _exercise(
    id: 'calves_only',
    name: 'Standing calf raise',
    primaryMuscles: const ['calves'],
    equipment: 'machine',
    movementPattern: 'ankle_extension',
    fatigueScore: 1,
    stimulusScore: 72,
  ),
];

final _rawUnknownExercises = <Exercise>[
  _exercise(
    id: 'raw_unknown_high',
    name: 'Raw unknown seed',
    primaryMuscles: const ['unknown_muscle'],
    equipment: 'machine',
    movementPattern: 'unknown',
    fatigueScore: 1,
    stimulusScore: 77,
  ),
  _exercise(
    id: 'raw_back_mid_upper_high',
    name: 'Raw back mid upper seed',
    primaryMuscles: const ['back_mid_upper'],
    equipment: 'machine',
    movementPattern: 'unknown',
    fatigueScore: 1,
    stimulusScore: 76,
  ),
  _exercise(
    id: 'raw_mysterychest_high',
    name: 'Raw mystery chest seed',
    primaryMuscles: const ['mysterychest'],
    equipment: 'machine',
    movementPattern: 'unknown',
    fatigueScore: 1,
    stimulusScore: 75,
  ),
];

final _allExercises = <Exercise>[
  ..._canonicalExercises,
  ..._rawUnknownExercises,
];

Exercise _exercise({
  required String id,
  required String name,
  required List<String> primaryMuscles,
  required String equipment,
  required String movementPattern,
  required int fatigueScore,
  required int stimulusScore,
}) {
  return Exercise(
    id: id,
    externalId: id,
    name: name,
    muscleKey: primaryMuscles.first,
    equipment: equipment,
    difficulty: movementPattern,
    primaryMuscles: primaryMuscles,
    secondaryMuscles: const <String>[],
    tertiaryMuscles: const <String>[],
    stimulusContribution: {
      for (final muscle in primaryMuscles) muscle: stimulusScore.toDouble(),
    },
    movementPattern: movementPattern,
    loadCategory: 'moderate',
    fatigueScore: fatigueScore,
    stimulusScore: stimulusScore,
    allowedIntensityZones: const <String, bool>{
      'heavy': true,
      'medium': true,
      'light': true,
    },
    equivalenceGroup: 'eq:$id',
  );
}

Map<String, dynamic> _loadFixture(String fileName) {
  final file = File('test/fixtures/training_v3/exercise_selection/$fileName');
  final decoded = jsonDecode(file.readAsStringSync());
  return Map<String, dynamic>.from(decoded as Map);
}

List<String> _stringList(dynamic raw) {
  if (raw is! List) return const <String>[];
  return raw.map((value) => value.toString()).toList();
}

Set<String> _stringSet(dynamic raw) => _stringList(raw).toSet();

Map<String, String> _stringMap(dynamic raw) {
  if (raw is! Map) return const <String, String>{};
  return Map<String, dynamic>.from(
    raw,
  ).map((key, value) => MapEntry(key, value.toString()));
}
