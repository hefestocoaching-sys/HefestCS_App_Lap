# AUDIT MUSCLE SSOT D1R5 - ExerciseSelectionEngine fixtures observacionales

Fecha: 2026-05-25  
Proyecto: HefestoCS / hcs_app_lap  
Scope: D1R5, fixtures/goldens observacionales antes de migrar ExerciseSelectionEngine.

## 1. Resumen ejecutivo

D1R5 queda aplicado como baseline observacional. Se crearon fixtures JSON y un test de regresion para congelar el comportamiento actual de `ExerciseSelectionEngine` antes de migrarlo a `MuscleRegistry` strict API.

No se modifico logica productiva. No se migro `ExerciseSelectionEngine`. No se tocaron Motor V3, UI, DB, modelos ni repositorios.

Hallazgo principal: `selectExercises` ya entra por `MuscleKeyAdapterV3.toCatalogKeys`, por lo que aliases validos se normalizan y unknowns terminan en `STRICT_NO_FALLBACK`. Pero `selectDeterministicCandidates` sigue usando `normalizeMuscleKey`, que internamente hace `muscle_registry.normalize(key) ?? key`; esto preserva riesgo legacy/raw passthrough.

## 2. Confirmacion de scope

Aplicado:
- Crear fixtures observacionales bajo `test/fixtures/training_v3/exercise_selection/`.
- Crear test `test/domain/training_v3/regression/exercise_selection_engine_fixtures_regression_test.dart`.
- Crear reporte `lib/audit/AUDIT_MUSCLE_SSOT_D1R5_EXERCISE_SELECTION_FIXTURES_REPORT.md`.
- Ejecutar test nuevo, tests focalizados previos y `flutter analyze --no-pub`.

No aplicado:
- No se migro `ExerciseSelectionEngine`.
- No se cambio `MuscleRegistry`.
- No se cambio catalogo productivo.
- No se cambio Motor V3, UI, DB, modelos, repositorios ni providers.

## 3. Archivos modificados

- `test/fixtures/training_v3/exercise_selection/exercise_selection_canonical.json`
- `test/fixtures/training_v3/exercise_selection/exercise_selection_alias.json`
- `test/fixtures/training_v3/exercise_selection/exercise_selection_unknown.json`
- `test/fixtures/training_v3/exercise_selection/exercise_selection_mixed.json`
- `test/fixtures/training_v3/exercise_selection/exercise_selection_equipment_constraints.json`
- `test/fixtures/training_v3/exercise_selection/exercise_selection_priority_cases.json`
- `test/fixtures/training_v3/exercise_selection/exercise_selection_catalog_edge_cases.json`
- `test/domain/training_v3/regression/exercise_selection_engine_fixtures_regression_test.dart`
- `lib/audit/AUDIT_MUSCLE_SSOT_D1R5_EXERCISE_SELECTION_FIXTURES_REPORT.md`

## 4. Archivos inspeccionados

- `lib/domain/training_v3/engines/exercise_selection_engine.dart`
- `lib/domain/training_v3/data/exercise_catalog_v3.dart`
- `lib/domain/training_v3/models/exercise_catalog_v3_entry.dart`
- `lib/domain/training_v3/resolvers/muscle_to_catalog_resolver.dart`
- `lib/domain/training_v3/utils/muscle_key_adapter_v3.dart`
- `lib/domain/entities/exercise.dart`
- `assets/data/exercises/exercise_catalog_gym.json` existe.
- `assets/data/training_v3/catalog/` existe con catalogo runtime, schema, media, defaults, registry y conflict rules.

## 5. Metodos publicos de ExerciseSelectionEngine

- `normalizeMuscleKey(String raw)`: trim/lower + `muscle_registry.normalize(key) ?? key`.
- `selectExercisesForMuscle({pool, targetSets})`: distribuye sets sobre un pool ya dado; no usa MuscleRegistry.
- `selectExercises({targetMuscle, availableExercises, availableEquipment, injuryHistory, targetExerciseCount, ...})`: selecciona ids desde un mapa de ejercicios.
- `selectExercisesByGroups({groups, targetSets, profile, ...})`: resuelve grupos, consulta `ExerciseCatalogV3`, filtra y ordena ejercicios reales.
- `selectDeterministicCandidates({pool, muscleKey, intensityZone, ...})`: seleccion deterministica desde pool; usa `normalizeMuscleKey`.
- `getExerciseVariations(String exerciseId, Map<String, Map<String, dynamic>> exerciseDatabase)`: busca variantes por `primary_muscles` y tipo; no usa MuscleRegistry.

## 6. Inputs requeridos

`selectExercises` requiere:
- `targetMuscle`
- `availableExercises`
- `availableEquipment`
- `injuryHistory`
- `targetExerciseCount`

`selectDeterministicCandidates` requiere:
- `pool`
- `muscleKey`
- `intensityZone`

`selectExercisesForMuscle` requiere:
- `pool`
- `targetSets`

El test usa un catalogo fake minimo en test, cargado con `ExerciseCatalogV3.loadFromExercises`, para no depender de assets productivos ni modificar loaders.

## 7. Outputs observados

- Canonicos: `pectorals`, `lats`, `quads`, `glutes` seleccionan ejercicios esperados del fake catalog.
- Aliases validos en `selectExercises`: `chest`, `quadriceps`, `gluteos`, `deltoide_anterior` seleccionan la salida canonica correspondiente.
- Unknowns en `selectExercises`: `unknown_muscle`, `back_mid_upper`, `mysterychest`, `glute` lanzan `[ExerciseSelection][STRICT_NO_FALLBACK]`.
- `selectDeterministicCandidates('glute')` selecciona `glute_high`; esto es legacy permisivo y debe cambiar en D1-C5.
- `selectDeterministicCandidates('unknown_muscle')` con pool raw selecciona `raw_unknown_high`; esto evidencia raw passthrough si el pool trae una key raw.
- `selectExercisesForMuscle` con pool vacio devuelve `[]`; con `calves_only` y `targetSets=5` devuelve sets 5 y `notes=''`.

## 8. Dependencias del engine

- `Exercise`
- `ClientProfile`
- `ExerciseCatalogV3`
- `MuscleKeyAdapterV3`
- `MuscleToCatalogResolver`
- `MuscleRegistry` legacy importado como `muscle_registry`
- `debugPrint`

## 9. Uso actual de MuscleRegistry o normalizer legacy

Evidencia:
- `exercise_selection_engine.dart:50-53`: `normalizeMuscleKey` hace `final key = raw.trim().toLowerCase();` y retorna `muscle_registry.normalize(key) ?? key`.
- `exercise_selection_engine.dart:124-126`: `selectExercises` usa `MuscleKeyAdapterV3.toCatalogKeys(targetMuscle)`.
- `exercise_selection_engine.dart:401`: `selectDeterministicCandidates` usa `normalizeMuscleKey(muscleKey)`.
- `exercise_selection_engine.dart:435-436`, `511-512`, `524-525`: compara primary muscles despues de `normalizeMuscleKey`.

Clasificacion:
- `selectExercises`: parcialmente alineado por adapter strict.
- `selectDeterministicCandidates`: requiere migracion D1-C5.
- `normalizeMuscleKey`: legacy permitido solo como comportamiento a congelar, no como contrato futuro.

## 10. Raw passthrough detectado

Detectado en superficie deterministica:
- `muscle_registry.normalize(key) ?? key` permite que un unknown quede como raw lowercase.
- Si el pool contiene `primaryMuscles: ['unknown_muscle']`, `selectDeterministicCandidates(muscleKey: 'unknown_muscle')` puede seleccionar ese ejercicio.
- `glute` no es alias strict esperado, pero legacy `normalize` lo convierte a `glutes` y selecciona `glute_high`.

No detectado en `selectExercises`:
- `glute`, `unknown_muscle`, `back_mid_upper`, `mysterychest` terminan en `catalogKeys=[]` y lanzan `STRICT_NO_FALLBACK`.

## 11. Fixtures creados

- `exercise_selection_canonical.json`: canonicos `pectorals`, `lats`, `quads`, `glutes`.
- `exercise_selection_alias.json`: aliases `chest`, `quadriceps`, `gluteos`, `deltoide_anterior`.
- `exercise_selection_unknown.json`: unknowns `unknown_muscle`, `back_mid_upper`, `mysterychest`, `glute`.
- `exercise_selection_mixed.json`: mezcla canonical + alias + unknown + grupo `back`.
- `exercise_selection_equipment_constraints.json`: equipo limitado y ausencia de fallback.
- `exercise_selection_priority_cases.json`: comportamiento observable de count/sort; no hay enum de prioridad.
- `exercise_selection_catalog_edge_cases.json`: musculo valido sin ejercicios, pocos ejercicios, alias, unknown y `selectExercisesForMuscle`.

## 12. Casos cubiertos

Canonical:
- `pectorals -> [pec_high, pec_mid]`
- `lats -> [lat_high, lat_mid]`
- `quads -> [quad_high, quad_mid]`
- `glutes -> [glute_high]`

Alias:
- `chest -> [pec_high, pec_mid]`
- `quadriceps -> [quad_high, quad_mid]`
- `gluteos -> [glute_high]`
- `deltoide_anterior -> [delt_front_high]`

Unknown:
- `unknown_muscle`, `back_mid_upper`, `mysterychest`, `glute` lanzan en `selectExercises`.
- `unknown_muscle` puede pasar en `selectDeterministicCandidates` si el pool trae raw.
- `glute` pasa como `glutes` en `selectDeterministicCandidates`.

Mixed:
- `pectorals` y `chest` devuelven la misma seleccion en llamadas separadas.
- No hay fusion interna multi-key en `selectExercises`.
- `back` expande a `lats + upper_back`; el fake catalog solo tiene `lats`.

Equipment:
- Equipo `machine` para pectorals deja `pec_low`.
- Equipo `cable` para pectorals lanza sin fallback.
- Equipo `barbell` para glutes deterministico devuelve `glute_high`.

Priority:
- No existe prioridad alta/media/baja como input directo.
- `targetExerciseCount` regula cantidad.
- `recentExerciseIds` no supera `stimulusScore` en el ordenamiento actual.

Catalog edge:
- `triceps` es canonico pero sin ejercicios en fake catalog: lanza sin fallback.
- `calves` con un ejercicio devuelve solo `calves_only`.
- `selectExercisesForMuscle` conserva `notes=''`.

## 13. Resultado observado por caso

Todos los casos del test nuevo pasaron contra los expected observacionales:
- 7 fixture files.
- 7 tests de fixture.
- Resultado final: `All tests passed!`.

## 14. Tabla de aliases

| Input | Output actual | Strict esperado futuro |
|---|---|---|
| `chest` | `selectExercises -> pectorals`; `selectDeterministicCandidates -> pectorals` | `pectorals` |
| `quadriceps` | `selectExercises -> quads` | `quads` |
| `gluteos` | `selectExercises -> glutes`; `selectDeterministicCandidates -> glutes` | `glutes` |
| `deltoide_anterior` | `selectExercises -> delts_front` | `delts_front` |

## 15. Tabla de unknowns

| Input | Output actual | Strict esperado futuro |
|---|---|---|
| `unknown_muscle` | `selectExercises` lanza; deterministico puede seleccionar raw si el pool lo contiene | descartar/null, nunca raw |
| `back_mid_upper` | `selectExercises` lanza | descartar/null |
| `mysterychest` | `selectExercises` lanza | descartar/null |
| `glute` | `selectExercises` lanza; deterministico legacy selecciona `glutes` | descartar/null |

## 16. Colisiones canonical + alias

`selectExercises` procesa un solo `targetMuscle` por llamada. Por eso `pectorals` y `chest` no se fusionan dentro del engine; si el caller invoca ambas entradas por separado, ambas devuelven `[pec_high, pec_mid]`.

Este baseline no define aun politica D1-C5 para dedupe inter-call. Solo congela el comportamiento actual.

## 17. Riesgos

Riesgo alto:
- `selectDeterministicCandidates` puede aceptar raw passthrough por `muscle_registry.normalize(key) ?? key`.
- `glute` se acepta como `glutes` en la superficie deterministica, aunque debe ser unknown bajo strict SSOT.

Riesgo medio:
- `getExerciseVariations` compara `primary_muscles` raw del mapa y no pasa por la registry.
- `selectExercisesForMuscle` no usa muscle key; depende de que el caller entregue un pool correcto.

Riesgo menor:
- `priority` no es input explicito del engine; el comportamiento real depende de count/sort y de decisiones previas del pipeline.

## 18. Tests ejecutados

Nuevo test D1R5:
- `flutter test test/domain/training_v3/regression/exercise_selection_engine_fixtures_regression_test.dart --reporter expanded`
- Resultado final fuera del sandbox: `+7`, `All tests passed!`.

Regresion WeeklyVolumePlanner fixtures:
- `flutter test test/domain/training_v3/regression/weekly_volume_planner_fixtures_regression_test.dart --reporter expanded`
- Resultado: `+8`, `All tests passed!`.

Regresion WeeklyVolumePlanner current behavior:
- `flutter test test/domain/training_v3/regression/weekly_volume_planner_current_behavior_test.dart --reporter expanded`
- Resultado: `+4`, `All tests passed!`.

Suite SSOT focalizada:
- `flutter test test/core/registry/muscle_registry_strict_test.dart test/features/training_feature/domain/exercise_preferences_muscle_key_mapper_strict_test.dart test/domain/training_v3/resolvers/muscle_to_catalog_resolver_strict_test.dart test/domain/training_v3/utils/muscle_key_adapter_v3_strict_test.dart test/domain/training_v3/validators/training_plan_forensic_validator_muscle_ssot_test.dart test/domain/training/models/mev_table_strict_muscle_test.dart test/domain/training/validation/vop_validator_strict_muscle_test.dart test/domain/training_v3/validators/volume_validator_strict_muscle_test.dart --reporter expanded`
- Resultado: `+55`, `All tests passed!`.

Notas de entorno:
- El primer intento de `flutter test` dentro del sandbox quedo sin salida hasta timeout.
- El comando exacto sin `--no-pub` tambien hizo timeout dentro del sandbox, pero paso fuera del sandbox con aprobacion.
- `dart test` no fue usado como evidencia final; fallo por permisos sobre `C:\Users\pedro\AppData\Roaming\.dart-tool\dart-flutter-telemetry-session.json`.

## 19. Resultado flutter analyze

Comando:
- `flutter analyze --no-pub`

Resultado:
- `No issues found! (ran in 107.1s)`

## 20. Siguiente sprint recomendado

D1-C5: migrar `ExerciseSelectionEngine` a `MuscleRegistry` strict API.

Trabajo recomendado:
- Reemplazar `normalizeMuscleKey` legacy o crear helper strict local que use `tryNormalizeMuscleKey`.
- En `selectDeterministicCandidates`, descartar unknowns antes de filtrar pool.
- Asegurar que `glute` se descarte.
- Asegurar que `unknown_muscle`, `back_mid_upper`, `mysterychest` no puedan seleccionar raw pool.
- Preservar ordenamiento actual: compatibility, stimulus, fatigue, preferred pattern, recent, variant tier, id.
- Preservar reglas de equipo, intensidad, restricciones y fallback por equivalencias sin introducir fallback generico.
- Actualizar estos fixtures/goldens al nuevo contrato strict despues de la migracion.

## 21. Que NO debe tocarse todavia

No tocar todavia:
- `MotorV3Orchestrator`
- `CycleTemplateBuilder`
- `SessionStructureEngine`
- UI
- DB
- modelos
- repositorios
- formulas de volumen o prioridad
- catalogo productivo salvo que D1-C5 lo requiera con evidencia separada

## 22. Conclusion operativa

D1R5 cumple su objetivo: el comportamiento actual de `ExerciseSelectionEngine` quedo congelado con fixtures observacionales y test de regresion. La linea anterior D1-A a D1-C4-C3 sigue verde y `flutter analyze --no-pub` esta limpio.

El siguiente paso correcto es D1-C5: migrar `ExerciseSelectionEngine` a la API strict de `MuscleRegistry`, usando este baseline para distinguir cambios intencionales de regresiones accidentales.
