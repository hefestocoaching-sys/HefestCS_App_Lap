# AUDIT MUSCLE SSOT D1R7 - Pairing helpers fixtures

## 1. Resumen ejecutivo

D1R7 quedo aplicado como baseline observacional para `PairingContract` y `AntagonistPairingEngine`.

No se migro ningun helper a MuscleRegistry strict API y no se modifico logica productiva. Se congelaron fixtures/goldens con el comportamiento actual, incluyendo aliases validos, unknowns, grupos legacy, simetria e interferencia.

Hallazgo principal:

- `PairingContract` usa `muscle_registry.normalize`, `muscle_registry.expandGroup` y fallback `raw.trim().toLowerCase()`.
- `AntagonistPairingEngine` usa `normalizeMuscleKey` legacy desde `muscle_key_normalizer.dart`.
- `glute` aun se normaliza como `glutes` en ambos caminos legacy.
- Unknowns como `unknown_muscle`, `back_mid_upper` y `mysterychest` pasan por fallback raw en normalizadores legacy, aunque actualmente no encuentran reglas de pairing.

## 2. Confirmacion de scope

Dentro de scope:

- Auditar `PairingContract`.
- Auditar `AntagonistPairingEngine`.
- Crear fixtures observacionales bajo `test/fixtures/training_v3/pairing_helpers/`.
- Crear test de regresion observacional.
- Ejecutar validacion focalizada y `flutter analyze --no-pub`.
- Crear este reporte en `lib/audit/`.

Fuera de scope y no tocado:

- Migracion strict de `PairingContract`.
- Migracion strict de `AntagonistPairingEngine`.
- `SessionStructureEngine`.
- `ExerciseSelectionEngine`.
- `CycleTemplateBuilder`.
- `MotorV3Orchestrator`.
- UI.
- DB.
- modelos.
- repositorios.
- reglas de pairing.
- reglas cientificas.
- formulas de volumen.

## 3. Archivos modificados

- `test/domain/training_v3/regression/pairing_helpers_fixtures_regression_test.dart`
- `test/fixtures/training_v3/pairing_helpers/pairing_helpers_canonical.json`
- `test/fixtures/training_v3/pairing_helpers/pairing_helpers_alias.json`
- `test/fixtures/training_v3/pairing_helpers/pairing_helpers_unknown.json`
- `test/fixtures/training_v3/pairing_helpers/pairing_helpers_mixed.json`
- `test/fixtures/training_v3/pairing_helpers/pairing_helpers_group_cases.json`
- `test/fixtures/training_v3/pairing_helpers/pairing_helpers_symmetry_cases.json`
- `test/fixtures/training_v3/pairing_helpers/pairing_helpers_interference_cases.json`
- `lib/audit/AUDIT_MUSCLE_SSOT_D1R7_PAIRING_HELPERS_FIXTURES_REPORT.md`

No se modificaron archivos productivos.

## 4. Archivos inspeccionados

- `lib/domain/policies/pairing_contract.dart`
- `lib/domain/training_v3/engines/antagonist_pairing_engine.dart`
- `lib/core/utils/muscle_key_normalizer.dart`
- `lib/core/registry/muscle_registry.dart`
- `lib/domain/training_v3/data/interference_matrix.dart`
- `test/domain/training_v3/regression/session_structure_engine_fixtures_regression_test.dart`
- `test/domain/training_v3/regression/weekly_volume_planner_fixtures_regression_test.dart`

## 5. Metodos publicos de PairingContract

- `PairingContract.classify({required String firstPrimaryMuscle, required String secondPrimaryMuscle})`
  - Output: `PairingType`.
  - Tipos posibles observados: `antagonist`, `lowInterference`, `synergy`, `forbiddenSamePrimary`, `none`.

- `PairingContract.isAllowedBiserie({required String firstPrimaryMuscle, required String secondPrimaryMuscle})`
  - Output: `bool`.
  - Retorna `true` para `antagonist`, `lowInterference` y `synergy`.
  - Retorna `false` para `forbiddenSamePrimary` y `none`.

## 6. Metodos publicos de AntagonistPairingEngine

- `AntagonistPairingEngine.areAntagonists(String a, String b)`
  - Output: `bool`.
  - Evalua pares canonicos de antagonismo despues de normalizacion legacy.

## 7. Inputs requeridos

Ambos helpers reciben strings de musculo primario:

- `PairingContract`: `firstPrimaryMuscle`, `secondPrimaryMuscle`.
- `AntagonistPairingEngine`: `a`, `b`.

No requieren objetos de dominio ni catalogo.

## 8. Outputs observados

Snapshots usados por los fixtures:

```json
{
  "pairingContract": {
    "type": "antagonist",
    "isAllowedBiserie": true
  },
  "antagonistPairingEngine": {
    "areAntagonists": true
  }
}
```

## 9. Dependencias

`PairingContract` depende de:

- `muscle_registry.normalize`
- `muscle_registry.expandGroup`
- `InterferenceMatrix.lowInterference`
- `AntagonistPairingEngine.areAntagonists`

`AntagonistPairingEngine` depende de:

- `normalizeMuscleKey` de `lib/core/utils/muscle_key_normalizer.dart`

## 10. Uso actual de MuscleRegistry o normalizadores legacy

`PairingContract._canonical`:

- Primero llama `muscle_registry.normalize(raw)`.
- Luego llama `muscle_registry.expandGroup(raw)`.
- Si el grupo expande, toma `expanded.first`.
- Si nada matchea, retorna `raw.trim().toLowerCase()`.

`AntagonistPairingEngine._normalize`:

- Llama `normalizeMuscleKey(key)`.
- `normalizeMuscleKey` usa `registry.normalize(raw)`.
- Si detecta grupo, retorna token de grupo legacy como `back`, `shoulders`, `legs` o `arms`.
- Si no reconoce la clave, retorna `raw.toLowerCase()`.
- Tiene caso especial `traps_upper -> traps`.

## 11. Raw passthrough detectado

Raw passthrough actual:

- `PairingContract._canonical` retorna raw lowercase cuando no reconoce una clave.
- `normalizeMuscleKey` retorna raw lowercase cuando no reconoce una clave.
- `unknown_muscle`, `back_mid_upper` y `mysterychest` generan warnings legacy, pero pasan como strings raw.

Impacto observado:

- Los unknowns no encuentran reglas actuales y devuelven `none` / `false`.
- Aun asi, el contrato no es strict porque raw llega a la comparacion.

## 12. Fixtures creados

Directorio creado:

- `test/fixtures/training_v3/pairing_helpers/`

Fixtures:

- `pairing_helpers_canonical.json`
- `pairing_helpers_alias.json`
- `pairing_helpers_unknown.json`
- `pairing_helpers_mixed.json`
- `pairing_helpers_group_cases.json`
- `pairing_helpers_symmetry_cases.json`
- `pairing_helpers_interference_cases.json`

Test creado:

- `test/domain/training_v3/regression/pairing_helpers_fixtures_regression_test.dart`

## 13. Casos cubiertos

Canonical:

- `pectorals/lats`
- `quads/hamstrings`
- `biceps/triceps`
- `delts_front/delts_rear`
- `glutes/quads`
- `calves/abs`

Alias:

- `chest/lats`
- `quadriceps/hamstrings`
- `gluteos/quads`
- `deltoide_anterior/deltoide_posterior`
- `abdomen/calves`

Unknown:

- `unknown_muscle/lats`
- `back_mid_upper/pectorals`
- `mysterychest/lats`
- `glute/quads`

Mixed:

- `pectorals/chest`
- `pectorals/unknown_muscle`
- `chest/unknown_muscle`
- `glute/gluteos`
- `unknown_muscle/back_mid_upper`

Group:

- `back/pectorals`
- `shoulders/triceps`
- `legs/biceps`
- `arms/quads`
- `back/shoulders`

Symmetry:

- `pectorals/lats` y `lats/pectorals`
- `pectorals/calves` y `calves/pectorals`
- `pectorals/triceps` y `triceps/pectorals`
- mismo primary

Interference:

- baja interferencia
- antagonismo
- sinergia
- mismo primary prohibido
- ausencia de regla con unknown

## 14. Resultado observado por caso

Resultados relevantes:

- `pectorals/lats`: `antagonist`, biserie permitida, antagonistas `true`.
- `quads/hamstrings`: `antagonist`, biserie permitida, antagonistas `true`.
- `biceps/triceps`: `antagonist`, biserie permitida, antagonistas `true`.
- `delts_front/delts_rear`: `none`, biserie no permitida, antagonistas `false`.
- `glutes/quads`: `synergy`, biserie permitida, antagonistas `false`.
- `calves/abs`: `none`, biserie no permitida.
- `glute/quads`: `synergy`, biserie permitida por legacy `glute -> glutes`.
- `back/pectorals`: `PairingContract` devuelve `antagonist`; `AntagonistPairingEngine` devuelve `false`.

## 15. Tabla de aliases

| Input | Output actual | Strict esperado futuro |
| --- | --- | --- |
| `chest` | `pectorals` en ambos helpers | `pectorals` |
| `quadriceps` | `quads` en ambos helpers | `quads` |
| `gluteos` | `glutes` en ambos helpers | `glutes` |
| `deltoide_anterior` | `delts_front` en ambos helpers | `delts_front` |
| `deltoide_posterior` | `delts_rear` en ambos helpers | `delts_rear` |
| `abdomen` | `abs` en ambos helpers | `abs` |

## 16. Tabla de unknowns

| Input | Output actual | Strict esperado futuro |
| --- | --- | --- |
| `unknown_muscle` | fallback raw lowercase, sin regla | no clasificado / `none` |
| `back_mid_upper` | fallback raw lowercase, sin regla | no clasificado / `none` |
| `mysterychest` | fallback raw lowercase, sin regla | no clasificado / `none` |
| `glute` | legacy normalize a `glutes` | no clasificado / `none` |

## 17. Caso glute

Comportamiento actual:

- `PairingContract.classify(glute, quads)` devuelve `synergy`.
- `PairingContract.isAllowedBiserie(glute, quads)` devuelve `true`.
- `AntagonistPairingEngine.areAntagonists(glute, quads)` devuelve `false`.

Interpretacion:

- `glute` no es strict, pero el normalizador legacy lo convierte a `glutes`.
- Este comportamiento queda congelado como baseline observacional para D1-C7.

## 18. Caso unknown_muscle

Comportamiento actual:

- `PairingContract.classify(unknown_muscle, lats)` devuelve `none`.
- `PairingContract.isAllowedBiserie(unknown_muscle, lats)` devuelve `false`.
- `AntagonistPairingEngine.areAntagonists(unknown_muscle, lats)` devuelve `false`.

Interpretacion:

- `unknown_muscle` pasa como raw lowercase en normalizacion legacy.
- Actualmente no encuentra reglas, pero el raw passthrough existe.

## 19. Riesgos

Riesgos altos:

- `glute` sigue entrando como `glutes` por legacy normalizer en ambos helpers.
- `PairingContract` puede aceptar grupos y tomar solo el primer musculo expandido, por ejemplo `back -> lats`.
- `AntagonistPairingEngine` trata grupos distinto a `PairingContract`; por ejemplo `back/pectorals` es antagonista para `PairingContract`, pero no para `AntagonistPairingEngine`.

Riesgos medios:

- Unknowns pasan como raw lowercase antes de no encontrar reglas.
- El comportamiento de grupos no es consistente entre helpers.
- La migracion D1-C7 debe cuidar call sites compartidos fuera de `SessionStructureEngine`.

Riesgos menores:

- Los normalizadores legacy emiten logs debug/warning durante tests con aliases y unknowns.

## 20. Tests ejecutados

Comando:

```powershell
flutter test test/domain/training_v3/regression/pairing_helpers_fixtures_regression_test.dart --reporter expanded
```

Resultado:

- Primer intento dentro del sandbox: timeout sin salida util.
- Reintento fuera del sandbox: `+10: All tests passed!`

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

## 21. Resultado flutter analyze

Comando:

```powershell
flutter analyze --no-pub
```

Resultado:

- Primer intento dentro del sandbox: imprimio `No issues found! (ran in 177.9s)` pero termino por timeout del proceso.
- Reintento fuera del sandbox: `No issues found! (ran in 3.7s)` con exit code 0.

## 22. Siguiente sprint recomendado

D1-C7: migrar `PairingContract` y `AntagonistPairingEngine` a MuscleRegistry strict API.

Objetivos recomendados:

- Reemplazar normalizadores legacy por `tryNormalizeMuscleKey`.
- Usar `expandMuscleGroupStrict` solo si el contrato decide seguir aceptando grupos.
- Evitar `raw.trim().toLowerCase()` como fallback.
- Evitar `normalizeMuscleKey` legacy como contrato nuevo.
- Hacer que `glute` retorne `none` / `false`.
- Hacer que unknowns retornen `none` / `false` sin entrar como raw.
- Preservar aliases validos.
- Preservar reglas de antagonismo, baja interferencia, sinergia y mismo primary.
- Definir de forma explicita el contrato de grupos, porque hoy `PairingContract` y `AntagonistPairingEngine` difieren.

## 23. Que NO debe tocarse todavia

No tocar todavia:

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
- reglas de prioridad

## Conclusion operativa

D1R7 queda cerrado como baseline observacional.

El repo ahora tiene fixtures y test de regresion que congelan el comportamiento actual de los helpers compartidos de pairing antes de migrarlos. El siguiente paso correcto es D1-C7, limitado a migrar `PairingContract` y `AntagonistPairingEngine` a MuscleRegistry strict API usando estos fixtures como baseline.
