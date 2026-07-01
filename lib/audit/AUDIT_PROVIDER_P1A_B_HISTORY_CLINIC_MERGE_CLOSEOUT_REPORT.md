# AUDIT_PROVIDER_P1A_B_HISTORY_CLINIC_MERGE_CLOSEOUT_REPORT

## 1. Resumen ejecutivo

PROVIDER-P1A-B cerrado.

Las tabs clinicas migradas (`personal`, `background`, `general`, `gyneco`) ya no devuelven un `Client` amplio desde `saveIfDirty()`. `HistoryClinicScreen` dejo de acumular resultados y dejo de ejecutar el merge amplio residual. El merge amplio de `HistoryClinicViewModel.saveClient(Client updated)` queda como ruta legacy para callers externos, marcado y fuera del flujo normal de tabs clinicas migradas.

## 2. Riesgo inicial

El riesgo residual era que `HistoryClinicScreen` aceptaba `Client? updated` desde cada tab y, si no era null, remezclaba secciones completas:

- `profile: updatedClient.profile`
- `history: updatedClient.history`
- `training: updatedClient.training.copyWith(extra: mergedTrainingExtra)`
- `nutrition.extra` con merge amplio

Ese contrato podia reintroducir snapshots viejos si alguna tab volvia a devolver un `Client` amplio, incluso cuando los patch helpers ya guardaban contra `prev` fresco via `clientsProvider.updateActiveClient((prev) { ... })`.

## 3. Archivos inspeccionados

- `lib/features/history_clinic_feature/screen/history_clinic_screen.dart`
- `lib/features/history_clinic_feature/viewmodel/history_clinic_view_model.dart`
- `lib/features/history_clinic_feature/tabs/clinical_tab_client_patches.dart`
- `lib/features/history_clinic_feature/tabs/personal_data_tab.dart`
- `lib/features/history_clinic_feature/tabs/background_tab.dart`
- `lib/features/history_clinic_feature/tabs/general_evaluation_tab.dart`
- `lib/features/history_clinic_feature/tabs/gyneco_tab.dart`
- `test/features/history_clinic_feature/clinical_tabs_stale_drafts_test.dart`

## 4. Archivos modificados

- `lib/features/history_clinic_feature/screen/history_clinic_screen.dart`
- `lib/features/history_clinic_feature/viewmodel/history_clinic_view_model.dart`
- `lib/features/history_clinic_feature/tabs/clinical_tab_client_patches.dart`
- `lib/features/history_clinic_feature/tabs/personal_data_tab.dart`
- `lib/features/history_clinic_feature/tabs/background_tab.dart`
- `lib/features/history_clinic_feature/tabs/general_evaluation_tab.dart`
- `lib/features/history_clinic_feature/tabs/gyneco_tab.dart`
- `test/features/history_clinic_feature/history_clinic_merge_closeout_test.dart`
- `lib/audit/AUDIT_PROVIDER_P1A_B_HISTORY_CLINIC_MERGE_CLOSEOUT_REPORT.md`

## 5. Flujo anterior

`HistoryClinicScreen._saveTabIfNeeded()` esperaba un `Client?` desde las tabs:

```dart
Client? updated;
updated = await _personalTabKey.currentState?.saveIfDirty();
```

Si habia resultado, ejecutaba merge amplio:

```dart
return prev.copyWith(
  profile: updatedClient.profile,
  history: updatedClient.history,
  training: updatedClient.training.copyWith(extra: mergedTrainingExtra),
  nutrition: prev.nutrition.copyWith(
    extra: mergedNutritionExtra,
    dailyMealPlans:
        updatedClient.nutrition.dailyMealPlans ??
        prev.nutrition.dailyMealPlans,
  ),
);
```

## 6. Flujo nuevo

- Cada tab clinica migrada guarda internamente con su patch helper y `clientsProvider.updateActiveClient((prev) { ... })`.
- `saveIfDirty()` en las 4 tabs ahora es `Future<void>`.
- `HistoryClinicScreen` solo delega el guardado a la tab activa o pendiente; no recibe `Client` y no remezcla.
- `HistoryClinicViewModel.saveClient(Client updated)` no se elimina porque tiene callers externos; queda marcado como legacy y no participa en tabs clinicas migradas.

## 7. Codigo relevante antes/despues

Antes:

```dart
Future<Client?> saveIfDirty() async {
  if (!_isDirty || _client == null) return null;
  ...
  return null;
}
```

Despues:

```dart
Future<void> saveIfDirty() async {
  if (!_isDirty || _client == null) return;
  ...
}
```

Antes en screen:

```dart
if (updated != null) {
  final updatedClient = updated;
  await ref.read(clientsProvider.notifier).updateActiveClient((prev) {
    ...
  });
}
```

Despues en screen:

```dart
Future<void> _saveTabIfNeeded(int tabIndex) async {
  switch (tabIndex) {
    case 0:
      await _personalTabKey.currentState?.saveIfDirty();
      break;
    case 1:
      await _backgroundTabKey.currentState?.saveIfDirty();
      break;
    case 2:
      await _generalTabKey.currentState?.saveIfDirty();
      break;
    case 4:
      await _gynecoTabKey.currentState?.saveIfDirty();
      break;
    default:
      break;
  }
}
```

Helper puro de contrato legacy:

```dart
bool shouldRunLegacyHistoryMerge(Iterable<Client?> tabResults) =>
    tabResults.any((result) => result != null);
```

## 8. Tests creados/ajustados

- Creado `test/features/history_clinic_feature/history_clinic_merge_closeout_test.dart`
  - `clinical tab patches preserve unrelated sections`
  - `history clinic wide merge is not used for migrated tabs`
  - `clinical revisions change only on relevant fields`
- Validado `test/features/history_clinic_feature/clinical_tabs_stale_drafts_test.dart`

## 9. Resultado de tests

```text
& C:\src\flutter\bin\flutter.bat test test\features\history_clinic_feature\history_clinic_merge_closeout_test.dart --reporter expanded
00:00 +3: All tests passed!

& C:\src\flutter\bin\flutter.bat test test\features\history_clinic_feature\clinical_tabs_stale_drafts_test.dart --reporter expanded
00:00 +8: All tests passed!

& C:\src\flutter\bin\flutter.bat test test\data\repositories\client_repository_outbox_test.dart --reporter expanded
00:00 +5: All tests passed!

& C:\src\flutter\bin\flutter.bat test test\data\repositories\clinical_records_outbox_test.dart --reporter expanded
00:00 +5: All tests passed!

& C:\src\flutter\bin\flutter.bat test test\data\repositories\client_repository_sync_test.dart --reporter expanded
00:00 +8: All tests passed!
```

## 10. Resultado analyze

```text
& C:\src\flutter\bin\flutter.bat analyze --no-pub
Analyzing hcs_app_lap...
No issues found! (ran in 238.3s)
```

## 11. Que NO se toco

- UI visual.
- Layout.
- Labels visibles.
- Motor V3.
- Logica cientifica.
- Firebase rules.
- Dependencias.
- `pubspec.yaml`.
- Agenda/pagos.
- Nutricion fuera de campos ya usados por historia clinica.
- Entrenamiento fuera de campos ya usados por historia clinica.
- Migraciones SQLite.
- Outbox Client productivo.
- Outbox clinical productivo.

## 12. Riesgos pendientes

- `HistoryClinicViewModel.saveClient(Client updated)` conserva merge amplio porque tiene callers externos fuera del flujo de tabs clinicas migradas; queda marcado como legacy.
- `clinical_tab_client_patches.dart` y `clinical_tabs_stale_drafts_test.dart` aparecen como untracked en este checkout, pero fueron usados y validados en este cierre.

## 13. Siguiente sprint recomendado

SAVE-P0E: deletes granulares antropometria/bioquimica con outbox durable.

Justificacion: PROVIDER-P1A-B queda cerrado y los canaries SAVE-P0A/P0B/P0C pasaron. El siguiente riesgo de save/sync es completar la simetria durable para deletes granulares de records clinicos, evitando que delete dependa de rutas no durables o de exito remoto inmediato.
