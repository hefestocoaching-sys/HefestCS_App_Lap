PR: Fixes for data persistence races, date handling and record parsing

Resumen:
- Implemented merge-on-write and per-client write serialization in `ClientsNotifier.updateActiveClient` to avoid lost-update races when multiple modules save concurrently.
- Synchronized `updatedAt` timestamp inside the JSON payload with the DB column in `DatabaseHelper._wrapClientJson` to avoid inconsistent ordering.
- Changed `Client.fromJson` to use epoch (1970-01-01) as fallback for invalid `createdAt`/`updatedAt` instead of `DateTime.now()` to avoid falsifying "most recent" logic.
- Hardened nutrition record helpers: normalize date strings, ignore invalid dates, and sort records robustly.

Ficheros modificados (principales):
- lib/features/main_shell/providers/clients_provider.dart
- lib/data/datasources/local/database_helper.dart
- lib/domain/entities/client.dart
- lib/features/history_clinic_feature/viewmodel/history_clinic_view_model.dart
- lib/features/nutrition_feature/widgets/dietary_tab.dart
- lib/features/training_feature/providers/training_plan_provider.dart
- lib/features/main_shell/screen/main_shell_screen.dart
- lib/utils/nutrition_record_helpers.dart

Tests añadidos:
- test/merge_updates_test.dart
- test/concurrent_updateActiveClient_test.dart
- test/client_fromjson_date_fallback_test.dart
- test/client_sorting_test.dart
- test/nutrition_record_helpers_test.dart
- test/navigation_save_integration_test.dart (marcado skip: requiere harness E2E; depende de navegación completa y puede ser flaky en entorno unit-test)

Criterios de aceptación (QA):
1. Ejecutar `flutter test` y verificar que TODO pase (incluyendo los tests nuevos).
2. Reproducir manualmente: dos módulos (p. ej. dieta y plan de comidas) guardan cambios simultáneos en client.nutrition.extra; verificar que ambos cambios persisten.
3. Asegurar que un JSON con `updatedAt: 'invalid'` no pasa a ser el registro más reciente al deserializar o listar clientes.
4. Verificar que `latestNutritionRecordByDate` selecciona la entrada correcta cuando las `dateIso` vienen con timestamp o con formato `YYYY-MM-DD`.

Notas de riesgo y mitigación:
- Cambios intencionados son locales y conservadores (merge de keys y colas por cliente). No se altera la arquitectura ni la UI.
- Se añadieron pruebas para los casos críticos. Recomendado ejecutar pruebas de integración adicionales en CI.

Siguientes pasos recomendados (no-blocking):
1. Añadir logging y métricas para detectar cuándo ocurren re-intentos en `updateActiveClient` (helpful for debugging races).
2. Revisar y endurecer parsers para otros records anidados (plans, adherence, training records) con validaciones y logs.
3. Añadir pruebas de integración end-to-end para flujos clínicos críticos.

Reviewer checklist:
- ¿Los cambios de merge mantienen campos no relacionados? (sí, pruebas lo verifican)
- ¿Se preservaron los objetivos clínicos al guardar? (sí, tests y revisión de código)
- ¿Hay casos de performance que requieran atención? (colas serializan escrituras por cliente; en escenarios de alto-concurrency esto es costoso, pero prefiero seguridad de datos sobre rendimiento para datos clínicos)

Documentación y pasos de verificación manual incluidos arriba.
