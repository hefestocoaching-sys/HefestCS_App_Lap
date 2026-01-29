# Volume Budget Balancer - Usage Examples

## Example 1: Reading Persisted Data

```dart
void exampleReadPersistedData() {
  final client = /* trainingProfile aquí */;
  final extra = client.trainingProfile.extra ?? {};

  // MEV por músculo (minimum effective volume)
  final mevByMuscle = (extra['mevByMuscle'] as Map?)?.cast<String, double>() ?? {};

  // MRV por músculo (maximum recoverable volume)
  final mrvByMuscle = (extra['mrvByMuscle'] as Map?)?.cast<String, double>() ?? {};

  // Sets efectivos calculados por el balanceador
  final effectiveSetsByMuscle =
      (extra['effectiveSetsByMuscle'] as Map?)?.cast<String, double>() ?? {};

  print('MEV por músculo: $mevByMuscle');
  print('MRV por músculo: $mrvByMuscle');
  print('Sets efectivos: $effectiveSetsByMuscle');
}
```

## Example 2: Exercise Contribution Patterns

Different exercise types have different muscle contribution patterns:

### Press Pattern (Bench Press)
```
Chest: 1.0 (primary)
Triceps: 0.6 (secondary)
Shoulders: 0.4 (tertiary)
```

### Pull Pattern (Lat Pulldown)
```
Back: 1.0 (primary)
Biceps: 0.7 (secondary)
Shoulders: 0.3 (tertiary)
```

### Lower Pattern (Back Squat)
```
Quads: 1.0 (primary)
Glutes: 0.8 (secondary)
Back: 0.6 (tertiary)
Hamstrings: 0.4 (quaternary)
```

## Example 3: Effective Sets Calculation

Given a plan with:
- Bench Press 4 sets
- Lat Pulldown 4 sets
- Back Squat 5 sets

Effective sets per muscle would be:
```
Chest: 4 × 1.0 = 4.0
Triceps: 4 × 0.6 = 2.4
Shoulders: 4 × 0.4 + (lat_pulldown × 0.3) + (squat × 0.1) = ... (aggregated)
Back: 4 × 1.0 + 5 × 0.6 = 7.0
Biceps: 4 × 0.7 = 2.8
Quads: 5 × 1.0 = 5.0
Glutes: 5 × 0.8 = 4.0
Hamstrings: 5 × 0.4 = 2.0
```

## Example 4: Balancer Iteration

If MRV for Triceps = 10 but effective is 12.5:

**Iteration 1:**
- Worst muscle: Triceps (excess = 2.5)
- Highest contributor: Bench Press (contribution = 0.6)
- Action: Reduce bench press from 4 to 3 sets
- New effective: 3 × 0.6 = 1.8 (triceps down to 11.2)

**Iteration 2:**
- Worst muscle: Triceps (excess = 1.2)
- Action: Reduce bench press from 3 to 2 sets
- New effective: 2 × 0.6 = 1.2 (triceps down to 10.0)

**Done**: All muscles ≤ MRV

## Example 5: Performance Metrics

For a typical weekly plan:
- **4 weeks × 4 sessions × 3 exercises = 48 total sets**
- **Effective sets calculation**: ~50ms
- **Balancer iterations**: 5-15 typical, <100ms total
- **Plan reconstruction**: ~20ms
- **Total time**: <200ms

## Example 6: Debugging Output

When balancer runs, look for these logs:

```
✅ No corrections needed (effective ≤ MRV)
→ 0 iterations

⚡ Light correction needed
→ 5-10 iterations, <20 sets reduced

⚠️ Significant correction needed
→ 15-30 iterations, >20 sets reduced

🛑 Blocked (cannot resolve)
→ 500 iterations, some muscles still > MRV
→ Check if MRV is too conservative
```

## Example 7: Verification Checklist

After plan generation:

- [ ] Check `effectiveSetsByMuscle` all ≤ `mrvByMuscle`
- [ ] Verify no exercise has less than 1 set
- [ ] Confirm plan is still structured (weeks → sessions → prescriptions)
- [ ] Validate that MEV ≤ effective ≤ MRV for all muscles
- [ ] Review decision trace for balancer output
- [ ] Test UI rendering of updated plan

## Example 8: Common Issues

**Issue**: Balancer blocked after 500 iterations
```
Cause: MRV is too low relative to plan structure
Solution: Increase global MRV or adjust evidence factors
```

**Issue**: effectiveSetsByMuscle is empty
```
Cause: mrvByMuscle not derived (user didn't save evaluation)
Solution: Complete training evaluation tab before generating plan
```

**Issue**: Same sets as original (0 iterations)
```
Cause: Plan was already compliant
Solution: This is normal, no correction needed
```

## Example 9: Data Persistence Verification

Check Firebase Console:
```
Collection: clients
Document: {clientId}
Field: trainingProfile
SubField: extra

Look for keys:
- mevByMuscle (should be a map)
- mrvByMuscle (should be a map)
- effectiveSetsByMuscle (should be a map)
```

## Example 10: Future Extensions

### Strategy B2 (Exercise Swaps)
```
Instead of: bench_press 4 → 3 (triceps reduction)
Could do: close_grip_bench_press (less triceps contribution)
Or: dips (more efficient for triceps)
```

### Adaptive Learning
```
Track when user reports "too much triceps fatigue"
Lower triceps factor from 0.80 → 0.75 over time
→ More conservative TCeps estimates
```

### Injury Constraints
```
If user has "shoulder injury":
- Reduce shoulder factor from 0.90 → 0.60
- Skip exercises with high shoulder contribution
- Suggest modifications
```

## Summary

The Volume Budget Balancer transparently:
1. **Calculates** multi-muscle effective volume
2. **Identifies** problematic muscles
3. **Reduces** sets intelligently
4. **Reconstructs** the plan immutably
5. **Persists** for audit and future learning
6. **Logs** all decisions for debugging

No UI changes needed—the plan just gets smarter automatically.
