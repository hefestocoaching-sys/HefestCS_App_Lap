# AUDIT MUSCLE SSOT D1-C5 - ExerciseSelectionEngine strict

Fecha: 2026-05-26  
Proyecto: HefestoCS / hcs_app_lap  
Scope: migracion D1-C5 de `ExerciseSelectionEngine` a MuscleRegistry strict API.

## 1. Resumen ejecutivo

D1-C5 queda aplicado. `ExerciseSelectionEngine` ya no usa raw fallback para seleccion muscular en sus rutas de comparacion de musculos.

El cambio principal fue reemplazar el contrato legacy `muscle_registry.normalize(key) ?? key` por normalizacion strict basada en `MuscleRegistry.tryNormalizeMuscleKey`. Los unknowns ahora se descartan en `selectDeterministicCandidates` retornando `[]`, y los `primaryMuscles` del pool tambien se normalizan strict antes de comparar.

No se modificaron Motor V3, `MotorV3Orchestrator`, `CycleTemplateBuilder`, `SessionStructureEngine`, UI, DB, modelos, repositorios ni catalogo productivo.

## 2. Archivos modificados

- `lib/domain/training_v3/engines/exercise_selection_engine.dart`
- `test/domain/training_v3/regression/exercise_selection_engine_fixtures_regression_test.dart`
- `test/fixtures/training_v3/exercise_selection/exercise_selection_canonical.json`
- `test/fixtures/training_v3/exercise_selection/exercise_selection_alias.json`
- `test/fixtures/training_v3/exercise_selection/exercise_selection_unknown.json`
- `test/fixtures/training_v3/exercise_selection/exercise_selection_mixed.json`
- `test/fixtures/training_v3/exercise_selection/exercise_selection_equipment_constraints.json`
- `test/fixtures/training_v3/exercise_selection/exercise_selection_priority_cases.json`
- `test/fixtures/training_v3/exercise_selection/exercise_selection_catalog_edge_cases.json`
- `lib/audit/AUDIT_MUSCLE_SSOT_D1C5_EXERCISE_SELECTION_STRICT_REPORT.md`

## 3. Archivos inspeccionados

- `lib/domain/training_v3/engines/exercise_selection_engine.dart`
- `lib/core/registry/muscle_registry.dart`
- `lib/domain/training_v3/utils/muscle_key_adapter_v3.dart`
- `lib/domain/training_v3/resolvers/muscle_to_catalog_resolver.dart`
- `lib/domain/training_v3/data/exercise_catalog_v3.dart`
- `test/domain/training_v3/regression/exercise_selection_engine_fixtures_regression_test.dart`
- `test/fixtures/training_v3/exercise_selection/`

## 4. Confirmacion de scope

Scope cumplido:
- Solo se migro `ExerciseSelectionEngine` en el archivo principal.
- Se actualizaron fixtures y test D1R5 al contrato strict D1-C5.
- Se mantuvo el ordenamiento existente.
- Se mantuvieron restricciones de equipo, zona, lesiones, restricciones y fallback especifico de equivalencias.
- No se introdujo fallback generico.

Fuera de scope, no tocado:
- MotorV3Orchestrator
- CycleTemplateBuilder
- SessionStructureEngine
- UI
- DB
- modelos
- repositorios
- catalogo productivo
- formulas de volumen
- reglas de prioridad

## 5. Comportamiento antes D1R5

D1R5 congelo este comportamiento:
- `selectExercises('glute')` lanzaba `STRICT_NO_FALLBACK`.
- `selectDeterministicCandidates('glute')` seleccionaba `glute_high` porque `glute` pasaba por `muscle_registry.normalize`.
- `selectDeterministicCandidates('unknown_muscle')` podia seleccionar `raw_unknown_high` si el pool contenia `primaryMuscles: ['unknown_muscle']`.
- `normalizeMuscleKey` devolvia `muscle_registry.normalize(key) ?? key`.

Ese ultimo punto era el raw passthrough principal.

## 6. Comportamiento despues D1-C5

Despues de la migracion:
- `selectExercises` conserva aliases validos, unknowns lanzan `STRICT_NO_FALLBACK`.
- `selectDeterministicCandidates('glute')` retorna `[]`.
- `selectDeterministicCandidates('unknown_muscle')` retorna `[]`, incluso con raw pool.
- `selectDeterministicCandidates('back_mid_upper')` retorna `[]`.
- `selectDeterministicCandidates('mysterychest')` retorna `[]`.
- `selectDeterministicCandidates('chest')` sigue seleccionando `pectorals`.
- `selectDeterministicCandidates('gluteos')` sigue seleccionando `glutes`.

## 7. API strict usada

API usada:
- `muscle_registry.tryNormalizeMuscleKey(raw)`

Helpers locales agregados:
- `_tryNormalizeSelectionMuscle(String raw): String?`
- `_matchesSelectionMuscle(Iterable<String> rawMuscles, String canonicalMuscle): bool`
- `_strictPrimaryMuscleSet(Map<String, dynamic> exercise): Set<String>`

`expandMuscleGroupStrict` no fue necesario en esta migracion porque `selectExercises` ya delega expansion de grupos a `MuscleKeyAdapterV3.toCatalogKeys`.

## 8. API legacy eliminada o aislada

Eliminado del flujo de seleccion:
- `muscle_registry.normalize(key) ?? key`
- comparaciones de `primaryMuscles` con raw normalizado permisivo

Aislado:
- `normalizeMuscleKey(String raw)` queda como wrapper deprecated y retorna canonical o `''`; ya no retorna raw.

## 9. Raw passthrough eliminado

El raw passthrough fue eliminado en:
- entrada `muscleKey` de `selectDeterministicCandidates`
- comparacion de `ex.primaryMuscles`
- comparacion de `source.primaryMuscles` en fallback de equivalencias
- comparacion de `candidate.primaryMuscles` en fallback de equivalencias
- `getExerciseVariations`
- `selectExercises` al comparar `primaryMuscles` de mapas

Busqueda post-cambio en `exercise_selection_engine.dart`:
- sin `muscle_registry.normalize`
- sin `?? key`
- sin `?? raw`
- sin `raw.toLowerCase()` o `key.toLowerCase()` como fallback muscular

## 10. Manejo de aliases

Aliases validos conservados:
- `chest -> pectorals`
- `quadriceps -> quads`
- `gluteos -> glutes`
- `deltoide_anterior -> delts_front`

El test D1-C5 valida que `chest` devuelve el mismo orden que `pectorals` en la superficie deterministica.

## 11. Manejo de unknowns

Unknowns descartados:
- `unknown_muscle`
- `back_mid_upper`
- `mysterychest`
- `glute`

Contrato aplicado:
- `selectExercises`: lanza `STRICT_NO_FALLBACK` cuando no hay `catalogKeys` o candidatos.
- `selectDeterministicCandidates`: retorna `[]` si el `muscleKey` no normaliza strict.
- raw unknowns del pool no matchean contra raw unknowns solicitados.

## 12. Caso glute antes/despues

Antes:
- `selectExercises('glute')`: `STRICT_NO_FALLBACK`.
- `selectDeterministicCandidates('glute')`: seleccionaba `glute_high`.

Despues:
- `selectExercises('glute')`: sigue `STRICT_NO_FALLBACK`.
- `selectDeterministicCandidates('glute')`: retorna `[]`.

Resultado esperado futuro strict cumplido: `glute` se descarta; `gluteos` si normaliza a `glutes`.

## 13. Caso unknown_muscle antes/despues

Antes:
- Con pool canonical, no encontraba candidatos.
- Con pool raw `primaryMuscles: ['unknown_muscle']`, podia seleccionar `raw_unknown_high`.

Despues:
- Retorna `[]` antes de filtrar pool.
- `raw_unknown_high` no puede aparecer en seleccion strict.

## 14. selectExercises antes/despues

Antes:
- Usaba `MuscleKeyAdapterV3.toCatalogKeys(targetMuscle)`.
- Aliases validos funcionaban.
- Unknowns terminaban en `STRICT_NO_FALLBACK`.
- Comparaba primary muscles del mapa por containment raw contra `catalogKeys`.

Despues:
- Conserva `MuscleKeyAdapterV3.toCatalogKeys(targetMuscle)`.
- Conserva aliases y unknown behavior.
- Normaliza strict los `primaryMuscles` / `primary_muscles` del mapa antes de compararlos.
- No agrega fallback generico.

## 15. selectDeterministicCandidates antes/despues

Antes:
- `muscleKey` pasaba por `normalizeMuscleKey`.
- `normalizeMuscleKey` podia devolver raw.
- `glute` se aceptaba por legacy normalize.
- raw pool podia matchear raw request.

Despues:
- `muscleKey` pasa por `tryNormalizeMuscleKey`.
- Unknown retorna `[]`.
- pool/candidates se comparan solo por canonical strict.
- fallback de equivalencias se mantiene, pero solo con canonical valido.
- Ordenamiento y filtros se preservan.

## 16. getExerciseVariations: estado y riesgo

Estado:
- Migrado dentro del scope.
- Ahora normaliza strict `primary_muscles` y `primaryMuscles`.
- Si la base solo tiene unknowns, retorna `[]`.
- Aliases validos como `chest` comparan contra canonical `pectorals`.

Riesgo pendiente:
- Esta ruta tiene cobertura focalizada nueva, pero no se auditaron todos los call sites de swap/variaciones fuera de este sprint.

## 17. Ordenamiento preservado

Se preservo el orden actual:
- compatibility
- exercise order class
- stimulus
- fatigue
- preferred pattern
- recent
- variant tier
- id

No se cambiaron reglas de prioridad ni formulas externas.

## 18. Equipment constraints preservado

Se preservo:
- `availableEquipment` vacio permite todo.
- Equipo limitado filtra candidatos.
- Si el filtro deja cero candidatos, no hay fallback generico.
- El fallback de equivalencias tambien respeta equipo.

Fixtures validados:
- pectorals + `machine` -> `pec_low`
- pectorals + `cable` -> `STRICT_NO_FALLBACK`
- glutes deterministico + `barbell` -> `glute_high`
- glutes deterministico + `cable` -> `STRICT_NO_ZONE_CANDIDATES`

## 19. Fixtures actualizados

Fixtures actualizados a contrato strict:
- canonical
- alias
- unknown
- mixed
- equipment constraints
- priority cases
- catalog edge cases

Cambios principales:
- `glute` en deterministico ahora `[]`.
- `unknown_muscle` en deterministico ahora `[]`.
- raw pool ya no selecciona `raw_unknown_high`.
- se agregaron casos para `back_mid_upper` y `mysterychest` con raw pool.

## 20. Tests ejecutados

Nuevo/regresivo D1-C5:
- `flutter test test/domain/training_v3/regression/exercise_selection_engine_fixtures_regression_test.dart --reporter expanded`
- Resultado: `+11`, `All tests passed!`

Regresion D1R4:
- `flutter test test/domain/training_v3/regression/weekly_volume_planner_fixtures_regression_test.dart --reporter expanded`
- Resultado: `+8`, `All tests passed!`

Regresion current behavior:
- `flutter test test/domain/training_v3/regression/weekly_volume_planner_current_behavior_test.dart --reporter expanded`
- Resultado: `+4`, `All tests passed!`

Suite SSOT focalizada:
- `flutter test test/core/registry/muscle_registry_strict_test.dart test/features/training_feature/domain/exercise_preferences_muscle_key_mapper_strict_test.dart test/domain/training_v3/resolvers/muscle_to_catalog_resolver_strict_test.dart test/domain/training_v3/utils/muscle_key_adapter_v3_strict_test.dart test/domain/training_v3/validators/training_plan_forensic_validator_muscle_ssot_test.dart test/domain/training/models/mev_table_strict_muscle_test.dart test/domain/training/validation/vop_validator_strict_muscle_test.dart test/domain/training_v3/validators/volume_validator_strict_muscle_test.dart --reporter expanded`
- Resultado: `+55`, `All tests passed!`

Nota de entorno:
- Los `flutter test` se ejecutaron fuera del sandbox con aprobacion porque en esta repo los Flutter tests dentro del sandbox han quedado colgados.

## 21. Resultado flutter analyze

Comando:
- `flutter analyze --no-pub`

Resultado final:
- `No issues found! (ran in 3.2s)`

## 22. Riesgos pendientes

- `ExerciseCatalogV3` todavia contiene normalizacion legacy interna; no fue parte de D1-C5 porque el contrato solicitado era `ExerciseSelectionEngine`.
- `getExerciseVariations` tiene cobertura focalizada, pero falta auditar call sites reales de swap/variaciones en un sprint separado.
- Otros motores/servicios del Motor V3 pueden conservar normalizadores legacy, pero no se tocaron por scope.

## 23. Siguiente sprint recomendado

D1R6 recomendado:
- Fixtures/goldens observacionales para la siguiente superficie del Motor V3 que aun consuma normalizacion legacy en seleccion/sesion.
- Candidato: auditar `CycleTemplateBuilder` o `SessionStructureEngine` solo si el roadmap lo autoriza.
- No migrar esas superficies sin baseline previo.

## 24. Que NO se toco

No se toco:
- MotorV3Orchestrator
- CycleTemplateBuilder
- SessionStructureEngine
- UI
- DB
- modelos
- repositorios
- catalogo productivo
- formulas de volumen
- reglas de prioridad
- tests globales fuera de los focalizados solicitados

Conclusion operativa: D1-C5 esta completo. `ExerciseSelectionEngine` descarta unknowns bajo Muscle SSOT strict, conserva canonicos y aliases validos, mantiene ordenamiento/restricciones, y queda validado con tests focalizados y analyze limpio.
