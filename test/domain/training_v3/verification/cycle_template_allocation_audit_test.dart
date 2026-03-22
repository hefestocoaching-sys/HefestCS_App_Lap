// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/training_v3/data/exercise_catalog_v3.dart';
import 'package:hcs_app_lap/domain/training_v3/models/client_profile.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_split.dart';
import 'package:hcs_app_lap/domain/training_v3/models/user_profile.dart';
import 'package:hcs_app_lap/domain/training_v3/services/cycle_template_builder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('V3 allocation audit - target to assigned invariants', () {
    test('Caso 1: 3 dias full body novato', () async {
      await _runScenario(
        label: '3d_full_body_novato',
        availableDays: 3,
        split: TrainingSplit.fullBody,
        level: 'novice',
        desiredMuscles: 10,
      );
    });

    test('Caso 2: 4 dias upper/lower intermedio', () async {
      await _runScenario(
        label: '4d_upper_lower_intermedio',
        availableDays: 4,
        split: TrainingSplit.upperLower,
        level: 'intermediate',
        desiredMuscles: 10,
      );
    });

    test('Caso 3: 5 dias upper/lower + rotacion intermedio', () async {
      await _runScenario(
        label: '5d_upper_lower_rotacion_intermedio',
        availableDays: 5,
        split: TrainingSplit.upperLower,
        level: 'intermediate',
        desiredMuscles: 10,
      );
    });

    test('Caso 4: 6 dias alta frecuencia avanzado', () async {
      await _runScenario(
        label: '6d_alta_frecuencia_avanzado',
        availableDays: 6,
        split: TrainingSplit.pushPullLegs,
        level: 'advanced',
        desiredMuscles: 10,
      );
    });
  });
}

Future<void> _runScenario({
  required String label,
  required int availableDays,
  required TrainingSplit split,
  required String level,
  required int desiredMuscles,
}) async {
  await ExerciseCatalogV3.ensureLoaded();

  final target = _buildTargetVolume(desiredMuscles: desiredMuscles);
  expect(
    target.isNotEmpty,
    true,
    reason: 'No hay musculos con pool utilizable',
  );

  final pool = _buildPoolByMuscle(target.keys);
  final priorities = _buildPriorities(target.keys);

  final userProfile = UserProfile(
    id: 'audit_$label',
    name: 'Audit $label',
    email: '$label@test.local',
    age: 30,
    gender: 'male',
    heightCm: 175,
    weightKg: 80,
    yearsTraining: level == 'novice' ? 0.5 : (level == 'advanced' ? 8 : 3),
    trainingLevel: level,
    availableDays: availableDays,
    sessionDuration: 75,
    primaryGoal: 'hypertrophy',
    musclePriorities: priorities,
    availableEquipment: const ['barbell', 'dumbbell', 'cable', 'machine'],
    createdAt: DateTime(2026, 3, 19),
    updatedAt: DateTime(2026, 3, 19),
  );

  final clientProfile = ClientProfile(
    age: 30,
    experience: level,
    recoveryCapacity: 7,
    caloricBalance: 250,
    geneticResponse: 1.0,
  );

  final result = CycleTemplateBuilder.buildBaseWeek(
    userProfile: userProfile,
    clientProfile: clientProfile,
    targetVolumeByMuscle: target,
    mesocycleExercisePoolByMuscle: pool,
    availableDays: availableDays,
    split: split,
  );

  expect(
    result.success,
    true,
    reason: 'Fallo en buildBaseWeek: ${result.error}',
  );

  final assigned = <String, int>{};
  final sessions = result.sessions ?? const [];
  for (final session in sessions) {
    for (final exercise in session.exercises) {
      final muscle = CycleTemplateBuilder.normalizeMuscleKey(
        exercise.muscleKey,
      );
      assigned[muscle] = (assigned[muscle] ?? 0) + exercise.sets.length;
    }
  }

  print('');
  print('[$label] muscle | target | assigned | delta');
  final muscles = target.keys.toList()..sort();
  for (final muscle in muscles) {
    final targetSets = target[muscle] ?? 0;
    final assignedSets = assigned[muscle] ?? 0;
    final delta = assignedSets - targetSets;
    print('[$label] $muscle | $targetSets | $assignedSets | $delta');
    expect(delta, 0, reason: 'Delta distinto de cero para $muscle en $label');
  }
}

Map<String, int> _buildTargetVolume({required int desiredMuscles}) {
  final candidates = <String>[
    'pectorals',
    'lats',
    'upper_back',
    'delts_front',
    'delts_lateral',
    'delts_rear',
    'biceps',
    'triceps',
    'quads',
    'hamstrings',
    'glutes',
    'calves',
    'abs',
  ];

  const setPattern = <int>[3, 3, 2, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3];
  final out = <String, int>{};

  for (var i = 0; i < candidates.length; i++) {
    if (out.length >= desiredMuscles) break;
    final muscle = candidates[i];
    final pool = ExerciseCatalogV3.getByMuscle(muscle);
    if (pool.isEmpty) continue;
    out[muscle] = setPattern[i % setPattern.length];
  }

  return out;
}

Map<String, List<String>> _buildPoolByMuscle(Iterable<String> muscles) {
  final out = <String, List<String>>{};
  for (final muscle in muscles) {
    final exercises = ExerciseCatalogV3.getByMuscle(muscle);
    if (exercises.isEmpty) continue;
    out[muscle] = exercises.take(6).map((e) => e.id).toList();
  }
  return out;
}

Map<String, int> _buildPriorities(Iterable<String> muscles) {
  final out = <String, int>{};
  var priority = 5;
  for (final muscle in muscles) {
    out[muscle] = priority;
    if (priority > 1) {
      priority--;
    }
  }
  return out;
}
