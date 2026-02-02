# Motor V3 - Teaching Material

**Educational Resources for Students and Practitioners**  
Version: 3.0.0 | Last Updated: February 2026

---

## Table of Contents

1. [Learning Objectives](#learning-objectives)
2. [Module Structure](#module-structure)
3. [Exercises and Assignments](#exercises-and-assignments)
4. [Case Studies](#case-studies)
5. [Quizzes and Assessments](#quizzes-and-assessments)
6. [Hands-On Labs](#hands-on-labs)
7. [Additional Resources](#additional-resources)

---

## Learning Objectives

### Course Overview

**Course Title**: Motor V3 - AI-Powered Training Program Generation  
**Duration**: 8 weeks (16 hours total)  
**Level**: Intermediate (requires basic programming and exercise science knowledge)  
**Prerequisites**:
- Basic understanding of strength training concepts
- Programming fundamentals (Dart/Flutter helpful but not required)
- High school level mathematics

### By the End of This Course, Students Will Be Able To:

#### Knowledge (Understand)
1. Explain the 7 Semanas de Evidencia framework (Israetel, Schoenfeld, Helms)
2. Define MEV, MAV, MRV and their application in volume programming
3. Describe the 5-layer architecture of Motor V3
4. Understand the 38 features used in decision making
5. Explain RIR (Reps in Reserve) and RPE (Rate of Perceived Exertion)

#### Skills (Apply)
6. Generate training programs using Motor V3 engine
7. Interpret readiness assessments and make deload decisions
8. Analyze feature vectors to understand client state
9. Collect and record ML outcomes for continuous learning
10. Troubleshoot blocked plans and provide recommendations

#### Analysis (Evaluate)
11. Compare different decision strategies (Rules vs Hybrid vs ML)
12. Evaluate training program quality using scientific criteria
13. Assess when to override system recommendations
14. Analyze ML prediction accuracy and confidence scores

#### Creation (Design)
15. Design custom decision strategies for specific populations
16. Create validation rules for safety checks
17. Build client profiles that maximize personalization

---

## Module Structure

### Module 1: Scientific Foundations (Week 1-2)

**Learning Goals:**
- Master the 7 Semanas framework
- Understand volume landmarks (MEV/MAV/MRV)
- Learn intensity distribution principles

**Topics:**
1. Introduction to Evidence-Based Training
2. Semana 1-2: Volume (MEV/MAV/MRV per muscle)
3. Semana 3: Intensity (Heavy/Moderate/Light distribution)
4. Semana 4: Effort (RIR/RPE protocols)
5. Semana 5: Exercise Selection (6 scoring criteria)
6. Semana 6: Split Configuration (Full Body/Upper-Lower/PPL)
7. Semana 7: Periodization (Wave loading, progression)

**Readings:**
- Israetel, M. et al. (2017). *Scientific Principles of Strength Training*
- Schoenfeld, B. (2021). *Science and Development of Muscle Hypertrophy* (2nd ed.)
- Helms, E. et al. (2018). *The Muscle & Strength Pyramids: Training*

**Deliverable**: Essay (1000 words) explaining how you would apply MEV/MAV/MRV to your own training.

---

### Module 2: Motor V3 Architecture (Week 3)

**Learning Goals:**
- Understand the 5-layer architecture
- Learn the 7-phase generation pipeline
- Explore code structure

**Topics:**
1. Layer 1: Knowledge Base (Constants, Rules)
2. Layer 2: Intelligent Generation (Phases 3-7)
3. Layer 3: Adaptive Personalization
4. Layer 4: Reactive Motors
5. Layer 5: AI/ML Predictions
6. Pipeline Overview: Context → Features → Decisions → Plan

**Activities:**
- Hands-on: Explore codebase structure
- Group discussion: Why 5 layers? Alternative architectures?
- Code walkthrough: TrainingProgramEngineV3 class

**Deliverable**: Diagram illustrating data flow through all 7 pipeline phases.

---

### Module 3: Feature Engineering (Week 4)

**Learning Goals:**
- Master the 38 features in FeatureVector
- Understand normalization techniques
- Learn to derive features (fatigue, readiness, overreaching risk)

**Topics:**
1. Demographics (5): Age, gender, BMI
2. Experience (3): Years training, training level
3. Volume (4): Weekly sets, tolerance
4. Recovery (6): Sleep, stress, soreness, PRS
5. Intensity (3): RIR, RPE, optimality
6. Derived Features (6): Fatigue index, readiness score, etc.
7. One-Hot Encoding: Goals and focuses

**Lab Exercise:**
- Given raw client data, manually calculate all 38 features
- Verify calculations against FeatureVector.fromContext()

**Deliverable**: Feature engineering report for 3 sample clients.

---

### Module 4: Decision Strategies (Week 5)

**Learning Goals:**
- Implement RuleBasedStrategy from scratch
- Understand HybridStrategy blending
- Design custom strategies

**Topics:**
1. DecisionStrategy interface
2. RuleBasedStrategy: 7 rules deep dive
3. Volume adjustment logic (0.7x - 1.3x)
4. Readiness levels (critical → excellent)
5. HybridStrategy: Weighted blending
6. MLModelStrategy: Future predictions

**Coding Exercise:**
- Implement a "ConservativeStrategy" that always reduces volume by 10%
- Implement a "ProgressiveStrategy" for advanced athletes
- Test strategies on sample clients

**Deliverable**: Custom strategy class with unit tests.

---

### Module 5: ML Pipeline (Week 6)

**Learning Goals:**
- Understand ML dataset structure
- Learn prediction-outcome tracking
- Explore model training workflow

**Topics:**
1. TrainingDatasetService API
2. Firestore schema: ml_training_data
3. Recording predictions (features + decision)
4. Recording outcomes (adherence, fatigue, progress)
5. Exporting datasets (CSV, JSON)
6. Model training: GradientBoosting, hyperparameters
7. SHAP explainability

**Lab Exercise:**
- Generate 5 training plans with ML logging
- Manually create fake outcomes for each
- Export dataset and analyze in Excel/Python

**Deliverable**: ML dataset analysis report (500 words + graphs).

---

### Module 6: Readiness Gate & Safety (Week 7)

**Learning Goals:**
- Master readiness assessment logic
- Learn when to block plans
- Provide actionable recommendations

**Topics:**
1. Readiness score calculation (weighted formula)
2. Readiness levels: Critical/Poor/Fair/Good/Excellent
3. Blocking conditions (score < 0.4)
4. Deload week generation
5. Recovery recommendations (sleep, stress, nutrition)
6. Clinical restrictions integration

**Case Study Analysis:**
- 5 clients with varying readiness levels
- Decision: Block, deload, or proceed?
- Justify recommendations

**Deliverable**: Readiness decision flowchart + 3 sample assessments.

---

### Module 7: Integration & Testing (Week 8)

**Learning Goals:**
- Integrate Motor V3 into Flutter app
- Write unit and integration tests
- Handle errors gracefully

**Topics:**
1. Riverpod state management
2. TrainingEngineV3 providers
3. UI widgets: PlanGeneratorButton, MLOutcomeDialog
4. Error handling: InsufficientDataError, ReadinessCriticalError
5. Unit testing: Strategies, FeatureVector
6. Integration testing: Full pipeline
7. Widget testing: UI components

**Hands-On Lab:**
- Build a simple Flutter app that generates plans
- Add error handling for incomplete profiles
- Write 10 unit tests for RuleBasedStrategy

**Deliverable**: Working Flutter app demo + test suite.

---

### Module 8: Capstone Project (Week 8)

**Goal**: Design and implement a complete training program generation system for a specific population.

**Options:**
1. **Athletes**: Olympic weightlifters, powerlifters, bodybuilders
2. **Special Populations**: Seniors (60+), rehab clients, beginners
3. **Custom Domain**: CrossFit, endurance athletes, military

**Requirements:**
- Custom decision strategy tailored to population
- Modified feature engineering (add/remove features)
- Validation rules specific to domain
- 5 case studies with outcomes
- Presentation (15 min) to class

**Deliverable**: GitHub repository + documentation + presentation slides.

---

## Exercises and Assignments

### Exercise 1: Calculate MEV/MAV/MRV for Client

**Difficulty**: Beginner  
**Time**: 30 minutes

**Scenario:**
You have a client, Alex, who wants to build chest and back muscle.

**Client Profile:**
- Training Level: Intermediate (2 years)
- Goal: Hypertrophy
- Days per week: 4
- Recovery: Good (7/10 PRS)

**Task:**
1. Look up MEV/MAV/MRV for chest and back (use Israetel landmarks)
2. Calculate total weekly sets for each muscle
3. Distribute sets across 4 days (Upper/Lower split)
4. Justify your volume choices

**Expected Answer:**
```
Chest MEV/MAV/MRV: 6 / 14 / 20 sets
Back MEV/MAV/MRV: 8 / 16 / 24 sets

Target Volume (MAV):
- Chest: 14 sets/week
- Back: 16 sets/week

Distribution (Upper/Lower, 4 days):
Day 1 (Upper A):
  - Chest: 7 sets (Bench Press 3×5, Incline DB 4×8)
  - Back: 8 sets (Pull-ups 3×6, Rows 5×8)
  
Day 2 (Lower): ...

Day 3 (Upper B):
  - Chest: 7 sets (...)
  - Back: 8 sets (...)
  
Day 4 (Lower): ...

Total: 14 chest + 16 back = 30 sets upper body
```

---

### Exercise 2: Feature Engineering Manual Calculation

**Difficulty**: Intermediate  
**Time**: 45 minutes

**Client: Maria**
- Age: 32 years
- Gender: Female
- Height: 165 cm
- Weight: 60 kg
- Years training: 3 years
- Consecutive weeks: 12 weeks
- Training level: Intermediate
- Avg weekly sets: 18 sets per muscle
- Avg sleep: 6.5 hours
- Perceived recovery: 6/10
- Stress level: 7/10
- Soreness 48h: 5/10
- Average RIR: 2.5
- Average session RPE: 7.5

**Task:**
Calculate the following 10 features manually:

1. `ageYearsNorm` = (age - 18) / (80 - 18)
2. `genderMaleEncoded` = 0.0 or 1.0
3. `bmiNorm` = (BMI - 15) / (40 - 15), where BMI = weight / (height/100)²
4. `yearsTrainingNorm` = (years - 0) / (30 - 0)
5. `avgWeeklySetsNorm` = (sets - 0) / (30 - 0)
6. `avgSleepHoursNorm` = (sleep - 4) / (12 - 4)
7. `perceivedRecoveryNorm` = (PRS - 1) / (10 - 1)
8. `fatigueIndex` = (10 - PRS) * RPE / 100
9. `readinessScore` = 0.30×sleep + 0.25×(1-fatigue) + 0.20×PRS + 0.15×(1-stress) + 0.10×(1-soreness)
10. `overreachingRisk` = (avgSets / maxSets) * fatigueIndex (assume maxSets = 25)

**Show your work step-by-step.**

**Expected Answer:**
```
1. ageYearsNorm = (32 - 18) / 62 = 14 / 62 = 0.226
2. genderMaleEncoded = 0.0 (female)
3. BMI = 60 / (1.65)² = 22.04
   bmiNorm = (22.04 - 15) / 25 = 0.282
4. yearsTrainingNorm = 3 / 30 = 0.100
5. avgWeeklySetsNorm = 18 / 30 = 0.600
6. avgSleepHoursNorm = (6.5 - 4) / 8 = 0.313
7. perceivedRecoveryNorm = (6 - 1) / 9 = 0.556
8. fatigueIndex = (10 - 6) * 7.5 / 100 = 4 * 7.5 / 100 = 0.300
9. readinessScore:
   = 0.30×0.313 + 0.25×(1-0.30) + 0.20×0.556 + 0.15×(1-0.7) + 0.10×(1-0.5)
   = 0.094 + 0.175 + 0.111 + 0.045 + 0.050
   = 0.475 → POOR readiness
10. overreachingRisk = (18 / 25) * 0.30 = 0.72 * 0.30 = 0.216
```

---

### Exercise 3: Decision Strategy Implementation

**Difficulty**: Advanced  
**Time**: 90 minutes

**Task:**
Implement a `BeginnerFriendlyStrategy` that:
1. Always uses conservative volume (0.8x adjustment max)
2. Never allows RIR < 3 (for safety)
3. Blocks plans if readiness < 0.6 (stricter than default 0.4)
4. Provides beginner-specific recommendations

**Template:**
```dart
class BeginnerFriendlyStrategy implements DecisionStrategy {
  @override
  String get name => 'BeginnerFriendly';
  
  @override
  String get version => '1.0.0';
  
  @override
  bool get isTrainable => false;

  @override
  VolumeDecision decideVolume(FeatureVector features) {
    // TODO: Implement
    // Rules:
    // 1. If readinessScore < 0.6 → deload (0.7x)
    // 2. If trainingLevel != beginner → throw error
    // 3. Max adjustment: 0.8x (never increase volume for beginners)
    // 4. Default: 0.75x (conservative)
  }

  @override
  ReadinessDecision decideReadiness(FeatureVector features) {
    // TODO: Implement
    // Rules:
    // 1. Stricter thresholds: critical if < 0.6 (not 0.4)
    // 2. Beginner-specific recommendations
    // 3. Always recommend 7+ hours sleep
  }
}
```

**Bonus:** Write 5 unit tests for your strategy.

---

### Exercise 4: ML Dataset Analysis

**Difficulty**: Intermediate  
**Time**: 60 minutes

**Given:** CSV dataset with 100 training examples (provided separately)

**Columns:**
- 38 features (ageYearsNorm, genderMaleEncoded, ...)
- prediction_volumeAdjustment (0.7-1.3)
- prediction_readinessLevel (critical/poor/fair/good/excellent)
- outcome_adherence (0.0-1.0)
- outcome_fatigue (1-10)
- outcome_progress (kg gained)

**Tasks:**

1. **Descriptive Statistics:**
   - Mean, median, std dev for adherence, fatigue, progress
   - Distribution of readiness levels (histogram)

2. **Correlation Analysis:**
   - Which features correlate most with adherence?
   - Which features predict fatigue best?
   - Is volumeAdjustment correlated with progress?

3. **Accuracy Assessment:**
   - Calculate MAE (Mean Absolute Error) between predicted and actual adherence
   - How often did readiness level match outcome (e.g., "excellent" → high adherence)?

4. **Insights:**
   - What patterns do you see?
   - Which features matter most?
   - Recommendations for improving predictions?

**Tools:** Excel, Google Sheets, Python (pandas), or R

**Deliverable:** 1-page report with 3 graphs.

---

### Exercise 5: Readiness Gate Decision Tree

**Difficulty**: Beginner  
**Time**: 30 minutes

**Task:** Create a decision tree for determining whether to block, deload, or proceed with a training plan.

**Inputs:**
- Readiness score (0.0-1.0)
- Fatigue index (0.0-1.0)
- Overreaching risk (0.0-1.0)
- Client preference (can client take a rest week?)

**Decision Flow:**
```
START
  ↓
┌───────────────────┐
│ readinessScore?   │
└────┬──────────────┘
     │
     ├── < 0.4 → BLOCK (critical)
     │
     ├── 0.4-0.6 → CHECK FATIGUE
     │              ├── fatigueIndex > 0.7 → BLOCK (poor)
     │              └── else → DELOAD (0.7x)
     │
     ├── 0.6-0.7 → CHECK OVERREACHING
     │              ├── overreachingRisk > 0.6 → DELOAD (0.8x)
     │              └── else → PROCEED (conservative, 0.9x)
     │
     └── > 0.7 → PROCEED (normal, 1.0x)
```

**Your Task:** Draw this as a visual decision tree (use draw.io, Lucidchart, or pen & paper).

---

## Case Studies

### Case Study 1: John - Intermediate Lifter Plateau

#### Background
**Client:** John Martinez, 28 years old  
**Goal:** Break through bench press plateau (stuck at 100kg for 6 months)  
**Training History:** 2.5 years consistent training, intermediate level  
**Current Program:** Generic gym program (5×5 for everything)

#### Baseline Assessment (Week 0)

**Physical:**
- Height: 180 cm
- Weight: 85 kg
- BMI: 26.2 (slightly overweight)

**Training Evaluation:**
- Avg weekly sets: 20 per muscle
- Avg sleep: 7 hours
- Perceived recovery: 6/10
- Stress level: 6/10
- Soreness: 5/10
- Average RIR: 2
- Session RPE: 8

**Calculated Features:**
```
readinessScore: 0.62 (FAIR)
fatigueIndex: 0.32 (moderate)
overreachingRisk: 0.26 (low)
volumeOptimalityIndex: 1.4 (between MAV and MRV)
```

#### Motor V3 Intervention

**Plan Generated:**
- Strategy: RuleBased
- Volume adjustment: 0.95x (slight reduction due to fair readiness)
- Split: Upper/Lower, 4 days/week
- Periodization: 4 weeks (accumulation → intensification → realization → deload)

**Week 1-3 Plan:**
```
Upper A (Monday):
- Bench Press: 4×6 @ RIR 2 (heavy)
- Incline DB Press: 3×10 @ RIR 2 (moderate)
- Cable Flies: 3×15 @ RIR 1 (light)
- Tricep Work: 3×12

Upper B (Thursday):
- Bench Press: 3×8 @ RIR 3 (moderate)
- Dips: 3×8 @ RIR 2
- Landmine Press: 3×12 @ RIR 2
- Tricep Work: 3×15

Volume: 19 sets chest/week (was 20, reduced 5% by Motor V3)
```

**Week 4: Deload**
- 50% volume reduction
- Maintain intensity (same weights, fewer sets)

#### Outcomes (Week 4)

**ML Outcome Collection:**
- Adherence: 95% (missed 1 session in 4 weeks)
- Average fatigue: 5.5/10 (decreased from 6.4 baseline)
- Progress: Bench Press 100kg → 105kg (+5kg)
- Injury: No
- Client feedback: "Perfect difficulty"

**Feature Changes:**
```
readinessScore: 0.62 → 0.78 (FAIR → GOOD)
fatigueIndex: 0.32 → 0.22 (improved recovery)
volumeOptimalityIndex: 1.4 → 1.35 (slightly reduced)
```

#### Analysis Questions for Students

1. **Why did Motor V3 reduce volume by 5% despite John being at MAV?**
   <details>
   <summary>Answer</summary>
   Readiness score was FAIR (0.62), indicating suboptimal recovery. Reducing volume slightly allowed better adaptation while still progressing.
   </details>

2. **What role did the deload week play in John's progress?**
   <details>
   <summary>Answer</summary>
   Deload week (Week 4) allowed supercompensation. Fatigue dissipated while fitness remained, leading to strength peak.
   </details>

3. **Should Motor V3 increase volume for John's next mesocycle?**
   <details>
   <summary>Answer</summary>
   Yes, readiness improved to 0.78 (GOOD). Next cycle could use 1.05x adjustment to push toward MRV.
   </details>

4. **How would you explain the 5kg bench press gain to John?**
   <details>
   <summary>Answer</summary>
   "Volume optimization (slightly reduced from excessive 20 sets), better recovery (deload week), and intensity periodization (heavy → moderate → deload pattern) allowed your body to adapt without overtraining."
   </details>

---

### Case Study 2: Maria - Overtraining Recovery

#### Background
**Client:** Maria Santos, 35 years old  
**Goal:** Recover from overtraining, return to safe training  
**Training History:** 5 years advanced training, last 8 months poorly programmed (no deloads)  
**Presenting Issue:** Chronic fatigue, joint pain, considering quitting

#### Baseline Assessment (Week 0)

**Physical:**
- Height: 160 cm
- Weight: 55 kg
- BMI: 21.5 (normal)

**Training Evaluation:**
- Avg weekly sets: 30+ per muscle (excessive)
- Avg sleep: 5.5 hours (poor)
- Perceived recovery: 2/10 (very poor)
- Stress level: 9/10 (very high)
- Soreness: 9/10 (severe DOMS)
- Average RIR: 0-1 (training to failure constantly)
- Session RPE: 9.5 (exhausting)

**Injuries:**
- Right shoulder pain (6/10)
- Left knee discomfort (4/10)
- Lower back tightness (5/10)

**Calculated Features:**
```
readinessScore: 0.28 (CRITICAL) ⚠️
fatigueIndex: 0.76 (very high)
overreachingRisk: 0.91 (critical)
recoveryCapacity: 0.18 (very low)
```

#### Motor V3 Intervention

**Plan Attempt 1: BLOCKED**

```
⛔ PLAN GENERATION BLOCKED

Readiness Level: CRITICAL (0.28)

Reasons:
1. Fatigue index 0.76 (>0.65 threshold)
2. Overreaching risk 0.91 (>0.60 threshold)
3. Recovery capacity 0.18 (<0.40 threshold)
4. Sleep deprivation (5.5h < 7h minimum)

Recommendations:
1. IMMEDIATE REST: 7-10 days complete deload
2. Address sleep: Increase to 8+ hours nightly
3. Stress management: Meditation, reduce life stressors
4. Medical check: Rule out chronic fatigue syndrome
5. Nutrition: Ensure caloric surplus (recovery mode)

Next Steps:
[Generate Deload Week] [Schedule Follow-Up]
```

**Deload Week Generated (Week 1):**
```
Full Body, 3 days/week
Volume: 6 sets chest, 6 sets back, 6 sets legs (60% reduction)
Intensity: 60-70% 1RM (very light)
RIR: 5 (no hard effort)
Focus: Technique, mind-muscle connection
```

#### Progress Tracking

**Week 2 Reassessment:**
- Sleep: 5.5h → 7h (improved)
- PRS: 2/10 → 4/10
- Stress: 9/10 → 7/10
- Soreness: 9/10 → 6/10
- **Readiness: 0.28 → 0.42 (POOR, still blocked)**

**Deload Week 2 Generated** (slightly higher volume)

**Week 4 Reassessment:**
- Sleep: 7h → 7.5h
- PRS: 4/10 → 6/10
- Stress: 7/10 → 6/10
- Soreness: 6/10 → 4/10
- **Readiness: 0.42 → 0.61 (FAIR, can train!)**

**Plan Generated (Week 5-8):**
- Strategy: RuleBased
- Volume adjustment: 0.7x (conservative)
- Split: Full Body, 3 days/week
- Volume: 10 sets chest, 10 sets back, 10 sets legs
- Progression: Minimal (+2.5kg every 2 weeks)

#### Outcomes (Week 8)

**ML Outcome Collection:**
- Adherence: 100%
- Average fatigue: 4/10 (much improved)
- Progress: Minimal strength gains, but pain-free training!
- Injury: Shoulder pain resolved, knee 90% better
- Client feedback: "Finally enjoying training again"

**Feature Changes:**
```
readinessScore: 0.28 → 0.75 (CRITICAL → GOOD)
fatigueIndex: 0.76 → 0.24 (normalized)
overreachingRisk: 0.91 → 0.17 (safe zone)
```

#### Analysis Questions for Students

1. **Why did Motor V3 block the plan initially?**
   <details>
   <summary>Answer</summary>
   Readiness score 0.28 indicated critical overtraining. Generating a normal plan would have worsened the situation and risked serious injury. Safety gate prevented harm.
   </details>

2. **Was 4 weeks of deloading excessive?**
   <details>
   <summary>Answer</summary>
   No. Severe overtraining requires extended recovery. Attempting to return too quickly would have re-triggered symptoms. Progressive deload (Week 1 → Week 2 slightly higher) allowed gradual adaptation.
   </details>

3. **What was the most important intervention?**
   <details>
   <summary>Answer</summary>
   Sleep improvement (5.5h → 7.5h). Without addressing the root cause (poor recovery), no volume reduction would have helped.
   </details>

4. **Should Maria increase volume in Week 9-12?**
   <details>
   <summary>Answer</summary>
   Cautiously. Readiness is GOOD (0.75) now, so a small increase (0.8x adjustment) is safe. Monitor closely for 2 weeks before progressing to 0.9x.
   </details>

---

### Case Study 3: Advanced Athlete - Sarah (Powerlifter)

#### Background
**Client:** Sarah Kim, 24 years old  
**Goal:** Increase powerlifting total (squat + bench + deadlift)  
**Training History:** 4 years competitive powerlifting, advanced level  
**Current Total:** 350kg (120kg squat, 70kg bench, 160kg deadlift)

#### Baseline Assessment

**Physical:**
- Height: 168 cm
- Weight: 68 kg (63kg class, off-season)
- BMI: 24.1

**Training Evaluation:**
- Avg weekly sets: 22 per major lift
- Avg sleep: 8 hours (good)
- Perceived recovery: 8/10 (good)
- Stress level: 4/10 (low)
- Soreness: 4/10 (normal)
- Average RIR: 2-3 (appropriate for strength)
- Session RPE: 7.5

**Calculated Features:**
```
readinessScore: 0.82 (EXCELLENT)
fatigueIndex: 0.15 (very low)
overreachingRisk: 0.12 (minimal)
trainingMaturity: 4.0 (high experience)
```

#### Motor V3 Intervention

**Challenge:** Powerlifting requires strength-specific programming, not hypertrophy.

**Modifications:**
- Goal: Strength (not hypertrophy)
- Focus: Power (explosive lifts)
- Intensity distribution: 50% heavy, 40% moderate, 10% light (not standard 35/45/20)

**Plan Generated:**
- Strategy: RuleBased (modified for strength)
- Volume adjustment: 1.15x (can handle more due to excellent readiness)
- Split: Upper/Lower, 4 days/week
- Periodization: Strength-focused (5×5 → 3×3 → 1×1 peak)

**Week 1-3 (Accumulation + Intensification):**
```
Lower A (Monday):
- Squat: 5×5 @ 80% 1RM, RIR 3
- Romanian Deadlift: 4×6 @ 75%, RIR 2
- Front Squat: 3×8 @ 70%, RIR 2
- Accessories: 3×10

Lower B (Friday):
- Deadlift: 5×5 @ 80%, RIR 3
- Squat (pause): 3×5 @ 75%, RIR 2
- Deficit Deadlift: 3×6 @ 70%, RIR 2
- Accessories: 3×10

Upper A (Tuesday):
- Bench Press: 5×5 @ 80%, RIR 3
- Overhead Press: 4×6, RIR 2
- Close-Grip Bench: 3×8, RIR 2

Upper B (Thursday):
- Bench Press (pause): 4×5 @ 75%, RIR 3
- Incline Bench: 3×8, RIR 2
- Dips: 3×10, RIR 1
```

**Week 4 (Deload):**
- 60% volume (not 50%, strength athletes need less reduction)
- Maintain intensity (80% 1RM, just fewer sets)

#### Outcomes (Week 4)

**ML Outcome Collection:**
- Adherence: 100%
- Average fatigue: 6/10 (slightly elevated, expected for strength training)
- Progress:
  - Squat: 120kg → 125kg (+5kg)
  - Bench: 70kg → 72.5kg (+2.5kg)
  - Deadlift: 160kg → 165kg (+5kg)
  - **Total: 350kg → 362.5kg (+12.5kg in 4 weeks!)**
- Injury: No
- Client feedback: "Best progress in a year"

#### Analysis Questions for Students

1. **Why did Motor V3 increase volume by 15% for Sarah?**
   <details>
   <summary>Answer</summary>
   Excellent readiness (0.82), low fatigue (0.15), advanced training maturity (4.0 years), and minimal overreaching risk (0.12) indicated capacity for higher volume.
   </details>

2. **Is 1.15x volume appropriate for strength training?**
   <details>
   <summary>Answer</summary>
   Yes. Strength training typically uses lower volume than hypertrophy (5×5 vs 4×10), so 1.15x adjustment is still within safe limits. Total sets: 22 → 25 (well below MRV of 30).
   </details>

3. **Why was the deload only 60% (not 50% like hypertrophy)?**
   <details>
   <summary>Answer</summary>
   Strength athletes benefit from maintaining neural adaptations. Reducing to 50% volume risks losing motor patterns. 60% is sufficient for recovery while preserving strength.
   </details>

4. **How would you program Sarah's next mesocycle?**
   <details>
   <summary>Answer</summary>
   - Week 1-2: 3×3 @ 85% (intensification)
   - Week 3: 2×2 @ 90% (realization)
   - Week 4: Singles @ 95% (peak/test)
   - Week 5: Deload → New cycle
   </details>

---

### Case Study 4: Beginner - Tom (6 Months Training)

#### Background
**Client:** Tom Johnson, 42 years old  
**Goal:** General fitness, lose body fat, gain some muscle  
**Training History:** 6 months (true beginner)  
**Current Program:** Random machines at gym, no structure

#### Baseline Assessment

**Physical:**
- Height: 175 cm
- Weight: 92 kg (overweight)
- BMI: 30.0 (obese class 1)

**Training Evaluation:**
- Avg weekly sets: 12 (low, inconsistent)
- Avg sleep: 6.5 hours
- Perceived recovery: 5/10 (moderate)
- Stress level: 7/10 (work stress)
- Soreness: 7/10 (high, unfamiliar with DOMS)
- Average RIR: unknown (doesn't understand concept)
- Session RPE: 6 (moderate)

**Calculated Features:**
```
readinessScore: 0.55 (FAIR, borderline)
fatigueIndex: 0.30 (moderate)
overreachingRisk: 0.14 (low, due to low volume)
trainingMaturity: 0.5 (very novice)
```

#### Motor V3 Intervention

**Plan Generated:**
- Strategy: RuleBased (beginner mode)
- Volume adjustment: 0.8x (conservative for novice)
- Split: Full Body, 3 days/week (optimal for beginners)
- Progression: Linear (add 2.5kg every 2 weeks)

**Beginner-Specific Modifications:**
- All exercises: RIR 4-5 (technique focus)
- Compounds only (no isolations yet)
- Long rest (3 minutes) to reduce fatigue
- Educational notes per exercise

**Week 1-3 Plan:**
```
Full Body A (Monday/Friday):
- Goblet Squat: 3×10 @ RIR 5 (learning pattern)
- DB Bench Press: 3×10 @ RIR 4 (safer than barbell)
- Lat Pulldown: 3×10 @ RIR 4
- DB Shoulder Press: 2×10 @ RIR 5
- Plank: 3×30s

Full Body B (Wednesday):
- Leg Press: 3×10 @ RIR 4 (machine, safer)
- Incline DB Press: 3×10 @ RIR 4
- Seated Row: 3×10 @ RIR 4
- Lateral Raise: 2×12 @ RIR 5
- Dead Bug: 3×10

Total: 9 sets per muscle group, 3x/week frequency
```

**Week 4 (Deload):**
- 2 sessions instead of 3
- 2 sets per exercise (instead of 3)

#### Outcomes (Week 4)

**ML Outcome Collection:**
- Adherence: 75% (missed 3 sessions due to work)
- Average fatigue: 5/10 (acceptable)
- Progress: Small strength gains (+5kg leg press, +2.5kg bench)
- Injury: No
- Client feedback: "Finally understand how to train properly"

**Non-Strength Outcomes (measured separately):**
- Weight: 92kg → 90kg (-2kg body fat)
- Energy levels: Improved (self-reported)
- Confidence: "I can do this long-term"

#### Follow-Up (Week 8)

**Tom's readiness improved:**
- Sleep: 6.5h → 7h
- PRS: 5/10 → 6/10
- Soreness: 7/10 → 4/10 (adapted to DOMS)
- **Readiness: 0.55 → 0.68 (FAIR → GOOD)**

**Next Mesocycle Adjustments:**
- Increase volume: 0.8x → 0.9x (9 sets → 10 sets per muscle)
- Add 1 isolation exercise per day (e.g., bicep curls, leg extensions)
- Reduce RIR: 4-5 → 3-4 (can push harder now)
- Maintain 3 days/week (still beginner)

#### Analysis Questions for Students

1. **Why Full Body 3x/week instead of Upper/Lower or PPL?**
   <details>
   <summary>Answer</summary>
   Beginners benefit from high frequency (3x/week per muscle) to practice movement patterns. Full Body allows this with only 3 gym days, fitting Tom's schedule.
   </details>

2. **Why RIR 4-5 (seemingly too easy)?**
   <details>
   <summary>Answer</summary>
   Beginners lack RIR accuracy. What feels like RIR 4 might actually be RIR 2. Conservative targets ensure safety and allow technique focus over grinding reps.
   </details>

3. **Is 0.8x volume too low? Won't Tom not progress?**
   <details>
   <summary>Answer</summary>
   No. Beginners can progress on MEV (minimum volume). 9 sets per muscle is sufficient for novice gains. Overloading too early risks injury and burnout.
   </details>

4. **How long should Tom stay on Full Body split?**
   <details>
   <summary>Answer</summary>
   6-12 months. Once he's consistently hitting 12+ sets per muscle with good technique, transition to Upper/Lower. Rushing to advanced splits is counterproductive.
   </details>

---

### Case Study 5: Injured Athlete - Recovery Protocol

**Scenario:** Design a recovery protocol using Motor V3 for a client with a torn rotator cuff (post-physical therapy clearance).

*Left as exercise for students to complete.*

**Requirements:**
- Update client profile with injury region
- Add movement restrictions
- Generate modified plan
- Track readiness during rehab (Weeks 1-8)
- Propose gradual return to full training (Weeks 9-16)

---

## Quizzes and Assessments

### Quiz 1: Scientific Foundations (20 questions)

#### Multiple Choice

**1. What does MEV stand for?**
- A) Maximum Effective Volume
- B) Minimum Effective Volume ✓
- C) Moderate Exercise Velocity
- D) Muscle Endurance Volume

**2. According to Dr. Israetel, what is the typical MAV for chest in intermediate lifters?**
- A) 6-8 sets/week
- B) 10-12 sets/week
- C) 14-18 sets/week ✓
- D) 20-25 sets/week

**3. RIR 2 means:**
- A) 2 reps completed
- B) 2 reps remaining in reserve ✓
- C) 2 sets remaining
- D) RPE of 2

**4. What is the recommended intensity distribution for hypertrophy (Helms)?**
- A) 50% heavy, 30% moderate, 20% light
- B) 35% heavy, 45% moderate, 20% light ✓
- C) 20% heavy, 60% moderate, 20% light
- D) 40% heavy, 40% moderate, 20% light

**5. Which split is optimal for beginners training 3 days/week?**
- A) PPL (Push/Pull/Legs)
- B) Upper/Lower
- C) Full Body ✓
- D) Bro Split (chest day, back day, etc.)

#### True/False

**6. MRV is the same for all muscle groups.**
- False ✓ (Varies: chest MRV ~20, quads MRV ~25)

**7. Deload weeks should reduce volume by 80-90%.**
- False ✓ (40-60% reduction is standard)

**8. RPE 8 is approximately RIR 2.**
- True ✓

**9. Isolations should make up 60% of a hypertrophy program.**
- False ✓ (40% isolations, 60% compounds)

**10. Wave loading involves linear progression every week.**
- False ✓ (Wave loading is undulating: increase → deload)

#### Short Answer

**11. Calculate the total weekly volume for a client targeting MAV for chest (14 sets) and back (16 sets) on a 4-day Upper/Lower split. Show distribution.**

**Expected Answer:**
```
Upper A (Monday):
- Chest: 7 sets
- Back: 8 sets

Upper B (Thursday):
- Chest: 7 sets
- Back: 8 sets

Total: 14 chest + 16 back per week
```

**12. Explain why Motor V3 might reduce volume for a client with readiness score 0.55.**

**Expected Answer:**
```
Readiness 0.55 = FAIR level. Indicates suboptimal recovery (not critical, but not ideal). Reducing volume by 10-20% (0.8-0.9x adjustment) allows client to adapt to current stress before adding more volume. Prevents accumulation of fatigue.
```

**13-20:** [Additional questions on periodization, exercise selection, etc.]

---

### Quiz 2: Motor V3 Architecture (15 questions)

**1. How many layers are in Motor V3 architecture?**
- A) 3
- B) 5 ✓
- C) 7
- D) 10

**2. Which phase comes first in the generation pipeline?**
- A) Feature Engineering
- B) Decision Making
- C) Context Building ✓
- D) ML Logging

**3. How many features are in FeatureVector?**
- A) 24
- B) 30
- C) 38 ✓
- D) 45

**4. What is the purpose of the Readiness Gate?**
- A) Validate client credentials
- B) Block plans if fatigue is critical ✓
- C) Check database connection
- D) Verify exercise availability

**5. Which decision strategy is used in production?**
- A) HybridStrategy
- B) MLModelStrategy
- C) RuleBasedStrategy ✓
- D) RandomStrategy

[... 10 more questions on architecture, code structure, etc.]

---

### Quiz 3: Feature Engineering (10 questions)

**Given client:**
- Age: 25
- Gender: Male
- Height: 170 cm
- Weight: 70 kg
- Years training: 1.5
- Avg sleep: 7.5 hours
- PRS: 8/10
- Stress: 4/10
- Soreness: 3/10
- Avg RIR: 2.5
- Session RPE: 7

**Calculate:**

**1. ageYearsNorm = (25 - 18) / (80 - 18)**

**Answer:** 7 / 62 = 0.113

**2. bmiNorm (show BMI calculation first)**

**Answer:**
```
BMI = 70 / (1.70)² = 24.22
bmiNorm = (24.22 - 15) / 25 = 0.369
```

**3. fatigueIndex = (10 - PRS) * RPE / 100**

**Answer:**
```
fatigueIndex = (10 - 8) * 7 / 100 = 2 * 7 / 100 = 0.14
```

**4. readinessScore (use simplified formula: 0.3×sleep + 0.25×(1-fatigue) + 0.2×PRS + 0.15×(1-stress) + 0.1×(1-soreness))**

**Answer:**
```
sleep_norm = (7.5 - 4) / 8 = 0.4375
PRS_norm = (8 - 1) / 9 = 0.778
stress_norm = 4 / 10 = 0.4
soreness_norm = 3 / 10 = 0.3

readinessScore = 0.3×0.4375 + 0.25×(1-0.14) + 0.2×0.778 + 0.15×(1-0.4) + 0.1×(1-0.3)
= 0.131 + 0.215 + 0.156 + 0.090 + 0.070
= 0.662 → FAIR readiness
```

**5-10:** [More calculation questions]

---

### Final Exam: Comprehensive Assessment (50 questions, 2 hours)

**Part A: Multiple Choice (20 questions, 1 point each)**
- Scientific foundations
- Architecture
- Feature engineering
- Decision strategies

**Part B: Calculations (10 problems, 3 points each)**
- Feature normalization
- Volume calculations
- Readiness scoring
- Volume distribution

**Part C: Short Answer (5 questions, 6 points each)**
- Explain decision logic
- Compare strategies
- Troubleshoot issues
- Design recommendations

**Part D: Case Study (1 problem, 20 points)**
- Complete client analysis
- Generate plan manually
- Justify all decisions
- Propose 12-week progression

**Passing Score:** 70/100

---

## Hands-On Labs

### Lab 1: Setup Development Environment (30 min)

**Objective:** Install Flutter, configure Firebase, run Motor V3 app locally.

**Steps:**
1. Install Flutter SDK (https://flutter.dev/docs/get-started/install)
2. Clone HefestCS repository
3. Run `flutter pub get`
4. Configure Firebase (flutterfire configure)
5. Run app: `flutter run`
6. Verify: Generate a test plan

**Deliverable:** Screenshot of successful plan generation.

---

### Lab 2: Manual Feature Engineering (45 min)

**Objective:** Build FeatureVector from scratch without using `.fromContext()`.

**Scenario:** You are given raw client data in JSON format:
```json
{
  "age": 30,
  "gender": "female",
  "height_cm": 165,
  "weight_kg": 60,
  "years_training": 2,
  "avg_sleep": 7,
  "prs": 7,
  "stress": 5,
  "avg_rir": 2.5,
  "session_rpe": 7.5
}
```

**Tasks:**
1. Calculate all 38 features manually (show work)
2. Write Dart code to construct FeatureVector
3. Verify against `FeatureVector.fromContext()`
4. Print JSON output

**Deliverable:** Dart file + calculation worksheet.

---

### Lab 3: Implement Custom Strategy (60 min)

**Objective:** Code a `ProgressiveOverloadStrategy` for advanced athletes.

**Requirements:**
1. Always increase volume by 5-10% (1.05-1.10x)
2. Block if readiness < 0.7 (stricter than default)
3. Use RIR 1-2 (push hard)
4. Provide advanced-specific recommendations

**Template:** (Provided in Exercise 3 earlier)

**Deliverable:** Dart file + 5 unit tests.

---

### Lab 4: ML Dataset Collection Simulation (60 min)

**Objective:** Simulate 10 clients, generate plans, record fake outcomes.

**Steps:**
1. Create 10 diverse client profiles (beginner → advanced, various readiness levels)
2. Generate plans for each using Motor V3
3. Record predictions to Firestore
4. Manually create realistic outcomes (adherence, fatigue, progress)
5. Update Firestore with outcomes
6. Export dataset as CSV
7. Analyze in Excel: correlations, distributions

**Deliverable:** CSV file + 1-page analysis report.

---

### Lab 5: A/B Testing Framework (90 min)

**Objective:** Design and implement A/B testing for RuleBased vs Hybrid strategies.

**Steps:**
1. Create 20 test clients (10 per group)
2. Group A: Use RuleBasedStrategy
3. Group B: Use HybridStrategy (mock ML predictions for now)
4. Generate plans for all
5. Record predictions
6. Simulate outcomes (use random realistic values)
7. Compare metrics:
   - Average adherence
   - Average fatigue
   - Average progress
   - Injury rate
8. Determine statistical significance (t-test)

**Deliverable:** Jupyter Notebook or Dart script + results presentation.

---

### Lab 6: UI Integration (90 min)

**Objective:** Build a Flutter UI for Motor V3 plan generation.

**Requirements:**
1. Client profile form (all fields)
2. "Generate Plan" button
3. Loading state
4. Success state: Display plan summary
5. Blocked state: Show readiness metrics + recommendations
6. Outcome feedback dialog (4 weeks later)

**Bonus:** Add charts (readiness timeline, volume distribution)

**Deliverable:** Flutter app demo video (3 min).

---

## Additional Resources

### Recommended Reading

#### Books

1. **Israetel, M. et al. (2017).** *Scientific Principles of Strength Training*  
   - Essential for understanding MEV/MAV/MRV
   - Chapters 3-5 (Volume, Intensity, Frequency)

2. **Schoenfeld, B. (2021).** *Science and Development of Muscle Hypertrophy* (2nd ed.)  
   - Gold standard for hypertrophy research
   - Chapter 4 (Mechanical Tension), Chapter 6 (Volume)

3. **Helms, E. et al. (2018).** *The Muscle & Strength Pyramids: Training*  
   - Practical application of science
   - RIR/RPE protocols, periodization

4. **Bompa, T. & Haff, G. (2009).** *Periodization: Theory and Methodology of Training*  
   - Comprehensive periodization models
   - Wave loading, block periodization

#### Research Papers

1. **Schoenfeld et al. (2017).** "Dose-response relationship between weekly resistance training volume and increases in muscle mass: A systematic review and meta-analysis." *Journal of Sports Sciences*.  
   - Evidence for volume landmarks

2. **Zourdos et al. (2016).** "Novel Resistance Training-Specific RPE Scale." *Journal of Strength and Conditioning Research*.  
   - RIR-RPE conversion tables

3. **Israetel et al. (2019).** "The Renaissance Diet 2.0"  
   - Nutrition integration with training

4. **Helms et al. (2014).** "Recommendations for natural bodybuilding contest preparation: nutrition and supplementation." *Journal of the International Society of Sports Nutrition*.

#### Online Resources

1. **Renaissance Periodization YouTube Channel**  
   https://youtube.com/c/RenaissancePeriodization  
   - Dr. Mike Israetel's evidence-based training videos

2. **Stronger by Science**  
   https://www.strongerbyscience.com/  
   - Greg Nuckols' research reviews and guides

3. **3DMJ (3D Muscle Journey)**  
   https://3dmusclejourney.com/  
   - Eric Helms' coaching and education

4. **Motor V3 Documentation**  
   https://docs.hefestcs.com/motor-v3/  
   - Official API docs, user guides

### Video Tutorials

1. **Motor V3 Quickstart (15 min)**  
   - Setup, first plan generation, outcome collection

2. **Feature Engineering Deep Dive (30 min)**  
   - Manual calculation walk-through
   - Normalization techniques

3. **Decision Strategy Comparison (20 min)**  
   - RuleBased vs Hybrid vs ML
   - A/B testing results

4. **Case Study Walkthroughs (60 min total)**  
   - John (plateau breaker)
   - Maria (overtraining recovery)
   - Sarah (powerlifter)

### Community & Support

1. **HefestCS Discord Server**  
   - #motor-v3-questions
   - #case-study-discussions
   - #ml-pipeline

2. **Monthly Office Hours**  
   - Live Q&A with developers
   - Guest lectures from sports scientists
   - Code reviews

3. **GitHub Repository**  
   https://github.com/hefestcs/motor-v3  
   - Open issues for questions
   - Pull requests for contributions
   - Example code snippets

### Practice Datasets

1. **Sample Clients (N=50)**  
   - Diverse profiles (beginner → advanced)
   - Complete training evaluations
   - 4-week outcome data

2. **Exercise Catalog (N=200)**  
   - All major movements
   - Scored by 6 criteria
   - Equipment requirements

3. **ML Training Data (N=500)**  
   - 38 features per example
   - Predictions + outcomes
   - CSV and JSON formats

**Download:** https://datasets.hefestcs.com/motor-v3/

---

## Instructor Guide

### Teaching Tips

**Week 1-2: Start with "Why"**
- Don't dive into code immediately
- Show real overtraining case studies
- Build excitement for evidence-based approach

**Week 3-4: Hands-On Early**
- Students learn by doing
- Provide incomplete code, have them fill in
- Pair programming exercises

**Week 5-6: ML Demystification**
- Many students fear ML
- Start with simple rules (decision trees)
- Gradually introduce complexity

**Week 7-8: Real-World Projects**
- Encourage students to bring own clients (anonymized)
- Apply Motor V3 to real scenarios
- Share results with class

### Common Student Struggles

**"I don't understand normalization"**
- Use visual examples (0-100% scales)
- Practice with age (easy to grasp)
- Show what happens without normalization (ML breaks)

**"Why so many features?"**
- Explain curse of dimensionality vs information gain
- Show feature importance rankings
- Let them try with fewer features (worse results)

**"ML is a black box"**
- Introduce SHAP early
- Always explain decisions in plain language
- Emphasize hybrid approaches (rules + ML)

### Assessment Rubrics

**Labs (40% of grade):**
- Code quality: 40%
- Correctness: 40%
- Documentation: 20%

**Quizzes (30% of grade):**
- Scientific knowledge: 50%
- Technical application: 50%

**Capstone Project (30% of grade):**
- Innovation: 25%
- Scientific rigor: 25%
- Code quality: 25%
- Presentation: 25%

---

## Certification

Upon completing this course with ≥80% score, students receive:

**Motor V3 Certified Practitioner**

**Benefits:**
- Listed on HefestCS practitioner directory
- Access to advanced features (API keys)
- Monthly continuing education webinars
- Community badge

**Renewal:** Every 2 years (complete refresher course or attend conference)

---

**Teaching Material Version:** 3.0.0  
**Last Updated:** February 2026  
**Contact:** education@hefestcs.com

---

**License:** CC BY-NC-SA 4.0 (Attribution-NonCommercial-ShareAlike)  
You may use and adapt this material for educational purposes with attribution.
