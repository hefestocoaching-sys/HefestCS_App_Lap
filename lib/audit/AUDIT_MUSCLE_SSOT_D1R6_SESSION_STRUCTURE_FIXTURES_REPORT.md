# AUDIT MUSCLE SSOT D1R6 - SessionStructureEngine fixtures observacionales

Fecha: 2026-05-26  
Proyecto: HefestoCS / hcs_app_lap  
Scope: D1R6, fixtures/goldens observacionales antes de migrar `SessionStructureEngine`.

## 1. Resumen ejecutivo

D1R6 queda aplicado como baseline observacional. Se audito `SessionStructureEngine` sin modificar produccion y se crearon fixtures JSON + test de regresion para congelar el comportamiento actual antes de migrarlo a MuscleRegistry strict API.

Hallazgo principal: `SessionStructureEngine._primaryMuscle` usa normalizacion legacy permisiva:

- `muscle_registry.normalize(raw)`
- `muscle_registry.expandGroup(raw)`
- fallback `raw.trim().toLowerCase()`

Esto permite raw passthrough para unknowns como `unknown_muscle`, `back_mid_upper` y `mysterychest`. Ademas, `glute` se convierte a `glutes` por el normalizador legacy. D1R6 no corrige esto; solo lo congela.

## 2. Confirmacion de scope

Aplicado:
- Inspeccion read-only de `lib/domain/training_v3/engines/session_structure_engine.dart`.
- Fixtures observacionales en `test/fixtures/training_v3/session_structure/`.
- Test de regresion en `test/domain/training_v3/regression/session_structure_engine_fixtures_regression_test.dart`.
- Reporte en `lib/audit/AUDIT_MUSCLE_SSOT_D1R6_SESSION_STRUCTURE_FIXTURES_REPORT.md`.

No aplicado:
- No se migro `SessionStructureEngine`.
- No se modifico logica productiva.
- No se tocaron MotorV3Orchestrator, CycleTemplateBuilder, ExerciseSelectionEngine, UI, DB, modelos ni repositorios.

## 3. Archivos modificados

- `test/fixtures/training_v3/session_structure/session_structure_canonical.json`
- `test/fixtures/training_v3/session_structure/session_structure_alias.json`
- `test/fixtures/training_v3/session_structure/session_structure_unknown.json`
- `test/fixtures/training_v3/session_structure/session_structure_mixed.json`
- `test/fixtures/training_v3/session_structure/session_structure_pairing_cases.json`
- `test/fixtures/training_v3/session_structure/session_structure_intensity_cases.json`
- `test/fixtures/training_v3/session_structure/session_structure_order_cases.json`
- `test/domain/training_v3/regression/session_structure_engine_fixtures_regression_test.dart`
- `lib/audit/AUDIT_MUSCLE_SSOT_D1R6_SESSION_STRUCTURE_FIXTURES_REPORT.md`

## 4. Archivos inspeccionados

- `lib/domain/training_v3/engines/session_structure_engine.dart`
- `lib/domain/training_v3/engines/exercise_ordering_engine.dart`
- `lib/domain/training_v3/engines/fatigue_balancer.dart`
- `lib/domain/training_v3/engines/antagonist_pairing_engine.dart`
- `lib/domain/policies/pairing_contract.dart`
- `lib/domain/training_v3/data/interference_matrix.dart`
- `lib/domain/training_v3/data/exercise_catalog_v3.dart`
- `lib/domain/training_v3/models/planned_exercise.dart`
- `lib/domain/entities/training_session.dart`

## 5. Metodos publicos de SessionStructureEngine

- `refinePlannedExercises(List<PlannedExercise> exercises)`: preserva estructura completa existente o rellena metadata estructural usando `build`.
- `build(List<Exercise> exercises)`: ordena, balancea fatiga, elige main lift y arma bloques A/B/C/D.

Clases de salida relacionadas:
- `SessionStructure`
- `SessionBlock`
- `StructuredExercisePlacement`

## 6. Inputs requeridos

`build` requiere:
- `List<Exercise> exercises`

El test usa ejercicios fake minimos con:
- `id`
- `name`
- `primaryMuscles`
- `movementPattern`
- `loadCategory`
- `fatigueScore`
- `stimulusScore`

`refinePlannedExercises` requiere:
- `List<PlannedExercise>`
- catalogo cargado para resolver `exerciseId`

## 7. Outputs observados

El snapshot congelado compara:
- `mainLiftId`
- `flattenedIds`
- bloques con `blockLabel`, `slotFirst`, `slotSecond`, `pairGroupId`, `isBiserie`
- placements con `blockLabel`, `slotLabel`, `pairGroupId`, `isMainLift`

Observaciones:
- A es siempre el main lift.
- B recibe antagonistas del main lift.
- C recibe candidatos de baja interferencia compatibles con main y B.
- D recibe complementarios/restantes y puede formar biserie.
- Si D1 queda como single, el comportamiento actual ya no arma biserie en D2 aunque exista una pareja sinergista posterior.

## 8. Dependencias del engine

- `Exercise`
- `ExerciseCatalogV3`
- `InterferenceMatrix`
- `AntagonistPairingEngine`
- `ExerciseOrderingEngine`
- `FatigueBalancer`
- `PlannedExercise`
- `PairingContract`
- `MuscleRegistry` legacy importado como `muscle_registry`

## 9. Uso actual de MuscleRegistry o legacy normalizer

Evidencia en `session_structure_engine.dart`:
- `_primaryMuscle` usa `muscle_registry.normalize(raw)`.
- Si no hay canonical legacy, usa `muscle_registry.expandGroup(raw)`.
- Si no expande, retorna `raw.trim().toLowerCase()`.

Ademas:
- `AntagonistPairingEngine` usa `core/utils/muscle_key_normalizer.dart`.
- `PairingContract` tambien usa `muscle_registry.normalize` y `expandGroup`.

## 10. Raw passthrough detectado

Detectado:
- `unknown_muscle` pasa como raw lowercase.
- `back_mid_upper` pasa como raw lowercase.
- `mysterychest` pasa como raw lowercase.
- `glute` se convierte a `glutes` por legacy normalize.

Durante el test se observan warnings de unknown muscle key, pero no bloquean la estructura. Los ejercicios unknown siguen entrando a bloques.

## 11. Fixtures creados

- `session_structure_canonical.json`
- `session_structure_alias.json`
- `session_structure_unknown.json`
- `session_structure_mixed.json`
- `session_structure_pairing_cases.json`
- `session_structure_intensity_cases.json`
- `session_structure_order_cases.json`

## 12. Casos cubiertos

Canonical:
- `pectorals`, `lats`, `quads`, `glutes`.

Alias:
- `chest`, `quadriceps`, `gluteos`, `deltoide_anterior`.

Unknown:
- `unknown_muscle`, `back_mid_upper`, `mysterychest`, `glute`.

Mixed:
- `pectorals`, `chest`, `lats`, `quadriceps`, `unknown_muscle`, `glute`, `back_mid_upper`.

Pairing:
- antagonista B.
- baja interferencia C.
- sinergia/biserie D.
- slots B1, C1/C2, D1/D2.

Intensity:
- `heavy`, `medium`, `light` via `loadCategory`.
- El engine no recibe `intensityZone` directo.

Order:
- El main lift sale por score, no por orden de entrada.
- Orden estable observado por `ExerciseOrderingEngine` + `FatigueBalancer`.

## 13. Resultado observado por caso

- Canonical: `pectorals` queda como A; `lats` entra en B; `quads + glutes` forman biserie D.
- Alias: aliases validos funcionan por legacy normalize, pero los `Exercise.primaryMuscles` permanecen raw.
- Unknown: unknowns no se descartan; se estructuran como ejercicios validos.
- Mixed: `pectorals` y `chest` son ejercicios distintos; unknowns permanecen; `glute` no se descarta.
- Pairing: B/C/D se construyen segun antagonista, baja interferencia y sinergia.
- Intensity: `loadCategory` participa en el score de ordenamiento.
- Order: un ejercicio de alta puntuacion queda como main aunque no sea el primero del input.

## 14. Tabla de aliases

| Input | Output actual | Strict esperado futuro |
|---|---|---|
| `chest` | Internamente normaliza como `pectorals`; objeto conserva raw `chest` | `pectorals` canonical |
| `quadriceps` | Internamente normaliza como `quads`; objeto conserva raw `quadriceps` | `quads` canonical |
| `gluteos` | Internamente normaliza como `glutes`; objeto conserva raw `gluteos` | `glutes` canonical |
| `deltoide_anterior` | Internamente normaliza como `delts_front`; objeto conserva raw `deltoide_anterior` | `delts_front` canonical |

## 15. Tabla de unknowns

| Input | Output actual | Strict esperado futuro |
|---|---|---|
| `unknown_muscle` | Warning, pero pasa como raw lowercase y se estructura | descartar/no matchear |
| `back_mid_upper` | Warning, pero pasa como raw lowercase y se estructura | descartar/no matchear |
| `mysterychest` | Warning, pero pasa como raw lowercase y se estructura | descartar/no matchear |
| `glute` | Se convierte a `glutes` por legacy normalize | descartar/no matchear |

## 16. Riesgos

Riesgo alto:
- `_primaryMuscle` tiene fallback `raw.trim().toLowerCase()`; esto permite raw passthrough.
- Unknowns pueden influir en buckets B/C/D como complementarios en vez de descartarse.

Riesgo medio:
- `PairingContract` y `AntagonistPairingEngine` tienen normalizacion legacy propia; D1-C6 debe decidir si se migra solo el engine o tambien helpers directos.
- `glute` se trata como `glutes` por legacy, contrario al contrato strict esperado.

Riesgo menor:
- El engine no expone decision trace; los fixtures congelan outputs estructurales.
- El test hook `ExerciseCatalogV3.loadFromExercises` no modela `category: isolation`, por lo que accesorios reales deben revisarse en D1-C6 si se toca ese camino.

## 17. Tests ejecutados

Nuevo test D1R6:
- `flutter test test/domain/training_v3/regression/session_structure_engine_fixtures_regression_test.dart --reporter expanded`
- Resultado: `+7`, `All tests passed!`

Regresion ExerciseSelection D1-C5:
- `flutter test test/domain/training_v3/regression/exercise_selection_engine_fixtures_regression_test.dart --reporter expanded`
- Resultado: `+11`, `All tests passed!`

Regresion WeeklyVolume:
- `flutter test test/domain/training_v3/regression/weekly_volume_planner_fixtures_regression_test.dart --reporter expanded`
- Resultado: `+8`, `All tests passed!`

Suite SSOT focalizada:
- `flutter test test/core/registry/muscle_registry_strict_test.dart test/features/training_feature/domain/exercise_preferences_muscle_key_mapper_strict_test.dart test/domain/training_v3/resolvers/muscle_to_catalog_resolver_strict_test.dart test/domain/training_v3/utils/muscle_key_adapter_v3_strict_test.dart test/domain/training_v3/validators/training_plan_forensic_validator_muscle_ssot_test.dart test/domain/training/models/mev_table_strict_muscle_test.dart test/domain/training/validation/vop_validator_strict_muscle_test.dart test/domain/training_v3/validators/volume_validator_strict_muscle_test.dart --reporter expanded`
- Resultado: `+55`, `All tests passed!`

Nota de entorno:
- El primer test D1R6 se ejecuto fuera del sandbox con aprobacion porque los `flutter test` de este repo han sido inestables dentro del sandbox.

## 18. Resultado flutter analyze

Comando:
- `flutter analyze --no-pub`

Resultado:
- `No issues found! (ran in 3.3s)`

## 19. Siguiente sprint recomendado

D1-C6: migrar `SessionStructureEngine` a MuscleRegistry strict API.

Recomendacion:
- Sustituir `_primaryMuscle` por helper strict basado en `tryNormalizeMuscleKey`.
- Definir contrato para unknowns: descartar/no clasificar/no emparejar.
- Hacer que `glute` no se convierta a `glutes`.
- Revisar si `PairingContract` y `AntagonistPairingEngine` deben migrarse en el mismo sprint o quedar como dependencias directas con wrappers strict.
- Actualizar estos fixtures observacionales al nuevo contrato strict despues de la migracion.

## 20. Que NO debe tocarse todavia

No tocar todavia:
- MotorV3Orchestrator
- CycleTemplateBuilder
- ExerciseSelectionEngine
- UI
- DB
- modelos
- repositorios
- catalogo productivo
- reglas de ordenamiento
- reglas de pairing
- formulas de volumen

Conclusion operativa: D1R6 esta completo. El comportamiento actual de `SessionStructureEngine` quedo congelado antes de la migracion strict, incluyendo aliases, unknown raw passthrough, pairing, intensidad por `loadCategory` y orden estructural.
