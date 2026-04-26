# Training Motor Phase 3 - Catalog, Selector and Intensity Materialization

## Scope
Changes were applied only in:
- lib/domain/training_v3/data/exercise_catalog_v3.dart
- lib/domain/entities/exercise.dart
- lib/domain/training_v3/engines/exercise_selection_engine.dart
- lib/domain/training_v3/services/cycle_template_builder.dart
- lib/domain/training_v3/engines/intensity_distribution_engine.dart
- lib/domain/training_v3/engines/intensity_engine.dart

Catalog source audited:
- assets/data/exercises/exercise_catalog_gym.json

Note: there is no file named exercise_catalog_v3.json in this workspace. The active V3 catalog loader uses exercise_catalog_gym.json.

## How Selector Works Now
1. Strict candidate filtering:
- target muscle (canonical)
- intensity zone compatibility
- available equipment
- explicit restrictions/injury constraints

2. Deterministic ordering:
- stimulusScore (desc)
- fatigueScore (asc)
- movementPattern match (preferred first)
- weekly variation (recent exercises moved down)
- stable tie-breaker by id

3. No global fallback:
- removed arbitrary global picks when no candidate exists
- missing candidates now raise explicit StateError in strict paths

## How Intensity Is Materialized
- Zones are explicitly materialized per selected exercise in CycleTemplateBuilder.
- Zone compatibility is validated with catalog metadata before adding each exercise.
- Rep ranges are fixed by zone:
  - heavy -> 6-8
  - medium -> 8-12
  - light -> 15-20

## Controlled Fallback Still Allowed
- Equivalence fallback only:
  - same equivalenceGroup
  - same movementPattern
  - same zone
  - same muscle context
- If equivalence does not resolve a valid candidate:
  - error is explicit/traced (StateError or explicit error log)
  - no permissive "any-zone" fallback is used

## Errors Blocked Explicitly
Examples of explicit blocked errors now:
- missing metadata for intensity validation
- insufficient exercises compatible with target zone
- exercise selected for a zone it does not allow
- strict selector with no candidates after filters

## Pending / Follow-up
- Catalog still contains legacy muscle aliases in JSON values (normalized at runtime).
- Some outer flows may still call legacy selector methods without passing zone context.
- Optional next hardening: export a dedicated catalog diagnostics report for stale aliases or weak metadata ranges.
