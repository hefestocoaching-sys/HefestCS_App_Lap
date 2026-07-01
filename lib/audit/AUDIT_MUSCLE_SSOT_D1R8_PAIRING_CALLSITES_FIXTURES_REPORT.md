# AUDIT MUSCLE SSOT D1R8 - Pairing call sites fixtures

## 1. Resumen ejecutivo

D1R8 quedo aplicado como baseline observacional post D1-C7 para call sites que consumen `PairingContract` y `AntagonistPairingEngine`, con foco en `CycleTemplateBuilder`.

No se modifico logica productiva. No se tocaron `PairingContract`, `AntagonistPairingEngine`, `SessionStructureEngine`, `ExerciseSelectionEngine`, `CycleTemplateBuilder`, `MotorV3Orchestrator`, UI, DB, modelos ni repositorios.

Hallazgo principal:

- `PairingContract` y `AntagonistPairingEngine` ya estan strict por D1-C7.
- `CycleTemplateBuilder` sigue teniendo `normalizeMuscleKey(k) => muscle_registry.normalize(k) ?? k.trim().toLowerCase()`.
- Por eso el call site puede convertir `glute -> glutes` antes de llamar a helpers strict.
- Unknowns como `unknown_muscle`, `back_mid_upper` y `mysterychest` pueden quedar como raw dentro del builder, aunque los helpers strict devuelven `none/false`.

## 2. Confirmacion de scope

Dentro de scope:

- Auditar `CycleTemplateBuilder` read-only.
- Buscar call sites de `PairingContract` y `AntagonistPairingEngine` bajo `lib/`.
- Crear fixtures observacionales bajo `test/fixtures/training_v3/pairing_callsites/`.
- Crear test de regresion/proxy bajo `test/domain/training_v3/regression/`.
- Ejecutar validacion focalizada y `flutter analyze --no-pub`.
- Crear este reporte en `lib/audit/`.

Fuera de scope y no tocado:

- Migrar `CycleTemplateBuilder`.
- Modificar `PairingContract`.
- Modificar `AntagonistPairingEngine`.
- Modificar `SessionStructureEngine`.
- Modificar `ExerciseSelectionEngine`.
- Modificar `CycleTemplateBuilder`.
- Modificar `MotorV3Orchestrator`.
- UI, DB, modelos, repositorios, catalogo productivo.

## 3. Archivos modificados

- `test/domain/training_v3/regression/pairing_callsites_fixtures_regression_test.dart`
- `test/fixtures/training_v3/pairing_callsites/pairing_callsites_cycle_template_canonical.json`
- `test/fixtures/training_v3/pairing_callsites/pairing_callsites_cycle_template_alias.json`
- `test/fixtures/training_v3/pairing_callsites/pairing_callsites_cycle_template_unknown.json`
- `test/fixtures/training_v3/pairing_callsites/pairing_callsites_cycle_template_group.json`
- `test/fixtures/training_v3/pairing_callsites/pairing_callsites_cycle_template_mixed.json`
- `test/fixtures/training_v3/pairing_callsites/pairing_callsites_biserie_cases.json`
- `test/fixtures/training_v3/pairing_callsites/pairing_callsites_order_cases.json`
- `lib/audit/AUDIT_MUSCLE_SSOT_D1R8_PAIRING_CALLSITES_FIXTURES_REPORT.md`

No se modificaron archivos productivos en D1R8.

Nota de estado local: `PairingContract` y `AntagonistPairingEngine` aparecen modificados en git por D1-C7 previo, no por D1R8.

## 4. Archivos inspeccionados

- `lib/domain/training_v3/services/cycle_template_builder.dart`
- `lib/domain/training_v3/validators/training_plan_forensic_validator.dart`
- `lib/domain/policies/pairing_contract.dart`
- `lib/domain/training_v3/engines/antagonist_pairing_engine.dart`
- `lib/domain/training_v3/data/interference_matrix.dart`
- `test/domain/training_v3/verification/cycle_template_allocation_audit_test.dart`
- `test/fixtures/training_v3/pairing_helpers/`

## 5. Call sites encontrados

Call sites reales:

- `lib/domain/training_v3/services/cycle_template_builder.dart`
  - Usa `AntagonistPairingEngine.areAntagonists`.
  - Usa `PairingContract.isAllowedBiserie`.
  - Tiene normalizador local legacy.
  - Clasificacion: requiere fixture y migracion futura.

- `lib/domain/training_v3/validators/training_plan_forensic_validator.dart`
  - Usa `PairingContract.isAllowedBiserie`.
  - Ya tiene tests SSOT focalizados.
  - Clasificacion: seguro por ahora; no fue foco D1R8.

- `lib/domain/training_v3/engines/session_structure_engine.dart`
  - Usa ambos helpers.
  - Ya cubierto por D1-C6.
  - Clasificacion: fuera de scope D1R8.

No se encontraron usos directos relevantes de estos helpers en UI, DB o repositorios.

## 6. Metodos de CycleTemplateBuilder relacionados

Metodos publicos relevantes:

- `buildBaseWeek`
- `normalizeMuscleKey`

Metodos privados relevantes:

- `_orderMusclesByBlockPriority`
- `_buildDayBlockMusclePlan`
- `_isValidPairingForBlock`
- `_exercisePrimaryMuscle`
- `_isLowInterference`
- `_applyPreferredDayOrder`
- `_canonicalizeVolumeMap`
- `_canonicalizeExercisePool`

## 7. Inputs requeridos

El test D1R8 usa inputs minimos:

- `firstPrimaryMuscle`
- `secondPrimaryMuscle`
- `primaryMuscle` opcional
- `dayMuscles` opcional

El proxy normaliza con:

- `CycleTemplateBuilder.normalizeMuscleKey`

Luego evalua:

- `PairingContract.classify`
- `PairingContract.isAllowedBiserie`
- `AntagonistPairingEngine.areAntagonists`
- proxy de orden/bloques A/B/C/D equivalente al fragmento privado auditado.

## 8. Outputs observados

Cada fixture captura:

- Normalizacion del call site.
- Resultado directo de helpers strict con raw input.
- Resultado despues de normalizar como lo hace `CycleTemplateBuilder`.
- `isLowInterference` local proxy.
- `orderedMuscles`.
- `blockPlan` A/B/C/D.

Ejemplo de snapshot:

```json
{
  "normalization": {
    "first": "glutes",
    "second": "quads"
  },
  "directHelpers": {
    "pairingType": "none",
    "isAllowedBiserie": false,
    "areAntagonists": false
  },
  "cycleTemplateProxy": {
    "pairingType": "synergy",
    "isAllowedBiserie": true,
    "areAntagonists": false
  }
}
```

## 9. Dependencias

`CycleTemplateBuilder` depende de:

- `PairingContract`
- `AntagonistPairingEngine`
- `InterferenceMatrix`
- `ExerciseCatalogV3`
- `SessionStructureEngine`
- `ExerciseSelectionEngine`
- `ExerciseOrderingEngine`
- `ExerciseRoleEngine`
- `IntensityDistributionEngine`
- `RepStructureEngine`
- `DayStartPolicy`
- `SplitTableSSOT`
- `muscle_registry`

El test D1R8 usa solo la superficie necesaria para congelar pairing-callsite behavior.

## 10. Uso actual de PairingContract

`CycleTemplateBuilder` usa `PairingContract.isAllowedBiserie` en:

- `_buildDayBlockMusclePlan`
- `_isValidPairingForBlock`

Observacion:

- `_buildDayBlockMusclePlan` no manda todo `isAllowedBiserie` a bloque B.
- Para B exige `isAllowedBiserie` y ademas `AntagonistPairingEngine.areAntagonists` o `_isLowInterference`.
- Por eso una `synergy` valida puede no entrar a B.

## 11. Uso actual de AntagonistPairingEngine

`CycleTemplateBuilder` usa `AntagonistPairingEngine.areAntagonists` en:

- Clasificacion de seeds frente al main lift.
- Ordenamiento por bloque.
- Filtro de compatibilidad para bloque C.
- Construccion del plan muscular A/B/C/D.

Post D1-C7, el helper ya expande grupos strict, pero el builder combina esa salida con `_isLowInterference` local, que no expande grupos.

## 12. Uso de normalizadores legacy en call sites

Riesgo confirmado:

```dart
static String normalizeMuscleKey(String k) {
  return muscle_registry.normalize(k) ?? k.trim().toLowerCase();
}
```

Impacto:

- `glute` se vuelve `glutes` dentro de `CycleTemplateBuilder`.
- `unknown_muscle` queda `unknown_muscle`.
- `back_mid_upper` queda `back_mid_upper`.
- `mysterychest` queda `mysterychest`.
- Grupos como `back`, `shoulders`, `legs`, `arms` quedan como tokens de grupo, no se expanden en el normalizador del builder.

## 13. Raw passthrough detectado

Raw passthrough detectado en `CycleTemplateBuilder`, no en los helpers D1-C7:

- `normalizeMuscleKey(k) => muscle_registry.normalize(k) ?? k.trim().toLowerCase()`

Casos congelados:

- `unknown_muscle/lats` conserva `unknown_muscle` como primary normalizado del builder.
- `back_mid_upper/pectorals` conserva `back_mid_upper`.
- `mysterychest/lats` conserva `mysterychest`.
- `glute/quads` se convierte a `glutes/quads`.

## 14. Fixtures creados

Directorio:

- `test/fixtures/training_v3/pairing_callsites/`

Fixtures:

- `pairing_callsites_cycle_template_canonical.json`
- `pairing_callsites_cycle_template_alias.json`
- `pairing_callsites_cycle_template_unknown.json`
- `pairing_callsites_cycle_template_group.json`
- `pairing_callsites_cycle_template_mixed.json`
- `pairing_callsites_biserie_cases.json`
- `pairing_callsites_order_cases.json`

Test:

- `test/domain/training_v3/regression/pairing_callsites_fixtures_regression_test.dart`

## 15. Casos cubiertos

Canonical:

- `pectorals/lats`
- `quads/hamstrings`
- `biceps/triceps`
- `glutes/quads`

Alias:

- `chest/lats`
- `quadriceps/hamstrings`
- `gluteos/quads`
- `deltoide_anterior/deltoide_posterior`

Unknown:

- `glute/quads`
- `unknown_muscle/lats`
- `back_mid_upper/pectorals`
- `mysterychest/lats`

Group:

- `back/pectorals`
- `shoulders/triceps`
- `legs/biceps`
- `arms/quads`
- `back/shoulders`

Mixed:

- canonical + alias
- canonical + unknown
- alias + unknown
- group + canonical
- group + unknown

Biserie:

- antagonist allowed
- synergy allowed
- lowInterference allowed
- forbiddenSamePrimary rejected
- none rejected

Order:

- primary -> antagonist -> lowInterference -> rest
- group strict impact in order proxy

## 16. Resultado observado por caso

Resultados relevantes:

- `pectorals/lats`: direct helpers `antagonist/true/true`; proxy B.
- `glutes/quads`: direct helpers `synergy/true/false`; proxy C porque B exige antagonist o lowInterference.
- `glute/quads`: direct helpers `none/false/false`; proxy normaliza `glute -> glutes` y queda `synergy/true/false`.
- `unknown_muscle/lats`: direct helpers `none/false/false`; proxy mantiene `unknown_muscle` y lo ubica como A si es primary.
- `back/pectorals`: direct helpers `antagonist/true/true`; proxy B.
- `back/shoulders`: direct helpers `synergy/true/false`; proxy C porque no es antagonist ni lowInterference local.
- `legs/biceps`: direct helpers `lowInterference/true/false`; proxy D porque `_isLowInterference` local no expande grupo y biceps es accesorio.
- `pectorals/chest`: same primary prohibido; proxy conserva duplicado normalizado y lo manda a C en el harness.

## 17. Impacto de D1-C7 en call sites

D1-C7 corrigio los helpers, pero no todos los call sites quedaron libres de legacy:

- Los helpers raw `glute/quads` devuelven `none/false`.
- `CycleTemplateBuilder.normalizeMuscleKey('glute')` devuelve `glutes`.
- Por tanto, un path del builder que normalice antes de llamar helpers puede seguir tratando `glute` como `glutes`.

Tambien hay diferencia con grupos:

- Helpers D1-C7 expanden grupos.
- `_isLowInterference` local del builder no expande grupos.
- Por eso algunos grupos son `isAllowedBiserie=true`, pero no entran a B si no son antagonist y si la baja interferencia solo aparece tras expansion strict.

## 18. Riesgos

Riesgos altos:

- `CycleTemplateBuilder` puede reintroducir `glute -> glutes`.
- `CycleTemplateBuilder` puede mantener unknowns raw internamente.
- Grupos strict son entendidos por helpers, pero no por `_isLowInterference` local.

Riesgos medios:

- `_buildDayBlockMusclePlan` puede ubicar same-primary normalizado en C cuando llega como duplicado en el proxy.
- El harness es proxy porque los metodos de bloque son privados; no sustituye un test full `buildBaseWeek`.

Riesgos menores:

- El test replica logica privada observada; si el builder cambia, el proxy debe revisarse.

## 19. Tests ejecutados

Comando:

```powershell
flutter test test/domain/training_v3/regression/pairing_callsites_fixtures_regression_test.dart --reporter expanded
```

Resultado:

- `+9: All tests passed!`

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

- `No issues found! (ran in 61.5s)`

## 21. Siguiente sprint recomendado

Siguiente sprint recomendado:

- D1-C8: migrar `CycleTemplateBuilder` en sus superficies de normalizacion muscular relacionadas con pairing y bloques.

Alcance recomendado:

- Reemplazar `normalizeMuscleKey(k) => muscle_registry.normalize(k) ?? k.trim().toLowerCase()` por un contrato strict o un helper strict local en rutas de pairing.
- Evitar que `glute` llegue como `glutes`.
- Evitar unknown raw en `_buildDayBlockMusclePlan`, `_orderMusclesByBlockPriority`, `_isValidPairingForBlock` y `_exercisePrimaryMuscle`.
- Resolver `_isLowInterference` para grupos usando la misma expansion strict que D1-C7.
- No tocar `MotorV3Orchestrator`.
- No tocar UI/DB/modelos/repositorios.

Si se quiere mayor evidencia antes de migrar:

- Crear un D1R9 con harness real de `CycleTemplateBuilder.buildBaseWeek` usando catalogo minimo/real para cubrir plan completo.

## 22. Que NO debe tocarse todavia

No tocar todavia:

- `MotorV3Orchestrator`
- `SessionStructureEngine`
- `ExerciseSelectionEngine`
- `PairingContract`
- `AntagonistPairingEngine`
- UI
- DB
- modelos
- repositorios
- catalogo productivo
- formulas de volumen
- reglas cientificas de entrenamiento

## Conclusion operativa

D1R8 queda cerrado como baseline observacional de call sites.

El punto critico ya no esta en `PairingContract` ni en `AntagonistPairingEngine`; esta en `CycleTemplateBuilder`, que todavia normaliza con fallback legacy antes de usar helpers strict. El siguiente paso correcto es D1-C8 sobre `CycleTemplateBuilder`, o un D1R9 de harness full `buildBaseWeek` si se prefiere mas cobertura antes de migrar.
