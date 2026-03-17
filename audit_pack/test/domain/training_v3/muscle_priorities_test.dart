import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/training/models/muscle_priorities.dart';
import 'package:hcs_app_lap/domain/training_v3/resolvers/muscle_to_catalog_resolver.dart';

void main() {
  group('MusclePriorities', () {
    test('should initialize with default values (3)', () {
      final priorities = MusclePriorities();

      for (final muscle in MusclePriorities.canonicalMuscles) {
        expect(priorities.get(muscle), 3);
      }
    });

    test('should set and get priorities correctly', () {
      final priorities = MusclePriorities();

      priorities.set('chest', 5);
      priorities.set('biceps', 4);
      priorities.set('abs', 1);

      expect(priorities.get('chest'), 5);
      expect(priorities.get('biceps'), 4);
      expect(priorities.get('abs'), 1);
    });

    test('should throw on invalid muscle', () {
      final priorities = MusclePriorities();

      expect(() => priorities.set('invalid_muscle', 3), throwsArgumentError);
    });

    test('should throw on invalid priority value', () {
      final priorities = MusclePriorities();

      expect(() => priorities.set('chest', 0), throwsArgumentError);

      expect(() => priorities.set('chest', 6), throwsArgumentError);
    });

    test('should sort muscles by priority', () {
      final priorities = MusclePriorities();
      priorities.set('chest', 5);
      priorities.set('biceps', 4);
      priorities.set('abs', 2);

      final sorted = priorities.getSortedByPriority();

      expect(sorted.first, 'chest');
      expect(sorted.contains('biceps'), true);
    });

    test('should filter muscles by threshold', () {
      final priorities = MusclePriorities();
      priorities.set('chest', 5);
      priorities.set('biceps', 4);
      priorities.set('abs', 2);

      final highPriority = priorities.getMusclesWithPriority(4);

      expect(highPriority, contains('chest'));
      expect(highPriority, contains('biceps'));
      expect(highPriority, isNot(contains('abs')));
    });

    test('should serialize to/from JSON', () {
      final original = MusclePriorities();
      original.set('chest', 5);
      original.set('biceps', 4);

      final json = original.toJson();
      final restored = MusclePriorities.fromJson(json);

      expect(restored.get('chest'), 5);
      expect(restored.get('biceps'), 4);
    });

    test('should create from legacy lists', () {
      final priorities = MusclePriorities.fromLegacyLists(
        primaryString: 'chest,lats',
        secondaryString: 'biceps,triceps',
        tertiaryString: 'abs',
      );

      expect(priorities.get('chest'), 5);
      expect(priorities.get('lats'), 5);
      expect(priorities.get('biceps'), 3);
      expect(priorities.get('triceps'), 3);
      expect(priorities.get('abs'), 1);
    });
  });

  group('MuscleToCatalogResolver', () {
    test('should expand traps to 3 variants', () {
      final expanded = MuscleToCatalogResolver.expandMuscleKey('traps');

      expect(expanded, ['traps_upper', 'traps_middle', 'traps_lower']);
    });

    test('should expand calves to 2 variants', () {
      final expanded = MuscleToCatalogResolver.expandMuscleKey('calves');

      expect(expanded, ['gastrocnemio', 'soleo']);
    });

    test('should NOT expand biceps (exists as-is in JSON)', () {
      final expanded = MuscleToCatalogResolver.expandMuscleKey('biceps');

      expect(expanded, ['biceps']);
    });

    test('should NOT expand triceps (exists as-is in JSON)', () {
      final expanded = MuscleToCatalogResolver.expandMuscleKey('triceps');

      expect(expanded, ['triceps']);
    });

    test('should expand multiple muscles correctly', () {
      final expanded = MuscleToCatalogResolver.expandMuscleKeys([
        'chest',
        'traps',
        'biceps',
        'calves',
      ]);

      expect(expanded, contains('pectorals'));
      expect(expanded, contains('traps_upper'));
      expect(expanded, contains('traps_middle'));
      expect(expanded, contains('traps_lower'));
      expect(expanded, contains('biceps'));
      expect(expanded, contains('gastrocnemio'));
      expect(expanded, contains('soleo'));
    });
  });
}
