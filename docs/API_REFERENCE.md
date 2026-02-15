# Motor V3 - API Reference

## Table of Contents

1. [Services](#services)
2. [Repositories](#repositories)
3. [Models](#models)
4. [Providers](#providers)
5. [ViewModels](#viewmodels)

---

## Services

### WeeklyProgressionService

Main service for weekly progression workflow.

#### Methods

##### `processWeeklyProgression()`

Signature:

```dart
Future<Map<String, MuscleDecision>> processWeeklyProgression({
  required String userId,
  required int weekNumber,
  required DateTime weekStart,
  required DateTime weekEnd,
  required List<ExerciseLog> exerciseLogs,
  required Map<String, Map<String, dynamic>> userFeedbackByMuscle,
})
```

Description:
Processes weekly feedback for all muscles and returns decisions.

Parameters:
- `userId` (String): User identifier
- `weekNumber` (int): Week number (1-52)
- `weekStart` (DateTime): Week start (Monday 00:00)
- `weekEnd` (DateTime): Week end (Sunday 23:59)
- `exerciseLogs` (List<ExerciseLog>): All exercise logs for the week
- `userFeedbackByMuscle` (Map): Feedback organized by muscle

Returns:
- Map of muscle name to MuscleDecision

Throws:
- ArgumentError if userId is empty
- StateError if week dates are invalid

Example:

```dart
final decisions = await service.processWeeklyProgression(
  userId: 'user123',
  weekNumber: 3,
  weekStart: DateTime(2024, 1, 14),
  weekEnd: DateTime(2024, 1, 20),
  exerciseLogs: logs,
  userFeedbackByMuscle: {
    'pectorals': {
      'muscle_activation': 8.5,
      'pump_quality': 8.0,
      'fatigue_level': 5.0,
      'recovery_quality': 8.0,
      'had_pain': false,
    },
  },
);
```

##### `processMuscleProgression()`

Signature:

```dart
Future<MuscleDecision> processMuscleProgression({
  required MuscleProgressionTracker tracker,
  required int weekNumber,
  required List<ExerciseLog> exerciseLogs,
  Map<String, dynamic>? userFeedback,
})
```

Description:
Processes progression for a single muscle.

Parameters:
- `tracker` (MuscleProgressionTracker): Current tracker state
- `weekNumber` (int): Week number
- `exerciseLogs` (List<ExerciseLog>): Logs for this muscle
- `userFeedback` (Map, optional): Feedback data

Returns:
- MuscleDecision with recommended action

Example:

```dart
final decision = await service.processMuscleProgression(
  tracker: tracker,
  weekNumber: 3,
  exerciseLogs: pectoralLogs,
  userFeedback: {
    'muscle_activation': 8.5,
    'pump_quality': 8.0,
    'fatigue_level': 5.0,
    'recovery_quality': 8.0,
  },
);
```

##### `getProgressionSummary()`

Signature:

```dart
Future<Map<String, dynamic>> getProgressionSummary({
  required String userId,
  int lastWeeks = 4,
})
```

Description:
Returns summary statistics for user's progression.

Parameters:
- `userId` (String): User identifier
- `lastWeeks` (int): Number of weeks to analyze (default 4)

Returns:

```dart
{
  'totalMuscles': int,
  'totalVolume': int,
  'musclesWithVMR': int,
  'musclesByPhase': {
    'discovering': int,
    'maintaining': int,
    'deloading': int,
  },
  'avgVolumePerMuscle': double,
}
```

---

## Repositories

### MuscleProgressionRepository

Manages persistence of muscle progression trackers.

#### Methods

##### `initializeAllTrackers()`

Signature:

```dart
Future<void> initializeAllTrackers({
  required String userId,
  required Map<String, int> musclePriorities,
  required String trainingLevel,
  required int age,
})
```

Description:
Creates initial trackers for all specified muscles.

Parameters:
- `userId` (String): User identifier
- `musclePriorities` (Map<String, int>): Muscle to priority mapping (5/3/1)
- `trainingLevel` (String): beginner, intermediate, or advanced
- `age` (int): User age for recovery calculations

Example:

```dart
await repo.initializeAllTrackers(
  userId: 'user123',
  musclePriorities: {
    'pectorals': 5,
    'lats': 5,
    'quadriceps': 5,
    'hamstrings': 3,
    'biceps': 3,
  },
  trainingLevel: 'intermediate',
  age: 30,
);
```

##### `getTracker()`

Signature:

```dart
Future<MuscleProgressionTracker?> getTracker({
  required String userId,
  required String muscle,
})
```

Description:
Retrieves a single muscle tracker.

Returns:
- MuscleProgressionTracker or null if not found

Example:

```dart
final tracker = await repo.getTracker(
  userId: 'user123',
  muscle: 'pectorals',
);

if (tracker != null) {
  print('Current volume: ${tracker.currentVolume}');
}
```

##### `getAllTrackers()`

Signature:

```dart
Future<Map<String, MuscleProgressionTracker>> getAllTrackers({
  required String userId,
})
```

Description:
Retrieves all trackers for a user.

Returns:
- Map of muscle name to tracker

Example:

```dart
final trackers = await repo.getAllTrackers(userId: 'user123');

for (final entry in trackers.entries) {
  print('${entry.key}: ${entry.value.currentVolume} sets');
}
```

##### `updateTracker()`

Signature:

```dart
Future<void> updateTracker(MuscleProgressionTracker tracker)
```

Description:
Updates a tracker's state in Firebase.

Example:

```dart
final updated = tracker.copyWith(
  currentVolume: 16,
  weekInCurrentPhase: tracker.weekInCurrentPhase + 1,
);

await repo.updateTracker(updated);
```

##### `deleteAllTrackers()`

Signature:

```dart
Future<void> deleteAllTrackers({required String userId})
```

Description:
Deletes all trackers for a user (for cleanup/reset).

Example:

```dart
await repo.deleteAllTrackers(userId: 'user123');
```

### WeeklyMuscleAnalysisRepository

Manages weekly analysis records.

#### Methods

##### `saveAnalysis()`

Signature:

```dart
Future<void> saveAnalysis(WeeklyMuscleAnalysis analysis)
```

Description:
Saves weekly analysis to Firebase.

Example:

```dart
final analysis = WeeklyMuscleAnalysis(
  userId: 'user123',
  muscle: 'pectorals',
  weekNumber: 3,
  weekStart: DateTime(2024, 1, 14),
  weekEnd: DateTime(2024, 1, 20),
  actualVolume: 14,
  plannedVolume: 12,
  muscleActivation: 8.5,
  pumpQuality: 8.0,
  fatigueLevel: 5.0,
  recoveryQuality: 8.0,
  hadPain: false,
  createdAt: DateTime.now(),
);

await repo.saveAnalysis(analysis);
```

##### `getAnalysis()`

Signature:

```dart
Future<WeeklyMuscleAnalysis?> getAnalysis({
  required String userId,
  required String muscle,
  required int weekNumber,
})
```

Description:
Retrieves analysis for a specific week.

Returns:
- WeeklyMuscleAnalysis or null if not found

##### `getHistory()`

Signature:

```dart
Future<List<WeeklyMuscleAnalysis>> getHistory({
  required String userId,
  required String muscle,
  int lastWeeks = 12,
})
```

Description:
Retrieves analysis history for a muscle.

Returns:
- List of analyses, ordered by week number ascending

Example:

```dart
final history = await repo.getHistory(
  userId: 'user123',
  muscle: 'pectorals',
  lastWeeks: 8,
);

for (final week in history) {
  print('Week ${week.weekNumber}: ${week.actualVolume} sets');
}
```

##### `archiveOldData()`

Signature:

```dart
Future<int> archiveOldData({
  required String userId,
  int olderThanWeeks = 12,
})
```

Description:
Archives data older than specified weeks.

Returns:
- Number of records archived

Example:

```dart
final archived = await repo.archiveOldData(
  userId: 'user123',
  olderThanWeeks: 12,
);

print('Archived $archived records');
```

---

## Models

### MuscleProgressionTracker

Represents the progression state for a single muscle.

Properties:
- `userId` (String): User identifier
- `muscle` (String): Muscle name (normalized)
- `currentVolume` (int): Current weekly sets
- `landmarks` (VolumeLandmarks): MEV/VOP/MRV thresholds
- `currentPhase` (ProgressionPhase): Current training phase
- `weekInCurrentPhase` (int): Weeks in current phase (0-indexed)
- `priority` (int): Priority level (5/3/1)
- `vmrDiscovered` (int?): VMR value if discovered
- `weeksSinceMicrodeload` (int?): Weeks since last microdeload
- `phaseHistory` (List<PhaseTransition>): History of phase transitions
- `createdAt` (DateTime): Creation timestamp
- `updatedAt` (DateTime): Last update timestamp

Methods:
- `copyWith()`
- `toJson()` / `fromJson()`

Computed:

```dart
bool get hasDiscoveredVMR => vmrDiscovered != null;
```

### MuscleDecision

Represents a weekly volume decision.

Properties:
- `muscle` (String): Muscle name
- `action` (VolumeAction): Decision action
- `newVolume` (int): New weekly sets
- `previousVolume` (int): Previous weekly sets
- `newPhase` (ProgressionPhase): New phase
- `reason` (String): Decision reasoning
- `weekNumber` (int): Week number
- `timestamp` (DateTime): Decision timestamp
- `vmrDiscovered` (int?): VMR if discovered
- `requiresMicrodeload` (bool): Microdeload needed
- `weeksToMicrodeload` (int?): Weeks until microdeload

Computed:

```dart
int get volumeChange => newVolume - previousVolume;
bool get isIncrease => volumeChange > 0;
bool get isDecrease => volumeChange < 0;
bool get hasDiscoveredVMR => vmrDiscovered != null;
```

### ExerciseLog

Represents a single exercise performance log.

Properties:
- `id` (String): Unique identifier
- `userId` (String): User identifier
- `exerciseId` (String): Exercise identifier
- `muscles` (List<String>): Target muscles
- `sets` (int): Number of sets
- `reps` (int): Reps per set
- `rir` (int): Reps in reserve (0-10)
- `performedAt` (DateTime): Performance timestamp
- `weight` (double?): Weight used (optional)
- `notes` (String?): Additional notes (optional)

Methods:
- `toJson()` / `fromJson()`
- `copyWith()`

### WeeklyMuscleAnalysis

Stores weekly analysis data.

Properties:
- `userId` (String): User identifier
- `muscle` (String): Muscle name
- `weekNumber` (int): Week number (1-52)
- `weekStart` (DateTime): Week start date
- `weekEnd` (DateTime): Week end date
- `actualVolume` (int): Actual sets performed
- `plannedVolume` (int?): Planned sets
- `muscleActivation` (double?): Activation rating (1-10)
- `pumpQuality` (double?): Pump rating (1-10)
- `fatigueLevel` (double?): Fatigue rating (1-10)
- `recoveryQuality` (double?): Recovery rating (1-10)
- `hadPain` (bool): Pain indicator
- `painSeverity` (double?): Pain severity (1-10)
- `painDescription` (String?): Pain description
- `createdAt` (DateTime): Creation timestamp

---

## Enums

### ProgressionPhase

```dart
enum ProgressionPhase {
  discovering,
  maintaining,
  overreaching,
  deloading,
  microdeload,
}
```

### VolumeAction

```dart
enum VolumeAction {
  increase,
  maintain,
  decrease,
  deload,
  microdeload,
  adjust,
}
```

---

## Providers

- `weeklyProgressionServiceProvider`: Provider<WeeklyProgressionService>
- `muscleProgressionRepositoryProvider`: Provider<MuscleProgressionRepository>
- `weeklyProgressionViewModelProvider`: ChangeNotifierProvider.autoDispose
- `muscleProgressionDashboardViewModelProvider`: ChangeNotifierProvider.autoDispose

---

## ViewModels

### WeeklyProgressionViewModel

Properties:
- `userId` (String)
- `currentWeekNumber` (int)
- `weekStart` (DateTime?)
- `weekEnd` (DateTime?)
- `exerciseLogs` (List<ExerciseLog>)
- `feedbackByMuscle` (Map)
- `decisions` (Map<String, MuscleDecision>?)
- `isLoading` (bool)
- `errorMessage` (String?)
- `isSubmitted` (bool)

Methods:
- `initializeWeek()`
- `addExerciseLog()`
- `updateMuscleFeedback()`
- `submitWeeklyProgression()`
- `resetForNextWeek()`

### MuscleProgressionDashboardViewModel

Properties:
- `userId` (String)
- `allTrackers` (Map<String, MuscleProgressionTracker>?)
- `summary` (Map<String, dynamic>?)
- `isLoading` (bool)
- `errorMessage` (String?)
- `filterPhase` (ProgressionPhase?)
- `filterPriority` (int?)

Methods:
- `loadData()`
- `refresh()`
- `setPhaseFilter()`
- `setPriorityFilter()`
- `getFilteredTrackers()`

Computed:
- `totalMuscles`
- `musclesDiscovering`
- `musclesMaintaining`
- `musclesDeloading`
- `totalWeeklyVolume`
- `averageVolumePerMuscle`
- `musclesWithVMR`

---

## Error Handling

Common exceptions:
- ArgumentError (invalid arguments)
- StateError (invalid state)
- FirebaseException (backend failures)

---

## Feedback Map Structure

```dart
Map<String, dynamic> feedback = {
  'muscle_activation': 8.5,
  'pump_quality': 8.0,
  'fatigue_level': 5.0,
  'recovery_quality': 8.0,
  'had_pain': false,
  'pain_severity': null,
  'pain_description': null,
};
```

User feedback by muscle:

```dart
Map<String, Map<String, dynamic>> userFeedbackByMuscle = {
  'pectorals': {
    'muscle_activation': 8.5,
    'pump_quality': 8.0,
    'fatigue_level': 5.0,
    'recovery_quality': 8.0,
    'had_pain': false,
  },
  'lats': {
    // ...
  },
};
```

Progression summary:

```dart
Map<String, dynamic> summary = {
  'totalMuscles': 14,
  'totalVolume': 180,
  'musclesWithVMR': 8,
  'musclesByPhase': {
    'discovering': 4,
    'maintaining': 8,
    'deloading': 2,
    'overreaching': 0,
    'microdeload': 0,
  },
  'avgVolumePerMuscle': 12.85,
  'trackers': {
    'pectorals': MuscleProgressionTracker(...),
  },
};
```

---

## Constants

```dart
const int DELOAD_DURATION = 1;
const int MICRODELOAD_DURATION = 1;
const int MIN_DISCOVERING_WEEKS = 3;

const double DELOAD_MULTIPLIER = 0.4;
const double MICRODELOAD_MULTIPLIER = 0.6;

const int DEFAULT_VOLUME_INCREMENT = 2;

const double HIGH_ACTIVATION_THRESHOLD = 8.0;
const double HIGH_FATIGUE_THRESHOLD = 7.5;
const double LOW_RECOVERY_THRESHOLD = 5.0;

const int WEEKS_BETWEEN_MICRODELOAD = 6;
```

---

## Migration Guide

If migrating from a previous training system:

```dart
await repo.initializeAllTrackers(
  userId: userId,
  musclePriorities: legacyPriorities,
  trainingLevel: legacyLevel,
  age: userAge,
);

for (final muscle in muscles) {
  final legacyVolume = getLegacyVolume(muscle);
  final tracker = await repo.getTracker(userId: userId, muscle: muscle);

  final updated = tracker!.copyWith(
    currentVolume: legacyVolume,
    currentPhase: ProgressionPhase.maintaining,
  );

  await repo.updateTracker(updated);
}
```

---

## Versioning

This API follows Semantic Versioning (SemVer).

- Major: Breaking changes
- Minor: New features (backward compatible)
- Patch: Bug fixes

Current Version: 1.0.0
