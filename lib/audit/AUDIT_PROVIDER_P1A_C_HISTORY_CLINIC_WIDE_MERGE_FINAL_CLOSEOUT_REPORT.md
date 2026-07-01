# AUDIT_PROVIDER_P1A_C_HISTORY_CLINIC_WIDE_MERGE_FINAL_CLOSEOUT_REPORT

## 1. Resumen ejecutivo

PROVIDER-P1A-C CERRADO.

Se cerraron las rutas productivas restantes de merge amplio de `Client` fuera de las tabs clinicas migradas. `HistoryClinicViewModel.saveClient(Client updated)` fue eliminado, `MealPlanScreen` dejo de usar `historyClinicVmProvider`, y `MainShellScreen` ya no remezcla `profile/history/training/nutrition` completos al guardar Historia Clinica.

## 2. Riesgo residual real encontrado tras P1A-B

PROVIDER-P1A-B cerro el flujo interno de tabs, pero quedaban rutas externas que podian recibir snapshots viejos:

- `HistoryClinicViewModel.saveClient(Client updated)` hacia `profile: updated.profile` y `history: updated.history`.
- `MealPlanScreen` llamaba `historyClinicVmProvider.saveClient(updated)` para cambios nutricionales.
- `MainShellScreen` llamaba el viewmodel desde `MealPlanScreen.onClientUpdated`.
- `MainShellScreen` hacia merge amplio desde el FAB de Historia Clinica usando `profile: client.profile` y `history: client.history` despues de `_saveActiveModuleIfNeeded()`.

## 3. Callers encontrados de `saveClient`

Callers reales de `HistoryClinicViewModel.saveClient` antes del patch:

- `lib/features/meal_plan_feature/screen/meal_plan_screen.dart`: llamaba `historyClinicVmProvider.saveClient(updated)` desde `handleClientUpdated`. El cambio real era nutricional: meal plan records, selected meal plan date y `dailyMealPlans`.
- `lib/features/main_shell/screen/main_shell_screen.dart`: llamaba `historyClinicVmProvider.saveClient(updated)` desde el callback `MealPlanScreen.onClientUpdated`. El cambio real tambien era nutricional.

Ninguno de esos callers justificaba guardar `profile` ni `history`.

## 4. Rutas eliminadas

- Eliminada la llamada a `historyClinicVmProvider.saveClient(updated)` en `MealPlanScreen`.
- Eliminada la llamada a `historyClinicVmProvider.saveClient(updated)` en `MainShellScreen`.
- Eliminado el metodo publico `Future<void> saveClient(Client updated)` de `HistoryClinicViewModel`.
- Eliminado el merge amplio del FAB de Historia Clinica en `MainShellScreen`.

## 5. Rutas que quedaron y por que

Quedo solo la declaracion vacia de `historyClinicVmProvider`:

```dart
class HistoryClinicViewModel {
  const HistoryClinicViewModel();
}
```

No tiene metodo de guardado, no tiene merge amplio y no tiene callers productivos normales. Se conserva el archivo/provider para no borrar archivos ni romper imports externos no mapeados.

## 6. Evidencia de que `HistoryClinicScreen` no remezcla tabs

`HistoryClinicScreen._saveTabIfNeeded()` solo delega a tabs migradas:

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

## 7. Evidencia de que `MainShellScreen` ya no hace merge amplio de Historia Clinica

Antes, el FAB de Historia Clinica remezclaba `Client` completo. Ahora solo guarda el modulo activo y muestra la misma confirmacion:

```dart
onPressed: () async {
  await _saveActiveModuleIfNeeded();
  if (!context.mounted) {
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Historia clinica guardada'),
    ),
  );
},
```

## 8. Evidencia de que `MealPlanScreen` ya no usa `HistoryClinicViewModel.saveClient`

`MealPlanScreen` delega el cambio al callback recibido:

```dart
Future<void> handleClientUpdated(Client updated) async {
  final result = widget.onClientUpdated(updated);
  if (result is Future) {
    await result;
  }
}
```

`MainShellScreen` aplica solo patch granular nutricional:

```dart
return prev.copyWith(
  nutrition: prev.nutrition.copyWith(
    extra: extra,
    dailyMealPlans:
        updated.nutrition.dailyMealPlans ??
        prev.nutrition.dailyMealPlans,
  ),
);
```

El patch solo copia:

- `NutritionExtraKeys.mealPlanRecords`
- `NutritionExtraKeys.selectedMealPlanRecordDateIso`
- `nutrition.dailyMealPlans`

Preserva `prev.profile`, `prev.history`, `prev.training` y demas secciones.

## 9. Tests creados o ajustados

- Creado `test/features/history_clinic_feature/history_clinic_wide_merge_final_closeout_test.dart`
  - Verifica que `HistoryClinicScreen` no contenga merge amplio de `updated`.
  - Verifica que `MainShellScreen` no contenga `profile: client.profile` ni `history: client.history`.
  - Verifica que `HistoryClinicViewModel` no exponga `Future<void> saveClient(Client updated)` ni merge amplio.
  - Verifica que `MealPlanScreen` no use `historyClinicVmProvider`.
  - Verifica que las tabs migradas mantengan `Future<void> saveIfDirty()` y `updateActiveClient((prev)`.

## 10. Comandos ejecutados con resultado textual

```text
rg -n "saveClient\(" lib test
Encontrados callers reales de HistoryClinicViewModel.saveClient en meal_plan_screen.dart y main_shell_screen.dart.

rg -n "HistoryClinicViewModel" lib test
Encontrado viewmodel y provider.

rg -n "historyClinicVmProvider" lib test
Antes: meal_plan_screen.dart, main_shell_screen.dart, viewmodel.
Despues: solo declaracion del provider en viewmodel.

rg -n "profile: updated\.profile|history: updated\.history|profile: client\.profile|history: client\.history" lib test
Antes: main_shell_screen.dart y history_clinic_view_model.dart.
Despues en rutas productivas en alcance: sin hits de merge amplio; solo queda declaracion vacia del provider.

rg -n "training:.*copyWith|nutrition:.*copyWith|dailyMealPlans" lib/features/main_shell lib/features/history_clinic_feature lib/features/meal_plan_feature
Confirmo que MealPlanScreen solo actualiza nutricion/dailyMealPlans.

& C:\src\flutter\bin\flutter.bat test test\features\history_clinic_feature\history_clinic_wide_merge_final_closeout_test.dart --reporter expanded
00:00 +4: All tests passed!

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

& C:\src\flutter\bin\flutter.bat analyze --no-pub
No issues found! (ran in 3.6s)
```

## 11. Comandos cancelados

```text
& C:\src\flutter\bin\flutter.bat analyze --no-pub
Estado: cancelado.
Motivo: imprimio "Analyzing hcs_app_lap..." y luego supero 90 segundos sin salida adicional.
Decision: se cerro el wrapper del proceso y se reintento una sola vez con la misma ruta directa.
Resultado del reintento: No issues found! (ran in 3.6s).
```

## 12. Archivos modificados

- `lib/features/history_clinic_feature/viewmodel/history_clinic_view_model.dart`
- `lib/features/main_shell/screen/main_shell_screen.dart`
- `lib/features/meal_plan_feature/screen/meal_plan_screen.dart`
- `test/features/history_clinic_feature/history_clinic_wide_merge_final_closeout_test.dart`
- `lib/audit/AUDIT_PROVIDER_P1A_C_HISTORY_CLINIC_WIDE_MERGE_FINAL_CLOSEOUT_REPORT.md`

Archivos ya modificados/untracked por P1A-B y validados como canary:

- `lib/features/history_clinic_feature/screen/history_clinic_screen.dart`
- `lib/features/history_clinic_feature/tabs/personal_data_tab.dart`
- `lib/features/history_clinic_feature/tabs/background_tab.dart`
- `lib/features/history_clinic_feature/tabs/general_evaluation_tab.dart`
- `lib/features/history_clinic_feature/tabs/gyneco_tab.dart`
- `lib/features/history_clinic_feature/tabs/clinical_tab_client_patches.dart`
- `test/features/history_clinic_feature/history_clinic_merge_closeout_test.dart`
- `test/features/history_clinic_feature/clinical_tabs_stale_drafts_test.dart`

## 13. Archivos no tocados

- UI visual.
- Layout.
- Labels visibles.
- Motor V3.
- Logica cientifica.
- Firebase rules.
- Dependencias.
- `pubspec.yaml`.
- Agenda/pagos.
- Entrenamiento fuera de campos ya usados por historia clinica.
- Nutricion fuera del flujo especifico de MealPlan.
- Migraciones SQLite.
- Outbox Client productivo.
- Outbox clinical productivo.

## 14. Riesgos pendientes reales

- `clientsProvider` conserva rutas generales de merge/update fuera de este scope. No son callers de `HistoryClinicViewModel` ni del FAB de Historia Clinica, pero deben tratarse como infraestructura general si se auditan todos los wide merges del app.
- `historyClinicVmProvider` queda declarado sin API de guardado para compatibilidad de simbolo. No tiene callers productivos normales ni metodo `saveClient`.

## 15. Veredicto

PROVIDER-P1A-C CERRADO.

No quedan rutas normales en `HistoryClinicScreen`, `MainShellScreen`, `MealPlanScreen` o `HistoryClinicViewModel` que hagan:

```dart
profile: updated.profile
history: updated.history
profile: updatedClient.profile
history: updatedClient.history
profile: client.profile
history: client.history
```

`MealPlanScreen` ya no llama `historyClinicVmProvider.saveClient(...)`, y `MainShellScreen` ya no remezcla un `Client` completo despues de `_saveActiveModuleIfNeeded()`.
