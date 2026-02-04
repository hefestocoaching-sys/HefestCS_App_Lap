# Motor V3 Developer Guide

**For Engineers Extending and Maintaining Motor V3**  
Version: 3.0.0 | Last Updated: February 2026

---

## Table of Contents

1. [Setup and Installation](#setup-and-installation)
2. [Code Structure Overview](#code-structure-overview)
3. [How to Add New Engines](#how-to-add-new-engines)
4. [How to Extend Validators](#how-to-extend-validators)
5. [Testing Guidelines](#testing-guidelines)
6. [Integration Patterns](#integration-patterns)
7. [Best Practices](#best-practices)

---

## Setup and Installation

### Prerequisites

- **Flutter SDK**: ≥3.5.0
- **Dart SDK**: ≥3.2.0
- **Firebase CLI**: Latest version
- **IDE**: VS Code / Android Studio with Flutter plugin
- **Git**: For version control

### Initial Setup

#### 1. Clone Repository

```bash
git clone https://github.com/your-org/HefestCS_App_Lap.git
cd HefestCS_App_Lap
```

#### 2. Install Dependencies

```bash
flutter pub get
```

#### 3. Configure Firebase

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase projects
flutterfire configure

# Select projects:
# - Development: hefestcs-dev
# - Production: hefestcs-prod
```

#### 4. Run Code Generation

```bash
# Generate Freezed models, Riverpod providers
flutter pub run build_runner build --delete-conflicting-outputs
```

#### 5. Verify Installation

```bash
# Run tests
flutter test

# Run app in debug mode
flutter run
```

### Development Environment

#### Recommended VS Code Extensions

```json
{
  "recommendations": [
    "Dart-Code.dart-code",
    "Dart-Code.flutter",
    "alexisvt.flutter-snippets",
    "felixangelov.bloc",
    "nash.awesome-flutter-snippets"
  ]
}
```

#### IDE Settings (`.vscode/settings.json`)

```json
{
  "dart.lineLength": 80,
  "editor.formatOnSave": true,
  "editor.rulers": [80],
  "dart.flutterSdkPath": "/path/to/flutter",
  "dart.debugExternalPackageLibraries": true,
  "dart.debugSdkLibraries": false
}
```

---

## Code Structure Overview

### High-Level Architecture

```
lib/
├── domain/                     # Business logic (pure Dart)
│   ├── training_v3/           # Motor V3 core
│   │   ├── engine/            # Main engine
│   │   ├── ml/                # ML components
│   │   └── models/            # Domain models
│   ├── training/              # Legacy motor
│   └── nutrition/             # Dietary motor
│
├── features/                   # UI features (Flutter)
│   ├── training_feature/      # Training screens
│   │   ├── providers/         # Riverpod state
│   │   └── widgets/           # UI components
│   ├── client_feature/        # Client management
│   └── dashboard_feature/     # Analytics
│
├── infrastructure/             # External dependencies
│   ├── repositories/          # Data access
│   └── services/              # Firebase, API
│
└── core/                       # Shared utilities
    ├── constants/
    ├── extensions/
    └── utils/
```

### Motor V3 Module Structure

```
lib/domain/training_v3/
│
├── engine/
│   ├── training_program_engine_v3.dart       # Main engine (794 lines)
│   └── training_program_engine_v3_full.dart  # Future full version
│
├── ml/
│   ├── decision_strategy.dart                # Strategy interface
│   ├── feature_vector.dart                   # 38 features
│   ├── training_dataset_service.dart         # Firestore CRUD
│   │
│   └── strategies/
│       ├── rule_based_strategy.dart          # 100% rules
│       ├── hybrid_strategy.dart              # 70% rules + 30% ML
│       └── ml_model_strategy.dart            # 100% ML (future)
│
├── models/
│   ├── training_context_v2.dart              # 30-field context
│   ├── volume_decision.dart                  # Volume output
│   ├── readiness_decision.dart               # Readiness output
│   ├── decision_trace.dart                   # Explainability
│   └── training_program_v3_result.dart       # Final result
│
└── validators/
    ├── context_validator.dart                # Validates input
    └── plan_validator.dart                   # Validates output
```

### Key Files Deep Dive

#### `training_program_engine_v3.dart`

**Purpose**: Main orchestrator for program generation.

**Key Classes**:

```dart
class TrainingProgramEngineV3 {
  final DecisionStrategy _strategy;
  final TrainingDatasetService? _datasetService;
  final Phase3VolumeCapacityModelService _phase3;
  final Phase4SplitDistributionService _phase4;
  final Phase5PeriodizationService _phase5;
  final Phase6ExerciseSelectionService _phase6;
  final Phase7PrescriptionService _phase7;

  // Factory constructors
  TrainingProgramEngineV3.production();
  TrainingProgramEngineV3.hybrid({required double mlWeight});
  TrainingProgramEngineV3.custom({required DecisionStrategy strategy});

  // Main API
  Future<TrainingProgramV3Result> generatePlan({
    required Client client,
    required List<Exercise> exercises,
    DateTime? asOfDate,
    bool recordPrediction = true,
  });
}
```

**Pipeline Stages**:

1. **Context Building** (`_buildContext`) **[Planned Feature]**
   - ⚠️ *Note: TrainingContext class not yet implemented*
   - Planned: Transforms `Client` → `TrainingContext`
   - Planned: Aggregates 30 fields from multiple sources

2. **Feature Engineering** (`_engineerFeatures`)
   - Derives 38 features from context
   - Normalizes values to [0.0, 1.0]

3. **Decision Making** (`_makeDecisions`)
   - Calls `_strategy.decideVolume()` and `decideReadiness()`
   - Returns `VolumeDecision` and `ReadinessDecision`

4. **ML Logging** (`_logPrediction`)
   - Saves to Firestore if `recordPrediction = true`
   - Returns `mlExampleId` for tracking

5. **Readiness Gate** (`_checkReadiness`)
   - Blocks plan if readiness = CRITICAL or POOR
   - Returns `blockedReason` if blocked

6. **Plan Generation** (`_buildPlanFromDecisions`)
   - Integrates Phases 3-7
   - Applies `volumeAdjustmentFactor`
   - Returns `TrainingPlanConfig`

7. **Result Assembly**
   - Packages everything into `TrainingProgramV3Result`

#### `feature_vector.dart`

**Purpose**: Defines 38 ML features with normalization.

**Structure**:

```dart
@freezed
class FeatureVector with _$FeatureVector {
  const factory FeatureVector({
    // Demographics (5)
    required double ageYearsNorm,              // [0.0, 1.0]
    required double genderMaleEncoded,         // 0.0 or 1.0
    required double heightCmNorm,              // [0.0, 1.0]
    required double weightKgNorm,              // [0.0, 1.0]
    required double bmiNorm,                   // [0.0, 1.0]

    // Experience (3)
    required double yearsTrainingNorm,
    required double consecutiveWeeksNorm,
    required double trainingLevelEncoded,      // 0.0/0.5/1.0

    // Volume (4)
    required double avgWeeklySetsNorm,
    required double maxSetsTolerance,
    required double volumeToleranceScore,
    required double volumeOptimalityScore,

    // ... 26 more features (see full file)
  }) = _FeatureVector;

  // Factory: Build from TrainingContext [NOT IMPLEMENTED]
  // TODO: Implement TrainingContext class
  /*
  factory FeatureVector.fromContext(TrainingContext context) {
    // Normalization logic
    final age = (context.athlete.ageYears - 18.0) / (80.0 - 18.0);
    final height = (context.athlete.heightCm - 140.0) / (220.0 - 140.0);
    // ... etc
    
    return FeatureVector(
      ...
    );
  }
  */
}
```

---

### Adding New Features

> ⚠️ **Note**: The ML dataset collection feature (TrainingContext, FeatureVector.fromContext, TrainingDatasetService.recordPrediction) is currently incomplete and commented out in the codebase. If you need to implement these features, you'll need to first create the TrainingContext class.
      ageYearsNorm: age.clamp(0.0, 1.0),
      heightCmNorm: height.clamp(0.0, 1.0),
      // ...
    );
  }
}
```

**Feature Categories**:

| Category | Count | Examples |
|----------|-------|----------|
| Demographics | 5 | age, gender, BMI |
| Experience | 3 | yearsTraining, trainingLevel |
| Volume | 4 | avgWeeklySets, volumeTolerance |
| Recovery | 6 | sleep, stress, soreness |
| Session | 4 | duration, RIR, RPE |
| Optimization | 2 | rirOptimality, deloadFreq |
| Longitudinal | 3 | adherence, performanceTrend |
| Objectives | 8 | goalOneHot (4) + focusOneHot (4) |
| Derived | 6 | fatigueIndex, readinessScore, overreachingRisk |

#### `decision_strategy.dart`

**Purpose**: Interface for decision-making strategies.

```dart
abstract class DecisionStrategy {
  String get name;
  String get version;

  VolumeDecision decideVolume(FeatureVector features);
  ReadinessDecision decideReadiness(FeatureVector features);

  List<DecisionTrace> get traces; // For explainability
}
```

**Implementations**:

1. **RuleBasedStrategy** (Production)
   - 100% scientific rules
   - No ML dependencies
   - Deterministic outputs

2. **HybridStrategy** (Testing)
   - 70% RuleBasedStrategy
   - 30% ML predictions (weighted blend)
   - Requires ML service endpoint

3. **MLModelStrategy** (Future)
   - 100% ML predictions
   - REST API to Cloud Function
   - Fallback to RuleBased if service down

#### `training_dataset_service.dart`

**Purpose**: Manages ML dataset in Firestore.

```dart
class TrainingDatasetService {
  final FirebaseFirestore _firestore;
  static const String _collection = 'ml_training_data';

  // Record prediction when plan generated
  Future<String> recordPrediction({
    required String clientId,
    required TrainingContextV2 context,
    required VolumeDecision volumeDecision,
    required ReadinessDecision readinessDecision,
    required String strategyUsed,
  }) async {
    final exampleId = const Uuid().v4();
    
    await _firestore.collection(_collection).doc(exampleId).set({
      'exampleId': exampleId,
      'clientId': clientId,
      'timestamp': FieldValue.serverTimestamp(),
      'features': FeatureVector.fromContext(context).toJson(),
      'prediction': {
        'volumeAdjustmentFactor': volumeDecision.adjustmentFactor,
        'volumeConfidence': volumeDecision.confidence,
        'readinessLevel': readinessDecision.level.name,
        'readinessScore': readinessDecision.score,
      },
      'outcome': {'hasOutcome': false}, // Filled later
      'strategyUsed': strategyUsed,
    });
    
    return exampleId;
  }

  // Record outcome after 3-4 weeks
  Future<void> recordOutcome({
    required String exampleId,
    required double adherence,       // 0-100
    required double fatigue,          // 1-10
    required double progress,         // kg or reps gained
    bool injury = false,
    bool tooHard = false,
    bool tooEasy = false,
  }) async {
    await _firestore.collection(_collection).doc(exampleId).update({
      'outcome': {
        'hasOutcome': true,
        'adherence': adherence,
        'fatigue': fatigue,
        'progress': progress,
        'injury': injury,
        'tooHard': tooHard,
        'tooEasy': tooEasy,
        'submittedAt': FieldValue.serverTimestamp(),
      },
    });
  }

  // Query examples for ML training
  Future<List<Map<String, dynamic>>> fetchExamplesWithOutcomes({
    int limit = 500,
  }) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('outcome.hasOutcome', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}
```

---

## How to Add New Engines

### Example: Adding a New Decision Strategy

Let's add a **TimeOfDayStrategy** that adjusts volume based on workout time.

#### Step 1: Create Strategy File

```dart
// lib/domain/training_v3/ml/strategies/time_of_day_strategy.dart

import '../decision_strategy.dart';
import '../feature_vector.dart';
import '../../models/volume_decision.dart';
import '../../models/readiness_decision.dart';
import '../../models/decision_trace.dart';

class TimeOfDayStrategy implements DecisionStrategy {
  final List<DecisionTrace> _traces = [];

  @override
  String get name => 'TimeOfDay';

  @override
  String get version => '1.0.0';

  @override
  List<DecisionTrace> get traces => List.unmodifiable(_traces);

  @override
  VolumeDecision decideVolume(FeatureVector features) {
    _traces.clear();

    final now = DateTime.now();
    final hour = now.hour;

    double adjustmentFactor;
    String reasoning;

    if (hour >= 6 && hour < 12) {
      // Morning: Lower cortisol, better performance
      adjustmentFactor = 1.1;
      reasoning = 'Morning workout: +10% volume (optimal cortisol)';
    } else if (hour >= 12 && hour < 17) {
      // Afternoon: Peak strength window
      adjustmentFactor = 1.2;
      reasoning = 'Afternoon workout: +20% volume (peak strength)';
    } else if (hour >= 17 && hour < 21) {
      // Evening: Good but slightly fatigued
      adjustmentFactor = 1.0;
      reasoning = 'Evening workout: Normal volume';
    } else {
      // Night: Poor recovery, reduce volume
      adjustmentFactor = 0.8;
      reasoning = 'Night workout: -20% volume (poor recovery)';
    }

    _traces.add(DecisionTrace(
      phase: 'VolumeDecision',
      rule: 'TimeOfDayAdjustment',
      reasoning: reasoning,
      confidence: 0.75,
      timestamp: now,
    ));

    return VolumeDecision(
      adjustmentFactor: adjustmentFactor,
      confidence: 0.75,
      reasoning: reasoning,
      traces: _traces,
    );
  }

  @override
  ReadinessDecision decideReadiness(FeatureVector features) {
    // Delegate to RuleBasedStrategy for readiness
    // Or implement custom logic
    final baseStrategy = RuleBasedStrategy();
    return baseStrategy.decideReadiness(features);
  }
}
```

#### Step 2: Register Strategy Provider

```dart
// lib/features/training_feature/providers/training_engine_v3_provider.dart

@riverpod
TrainingProgramEngineV3 trainingEngineV3TimeOfDay(
  TrainingEngineV3TimeOfDayRef ref,
) {
  return TrainingProgramEngineV3.custom(
    strategy: TimeOfDayStrategy(),
  );
}
```

#### Step 3: Use in UI

```dart
// In widget
final engine = ref.read(trainingEngineV3TimeOfDayProvider);

final result = await engine.generatePlan(
  client: currentClient,
  exercises: exerciseCatalog,
);
```

#### Step 4: Test Strategy

```dart
// test/domain/training_v3/strategies/time_of_day_strategy_test.dart

void main() {
  group('TimeOfDayStrategy', () {
    late TimeOfDayStrategy strategy;
    late FeatureVector mockFeatures;

    setUp(() {
      strategy = TimeOfDayStrategy();
      mockFeatures = FeatureVector.fromContext(mockContext);
    });

    test('morning workout increases volume by 10%', () {
      // Mock time to 8 AM
      final decision = strategy.decideVolume(mockFeatures);
      
      expect(decision.adjustmentFactor, 1.1);
      expect(decision.reasoning, contains('Morning workout'));
    });

    test('night workout decreases volume by 20%', () {
      // Mock time to 11 PM
      final decision = strategy.decideVolume(mockFeatures);
      
      expect(decision.adjustmentFactor, 0.8);
      expect(decision.reasoning, contains('Night workout'));
    });
  });
}
```

### Adding a New Phase (e.g., Phase 8: Autoregulation)

#### Step 1: Create Service

```dart
// lib/domain/training_v3/phases/phase8_autoregulation_service.dart

class Phase8AutoregulationService {
  /// Adjusts RIR targets based on real-time performance
  List<RirAdjustment> adjustRir({
    required TrainingPlanConfig basePlan,
    required List<WorkoutLog> recentLogs,
  }) {
    final adjustments = <RirAdjustment>[];

    for (final session in basePlan.sessions) {
      for (final exercise in session.exercises) {
        final recentPerformance = _findRecentPerformance(
          exercise: exercise,
          logs: recentLogs,
        );

        if (recentPerformance != null) {
          final adjustedRir = _calculateAdjustedRir(
            plannedRir: exercise.rir,
            actualRir: recentPerformance.actualRir,
            performanceTrend: recentPerformance.trend,
          );

          adjustments.add(RirAdjustment(
            exerciseId: exercise.id,
            originalRir: exercise.rir,
            adjustedRir: adjustedRir,
            reasoning: 'Based on recent performance trend',
          ));
        }
      }
    }

    return adjustments;
  }

  double _calculateAdjustedRir({
    required double plannedRir,
    required double actualRir,
    required PerformanceTrend trend,
  }) {
    // If consistently hitting RIR 0 when planned RIR 2 → too easy
    if (actualRir < plannedRir - 1 && trend == PerformanceTrend.improving) {
      return (plannedRir - 1).clamp(0.0, 5.0);
    }
    
    // If struggling to hit RIR 3 when planned RIR 1 → too hard
    if (actualRir > plannedRir + 1 && trend == PerformanceTrend.declining) {
      return (plannedRir + 1).clamp(0.0, 5.0);
    }

    return plannedRir;
  }
}
```

#### Step 2: Integrate into Engine

```dart
// In training_program_engine_v3.dart

class TrainingProgramEngineV3 {
  final Phase8AutoregulationService _phase8;

  // Add to _buildPlanFromDecisions()
  TrainingPlanConfig _buildPlanFromDecisions(...) {
    // ... existing Phase 3-7 ...

    // Phase 8: Autoregulation
    final rirAdjustments = _phase8.adjustRir(
      basePlan: planConfig,
      recentLogs: context.longitudinal.recentWorkouts,
    );

    final autoregulatedPlan = _applyRirAdjustments(
      plan: planConfig,
      adjustments: rirAdjustments,
    );

    return autoregulatedPlan;
  }
}
```

---

## How to Extend Validators

### Current Validators

1. **ContextValidator**: Validates `TrainingContextV2`
2. **PlanValidator**: Validates `TrainingPlanConfig`

### Adding Custom Validation Rules

#### Example: Volume Ceiling Validator

Prevents plans exceeding 200 sets/week (injury risk).

```dart
// lib/domain/training_v3/validators/volume_ceiling_validator.dart

class VolumeCeilingValidator {
  static const int maxWeeklySets = 200;
  static const int warningThreshold = 180;

  ValidationResult validate(TrainingPlanConfig plan) {
    final totalSets = _calculateTotalWeeklySets(plan);

    if (totalSets > maxWeeklySets) {
      return ValidationResult.error(
        code: 'VOLUME_EXCEEDS_CEILING',
        message: 'Plan has $totalSets sets/week (max: $maxWeeklySets)',
        severity: ValidationSeverity.critical,
        recommendation: 'Reduce volume by ${totalSets - maxWeeklySets} sets',
      );
    }

    if (totalSets > warningThreshold) {
      return ValidationResult.warning(
        code: 'VOLUME_HIGH',
        message: 'Plan has $totalSets sets/week (recommended max: $warningThreshold)',
        severity: ValidationSeverity.moderate,
        recommendation: 'Monitor fatigue closely',
      );
    }

    return ValidationResult.pass();
  }

  int _calculateTotalWeeklySets(TrainingPlanConfig plan) {
    int total = 0;
    for (final week in plan.weeks) {
      for (final session in week.sessions) {
        total += session.totalSets;
      }
    }
    return total ~/ plan.weeks.length; // Average per week
  }
}
```

#### Integrate into Pipeline

```dart
// In training_program_engine_v3.dart

Future<TrainingProgramV3Result> generatePlan(...) async {
  // ... existing pipeline ...

  // Before returning result
  final volumeValidator = VolumeCeilingValidator();
  final validationResult = volumeValidator.validate(planConfig);

  if (validationResult.isCritical) {
    return TrainingProgramV3Result(
      plan: null,
      blockedReason: validationResult.message,
      // ... other fields
    );
  }

  if (validationResult.isWarning) {
    // Log warning but allow plan
    logger.warn(validationResult.message);
  }

  return TrainingProgramV3Result(plan: planConfig, ...);
}
```

### Validator Best Practices

1. **Fail Fast**: Check critical validations early
2. **Clear Messages**: Include specific values and thresholds
3. **Actionable Recommendations**: Tell user how to fix
4. **Severity Levels**: `critical` (block) vs `warning` (log)
5. **Performance**: Optimize validation for large plans (1000+ exercises)

---

## Testing Guidelines

### Test Structure

```
test/
├── unit/
│   ├── domain/
│   │   ├── training_v3/
│   │   │   ├── engine_test.dart
│   │   │   ├── strategies/
│   │   │   │   ├── rule_based_test.dart
│   │   │   │   └── hybrid_test.dart
│   │   │   └── models/
│   │   │       └── feature_vector_test.dart
│
├── integration/
│   ├── training_v3_pipeline_test.dart
│   └── firestore_dataset_test.dart
│
└── widget/
    ├── training_plan_generator_button_test.dart
    └── ml_outcome_feedback_dialog_test.dart
```

### Unit Testing

#### Testing Feature Engineering

```dart
// test/unit/domain/training_v3/models/feature_vector_test.dart

void main() {
  group('FeatureVector.fromContext', () {
    test('normalizes age correctly', () {
      final context = TrainingContextV2(
        athlete: AthleteProfile(ageYears: 30),
        // ... other fields
      );

      final features = FeatureVector.fromContext(context);

      // Age normalization: (30 - 18) / (80 - 18) = 0.1935
      expect(features.ageYearsNorm, closeTo(0.1935, 0.01));
    });

    test('clamps BMI to [0.0, 1.0]', () {
      final context = TrainingContextV2(
        athlete: AthleteProfile(
          heightCm: 175,
          weightKg: 150, // Very high BMI
        ),
      );

      final features = FeatureVector.fromContext(context);
      
      expect(features.bmiNorm, lessThanOrEqualTo(1.0));
    });

    test('encodes gender correctly', () {
      final maleContext = TrainingContextV2(
        athlete: AthleteProfile(gender: Gender.male),
      );
      final femaleContext = TrainingContextV2(
        athlete: AthleteProfile(gender: Gender.female),
      );

      expect(FeatureVector.fromContext(maleContext).genderMaleEncoded, 1.0);
      expect(FeatureVector.fromContext(femaleContext).genderMaleEncoded, 0.0);
    });
  });
}
```

#### Testing Decision Strategies

```dart
// test/unit/domain/training_v3/strategies/rule_based_test.dart

void main() {
  group('RuleBasedStrategy', () {
    late RuleBasedStrategy strategy;
    late FeatureVector baseFeatures;

    setUp(() {
      strategy = RuleBasedStrategy();
      baseFeatures = FeatureVector(
        // Baseline "good" client
        readinessScore: 0.7,
        fatigueIndex: 0.4,
        overreachingRisk: 0.2,
        // ... other features
      );
    });

    group('decideVolume', () {
      test('returns 1.0 adjustment for balanced client', () {
        final decision = strategy.decideVolume(baseFeatures);
        
        expect(decision.adjustmentFactor, closeTo(1.0, 0.1));
        expect(decision.confidence, greaterThan(0.7));
      });

      test('reduces volume for high fatigue', () {
        final fatigued = baseFeatures.copyWith(
          fatigueIndex: 0.8,
          readinessScore: 0.3,
        );

        final decision = strategy.decideVolume(fatigued);
        
        expect(decision.adjustmentFactor, lessThan(0.9));
        expect(decision.reasoning, contains('fatigue'));
      });

      test('increases volume for advanced + low fatigue', () {
        final optimal = baseFeatures.copyWith(
          trainingLevelEncoded: 1.0, // Advanced
          fatigueIndex: 0.2,
          readinessScore: 0.9,
        );

        final decision = strategy.decideVolume(optimal);
        
        expect(decision.adjustmentFactor, greaterThan(1.1));
      });
    });

    group('decideReadiness', () {
      test('returns EXCELLENT for optimal recovery', () {
        final optimal = baseFeatures.copyWith(
          readinessScore: 0.95,
          fatigueIndex: 0.15,
        );

        final decision = strategy.decideReadiness(optimal);
        
        expect(decision.level, ReadinessLevel.excellent);
        expect(decision.needsDeload, false);
      });

      test('returns CRITICAL for severe fatigue', () {
        final critical = baseFeatures.copyWith(
          fatigueIndex: 0.9,
          readinessScore: 0.2,
          overreachingRisk: 0.8,
        );

        final decision = strategy.decideReadiness(critical);
        
        expect(decision.level, ReadinessLevel.critical);
        expect(decision.needsDeload, true);
      });
    });
  });
}
```

### Integration Testing

#### Testing Full Pipeline

```dart
// test/integration/training_v3_pipeline_test.dart

void main() {
  late TrainingProgramEngineV3 engine;
  late Client testClient;
  late List<Exercise> exerciseCatalog;

  setUp(() async {
    // Initialize with test Firestore emulator
    await FirebaseEmulator.initialize();
    
    engine = TrainingProgramEngineV3.production();
    
    testClient = Client(
      id: 'test_client_1',
      profile: ClientProfile(
        fullName: 'Test User',
        trainingLevel: TrainingLevel.intermediate,
        daysPerWeek: 4,
        // ... complete profile
      ),
      trainingEvaluation: TrainingEvaluation(
        avgWeeklySets: 80,
        avgSleepHours: 7,
        perceivedRecoveryStatus: 7,
        stressLevel: 5,
        soreness48h: 4,
      ),
    );

    exerciseCatalog = await loadTestExerciseCatalog();
  });

  test('generates valid 4-week plan for normal client', () async {
    final result = await engine.generatePlan(
      client: testClient,
      exercises: exerciseCatalog,
      recordPrediction: false, // Skip Firestore in test
    );

    expect(result.isSuccess, true);
    expect(result.plan, isNotNull);
    expect(result.plan!.weeks.length, 4);
    expect(result.volumeDecision.adjustmentFactor, inRange(0.7, 1.3));
    expect(result.readinessDecision.level, isNot(ReadinessLevel.critical));
  });

  test('blocks plan for critical fatigue client', () async {
    final criticalClient = testClient.copyWith(
      trainingEvaluation: TrainingEvaluation(
        avgSleepHours: 4,
        perceivedRecoveryStatus: 2,
        stressLevel: 9,
        soreness48h: 9,
      ),
    );

    final result = await engine.generatePlan(
      client: criticalClient,
      exercises: exerciseCatalog,
      recordPrediction: false,
    );

    expect(result.isBlocked, true);
    expect(result.readinessDecision.needsDeload, true);
    expect(result.blockedReason, isNotNull);
  });

  test('applies volume adjustment correctly', () async {
    final result = await engine.generatePlan(
      client: testClient,
      exercises: exerciseCatalog,
      recordPrediction: false,
    );

    final adjustmentFactor = result.volumeDecision.adjustmentFactor;
    
    // Check that plan volume matches adjustment
    final totalSets = _countTotalSets(result.plan!);
    final expectedSets = (80 * adjustmentFactor).round(); // Base 80 sets

    expect(totalSets, closeTo(expectedSets, 10)); // Within 10 sets
  });
}
```

#### Testing Firestore Integration

```dart
// test/integration/firestore_dataset_test.dart

void main() {
  late TrainingDatasetService service;

  setUp(() async {
    await FirebaseEmulator.initialize();
    service = TrainingDatasetService(FirebaseFirestore.instance);
  });

  test('records prediction to Firestore', () async {
    final exampleId = await service.recordPrediction(
      clientId: 'test_client',
      context: mockContext,
      volumeDecision: VolumeDecision(adjustmentFactor: 0.9, confidence: 0.8),
      readinessDecision: ReadinessDecision(level: ReadinessLevel.good, score: 0.75),
      strategyUsed: 'RuleBased',
    );

    expect(exampleId, isNotEmpty);

    // Verify in Firestore
    final doc = await FirebaseFirestore.instance
        .collection('ml_training_data')
        .doc(exampleId)
        .get();

    expect(doc.exists, true);
    expect(doc.data()!['prediction']['volumeAdjustmentFactor'], 0.9);
  });

  test('records outcome updates existing example', () async {
    final exampleId = await service.recordPrediction(...);

    await service.recordOutcome(
      exampleId: exampleId,
      adherence: 90.0,
      fatigue: 5.5,
      progress: 2.5,
      injury: false,
    );

    final doc = await FirebaseFirestore.instance
        .collection('ml_training_data')
        .doc(exampleId)
        .get();

    expect(doc.data()!['outcome']['hasOutcome'], true);
    expect(doc.data()!['outcome']['adherence'], 90.0);
  });
}
```

### Widget Testing

```dart
// test/widget/training_plan_generator_button_test.dart

void main() {
  testWidgets('shows loading state during generation', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: TrainingPlanGeneratorV3Button(
              client: mockClient,
            ),
          ),
        ),
      ),
    );

    // Tap button
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    // Should show loading indicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('displays readiness metrics on success', (tester) async {
    // ... setup with mock engine returning success

    await tester.tap(find.text('Generate Program'));
    await tester.pumpAndSettle();

    // Should show readiness level
    expect(find.text('GOOD'), findsOneWidget);
    expect(find.textContaining('Readiness Score'), findsOneWidget);
  });
}
```

### Test Coverage Goals

- **Unit Tests**: ≥90% coverage for `domain/` layer
- **Integration Tests**: All critical paths (generate, block, log)
- **Widget Tests**: All user-facing buttons and dialogs

Run coverage:

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## Integration Patterns

### Pattern 1: Riverpod State Management

#### Define Providers

```dart
// lib/features/training_feature/providers/training_engine_v3_provider.dart

@riverpod
TrainingProgramEngineV3 trainingEngineV3Production(
  TrainingEngineV3ProductionRef ref,
) {
  final datasetService = ref.watch(trainingDatasetServiceProvider);
  final phase3 = ref.watch(phase3ServiceProvider);
  final phase4 = ref.watch(phase4ServiceProvider);
  // ... other dependencies

  return TrainingProgramEngineV3.production();
}

@riverpod
class PlanGeneratorNotifier extends _$PlanGeneratorNotifier {
  @override
  AsyncValue<TrainingProgramV3Result?> build() {
    return const AsyncValue.data(null);
  }

  Future<void> generatePlan(Client client) async {
    state = const AsyncValue.loading();
    
    state = await AsyncValue.guard(() async {
      final engine = ref.read(trainingEngineV3ProductionProvider);
      final exercises = ref.read(exerciseCatalogProvider);

      return await engine.generatePlan(
        client: client,
        exercises: exercises,
      );
    });
  }
}
```

#### Consume in UI

```dart
// In widget
class TrainingPlanScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planState = ref.watch(planGeneratorNotifierProvider);

    return planState.when(
      data: (result) {
        if (result == null) {
          return _buildInitialState();
        }
        
        if (result.isBlocked) {
          return _buildBlockedState(result);
        }
        
        return _buildSuccessState(result);
      },
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => ErrorWidget(error: err),
    );
  }
}
```

### Pattern 2: Repository Pattern for Data Access

```dart
// lib/infrastructure/repositories/training_plan_repository.dart

class TrainingPlanRepository {
  final FirebaseFirestore _firestore;

  Future<void> savePlan({
    required String clientId,
    required TrainingPlanConfig plan,
    required String mlExampleId,
  }) async {
    final planDoc = {
      'clientId': clientId,
      'plan': plan.toJson(),
      'mlExampleId': mlExampleId,
      'createdAt': FieldValue.serverTimestamp(),
      'version': 'v3.0.0',
    };

    await _firestore
        .collection('training_plans')
        .doc(plan.id)
        .set(planDoc);
  }

  Future<TrainingPlanConfig?> fetchActivePlan(String clientId) async {
    final snapshot = await _firestore
        .collection('training_plans')
        .where('clientId', isEqualTo: clientId)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    return TrainingPlanConfig.fromJson(snapshot.docs.first.data()['plan']);
  }
}
```

### Pattern 3: Error Handling

```dart
// lib/core/errors/training_errors.dart

sealed class TrainingError implements Exception {
  String get message;
}

class InsufficientDataError extends TrainingError {
  final List<String> missingFields;
  
  @override
  String get message => 'Missing required fields: ${missingFields.join(", ")}';
}

class ReadinessCriticalError extends TrainingError {
  final ReadinessDecision decision;
  
  @override
  String get message => 'Client readiness critical: ${decision.reasoning}';
}

class MLServiceUnavailableError extends TrainingError {
  @override
  String get message => 'ML prediction service unavailable, using fallback';
}

// In engine
Future<TrainingProgramV3Result> generatePlan(...) async {
  try {
    // ... pipeline
  } on InsufficientDataError catch (e) {
    return TrainingProgramV3Result(
      plan: null,
      blockedReason: e.message,
      // ...
    );
  } on FirebaseException catch (e) {
    logger.error('Firestore error: ${e.message}');
    // Continue without ML logging
  } catch (e, stack) {
    logger.error('Unexpected error', error: e, stackTrace: stack);
    rethrow;
  }
}
```

---

## Best Practices

### 1. Code Organization

✅ **DO**: Separate domain logic from UI
```dart
// Good: Domain logic in domain/
class TrainingProgramEngineV3 { ... }

// Bad: Domain logic in widgets
class TrainingButton extends StatelessWidget {
  void _generatePlan() {
    // Complex calculation here ❌
  }
}
```

✅ **DO**: Use immutable models with Freezed
```dart
@freezed
class VolumeDecision with _$VolumeDecision {
  const factory VolumeDecision({
    required double adjustmentFactor,
    required double confidence,
  }) = _VolumeDecision;
}
```

✅ **DO**: Favor composition over inheritance
```dart
// Good
class TrainingProgramEngineV3 {
  final DecisionStrategy _strategy; // Inject
}

// Bad
class MLEngine extends TrainingProgramEngineV3 { ... }
```

### 2. Performance Optimization

✅ **DO**: Cache expensive computations
```dart
class FeatureVector {
  double? _cachedReadinessScore;

  double get readinessScore {
    _cachedReadinessScore ??= _computeReadinessScore();
    return _cachedReadinessScore!;
  }
}
```

✅ **DO**: Use lazy loading for large datasets
```dart
@riverpod
Future<List<Exercise>> exerciseCatalog(ExerciseCatalogRef ref) async {
  // Load on-demand, cache result
  final cache = await ref.watch(cacheManagerProvider);
  return cache.getOrFetch('exercises', () => loadFromFirestore());
}
```

✅ **DO**: Limit Firestore queries
```dart
// Good: Fetch once, filter in-memory
final allExercises = await fetchExercises();
final filtered = allExercises.where((e) => e.muscleGroup == 'chest');

// Bad: Multiple queries
final chestEx = await fetchExercises(muscleGroup: 'chest');
final backEx = await fetchExercises(muscleGroup: 'back');
```

### 3. Error Handling

✅ **DO**: Fail gracefully with fallbacks
```dart
Future<VolumeDecision> decideVolume(...) async {
  try {
    return await _mlService.predict(features);
  } catch (e) {
    logger.warn('ML service down, using rule-based fallback');
    return _ruleBasedStrategy.decideVolume(features);
  }
}
```

✅ **DO**: Provide actionable error messages
```dart
// Good
throw InsufficientDataError(
  missingFields: ['avgWeeklySets', 'avgSleepHours'],
);

// Bad
throw Exception('Invalid data');
```

### 4. Documentation

✅ **DO**: Document complex algorithms
```dart
/// Calculates readiness score using weighted formula:
/// 
/// readinessScore = 
///   0.30 * sleepQuality +
///   0.25 * (1 - fatigue) +
///   0.20 * perceivedRecovery +
///   0.15 * (1 - stress) +
///   0.10 * (1 - soreness)
/// 
/// Range: [0.0, 1.0] where:
/// - 0.0-0.4: Critical (block plan)
/// - 0.4-0.6: Poor (conservative mode)
/// - 0.6-0.8: Good (normal mode)
/// - 0.8-1.0: Excellent (optimal volume)
double _calculateReadinessScore(FeatureVector features) { ... }
```

✅ **DO**: Use dartdoc for public APIs
```dart
/// Generates a personalized 4-week training program.
///
/// This method orchestrates the full Motor V3 pipeline:
/// 1. Context building
/// 2. Feature engineering
/// 3. ML/Rule-based decision making
/// 4. Plan generation (Phases 3-7)
///
/// **Parameters:**
/// - [client]: Client with complete profile and training evaluation
/// - [exercises]: Available exercise catalog (filtered by equipment)
/// - [asOfDate]: Reference date for plan start (defaults to today)
/// - [recordPrediction]: Whether to log prediction to Firestore (default: true)
///
/// **Returns:**
/// [TrainingProgramV3Result] containing:
/// - `plan`: 4-week training plan (null if blocked)
/// - `volumeDecision`: Volume adjustment (0.7-1.3x)
/// - `readinessDecision`: Readiness level + score
/// - `mlExampleId`: Tracking ID for outcome collection
/// - `blockedReason`: Explanation if plan blocked
///
/// **Throws:**
/// - [InsufficientDataError]: If client profile incomplete
/// - [FirebaseException]: If Firestore unavailable (non-fatal)
///
/// **Example:**
/// ```dart
/// final result = await engine.generatePlan(
///   client: myClient,
///   exercises: catalog,
/// );
///
/// if (result.isBlocked) {
///   print('Blocked: ${result.blockedReason}');
/// } else {
///   await savePlan(result.plan!);
/// }
/// ```
Future<TrainingProgramV3Result> generatePlan({ ... }) async { ... }
```

### 5. Testing

✅ **DO**: Test edge cases
```dart
test('handles extreme BMI (>50)', () {
  final features = FeatureVector.fromContext(
    context.copyWith(athlete: AthleteProfile(weightKg: 200, heightCm: 150)),
  );
  expect(features.bmiNorm, lessThanOrEqualTo(1.0));
});
```

✅ **DO**: Mock external dependencies
```dart
class MockTrainingDatasetService extends Mock implements TrainingDatasetService {}

test('continues if Firestore unavailable', () async {
  final mockService = MockTrainingDatasetService();
  when(mockService.recordPrediction(any)).thenThrow(FirebaseException());

  final engine = TrainingProgramEngineV3(..., datasetService: mockService);
  
  // Should not throw
  final result = await engine.generatePlan(...);
  expect(result.mlExampleId, isNull); // Fallback behavior
});
```

### 6. Security

✅ **DO**: Validate all inputs
```dart
Future<TrainingProgramV3Result> generatePlan({
  required Client client,
  ...
}) async {
  // Validate before processing
  final validation = ContextValidator.validate(client);
  if (!validation.isValid) {
    throw InsufficientDataError(missingFields: validation.missingFields);
  }
  
  // Sanitize user inputs
  final safeName = sanitize(client.profile.fullName);
  
  // ... proceed
}
```

✅ **DO**: Use Firestore Security Rules
```javascript
// firestore.rules
match /ml_training_data/{exampleId} {
  // Only authenticated users can write
  allow create: if request.auth != null;
  
  // Only coaches can read their own clients' data
  allow read: if request.auth.uid == resource.data.coachId;
  
  // Prevent tampering with features
  allow update: if !request.resource.data.features.diff(resource.data.features).hasAny();
}
```

---

## Additional Resources

- **[API Reference](api-reference.md)** - Complete API documentation
- **[User Guide](user-guide.md)** - End-user workflows
- **[Scientific Foundation](../scientific-foundation/)** - 7 Semanas model
- **[Architecture](architecture.md)** - System design deep dive

For questions: dev@hefestcs.com  
Report bugs: https://github.com/your-org/HefestCS_App_Lap/issues

---

**Version:** 3.0.0  
**Last Updated:** February 2026  
**Contributors:** HefestCS Engineering Team
