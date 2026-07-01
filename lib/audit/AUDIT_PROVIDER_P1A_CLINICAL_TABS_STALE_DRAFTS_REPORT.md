# AUDIT_PROVIDER_P1A_CLINICAL_TABS_STALE_DRAFTS_REPORT

## 1. Resumen ejecutivo

PROVIDER-P1A parcial.

El contrato de codigo quedo implementado en las cuatro tabs clinicas: cada `saveIfDirty()` guarda mediante `clientsProvider.updateActiveClient((prev) { ... })`, usa `prev` como base fresca y aplica un patch especifico de la seccion. `flutter analyze --no-pub` quedo limpio y los canaries SAVE-P0B/SAVE-P0C pasaron.

El cierre no puede marcarse como completo porque `flutter test test/features/history_clinic_feature/clinical_tabs_stale_drafts_test.dart --reporter expanded` se cuelga antes de imprimir salida y vence por timeout.

## 2. Estado inicial

Las tabs clinicas mantenian drafts locales correctos para UI, pero el guardado automatico devolvia un `Client` parcheado al `HistoryClinicScreen`. Luego el screen hacia una mezcla amplia de `profile`, `history`, `training` y `nutrition`, con riesgo de reintroducir snapshots viejos o pisar cambios recientes de otra tab del mismo cliente.

## 3. Archivos inspeccionados

- `lib/features/history_clinic_feature/tabs/clinical_tab_client_patches.dart`
- `lib/features/history_clinic_feature/tabs/personal_data_tab.dart`
- `lib/features/history_clinic_feature/tabs/background_tab.dart`
- `lib/features/history_clinic_feature/tabs/general_evaluation_tab.dart`
- `lib/features/history_clinic_feature/tabs/gyneco_tab.dart`
- `lib/features/history_clinic_feature/screen/history_clinic_screen.dart`
- `lib/domain/entities/client.dart`
- `lib/domain/entities/client_profile.dart`
- `lib/domain/entities/clinical_history.dart`
- `lib/domain/entities/nutrition_settings.dart`
- `lib/domain/entities/training_profile.dart`
- `test/features/history_clinic_feature/clinical_tabs_stale_drafts_test.dart`

## 4. Archivos modificados

- `lib/features/history_clinic_feature/tabs/clinical_tab_client_patches.dart`
- `lib/features/history_clinic_feature/tabs/personal_data_tab.dart`
- `lib/features/history_clinic_feature/tabs/background_tab.dart`
- `lib/features/history_clinic_feature/tabs/general_evaluation_tab.dart`
- `lib/features/history_clinic_feature/tabs/gyneco_tab.dart`
- `test/features/history_clinic_feature/clinical_tabs_stale_drafts_test.dart`
- `lib/audit/AUDIT_PROVIDER_P1A_CLINICAL_TABS_STALE_DRAFTS_REPORT.md`

## 5. Estado por tab

| Tab | Estado | Usa patch helper | Usa activeClient fresco | Rehidrata por revision | Riesgo residual |
| --- | ------ | ---------------- | ----------------------- | ---------------------- | --------------- |
| personal_data_tab | Implementado | Si | Si, `prev` de `updateActiveClient` | Si, `personalDataTabRevision` | Bajo; test nuevo no ejecuta por cuelgue del runner |
| background_tab | Implementado | Si | Si, `prev` de `updateActiveClient` | Si, `backgroundTabRevision` | Bajo; test nuevo no ejecuta por cuelgue del runner |
| general_evaluation_tab | Implementado | Si | Si, `prev` de `updateActiveClient` | Si, `generalEvaluationTabRevision` | Bajo; test nuevo no ejecuta por cuelgue del runner |
| gyneco_tab | Implementado | Si | Si, `prev` de `updateActiveClient` | Si, `gynecoTabRevision` | Bajo; test nuevo no ejecuta por cuelgue del runner |

## 6. Patch helpers

| Helper | Campos que toca | Campos que preserva | Estado |
| ------ | --------------- | ------------------- | ------ |
| applyPersonalDataTabPatch | `profile.fullName`, `email`, `phone`, `birthDate`, `age`, `gender`, `country`, `occupation`, `level`, `objective`; `nutrition.planType`, `planStartDate`, `planEndDate`; `invitationCode` opcional | `history`, `training`, registros, outbox, y campos no editados de profile/nutrition | Implementado |
| applyBackgroundTabPatch | `history.extra[hereditaryFamilyHistory]`, `history.extra[personalPathologicalHistory]` | Datos personales, evaluacion general, gyneco, nutrition, training y otros extras | Implementado |
| applyGeneralEvaluationTabPatch | `history.allergies`, `history.medications`, `history.extra[foodPreferences]`, `history.extra[supplementUse]`, extras nutricionales de evaluacion general, y contexto competitivo de `training` | Datos personales, antecedentes, gyneco y campos no editados de nutrition/training | Implementado |
| applyGynecoTabPatch | `history.isBreastfeeding`, `cycleRelatedSymptoms`, `specificGynecoConditions`, extras gineco | Datos personales, antecedentes, evaluacion general, nutrition y training | Implementado |

## 7. Revision helpers

| Revision helper | Campos incluidos | Campos excluidos | Estado |
| --------------- | ---------------- | ---------------- | ------ |
| personalDataTabRevision | `client.id`, campos de `profile` editados por datos personales, `planType`, `planStartDate`, `planEndDate` | `updatedAt`, history, training, registros y extras no editados por la tab | Implementado |
| backgroundTabRevision | `client.id`, extras heredofamiliares y patologicos personales | `updatedAt`, profile, nutrition, training, general evaluation y gyneco | Implementado |
| generalEvaluationTabRevision | `client.id`, alergias, medicamentos, preferencias, suplementacion, extras nutricionales de evaluacion y contexto competitivo | `updatedAt`, datos personales, antecedentes no editados y gyneco | Implementado |
| gynecoTabRevision | `client.id`, lactancia, sintomas de ciclo, condiciones gineco y extras gineco | `updatedAt`, datos personales, antecedentes, evaluacion general, nutrition y training | Implementado |

## 8. Bugs encontrados

- Archivo: `personal_data_tab.dart`
  - Causa: `saveIfDirty()` devolvia un `Client` parcheado y no persistia directamente via provider.
  - Riesgo: el screen podia hacer una segunda mezcla amplia con snapshot viejo.
  - Cambio aplicado: `saveIfDirty()` ahora llama `clientsProvider.updateActiveClient` y aplica `applyPersonalDataTabPatch` sobre `prev`.

- Archivo: `background_tab.dart`
  - Causa: mismo patron de retorno de `Client` parcheado.
  - Riesgo: antecedentes podian guardar desde un draft viejo y despues ser remezclados por el screen.
  - Cambio aplicado: guardado automatico directo via provider con `applyBackgroundTabPatch`.

- Archivo: `general_evaluation_tab.dart`
  - Causa: mismo patron de retorno de `Client` parcheado.
  - Riesgo: evaluacion general podia pisar cambios gineco/personales recientes en la segunda mezcla.
  - Cambio aplicado: guardado automatico directo via provider con `applyGeneralEvaluationTabPatch`.

- Archivo: `gyneco_tab.dart`
  - Causa: mismo patron de retorno de `Client` parcheado.
  - Riesgo: gyneco podia pisar cambios de evaluacion general recientes en la segunda mezcla.
  - Cambio aplicado: guardado automatico directo via provider con `applyGynecoTabPatch`.

- Archivo: `clinical_tab_client_patches.dart`
  - Causa: revision helpers incluian `updatedAt`, que cambia por saves de otras secciones.
  - Riesgo: rehidrataciones no relevantes.
  - Cambio aplicado: las revisiones quedaron limitadas a campos reales de cada tab.

## 9. Contrato final

- El draft local sigue permitido para formularios.
- El draft local ya no es base completa de guardado.
- El base final de guardado es siempre `prev`, recibido desde `clientsProvider.updateActiveClient`.
- Cada tab aplica un patch especifico de su seccion.
- Las tabs no reemplazan subobjetos completos si solo cambiaron claves concretas.
- `_isDirty == true` evita rehidratacion destructiva sobre ediciones locales.
- Las revisiones usan solo campos relevantes de cada tab, no `updatedAt` global.

## 10. Tests creados

Archivo: `test/features/history_clinic_feature/clinical_tabs_stale_drafts_test.dart`

- `personal data patch does not overwrite background changes`
- `background patch does not overwrite personal data changes`
- `general evaluation patch does not overwrite gyneco changes`
- `gyneco patch does not overwrite general evaluation changes`
- `personalDataTabRevision changes when personal data changes`
- `backgroundTabRevision changes when background changes`
- `generalEvaluationTabRevision changes when general evaluation changes`
- `gynecoTabRevision changes when gyneco changes`

## 11. Resultado de tests

`flutter test test/features/history_clinic_feature/clinical_tabs_stale_drafts_test.dart --reporter expanded`

- Resultado: timeout.
- Detalle: el comando se colgo antes de imprimir el primer evento `loading` o cualquier fallo de assertion.
- Se repitio tras limpiar procesos Dart/DartVM y lockfiles de Flutter; volvio a colgarse.

`flutter test test/data/repositories/client_repository_outbox_test.dart --reporter expanded`

- Resultado: paso.
- Resumen: `00:00 +4: All tests passed!`
- Logs esperados: warning de permission-denied en retry path y remote queue already resolved.

`flutter test test/data/repositories/clinical_records_outbox_test.dart --reporter expanded`

- Resultado: paso.
- Resumen: `00:00 +5: All tests passed!`
- Logs esperados: `Anthropometry fast-path skipped: no remote datasource`.

## 12. Resultado flutter analyze

`flutter analyze --no-pub`

- Resultado: limpio.
- Salida: `No issues found! (ran in 67.5s)`

## 13. Que NO se toco

- UI visual.
- Layout.
- Labels/textos visibles.
- Motor V3.
- Logica cientifica de entrenamiento.
- Firebase rules.
- Dependencias.
- `pubspec.yaml`.
- Agenda/pagos.
- Nutricion productiva fuera de campos clinicos ya editados por la tab de evaluacion.
- Entrenamiento productivo fuera de campos clinicos ya editados por la tab de evaluacion.
- Migraciones SQLite.
- Outbox Client SAVE-P0B productivo.
- Outbox clinical SAVE-P0C productivo.

## 14. Riesgos pendientes

- El test nuevo obligatorio existe pero no pudo ejecutarse por cuelgue del runner en esa suite.
- `HistoryClinicScreen` conserva el codigo de mezcla amplia para compatibilidad, pero las tabs modificadas devuelven `null` despues de persistir para evitar esa segunda mezcla. Riesgo bajo mientras todas las tabs clinicas mantengan este contrato.

## 15. Siguiente sprint recomendado

PROVIDER-P1A-B con alcance exacto:

- Aislar por que `clinical_tabs_stale_drafts_test.dart` cuelga antes de cargar.
- Convertir los `saveIfDirty()` clinicos a una firma `Future<void>` cuando el screen pueda eliminar la compatibilidad con retorno `Client?`.
- Si el runner queda estable, re-ejecutar el test nuevo y cerrar PROVIDER-P1A.
