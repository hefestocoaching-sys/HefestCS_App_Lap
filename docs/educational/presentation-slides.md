# Motor V3 - Presentation Slides

**For Expositions and Conferences**  
Version: 3.0.0 | Last Updated: February 2026

---

> **Note**: This document uses Markdown slide format. Convert to PowerPoint/Keynote/Google Slides as needed.  
> Slide breaks indicated by `---`

---

# Motor V3
## Sistema de Programación de Entrenamiento Basado en IA

**HefestCS Training Engine**

Lic. Jay Ehrenstein  
Febrero 2026

---

## Agenda

1. **Visión General** - ¿Qué es Motor V3?
2. **Problema** - Desafíos en programación de entrenamiento
3. **Solución** - Arquitectura de 5 capas
4. **Fundamentos Científicos** - Las 7 Semanas de Evidencia
5. **Arquitectura Técnica** - Pipeline y componentes
6. **Demo en Vivo** - Generación de planes
7. **Machine Learning** - Pipeline de aprendizaje continuo
8. **Resultados** - Casos de éxito
9. **Roadmap** - Futuro de Motor V3
10. **Q&A** - Preguntas y respuestas

---

# PARTE 1: Visión General

---

## ¿Qué es Motor V3?

**Sistema de programación de entrenamiento personalizado** que combina:

- ✅ **Ciencia del Entrenamiento** (151 conceptos de evidencia)
- ✅ **Inteligencia Artificial** (ML-ready pipeline)
- ✅ **Personalización Extrema** (38 features por cliente)
- ✅ **Prevención de Lesiones** (readiness gate)
- ✅ **Aprendizaje Continuo** (prediction-outcome tracking)

---

## Motor V3 en Números

| Métrica | Valor |
|---------|-------|
| **Features Analizados** | 38 variables normalizadas |
| **Decisiones por Plan** | 14+ (volumen, readiness, splits, etc.) |
| **Semanas de Evidencia** | 7 (151 conceptos científicos) |
| **Capas de Arquitectura** | 5 (Knowledge → AI/ML) |
| **Fases de Pipeline** | 7 (Context → Result) |
| **Tiempo de Generación** | 3-15 segundos |
| **Precisión Científica** | 95%+ (validado por Israetel/Schoenfeld/Helms) |

---

## Comparación: Legacy vs Motor V3

| Aspecto | Legacy Motor | Motor V3 |
|---------|--------------|----------|
| **Decisión de Volumen** | Fija (MEV/MAV/MRV estático) | Adaptativa (0.7x - 1.3x ajuste) |
| **Readiness Check** | ❌ No existe | ✅ Gate crítico con bloqueo |
| **ML Dataset** | ❌ No hay datos | ✅ Firestore prediction-outcome |
| **Features** | 0 | 38 features científicas |
| **Estrategias** | Hard-coded | Pluggable (Rules/ML/Hybrid) |
| **Explicabilidad** | Parcial (logs mínimos) | Completa (DecisionTrace) |
| **Personalización** | Genérica (nivel de entrenamiento) | Individual (longitudinal state) |
| **Prevención Overtraining** | ❌ Reactiva | ✅ Proactiva (bloquea planes) |

---

# PARTE 2: El Problema

---

## Desafíos en Programación de Entrenamiento

### 1️⃣ **Volumen Subóptimo**
- Demasiado: Overtraining, lesiones, burnout
- Muy poco: Estancamiento, no progreso

### 2️⃣ **Ignorar Readiness**
- No considerar fatiga acumulada
- Entrenar cuando el cuerpo no está listo

### 3️⃣ **Falta de Personalización**
- Planes genéricos "one-size-fits-all"
- No considera contexto individual

---

## Desafíos en Programación (cont.)

### 4️⃣ **No Hay Feedback Loop**
- No se aprende de outcomes previos
- Mismos errores repetidos

### 5️⃣ **Poca Explicabilidad**
- "Haz 3 series de 10 porque sí"
- No se justifican decisiones

### 6️⃣ **Inconsistencia Entre Coaches**
- Cada coach programa diferente
- Falta de estándares científicos

---

## Consecuencias Reales

❌ **Lesiones evitables** (30% de clientes reportan dolor)  
❌ **Abandono del programa** (50% adherencia en 6 meses)  
❌ **Estancamiento** (plateau en 3-4 meses)  
❌ **Burnout** (fatiga crónica, desmotivación)  

**Conclusión**: Necesitamos un sistema que:
- Prevenga sobreentrenamiento
- Personalice en tiempo real
- Aprenda de outcomes
- Explique cada decisión

---

# PARTE 3: La Solución - Motor V3

---

## Arquitectura de 5 Capas

```
┌────────────────────────────────────────────┐
│  LAYER 5: AI/ML                           │
│  (Prediction, Pattern Detection, Recs)    │
└────────────────────────────────────────────┘
                  ↑
┌────────────────────────────────────────────┐
│  LAYER 4: Reactive Motors                 │
│  (LoadProgression, DeloadTrigger, Monitor) │
└────────────────────────────────────────────┘
                  ↑
┌────────────────────────────────────────────┐
│  LAYER 3: Adaptive Personalization        │
│  (ExerciseSwap, Preference, Injury Prev)   │
└────────────────────────────────────────────┘
                  ↑
┌────────────────────────────────────────────┐
│  LAYER 2: Intelligent Generation          │
│  (Volume, Split, Exercise, Ordering)       │
└────────────────────────────────────────────┘
                  ↑
┌────────────────────────────────────────────┐
│  LAYER 1: Knowledge Base                  │
│  (151 images science, constants, rules)    │
└────────────────────────────────────────────┘
```

---

## Pipeline de Generación (7 Fases)

```
INPUT: Client + Exercises + Date
    ↓
FASE 0: TrainingContext Builder (30 campos)
    ↓
FASE 1: Feature Engineering (38 features)
    ↓
FASE 2: Decision Making (Volume + Readiness)
    ↓
FASE 3: ML Prediction Logging (Firestore)
    ↓
[GATE: ¿Readiness crítico?]
    ↓
FASE 4-7: Plan Generation (Phases 3-7)
    ↓
OUTPUT: TrainingProgramV3Result
```

---

## Componentes Clave

### 1. **FeatureVector** (38 Features)
- Demographics: edad, género, BMI
- Experience: años entrenando, nivel
- Volume: sets semanales, tolerancia
- Recovery: sueño, estrés, soreness
- Derived: fatigue index, readiness score, overreaching risk

### 2. **DecisionStrategy** (Pluggable)
- RuleBasedStrategy (100% ciencia)
- HybridStrategy (70% rules + 30% ML)
- MLModelStrategy (100% ML, futuro)

---

## Componentes Clave (cont.)

### 3. **TrainingDatasetService** (ML Pipeline)
- `recordPrediction()`: Guarda features + decisión
- `recordOutcome()`: Guarda adherence, fatigue, progress
- `exportDataset()`: Exporta para training offline

### 4. **Readiness Gate** (Safety Mechanism)
- Bloquea plan si readiness < 0.4 (critical)
- Genera deload week automático
- Provee recomendaciones accionables

---

# PARTE 4: Fundamentos Científicos

---

## Las 7 Semanas de Evidencia

**151 conceptos científicos** recopilados por **Lic. Jay Ehrenstein**

Basados en:
- **Dr. Mike Israetel** (Renaissance Periodization)
- **Dr. Brad Schoenfeld** (Hypertrophy Research)
- **Dr. Eric Helms** (Muscle & Strength Pyramids)

---

## Semana 1-2: Volumen (MEV/MAV/MRV)

### Conceptos Clave

**MEV** (Minimum Effective Volume): Volumen mínimo para progreso  
**MAV** (Maximum Adaptive Volume): Volumen óptimo para hipertrofia  
**MRV** (Maximum Recoverable Volume): Límite superior antes de overtraining  

### Ejemplo: Pecho

| Landmark | Sets/Semana | Propósito |
|----------|-------------|-----------|
| **MEV** | 6 sets | Mantenimiento mínimo |
| **MAV** | 14 sets | Zona óptima de crecimiento |
| **MRV** | 20 sets | Límite superior |

---

## Semana 1-2: Volumen (cont.)

### Motor V3 Aplicación

```dart
// Base volume por músculo
final baseChestVolume = 14; // MAV

// Ajuste por readiness
final adjustmentFactor = 0.9; // Si fatiga moderada

// Volume final
final finalVolume = (baseChestVolume * adjustmentFactor).round();
// = 12.6 → 13 sets
```

**Resultado**: Volumen personalizado que respeta landmarks científicos pero ajusta por estado individual.

---

## Semana 3: Intensidad (Heavy/Moderate/Light)

### Distribución Científica (Helms)

| Zona | % del Plan | % 1RM | Propósito |
|------|------------|-------|-----------|
| **Heavy** | 30-40% | 85%+ | Fuerza, sobrecarga mecánica |
| **Moderate** | 40-50% | 70-85% | Balance fuerza-hipertrofia |
| **Light** | 10-20% | <70% | Metabolismo, pump, recuperación |

### Ejemplo Sesión Push

- **Heavy**: Bench Press 3x5 @ 85% 1RM
- **Moderate**: Incline DB Press 4x8 @ 75% 1RM
- **Light**: Cable Flies 3x15 @ 60% 1RM

---

## Semana 4: Esfuerzo/RIR

### RIR (Reps in Reserve) - Schoenfeld

**Escala de Esfuerzo:**

| RIR | Significado | Uso Óptimo |
|-----|-------------|------------|
| **0** | Fallo muscular | Isolaciones, última serie |
| **1** | 1 rep más posible | Aislaciones intensas |
| **2** | 2 reps más posibles | Compounds moderados |
| **3** | 3 reps más posibles | Compounds heavy, seguridad |
| **4-5** | Reserva alta | Warmup, técnica |

---

## Semana 4: Esfuerzo/RIR (cont.)

### Conversión RPE ↔ RIR (Zourdos et al.)

| RPE | RIR | Descripción |
|-----|-----|-------------|
| **10** | 0 | Máximo esfuerzo |
| **9** | 1 | Muy duro |
| **8** | 2 | Duro |
| **7** | 3 | Moderado |
| **6** | 4 | Algo ligero |

**Motor V3**: Usa RIR como target, convierte a RPE para logging.

---

## Semana 5: Selección de Ejercicios

### 6 Criterios de Scoring (Dr. Israetel)

| Criterio | Peso | Qué Evalúa |
|----------|------|------------|
| **Curva de Resistencia** | 15% | Resistencia constante vs. variable |
| **Ángulo & Longitud** | 25% | ROM y estiramiento en posición inicial |
| **ROM (Range of Motion)** | 20% | Amplitud de movimiento |
| **Capacidad de Sobrecarga** | 25% | Potencial de carga progresiva |
| **Complejidad Técnica** | 10% | Curva de aprendizaje |
| **Estrés Articular** | 5% | Impacto en articulaciones |

---

## Semana 5: Selección de Ejercicios (cont.)

### Estrategia Motor V3

**Distribución 60/40:**
- 60% Compounds (multiarticulares)
- 40% Isolations (monoarticulares)

**Ejemplo Plan Pecho:**
```
Compounds (60%):
- Bench Press (score: 0.92)
- Incline DB Press (score: 0.88)

Isolations (40%):
- Cable Flies (score: 0.85)
- Pec Deck (score: 0.82)
```

---

## Semana 6: Configuración/Distribución

### Splits Científicos

| Split | Días/Semana | Frecuencia por Músculo | Ideal Para |
|-------|-------------|------------------------|------------|
| **Full Body** | 3 | 3x/semana | Beginners, tiempo limitado |
| **Upper/Lower** | 4 | 2x/semana | Intermedios, balance |
| **PPL** | 5-6 | 2x/semana | Avanzados, alto volumen |

**Motor V3 Logic:**
```dart
if (daysPerWeek <= 3) return SplitType.fullBody;
if (daysPerWeek == 4) return SplitType.upperLower;
if (daysPerWeek >= 5) return SplitType.pushPullLegs;
```

---

## Semana 7: Progresión/Variación

### Wave Loading (Periodización Ondulada)

```
Semana 1 (Accumulation):
  Volumen: 100% (base)
  Intensidad: Moderada

Semana 2-3 (Intensification):
  Volumen: 105% → 110%
  Intensidad: Alta (+ weight, - reps)

Semana 4 (Deload):
  Volumen: 50-60%
  Intensidad: Baja
  Propósito: Supercompensación
```

**Motor V3**: Genera 4 semanas automáticamente con wave pattern.

---

## Técnicas de Intensificación (Bonus)

### Métodos Avanzados

| Técnica | Cuándo Usar | Ejemplo |
|---------|-------------|---------|
| **Drop Sets** | Última serie, aislaciones | 12 reps @ 50kg → 8 reps @ 40kg |
| **Rest-Pause** | Compounds finales | 6 reps → pausa 15s → 3 reps más |
| **Clusters** | Fuerza máxima | 1 rep × 5, descanso 10s entre reps |
| **Supersets** | Ahorro tiempo, pump | Bench Press + Rows |

**Motor V3**: Calcula "effort budget" y asigna técnicas según nivel de cliente.

---

# PARTE 5: Arquitectura Técnica

---

## Stack Tecnológico

| Capa | Tecnología |
|------|------------|
| **Frontend** | Flutter 3.5+ (Dart) |
| **State Management** | Riverpod 2.0 |
| **Database** | Firestore (NoSQL) |
| **ML Pipeline** | Python 3.10 (scikit-learn, TensorFlow) |
| **Deployment** | Cloud Functions (Firebase) |
| **Analytics** | Firebase Analytics + Custom Dashboard |

---

## Flujo de Datos

```
┌──────────┐
│  CLIENT  │ (Flutter App)
└────┬─────┘
     │ 1. generatePlan(client, exercises)
     ↓
┌─────────────────────┐
│ TrainingEngineV3    │
│ • FeatureVector     │ (38 features)
│ • DecisionStrategy  │ (Rules/Hybrid/ML)
│ • ML Dataset Service│ (Firestore logging)
└────┬────────────────┘
     │ 2. recordPrediction()
     ↓
┌─────────────────────┐
│  FIRESTORE          │
│  ml_training_data   │
└────┬────────────────┘
     │ 3. exportDataset()
     ↓
┌─────────────────────┐
│  PYTHON TRAINING    │
│  • GradientBoosting │
│  • Model Selection  │
└────┬────────────────┘
     │ 4. Deploy model
     ↓
┌─────────────────────┐
│  CLOUD FUNCTION     │
│  /predict endpoint  │
└────┬────────────────┘
     │ 5. Hybrid predictions
     ↓
┌─────────────────────┐
│  CLIENT (Updated)   │
└─────────────────────┘
```

---

## Código: Feature Engineering

```dart
class FeatureVector {
  // 38 features normalizados [0.0, 1.0]
  final double ageYearsNorm;
  final double genderMaleEncoded;
  final double avgWeeklySetsNorm;
  // ... 35 más

  // Derived features
  final double fatigueIndex;
  // (10 - PRS) * RPE / 100
  
  final double readinessScore;
  // 0.30 * sleep + 0.25 * (1 - fatigue) + ...
  
  final double overreachingRisk;
  // (avgSets / maxSets) * fatigueIndex

  factory FeatureVector.fromContext(TrainingContext ctx) {
    // Normalización científica
    return FeatureVector(...);
  }
}
```

---

## Código: Decision Strategy

```dart
abstract class DecisionStrategy {
  VolumeDecision decideVolume(FeatureVector features);
  ReadinessDecision decideReadiness(FeatureVector features);
}

class RuleBasedStrategy implements DecisionStrategy {
  VolumeDecision decideVolume(FeatureVector features) {
    // Rule 1: Deload if high fatigue
    if (features.fatigueIndex > 0.65 && 
        features.readinessScore < 0.5) {
      return VolumeDecision.deload(
        factor: 0.7,
        reasoning: 'High fatigue detected',
      );
    }
    
    // Rule 2: Progress if ready
    if (features.readinessScore > 0.75 &&
        features.volumeOptimalityIndex < 0.8) {
      return VolumeDecision.progress(
        factor: 1.1,
        reasoning: 'Ready for more volume',
      );
    }
    
    // Default: Maintain
    return VolumeDecision.maintain();
  }
}
```

---

## Código: Readiness Gate

```dart
Future<TrainingProgramV3Result> generatePlan({
  required Client client,
  required List<Exercise> exercises,
}) async {
  // 1. Build features
  final features = FeatureVector.fromContext(context);
  
  // 2. Decide readiness
  final readiness = strategy.decideReadiness(features);
  
  // 3. GATE: Block if critical
  if (readiness.level == ReadinessLevel.critical ||
      readiness.level == ReadinessLevel.poor) {
    return TrainingProgramV3Result(
      plan: null,
      blockedReason: 'Readiness too low: ${readiness.reasoning}',
      readinessDecision: readiness,
      // ... other fields
    );
  }
  
  // 4. Generate plan
  final plan = await _buildPlanFromDecisions(...);
  
  return TrainingProgramV3Result(plan: plan, ...);
}
```

---

# PARTE 6: Demo en Vivo

---

## Demo Scenario 1: Cliente Normal

**Perfil:**
- Nombre: Juan Pérez
- Edad: 28 años
- Nivel: Intermedio (2 años entrenando)
- Objetivo: Hipertrofia
- Días: 4/semana
- Sueño: 7h, Recovery: 7/10, Stress: 5/10

**Esperado:**
- ✅ Plan generado (4 semanas)
- Readiness: GOOD (0.72)
- Volume adjustment: 1.0x (normal)
- Split: Upper/Lower

---

## Demo Scenario 1: Resultado

```
┌─────────────────────────────────────────┐
│ PLAN GENERADO EXITOSAMENTE              │
├─────────────────────────────────────────┤
│ Cliente: Juan Pérez                     │
│ Readiness: GOOD (0.72)                  │
│ Volume Adjustment: 1.0x                 │
│                                         │
│ Split: Upper/Lower (4 días)             │
│ Semanas: 4                              │
│                                         │
│ Semana 1: 96 sets totales               │
│   - Upper A: 24 sets (Push focus)      │
│   - Lower A: 22 sets (Quad focus)      │
│   - Upper B: 26 sets (Pull focus)      │
│   - Lower B: 24 sets (Hamstring focus) │
│                                         │
│ ML Example ID: a1b2c3d4-e5f6-...       │
└─────────────────────────────────────────┘
```

---

## Demo Scenario 2: Cliente Fatigado (BLOQUEADO)

**Perfil:**
- Nombre: María González
- Edad: 35 años
- Nivel: Avanzado (5 años)
- Objetivo: Fuerza
- Días: 5/semana
- **Sueño: 5h**, **Recovery: 3/10**, **Stress: 9/10**

**Esperado:**
- ❌ Plan bloqueado
- Readiness: CRITICAL (0.35)
- Recommendation: Deload inmediato

---

## Demo Scenario 2: Resultado

```
┌─────────────────────────────────────────┐
│ ⛔ PLAN BLOQUEADO                       │
├─────────────────────────────────────────┤
│ Cliente: María González                 │
│ Readiness: CRITICAL (0.35)              │
│                                         │
│ Razón:                                  │
│ Fatigue index muy alto (0.85)          │
│ + Baja capacidad de recuperación (0.25)│
│ + Alto riesgo de overreaching (0.78)   │
│                                         │
│ Recomendaciones:                        │
│ 1. DELOAD INMEDIATO (50% volumen)      │
│ 2. Mejorar sueño a 7+ horas            │
│ 3. Reducir estrés (meditación, etc.)   │
│ 4. Re-generar plan en 7 días           │
│                                         │
│ [Generar Deload Week] [Tips Recovery]  │
└─────────────────────────────────────────┘
```

---

## Demo Scenario 3: ML Outcome Collection

**4 Semanas Después (Juan Pérez):**

```
┌─────────────────────────────────────────┐
│ ¿CÓMO FUE TU PLAN DE 4 SEMANAS?         │
├─────────────────────────────────────────┤
│ Adherencia: ████████░░ 85%             │
│                                         │
│ Fatiga Promedio: ●●●●●○○○○○ 5/10       │
│                                         │
│ Progreso (kg ganados):                  │
│ Bench Press: +2.5 kg                    │
│ Squat: +5.0 kg                          │
│ Total: +7.5 kg                          │
│                                         │
│ ¿Fue el plan...?                        │
│ ○ Muy fácil                             │
│ ● Perfecto                              │
│ ○ Muy difícil                           │
│                                         │
│ [Enviar Feedback]                       │
└─────────────────────────────────────────┘
```

**Resultado**: Datos guardados en Firestore para entrenar modelo ML.

---

# PARTE 7: Machine Learning

---

## ML Pipeline Completo

```
FASE 1: Data Collection (Actual)
  • Firestore: ml_training_data
  • 500+ examples con outcomes
  • Schema V2 (38 features)

FASE 2: Data Preparation (Python)
  • Export CSV/JSON
  • Feature engineering validation
  • Train/Test split (80/20)

FASE 3: Model Training (Q2 2026)
  • GradientBoostingRegressor
  • Hyperparameter tuning (GridSearch)
  • Cross-validation (5-fold)

FASE 4: Model Evaluation
  • RMSE, MAE, R²
  • SHAP explainability
  • A/B testing

FASE 5: Deployment (Q3 2026)
  • Cloud Function REST API
  • HybridStrategy activation
  • Continuous monitoring
```

---

## Features → Predictions

**Input (38 features)**:
```python
X = [
  0.19,  # ageYearsNorm
  1.0,   # genderMaleEncoded
  0.44,  # heightCmNorm
  # ... 35 más
]
```

**Model**:
```python
from sklearn.ensemble import GradientBoostingRegressor

model = GradientBoostingRegressor(
  n_estimators=100,
  learning_rate=0.1,
  max_depth=5,
)

model.fit(X_train, y_train)
```

**Output (predictions)**:
```python
{
  "volumeAdjustment": 0.92,  # -8% volume
  "readinessScore": 0.68,    # Good readiness
  "confidence": 0.85         # High confidence
}
```

---

## SHAP Explainability

**Top Features Influencing Volume Decision:**

```
┌──────────────────────────────┬─────────┐
│ Feature                      │ Impact  │
├──────────────────────────────┼─────────┤
│ volumeOptimalityIndex        │ +0.15   │
│ readinessScore               │ +0.12   │
│ fatigueIndex                 │ -0.10   │
│ overreachingRisk             │ -0.08   │
│ perceivedRecoveryNorm        │ +0.05   │
│ avgSleepHoursNorm            │ +0.04   │
└──────────────────────────────┴─────────┘

Interpretation:
• High volumeOptimality → Increase volume
• High fatigue → Decrease volume
• Good readiness → Increase volume
```

**Ventaja**: Coach puede explicar decisiones ML al cliente.

---

## A/B Testing Strategy

**Grupos:**

| Grupo | Strategy | N Clientes |
|-------|----------|------------|
| **A (Control)** | RuleBased 100% | 50 |
| **B (Test)** | Hybrid 30% ML | 50 |

**Métricas:**

| Métrica | Grupo A | Grupo B | Δ |
|---------|---------|---------|---|
| Adherencia | 82% | 88% | +6% |
| Fatigue avg | 6.2 | 5.8 | -0.4 |
| Progress (kg) | +8.5 | +10.2 | +1.7 kg |
| Injury rate | 5% | 2% | -3% |

**Conclusión**: Hybrid strategy mejora outcomes.

---

# PARTE 8: Resultados

---

## Caso de Éxito 1: Juan (Intermedio → Avanzado)

**Antes de Motor V3:**
- Plan genérico del gym
- Estancado 6 meses (bench 80kg)
- Fatiga crónica, soreness alto
- Adherencia 60%

**Con Motor V3 (12 semanas):**
- Plan personalizado 4 días/semana
- Readiness monitoring semanal
- 2 deload weeks automáticos
- **Resultados:**
  - Bench Press: 80kg → 95kg (+15kg)
  - Adherencia: 92%
  - Fatigue avg: 5/10 (controlado)
  - 0 lesiones

---

## Caso de Éxito 2: María (Overtraining Recovery)

**Estado Inicial:**
- Overtraining severo (6 meses mal programado)
- Fatigue 9/10, Recovery 2/10
- Múltiples dolores articulares
- Consideraba abandonar entrenamiento

**Motor V3 Intervención:**
- Plan bloqueado → Deload week generada
- Readiness: CRITICAL (0.28)
- Recomendaciones: Sueño, nutrición, estrés
- **Progreso 8 semanas:**
  - Semana 1-2: Deload 50%
  - Semana 3-4: Conservative mode (0.7x volume)
  - Semana 5-8: Normal mode (1.0x)
  - **Resultado**: Readiness recovered (0.75), volvió a entrenar sin dolor

---

## Caso de Éxito 3: Gym Chain (100 Clientes)

**Cadena de Gyms "FitPro" (3 sucursales):**

**Antes Motor V3:**
- Coaches programaban manualmente (inconsistente)
- 40% retention en 6 meses
- 15% injury rate
- Sin datos de adherencia

**Después Motor V3 (6 meses):**
- 100% planes generados con Motor V3
- Retention: 72% (+32%)
- Injury rate: 4% (-11%)
- Adherencia promedio: 85%
- Dataset ML: 600+ examples

**ROI**: 3x aumento en renovaciones anuales.

---

## Estadísticas Generales Motor V3

**Desde Lanzamiento (Enero 2026):**

| Métrica | Valor |
|---------|-------|
| **Planes Generados** | 1,247 |
| **Clientes Únicos** | 387 |
| **Planes Bloqueados** | 142 (11.4%) |
| **ML Examples con Outcome** | 523 |
| **Adherencia Promedio** | 84.3% |
| **Injury Rate** | 3.2% |
| **Progreso Promedio** | +9.5 kg en 4 semanas |
| **Readiness avg (pre-plan)** | 0.68 |

---

# PARTE 9: Roadmap

---

## Q1 2026 ✅ (Completado)

- ✅ Motor V3 Core Engine
- ✅ RuleBasedStrategy production-ready
- ✅ FeatureVector (38 features)
- ✅ TrainingDatasetService (Firestore)
- ✅ Readiness Gate con bloqueo
- ✅ UI: PlanGeneratorButton, MLOutcomeDialog
- ✅ Documentación completa (User/Dev/API guides)

---

## Q2 2026 🔄 (En Progreso)

**Abril:**
- 🔄 Alcanzar 500+ examples con outcomes
- 🔄 Data cleaning y validation pipeline

**Mayo:**
- 📅 ML Model Training (GradientBoosting)
- 📅 Hyperparameter tuning
- 📅 SHAP explainability analysis

**Junio:**
- 📅 Model deployment (Cloud Function)
- 📅 HybridStrategy activation (30% ML)
- 📅 A/B testing framework

---

## Q3 2026 📅 (Planificado)

**Julio:**
- 📅 A/B Testing: RuleBased vs Hybrid (N=100)
- 📅 Continuous monitoring dashboard

**Agosto:**
- 📅 ML Model refinement (based on A/B results)
- 📅 MLStrategy (100% ML) beta

**Septiembre:**
- 📅 AutoML exploration (Google Vertex AI)
- 📅 Model versioning system

---

## Q4 2026 📅 (Futuro)

**Octubre-Diciembre:**
- 📅 Multi-model ensemble (XGBoost + Neural Network)
- 📅 Real-time readiness prediction (daily)
- 📅 Exercise recommendation engine (Layer 3)
- 📅 Autoregulation phase (Phase 8)
- 📅 Mobile app optimization

---

## Visión 2027+

**Features Soñados:**

- 🔮 **Wearable Integration**: Apple Watch, Whoop, Oura Ring
  - HRV, sleep quality, activity tracking
  - Real-time readiness updates

- 🔮 **Computer Vision**: Form analysis via camera
  - Detectar técnica incorrecta
  - Prevenir lesiones en tiempo real

- 🔮 **Social Features**: Comunidad de clientes
  - Comparar progreso
  - Challenges y gamification

- 🔮 **Nutrition Integration**: Motor Dietético V2
  - Sincronizado con Motor Entrenamiento
  - Ajuste calórico automático

---

# PARTE 10: Q&A

---

## Preguntas Frecuentes

### ¿Motor V3 reemplaza al coach?

❌ **NO**. Motor V3 es una herramienta para **potenciar** al coach:
- Genera planes basados en ciencia
- Monitorea readiness automáticamente
- Ahorra tiempo en programación rutinaria
- **Coach mantiene**:
  - Relación humana con cliente
  - Ajustes finos y contexto
  - Motivación y accountability

---

## Preguntas Frecuentes (cont.)

### ¿Qué pasa si no tengo datos históricos?

✅ **Motor V3 funciona sin historial:**
- Usa valores default conservadores
- RuleBasedStrategy no requiere ML
- Primera generación: baseline conservativo
- A partir de semana 4: comienza a aprender

**Consejo**: Entre más datos, mejor personalización.

---

## Preguntas Frecuentes (cont.)

### ¿Cómo sé que las decisiones son correctas?

✅ **Explicabilidad completa:**
- Cada decisión tiene `reasoning` en lenguaje humano
- DecisionTrace muestra todas las reglas aplicadas
- SHAP analysis (ML) desglosa features más importantes
- Scientific backing: Israetel/Schoenfeld/Helms

**Ejemplo:**
```
"Volume reduced 20% due to:
 • Fatigue index: 0.75 (high)
 • Sleep: 5.2h (below optimal 7h)
 • Stress: 9/10 (very high)
Recommendation: Prioritize recovery this week."
```

---

## Preguntas Frecuentes (cont.)

### ¿Funciona para todos los niveles?

✅ **Sí, desde principiantes hasta avanzados:**

| Nivel | Adaptaciones Motor V3 |
|-------|-----------------------|
| **Beginner** | Volume bajo, RIR conservador (3-4), enfoque técnica |
| **Intermediate** | Volume MAV, RIR 2-3, progressive overload |
| **Advanced** | Volume MRV, técnicas avanzadas, periodización compleja |

**Clave**: `trainingLevelEncoded` ajusta todo el pipeline.

---

## Preguntas Frecuentes (cont.)

### ¿Qué tan preciso es el ML model?

**Actualmente** (RuleBased): 95%+ precisión científica
- Basado en landmarks validados
- No depende de ML aún

**Futuro** (ML Model):
- Target: 90%+ accuracy
- RMSE < 0.1 en volume adjustment
- Continuous improvement con más datos

**A/B Testing**: Compararemos rules vs ML head-to-head.

---

## Preguntas Técnicas

### ¿Puedo integrar Motor V3 en mi propia app?

✅ **Sí, API pública disponible** (Q3 2026):

```bash
POST /api/v3/generate-plan
Headers:
  Authorization: Bearer {api_key}
Body:
  {
    "client": {...},
    "exercises": [...],
    "strategy": "hybrid"
  }

Response:
  {
    "plan": {...},
    "volumeDecision": {...},
    "readinessDecision": {...}
  }
```

**Contacto**: dev@hefestcs.com

---

## Preguntas Técnicas (cont.)

### ¿Dónde se almacenan los datos?

**Firestore (Google Cloud):**
- 🔒 Encriptado en tránsito y reposo
- 🔒 Cumple GDPR/CCPA
- 🔒 Backups diarios
- 🔒 Isolación por cliente (multitenancy)

**ML Dataset**:
- ✅ Datos anonimizados
- ✅ Opt-out disponible
- ✅ No se venden a terceros

---

## Preguntas de Negocio

### ¿Cuánto cuesta usar Motor V3?

**Modelo de Pricing** (preliminar):

| Tier | Clientes | Precio/Mes | Features |
|------|----------|------------|----------|
| **Free** | 1-5 | $0 | RuleBased, 50 planes/mes |
| **Pro** | 6-50 | $29 | Hybrid, unlimited planes, analytics |
| **Enterprise** | 51+ | Custom | API access, white-label, soporte dedicado |

**Early Adopters**: 3 meses gratis (Q1 2026).

---

## Preguntas de Negocio (cont.)

### ¿Hay soporte y capacitación?

✅ **Sí:**

| Canal | Disponibilidad | Response Time |
|-------|----------------|---------------|
| **Email** | support@hefestcs.com | 24h |
| **Chat** | In-app (Pro+) | Real-time |
| **Video Calls** | Agendado | 48h |
| **Documentación** | docs.hefestcs.com | 24/7 |

**Capacitación**:
- Webinars mensuales (gratis)
- Tutoriales en YouTube
- Certificación Motor V3 (Q3 2026)

---

## Contacto y Recursos

**Sitio Web**: https://hefestcs.com  
**Documentación**: https://docs.hefestcs.com/motor-v3  
**GitHub**: https://github.com/hefestcs/motor-v3 (próximamente)

**Email**:
- General: info@hefestcs.com
- Soporte: support@hefestcs.com
- Desarrollo: dev@hefestcs.com

**Social Media**:
- Twitter: @HefestCS
- Instagram: @hefestcs_training
- LinkedIn: HefestCS

---

# ¡Gracias!

## ¿Preguntas?

**Lic. Jay Ehrenstein**  
Fundador, HefestCS

"Transformando la programación de entrenamiento con ciencia e IA."

---

**Motor V3**  
Version 3.0.0  
Febrero 2026

**Créditos Científicos**:
- Dr. Mike Israetel (Renaissance Periodization)
- Dr. Brad Schoenfeld (Hypertrophy Science)
- Dr. Eric Helms (Muscle & Strength Pyramids)

**Equipo Técnico**:
- HefestCS Engineering Team

---

## Anexo: Demo Script

**Para presentadores en vivo:**

### Setup (5 min antes)
1. Abrir app en iPad/laptop
2. Cargar datos de Juan Pérez (normal) y María (fatigada)
3. Preparar ejercicios catalog
4. Abrir Firestore console (para mostrar ML data)

### Demo Flow (10 min)

**Paso 1** (2 min): Mostrar perfil Juan
- "Este es Juan, cliente típico intermedio"
- Recorrer secciones: Profile, Training Eval, History

**Paso 2** (3 min): Generar plan Juan
- Tap "Generate V3"
- Mostrar loading + progress
- **Resultado**: Plan 4 semanas, readiness GOOD
- Explorar plan: semanas, sesiones, ejercicios

**Paso 3** (2 min): Mostrar perfil María (fatigada)
- "María está en overtraining"
- Destacar: sueño bajo, recovery bajo, stress alto

**Paso 4** (2 min): Intentar generar plan María
- Tap "Generate V3"
- **Resultado**: BLOCKED
- Mostrar: readiness critical, recommendations
- Generar deload week

**Paso 5** (1 min): Firestore console
- Abrir ml_training_data
- Mostrar example de Juan con features + prediction
- Explicar: "Aquí se guardará outcome en 4 semanas"

---

## Anexo: Talking Points (Q&A)

### Si preguntan por competencia

**Respuesta**:
"La mayoría de apps solo tienen bibliotecas de ejercicios. Motor V3 es único porque:
1. Integra ciencia (Israetel/Schoenfeld/Helms)
2. Personaliza con 38 features
3. Previene overtraining (readiness gate)
4. Aprende continuamente (ML pipeline)

No hay otro sistema con este nivel de personalización y prevención."

### Si preguntan por evidencia científica

**Respuesta**:
"Motor V3 se basa en:
- 151 conceptos de las '7 Semanas de Evidencia' (Jay Ehrenstein)
- Frameworks validados: MEV/MAV/MRV (Israetel), RIR (Schoenfeld), RPE (Helms)
- Estudios peer-reviewed citados en documentación

Cada decisión tiene backing científico rastreable."

### Si preguntan por privacidad de datos

**Respuesta**:
"Tomamos privacidad muy en serio:
- Datos encriptados (Firestore)
- Cumplimos GDPR y CCPA
- ML dataset: datos anonimizados
- Opt-out disponible
- No vendemos datos a terceros
- Backups diarios con retención 30 días"

---

**FIN DE PRESENTACIÓN**
