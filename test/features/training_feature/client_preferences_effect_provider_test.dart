import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/features/training_feature/domain/client_exercise_preferences_resolver.dart';
import 'package:hcs_app_lap/features/training_feature/domain/exercise_preferences_models.dart';

void main() {
  group('resolveClientExercisePreferences', () {
    test('null client devuelve vacio', () {
      final ExercisePreferencesByMuscle preferences =
          resolveClientExercisePreferences(null);

      expect(preferences.byMuscle, isEmpty);
      expect(preferences.hasMinimumData, isFalse);
    });

    test('cliente sin key devuelve vacio', () {
      final client = _clientFixture(trainingExtra: const <String, dynamic>{});

      final preferences = resolveClientExercisePreferences(client);

      expect(preferences.byMuscle, isEmpty);
      expect(preferences.hasMinimumData, isFalse);
    });

    test('payload mal formado no crashea y devuelve vacio', () {
      final client = _clientFixture(
        trainingExtra: const <String, dynamic>{
          TrainingExtraKeys.exercisePreferencesByMuscle: 'invalid-payload',
        },
      );

      final preferences = resolveClientExercisePreferences(client);

      expect(preferences.byMuscle, isEmpty);
      expect(preferences.hasMinimumData, isFalse);
    });

    test('payload valido devuelve preferencias reales', () {
      final client = _clientFixture(
        trainingExtra: const <String, dynamic>{
          TrainingExtraKeys.exercisePreferencesByMuscle: <String, dynamic>{
            'pectorals': <String, dynamic>{
              'frequent': <String>['bench_press'],
              'preferred': <String>['incline_press'],
              'avoid': <String>['cable_fly'],
            },
          },
        },
      );

      final preferences = resolveClientExercisePreferences(client);
      final bucket = preferences.byMuscle['pectorals'];

      expect(preferences.hasMinimumData, isTrue);
      expect(bucket, isNotNull);
      expect(bucket!.frequent, contains('bench_press'));
      expect(bucket.preferred, contains('incline_press'));
      expect(bucket.avoid, contains('cable_fly'));
    });

    test('canary mantiene el test aislado de infraestructura pesada', () {
      final source = _read(
        'test/features/training_feature/client_preferences_effect_'
        'provider_test.dart',
      );
      final banned = <String>[
        'Provider' 'Container',
        'client_preferences_effect_' 'provider.dart',
        'flutter_' 'riverpod',
        'clients' 'Provider',
        'Fire' 'base',
        'Fire' 'store',
        'Database' 'Helper',
        'Client' 'Repository',
      ];

      for (final token in banned) {
        expect(source, isNot(contains(token)));
      }
    });
  });
}

Client _clientFixture({required Map<String, dynamic> trainingExtra}) {
  return Client.fromJson(<String, dynamic>{
    'id': 'training-pref-client',
    'profile': const <String, dynamic>{
      'id': 'training-pref-profile',
      'fullName': 'Training Pref Client',
      'email': 'pref@example.com',
      'phone': '000',
      'country': 'Mexico',
      'occupation': 'Athlete',
      'objective': 'Hypertrophy',
    },
    'history': const <String, dynamic>{},
    'training': <String, dynamic>{'extra': trainingExtra},
    'nutrition': const <String, dynamic>{},
    'createdAt': DateTime.utc(2026).toIso8601String(),
    'updatedAt': DateTime.utc(2026).toIso8601String(),
  });
}

String _read(String path) => File(path).readAsStringSync();
