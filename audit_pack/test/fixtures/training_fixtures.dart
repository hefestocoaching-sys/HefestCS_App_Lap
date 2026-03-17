import 'package:hcs_app_lap/core/enums/training_goal.dart';
import 'package:hcs_app_lap/core/enums/training_level.dart';
import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';

TrainingProfile validTrainingProfile({int daysPerWeek = 4}) {
  return TrainingProfile(
    id: 'client-valid',
    daysPerWeek: daysPerWeek,
    timePerSessionMinutes: 60,
    trainingLevel: TrainingLevel.intermediate,
    globalGoal: TrainingGoal.hypertrophy,
    equipment: const ['barbell', 'dumbbell', 'machine', 'cable', 'bodyweight'],
    avgSleepHours: 7.5,
    baseVolumePerMuscle: const {
      'chest': 12,
      'back': 14,
      'shoulders': 10,
      'quads': 10,
      'hamstrings': 8,
      'glutes': 10,
      'biceps': 6,
      'triceps': 6,
      'abs': 6,
    },
    priorityMusclesPrimary: const [
      'chest',
      'back',
      'shoulders',
      'quads',
      'hamstrings',
      'glutes',
    ],
  );
}

List<Exercise> canonicalExercises() {
  return <Exercise>[
    // Chest
    Exercise(
      id: 'bench_press',
      externalId: 'bench_press',
      name: 'Bench Press',
      muscleKey: 'chest',
      equipment: 'barbell',
    ),
    Exercise(
      id: 'incline_db_press',
      externalId: 'incline_db_press',
      name: 'Incline DB Press',
      muscleKey: 'chest',
      equipment: 'dumbbell',
    ),
    Exercise(
      id: 'machine_chest_press',
      externalId: 'machine_chest_press',
      name: 'Machine Chest Press',
      muscleKey: 'chest',
      equipment: 'machine',
    ),
    Exercise(
      id: 'cable_fly',
      externalId: 'cable_fly',
      name: 'Cable Fly',
      muscleKey: 'chest',
      equipment: 'cable',
    ),
    // Back
    Exercise(
      id: 'barbell_row',
      externalId: 'barbell_row',
      name: 'Barbell Row',
      muscleKey: 'back',
      equipment: 'barbell',
    ),
    Exercise(
      id: 'lat_pulldown',
      externalId: 'lat_pulldown',
      name: 'Lat Pulldown',
      muscleKey: 'back',
      equipment: 'machine',
    ),
    Exercise(
      id: 'seated_row',
      externalId: 'seated_row',
      name: 'Seated Row',
      muscleKey: 'back',
      equipment: 'machine',
    ),
    // Shoulders
    Exercise(
      id: 'ohp',
      externalId: 'ohp',
      name: 'Overhead Press',
      muscleKey: 'shoulders',
      equipment: 'barbell',
    ),
    Exercise(
      id: 'lateral_raise',
      externalId: 'lateral_raise',
      name: 'Lateral Raise',
      muscleKey: 'shoulders',
      equipment: 'dumbbell',
    ),
    // Quads
    Exercise(
      id: 'back_squat',
      externalId: 'back_squat',
      name: 'Back Squat',
      muscleKey: 'quads',
      equipment: 'barbell',
    ),
    Exercise(
      id: 'front_squat',
      externalId: 'front_squat',
      name: 'Front Squat',
      muscleKey: 'quads',
      equipment: 'barbell',
    ),
    Exercise(
      id: 'leg_press',
      externalId: 'leg_press',
      name: 'Leg Press',
      muscleKey: 'quads',
      equipment: 'machine',
    ),
    Exercise(
      id: 'leg_extension',
      externalId: 'leg_extension',
      name: 'Leg Extension',
      muscleKey: 'quads',
      equipment: 'machine',
    ),
    // Hamstrings
    Exercise(
      id: 'rdl',
      externalId: 'rdl',
      name: 'Romanian Deadlift',
      muscleKey: 'hamstrings',
      equipment: 'barbell',
    ),
    Exercise(
      id: 'leg_curl',
      externalId: 'leg_curl',
      name: 'Leg Curl',
      muscleKey: 'hamstrings',
      equipment: 'machine',
    ),
    // Glutes
    Exercise(
      id: 'hip_thrust',
      externalId: 'hip_thrust',
      name: 'Hip Thrust',
      muscleKey: 'glutes',
      equipment: 'barbell',
    ),
    Exercise(
      id: 'glute_bridge',
      externalId: 'glute_bridge',
      name: 'Glute Bridge',
      muscleKey: 'glutes',
      equipment: 'bodyweight',
    ),
    Exercise(
      id: 'cable_abduction',
      externalId: 'cable_abduction',
      name: 'Cable Abduction',
      muscleKey: 'glutes',
      equipment: 'cable',
    ),
    // Full body (para fallback de días sin músculos específicos)
    Exercise(
      id: 'full_body_circuit',
      externalId: 'full_body_circuit',
      name: 'Full Body Circuit',
      muscleKey: 'fullBody',
      equipment: 'bodyweight',
    ),
    Exercise(
      id: 'machine_circuit',
      externalId: 'machine_circuit',
      name: 'Machine Circuit',
      muscleKey: 'fullBody',
      equipment: 'machine',
    ),
    // Arms / Core
    Exercise(
      id: 'barbell_curl',
      externalId: 'barbell_curl',
      name: 'Barbell Curl',
      muscleKey: 'biceps',
      equipment: 'barbell',
    ),
    Exercise(
      id: 'triceps_pushdown',
      externalId: 'triceps_pushdown',
      name: 'Triceps Pushdown',
      muscleKey: 'triceps',
      equipment: 'cable',
    ),
    Exercise(
      id: 'crunches',
      externalId: 'crunches',
      name: 'Crunches',
      muscleKey: 'abs',
      equipment: 'bodyweight',
    ),
  ];
}
