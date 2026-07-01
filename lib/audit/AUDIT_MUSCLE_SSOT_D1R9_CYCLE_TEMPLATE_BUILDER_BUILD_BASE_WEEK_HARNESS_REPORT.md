# AUDIT MUSCLE SSOT D1R9 - CycleTemplateBuilder buildBaseWeek harness

## 1. Resumen ejecutivo

D1R9 quedo aplicado como baseline observacional real para `CycleTemplateBuilder.buildBaseWeek`, antes de cualquier migracion a la API estricta de `MuscleRegistry` en D1-C8.

No se modifico logica productiva. El cambio quedo limitado a harness, fixtures observacionales y este reporte.

Hallazgo principal:

- El harness ejecuta el `buildBaseWeek` real contra catalogo fake instalado en test.
- El builder actual sigue canonicalizando algunos tokens legacy dentro del propio call site, por ejemplo `glute -> glutes`.
- Los grupos crudos como `back`, `shoulders`, `arms` y `legs` siguen fallando en la seleccion real del builder.
- `buildBaseWeek` produce salidas observables distintas segun el tipo de input: canonical, alias, raw unknown y combinaciones mixtas.

## 2. Scope confirmado

Dentro de scope:

- Crear harness real de `CycleTemplateBuilder.buildBaseWeek` en test.
- Crear fixtures observacionales para canonical, alias, unknown, mixed y block/pairing paths.
- Ejecutar validacion focalizada del harness.
- Crear este reporte en `lib/audit/`.

Fuera de scope y no tocado:

- Migrar `CycleTemplateBuilder` a `MuscleRegistry` strict API.
- Cambiar logica productiva de `CycleTemplateBuilder`.
- Cambiar `ExerciseCatalogV3` en produccion.
- Cambiar servicios, repositorios, UI o DB.

## 3. Archivos modificados

- `test/domain/training_v3/regression/cycle_template_builder_build_base_week_harness_regression_test.dart`
- `test/fixtures/training_v3/cycle_template_builder/cycle_template_builder_canonical.json`
- `test/fixtures/training_v3/cycle_template_builder/cycle_template_builder_alias.json`
- `test/fixtures/training_v3/cycle_template_builder/cycle_template_builder_unknown.json`
- `test/fixtures/training_v3/cycle_template_builder/cycle_template_builder_mixed.json`
- `test/fixtures/training_v3/cycle_template_builder/cycle_template_builder_block_pairing.json`
- `test/fixtures/training_v3/cycle_template_builder/cycle_template_builder_training_week_snapshot.json`
- `lib/audit/AUDIT_MUSCLE_SSOT_D1R9_CYCLE_TEMPLATE_BUILDER_BUILD_BASE_WEEK_HARNESS_REPORT.md`

## 4. Archivos inspeccionados

- `lib/domain/training_v3/services/cycle_template_builder.dart`
- `lib/domain/training_v3/catalog/exercise_catalog_v3.dart`
- `test/domain/training_v3/regression/cycle_template_builder_build_base_week_harness_regression_test.dart`
- `test/fixtures/training_v3/cycle_template_builder/`

## 5. Comportamiento observado

Casos confirmados por el harness real:

- Canonical: salida de 4 ejercicios con orden estable y bloques A/B/C/D.
- Alias: normalizacion legacy a claves SSOT y salida de 4 ejercicios.
- Unknown glute: `glute` sigue cayendo en `glutes` y ejecuta un plan valido.
- Unknown raw: claves desconocidas fallan con `Bad state:`.
- Mixed canonical/alias: los duplicados canonicos se consolidan en un solo volumen normalizado.
- Pairing antagonist: salida real con 4 ejercicios y orden de bloques observables.
- Pairing synergy: salida real con 3 ejercicios y orden de bloques observables.
- Pairing low interference: salida real con 2 ejercicios y bloques observables.
- Same-primary overcommit: falla por capacidad insuficiente, no genera plan.

## 6. Riesgos confirmados

- `CycleTemplateBuilder` mantiene comportamiento legacy en la normalizacion de claves musculares.
- Las entradas raw de grupo no estan preparadas para la seleccion real actual.
- Parte del comportamiento esperado depende de heuristicas locales del builder, no solo de helpers strict.

## 7. Validacion ejecutada

Se ejecuto y quedo verde:

- `flutter test test/domain/training_v3/regression/cycle_template_builder_build_base_week_harness_regression_test.dart --reporter expanded`

Resultado final del harness:

- `summary passed=9 failed=0`

## 8. Conclusiones

D1R9 dejo un baseline real y estable para `buildBaseWeek` antes de la migracion estricta.

La salida congelada en fixtures ya refleja el comportamiento actual del builder, incluyendo canonicalizacion legacy, fallos por grupos raw y limites de capacidad en casos de overcommit.

La migracion a la API estricta de `MuscleRegistry` debe tratar este reporte y estas fixtures como referencia previa.
