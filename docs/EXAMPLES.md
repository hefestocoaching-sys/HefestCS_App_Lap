# Motor V3 - Practical Examples

## Table of Contents

1. [Quick Start](#quick-start)
2. [Basic Workflows](#basic-workflows)
3. [Advanced Scenarios](#advanced-scenarios)
4. [Custom Implementations](#custom-implementations)
5. [Real-World Use Cases](#real-world-use-cases)

---

## Quick Start

### 5-Minute Setup

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/domain/training_v3/repositories/muscle_progression_repository_impl.dart';
import 'package:hcs_app_lap/domain/training_v3/services/weekly_progression_service_impl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final progressionRepo = MuscleProgressionRepositoryImpl();
  final analysisRepo = WeeklyMuscleAnalysisRepositoryImpl();

  await progressionRepo.initializeAllTrackers(
    userId: 'demo_user',
    musclePriorities: {
      'pectorals': 5,
      'lats': 5,
      'quadriceps': 5,
    },
    trainingLevel: 'intermediate',
    age: 30,
  );

  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: WeeklyProgressionDemoScreen(),
    );
  }
}
```

---

## Basic Workflows

### Example 1: Complete Weekly Cycle

```dart
Future<void> completeWeeklyCycle() async {
  final service = WeeklyProgressionServiceImpl(
    progressionRepo: MuscleProgressionRepositoryImpl(),
    analysisRepo: WeeklyMuscleAnalysisRepositoryImpl(),
  );

  final weekStart = DateTime(2024, 1, 14);
  final weekEnd = DateTime(2024, 1, 20);

  final exerciseLogs = <ExerciseLog>[];

  exerciseLogs.add(ExerciseLog(
    id: 'log_1',
    userId: 'user123',
    exerciseId: 'bench_press',
    muscles: ['pectorals'],
    sets: 4,
    reps: 10,
    rir: 2,
    performedAt: DateTime(2024, 1, 16, 10, 30),
    weight: 80.0,
    notes: 'Felt strong',
  ));

  exerciseLogs.add(ExerciseLog(
    id: 'log_2',
    userId: 'user123',
    exerciseId: 'incline_press',
    muscles: ['pectorals'],
    sets: 3,
    reps: 12,
    rir: 3,
    performedAt: DateTime(2024, 1, 16, 11, 00),
    weight: 60.0,
  ));

  exerciseLogs.add(ExerciseLog(
    id: 'log_3',
    userId: 'user123',
    exerciseId: 'lat_pulldown',
    muscles: ['lats'],
    sets: 4,
    reps: 12,
    rir: 2,
    performedAt: DateTime(2024, 1, 17, 10, 30),
    weight: 70.0,
  ));

  exerciseLogs.add(ExerciseLog(
    id: 'log_4',
    userId: 'user123',
    exerciseId: 'squat',
    muscles: ['quadriceps'],
    sets: 5,
    reps: 8,
    rir: 1,
    performedAt: DateTime(2024, 1, 19, 10, 30),
    weight: 100.0,
    notes: 'Depth was good',
  ));

  final feedback = {
    'pectorals': {
      'muscle_activation': 8.5,
      'pump_quality': 8.0,
      'fatigue_level': 5.0,
      'recovery_quality': 8.0,
      'had_pain': false,
    },
    'lats': {
      'muscle_activation': 7.5,
      'pump_quality': 7.5,
      'fatigue_level': 5.5,
      'recovery_quality': 7.5,
      'had_pain': false,
    },
    'quadriceps': {
      'muscle_activation': 9.0,
      'pump_quality': 8.5,
      'fatigue_level': 6.0,
      'recovery_quality': 7.0,
      'had_pain': false,
    },
  };

  final decisions = await service.processWeeklyProgression(
    userId: 'user123',
    weekNumber: 1,
    weekStart: weekStart,
    weekEnd: weekEnd,
    exerciseLogs: exerciseLogs,
    userFeedbackByMuscle: feedback,
  );

  for (final entry in decisions.entries) {
    final muscle = entry.key;
    final decision = entry.value;

    print('$muscle:');
    print('  Action: ${decision.action}');
    print('  Volume: ${decision.previousVolume} -> ${decision.newVolume}');
    print('  Phase: ${decision.newPhase}');
    print('  Reason: ${decision.reason}');
    print('');
  }
}
```

### Example 2: Using ViewModels in UI

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WeeklyFeedbackScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<WeeklyFeedbackScreen> createState() =>
      _WeeklyFeedbackScreenState();
}

class _WeeklyFeedbackScreenState extends ConsumerState<WeeklyFeedbackScreen> {
  final _muscles = ['pectorals', 'lats', 'quadriceps'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeWeek();
    });
  }

  void _initializeWeek() {
    final viewModel = ref.read(weeklyProgressionViewModelProvider);
    viewModel.initializeWeek(
      weekNumber: 1,
      weekStart: DateTime.now().subtract(const Duration(days: 7)),
      weekEnd: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(weeklyProgressionViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Week ${viewModel.currentWeekNumber} Feedback'),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: LinearProgressIndicator(
              value: viewModel.musclesWithFeedbackCount / _muscles.length,
            ),
          ),
          for (final muscle in _muscles)
            WeeklyFeedbackForm(
              muscle: muscle,
              initialFeedback: viewModel.getMuscleFeedback(muscle),
              onFeedbackChanged: (feedback) {
                viewModel.updateMuscleFeedback(muscle, feedback);
              },
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: viewModel.canSubmit ? () => _submit() : null,
        label: const Text('Submit Week'),
        icon: viewModel.isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.check),
      ),
    );
  }

  Future<void> _submit() async {
    final viewModel = ref.read(weeklyProgressionViewModelProvider);
    final success = await viewModel.submitWeeklyProgression();

    if (success && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DecisionSummaryScreen(
            decisions: viewModel.decisions!,
            weekNumber: viewModel.currentWeekNumber,
          ),
        ),
      );
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.errorMessage ?? 'Failed to submit'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

---

## Advanced Scenarios

### Example 3: Discovering VMR Phase

```dart
Future<void> discoverVMR() async {
  final service = WeeklyProgressionServiceImpl(
    progressionRepo: MuscleProgressionRepositoryImpl(),
    analysisRepo: WeeklyMuscleAnalysisRepositoryImpl(),
  );

  final userId = 'user123';
  final muscle = 'pectorals';

  await service.progressionRepo.initializeAllTrackers(
    userId: userId,
    musclePriorities: {muscle: 5},
    trainingLevel: 'intermediate',
    age: 30,
  );

  for (int week = 1; week <= 8; week++) {
    var tracker = await service.progressionRepo.getTracker(
      userId: userId,
      muscle: muscle,
    );

    final logs = [
      ExerciseLog(
        id: 'week${week}_log1',
        userId: userId,
        exerciseId: 'bench_press',
        muscles: [muscle],
        sets: (tracker!.currentVolume * 0.6).round(),
        reps: 10,
        rir: 2,
        performedAt: DateTime.now(),
      ),
      ExerciseLog(
        id: 'week${week}_log2',
        userId: userId,
        exerciseId: 'incline_press',
        muscles: [muscle],
        sets: (tracker.currentVolume * 0.4).round(),
        reps: 12,
        rir: 2,
        performedAt: DateTime.now(),
      ),
    ];

    final feedback = {
      muscle: {
        'muscle_activation': 8.5 - (week * 0.2),
        'pump_quality': 8.0 - (week * 0.2),
        'fatigue_level': 4.0 + (week * 0.3),
        'recovery_quality': 8.0 - (week * 0.1),
        'had_pain': false,
      },
    };

    final decisions = await service.processWeeklyProgression(
      userId: userId,
      weekNumber: week,
      weekStart: DateTime.now().subtract(const Duration(days: 7)),
      weekEnd: DateTime.now(),
      exerciseLogs: logs,
      userFeedbackByMuscle: feedback,
    );

    final decision = decisions[muscle]!;

    if (decision.hasDiscoveredVMR) {
      print('VMR discovered: ${decision.vmrDiscovered} sets');
      break;
    }
  }
}
```

### Example 4: Handling Deload

```dart
Future<void> handleDeload() async {
  final service = WeeklyProgressionServiceImpl(
    progressionRepo: MuscleProgressionRepositoryImpl(),
    analysisRepo: WeeklyMuscleAnalysisRepositoryImpl(),
  );

  final userId = 'user123';
  final muscle = 'quadriceps';

  final tracker = MuscleProgressionTracker(
    userId: userId,
    muscle: muscle,
    currentVolume: 18,
    landmarks: VolumeLandmarks(vme: 12, vop: 16, mrv: 24),
    currentPhase: ProgressionPhase.maintaining,
    weekInCurrentPhase: 4,
    priority: 5,
    vmrDiscovered: 18,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  await service.progressionRepo.updateTracker(tracker);

  final logs = [
    ExerciseLog(
      id: 'log1',
      userId: userId,
      exerciseId: 'squat',
      muscles: [muscle],
      sets: 5,
      reps: 8,
      rir: 0,
      performedAt: DateTime.now(),
    ),
  ];

  final feedback = {
    muscle: {
      'muscle_activation': 6.0,
      'pump_quality': 5.0,
      'fatigue_level': 9.0,
      'recovery_quality': 4.0,
      'had_pain': false,
    },
  };

  final decisions = await service.processWeeklyProgression(
    userId: userId,
    weekNumber: 5,
    weekStart: DateTime.now().subtract(const Duration(days: 7)),
    weekEnd: DateTime.now(),
    exerciseLogs: logs,
    userFeedbackByMuscle: feedback,
  );

  final decision = decisions[muscle]!;

  print('Deload decision:');
  print('  Action: ${decision.action}');
  print('  New volume: ${decision.newVolume}');
  print('  New phase: ${decision.newPhase}');
}
```

---

## Custom Implementations

### Example 6: Custom Decision Logic

```dart
class CustomWeeklyProgressionService extends WeeklyProgressionServiceImpl {
  CustomWeeklyProgressionService({
    required super.progressionRepo,
    required super.analysisRepo,
  });

  @override
  Future<MuscleDecision> processMuscleProgression({
    required MuscleProgressionTracker tracker,
    required int weekNumber,
    required List<ExerciseLog> exerciseLogs,
    Map<String, dynamic>? userFeedback,
  }) async {
    final activation = userFeedback?['muscle_activation'] as double? ?? 7.0;
    final pump = userFeedback?['pump_quality'] as double? ?? 7.0;
    final fatigue = userFeedback?['fatigue_level'] as double? ?? 5.0;
    final recovery = userFeedback?['recovery_quality'] as double? ?? 7.0;
    final hadPain = userFeedback?['had_pain'] as bool? ?? false;

    if (tracker.currentPhase == ProgressionPhase.discovering) {
      if (activation >= 8.5 &&
          pump >= 8.0 &&
          fatigue <= 5.0 &&
          recovery >= 8.0 &&
          !hadPain) {
        return MuscleDecision(
          muscle: tracker.muscle,
          action: VolumeAction.increase,
          newVolume: tracker.currentVolume + 1,
          previousVolume: tracker.currentVolume,
          newPhase: ProgressionPhase.discovering,
          reason: 'Conservative increase - all indicators excellent',
          weekNumber: weekNumber,
          timestamp: DateTime.now(),
        );
      }
    }

    if (fatigue >= 7.0 || recovery <= 6.0) {
      return MuscleDecision(
        muscle: tracker.muscle,
        action: VolumeAction.deload,
        newVolume: (tracker.currentVolume * 0.5).round(),
        previousVolume: tracker.currentVolume,
        newPhase: ProgressionPhase.deloading,
        reason: 'Early deload - preventing overreaching',
        weekNumber: weekNumber,
        timestamp: DateTime.now(),
      );
    }

    return super.processMuscleProgression(
      tracker: tracker,
      weekNumber: weekNumber,
      exerciseLogs: exerciseLogs,
      userFeedback: userFeedback,
    );
  }
}
```

---

## Real-World Use Cases

### Example 7: Beginner 12-Week Program

```dart
Future<void> beginnerProgram() async {
  final service = WeeklyProgressionServiceImpl(
    progressionRepo: MuscleProgressionRepositoryImpl(),
    analysisRepo: WeeklyMuscleAnalysisRepositoryImpl(),
  );

  final userId = 'beginner_user';

  await service.progressionRepo.initializeAllTrackers(
    userId: userId,
    musclePriorities: {
      'pectorals': 5,
      'lats': 5,
      'quadriceps': 5,
      'hamstrings': 3,
      'deltoide_lateral': 3,
      'biceps': 1,
      'triceps': 1,
    },
    trainingLevel: 'beginner',
    age: 25,
  );

  for (int week = 1; week <= 12; week++) {
    final isDeloadWeek = week % 4 == 0;
    print(isDeloadWeek ? 'Deload week' : 'Training week');
  }
}
```

### Example 8: Advanced Athlete with Specialization

```dart
Future<void> advancedSpecialization() async {
  final service = WeeklyProgressionServiceImpl(
    progressionRepo: MuscleProgressionRepositoryImpl(),
    analysisRepo: WeeklyMuscleAnalysisRepositoryImpl(),
  );

  final userId = 'advanced_user';

  await service.progressionRepo.initializeAllTrackers(
    userId: userId,
    musclePriorities: {
      'lats': 5,
      'upper_back': 5,
      'quadriceps': 5,
      'hamstrings': 5,
      'glutes': 5,
      'pectorals': 3,
      'deltoide_lateral': 3,
      'deltoide_posterior': 3,
      'biceps': 1,
      'triceps': 1,
      'calves': 1,
    },
    trainingLevel: 'advanced',
    age: 28,
  );
}
```

### Example 9: Recovery from Injury

```dart
Future<void> injuryRecovery() async {
  final service = WeeklyProgressionServiceImpl(
    progressionRepo: MuscleProgressionRepositoryImpl(),
    analysisRepo: WeeklyMuscleAnalysisRepositoryImpl(),
  );

  final userId = 'recovery_user';
  final injuredMuscle = 'pectorals';

  await service.progressionRepo.initializeAllTrackers(
    userId: userId,
    musclePriorities: {
      'pectorals': 5,
      'lats': 5,
      'quadriceps': 5,
    },
    trainingLevel: 'intermediate',
    age: 32,
  );

  var tracker = await service.progressionRepo.getTracker(
    userId: userId,
    muscle: injuredMuscle,
  );

  final reducedTracker = tracker!.copyWith(
    currentVolume: (tracker.currentVolume * 0.5).round(),
  );

  await service.progressionRepo.updateTracker(reducedTracker);
}
```

---

## Tips and Best Practices

1. Always initialize before use
2. Log all exercises with accurate RIR
3. Provide complete feedback
4. Monitor fatigue and recovery weekly
5. Archive old data after 12 weeks
