# Motor V2 to V3 Migration Status

**Date**: February 4, 2026  
**Status**: ⚠️ V2 REMOVED, V3 INTEGRATION BLOCKED

---

## Summary

The legacy V2 training engine has been successfully **removed** from the codebase. However, **V3 integration is blocked** due to incompatible APIs between the current system's data models and the V3 architecture.

---

## What Was Removed ✅

### Deleted Directories
- `lib/domain/training_v2/` (16 files, complete removal)
  - `engine/` - TrainingProgramEngineV2, TrainingProgramEngineV2Full
  - `engine/phases/` - Phase 1-8 implementations
  - `models/` - TrainingContext, TrainingBlockContext
  - `services/` - TrainingContextBuilder, TrainingContextNormalizer
  - `errors/` - TrainingContextError
  - `mappers/` - TrainingProfileFromContextMapper

### Deleted Files in lib/domain/services/
- `phase_1_data_ingestion_service.dart`
- `phase_2_readiness_evaluation_service.dart`
- `phase_3_volume_capacity_model_service.dart`
- `phase_4_split_distribution_service.dart`
- `phase_4_5_session_structure_service.dart`
- `phase_5_periodization_service.dart`
- `phase_6_exercise_selection_service.dart`
- `phase_7_prescription_service.dart`
- `phase_8_adaptation_service.dart`
- `training_program_engine.dart`

### Deleted Files in lib/domain/training/
- `facade/training_engine_facade.dart`

### Total Files Removed
**27 files** containing **~15,500 lines of code**

---

## What Was Modified ✅

### lib/features/training_feature/providers/training_plan_provider.dart
**Changes:**
- ❌ Removed imports:
  - `import 'package:hcs_app_lap/domain/training_v2/engine/training_program_engine_v2_full.dart';`
  - `import 'package:hcs_app_lap/domain/training_v2/services/training_context_builder.dart';`

- ✅ Added imports:
  - `import 'package:hcs_app_lap/domain/training_v3/ml_integration/hybrid_orchestrator_v3.dart';`
  - `import 'package:hcs_app_lap/domain/training_v3/ml_integration/ml_config_v3.dart';`
  - `import 'package:hcs_app_lap/domain/training_v3/ml/strategies/rule_based_strategy.dart';`
  - `import 'package:hcs_app_lap/domain/training_v3/models/training_program.dart';`

- 🚫 Blocked V2 generation code (lines ~567-595):
  - Replaced with early return and error message
  - Error: "Motor V3 requiere capa de adaptadores (Client → UserProfile)"
  - Added TODO comments explaining the blocking issue

### lib/domain/index.dart
**Changes:**
- Removed all V2 exports (Phase 1-8 services, engines, models, facades)
- Added comment: "All training_v2 files have been removed and migrated to V3"

### lib/domain/training_v3/ml/feature_vector.dart
**Changes:**
- Commented out: `import 'package:hcs_app_lap/domain/training_v2/models/training_context.dart';`
- Added TODO: "TrainingContext removed with V2 cleanup - need to create V3 equivalent"
- Method `FeatureVector.fromContext()` now broken (depends on TrainingContext)

### lib/domain/training_v3/ml/training_dataset_service.dart
**Changes:**
- Commented out: `import 'package:hcs_app_lap/domain/training_v2/models/training_context.dart';`
- Added TODO: "TrainingContext removed with V2 cleanup - need to create V3 equivalent"
- Methods depending on TrainingContext now broken

---

## Blocking Issue ⚠️

### Incompatible APIs

**Current System (V2) Models:**
- `Client` (from lib/domain/entities/client.dart)
  - Contains: profile, history, training, anthropometry, etc.
  - Used throughout entire app
- `TrainingPlanConfig` (from lib/domain/entities/training_plan_config.dart)
  - Contains: weeks, sessions, prescriptions
  - Used by UI components
- `Exercise` (from lib/domain/entities/exercise.dart)
  - Exercise catalog entries

**V3 Architecture Models:**
- `UserProfile` (from lib/domain/training_v3/models/user_profile.dart)
  - Contains: age, gender, trainingLevel, availableDays, etc.
  - Completely different structure from `Client`
- `TrainingProgram` (from lib/domain/training_v3/models/training_program.dart)
  - Contains: split, sessions, weeklyVolumeByMuscle
  - Different structure from `TrainingPlanConfig`

**V3 Orchestrator API:**
```dart
HybridOrchestratorV3.generateHybridProgram({
  required UserProfile userProfile,  // ❌ Needs UserProfile, not Client
  required String phase,
  required int durationWeeks,
})
```

**Current Provider Needs:**
```dart
// Has access to:
Client freshClient
List<Exercise> exercises
DateTime startDate

// Needs to produce:
TrainingPlanConfig planConfig
```

---

## Current App Behavior 🚫

When user tries to generate a training plan:

1. ✅ Provider loads client data
2. ✅ Provider loads exercise catalog
3. ✅ Provider creates/retrieves training cycle
4. ❌ **BLOCKED**: Generation code returns early with error:
   ```
   "Motor V3 requiere capa de adaptadores (Client → UserProfile). Migración en progreso."
   ```
5. ❌ User sees error message
6. ❌ No training plan is generated

**Result**: Training plan generation is completely non-functional until adapters are implemented.

---

## What's Needed to Complete Migration 🔨

### Option 1: Create Adapter Layer (Recommended)

Create bidirectional adapters to bridge V2 and V3 models:

#### 1. Client → UserProfile Adapter
**File**: `lib/domain/training_v3/adapters/client_to_user_profile_adapter.dart`

```dart
class ClientToUserProfileAdapter {
  static UserProfile convert(Client client) {
    final training = client.training;
    final profile = client.profile;
    
    return UserProfile(
      id: client.id,
      name: '${profile.firstName} ${profile.lastName}',
      email: profile.email ?? '',
      age: profile.age ?? 30,
      gender: _mapGender(profile.gender),
      heightCm: profile.anthropometry?.height ?? 170.0,
      weightKg: profile.anthropometry?.weight ?? 70.0,
      trainingLevel: _mapTrainingLevel(training.trainingLevel),
      availableDays: training.daysPerWeek ?? 4,
      primaryGoal: _mapGoal(training.globalGoal),
      // ... map all other fields
    );
  }
  
  static String _mapGender(Gender? gender) {
    // Implementation
  }
  
  static String _mapTrainingLevel(TrainingLevel? level) {
    // Implementation
  }
  
  // ... other mapping methods
}
```

#### 2. TrainingProgram → TrainingPlanConfig Adapter
**File**: `lib/domain/training_v3/adapters/training_program_to_plan_config_adapter.dart`

```dart
class TrainingProgramToPlanConfigAdapter {
  static TrainingPlanConfig convert(
    TrainingProgram program,
    String clientId,
    DateTime startDate,
  ) {
    return TrainingPlanConfig(
      id: program.id,
      clientId: clientId,
      name: 'Training Plan ${DateTime.now().toIso8601String()}',
      startDate: startDate,
      weeks: _convertWeeks(program.weeks, startDate),
      trainingProfileSnapshot: _createProfileSnapshot(program),
      // ... map all other fields
    );
  }
  
  static List<TrainingWeek> _convertWeeks(
    List<WeekPlan> weeks,
    DateTime startDate,
  ) {
    // Implementation
  }
  
  // ... other mapping methods
}
```

#### 3. Update training_plan_provider.dart
Replace the blocked code (lines ~567-595) with:

```dart
// Convert Client to UserProfile
final userProfile = ClientToUserProfileAdapter.convert(freshClient);

// Create V3 orchestrator with RuleBased strategy
final orchestrator = HybridOrchestratorV3(
  config: MLConfigV3(
    strategy: RuleBasedStrategy(),
    recordPredictions: false,
  ),
);

// Generate program
final result = await orchestrator.generateHybridProgram(
  userProfile: userProfile,
  phase: 'accumulation', // or determine from activeCycle
  durationWeeks: 4,
);

if (!result['success']) {
  state = state.copyWith(
    isLoading: false,
    error: result['errors'].join(', '),
  );
  return;
}

final v3Program = result['program'] as TrainingProgram;

// Convert V3 TrainingProgram to V2 TrainingPlanConfig
final planConfig = TrainingProgramToPlanConfigAdapter.convert(
  v3Program,
  clientId,
  startDate,
);

// Continue with persistence code (unchanged)
```

#### 4. Recreate TrainingContext for V3 ML
**File**: `lib/domain/training_v3/models/training_context_v3.dart`

Create a V3 equivalent of TrainingContext that:
- Contains fields needed by FeatureVector
- Can be constructed from Client
- Doesn't depend on V2 models

Then update:
- `lib/domain/training_v3/ml/feature_vector.dart`
- `lib/domain/training_v3/ml/training_dataset_service.dart`

---

### Option 2: Revert V2 Removal (If V3 Not Ready)

If V3 is not ready for production:

1. Revert this PR
2. Keep V2 engine functional
3. Complete V3 implementation separately
4. Migrate when V3 is fully compatible

---

## Compilation Status 📊

### Expected Errors:

1. **lib/domain/training_v3/ml/feature_vector.dart**
   - Error: `TrainingContext` undefined
   - Cause: Commented import after V2 deletion
   - Impact: V3 ML feature engineering broken

2. **lib/domain/training_v3/ml/training_dataset_service.dart**
   - Error: `TrainingContext` undefined
   - Cause: Commented import after V2 deletion
   - Impact: V3 ML dataset service broken

3. **Runtime Error in training_plan_provider.dart**
   - Error: Early return with error message
   - Cause: V3 integration incomplete
   - Impact: Training plan generation non-functional

### Files That Should Still Compile:
- All UI components (no direct V2 dependencies)
- All data repositories
- All other domain services
- V3 services (except ML components)

---

## Testing Recommendations 🧪

### Before Adapter Implementation:
1. ✅ Verify app compiles (with expected errors in V3 ML files)
2. ✅ Verify app runs without crashes
3. ✅ Verify training plan generation shows error message (not crash)
4. ✅ Verify other app features still work

### After Adapter Implementation:
1. ✅ Test Client → UserProfile conversion with real data
2. ✅ Test V3 program generation
3. ✅ Test TrainingProgram → TrainingPlanConfig conversion
4. ✅ Test UI displays converted plan correctly
5. ✅ Test plan persistence in Firestore
6. ✅ Test volume tab (14 canonical muscles)
7. ✅ Test sessions tab (expandable weeks)

---

## Rollback Instructions 🔄

If this migration needs to be reverted:

```bash
# Revert the commit
git revert 4282c75

# Or reset to before the change
git reset --hard abeae26

# Force push (if necessary)
git push origin copilot/remove-legacy-engine-v2 --force
```

---

## Next Steps 📋

### Immediate (To restore functionality):
1. [ ] Implement ClientToUserProfileAdapter
2. [ ] Implement TrainingProgramToPlanConfigAdapter
3. [ ] Update training_plan_provider.dart with adapters
4. [ ] Test end-to-end plan generation

### Short-term (To fix V3 ML):
5. [ ] Create TrainingContextV3 model
6. [ ] Update FeatureVector.fromContext to use V3 models
7. [ ] Update TrainingDatasetService to use V3 models

### Long-term (To improve architecture):
8. [ ] Gradually migrate UI to use V3 models directly
9. [ ] Remove adapter layer once UI is migrated
10. [ ] Deprecate V2 model classes

---

## Files Reference 📁

### Modified Files:
- `lib/features/training_feature/providers/training_plan_provider.dart`
- `lib/domain/index.dart`
- `lib/domain/training_v3/ml/feature_vector.dart`
- `lib/domain/training_v3/ml/training_dataset_service.dart`

### Deleted Files:
- 27 files in `lib/domain/training_v2/`
- 9 files in `lib/domain/services/phase_*.dart`
- 1 file in `lib/domain/services/training_program_engine.dart`
- 1 file in `lib/domain/training/facade/training_engine_facade.dart`

### New Files Needed:
- `lib/domain/training_v3/adapters/client_to_user_profile_adapter.dart`
- `lib/domain/training_v3/adapters/training_program_to_plan_config_adapter.dart`
- `lib/domain/training_v3/models/training_context_v3.dart`

---

## Questions? 💬

For questions or issues with this migration, refer to:
- Problem statement: Original migration requirements
- This document: Current status and next steps
- V3 documentation: `docs/motor-v3/developer-guide.md`
- V3 API reference: `docs/motor-v3/api-reference.md`

---

**Author**: GitHub Copilot  
**Date**: February 4, 2026  
**PR**: copilot/remove-legacy-engine-v2  
**Commit**: 4282c75
