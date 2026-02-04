# Motor V3 API Reference

**Complete API Documentation**  
Version: 3.0.0 | Last Updated: February 2026

---

## Table of Contents

1. [Core Engine](#core-engine)
2. [Decision Strategies](#decision-strategies)
3. [Feature Engineering](#feature-engineering)
4. [ML Dataset Service](#ml-dataset-service)
5. [Model Classes](#model-classes)
6. [Validators](#validators)
7. [Error Handling](#error-handling)
8. [Code Examples](#code-examples)

---

## Core Engine

### TrainingProgramEngineV3

**File**: `lib/domain/training_v3/engine/training_program_engine_v3.dart`

Main orchestrator for Motor V3 program generation pipeline.

#### Constructors

##### `TrainingProgramEngineV3()`

```dart
TrainingProgramEngineV3({
  DecisionStrategy? strategy,
  TrainingDatasetService? datasetService,
})
```

Default constructor with optional strategy injection.

**Parameters:**
- `strategy` (DecisionStrategy?, optional) - Decision-making strategy. Defaults to `RuleBasedStrategy()`.
- `datasetService` (TrainingDatasetService?, optional) - ML dataset service for Firestore logging.

**Example:**
```dart
final engine = TrainingProgramEngineV3(
  strategy: RuleBasedStrategy(),
  datasetService: TrainingDatasetService(firestore: FirebaseFirestore.instance),
);
```

---

##### `TrainingProgramEngineV3.production()`

```dart
factory TrainingProgramEngineV3.production({
  required FirebaseFirestore firestore,
})
```

Production-ready engine with rule-based strategy and ML logging.

**Parameters:**
- `firestore` (FirebaseFirestore, required) - Firestore instance for ML dataset.

**Returns:**  
- `TrainingProgramEngineV3` configured with `RuleBasedStrategy` and dataset logging enabled.

**Example:**
```dart
final engine = TrainingProgramEngineV3.production(
  firestore: FirebaseFirestore.instance,
);
```

---

##### `TrainingProgramEngineV3.hybrid()`

```dart
factory TrainingProgramEngineV3.hybrid({
  required FirebaseFirestore firestore,
  double mlWeight = 0.3,
})
```

Hybrid engine blending rule-based (70%) and ML predictions (30%).

**Parameters:**
- `firestore` (FirebaseFirestore, required) - Firestore instance.
- `mlWeight` (double, optional) - ML weight in range [0.0, 1.0]. Default: 0.3 (30% ML, 70% rules).

**Returns:**  
- `TrainingProgramEngineV3` configured with `HybridStrategy`.

**Example:**
```dart
final engine = TrainingProgramEngineV3.hybrid(
  firestore: FirebaseFirestore.instance,
  mlWeight: 0.4, // 40% ML, 60% rules
);
```

---

#### Methods

##### `generatePlan()`

```dart
Future<TrainingProgramV3Result> generatePlan({
  required Client client,
  required List<Exercise> exercises,
  DateTime? asOfDate,
  bool recordPrediction = true,
})
```

Generates a personalized 4-week training program using the Motor V3 pipeline.

**Pipeline Stages:**
1. Context Building (30 fields)
2. Feature Engineering (38 features)
3. Decision Making (Volume + Readiness)
4. ML Logging (Firestore)
5. Readiness Gate (blocks if critical)
6. Plan Generation (Phases 3-7)
7. Result Assembly

**Parameters:**
- `client` (Client, required) - Client with complete profile, training evaluation, and history.
- `exercises` (List<Exercise>, required) - Available exercise catalog filtered by equipment.
- `asOfDate` (DateTime?, optional) - Reference date for plan start. Defaults to `DateTime.now()`.
- `recordPrediction` (bool, optional) - Whether to log prediction to Firestore for ML training. Default: `true`.

**Returns:**  
- `Future<TrainingProgramV3Result>` containing:
  - `plan`: 4-week training plan (null if blocked)
  - `volumeDecision`: Volume adjustment factor (0.7-1.3x)
  - `readinessDecision`: Readiness level and score
  - `mlExampleId`: Tracking ID for outcome collection
  - `blockedReason`: Explanation if plan was blocked
  - `features`: All 38 engineered features
  - `strategyUsed`: Name of decision strategy used
  - `decisions`: Full decision trace for explainability

**Throws:**
- `InsufficientDataError` - If client profile is incomplete.
- `FirebaseException` - If Firestore is unavailable (non-fatal, continues without ML logging).

**Example:**
```dart
final result = await engine.generatePlan(
  client: myClient,
  exercises: exerciseCatalog,
  asOfDate: DateTime(2026, 2, 1),
  recordPrediction: true,
);

if (result.isBlocked) {
  print('Plan blocked: ${result.blockedReason}');
  print('Recommendations: ${result.readinessDecision.recommendations.join(", ")}');
} else {
  print('Plan generated successfully!');
  print('Volume adjustment: ${result.volumeDecision.adjustmentFactor}x');
  print('Total weeks: ${result.plan!.weeks.length}');
  
  // Save plan to repository
  await planRepository.savePlan(result.plan!);
  
  // Optionally show outcome feedback dialog after 4 weeks
  if (result.mlExampleId != null) {
    // Display MLOutcomeFeedbackDialog with mlExampleId
  }
}
```

---

## Decision Strategies

### DecisionStrategy (Interface)

**File**: `lib/domain/training_v3/ml/decision_strategy.dart`

Abstract interface for decision-making strategies in Motor V3.

#### Properties

```dart
String get name;              // Strategy identifier (e.g., "RuleBased_Israetel_v1")
String get version;           // Semantic version (e.g., "1.1.0")
bool get isTrainable;         // true if ML-based, false if rule-based
```

#### Methods

##### `decideVolume()`

```dart
VolumeDecision decideVolume(FeatureVector features);
```

Determines optimal volume adjustment factor based on client features.

**Parameters:**
- `features` (FeatureVector) - 38 normalized features.

**Returns:**  
- `VolumeDecision` with adjustment factor (0.7-1.3x), confidence, and reasoning.

---

##### `decideReadiness()`

```dart
ReadinessDecision decideReadiness(FeatureVector features);
```

Assesses client readiness to train and recommends actions.

**Parameters:**
- `features` (FeatureVector) - 38 normalized features.

**Returns:**  
- `ReadinessDecision` with level (critical/poor/fair/good/excellent), score, and recommendations.

---

### RuleBasedStrategy

**File**: `lib/domain/training_v3/ml/strategies/rule_based_strategy.dart`

100% rule-based strategy using Israetel, Schoenfeld, and Helms frameworks.

#### Properties

```dart
String get name => 'RuleBased_Israetel_Schoenfeld_Helms';
String get version => '1.1.0';
bool get isTrainable => false;
```

#### Decision Rules

**Volume Decision Logic:**

1. **Deload Detection** (Priority 1)
   ```dart
   if (fatigueIndex > 0.65 && readinessScore < 0.5) {
     return VolumeDecision.deload(factor: 0.7, reasoning: 'High fatigue detected');
   }
   ```

2. **Overreaching Risk** (Priority 2)
   ```dart
   if (overreachingRisk > 0.6) {
     return VolumeDecision.deload(factor: 0.8, reasoning: 'Overreaching risk');
   }
   ```

3. **Progressive Overload** (Priority 3)
   ```dart
   if (readinessScore > 0.75 && volumeOptimalityIndex < 0.8) {
     return VolumeDecision.progress(factor: 1.1, reasoning: 'Ready for more volume');
   }
   ```

4. **Maintenance** (Default)
   ```dart
   return VolumeDecision.maintain(reasoning: 'Balanced state');
   ```

**Readiness Decision Logic:**

| Readiness Score | Level | Needs Deload |
|-----------------|-------|--------------|
| 0.0 - 0.4 | CRITICAL | Yes |
| 0.4 - 0.6 | POOR | Yes |
| 0.6 - 0.7 | FAIR | No (conservative mode) |
| 0.7 - 0.85 | GOOD | No |
| 0.85 - 1.0 | EXCELLENT | No |

**Example:**
```dart
final strategy = RuleBasedStrategy();
final features = FeatureVector.fromContext(context);

final volumeDecision = strategy.decideVolume(features);
print('Adjustment: ${volumeDecision.adjustmentFactor}x');
print('Reasoning: ${volumeDecision.reasoning}');

final readinessDecision = strategy.decideReadiness(features);
print('Readiness: ${readinessDecision.level.name}');
print('Score: ${readinessDecision.score}');
print('Recommendations: ${readinessDecision.recommendations}');
```

---

### HybridStrategy

**File**: `lib/domain/training_v3/ml/strategies/hybrid_strategy.dart`

Blends rule-based decisions (70%) with ML predictions (30%).

#### Constructor

```dart
HybridStrategy({
  MLModelStrategy? mlModel,
  double mlWeight = 0.3,
})
```

**Parameters:**
- `mlModel` (MLModelStrategy?, optional) - ML prediction service. Falls back to 100% rules if null.
- `mlWeight` (double, optional) - ML weight [0.0, 1.0]. Default: 0.3.

#### Properties

```dart
String get name => 'Hybrid_${(1 - mlWeight) * 100}R${mlWeight * 100}ML';
String get version => '1.0.0';
bool get isTrainable => true;
```

#### Decision Logic

```dart
final ruleDecision = _ruleBasedStrategy.decideVolume(features);
final mlDecision = _mlModel?.decideVolume(features);

if (mlDecision == null) {
  return ruleDecision; // Fallback to 100% rules
}

final blendedFactor = 
  (ruleDecision.adjustmentFactor * (1 - mlWeight)) +
  (mlDecision.adjustmentFactor * mlWeight);

return VolumeDecision(
  adjustmentFactor: blendedFactor,
  confidence: min(ruleDecision.confidence, mlDecision.confidence),
  reasoning: 'Hybrid: ${ruleDecision.reasoning} + ML prediction',
);
```

**Example:**
```dart
final hybrid = HybridStrategy(
  mlModel: MLModelStrategy(endpoint: 'https://api.hefestcs.com/ml/predict'),
  mlWeight: 0.4, // 40% ML, 60% rules
);

final decision = await hybrid.decideVolume(features);
// decision.adjustmentFactor = (ruleAdjustment * 0.6) + (mlAdjustment * 0.4)
```

---

## Feature Engineering

### FeatureVector

**File**: `lib/domain/training_v3/ml/feature_vector.dart`

Contains 38 normalized features (0.0-1.0) for ML predictions and rule-based decisions.

#### Feature Categories

##### Demographics (5 features)

```dart
final double ageYearsNorm;           // (age - 18) / (80 - 18)
final double genderMaleEncoded;      // 1.0 = male, 0.0 = female
final double heightCmNorm;           // (height - 140) / (220 - 140)
final double weightKgNorm;           // (weight - 40) / (160 - 40)
final double bmiNorm;                // (bmi - 15) / (40 - 15)
```

##### Experience (3 features)

```dart
final double yearsTrainingNorm;      // (years - 0) / (30 - 0)
final double consecutiveWeeksNorm;   // (weeks - 0) / (52 - 0)
final double trainingLevelEncoded;   // beginner: 0.2, intermediate: 0.5, advanced: 0.8
```

##### Volume (4 features)

```dart
final double avgWeeklySetsNorm;      // (sets - 0) / (30 - 0) per muscle
final double maxSetsTolerance;       // Max sets before overreaching
final double volumeToleranceScore;   // avgSets / (yearsTraining + 1)
final double volumeOptimalityScore;  // avgSets / MEV_for_level
```

##### Recovery (6 features)

```dart
final double avgSleepHoursNorm;      // (sleep - 4) / (12 - 4)
final double perceivedRecoveryNorm;  // (PRS - 1) / (10 - 1)
final double stressLevelNorm;        // (stress - 0) / (10 - 0)
final double soreness48hNorm;        // (DOMS - 0) / (10 - 0)
final double sessionDurationNorm;    // (duration - 30) / (120 - 30)
final double restBetweenSetsNorm;    // (rest - 30) / (300 - 30)
```

##### Intensity (3 features)

```dart
final double averageRIRNorm;         // (RIR - 0) / (5 - 0)
final double averageSessionRPENorm;  // (RPE - 1) / (10 - 1)
final double rirOptimalityScore;     // 1.0 if RIR = 2-3, else <1.0
```

##### Optimization (2 features)

```dart
final double deloadFrequencyNorm;    // (weeks - 0) / (12 - 0)
final double periodBreaksNorm;       // (breaks - 0) / (6 - 0)
```

##### Longitudinal (3 features)

```dart
final double adherenceHistorical;   // 0.0-1.0 (completion rate)
final double performanceTrendEncoded;// improving: 1.0, plateau: 0.5, declining: 0.0
```

##### Objectives (8 features, one-hot encoded)

```dart
final Map<String, double> goalOneHot;
// {'hypertrophy': 1.0, 'strength': 0.0, 'endurance': 0.0, 'general': 0.0}

final Map<String, double> focusOneHot;
// {'hypertrophy': 1.0, 'strength': 0.0, 'power': 0.0, 'mixed': 0.0}
```

##### Derived Features (6 features)

```dart
final double fatigueIndex;
// Formula: (10 - perceivedRecoveryStatus) * averageSessionRPE / 100
// Range: 0.0-1.0 (higher = more fatigued)
// Threshold: >0.65 = high fatigue

final double recoveryCapacity;
// Formula: avgSleepHoursNorm * (1 - stressLevelNorm) * perceivedRecoveryNorm
// Range: 0.0-1.0 (higher = better recovery)
// Threshold: >0.7 = good recovery

final double trainingMaturity;
// Formula: yearsTraining * (consecutiveWeeks / 52)
// Range: 0.0-30.0 (higher = more mature)
// Threshold: >3.0 = mature trainee

final double overreachingRisk;
// Formula: (avgWeeklySets / maxSetsTolerated) * fatigueIndex
// Range: 0.0-1.0 (higher = higher risk)
// Threshold: >0.6 = high risk

final double readinessScore;
// Formula: 0.30 * sleepNorm +
//          0.25 * (1 - fatigueIndex) +
//          0.20 * perceivedRecoveryNorm +
//          0.15 * (1 - stressNorm) +
//          0.10 * (1 - sorenessNorm)
// Range: 0.0-1.0
// Thresholds: <0.4 critical, 0.4-0.6 poor, 0.6-0.7 fair, 0.7-0.85 good, >0.85 excellent

final double volumeOptimalityIndex;
// Formula: avgWeeklySets / MEV_for_training_level
// Range: 0.0-4.0
// Interpretation: 1.0 = MEV, 2.0 = MAV, 3.0 = MRV
```

#### Constructors

##### `FeatureVector()`

```dart
const FeatureVector({
  required double ageYearsNorm,
  required double genderMaleEncoded,
  // ... all 38 parameters
});
```

Manual constructor requiring all 38 features.

---

##### `FeatureVector.fromContext()`

```dart
factory FeatureVector.fromContext(
  TrainingContextV2 context, {
  required String clientId,
  double? historicalAdherence,
})
```

Builds FeatureVector from TrainingContextV2 with automatic normalization.

**Parameters:**
- `context` (TrainingContextV2) - Complete training context.
- `clientId` (String) - Client identifier.
- `historicalAdherence` (double?, optional) - Override adherence rate.

**Returns:**  
- `FeatureVector` with all 38 features normalized to [0.0, 1.0].

**Example:**
```dart
final context = TrainingContextV2(
  athlete: AthleteSnapshot(
    ageYears: 28,
    gender: Gender.male,
    heightCm: 175,
    weightKg: 80,
  ),
  interview: TrainingInterviewSnapshot(
    avgSleepHours: 7.5,
    perceivedRecoveryStatus: 8,
    avgWeeklySetsPerMuscle: 16,
    // ... other fields
  ),
  // ... other snapshots
);

final features = FeatureVector.fromContext(
  context,
  clientId: 'client_123',
);
---

##### `toTensor()`

```dart
List<double> toTensor()
```

Converts features to 38-element tensor for ML models.

**Returns:**  
- `List<double>` with 38 elements in fixed order.

**Example:**
```dart
final tensor = features.toTensor();
// [0.19, 1.0, 0.44, 0.50, 0.42, ...] (38 elements)

// Use for ML prediction
final prediction = await mlModel.predict(tensor);
```

---

##### `toJson()`

```dart
Map<String, dynamic> toJson()
```

Serializes features to structured JSON with categories.

**Returns:**  
- `Map<String, dynamic>` with 13 sections (demographics, experience, volume, etc.).

**Example:**
```dart
final json = features.toJson();
print(json);
// {
//   'demographics': {'ageYearsNorm': 0.19, 'genderMaleEncoded': 1.0, ...},
//   'experience': {'yearsTrainingNorm': 0.08, ...},
//   'derived': {'readinessScore': 0.75, 'fatigueIndex': 0.35, ...},
//   // ... 10 more categories
// }
```

#### Feature Importance (Scientific Weights)

```dart
static const Map<String, double> featureImportance = {
  'volumeOptimalityIndex': 1.00,    // #1 most important
  'readinessScore': 0.95,
  'overreachingRisk': 0.90,
  'fatigueIndex': 0.85,
  'recoveryCapacity': 0.80,
  'avgWeeklySetsNorm': 0.75,
  'perceivedRecoveryNorm': 0.70,
  'avgSleepHoursNorm': 0.65,
  // ... 30 more features
};
```

Use for feature selection in ML models.

---

## ML Dataset Service

### TrainingDatasetService

**File**: `lib/domain/training_v3/ml/training_dataset_service.dart`

Manages ML training dataset in Firestore for continuous learning.

#### Constructor

```dart
TrainingDatasetService({
  required FirebaseFirestore firestore,
})
```

**Parameters:**
- `firestore` (FirebaseFirestore) - Firestore instance.

**Firestore Collection**: `ml_training_data`

#### Methods

##### `recordPrediction()` **[NOT IMPLEMENTED]**

> ⚠️ **Note**: This method is currently commented out in the codebase because the `TrainingContext` class has not been implemented. This is part of a planned ML dataset feature that is incomplete.

```dart
// COMMENTED OUT - TrainingContext class not implemented
Future<String> recordPrediction({
  required String clientId,
  required TrainingContext context,
  required VolumeDecision volumeDecision,
  required ReadinessDecision readinessDecision,
  required String strategyUsed,
})
```

~~Records prediction when a training plan is generated.~~

**Status**: Planned for future ML dataset feature

**Parameters:**
- `clientId` (String) - Client identifier.
- ~~`context` (TrainingContext) - Full context used for prediction.~~
- `volumeDecision` (VolumeDecision) - Volume adjustment decision.
- `readinessDecision` (ReadinessDecision) - Readiness assessment.
- `strategyUsed` (String) - Name of strategy (e.g., "RuleBased", "Hybrid").

**Returns:**  
- ~~`Future<String>` - Unique example ID (UUID v4) for tracking.~~

**Firestore Document Structure:**
```json
{
  "exampleId": "a1b2c3d4-e5f6-...",
  "clientId": "client_123",
  "timestamp": "2026-02-01T10:30:00Z",
  "features": {
    "demographics": {...},
    "experience": {...},
    "derived": {...}
  },
  "prediction": {
    "volumeAdjustmentFactor": 0.9,
    "volumeConfidence": 0.85,
    "readinessLevel": "good",
    "readinessScore": 0.72
  },
  "outcome": {
    "hasOutcome": false
  },
  "strategyUsed": "RuleBased",
  "schemaVersion": 2
}
```

**Example:**
```dart
final exampleId = await datasetService.recordPrediction(
  clientId: client.id,
  context: trainingContext,
  volumeDecision: volumeDecision,
  readinessDecision: readinessDecision,
  strategyUsed: 'RuleBased',
);

print('Prediction logged with ID: $exampleId');
// Store exampleId in plan metadata for later outcome collection
```

---

##### `recordOutcome()`

```dart
Future<void> recordOutcome({
  required String exampleId,
  required double adherence,
  required double fatigue,
  double? progress,
  bool? injury,
  bool? tooHard,
  bool? tooEasy,
})
```

Records actual outcomes 3-4 weeks after plan execution.

**Parameters:**
- `exampleId` (String, required) - Example ID from `recordPrediction()`.
- `adherence` (double, required) - Adherence rate 0.0-1.0 (0-100%).
- `fatigue` (double, required) - Average fatigue level 1-10.
- `progress` (double?, optional) - Performance delta (kg or reps gained).
- `injury` (bool?, optional) - Whether injury occurred.
- `tooHard` (bool?, optional) - User feedback: plan too difficult.
- `tooEasy` (bool?, optional) - User feedback: plan too easy.

**Updates Firestore:**
```json
{
  "outcome": {
    "hasOutcome": true,
    "adherence": 0.90,
    "fatigue": 5.5,
    "progress": 2.5,
    "injury": false,
    "tooHard": false,
    "tooEasy": false,
    "submittedAt": "2026-02-28T15:45:00Z"
  }
}
```

**Example:**
```dart
// 4 weeks later, collect outcome via dialog
await datasetService.recordOutcome(
  exampleId: plan.mlExampleId!,
  adherence: 0.88,      // 88% adherence
  fatigue: 6.0,         // Moderate fatigue
  progress: 3.5,        // +3.5 kg on key lifts
  injury: false,
  tooHard: false,
  tooEasy: false,
);

print('Outcome recorded successfully');
```

---

##### `exportDataset()`

```dart
Future<List<TrainingExample>> exportDataset({
  DateTime? startDate,
  DateTime? endDate,
  int? limit,
  bool onlyWithLabels = true,
})
```

Exports dataset for offline ML training.

**Parameters:**
- `startDate` (DateTime?, optional) - Filter start date.
- `endDate` (DateTime?, optional) - Filter end date.
- `limit` (int?, optional) - Max examples to fetch.
- `onlyWithLabels` (bool, optional) - Only include examples with outcomes. Default: `true`.

**Returns:**  
- `Future<List<TrainingExample>>` - List of training examples with features + outcomes.

**Example:**
```dart
final dataset = await datasetService.exportDataset(
  startDate: DateTime(2026, 1, 1),
  endDate: DateTime(2026, 12, 31),
  limit: 1000,
  onlyWithLabels: true,
);

print('Exported ${dataset.length} examples');

// Train ML model offline
final model = await trainGradientBoosting(dataset);
```

---

##### `exportToCSV()`

```dart
Future<String> exportToCSV({
  DateTime? startDate,
  DateTime? endDate,
})
```

Exports dataset to CSV format for analysis in Python/R.

**Parameters:**
- `startDate` (DateTime?, optional) - Filter start date.
- `endDate` (DateTime?, optional) - Filter end date.

**Returns:**  
- `Future<String>` - CSV string with headers.

**CSV Format:**
```csv
exampleId,clientId,timestamp,ageYearsNorm,genderMaleEncoded,...,volumeAdjustment,readinessLevel,adherence,fatigue,progress
a1b2c3...,client_1,2026-02-01,0.19,1.0,...,0.9,good,0.88,5.5,3.5
```

**Example:**
```dart
final csv = await datasetService.exportToCSV(
  startDate: DateTime(2026, 1, 1),
);

// Save to file
final file = File('training_data_2026.csv');
await file.writeAsString(csv);
print('CSV exported to ${file.path}');
```

---

##### `getDatasetStats()`

```dart
Future<Map<String, dynamic>> getDatasetStats()
```

Returns statistics about the ML dataset.

**Returns:**  
- `Future<Map<String, dynamic>>` with keys:
  - `totalExamples`: Total predictions logged
  - `withOutcome`: Examples with outcome data
  - `withLabels`: Examples with computed labels
  - `averageAdherence`: Mean adherence across all outcomes
  - `averageFatigue`: Mean fatigue level
  - `injuryRate`: % of outcomes with injury
  - `datasetQuality`: Quality score [0.0-1.0]

**Example:**
```dart
final stats = await datasetService.getDatasetStats();

print('Total examples: ${stats['totalExamples']}');
print('With outcomes: ${stats['withOutcome']}');
print('Dataset quality: ${stats['datasetQuality']}');

if (stats['totalExamples'] >= 500) {
  print('Ready to train ML model!');
}
```

---

## Model Classes

### VolumeDecision

**File**: `lib/domain/training_v3/models/volume_decision.dart`

Represents volume adjustment decision from strategy.

#### Properties

```dart
final double adjustmentFactor;    // 0.5-1.3 (multiplier for base volume)
final double confidence;          // 0.0-1.0 (strategy confidence)
final String reasoning;           // Human-readable explanation
final Map<String, dynamic> metadata; // Additional context
```

#### Constructors

##### `VolumeDecision()`

```dart
const VolumeDecision({
  required double adjustmentFactor,
  required double confidence,
  required String reasoning,
  Map<String, dynamic> metadata = const {},
})
```

---

##### `VolumeDecision.maintain()`

```dart
factory VolumeDecision.maintain({
  String? reasoning,
})
```

Creates decision to maintain current volume (factor = 1.0).

**Example:**
```dart
final decision = VolumeDecision.maintain(
  reasoning: 'Client in balanced state',
);
// decision.adjustmentFactor == 1.0
```

---

##### `VolumeDecision.deload()`

```dart
factory VolumeDecision.deload({
  required String reasoning,
  double factor = 0.7,
})
```

Creates decision to reduce volume (deload).

**Parameters:**
- `reasoning` (String, required) - Why deload is needed.
- `factor` (double, optional) - Deload factor [0.5-0.8]. Default: 0.7.

**Example:**
```dart
final decision = VolumeDecision.deload(
  reasoning: 'High fatigue index detected',
  factor: 0.6, // 40% volume reduction
);
```

---

##### `VolumeDecision.progress()`

```dart
factory VolumeDecision.progress({
  required String reasoning,
  double factor = 1.05,
})
```

Creates decision to increase volume (progressive overload).

**Parameters:**
- `reasoning` (String, required) - Why progress is warranted.
- `factor` (double, optional) - Progress factor [1.05-1.2]. Default: 1.05.

**Example:**
```dart
final decision = VolumeDecision.progress(
  reasoning: 'Excellent readiness, ready for more volume',
  factor: 1.1, // 10% volume increase
);
```

---

### ReadinessDecision

**File**: `lib/domain/training_v3/models/readiness_decision.dart`

Represents readiness assessment from strategy.

#### Enums

##### `ReadinessLevel`

```dart
enum ReadinessLevel {
  critical,   // Immediate deload required
  poor,       // Reduce training load
  fair,       // Conservative training
  good,       // Normal training
  excellent,  // Optimal volume possible
}
```

#### Properties

```dart
final ReadinessLevel level;                  // Categorical level
final double score;                          // 0.0-1.0 numerical score
final double confidence;                     // Strategy confidence
final List<String> recommendations;          // Actionable advice
final Map<String, dynamic> metadata;         // Additional context
```

#### Methods

##### `needsDeload`

```dart
bool get needsDeload => level == ReadinessLevel.critical || level == ReadinessLevel.poor;
```

Returns `true` if client needs deload (critical or poor readiness).

---

##### `needsVolumeReduction`

```dart
bool get needsVolumeReduction => level == ReadinessLevel.critical || 
                                  level == ReadinessLevel.poor ||
                                  level == ReadinessLevel.fair;
```

Returns `true` if volume should be reduced.

**Example:**
```dart
final decision = ReadinessDecision(
  level: ReadinessLevel.poor,
  score: 0.45,
  confidence: 0.80,
  recommendations: [
    'Increase sleep to 8+ hours',
    'Reduce stress through meditation',
    'Consider 50% volume deload this week',
  ],
);

if (decision.needsDeload) {
  print('Deload required!');
  print('Recommendations:');
  for (final rec in decision.recommendations) {
    print('- $rec');
  }
}
```

---

### TrainingProgramV3Result

**File**: `lib/domain/training_v3/models/training_program_v3_result.dart`

Complete result from `generatePlan()` with all decisions and metadata.

#### Properties

```dart
final TrainingPlanConfig? plan;              // 4-week plan (null if blocked)
final String? mlExampleId;                   // Firestore tracking ID
final VolumeDecision volumeDecision;         // Volume adjustment
final ReadinessDecision readinessDecision;   // Readiness assessment
final FeatureVector features;                // All 38 features
final String strategyUsed;                   // Strategy name
final List<DecisionTrace> decisions;         // Full decision log
final String? blockedReason;                 // Why plan was blocked (if applicable)
```

#### Methods

##### `isBlocked`

```dart
bool get isBlocked => plan == null;
```

Returns `true` if plan was blocked due to critical readiness.

---

##### `isSuccess`

```dart
bool get isSuccess => plan != null;
```

Returns `true` if plan was generated successfully.

**Example:**
```dart
final result = await engine.generatePlan(
  client: client,
  exercises: exercises,
);

if (result.isSuccess) {
  print('Plan created with ${result.plan!.weeks.length} weeks');
  print('Strategy: ${result.strategyUsed}');
  print('Volume adjustment: ${result.volumeDecision.adjustmentFactor}x');
  print('Readiness: ${result.readinessDecision.level.name}');
  
  // Access features
  print('Fatigue index: ${result.features.fatigueIndex}');
  print('Readiness score: ${result.features.readinessScore}');
  
  // Access decision trace
  for (final trace in result.decisions) {
    print('${trace.phase}: ${trace.reasoning}');
  }
} else {
  print('Plan blocked: ${result.blockedReason}');
  print('Readiness score: ${result.readinessDecision.score}');
  print('Recommendations:');
  for (final rec in result.readinessDecision.recommendations) {
    print('- $rec');
  }
}
```

---

## Validators

### ClinicalRestrictionValidator

**File**: `lib/domain/services/clinical_restriction_validator.dart`

Validates food items against clinical restrictions (P0 safety checks).

#### Methods

##### `isFoodAllowed()`

```dart
static bool isFoodAllowed({
  required String foodName,
  required ClinicalRestrictionProfile profile,
})
```

Checks if food is safe under clinical restrictions.

**Parameters:**
- `foodName` (String, required) - Name of food item.
- `profile` (ClinicalRestrictionProfile, required) - Client's restriction profile.

**Returns:**  
- `bool` - `true` if food is allowed, `false` if blocked.

**Blocking Conditions:**
1. **IgE-mediated allergies** (severe reactions)
2. **Dietary patterns** (vegan, vegetarian, pescatarian, etc.)
3. **Clinical conditions** (diabetes, hypertension, kidney disease, etc.)

**Example:**
```dart
final profile = ClinicalRestrictionProfile(
  allergies: [Allergy.shellfish, Allergy.nuts],
  dietaryPattern: DietaryPattern.vegetarian,
);

final canEatShrimp = ClinicalRestrictionValidator.isFoodAllowed(
  foodName: 'Shrimp',
  profile: profile,
);
print(canEatShrimp); // false (shellfish allergy + not vegetarian)

final canEatBroccoli = ClinicalRestrictionValidator.isFoodAllowed(
  foodName: 'Broccoli',
  profile: profile,
);
print(canEatBroccoli); // true
```

---

## Error Handling

### TrainingError Hierarchy

**File**: `lib/core/errors/training_errors.dart`

#### Base Class

```dart
sealed class TrainingError implements Exception {
  String get message;
}
```

#### Error Types

##### `InsufficientDataError`

```dart
class InsufficientDataError extends TrainingError {
  final List<String> missingFields;
  
  @override
  String get message => 'Missing required fields: ${missingFields.join(", ")}';
}
```

Thrown when client profile is incomplete.

**Example:**
```dart
try {
  final result = await engine.generatePlan(client: incompleteClient, ...);
} on InsufficientDataError catch (e) {
  print('Cannot generate plan: ${e.message}');
  print('Missing: ${e.missingFields}');
  // Show UI prompt to complete profile
}
```

---

##### `ReadinessCriticalError`

```dart
class ReadinessCriticalError extends TrainingError {
  final ReadinessDecision decision;
  
  @override
  String get message => 'Client readiness critical: ${decision.reasoning}';
}
```

Thrown when readiness is critical (not actually thrown, but returned in result).

---

##### `MLServiceUnavailableError`

```dart
class MLServiceUnavailableError extends TrainingError {
  @override
  String get message => 'ML prediction service unavailable, using fallback';
}
```

Logged (not thrown) when ML service is down, engine falls back to rules.

---

## Code Examples

### Example 1: Basic Program Generation

```dart
import 'package:hefestcs_app/domain/training_v3/engine/training_program_engine_v3.dart';

Future<void> generateBasicPlan() async {
  // Initialize engine
  final engine = TrainingProgramEngineV3.production(
    firestore: FirebaseFirestore.instance,
  );

  // Prepare client
  final client = Client(
    id: 'client_123',
    profile: ClientProfile(
      fullName: 'John Doe',
      trainingLevel: TrainingLevel.intermediate,
      trainingGoal: TrainingGoal.muscleGain,
      daysPerWeek: 4,
    ),
    trainingEvaluation: TrainingEvaluation(
      avgWeeklySets: 80,
      avgSleepHours: 7.5,
      perceivedRecoveryStatus: 7,
      stressLevel: 5,
      soreness48h: 4,
    ),
  );

  // Load exercises
  final exercises = await ExerciseCatalog.loadAll();

  // Generate plan
  final result = await engine.generatePlan(
    client: client,
    exercises: exercises,
  );

  // Handle result
  if (result.isSuccess) {
    print('✅ Plan generated successfully!');
    print('Weeks: ${result.plan!.weeks.length}');
    print('Volume adjustment: ${result.volumeDecision.adjustmentFactor}x');
    print('Readiness: ${result.readinessDecision.level.name}');
    
    // Save to repository
    await TrainingPlanRepository().savePlan(result.plan!);
  } else {
    print('❌ Plan blocked: ${result.blockedReason}');
  }
}
```

---

### Example 2: Collecting ML Outcomes

```dart
import 'package:hefestcs_app/domain/training_v3/ml/training_dataset_service.dart';

Future<void> collectOutcome(String mlExampleId) async {
  final datasetService = TrainingDatasetService(
    firestore: FirebaseFirestore.instance,
  );

  // Show dialog to user after 4 weeks
  final outcome = await showMLOutcomeFeedbackDialog(
    context: context,
    exampleId: mlExampleId,
  );

  // Record outcome
  await datasetService.recordOutcome(
    exampleId: mlExampleId,
    adherence: outcome.adherence / 100.0,  // 0.0-1.0
    fatigue: outcome.fatigue,              // 1-10
    progress: outcome.progressKg,          // kg gained
    injury: outcome.injuryOccurred,
    tooHard: outcome.wasTooHard,
    tooEasy: outcome.wasTooEasy,
  );

  print('Outcome recorded successfully');
}
```

---

### Example 3: Custom Strategy

```dart
import 'package:hefestcs_app/domain/training_v3/ml/decision_strategy.dart';

class ConservativeStrategy implements DecisionStrategy {
  @override
  String get name => 'Conservative';
  
  @override
  String get version => '1.0.0';
  
  @override
  bool get isTrainable => false;

  @override
  VolumeDecision decideVolume(FeatureVector features) {
    // Always reduce volume by 10% to be safe
    return VolumeDecision(
      adjustmentFactor: 0.9,
      confidence: 1.0,
      reasoning: 'Conservative approach: -10% volume',
    );
  }

  @override
  ReadinessDecision decideReadiness(FeatureVector features) {
    // Delegate to rule-based for readiness
    return RuleBasedStrategy().decideReadiness(features);
  }
}

// Use custom strategy
final engine = TrainingProgramEngineV3(
  strategy: ConservativeStrategy(),
);
```

---

### Example 4: Feature Analysis

```dart
import 'package:hefestcs_app/domain/training_v3/ml/feature_vector.dart';

Future<void> analyzeClientFeatures(Client client) async {
  final context = TrainingContextV2.fromClient(client);
  final features = FeatureVector.fromContext(context, clientId: client.id);

  // Print all features
  print('=== CLIENT FEATURE ANALYSIS ===');
  
  print('\nDemographics:');
  print('  Age: ${features.ageYearsNorm.toStringAsFixed(2)}');
  print('  Gender: ${features.genderMaleEncoded == 1.0 ? "Male" : "Female"}');
  print('  BMI: ${features.bmiNorm.toStringAsFixed(2)}');

  print('\nDerived Features:');
  print('  Readiness Score: ${features.readinessScore.toStringAsFixed(2)}');
  print('  Fatigue Index: ${features.fatigueIndex.toStringAsFixed(2)}');
  print('  Overreaching Risk: ${features.overreachingRisk.toStringAsFixed(2)}');
  print('  Recovery Capacity: ${features.recoveryCapacity.toStringAsFixed(2)}');

  // Check flags
  if (features.fatigueIndex > 0.65) {
    print('\n⚠️ WARNING: High fatigue detected');
  }
  
  if (features.overreachingRisk > 0.6) {
    print('\n⚠️ WARNING: High overreaching risk');
  }
  
  if (features.readinessScore < 0.5) {
    print('\n🚫 CRITICAL: Low readiness - deload recommended');
  }

  // Export to JSON
  final json = features.toJson();
  print('\nJSON Export:');
  print(jsonEncode(json));
}
```

---

### Example 5: Dataset Export for ML Training

```dart
import 'dart:io';
import 'package:hefestcs_app/domain/training_v3/ml/training_dataset_service.dart';

Future<void> exportDatasetForTraining() async {
  final service = TrainingDatasetService(
    firestore: FirebaseFirestore.instance,
  );

  // Check dataset stats
  final stats = await service.getDatasetStats();
  print('Total examples: ${stats['totalExamples']}');
  print('With outcomes: ${stats['withOutcome']}');

  if (stats['withOutcome'] < 500) {
    print('⚠️ Need at least 500 examples with outcomes for training');
    return;
  }

  // Export to CSV
  final csv = await service.exportToCSV(
    startDate: DateTime(2026, 1, 1),
    endDate: DateTime(2026, 12, 31),
  );

  // Save to file
  final file = File('ml_training_data_2026.csv');
  await file.writeAsString(csv);
  
  print('✅ Dataset exported to ${file.path}');
  print('   ${csv.split('\n').length - 1} examples');

  // Alternative: Export as JSON for Python
  final dataset = await service.exportDataset(onlyWithLabels: true);
  final jsonFile = File('ml_training_data_2026.json');
  await jsonFile.writeAsString(jsonEncode(dataset.map((e) => e.toJson()).toList()));
  
  print('✅ JSON export: ${jsonFile.path}');
}
```

---

## Additional Resources

- **[User Guide](user-guide.md)** - For end-users and coaches
- **[Developer Guide](developer-guide.md)** - For extending Motor V3
- **[Architecture](architecture.md)** - System design overview
- **[Scientific Foundation](../scientific-foundation/)** - 7 Semanas evidence

For API support: dev@hefestcs.com  
Report bugs: https://github.com/your-org/HefestCS_App_Lap/issues

---

**Version:** 3.0.0  
**Last Updated:** February 2026  
**Maintained by:** HefestCS Engineering Team
