# Motor V3 - Complete Implementation Guide

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Core Components](#core-components)
3. [Weekly Progression Workflow](#weekly-progression-workflow)
4. [Integration Guide](#integration-guide)
5. [API Reference](#api-reference)
6. [Testing](#testing)
7. [Troubleshooting](#troubleshooting)

---

## Architecture Overview

Motor V3 is an adaptive training system that automatically adjusts training
volume based on weekly feedback and performance data.

### High-Level Architecture

```
UI LAYER
- Screens (WeeklyProgressionDemoScreen)
- Widgets (WeeklyFeedbackForm, MuscleProgressionCard)
- ViewModels (WeeklyProgressionViewModel)

PROVIDER LAYER
- Riverpod Providers (weeklyProgressionServiceProvider)
- State Management (ChangeNotifier)

SERVICE LAYER
- WeeklyProgressionService
- MotorV3Orchestrator

REPOSITORY LAYER
- MuscleProgressionRepository (Firebase)
- WeeklyMuscleAnalysisRepository (Firebase)

DATA LAYER
- Models (MuscleProgressionTracker, MuscleDecision)
- Freezed DTOs
```

---

## Core Components

### 1. MuscleProgressionTracker

Tracks progression state for a single muscle.

```dart
MuscleProgressionTracker(
  userId: 'user123',
  muscle: 'pectorals',
  currentVolume: 14,
  landmarks: VolumeLandmarks(vme: 8, vop: 12, mrv: 20),
  currentPhase: ProgressionPhase.discovering,
  weekInCurrentPhase: 2,
  priority: 5,
  vmrDiscovered: null,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);
```

Key fields:
- `currentVolume`: Current weekly sets for this muscle
- `landmarks`: MEV/VOP/MRV thresholds
- `currentPhase`: discovering/maintaining/overreaching/deloading/microdeload
- `vmrDiscovered`: Volume Maximum Recoverable (when found)
- `priority`: 5=primary, 3=secondary, 1=tertiary

### 2. MuscleDecision

Represents a weekly decision for volume adjustment.

```dart
MuscleDecision(
  muscle: 'pectorals',
  action: VolumeAction.increase,
  newVolume: 16,
  previousVolume: 14,
  newPhase: ProgressionPhase.discovering,
  reason: 'Good response, increasing by 2 sets',
  weekNumber: 3,
  timestamp: DateTime.now(),
);
```

Actions:
- `increase`: Add volume
- `maintain`: Keep same volume
- `decrease`: Reduce volume
- `deload`: Enter deload phase (40 percent volume)
- `microdeload`: Brief recovery (60 percent volume)
- `adjust`: Fine-tune volume

### 3. WeeklyProgressionService

Main service orchestrating the weekly workflow.

```dart
final service = WeeklyProgressionServiceImpl(
  progressionRepo: MuscleProgressionRepositoryImpl(),
  analysisRepo: WeeklyMuscleAnalysisRepositoryImpl(),
);

final decisions = await service.processWeeklyProgression(
  userId: 'user123',
  weekNumber: 3,
  weekStart: DateTime(2024, 1, 14),
  weekEnd: DateTime(2024, 1, 20),
  exerciseLogs: logs,
  userFeedbackByMuscle: feedback,
);
```

---

## Weekly Progression Workflow

### Step-by-Step Process

#### Week Start

1. User trains according to current tracker volumes
2. Logs all exercises with sets/reps/RIR
3. Tracks subjective feedback daily

#### Week End (Sunday)

1. User opens weekly feedback form
2. Fills feedback for each muscle:
   - Muscle activation (1-10)
   - Pump quality (1-10)
   - Fatigue level (1-10)
   - Recovery quality (1-10)
   - Pain (yes/no + severity)

3. Submits feedback
4. Motor V3 processes:

```
For each muscle:
  - Get current tracker
  - Analyze exercise logs
  - Analyze feedback
  - Determine decision (increase/maintain/deload)
  - Update tracker
  - Save analysis to Firebase
```

5. User receives decisions for all muscles
6. Next week starts with new volumes

### Decision Logic

```
IF discovering phase:
  IF high activation + low fatigue:
    - Increase volume by 2 sets
  IF 3+ weeks no progress:
    - VMR discovered, transition to maintaining

IF maintaining phase:
  IF stable performance:
    - Maintain volume
  IF high fatigue OR poor recovery:
    - Enter deload
  IF 6+ weeks since microdeload:
    - Enter microdeload

IF deloading:
  Duration: 1 week at 40 percent volume
  - Return to maintaining

IF microdeload:
  Duration: 1 week at 60 percent volume
  - Return to maintaining
```

---

## Integration Guide

### Step 1: Initialize Trackers

```dart
final repo = MuscleProgressionRepositoryImpl();

await repo.initializeAllTrackers(
  userId: 'user123',
  musclePriorities: {
    'pectorals': 5,
    'lats': 5,
    'quadriceps': 5,
    'hamstrings': 3,
  },
  trainingLevel: 'intermediate',
  age: 30,
);
```

### Step 2: Set Up Providers

```dart
final container = ProviderContainer();

final service = container.read(weeklyProgressionServiceProvider);
final viewModel = container.read(weeklyProgressionViewModelProvider);
```

### Step 3: Create UI

```dart
class MyWeeklyProgressionScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(weeklyProgressionViewModelProvider);

    return Scaffold(
      body: WeeklyFeedbackForm(
        muscle: 'pectorals',
        onFeedbackChanged: (feedback) {
          viewModel.updateMuscleFeedback('pectorals', feedback);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await viewModel.submitWeeklyProgression();
        },
        child: Icon(Icons.check),
      ),
    );
  }
}
```

### Step 4: Handle Decisions

```dart
final viewModel = ref.watch(weeklyProgressionViewModelProvider);

if (viewModel.decisions != null) {
  showDialog(
    context: context,
    builder: (context) => WeeklyDecisionSummary(
      decisions: viewModel.decisions!,
      weekNumber: viewModel.currentWeekNumber,
    ),
  );
}
```

---

## API Reference

See [docs/API_REFERENCE.md](API_REFERENCE.md) for the full API details.

---

## Testing

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/domain/training_v3/services/weekly_progression_service_test.dart

# Run with coverage
flutter test --coverage
```

---

## Troubleshooting

### Issue: Tracker not found

```dart
await repo.initializeAllTrackers(
  userId: userId,
  musclePriorities: {'pectorals': 5},
  trainingLevel: 'intermediate',
  age: 30,
);
```

### Issue: Decisions not generated

```dart
print('Logs: ${viewModel.totalLogsCount}');
print('Feedback: ${viewModel.musclesWithFeedbackCount}');
print('Week: ${viewModel.weekStart} - ${viewModel.weekEnd}');
```

### Issue: VMR not discovered

Reasons:
- Not enough weeks in discovering phase (need 3-4 weeks minimum)
- Feedback not indicating progress (activation/pump too low)
- Volume not increasing each week

Solution: Continue discovering phase with consistent feedback.
