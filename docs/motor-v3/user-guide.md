# Motor V3 User Guide

**For Coaches and Trainers**  
Version: 3.0.0 | Last Updated: February 2026

---

## Table of Contents

1. [Introduction](#introduction)
2. [Getting Started](#getting-started)
3. [Creating Client Profiles](#creating-client-profiles)
4. [Generating Training Programs](#generating-training-programs)
5. [Processing Workout Logs](#processing-workout-logs)
6. [Interpreting Analytics and Charts](#interpreting-analytics-and-charts)
7. [Common Workflows](#common-workflows)
8. [FAQ](#faq)

---

## Introduction

### What is Motor V3?

Motor V3 is a **scientifically-backed, AI-ready training program generation system** that creates personalized workout plans based on:

- **7 Semanas de Evidencia** (151 research-backed concepts)
- **Client's individual profile** (training history, recovery status, goals)
- **Real-time adaptation** (ML-powered decision making)
- **Readiness monitoring** (blocks plans when client is at risk)

### Key Features

✅ **Adaptive Volume Control** - Adjusts weekly sets (0.7x - 1.3x) based on recovery  
✅ **Readiness Gate** - Prevents overtraining by blocking plans when fatigue is critical  
✅ **ML-Powered Predictions** - Learns from outcomes to optimize future programs  
✅ **Complete Explainability** - Every decision is traceable and justified  
✅ **4-Week Periodization** - Progressive overload with automatic deload phases  

### Who Should Use This Guide?

- **Personal Trainers** managing 1-50 clients
- **Strength Coaches** working with athletes
- **Gym Managers** overseeing training teams
- **Self-coached Athletes** with intermediate+ experience

---

## Getting Started

### System Requirements

- **Device**: Android 9.0+ / iOS 13.0+
- **Internet**: Required for plan generation and ML logging
- **Permissions**: Storage (for workout logs), Notifications (for reminders)

### First-Time Setup

#### Step 1: Launch the App

Open **HefestCS App** and navigate to:

```
Main Menu → Training → Motor V3
```

#### Step 2: Review Exercise Catalog

Before creating client profiles, ensure your gym's equipment is properly configured:

1. Go to **Settings → Equipment**
2. Enable available equipment:
   - Barbell, Dumbbells, Cables, Machines, Bodyweight
3. Mark unavailable equipment as disabled

#### Step 3: Understand the Interface

Motor V3 has 3 main screens:

| Screen | Purpose |
|--------|---------|
| **Client List** | View all clients, create new profiles |
| **Program Generator** | Generate 4-week training plans |
| **Analytics Dashboard** | View client progress and ML insights |

---

## Creating Client Profiles

### Required Information

A complete client profile requires:

#### 1. **Basic Information**
- Full Name
- Age (18-80 years)
- Gender
- Height (cm)
- Weight (kg)

#### 2. **Training Background**
- **Training Level**: Beginner / Intermediate / Advanced
  - *Beginner*: <1 year consistent training
  - *Intermediate*: 1-3 years
  - *Advanced*: 3+ years
- **Years Training**: Total years (can include breaks)
- **Consecutive Weeks**: Uninterrupted weeks currently training

#### 3. **Training Goals**
- **Primary Goal**: Muscle Gain / Strength / Fat Loss / General Fitness
- **Secondary Goals** (optional): Mobility, Endurance, Sport Performance

#### 4. **Availability**
- **Days Per Week**: 3-6 days
- **Session Duration**: 45-120 minutes

#### 5. **Recovery Metrics**
- **Average Sleep Hours**: 4-10 hours
- **Perceived Recovery Status**: 1-10 scale
  - 1-3: Severe fatigue
  - 4-6: Moderate fatigue
  - 7-8: Good recovery
  - 9-10: Excellent recovery
- **Stress Level**: 1-10 scale
- **Soreness 48h Post-Workout**: 0-10 scale

#### 6. **Restrictions & Preferences**
- **Injuries**: Select active injury regions
  - Shoulder, Elbow, Wrist, Lower Back, Knee, Ankle, Hip, Neck
- **Movement Restrictions**: Exercises to avoid
  - Overhead Press, Heavy Squats, Deadlifts, etc.
- **Exercise Preferences**: Favorite/disliked exercises

#### 7. **Performance History** (Optional but Recommended)
- **Average Weekly Sets**: Total sets per week across all muscles
- **Max Sets Tolerated**: Highest weekly volume before fatigue
- **Adherence Rate**: 0-100% (% of planned workouts completed)
- **Performance Trend**: Improving / Maintaining / Declining

### Step-by-Step: Creating a New Client

1. **Tap "New Client"** on Client List screen

2. **Fill Basic Info Section**
   ```
   Name: John Doe
   Age: 28
   Gender: Male
   Height: 175 cm
   Weight: 80 kg
   ```

3. **Set Training Background**
   ```
   Training Level: Intermediate
   Years Training: 2.5
   Consecutive Weeks: 8
   ```

4. **Define Goals**
   ```
   Primary Goal: Muscle Gain
   Days Per Week: 4
   Session Duration: 75 minutes
   ```

5. **Enter Recovery Metrics**
   ```
   Avg Sleep: 7 hours
   Recovery Status: 7/10
   Stress Level: 5/10
   Soreness: 4/10
   ```

6. **Add Restrictions (if any)**
   ```
   Injuries: Right Shoulder (minor)
   Movement Restrictions: Heavy Overhead Press
   ```

7. **Save Profile**
   - Tap "Save Client"
   - Profile is now ready for program generation

### Updating Existing Profiles

**When to Update:**
- Weekly: Recovery metrics (sleep, stress, soreness)
- Monthly: Weight, performance trend
- As needed: Injuries, goals, availability

**How to Update:**
1. Select client from Client List
2. Tap "Edit Profile"
3. Update relevant fields
4. Save changes

> ⚠️ **Important**: Always update recovery metrics before generating a new program. Outdated metrics can lead to suboptimal plans.

---

## Generating Training Programs

### The Generation Process

Motor V3 generates programs through a **7-phase pipeline**:

```
Phase 0: Context Building (30 fields)
    ↓
Phase 1: Feature Engineering (38 features)
    ↓
Phase 2: Decision Making (Volume + Readiness)
    ↓
Phase 3: ML Prediction Logging
    ↓
[Readiness Gate: Block if critical]
    ↓
Phase 4-7: Plan Construction
    ↓
Output: 4-Week Training Plan
```

### Generating Your First Program

#### Step 1: Select Client

From Client List, tap the client you want to generate a plan for.

#### Step 2: Tap "Generate Program V3"

The system will:
- Analyze 38 client features
- Calculate readiness score
- Determine optimal volume adjustment (0.7x - 1.3x)
- Check for overtraining risk

#### Step 3: Review Readiness Assessment

You'll see a readiness summary:

```
┌─────────────────────────────────────────┐
│ READINESS ASSESSMENT                    │
├─────────────────────────────────────────┤
│ Level: GOOD ✅                          │
│ Score: 0.72 / 1.00                      │
│ Confidence: 85%                         │
│                                         │
│ Metrics:                                │
│ • Fatigue Index: 0.45 (Moderate)       │
│ • Recovery Capacity: 0.68               │
│ • Overreaching Risk: 0.28 (Low)        │
│                                         │
│ Volume Adjustment: 0.9x                 │
│ (Slightly reduced due to recent stress) │
└─────────────────────────────────────────┘
```

**Readiness Levels:**
- 🔴 **CRITICAL**: Plan blocked, recommend deload week
- 🟠 **POOR**: Plan blocked, investigate fatigue sources
- 🟡 **FAIR**: Plan generated, conservative mode
- 🟢 **GOOD**: Plan generated, normal mode
- 💚 **EXCELLENT**: Plan generated, optimal volume

#### Step 4: Review Generated Plan

If readiness ≥ FAIR, you'll see:

```
┌─────────────────────────────────────────┐
│ 4-WEEK TRAINING PLAN                    │
├─────────────────────────────────────────┤
│ Split: Push/Pull/Legs (PPL)            │
│ Frequency: 4 days/week                  │
│ Total Volume: 96 sets/week              │
│                                         │
│ Week 1 (Accumulation):                  │
│  • Push Day: 8 exercises, 24 sets      │
│  • Pull Day: 8 exercises, 24 sets      │
│  • Legs Day: 7 exercises, 22 sets      │
│                                         │
│ Week 2-3 (Intensification):            │
│  • Progressive overload +5%             │
│                                         │
│ Week 4 (Deload):                        │
│  • 50% volume reduction                 │
└─────────────────────────────────────────┘
```

#### Step 5: Customize (Optional)

You can modify:
- Individual exercises (swap similar movements)
- Set counts (+/- 2 sets per exercise)
- RIR targets (within scientific bounds)

#### Step 6: Save & Start

- Tap "Save Plan"
- Client receives notification
- Program becomes active immediately

### Understanding Blocked Plans

If readiness is **CRITICAL** or **POOR**, the plan will be blocked.

**What You'll See:**

```
⛔ PROGRAM BLOCKED

Reason: Critical Fatigue Detected

Recommendations:
1. Immediate Deload (50% volume for 1 week)
2. Address Recovery Issues:
   • Sleep: Currently 5.2h, increase to 7+
   • Stress: Level 9/10, manage stressors
   • Nutrition: Check caloric intake

3. Re-generate program after deload week

Actions:
[Generate Deload Week] [View Recovery Tips]
```

**What to Do:**
1. **Generate Deload Week**: Creates 40-60% volume plan
2. **Address Root Causes**: Improve sleep, nutrition, stress management
3. **Re-assess in 7 days**: Update recovery metrics and re-generate

---

## Processing Workout Logs

### Why Log Workouts?

Workout logs enable Motor V3 to:
- **Track adherence** (% of planned workouts completed)
- **Measure fatigue accumulation** (RIR, RPE trends)
- **Detect performance trends** (strength gains, plateaus)
- **Train ML models** (outcome data for predictions)

### Logging Methods

#### Method 1: In-App Real-Time Logging (Recommended)

During the workout:

1. **Select Active Plan** → **Today's Session**
2. For each exercise, log:
   ```
   Exercise: Bench Press
   Set 1: 100 kg × 8 reps @ RIR 3
   Set 2: 100 kg × 7 reps @ RIR 2
   Set 3: 100 kg × 6 reps @ RIR 1
   ```
3. **Rate Session RPE** (1-10) at the end
4. **Add Notes** (optional): "Felt strong, increased weight"

#### Method 2: Post-Workout Entry

After the workout:

1. **Training Logs** → **Add Entry**
2. Select date and session
3. Enter completed sets/reps/load
4. Save

#### Method 3: Bulk Import (Advanced)

For coaches managing multiple clients:

1. **Training Logs** → **Import CSV**
2. Upload file in format:
   ```csv
   date,client_id,exercise,sets,reps,load,rir
   2026-02-01,john_doe,bench_press,3,8,100,2
   ```

### What to Log

**Essential Fields:**
- ✅ Exercise name
- ✅ Weight/Load (kg or lbs)
- ✅ Reps completed
- ✅ RIR (Reps in Reserve) per set

**Optional but Helpful:**
- Session RPE (overall difficulty)
- Rest times
- Tempo
- Notes (pain, form issues, PRs)

### Logging Best Practices

1. **Be Honest with RIR**: Accurate RIR enables better volume adjustments
2. **Log Immediately**: Don't trust memory for 3-4 sets later
3. **Include Failed Sets**: If you missed reps, log actual reps (not planned)
4. **Note Deviations**: If you skipped an exercise, mark it as skipped

---

## Interpreting Analytics and Charts

### Analytics Dashboard Overview

The Analytics Dashboard shows:

1. **Volume Trends** (Weekly Sets by Muscle Group)
2. **Intensity Distribution** (Heavy/Moderate/Light %)
3. **Performance Metrics** (Strength gains, endurance)
4. **Recovery Indicators** (Fatigue Index, Readiness Score)
5. **Adherence Rate** (% of planned workouts completed)
6. **ML Insights** (Predictions vs Outcomes)

### Key Charts Explained

#### 1. Weekly Volume Chart

```
Sets per Week
100 ├─────────────────────────────────
    │         ╱╲
 80 │        ╱  ╲
    │       ╱    ╲
 60 │      ╱      ╲____
    │     ╱            ╲
 40 │    ╱              ╲
    │   ╱                ╲
 20 │  ╱                  ╲
    │ ╱                    ╲
  0 └─────────────────────────────────
    W1  W2  W3  W4  W5  W6  W7  W8
```

**What it shows:**
- Total weekly sets across all muscle groups
- Deload weeks (W4, W8 show reduced volume)

**What to look for:**
- ✅ Gradual increase (not sudden jumps)
- ✅ Regular deloads every 3-4 weeks
- ⚠️ Excessive volume (>MRV for extended periods)
- ⚠️ Flat trend (no progressive overload)

#### 2. Readiness Score Timeline

```
Readiness Score (0-1.0)
1.0 ├─────────────────────────────────
    │     ●     ●
0.8 │   ●   ●     ●   ●
    │ ●           ●
0.6 │                   ●
    │                     ●
0.4 │                       ●
    │
0.2 │
    │
0.0 └─────────────────────────────────
    Mon Tue Wed Thu Fri Sat Sun
```

**What it shows:**
- Daily readiness fluctuations
- Impact of training sessions (drops after hard workouts)
- Recovery patterns

**What to look for:**
- ✅ Score returns to baseline within 48-72h
- ⚠️ Chronically low scores (<0.5 for >1 week)
- ⚠️ Declining trend (sign of overreaching)

#### 3. Muscle Group Balance

```
Sets per Muscle (4-week average)

Chest     ████████████████░░░░  16 sets
Back      ██████████████████░░  18 sets
Shoulders ████████████░░░░░░░░  12 sets
Quads     ████████████████░░░░  16 sets
Hamstrings████████████░░░░░░░░  12 sets
Arms      ██████████░░░░░░░░░░  10 sets

        0    5    10   15   20   25
```

**What it shows:**
- Volume distribution across muscle groups
- Balance vs imbalance

**What to look for:**
- ✅ Balanced volume for opposing muscles (chest ≈ back)
- ✅ Adequate volume for weak points
- ⚠️ Severe imbalances (chest 2× back)

#### 4. ML Prediction Accuracy

```
Predicted vs Actual Adherence

100% ├─────────────────────────────────
     │           ●   Actual
  80%│         ●   ●
     │       ●   /
  60%│     ●   /  ○ Predicted
     │   ○   /
  40%│  /  /
     │ /  /
  20%│/  /
     │  /
   0%└─────────────────────────────────
     Plan1 Plan2 Plan3 Plan4 Plan5
```

**What it shows:**
- How well Motor V3 predicted outcomes
- Model accuracy over time

**What to look for:**
- ✅ Predictions converge to actuals (model learning)
- ⚠️ Consistent over-prediction (plans too aggressive)
- ⚠️ Consistent under-prediction (plans too conservative)

### Interpreting Metrics

#### Fatigue Index (0.0 - 1.0)

| Range | Interpretation | Action |
|-------|----------------|--------|
| 0.0 - 0.3 | **Low Fatigue** | Can handle high volume |
| 0.3 - 0.5 | **Moderate Fatigue** | Normal training intensity |
| 0.5 - 0.7 | **High Fatigue** | Reduce volume 10-20% |
| 0.7 - 1.0 | **Critical Fatigue** | Immediate deload required |

#### Overreaching Risk (0.0 - 1.0)

| Range | Risk Level | Recommendation |
|-------|------------|----------------|
| 0.0 - 0.2 | **Minimal** | Continue as planned |
| 0.2 - 0.4 | **Low** | Monitor closely |
| 0.4 - 0.6 | **Moderate** | Consider conservative mode |
| 0.6 - 0.8 | **High** | Reduce volume, increase rest |
| 0.8 - 1.0 | **Critical** | Block plan, deload immediately |

#### Volume Optimality Index (0.0 - 1.0)

| Range | Interpretation | Action |
|-------|----------------|--------|
| 0.8 - 1.0 | **Optimal** | Perfect volume for growth |
| 0.6 - 0.8 | **Good** | Slightly below ideal |
| 0.4 - 0.6 | **Suboptimal** | Increase volume 10-20% |
| 0.0 - 0.4 | **Too Low** | Significantly increase volume |

---

## Common Workflows

### Workflow 1: Onboarding a New Client

**Steps:**
1. **Initial Consultation** (60 min)
   - Assess training history
   - Identify goals and restrictions
   - Measure anthropometrics

2. **Create Client Profile** (10 min)
   - Enter all data from consultation
   - Set conservative recovery metrics for first plan

3. **Generate First Program** (5 min)
   - Motor V3 generates 4-week plan
   - Review with client, explain exercises

4. **Baseline Testing** (Week 1, Session 1)
   - Test key lifts (bench, squat, deadlift)
   - Establish RIR calibration (teach client to gauge effort)

5. **Feedback Loop** (Week 2-4)
   - Client logs all workouts
   - Review adherence and fatigue
   - Adjust volume if needed

6. **Outcome Collection** (End of Week 4)
   - ML outcome dialog pops up
   - Rate: Adherence, Fatigue, Progress
   - Data saves to improve future plans

### Workflow 2: Weekly Client Check-In

**Monday Morning Routine:**

1. **Review Last Week's Logs** (5 min/client)
   ```
   - Did they complete all sessions?
   - Were RIR targets hit?
   - Any pain/injury reports?
   ```

2. **Update Recovery Metrics** (2 min/client)
   ```
   - Ask about sleep quality (last 7 days avg)
   - Stress level
   - Soreness
   ```

3. **Check Readiness Dashboard** (1 min/client)
   ```
   - Is readiness score trending down?
   - Any red flags (high fatigue, low recovery)?
   ```

4. **Adjust Current Plan** (if needed)
   ```
   - If fatigue high: Reduce 1-2 sets per session
   - If crushing it: Add 1 set to weak point muscles
   ```

### Workflow 3: Deload Week Management

**When to Deload:**
- Every 3-4 weeks (programmed)
- Readiness score <0.5 for 5+ consecutive days
- Client reports excessive soreness/fatigue
- Performance plateau or regression

**How to Deload:**

1. **Option A: Auto-Deload (Motor V3)**
   - Select client
   - Tap "Generate Deload Week"
   - System creates 50% volume plan automatically

2. **Option B: Manual Deload**
   - Keep same exercises
   - Reduce to 40-60% of normal sets
   - Maintain intensity (same weight, fewer reps)
   - Add extra rest day

**What to Tell Client:**
```
"This week is about recovery, not testing limits.
Goal: Maintain technique, feel fresh by Friday."
```

### Workflow 4: Injury Response Protocol

**When Client Reports Pain:**

1. **Assess Severity** (via questionnaire)
   ```
   - Pain level: 1-10
   - Type: Sharp / Dull / Burning
   - When: During lift / After / Next day
   ```

2. **Update Profile Immediately**
   ```
   Settings → Client Profile → Injuries
   Add: "Right Shoulder, Severity: Moderate"
   ```

3. **Add Movement Restrictions**
   ```
   Movement Restrictions → Enable:
   - Overhead Press
   - Bench Press (if shoulder pain)
   ```

4. **Regenerate Plan**
   ```
   Generate Program V3 → System auto-avoids restricted movements
   ```

5. **Alternative Exercises Suggested**
   ```
   Instead of Overhead Press:
   → Lateral Raises (lighter)
   → Incline Bench (30°, less shoulder stress)
   ```

### Workflow 5: Progress Review (Monthly)

**First Monday of Each Month:**

1. **Pull 4-Week Analytics Report**
   ```
   Analytics → Reports → Last 30 Days
   ```

2. **Review Key Metrics**
   ```
   ✓ Adherence: 85%+ target
   ✓ Volume Trend: Gradual increase
   ✓ Strength Gains: 2-5% per month
   ✓ Readiness Stability: Avg >0.6
   ```

3. **Goal Reassessment**
   ```
   - Is client on track for goal?
   - Need to adjust priorities?
   - Switch from muscle gain → strength?
   ```

4. **Update Profile**
   ```
   - New body weight
   - New training level (if progressed)
   - Adjust days/week if schedule changed
   ```

5. **Generate Next Mesocycle**
   ```
   Generate Program V3 → Fresh 4-week plan
   ```

---

## FAQ

### General Questions

**Q: How long does it take to generate a program?**  
A: 3-15 seconds depending on internet speed. The ML prediction logging adds ~2 seconds.

**Q: Can I generate plans offline?**  
A: No, Motor V3 requires internet for ML predictions and Firestore logging. Future versions may support offline mode with limited features.

**Q: How often should I regenerate programs?**  
A: Every 4 weeks (one mesocycle). You can regenerate earlier if:
- Client's goals change
- Injury occurs
- Readiness drops significantly
- Current plan too easy/hard

**Q: What's the difference between Motor V3 and Legacy Motor?**  
A:
| Feature | Legacy | Motor V3 |
|---------|--------|----------|
| Volume Adjustment | Fixed | Adaptive (0.7-1.3x) |
| Readiness Check | None | Critical gate |
| ML Predictions | No | Yes |
| Explainability | Partial | Full trace |

### Client Profile Questions

**Q: My client is a complete beginner (3 months training). Can I use Motor V3?**  
A: Yes, but consider:
- Set Training Level = Beginner
- Start with 3-4 days/week
- Focus on technique over volume
- Monitor fatigue closely (beginners often overestimate recovery)

**Q: What if client doesn't know their "average weekly sets"?**  
A: Use these estimates:
- Beginner: 40-60 sets/week
- Intermediate: 60-100 sets/week
- Advanced: 100-150+ sets/week

**Q: Can I manage clients with medical conditions?**  
A: Motor V3 handles common restrictions (injuries), but consult a medical professional for:
- Heart conditions
- Uncontrolled diabetes
- Recent surgeries
- Pregnancy

### Program Generation Questions

**Q: Why was my client's plan blocked?**  
A: Plans are blocked when:
- Readiness Level = CRITICAL or POOR
- Fatigue Index > 0.7
- Overreaching Risk > 0.6
- Recent injury flagged

**Q: Can I override a blocked plan?**  
A: No, for safety reasons. However, you can:
1. Generate a Deload Week instead
2. Address recovery issues
3. Re-generate after 7 days

**Q: How does volume adjustment work?**  
A: Motor V3 calculates a factor (0.7 - 1.3):
```
Adjusted Sets = Base Sets × Adjustment Factor

Example:
Base: 16 sets chest/week
Adjustment: 0.9x (slightly fatigued)
Final: 14.4 sets → rounded to 14 sets
```

**Q: What if client wants 7 days/week training?**  
A: Motor V3 supports 3-6 days/week. For 7 days:
- Use 6-day PPL split
- Add a 7th "active recovery" day (not in Motor V3)

### Workout Logging Questions

**Q: Client forgot to log a workout. Can I add it later?**  
A: Yes, use **Post-Workout Entry** method. You can backdate entries up to 30 days.

**Q: What if client doesn't understand RIR?**  
A: Educate them:
```
RIR 0 = Failure (couldn't do 1 more rep)
RIR 1 = Could do 1 more rep
RIR 2 = Could do 2 more reps
RIR 3 = Could do 3 more reps
```
Alternatively, log RPE (Rate of Perceived Exertion):
```
RPE 10 = RIR 0
RPE 9 = RIR 1
RPE 8 = RIR 2
```

**Q: Do I need to log warmup sets?**  
A: No, only working sets (sets that challenge the muscle).

### Analytics Questions

**Q: What's a "good" adherence rate?**  
A:
- 90-100%: Excellent
- 80-89%: Good
- 70-79%: Acceptable
- <70%: Investigate barriers

**Q: Fatigue Index is high but client feels fine. Is this a bug?**  
A: Possibly, but consider:
- Client may be underestimating fatigue
- Sleep quality (not just hours) matters
- Check for hidden stressors (work, life events)
- Re-calibrate recovery metrics

**Q: How do I interpret "ML Confidence" scores?**  
A: Confidence represents how certain the model is:
- 80-100%: High confidence (model has seen similar cases)
- 60-79%: Moderate confidence
- <60%: Low confidence (client is an outlier)

Low confidence doesn't mean bad prediction, just less certainty.

### ML & Data Questions

**Q: What happens to the ML outcome data I submit?**  
A: It's stored in Firestore (`ml_training_data` collection) and used to:
1. Train future ML models
2. Improve volume predictions
3. Refine readiness algorithms

All data is anonymized and encrypted.

**Q: When will ML models be "fully trained"?**  
A: Current timeline:
- **Q2 2026**: 500+ examples collected → model training begins
- **Q3 2026**: Model deployed, HybridStrategy activated
- **Q4 2026**: 100% ML predictions (if accuracy >90%)

**Q: Can I opt out of ML data collection?**  
A: Yes, when generating plans, set:
```
recordPrediction: false
```
However, this limits future personalization improvements.

### Troubleshooting

**Q: App crashes when generating program.**  
A:
1. Check internet connection
2. Update client profile (ensure no missing required fields)
3. Restart app
4. Contact support with error log

**Q: Generated plan has exercises my client can't do.**  
A:
1. Verify Equipment settings match gym availability
2. Check Movement Restrictions are properly set
3. Update Injury regions in profile
4. Re-generate plan

**Q: Readiness score seems inaccurate.**  
A:
1. Ensure recovery metrics are up-to-date
2. Verify sleep hours (actual sleep, not time in bed)
3. Re-assess stress level (use weekly average, not daily)
4. Check for data entry errors (e.g., soreness 10/10 every day)

**Q: Can't find a specific exercise in logs.**  
A: Use search function or:
1. Navigate to **Exercise Catalog**
2. Check if exercise is enabled
3. If missing, request addition via Support

---

## Next Steps

Now that you understand Motor V3, explore:

1. **[Developer Guide](developer-guide.md)** - For customization and integrations
2. **[API Reference](api-reference.md)** - For programmatic access
3. **[Scientific Foundation](../scientific-foundation/)** - Deep dive into the 7 Semanas

For support: support@hefestcs.com  
For feedback: feedback@hefestcs.com

---

**Version History:**
- v3.0.0 (Feb 2026): Initial Motor V3 release
- v2.5.0 (Jan 2026): Legacy Motor deprecation notice
- v2.0.0 (Dec 2025): Beta testing phase
