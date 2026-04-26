# Forensic Catalog SSOT Status

## Pregunta
¿El catálogo V3 es SSOT real en runtime?

## Evidencia
- `ExerciseCatalogV3.ensureLoaded()` carga obligatoriamente:
  - `exercise_catalog_v3_runtime.json`
  - `exercise_pattern_registry_v3.json`
  - `exercise_muscle_zone_defaults_v3.json`
  - `exercise_slot_conflict_rules_v3.json`
  - `exercise_media_library_v3.json`
- `MotorV3Orchestrator` ignora lista externa de ejercicios y declara runtime SSOT desde assets.
- `ExerciseCatalogV3Entry` exige campos críticos (`id`, `name`, `primaryMuscles`, `allowedIntensityZones`, `slotRoles`, `exerciseOrderClass`, etc.).

Referencias:
- `lib/domain/training_v3/data/exercise_catalog_v3.dart`
- `lib/domain/training_v3/models/exercise_catalog_v3_entry.dart`
- `lib/domain/training_v3/services/motor_v3_orchestrator.dart` (log de ignore external list)

## Hallazgo Principal
**SSOT runtime = SI, pero parcial a nivel semántico.**

Se consumen y validan campos contractuales de selección/estructura/intensidad, pero una parte relevante de metadata del JSON runtime no participa en decisiones del motor.

## Campos Runtime No Integrados A Decisión (observado)
- `aliases`
- `exerciseFamily`
- `patternTier`
- `pairingTags`
- `stabilityScore`
- `technicalDemand`
- `jointStress`
- `systemicDemand`
- `intensificationEligibleZones`
- `mediaLookupHints`
- `sourceBank`
- `reviewNeeded` / `reviewReason`

## Impacto
- **P1**: Riesgo de creer que todo el catálogo gobierna runtime cuando solo gobierna una porción.
- **P2**: Dificulta auditoría de trazabilidad (qué campos son normativos vs informativos).

## Veredicto
- **SSOT técnico (archivo fuente único en runtime)**: `SI`.
- **SSOT contractual completo (todos los metadatos gobiernan decisiones)**: `NO`.
