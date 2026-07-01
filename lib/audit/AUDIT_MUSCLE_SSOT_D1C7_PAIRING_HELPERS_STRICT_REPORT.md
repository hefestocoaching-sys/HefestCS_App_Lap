# AUDIT MUSCLE SSOT D1-C7 - Pairing helpers strict

## 1. Resumen ejecutivo

D1-C7 quedo aplicado sobre `PairingContract` y `AntagonistPairingEngine`.

Ambos helpers dejaron de usar normalizadores legacy y ahora resuelven musculos con `MuscleRegistry` strict API. Los canonicos y aliases validos siguen funcionando, los grupos tienen contrato explicito por expansion strict y los unknowns retornan `none` / `false` sin fallback raw.

Resultado clave:

- `glute` ya no se convierte a `glutes`.
- `unknown_muscle`, `back_mid_upper` y `mysterychest` no pasan como raw lowercase.
- `back/pectorals` ahora es consistente: `PairingContract -> antagonist` y `AntagonistPairingEngine -> true`.

## 2. Archivos modificados

- `lib/domain/policies/pairing_contract.dart`
- `lib/domain/training_v3/engines/antagonist_pairing_engine.dart`
- `test/domain/training_v3/regression/pairing_helpers_fixtures_regression_test.dart`
- `test/fixtures/training_v3/pairing_helpers/pairing_helpers_canonical.json`
- `test/fixtures/training_v3/pairing_helpers/pairing_helpers_alias.json`
- `test/fixtures/training_v3/pairing_helpers/pairing_helpers_unknown.json`
- `test/fixtures/training_v3/pairing_helpers/pairing_helpers_mixed.json`
- `test/fixtures/training_v3/pairing_helpers/pairing_helpers_group_cases.json`
- `test/fixtures/training_v3/pairing_helpers/pairing_helpers_symmetry_cases.json`
- `test/fixtures/training_v3/pairing_helpers/pairing_helpers_interference_cases.json`
- `lib/audit/AUDIT_MUSCLE_SSOT_D1C7_PAIRING_HELPERS_STRICT_REPORT.md`

## 3. Archivos inspeccionados

- `lib/domain/policies/pairing_contract.dart`
- `lib/domain/training_v3/engines/antagonist_pairing_engine.dart`
- `lib/core/registry/muscle_registry.dart`
- `lib/core/utils/muscle_key_normalizer.dart`
- `lib/domain/training_v3/data/interference_matrix.dart`
- `test/domain/training_v3/regression/pairing_helpers_fixtures_regression_test.dart`
- `test/fixtures/training_v3/pairing_helpers/`

## 4. Confirmacion de scope

Dentro de scope:

- Migrar `PairingContract` a MuscleRegistry strict API.
- Migrar `AntagonistPairingEngine` a MuscleRegistry strict API.
- Actualizar fixtures D1R7 al contrato D1-C7.
- Actualizar el test de regresion D1R7 a expectativas strict.
- Ejecutar validacion focalizada y `flutter analyze --no-pub`.

Fuera de scope y no tocado:

- `SessionStructureEngine`
- `ExerciseSelectionEngine`
- `CycleTemplateBuilder`
- `MotorV3Orchestrator`
- UI
- DB
- modelos
- repositorios
- catalogo productivo
- formulas de volumen
- reglas cientificas de entrenamiento

## 5. Comportamiento antes D1R7

D1R7 congelo este comportamiento legacy:

- `PairingContract` usaba `muscle_registry.normalize`.
- `PairingContract` usaba `muscle_registry.expandGroup`.
- `PairingContract` tenia fallback `raw.trim().toLowerCase()`.
- `AntagonistPairingEngine` usaba `normalizeMuscleKey` legacy.
- `glute` se convertia a `glutes`.
- `unknown_muscle`, `back_mid_upper` y `mysterychest` podian pasar como raw lowercase.
- Los grupos no eran consistentes entre helpers: `PairingContract back/pectorals -> antagonist`, pero `AntagonistPairingEngine back/pectorals -> false`.

## 6. Comportamiento despues D1-C7

Nuevo comportamiento:

- Cada input se resuelve como lista strict:
  - canonico o alias valido -> lista de un elemento.
  - grupo strict -> lista expandida.
  - unknown -> lista vacia.
- `PairingContract.classify` evalua todas las combinaciones entre lista A y lista B.
- `AntagonistPairingEngine.areAntagonists` evalua todas las combinaciones y retorna `true` si alguna es antagonista.
- Unknowns retornan `PairingType.none` / `false`.
- No hay fallback raw.

## 7. API strict usada

API usada:

- `muscle_registry.tryNormalizeMuscleKey(raw)`
- `muscle_registry.expandMuscleGroupStrict(raw)`

No se uso `isCanonicalMuscleKey` porque el helper de resolucion ya queda cubierto por `tryNormalizeMuscleKey`.

## 8. API legacy eliminada

Eliminado de `PairingContract`:

- `muscle_registry.normalize(raw)`
- `muscle_registry.expandGroup(raw)`
- `raw.trim().toLowerCase()`

Eliminado de `AntagonistPairingEngine`:

- import de `core/utils/muscle_key_normalizer.dart`
- `normalizeMuscleKey(key)`
- caso legacy `traps_upper -> traps`

## 9. Raw passthrough eliminado

Busqueda de seguridad en los dos helpers modificados no encontro:

- `muscle_registry.normalize(`
- `muscle_registry.expandGroup(`
- `normalizeMuscleKey(`
- `raw.trim().toLowerCase(`
- `raw.toLowerCase(`
- `key.toLowerCase(`
- `?? raw`
- `?? key`

Los helpers ahora retornan lista vacia para unknowns y no exponen raw.

## 10. Manejo de aliases

Aliases preservados:

| Input | Resultado D1-C7 |
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

Casos validados:

- `chest/lats -> antagonist`
- `quadriceps/hamstrings -> antagonist`
- `gluteos/quads -> synergy`
- `deltoide_anterior/deltoide_posterior -> none`
- `abdomen/calves -> none`

## 11. Manejo de unknowns

| Input | Resultado D1-C7 |
| --- | --- |
| `unknown_muscle/lats` | `none` / `false` |
| `back_mid_upper/pectorals` | `none` / `false` |
| `mysterychest/lats` | `none` / `false` |
| `glute/quads` | `none` / `false` |

Los unknowns no participan en reglas de antagonismo, sinergia ni baja interferencia.

## 12. Caso glute antes/despues

Antes:

- `glute/quads` normalizaba `glute -> glutes`.
- `PairingContract` devolvia `synergy`.
- `isAllowedBiserie` devolvia `true`.

Despues:

- `glute` no normaliza ni expande con strict API.
- `PairingContract` devuelve `none`.
- `isAllowedBiserie` devuelve `false`.
- `AntagonistPairingEngine` devuelve `false`.

## 13. Caso unknown_muscle antes/despues

Antes:

- `unknown_muscle` pasaba como raw lowercase por normalizadores legacy.
- No encontraba regla, pero el raw llegaba a la comparacion.

Despues:

- `unknown_muscle` resuelve a lista vacia.
- `PairingContract` devuelve `none`.
- `AntagonistPairingEngine` devuelve `false`.
- No hay raw passthrough.

## 14. Contrato de grupos aplicado

Grupos strict:

- `back -> lats + upper_back`
- `shoulders -> delts_front + delts_lateral + delts_rear`
- `arms -> biceps + triceps`
- `legs -> quads + hamstrings + glutes + calves`

Politica aplicada:

- Si el input normaliza como musculo canonico, se usa `[canonical]`.
- Si expande como grupo strict, se usa la lista expandida.
- Si no normaliza ni expande, se usa `[]`.
- Se evaluan todas las combinaciones `listaA x listaB`.

Resultados de grupo actualizados:

- `back/pectorals -> antagonist`, engine `true`.
- `shoulders/triceps -> synergy`, engine `false`.
- `legs/biceps -> lowInterference`, engine `false`.
- `arms/quads -> lowInterference`, engine `false`.
- `back/shoulders -> synergy`, engine `false`.

## 15. Diferencia PairingContract vs AntagonistPairingEngine antes/despues

Antes:

- `PairingContract` podia expandir grupos y tomar solo el primer musculo.
- `AntagonistPairingEngine` conservaba tokens de grupo legacy.
- Caso divergente: `back/pectorals`.
  - `PairingContract -> antagonist`
  - `AntagonistPairingEngine -> false`

Despues:

- Ambos helpers resuelven grupos con la misma politica strict.
- `AntagonistPairingEngine` evalua combinaciones completas.
- Caso `back/pectorals`:
  - `PairingContract -> antagonist`
  - `AntagonistPairingEngine -> true`

## 16. Reglas de prioridad de clasificacion

`PairingContract.classify` aplica esta prioridad:

1. `forbiddenSamePrimary`
2. `antagonist`
3. `synergy`
4. `lowInterference`
5. `none`

Esto hace explicito el comportamiento cuando grupos expandidos producen multiples combinaciones.

## 17. isAllowedBiserie antes/despues

Se preservo el contrato publico:

- Permite `antagonist`.
- Permite `synergy`.
- Permite `lowInterference`.
- Rechaza `forbiddenSamePrimary`.
- Rechaza `none`.

Casos validados:

- `pectorals/lats -> true`
- `pectorals/triceps -> true`
- `pectorals/calves -> true`
- `pectorals/chest -> false`
- `unknown_muscle/lats -> false`

## 18. Fixtures actualizados

Fixtures actualizados bajo `test/fixtures/training_v3/pairing_helpers/`:

- `pairing_helpers_canonical.json`
- `pairing_helpers_alias.json`
- `pairing_helpers_unknown.json`
- `pairing_helpers_mixed.json`
- `pairing_helpers_group_cases.json`
- `pairing_helpers_symmetry_cases.json`
- `pairing_helpers_interference_cases.json`

Cambios principales:

- `glute/quads` paso de `synergy` a `none`.
- `glute/gluteos` paso de `forbiddenSamePrimary` a `none`.
- `back/pectorals` ahora devuelve `areAntagonists: true`.
- `back/shoulders` paso de `none` a `synergy` por expansion completa de grupos.
- Las notas legacy/observacionales fueron reemplazadas por contrato strict.

## 19. Tests ejecutados

Comando:

```powershell
flutter test test/domain/training_v3/regression/pairing_helpers_fixtures_regression_test.dart --reporter expanded
```

Resultado:

- `+11: All tests passed!`

Comando:

```powershell
flutter test test/domain/training_v3/regression/session_structure_engine_fixtures_regression_test.dart --reporter expanded
```

Resultado:

- `+10: All tests passed!`

Comando:

```powershell
flutter test test/domain/training_v3/regression/exercise_selection_engine_fixtures_regression_test.dart --reporter expanded
```

Resultado:

- `+11: All tests passed!`

Comando:

```powershell
flutter test test/domain/training_v3/regression/weekly_volume_planner_fixtures_regression_test.dart --reporter expanded
```

Resultado:

- `+8: All tests passed!`

Comando:

```powershell
flutter test test/core/registry/muscle_registry_strict_test.dart test/features/training_feature/domain/exercise_preferences_muscle_key_mapper_strict_test.dart test/domain/training_v3/resolvers/muscle_to_catalog_resolver_strict_test.dart test/domain/training_v3/utils/muscle_key_adapter_v3_strict_test.dart test/domain/training_v3/validators/training_plan_forensic_validator_muscle_ssot_test.dart test/domain/training/models/mev_table_strict_muscle_test.dart test/domain/training/validation/vop_validator_strict_muscle_test.dart test/domain/training_v3/validators/volume_validator_strict_muscle_test.dart --reporter expanded
```

Resultado:

- `+55: All tests passed!`

## 20. Resultado flutter analyze

Comando:

```powershell
flutter analyze --no-pub
```

Resultado:

- `No issues found! (ran in 193.4s)`

## 21. Riesgos pendientes

Riesgos pendientes:

- Call sites externos pueden haber dependido implicitamente de que `glute` se tratara como `glutes`; ahora retornara `none` / `false`.
- Los grupos ahora se evaluan por combinaciones completas. Esto es el contrato solicitado, pero cambia resultados como `back/shoulders`.
- No se hizo barrido global de consumidores porque el scope prohibia tocar `CycleTemplateBuilder`, `MotorV3Orchestrator`, UI, DB, modelos y repositorios.

## 22. Siguiente sprint recomendado

Siguiente sprint recomendado:

- D1R8: fixtures/goldens observacionales para call sites que consumen `PairingContract` y `AntagonistPairingEngine` fuera de `SessionStructureEngine`, especialmente rutas de template/ciclo que no se tocaron en D1-C7.

Objetivo:

- Verificar impacto de grupos strict y de `glute -> none` en consumidores compartidos sin ampliar este sprint.

## 23. Que NO se toco

No se toco:

- `SessionStructureEngine`
- `ExerciseSelectionEngine`
- `CycleTemplateBuilder`
- `MotorV3Orchestrator`
- UI
- DB
- modelos
- repositorios
- catalogo productivo
- formulas de volumen
- reglas cientificas de entrenamiento
- reportes en raiz

## Conclusion operativa

D1-C7 queda cerrado.

`PairingContract` y `AntagonistPairingEngine` ya usan MuscleRegistry strict API, no hacen raw passthrough, no convierten `glute` a `glutes`, preservan aliases/canonicos validos y aplican un contrato explicito y consistente para grupos.
