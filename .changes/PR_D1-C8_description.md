Resumen del PR: Migración a normalización estricta en CycleTemplateBuilder + ajustes en fixtures y harness

Archivos modificados:
- lib/domain/training_v3/services/cycle_template_builder.dart (normalización strict)
- lib/domain/training_v3/data/exercise_catalog_v3.dart (test-skip loading when test-injected)
- test/fixtures/training_v3/pairing_callsites/pairing_callsites_cycle_template_unknown.json (ajuste unknown_glute_quads)
- test/domain/training_v3/services/motor_v3_cycle_state_regression_test.dart (ensureInitialized + loadFromExercises + test exercise metadata)

Resumen de cambios:
- CycleTemplateBuilder ahora rechaza claves musculares desconocidas con StateError prefijado: [V3][MUSCLE_NORMALIZE_FAIL]
- Fixtures actualizados para reflejar comportamiento strict (glute permanece raw)
- Harness y tests adaptados para inyectar un catálogo de prueba y evitar carga runtime de assets durante pruebas unitarias
- Ajustes menores para permitir selección de intensidad en tests (allowedIntensityZones=true)

Open issues (recomendado antes de merge):
1. Resolver INTENSITY_PRECHECK_FAIL en tests: ajustar catálogo de prueba o política de pre-check.
2. Revisar otros fixtures que aún puedan asumir normalización lax.

Cómo probar localmente:
```bash
# correr tests focalizados
flutter test test/domain/training_v3/regression/cycle_template_builder_build_base_week_harness_regression_test.dart --reporter expanded

# correr suite de training_v3
flutter test test/domain/training_v3 --reporter expanded
```

Nota: este PR se marca como draft; recomiendo revisión manual del comportamiento strict sobre inputs externos antes de merge.
