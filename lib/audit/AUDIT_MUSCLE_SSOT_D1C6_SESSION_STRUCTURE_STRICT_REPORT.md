# AUDIT MUSCLE SSOT D1-C6 - SessionStructureEngine strict

## 1. Resumen ejecutivo

D1-C6 quedo aplicado sobre `SessionStructureEngine`.

La normalizacion muscular usada para clasificar, emparejar y evaluar interferencia en la estructura de sesion dejo de depender de `muscle_registry.normalize`, `muscle_registry.expandGroup` y fallback `raw.trim().toLowerCase()`. Ahora el engine normaliza con `muscle_registry.tryNormalizeMuscleKey` y trata los musculos no reconocidos como no clasificados.

El comportamiento productivo de ordenamiento, bloques A/B/C/D, intensidad y reglas de pairing validas se preservo. Los unknowns pueden permanecer como ejercicios en la estructura cuando ya estaban en el input, pero no entran como musculo valido ni forman pairing muscular.

## 2. Archivos modificados

- `lib/domain/training_v3/engines/session_structure_engine.dart`
- `test/domain/training_v3/regression/session_structure_engine_fixtures_regression_test.dart`
- `test/fixtures/training_v3/session_structure/session_structure_canonical.json`
- `test/fixtures/training_v3/session_structure/session_structure_alias.json`
- `test/fixtures/training_v3/session_structure/session_structure_unknown.json`
- `test/fixtures/training_v3/session_structure/session_structure_mixed.json`
- `test/fixtures/training_v3/session_structure/session_structure_pairing_cases.json`
- `test/fixtures/training_v3/session_structure/session_structure_order_cases.json`

## 3. Archivos inspeccionados

- `lib/domain/training_v3/engines/session_structure_engine.dart`
- `lib/domain/training_v3/engines/antagonist_pairing_engine.dart`
- `lib/domain/policies/pairing_contract.dart`
- `test/domain/training_v3/regression/session_structure_engine_fixtures_regression_test.dart`
- `test/fixtures/training_v3/session_structure/`

## 4. Confirmacion de scope

Dentro de scope:

- Migrar la clasificacion muscular de `SessionStructureEngine` a MuscleRegistry strict API.
- Actualizar fixtures/goldens D1R6 al contrato D1-C6.
- Actualizar el test de regresion D1R6 para validar el contrato strict.
- Documentar el resultado en `lib/audit/`.

Fuera de scope y no tocado:

- `MotorV3Orchestrator`
- `CycleTemplateBuilder`
- `ExerciseSelectionEngine`
- UI
- DB
- modelos
- repositorios
- catalogo productivo
- formulas de volumen
- reglas cientificas de entrenamiento
- reglas de prioridad

## 5. Comportamiento antes D1R6

D1R6 habia congelado el comportamiento observacional previo:

- `_primaryMuscle` intentaba `muscle_registry.normalize(raw)`.
- Si no normalizaba, intentaba `muscle_registry.expandGroup(raw)`.
- Si no habia resultado, retornaba `raw.trim().toLowerCase()`.
- `unknown_muscle`, `back_mid_upper` y `mysterychest` podian pasar como claves raw lowercase.
- `glute` se convertia a `glutes` por normalizacion legacy.
- Los helpers de pairing podian recibir claves musculares raw desde `SessionStructureEngine`.

## 6. Comportamiento despues D1-C6

El engine ahora usa un helper strict local:

- Recorre `exercise.primaryMuscles`.
- Aplica `muscle_registry.tryNormalizeMuscleKey(raw)`.
- Si encuentra un canonico valido, lo retorna.
- Si no encuentra canonico en `primaryMuscles`, intenta normalizar `exercise.muscleKey`.
- Si tampoco normaliza, retorna `null`.

Resultado:

- No retorna raw.
- No retorna raw lowercase.
- No usa `muscle_registry.normalize`.
- No usa `muscle_registry.expandGroup`.
- Unknowns quedan como ejercicios no clasificados cuando ya estan en la lista, pero no se usan para pairing/interferencia.

## 7. API strict usada

API usada:

- `muscle_registry.tryNormalizeMuscleKey(String raw): String?`

No se requirio `expandMuscleGroupStrict` en este sprint porque la superficie real del engine clasifica ejercicios concretos por musculo primario, no expande grupos de entrada.

## 8. API legacy eliminada o aislada

Eliminado de `SessionStructureEngine`:

- `muscle_registry.normalize(raw)`
- `muscle_registry.expandGroup(raw)`
- fallback `raw.trim().toLowerCase()`

`PairingContract` y `AntagonistPairingEngine` conservan normalizacion legacy interna, pero quedaron aislados para esta ruta: `SessionStructureEngine` solo los llama cuando ambos musculos fueron normalizados strict y no son `null`.

## 9. Raw passthrough eliminado

Antes:

- Un musculo desconocido podia retornar como raw lowercase desde `_primaryMuscle`.
- Ese raw podia participar en decisiones de pairing/interferencia.

Despues:

- `_tryPrimaryMuscle` retorna solo canonicos estrictos o `null`.
- Si `mainMuscle` o `candidateMuscle` es `null`, no se evalua pairing muscular.
- `unknown_muscle`, `back_mid_upper`, `mysterychest` y `glute` no se clasifican como musculos validos.

## 10. Manejo de aliases

Aliases validos conservados:

| Input | Output D1-C6 |
| --- | --- |
| `chest` | `pectorals` |
| `pectorales` | `pectorals` |
| `quadriceps` | `quads` |
| `quads` | `quads` |
| `deltoide_anterior` | `delts_front` |
| `deltoide_lateral` | `delts_lateral` |
| `deltoide_posterior` | `delts_rear` |
| `gluteos` | `glutes` |
| `abdomen` | `abs` |

Los objetos `Exercise` pueden conservar el valor raw original en sus campos, pero las decisiones musculares internas del engine usan el canonico strict.

## 11. Manejo de unknowns

| Input | Resultado D1R6 | Resultado D1-C6 |
| --- | --- | --- |
| `unknown_muscle` | raw lowercase valido para clasificacion | no clasificado |
| `back_mid_upper` | raw lowercase valido para clasificacion | no clasificado |
| `mysterychest` | raw lowercase valido para clasificacion | no clasificado |
| `glute` | legacy normalize a `glutes` | no clasificado |

Los unknowns no generan musculo canonico inventado y no crean pairing valido.

## 12. Caso glute antes/despues

Antes D1R6:

- `glute` podia convertirse a `glutes` por `muscle_registry.normalize`.
- Un ejercicio con `primaryMuscles: ['glute']` podia influir como gluteo en pairing/interferencia.

Despues D1-C6:

- `glute` no normaliza con `tryNormalizeMuscleKey`.
- El ejercicio puede quedar ubicado como complemento si esta en el input.
- No se trata como `glutes`.
- No forma biserie ni pairing muscular por gluteo.

## 13. Caso unknown_muscle antes/despues

Antes D1R6:

- `unknown_muscle` podia pasar como `unknown_muscle`.
- Ese raw podia participar como musculo clasificado.

Despues D1-C6:

- `unknown_muscle` retorna `null` como decision muscular.
- No entra a `PairingContract`.
- No entra a `AntagonistPairingEngine`.
- No produce pairGroup muscular valido.

## 14. build antes/despues

Antes:

- `build` recibia `mainMuscle` desde `_primaryMuscle`.
- `_primaryMuscle` siempre podia devolver algun string por fallback raw lowercase.
- Las listas de antagonistas, baja interferencia y pairing podian evaluarse con unknowns raw.

Despues:

- `build` recibe `mainMuscle` desde `_tryPrimaryMuscle`.
- `mainMuscle` puede ser `null`.
- Si el main o candidato no normaliza strict, se omiten reglas musculares.
- El orden general y bloques A/B/C/D se conservan.

## 15. refinePlannedExercises antes/despues

`refinePlannedExercises` no requirio cambio de contrato.

Antes:

- Ordenaba por foco de sesion, compound, score y estabilidad.
- No dependia directamente de `_primaryMuscle`.

Despues:

- Mantiene el mismo ordenamiento.
- No se agrego normalizacion muscular nueva en esta ruta para evitar cambios fuera del contrato real.

## 16. PairingContract y AntagonistPairingEngine

No fueron modificados.

Motivo:

- Ambos helpers tambien son usados fuera de `SessionStructureEngine`, incluyendo rutas no autorizadas en este sprint.
- Cambiarlos habria ampliado el scope hacia superficies compartidas.
- En D1-C6 se bloqueo la reintroduccion de raw passthrough desde `SessionStructureEngine` normalizando antes de llamar esos helpers.

Estado:

- `PairingContract` y `AntagonistPairingEngine` siguen teniendo normalizacion legacy interna.
- Riesgo pendiente documentado: migrarlos en un sprint propio si se decide cerrar toda la superficie de pairing compartido.

## 17. Ordenamiento preservado

Se preservo:

- Seleccion de main lift por score.
- Estabilidad deterministica por orden original.
- Construccion de bloque A.
- Construccion de bloque B por antagonistas validos.
- Construccion de bloque C por baja interferencia valida.
- Construccion de bloque D para complementarios.

No se cambiaron formulas ni reglas de prioridad.

## 18. Pairing preservado

Pairing valido preservado:

- Antagonistas canonicos siguen funcionando.
- Baja interferencia entre musculos canonicos sigue funcionando.
- Biseries validas siguen generando `pairGroupId`.

Pairing invalidado por strict:

- Unknowns ya no forman pairing por raw.
- `glute` ya no forma pairing como `glutes`.

## 19. Intensity/loadCategory preservado

No se modifico la logica de `loadCategory`.

Los casos `heavy`, `medium` y `light` siguen usando el mismo orden y ubicacion observada cuando no dependen de unknown raw.

## 20. Fixtures actualizados

Fixtures actualizados bajo `test/fixtures/training_v3/session_structure/`:

- `session_structure_canonical.json`
- `session_structure_alias.json`
- `session_structure_unknown.json`
- `session_structure_mixed.json`
- `session_structure_pairing_cases.json`
- `session_structure_order_cases.json`

Casos cubiertos:

- Canonical: `pectorals`, `lats`, `quads`, `glutes`.
- Alias: `chest`, `quadriceps`, `gluteos`, `deltoide_anterior`.
- Unknown: `unknown_muscle`, `back_mid_upper`, `mysterychest`, `glute`.
- Mixed: canonicos + aliases validos + unknowns.
- Pairing: antagonistas y biseries validas preservadas.
- Intensity: `heavy`, `medium`, `light`.
- Order: ranking valido preservado.

## 21. Tests ejecutados

Comandos ejecutados:

```powershell
flutter test test/domain/training_v3/regression/session_structure_engine_fixtures_regression_test.dart --reporter expanded
```

Resultado:

- `+10: All tests passed!`

```powershell
flutter test test/domain/training_v3/regression/exercise_selection_engine_fixtures_regression_test.dart --reporter expanded
```

Resultado:

- `+11: All tests passed!`

```powershell
flutter test test/domain/training_v3/regression/weekly_volume_planner_fixtures_regression_test.dart --reporter expanded
```

Resultado:

- `+8: All tests passed!`

```powershell
flutter test test/core/registry/muscle_registry_strict_test.dart test/features/training_feature/domain/exercise_preferences_muscle_key_mapper_strict_test.dart test/domain/training_v3/resolvers/muscle_to_catalog_resolver_strict_test.dart test/domain/training_v3/utils/muscle_key_adapter_v3_strict_test.dart test/domain/training_v3/validators/training_plan_forensic_validator_muscle_ssot_test.dart test/domain/training/models/mev_table_strict_muscle_test.dart test/domain/training/validation/vop_validator_strict_muscle_test.dart test/domain/training_v3/validators/volume_validator_strict_muscle_test.dart --reporter expanded
```

Resultado:

- `+55: All tests passed!`

## 22. Resultado flutter analyze

Comando ejecutado:

```powershell
flutter analyze --no-pub
```

Resultado:

- `No issues found! (ran in 3.1s)`

## 23. Riesgos pendientes

Riesgos pendientes:

- `PairingContract` conserva normalizacion legacy interna y deberia auditarse/migrarse en un sprint propio si se busca SSOT completo de pairing compartido.
- `AntagonistPairingEngine` conserva normalizacion legacy interna y tambien deberia migrarse fuera de este scope.
- Unknown exercises pueden seguir apareciendo en la estructura como ejercicios no clasificados si llegan desde el input; esto es intencional para no alterar el pipeline ni descartar ejercicios fuera del contrato D1-C6.

## 24. Siguiente sprint recomendado

Siguiente sprint recomendado:

- D1R7: fixtures/goldens observacionales para `PairingContract` y `AntagonistPairingEngine`, antes de migrar helpers compartidos a MuscleRegistry strict API.

Razon:

- D1-C6 ya impide raw passthrough desde `SessionStructureEngine`.
- Los helpers compartidos aun tienen legacy normalizer.
- Migrarlos requiere baseline propio porque tambien son usados por superficies fuera de `SessionStructureEngine`.

## 25. Que NO se toco

No se toco:

- `MotorV3Orchestrator`
- `CycleTemplateBuilder`
- `ExerciseSelectionEngine`
- UI
- DB
- modelos
- repositorios
- catalogo productivo
- formulas de volumen
- reglas de prioridad
- reglas cientificas de entrenamiento
- tests no relacionados
- reportes en raiz

## Conclusion operativa

D1-C6 queda cerrado.

`SessionStructureEngine` ya no clasifica musculos con fallback raw y no convierte `glute` a `glutes`. Los aliases validos siguen funcionando, los canonicos conservan comportamiento, el pairing valido se preserva y los unknowns no influyen como musculos validos.

La siguiente superficie de riesgo no esta en `SessionStructureEngine`, sino en los helpers compartidos de pairing que todavia conservan normalizacion legacy interna.
