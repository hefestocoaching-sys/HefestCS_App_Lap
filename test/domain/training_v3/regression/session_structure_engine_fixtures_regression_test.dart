import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/domain/training_v3/data/exercise_catalog_v3.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/session_structure_engine.dart';

void main() {
  group('SessionStructureEngine D1-C6 strict fixtures', () {
    for (final fixtureName in _fixtureNames) {
      test(fixtureName, () {
        final fixture = _loadFixture(fixtureName);
        final cases = List<Map<String, dynamic>>.from(
          (fixture['cases'] as List).map(
            (raw) => Map<String, dynamic>.from(raw as Map),
          ),
        );

        for (final fixtureCase in cases) {
          final input = Map<String, dynamic>.from(fixtureCase['input'] as Map);
          final exercises = _exercisesFromInput(input);
          // ignore: deprecated_member_use
          ExerciseCatalogV3.loadFromExercises(exercises);

          final structure = SessionStructureEngine.build(exercises);
          final actual = _snapshot(structure);
          final expected = Map<String, dynamic>.from(
            fixtureCase['expected'] as Map,
          );

          expect(actual, expected, reason: fixtureCase['id'] as String);
        }
      });
    }

    test('valid aliases keep canonical pairing behavior', () {
      final structure = _buildFromInlineExercises([
        _inlineExercise(
          id: 'alias_pair_chest',
          primaryMuscles: const ['chest'],
          movementPattern: 'horizontal_push',
          loadCategory: 'heavy',
          stimulusScore: 100,
          fatigueScore: 3,
        ),
        _inlineExercise(
          id: 'alias_pair_lats',
          primaryMuscles: const ['lats'],
          movementPattern: 'vertical_pull',
          loadCategory: 'medium',
          stimulusScore: 94,
          fatigueScore: 2,
        ),
        _inlineExercise(
          id: 'alias_pair_quadriceps',
          primaryMuscles: const ['quadriceps'],
          movementPattern: 'squat',
          loadCategory: 'medium',
          stimulusScore: 90,
          fatigueScore: 2,
        ),
        _inlineExercise(
          id: 'alias_pair_gluteos',
          primaryMuscles: const ['gluteos'],
          movementPattern: 'hip_extension',
          loadCategory: 'light',
          stimulusScore: 84,
          fatigueScore: 2,
        ),
      ]);

      expect(structure.mainLift.id, 'alias_pair_chest');
      expect(
        structure.blocks
            .where((block) => block.blockLabel == 'B')
            .map((block) => block.first.id),
        contains('alias_pair_lats'),
      );
      expect(
        structure.blocks.any(
          (block) =>
              block.isBiserie &&
              block.first.id == 'alias_pair_quadriceps' &&
              block.second?.id == 'alias_pair_gluteos',
        ),
        isTrue,
      );
    });

    test('unknowns and raw glute stay unclassified for pairing', () {
      final structure = _buildFromInlineExercises([
        _inlineExercise(
          id: 'invalid_pair_pectorals',
          primaryMuscles: const ['pectorals'],
          movementPattern: 'horizontal_push',
          loadCategory: 'heavy',
          stimulusScore: 100,
          fatigueScore: 3,
        ),
        _inlineExercise(
          id: 'invalid_pair_quads',
          primaryMuscles: const ['quads'],
          movementPattern: 'squat',
          loadCategory: 'medium',
          stimulusScore: 90,
          fatigueScore: 2,
        ),
        _inlineExercise(
          id: 'invalid_pair_glute',
          primaryMuscles: const ['glute'],
          movementPattern: 'hip_extension',
          loadCategory: 'light',
          stimulusScore: 84,
          fatigueScore: 2,
        ),
        _inlineExercise(
          id: 'invalid_pair_unknown',
          primaryMuscles: const ['unknown_muscle'],
          movementPattern: 'unknown',
          loadCategory: 'light',
          stimulusScore: 82,
          fatigueScore: 2,
        ),
      ]);

      final invalidPlacements = structure.placements().where(
        (placement) =>
            placement.exerciseId == 'invalid_pair_glute' ||
            placement.exerciseId == 'invalid_pair_unknown',
      );

      expect(invalidPlacements, isNotEmpty);
      expect(
        invalidPlacements.every((placement) => placement.pairGroupId == null),
        isTrue,
      );
      expect(
        structure.blocks.any(
          (block) =>
              block.isBiserie &&
              (block.first.id == 'invalid_pair_glute' ||
                  block.second?.id == 'invalid_pair_glute' ||
                  block.first.id == 'invalid_pair_unknown' ||
                  block.second?.id == 'invalid_pair_unknown'),
        ),
        isFalse,
      );
    });

    test('all unknown exercises do not crash and stay unpaired', () {
      final structure = _buildFromInlineExercises([
        _inlineExercise(
          id: 'all_unknown_main',
          primaryMuscles: const ['unknown_muscle'],
          movementPattern: 'unknown_a',
          loadCategory: 'heavy',
          stimulusScore: 100,
          fatigueScore: 3,
        ),
        _inlineExercise(
          id: 'all_unknown_back',
          primaryMuscles: const ['back_mid_upper'],
          movementPattern: 'unknown_b',
          loadCategory: 'medium',
          stimulusScore: 90,
          fatigueScore: 2,
        ),
        _inlineExercise(
          id: 'all_unknown_mystery',
          primaryMuscles: const ['mysterychest'],
          movementPattern: 'unknown_c',
          loadCategory: 'light',
          stimulusScore: 80,
          fatigueScore: 2,
        ),
      ]);

      expect(structure.mainLift.id, 'all_unknown_main');
      expect(
        structure.blocks
            .expand((block) => block.exercises)
            .map((exercise) => exercise.id),
        containsAll(['all_unknown_back', 'all_unknown_mystery']),
      );
      expect(structure.blocks.every((block) => !block.isBiserie), isTrue);
      expect(
        structure
            .placements()
            .where((placement) => !placement.isMainLift)
            .every((placement) => placement.pairGroupId == null),
        isTrue,
      );
    });
  });
}

const _fixtureNames = <String>[
  'session_structure_canonical.json',
  'session_structure_alias.json',
  'session_structure_unknown.json',
  'session_structure_mixed.json',
  'session_structure_pairing_cases.json',
  'session_structure_intensity_cases.json',
  'session_structure_order_cases.json',
];

Map<String, dynamic> _snapshot(SessionStructure structure) {
  return <String, dynamic>{
    'mainLiftId': structure.mainLift.id,
    'flattenedIds': structure
        .flattenExercises()
        .map((exercise) => exercise.id)
        .toList(),
    'blocks': structure.blocks
        .map(
          (block) => <String, dynamic>{
            'blockLabel': block.blockLabel,
            'slotFirst': block.slotFirst,
            'firstId': block.first.id,
            'slotSecond': block.slotSecond,
            'secondId': block.second?.id,
            'pairGroupId': block.pairGroupId,
            'isBiserie': block.isBiserie,
          },
        )
        .toList(),
    'placements': structure
        .placements()
        .map(
          (placement) => <String, dynamic>{
            'exerciseId': placement.exerciseId,
            'blockLabel': placement.blockLabel,
            'slotLabel': placement.slotLabel,
            'pairGroupId': placement.pairGroupId,
            'isMainLift': placement.isMainLift,
          },
        )
        .toList(),
  };
}

List<Exercise> _exercisesFromInput(Map<String, dynamic> input) {
  final rawExercises = List<Map<String, dynamic>>.from(
    (input['exercises'] as List).map(
      (raw) => Map<String, dynamic>.from(raw as Map),
    ),
  );
  return rawExercises.map(_exerciseFromMap).toList();
}

SessionStructure _buildFromInlineExercises(List<Exercise> exercises) {
  // ignore: deprecated_member_use
  ExerciseCatalogV3.loadFromExercises(exercises);
  return SessionStructureEngine.build(exercises);
}

Exercise _inlineExercise({
  required String id,
  required List<String> primaryMuscles,
  required String movementPattern,
  required String loadCategory,
  required int stimulusScore,
  required int fatigueScore,
}) {
  return Exercise(
    id: id,
    externalId: id,
    name: id,
    muscleKey: primaryMuscles.isEmpty ? '' : primaryMuscles.first,
    equipment: 'machine',
    difficulty: movementPattern,
    primaryMuscles: primaryMuscles,
    secondaryMuscles: const <String>[],
    tertiaryMuscles: const <String>[],
    stimulusContribution: {
      for (final muscle in primaryMuscles) muscle: stimulusScore.toDouble(),
    },
    movementPattern: movementPattern,
    loadCategory: loadCategory,
    fatigueScore: fatigueScore,
    stimulusScore: stimulusScore,
    allowedIntensityZones: const <String, bool>{
      'heavy': true,
      'medium': true,
      'light': true,
    },
    equivalenceGroup: 'session-structure:$id',
  );
}

Exercise _exerciseFromMap(Map<String, dynamic> map) {
  final primaryMuscles = _stringList(map['primaryMuscles']);
  return Exercise(
    id: map['id'] as String,
    externalId: map['id'] as String,
    name: map['name'] as String,
    muscleKey: primaryMuscles.isEmpty ? '' : primaryMuscles.first,
    equipment: map['equipment'] as String? ?? 'machine',
    difficulty: map['movementPattern'] as String,
    primaryMuscles: primaryMuscles,
    secondaryMuscles: _stringList(map['secondaryMuscles']),
    tertiaryMuscles: const <String>[],
    stimulusContribution: {
      for (final muscle in primaryMuscles)
        muscle: (map['stimulusScore'] as num).toDouble(),
    },
    movementPattern: map['movementPattern'] as String,
    loadCategory: map['loadCategory'] as String,
    fatigueScore: (map['fatigueScore'] as num).toInt(),
    stimulusScore: (map['stimulusScore'] as num).toInt(),
    allowedIntensityZones: const <String, bool>{
      'heavy': true,
      'medium': true,
      'light': true,
    },
    equivalenceGroup: 'session-structure:${map['id']}',
  );
}

Map<String, dynamic> _loadFixture(String fileName) {
  final file = File('test/fixtures/training_v3/session_structure/$fileName');
  final decoded = jsonDecode(file.readAsStringSync());
  return Map<String, dynamic>.from(decoded as Map);
}

List<String> _stringList(dynamic raw) {
  if (raw is! List) return const <String>[];
  return raw
      .map((value) => value?.toString().trim() ?? '')
      .where((value) => value.isNotEmpty)
      .toList();
}
