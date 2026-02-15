# Motor V3 - Testing Guide

## Table of Contents

1. [Overview](#overview)
2. [Unit Testing](#unit-testing)
3. [Integration Testing](#integration-testing)
4. [Widget Testing](#widget-testing)
5. [Test Coverage](#test-coverage)
6. [CI/CD Integration](#cicd-integration)

---

## Overview

Motor V3 uses a comprehensive testing strategy:

- Unit tests: Test individual components in isolation
- Integration tests: Test component interactions
- Widget tests: Test UI components
- E2E tests: Test complete user workflows

### Testing Stack

```yaml
dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  mocktail: ^1.0.0
  fake_async: ^1.3.0
```

---

## Unit Testing

### Running Unit Tests

```bash
# Run all unit tests
flutter test

# Run specific file
flutter test test/domain/training_v3/models/muscle_progression_tracker_test.dart

# Run with coverage
flutter test --coverage

# View coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Writing Unit Tests

#### Testing Models

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/training_v3/models/muscle_progression_tracker.dart';

void main() {
  group('MuscleProgressionTracker', () {
    test('should initialize with correct defaults', () {
      final tracker = MuscleProgressionTracker(
        userId: 'test_user',
        muscle: 'pectorals',
        currentVolume: 12,
        landmarks: VolumeLandmarks(vme: 8, vop: 12, mrv: 20),
        currentPhase: ProgressionPhase.discovering,
        weekInCurrentPhase: 0,
        priority: 5,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(tracker.muscle, 'pectorals');
      expect(tracker.currentVolume, 12);
      expect(tracker.currentPhase, ProgressionPhase.discovering);
    });

    test('should serialize/deserialize correctly', () {
      final original = MuscleProgressionTracker(
        userId: 'test_user',
        muscle: 'pectorals',
        currentVolume: 12,
        landmarks: VolumeLandmarks(vme: 8, vop: 12, mrv: 20),
        currentPhase: ProgressionPhase.discovering,
        weekInCurrentPhase: 0,
        priority: 5,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final json = original.toJson();
      final restored = MuscleProgressionTracker.fromJson(json);

      expect(restored.muscle, original.muscle);
      expect(restored.currentVolume, original.currentVolume);
    });
  });
}
```

#### Testing Services with Mocks

```dart
import 'package:mocktail/mocktail.dart';

class MockMuscleProgressionRepository extends Mock
    implements MuscleProgressionRepository {}

void main() {
  late WeeklyProgressionServiceImpl service;
  late MockMuscleProgressionRepository mockRepo;

  setUp(() {
    mockRepo = MockMuscleProgressionRepository();
    service = WeeklyProgressionServiceImpl(
      progressionRepo: mockRepo,
      analysisRepo: mockAnalysisRepo,
    );

    registerFallbackValue(MuscleProgressionTracker(
      userId: 'test',
      muscle: 'pectorals',
      currentVolume: 12,
      landmarks: VolumeLandmarks(vme: 8, vop: 12, mrv: 20),
      currentPhase: ProgressionPhase.discovering,
      weekInCurrentPhase: 0,
      priority: 5,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  });

  test('should process weekly progression', () async {
    when(() => mockRepo.getTracker(
          userId: any(named: 'userId'),
          muscle: any(named: 'muscle'),
        )).thenAnswer((_) async => tracker);

    final decisions = await service.processWeeklyProgression(
      userId: 'user123',
      weekNumber: 1,
      weekStart: DateTime.now().subtract(const Duration(days: 7)),
      weekEnd: DateTime.now(),
      exerciseLogs: [],
      userFeedbackByMuscle: {},
    );

    expect(decisions, isNotEmpty);
    verify(() => mockRepo.getTracker(
          userId: any(named: 'userId'),
          muscle: any(named: 'muscle'),
        )).called(1);
  });
}
```

### Test Organization

```
test/
├── domain/
│   └── training_v3/
│       ├── models/
│       │   ├── muscle_progression_tracker_test.dart
│       │   ├── muscle_decision_test.dart
│       │   └── exercise_log_test.dart
│       ├── services/
│       │   └── weekly_progression_service_test.dart
│       └── repositories/
│           └── muscle_progression_repository_test.dart
└── features/
    └── training_feature/
        ├── viewmodels/
        │   └── weekly_progression_viewmodel_test.dart
        └── widgets/
            ├── weekly_feedback_form_test.dart
            └── muscle_progression_card_test.dart
```

---

## Integration Testing

### Running Integration Tests

```bash
# Run all integration tests
flutter test integration_test/

# Run specific test
flutter test integration_test/weekly_progression_integration_test.dart
```

### Writing Integration Tests

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Weekly Progression Integration', () {
    test('Complete 4-week workflow', () async {
      final service = WeeklyProgressionServiceImpl(
        progressionRepo: MuscleProgressionRepositoryImpl(),
        analysisRepo: WeeklyMuscleAnalysisRepositoryImpl(),
      );

      final week1Decisions = await service.processWeeklyProgression(
        userId: 'user123',
        weekNumber: 1,
        weekStart: DateTime.now().subtract(const Duration(days: 7)),
        weekEnd: DateTime.now(),
        exerciseLogs: [],
        userFeedbackByMuscle: {},
      );

      expect(week1Decisions, isNotEmpty);
    });
  });
}
```

---

## Widget Testing

### Running Widget Tests

```bash
# Run widget tests
flutter test test/features/training_feature/widgets/

# Run with golden files
flutter test --update-goldens
```

### Writing Widget Tests

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('should render all sliders', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WeeklyFeedbackForm(
            muscle: 'pectorals',
            onFeedbackChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Activacion Muscular'), findsOneWidget);
    expect(find.text('Calidad del Pump'), findsOneWidget);
    expect(find.byType(Slider), findsNWidgets(4));
  });
}
```

---

## Test Coverage

### Generating Coverage Reports

```bash
# Generate coverage
flutter test --coverage

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html

# Open report
open coverage/html/index.html
```

### Coverage Goals

| Component   | Target | Current |
|-------------|--------|---------|
| Models      | 95%+   | 98%     |
| Services    | 90%+   | 92%     |
| Repositories| 85%+   | 87%     |
| ViewModels  | 85%+   | 85%     |
| Widgets     | 80%+   | 83%     |
| Overall     | 85%+   | 89%     |

---

## CI/CD Integration

### GitHub Actions

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'

      - name: Install dependencies
        run: flutter pub get

      - name: Run tests
        run: flutter test --coverage

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/lcov.info

      - name: Check coverage threshold
        run: |
          COVERAGE=$(lcov --summary coverage/lcov.info | grep lines | awk '{print $2}' | sed 's/%//')
          if (( $(echo "$COVERAGE < 85" | bc -l) )); then
            echo "Coverage is below 85%: $COVERAGE%"
            exit 1
          fi
```

---

## Best Practices

1. AAA Pattern

```dart
test('should increase volume on good response', () async {
  final tracker = MuscleProgressionTracker(
    userId: 'user123',
    muscle: 'pectorals',
    currentVolume: 12,
    landmarks: VolumeLandmarks(vme: 8, vop: 12, mrv: 20),
    currentPhase: ProgressionPhase.discovering,
    weekInCurrentPhase: 1,
    priority: 5,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
  final feedback = {
    'muscle_activation': 8.5,
    'pump_quality': 8.0,
    'fatigue_level': 4.0,
    'recovery_quality': 8.5,
    'had_pain': false,
  };

  final decision = await service.processMuscleProgression(
    tracker: tracker,
    weekNumber: 2,
    exerciseLogs: [],
    userFeedback: feedback,
  );

  expect(decision.action, VolumeAction.increase);
});
```

2. Use Descriptive Names

```dart
// Bad
// test('test1', () { /* ... */ });

// Good
// test('should increase volume when muscle activation is high and fatigue is low', () { /* ... */ });
```

3. Test Edge Cases

```dart
group('Edge Cases', () {
  test('should handle zero volume', () { /* ... */ });
  test('should handle null feedback', () { /* ... */ });
  test('should handle missing tracker', () { /* ... */ });
});
```

4. Mock External Dependencies

```dart
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

setUp(() {
  mockFirestore = MockFirebaseFirestore();
  repo = MuscleProgressionRepositoryImpl(firestore: mockFirestore);
});
```

5. Clean Up Resources

```dart
late MyService service;

setUp(() {
  service = MyService();
});

test('example', () async {
  // ...
});
```

---

## Debugging Tests

### Running Single Test

```dart
test('my specific test', () {
  // ...
}, skip: false);

test('other test', () {
  // ...
}, skip: true);
```

### Using Debugger

```dart
test('debug this', () async {
  final result = await service.method();
  debugger();
  expect(result, isNotNull);
});
```

### Verbose Output

```bash
flutter test --verbose
```

---

## Troubleshooting

Issue: Tests timing out

```dart
test('long running test', () async {
  // ...
}, timeout: Timeout(Duration(minutes: 2)));
```

Issue: Flaky tests

```dart
await tester.pumpAndSettle();
```

Issue: Firebase emulator connection

```bash
firebase emulators:start
flutter test --dart-define=USE_FIREBASE_EMULATOR=true
```
