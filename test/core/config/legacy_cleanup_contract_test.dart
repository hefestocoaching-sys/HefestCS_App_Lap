import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Legacy cleanup contract', () {
    test('clients provider no longer exposes the legacy wide merge path', () {
      final source = _read(
        'lib/features/main_shell/providers/clients_provider.dart',
      );

      expect(source, isNot(contains('FeatureFlags.useLegacyClientUpdate')));
      expect(source, isNot(contains('_updateActiveClientLegacy')));
    });

    test(
      'feature flags no longer keep the inert legacy client update flag',
      () {
        final source = _read('lib/core/config/feature_flags.dart');

        expect(source, isNot(contains('useLegacyClientUpdate')));
      },
    );

    test('lib no longer imports flutter_riverpod legacy entrypoints', () {
      final hits = _collectLibraryHits('flutter_riverpod/legacy.dart');
      final allowed = {
        'lib/features/nutrition_feature/providers/nutrition_blocked_provider.dart',
        'lib/features/training_feature/providers/muscle_progression_tracker_provider.dart',
        'lib/features/training_feature/providers/weekly_feedback_provider.dart',
        'lib/features/training_feature/providers/weekly_progression_provider.dart',
      };

      expect(hits.toSet(), allowed, reason: _describeHits(hits));
    });

    test('exercise catalog loader usage stays confined to known consumers', () {
      final hits = _collectLibraryHits('ExerciseCatalogLoader');
      final expected = {
        'lib/data/datasources/local/exercise_catalog_loader.dart',
        'lib/features/training_feature/providers/training_plan_provider.dart',
      };

      expect(hits.toSet(), expected, reason: _describeHits(hits));
    });

    test(
      'training plan provider keeps legacy training strings out of the path',
      () {
        final source = _read(
          'lib/features/training_feature/providers/training_plan_provider.dart',
        );

        expect(
          source,
          isNot(contains('No se pudo materializar TrainingPlan legacy')),
        );
        expect(
          source,
          isNot(contains('[TrainingPlanProvider] Generating plan for client')),
        );
      },
    );
  });
}

String _read(String path) => File(path).readAsStringSync();

List<String> _collectLibraryHits(String needle) {
  final hits = <String>[];
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final source = entity.readAsStringSync();
    if (!source.contains(needle)) continue;
    hits.add(_relativePath(entity.path));
  }
  hits.sort();
  return hits;
}

String _relativePath(String absolutePath) {
  final current = Directory.current.path.replaceAll('\\', '/');
  final normalized = absolutePath.replaceAll('\\', '/');
  if (normalized.startsWith('$current/')) {
    return normalized.substring(current.length + 1);
  }
  return normalized;
}

String _describeHits(List<String> hits) {
  if (hits.isEmpty) return 'No matches found.';
  return hits.map((hit) => '- $hit').join('\n');
}
