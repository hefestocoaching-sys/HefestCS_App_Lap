# MOTOR DE ENTRENAMIENTO V3: ML-READY

## 📋 ÍNDICE

1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Arquitectura](#arquitectura)
3. [Componentes](#componentes)
4. [Pipeline de Generación](#pipeline-de-generación)
5. [Uso](#uso)
6. [ML Pipeline](#ml-pipeline)
7. [Testing](#testing)
8. [Referencias Científicas](#referencias-científicas)

---

## 🎯 RESUMEN EJECUTIVO

El **Training Program Engine V3** es un motor de generación de planes de entrenamiento que combina:

- ✅ **Ciencia del Entrenamiento** (Israetel/Schoenfeld/Helms)
- ✅ **Machine Learning** (Hybrid Strategy: Rules + ML)
- ✅ **Explicabilidad Total** (DecisionTrace en cada paso)
- ✅ **Producción-Ready** (Integración completa con Phases 3-7 legacy)

### Mejoras vs Motor Legacy

| Característica | Legacy | V3 |
|----------------|--------|-----|
| Decision Making | Hardcoded rules | Pluggable Strategy (Rules/ML/Hybrid) |
| ML Dataset | No existe | Firestore `ml_training_data` |
| Feature Engineering | N/A | 37 features científicas |
| Explicabilidad | Parcial | Completa (DecisionTrace) |
| Personalización | Estática | Adaptativa (aprende del cliente) |
| Context Schema | V1 (20 campos) | V2 (30 campos) |

---

## 🏗️ ARQUITECTURA

```
┌────────────────────────────────────────────────────────────────┐
│                  TRAINING PROGRAM ENGINE V3                     │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│  INPUT: Client + Exercises + asOfDate                          │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │ FASE 0: BUILD TRAINING CONTEXT V2                       │  │
│  │ - TrainingContextBuilder                                │  │
│  │ - Schema: 30 campos (athlete, meta, interview,          │  │
│  │           longitudinal, restrictions, equipment)         │  │
│  └─────────────────────────────────────────────────────────┘  │
│                          ↓                                      │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │ FASE 1: FEATURE ENGINEERING                             │  │
│  │ - FeatureVector.fromContext()                           │  │
│  │ - 37 features científicas normalizadas                  │  │
│  │ - Features derivadas: readinessScore, fatigueIndex,     │  │
│  │   overreachingRisk, volumeOptimalityIndex, etc.         │  │
│  └─────────────────────────────────────────────────────────┘  │
│                          ↓                                      │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │ FASE 2: DECISION MAKING (Pluggable Strategy)            │  │
│  │                                                          │  │
│  │ ┌──────────────────────────────────────────────────┐    │  │
│  │ │ DecisionStrategy (Interface)                     │    │  │
│  │ ├──────────────────────────────────────────────────┤    │  │
│  │ │ - decideVolume(features) → VolumeDecision       │    │  │
│  │ │ - decideReadiness(features) → ReadinessDecision │    │  │
│  │ │ - name, version                                  │    │  │
│  │ └──────────────────────────────────────────────────┘    │  │
│  │                ↓         ↓         ↓                      │  │
│  │    RuleBasedStrategy  HybridStrategy  MLStrategy         │  │
│  │         (100%)         (70% R + 30% ML)  (100% ML)       │  │
│  └─────────────────────────────────────────────────────────┘  │
│                          ↓                                      │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │ FASE 3: ML PREDICTION LOGGING                           │  │
│  │ - TrainingDatasetService.recordPrediction()             │  │
│  │ - Guarda en Firestore: ml_training_data                 │  │
│  │ - Campos: exampleId, clientId, timestamp, features,     │  │
│  │           volumeDecision, readinessDecision, strategy   │  │
│  └─────────────────────────────────────────────────────────┘  │
│                          ↓                                      │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │ FASE 4: READINESS VALIDATION (Gate)                     │  │
│  │ - if (readinessDecision.needsDeload) → BLOCK           │  │
│  │ - Retorna null plan + blockedReason                     │  │
│  └─────────────────────────────────────────────────────────┘  │
│                          ↓                                      │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │ FASE 5: PLAN GENERATION (Phases 3-7 Legacy)            │  │
│  │                                                          │  │
│  │ PHASE 3: Volume Capacity (Override con adjustmentFactor)│  │
│  │ PHASE 4: Split Distribution (readinessMode)            │  │
│  │ PHASE 5: Periodization (4 semanas: Acc → Int → Deload) │  │
│  │ PHASE 6: Exercise Selection (catálogo + equipo)        │  │
│  │ PHASE 7: Prescription (sets, reps, RIR, descanso)      │  │
│  └─────────────────────────────────────────────────────────┘  │
│                          ↓                                      │
│  OUTPUT: TrainingProgramV3Result                               │
│  - plan: TrainingPlanConfig (null si bloqueado)                │
│  - mlExampleId: String                                         │
│  - volumeDecision: VolumeDecision                              │
│  - readinessDecision: ReadinessDecision                        │
│  - features: FeatureVector                                     │
│  - strategyUsed: String                                        │
│  - decisions: List<DecisionTrace>                              │
│  - blockedReason: String?                                      │
│                                                                 │
└────────────────────────────────────────────────────────────────┘
```

---

## 🧩 COMPONENTES

### 1. TrainingProgramEngineV3

**Ubicación:** `lib/domain/training_v3/engine/training_program_engine_v3.dart`

**Responsabilidad:** Motor principal que orquesta todo el pipeline.

**Métodos públicos:**

```dart
// Factory para producción (RuleBased 100%)
TrainingProgramEngineV3.production({
  required FirebaseFirestore firestore,
});

// Factory para testing ML (Hybrid)
TrainingProgramEngineV3.hybrid({
  required FirebaseFirestore firestore,
  double mlWeight = 0.3, // 70% rules + 30% ML
});

// Genera plan completo
Future<TrainingProgramV3Result> generatePlan({
  required Client client,
  required List<Exercise> exercises,
  DateTime? asOfDate,
  bool recordPrediction = true, // Guardar en Firestore
});
```

### 2. DecisionStrategy (Pluggable)

**Ubicación:** `lib/domain/training_v3/ml/decision_strategy.dart`

**Implementaciones:**

- **RuleBasedStrategy:** Reglas científicas puras (Israetel, Schoenfeld, Helms)
- **HybridStrategy:** Combina Rules (70%) + ML (30%) con weighted averaging
- **MLStrategy:** (Futuro) 100% ML cuando el modelo esté entrenado

**Interface:**

```dart
abstract class DecisionStrategy {
  String get name;
  String get version;
  
  VolumeDecision decideVolume(FeatureVector features);
  ReadinessDecision decideReadiness(FeatureVector features);
}
```

### 3. FeatureVector (37 Features Científicas)

**Ubicación:** `lib/domain/training_v3/ml/feature_vector.dart`

**Categorías:**

| Categoría | Features | Ejemplos |
|-----------|----------|----------|
| **Demográficas** | 5 | age, gender, height, weight, BMI |
| **Experiencia** | 3 | yearsTraining, consecutiveWeeks, trainingLevel |
| **Volumen** | 4 | avgWeeklySets, maxSetsTolerated, volumeTolerance, volumeOptimality |
| **Recuperación** | 6 | avgSleepHours, perceivedRecovery, stress, soreness48h, recoveryCapacity |
| **Sesión** | 4 | sessionDuration, restBetweenSets, averageRIR, averageSessionRPE |
| **Optimización** | 2 | rirOptimalityScore, deloadFrequency |
| **Longitudinal** | 3 | periodBreaks, adherenceHistorical, performanceTrend |
| **Objetivos** | 2 | goalOneHot (4), focusOneHot (4) |
| **Derivadas** | 6 | fatigueIndex, trainingMaturity, overreachingRisk, readinessScore |

**Total:** 37 features normalizadas [0.0 - 1.0]

### 4. TrainingDatasetService

**Ubicación:** `lib/domain/training_v3/ml/training_dataset_service.dart`

**Responsabilidad:** Gestión del dataset ML en Firestore.

**Métodos:**

```dart
// Registra predicción inicial
Future<String> recordPrediction({
  required String clientId,
  required TrainingContext context,
  required VolumeDecision volumeDecision,
  required ReadinessDecision readinessDecision,
  required String strategyUsed,
});

// Registra outcome al finalizar plan
Future<void> recordOutcome({
  required String exampleId,
  required double adherence,
  required double fatigue,
  required double progress,
  bool injury = false,
  bool tooHard = false,
  bool tooEasy = false,
});
```

**Esquema Firestore:**

```typescript
ml_training_data {
  exampleId: string,
  clientId: string,
  timestamp: Timestamp,
  
  // Input features (37)
  features: {
    ageYearsNorm: number,
    genderMaleEncoded: number,
    // ... (35 más)
  },
  
  // Predicción (Volume + Readiness)
  prediction: {
    volumeAdjustmentFactor: number,
    volumeConfidence: number,
    readinessLevel: string,
    readinessScore: number,
    readinessConfidence: number,
  },
  
  // Outcome (llenado después)
  outcome: {
    hasOutcome: boolean,
    adherence: number,
    fatigue: number,
    progress: number,
    injury: boolean,
    tooHard: boolean,
    tooEasy: boolean,
    submittedAt: Timestamp,
  },
  
  // Metadata
  strategyUsed: string,
  contextSchemaVersion: string,
}
```

### 5. Providers (Riverpod)

**Ubicación:** `lib/features/training_feature/providers/training_engine_v3_provider.dart`

```dart
// Firestore instance
final firestoreProvider = Provider<FirebaseFirestore>(...);

// Dataset service
final trainingDatasetServiceProvider = Provider<TrainingDatasetService>(...);

// Strategy (configurable)
final decisionStrategyProvider = Provider<DecisionStrategy>(...);

// Engine principal
final trainingEngineV3Provider = Provider<TrainingProgramEngineV3>(...);

// State notifier para UI
final trainingPlanGenerationProvider = 
    StateNotifierProvider<TrainingPlanGenerationNotifier, 
                           TrainingPlanGenerationState>(...);
```

### 6. UI Widgets

**TrainingPlanGeneratorV3Button:**

- Botón para generar plan con Motor V3
- Muestra estrategia activa (Rules/Hybrid)
- Loading state, success/error feedback
- Dialog para planes bloqueados con métricas detalladas

**MLOutcomeFeedbackDialog:**

- Dialog para registrar outcome al finalizar plan
- Sliders: adherence (0-100%), fatigue (1-10), progress (-5 a +10)
- Checkboxes: injury, tooHard, tooEasy
- Guarda en Firestore vía `trainingDatasetService.recordOutcome()`

---

## 🔄 PIPELINE DE GENERACIÓN

### PASO 1: Construcción de Contexto

```dart
final contextBuilder = TrainingContextBuilder();
final contextResult = contextBuilder.build(
  client: client,
  asOfDate: referenceDate,
);

if (!contextResult.isOk) {
  return TrainingProgramV3Result(
    plan: null,
    blockedReason: 'Context build failed',
    // ...
  );
}

final context = contextResult.context!;
```

**TrainingContext V2 Schema:**

```dart
class TrainingContext {
  final String schemaVersion = '2.0.0';
  final AthleteInfo athlete;        // age, gender, weight, etc.
  final MetaInfo meta;              // goal, focus, level, days/week
  final InterviewInfo interview;    // sets, RIR, RPE, sleep, stress
  final LongitudinalInfo longitudinal; // adherence, performance trend
  final RestrictionsInfo restrictions; // injuries, contraindicaciones
  final EquipmentInfo equipment;    // available equipment
}
```

### PASO 2: Feature Engineering

```dart
final features = FeatureVector.fromContext(
  context,
  clientId: client.id,
  historicalAdherence: context.longitudinal.averageAdherence,
);
```

**Features Derivadas (Ejemplo):**

```dart
// Fatigue Index (0.0 = fresh, 1.0 = burnt out)
fatigueIndex = normalize(
  soreness48h * 0.3 +
  (1.0 - perceivedRecovery) * 0.4 +
  stressLevel * 0.2 +
  consecutiveWeeks * 0.1
);

// Readiness Score (0.0 = critical, 1.0 = optimal)
readinessScore = normalize(
  perceivedRecovery * 0.35 +
  avgSleepHours * 0.25 +
  (1.0 - fatigueIndex) * 0.25 +
  (1.0 - stressLevel) * 0.15
);

// Overreaching Risk (0.0 = safe, 1.0 = high risk)
overreachingRisk = normalize(
  volumeToleranceRatio * 0.35 +
  fatigueIndex * 0.30 +
  consecutiveWeeks * 0.20 +
  (1.0 - readinessScore) * 0.15
);
```

### PASO 3: Decision Making

**Volume Decision:**

```dart
final volumeDecision = strategy.decideVolume(features);

// VolumeDecision {
//   adjustmentFactor: 1.1,  // +10% volumen
//   confidence: 0.85,
//   reasoning: "Alta readiness (0.78) + bajo overreaching risk (0.23)"
// }
```

**Readiness Decision:**

```dart
final readinessDecision = strategy.decideReadiness(features);

// ReadinessDecision {
//   level: ReadinessLevel.high,
//   score: 0.78,
//   confidence: 0.92,
//   recommendations: ["Mantener volumen actual"],
//   needsDeload: false,
// }
```

### PASO 4: ML Logging

```dart
if (recordPrediction && _datasetService != null) {
  mlExampleId = await _datasetService!.recordPrediction(
    clientId: client.id,
    context: context,
    volumeDecision: volumeDecision,
    readinessDecision: readinessDecision,
    strategyUsed: _strategy.name,
  );
}
```

### PASO 5: Validation Gate

```dart
if (readinessDecision.needsDeload) {
  return TrainingProgramV3Result(
    plan: null,
    blockedReason: 'Readiness crítico: ${readinessDecision.level.name}',
    // ...
  );
}
```

### PASO 6: Phase 3-7 Integration

```dart
// PHASE 3: Volume Capacity (con adjustment factor)
final phase3Result = _phase3.calculateVolumeCapacity(
  profile: profile,
  readinessAdjustment: volumeDecision.adjustmentFactor,
);

// PHASE 4: Split Distribution
final phase4Result = _phase4.buildWeeklySplit(
  profile: profile,
  volumeByMuscle: adjustedVolumeLimits,
  readinessMode: readinessDecision.level == ReadinessLevel.high 
      ? 'normal' 
      : 'conservative',
);

// PHASE 5: Periodization
final phase5Result = _phase5.periodize(
  profile: profile,
  baseSplit: baseSplit,
);

// PHASE 6: Exercise Selection
final phase6Result = _phase6.selectExercises(
  profile: profile,
  baseSplit: baseSplit,
  catalog: exercises,
  weeks: periodizedWeeks.length,
);

// PHASE 7: Prescription
final phase7Result = _phase7.buildPrescriptions(
  baseSplit: baseSplit,
  periodization: phase5Result,
  selections: exerciseSelections,
  volumeLimitsByMuscle: adjustedVolumeLimits,
  trainingLevel: profile.trainingLevel,
  profile: profile,
);
```

### PASO 7: Assembly

```dart
final weeks = <TrainingWeek>[];

for (final periodizedWeek in periodizedWeeks) {
  final sessions = <TrainingSession>[];
  
  for (final dayNumber in sortedDays) {
    final session = TrainingSession(
      id: 'w${weekIndex}_d${dayNumber}_${timestamp}',
      dayNumber: dayNumber,
      sessionName: _buildSessionName(...),
      prescriptions: dayPrescriptions,
    );
    sessions.add(session);
  }
  
  final week = TrainingWeek(
    id: 'week_${weekIndex}_${phase.name}',
    weekNumber: weekIndex,
    phase: periodizedWeek.phase,
    sessions: sessions,
  );
  weeks.add(week);
}

final plan = TrainingPlanConfig(
  id: 'plan_v3_${timestamp}',
  name: 'Plan V3 - ${client.profile.fullName}',
  clientId: client.id,
  startDate: referenceDate,
  phase: periodizedWeeks.first.phase,
  splitId: baseSplit.splitId,
  microcycleLengthInWeeks: periodizedWeeks.length,
  weeks: weeks,
  trainingProfileSnapshot: profile,
);
```

---

## 💻 USO

### 1. Producción (RuleBased Strategy)

```dart
// En Provider
final decisionStrategyProvider = Provider<DecisionStrategy>((ref) {
  return RuleBasedStrategy(); // 100% científico
});

// Generar plan
ref.read(trainingPlanGenerationProvider.notifier).generatePlan(
  client: currentClient,
  exercises: exerciseCatalog,
);
```

### 2. Testing ML (Hybrid Strategy)

```dart
// En Provider
final decisionStrategyProvider = Provider<DecisionStrategy>((ref) {
  return HybridStrategy(mlWeight: 0.3); // 70% rules + 30% ML
});

// Generar plan
ref.read(trainingPlanGenerationProvider.notifier).generatePlan(
  client: currentClient,
  exercises: exerciseCatalog,
  recordPrediction: true, // ✅ Guardar en Firestore
);
```

### 3. Registrar Outcome

```dart
// Al finalizar plan (3-4 semanas después)
await ref.read(trainingDatasetServiceProvider).recordOutcome(
  exampleId: mlExampleId,
  adherence: 85.0,
  fatigue: 6.5,
  progress: 3.2,
  injury: false,
  tooHard: false,
  tooEasy: false,
);
```

---

## 🤖 ML PIPELINE

### Fase 1: Data Collection (Actual)

1. **Generación de Plan:**
   - Motor V3 genera plan
   - Guarda predicción en `ml_training_data`
   - exampleId se guarda en TrainingPlanConfig

2. **Registro de Outcome:**
   - Al finalizar plan, usuario completa MLOutcomeFeedbackDialog
   - Se actualiza documento con outcome
   - `hasOutcome: true` habilita el ejemplo para entrenamiento

### Fase 2: ML Model Training (Futuro)

**Dataset Schema:**

```python
# Input: 37 features normalizadas
X = [
    'ageYearsNorm', 'genderMaleEncoded', 'heightCmNorm', ...
]

# Output: 2 targets
y_volume = 'volumeAdjustmentFactor'  # Regresión [0.7 - 1.3]
y_readiness = 'readinessScore'       # Regresión [0.0 - 1.0]
```

**Modelo Propuesto:**

```python
from sklearn.ensemble import GradientBoostingRegressor

# Volume Model
volume_model = GradientBoostingRegressor(
    n_estimators=200,
    max_depth=6,
    learning_rate=0.05,
    subsample=0.8,
)

# Readiness Model
readiness_model = GradientBoostingRegressor(
    n_estimators=200,
    max_depth=6,
    learning_rate=0.05,
    subsample=0.8,
)
```

**Feature Importance:**

```python
import shap

explainer = shap.TreeExplainer(volume_model)
shap_values = explainer.shap_values(X_test)

# Top features esperados:
# 1. readinessScore
# 2. fatigueIndex
# 3. overreachingRisk
# 4. volumeOptimalityIndex
# 5. trainingMaturity
```

### Fase 3: Model Deployment

1. **Exportar Modelo:**
   ```python
   import joblib
   joblib.dump(volume_model, 'volume_model.pkl')
   joblib.dump(readiness_model, 'readiness_model.pkl')
   ```

2. **Servir vía Cloud Function:**
   ```javascript
   // Firebase Cloud Function
   exports.predictVolume = functions.https.onRequest(async (req, res) => {
     const features = req.body.features;
     const prediction = await mlService.predict(features);
     res.json(prediction);
   });
   ```

3. **Integrar en MLStrategy:**
   ```dart
   class MLStrategy implements DecisionStrategy {
     final String mlEndpoint = 'https://us-central1-PROJECT.cloudfunctions.net/predictVolume';
     
     @override
     Future<VolumeDecision> decideVolume(FeatureVector features) async {
       final response = await http.post(
         Uri.parse(mlEndpoint),
         body: jsonEncode({'features': features.toMap()}),
       );
       
       final prediction = jsonDecode(response.body);
       
       return VolumeDecision(
         adjustmentFactor: prediction['volumeFactor'],
         confidence: prediction['confidence'],
         reasoning: prediction['explanation'],
       );
     }
   }
   ```

---

## 🧪 TESTING

### Tests Unitarios

**PASO 6.1: Feature Engineering Tests**

```dart
// test/domain/training_v3/ml/feature_vector_test.dart
test('FeatureVector.fromContext normaliza correctamente', () {
  final context = TrainingContext(...);
  final features = FeatureVector.fromContext(context, clientId: 'test');
  
  expect(features.ageYearsNorm, inRange(0.0, 1.0));
  expect(features.readinessScore, inRange(0.0, 1.0));
  expect(features.fatigueIndex, inRange(0.0, 1.0));
});
```

**PASO 6.2: RuleBasedStrategy Tests**

```dart
// test/domain/training_v3/ml/strategies/rule_based_strategy_test.dart
test('RuleBasedStrategy: Alto readiness → +10% volumen', () {
  final strategy = RuleBasedStrategy();
  final features = FeatureVector(
    readinessScore: 0.8,
    fatigueIndex: 0.2,
    overreachingRisk: 0.15,
    // ...
  );
  
  final decision = strategy.decideVolume(features);
  
  expect(decision.adjustmentFactor, greaterThan(1.0));
  expect(decision.adjustmentFactor, lessThanOrEqualTo(1.15));
});

test('RuleBasedStrategy: Readiness crítico → Deload', () {
  final strategy = RuleBasedStrategy();
  final features = FeatureVector(
    readinessScore: 0.3,
    fatigueIndex: 0.8,
    overreachingRisk: 0.7,
    // ...
  );
  
  final decision = strategy.decideReadiness(features);
  
  expect(decision.needsDeload, isTrue);
  expect(decision.level, ReadinessLevel.critical);
});
```

**PASO 6.3: HybridStrategy Tests**

```dart
// test/domain/training_v3/ml/strategies/hybrid_strategy_test.dart
test('HybridStrategy combina Rules + ML con weighted averaging', () {
  final strategy = HybridStrategy(mlWeight: 0.3);
  final features = FeatureVector(...);
  
  final decision = strategy.decideVolume(features);
  
  // Debe estar entre decisión Rules y decisión ML
  expect(decision.adjustmentFactor, inRange(0.7, 1.3));
  expect(decision.reasoning, contains('Hybrid'));
});
```

**PASO 6.4: Engine Integration Tests**

```dart
// test/domain/training_v3/engine/training_program_engine_v3_test.dart
test('Engine V3 genera plan completo con Phases 3-7', () async {
  final engine = TrainingProgramEngineV3.production(
    firestore: MockFirebaseFirestore(),
  );
  
  final result = await engine.generatePlan(
    client: testClient,
    exercises: testExercises,
  );
  
  expect(result.plan, isNotNull);
  expect(result.plan!.weeks.length, greaterThan(0));
  expect(result.decisions.length, greaterThan(10));
});

test('Engine V3 bloquea si readiness crítico', () async {
  final engine = TrainingProgramEngineV3.production(
    firestore: MockFirebaseFirestore(),
  );
  
  final criticalClient = testClient.copyWith(
    trainingEvaluation: TrainingEvaluation(
      perceivedRecoveryStatus: 2, // Muy bajo
      soreness48h: 9,
      stressLevel: 8,
      avgSleepHours: 4.5,
    ),
  );
  
  final result = await engine.generatePlan(
    client: criticalClient,
    exercises: testExercises,
  );
  
  expect(result.isBlocked, isTrue);
  expect(result.blockedReason, contains('Readiness crítico'));
  expect(result.readinessDecision.needsDeload, isTrue);
});
```

### Tests de Integración

**PASO 6.5: Firestore Tests**

```dart
// test/domain/training_v3/ml/training_dataset_service_test.dart
test('TrainingDatasetService guarda predicción en Firestore', () async {
  final firestore = FakeFirebaseFirestore();
  final service = TrainingDatasetService(firestore: firestore);
  
  final exampleId = await service.recordPrediction(
    clientId: 'test_client',
    context: testContext,
    volumeDecision: testVolumeDecision,
    readinessDecision: testReadinessDecision,
    strategyUsed: 'RuleBased',
  );
  
  final doc = await firestore
      .collection('ml_training_data')
      .doc(exampleId)
      .get();
  
  expect(doc.exists, isTrue);
  expect(doc.data()!['clientId'], 'test_client');
  expect(doc.data()!['outcome']['hasOutcome'], isFalse);
});

test('TrainingDatasetService registra outcome correctamente', () async {
  final firestore = FakeFirebaseFirestore();
  final service = TrainingDatasetService(firestore: firestore);
  
  final exampleId = await service.recordPrediction(...);
  
  await service.recordOutcome(
    exampleId: exampleId,
    adherence: 85.0,
    fatigue: 6.5,
    progress: 3.2,
  );
  
  final doc = await firestore
      .collection('ml_training_data')
      .doc(exampleId)
      .get();
  
  expect(doc.data()!['outcome']['hasOutcome'], isTrue);
  expect(doc.data()!['outcome']['adherence'], 85.0);
});
```

### Widget Tests

**PASO 6.6: UI Tests**

```dart
// test/features/training_feature/widgets/training_plan_generator_v3_button_test.dart
testWidgets('TrainingPlanGeneratorV3Button muestra estrategia actual', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        decisionStrategyProvider.overrideWith((ref) => RuleBasedStrategy()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: TrainingPlanGeneratorV3Button(),
        ),
      ),
    ),
  );
  
  expect(find.text('RuleBased'), findsOneWidget);
});

testWidgets('TrainingPlanGeneratorV3Button muestra loading state', (tester) async {
  await tester.pumpWidget(...);
  
  await tester.tap(find.byType(ElevatedButton));
  await tester.pump();
  
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});
```

---

## 📚 REFERENCIAS CIENTÍFICAS

### Volume Progression

- **Israetel, M. et al.** (2017). *Scientific Principles of Hypertrophy Training*. Renaissance Periodization.
  - MEV (Minimum Effective Volume)
  - MAV (Maximum Adaptive Volume)
  - MRV (Maximum Recoverable Volume)

- **Schoenfeld, B. J. et al.** (2017). *Dose-response relationship between weekly resistance training volume and increases in muscle mass*. Journal of Sports Sciences, 35(11), 1073-1082.

### Readiness & Fatigue

- **Halson, S. L.** (2014). *Monitoring training load to understand fatigue in athletes*. Sports Medicine, 44(2), 139-147.

- **Kellmann, M. et al.** (2018). *Recovery and Performance in Sport: Consensus Statement*. International Journal of Sports Physiology and Performance, 13(2), 240-245.

### Periodization

- **Helms, E. et al.** (2018). *The Muscle and Strength Pyramid: Training*. Independently published.
  - Mesociclo: 3-6 semanas
  - Deload: 40-60% volumen cada 3-4 semanas

- **Stone, M. H. et al.** (2007). *Periodization strategies*. Strength & Conditioning Journal, 29(6), 50.

### RIR & RPE

- **Zourdos, M. C. et al.** (2016). *Novel Resistance Training-Specific Rating of Perceived Exertion Scale Measuring Repetitions in Reserve*. Journal of Strength and Conditioning Research, 30(1), 267-275.

---

## 📊 MÉTRICAS DE ÉXITO

### KPIs Motor V3

| Métrica | Target | Medición |
|---------|--------|----------|
| **Plan Success Rate** | > 95% | planes generados / intentos |
| **Block Rate (Readiness)** | < 5% | planes bloqueados / total |
| **Outcome Coverage** | > 70% | outcomes registrados / predicciones |
| **ML Dataset Size** | > 1000 | ejemplos con outcome en 6 meses |
| **Model Accuracy (R²)** | > 0.75 | correlación predicción-outcome |
| **Feature Importance** | Top 10 | features que explican > 80% varianza |

---

## 🚀 ROADMAP

### Q1 2026: MVP (✅ COMPLETADO)

- [x] TrainingProgramEngineV3 core
- [x] RuleBasedStrategy
- [x] HybridStrategy (mock ML)
- [x] FeatureVector (37 features)
- [x] TrainingDatasetService
- [x] Providers (Riverpod)
- [x] UI Widgets (V3 Button + ML Feedback Dialog)
- [x] Firestore indexes
- [x] Integration con Phases 3-7

### Q2 2026: ML Training

- [ ] Recolectar > 500 ejemplos con outcome
- [ ] Entrenar modelo Volume (GBR)
- [ ] Entrenar modelo Readiness (GBR)
- [ ] SHAP analysis (explicabilidad)
- [ ] Deploy Cloud Function
- [ ] Implementar MLStrategy

### Q3 2026: Optimización

- [ ] A/B Testing: RuleBased vs Hybrid vs ML
- [ ] Hyperparameter tuning
- [ ] Feature engineering v2
- [ ] Client-specific models (personalización)
- [ ] AutoML exploration

### Q4 2026: Production

- [ ] Migrar 100% a Motor V3
- [ ] Deprecar motor legacy
- [ ] Monitoring dashboard
- [ ] Alertas de drift
- [ ] Reentrenamiento automático

---

## 📝 CHANGELOG

### v3.0.0 (2026-02-01)

- ✅ Implementación completa Motor V3
- ✅ Integración Phases 3-7
- ✅ ML-ready pipeline (Firestore dataset)
- ✅ RuleBasedStrategy (producción)
- ✅ HybridStrategy (testing)
- ✅ 37 features científicas
- ✅ DecisionTrace completo
- ✅ UI widgets (V3 Button + Feedback Dialog)
- ✅ Firestore indexes
- ✅ Documentación completa

---

## 👥 CONTRIBUIDORES

- **Pedro** - Arquitectura, Implementación, Testing
- **GitHub Copilot (Claude Sonnet 4.5)** - Code Generation, Documentation

---

## 📄 LICENCIA

Propietario - HCS App LAP © 2026
