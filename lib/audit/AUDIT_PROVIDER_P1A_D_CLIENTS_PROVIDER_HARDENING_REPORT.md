# AUDIT_PROVIDER_P1A_D_CLIENTS_PROVIDER_HARDENING_REPORT

## 1. Resumen ejecutivo

PROVIDER-P1A-D CERRADO.

El cierre es incremental, no una eliminacion total de todos los wide merges del sistema. Se agrego contrato fuerte a `ClientsNotifier.updateActiveClient`, se agregaron helpers granulares testeados para `profile`, `history`, `nutrition` y `training`, y se migro el patch nutricional de `MainShellScreen` usado por `MealPlanScreen` a `updateActiveClientNutrition`.

Quedan riesgos sistemicos mapeados fuera del alcance de este sprint, especialmente callers legacy que todavia usan `updateActiveClient` con snapshots amplios o secciones completas.

## 2. Riesgo sistemico despues de P1A-C

PROVIDER-P1A-C cerro el flujo especifico de Historia Clinica, MealPlan y MainShell FAB, pero `clientsProvider` seguia exponiendo una API general:

```dart
Future<void> updateActiveClient(Client Function(Client) transform)
```

Esa API puede ser usada correctamente si el caller transforma el `prev` fresco. Tambien puede ser usada incorrectamente si el caller devuelve un `Client` capturado antes por UI o copia secciones completas desde un snapshot viejo.

## 3. Mapa real de APIs publicas de ClientsNotifier

APIs publicas encontradas en `lib/features/main_shell/providers/clients_provider.dart`:

- `refresh()`
- `createClient(Client client)`
- `setActiveClientById(String id)`
- `updateActiveClient(Client Function(Client) transform)`
- `updateActiveClientProfile(ClientProfile Function(ClientProfile previous) transform)`
- `updateActiveClientHistory(ClinicalHistory Function(ClinicalHistory previous) transform)`
- `updateActiveClientNutrition(NutritionSettings Function(NutritionSettings previous) transform, {String? expectedClientId})`
- `updateActiveClientTraining(TrainingProfile Function(TrainingProfile previous) transform)`
- `clearActiveClient()`

No existe `replaceActiveClient`.

## 4. Mapa real de callers de updateActiveClient

Callers directos encontrados por `rg -n "updateActiveClient|replaceActiveClient|setActiveClientById|clearActiveClient" lib test`:

- `lib/features/history_clinic_feature/tabs/personal_data_tab.dart`
- `lib/features/history_clinic_feature/tabs/background_tab.dart`
- `lib/features/history_clinic_feature/tabs/general_evaluation_tab.dart`
- `lib/features/history_clinic_feature/tabs/gyneco_tab.dart`
- `lib/features/main_shell/screen/main_shell_screen.dart`
- `lib/features/main_shell/widgets/inactive_clients_screen.dart`
- `lib/features/anthropometry_feature/widgets/anthropometry_measures_tab.dart`
- `lib/features/anthropometry_feature/widgets/anthropometry_interpretation_tab.dart`
- `lib/features/biochemistry_feature/widgets/biochemistry_tab.dart`
- `lib/features/macros_feature/viewmodel/macros_view_model.dart`
- `lib/features/macros_feature/widgets/macros_content.dart`
- `lib/features/nutrition_feature/widgets/dietary_tab.dart`
- `lib/features/nutrition_feature/widgets/depletion_tab.dart`
- `lib/features/nutrition_feature/screens/equivalents_screen.dart`
- `lib/features/nutrition_feature/screens/equivalents_by_day_screen.dart`
- `lib/data/repositories/nutrition_plan_repository.dart`
- `lib/features/training_feature/tabs/training_interview_tab.dart`
- `lib/features/training_feature/screens/training_workspace_screen.dart`
- `lib/features/training_feature/screens/gym_exercises_stage_screen.dart`
- `lib/features/training_feature/providers/training_plan_provider.dart`
- tests existentes de concurrencia y canaries P1A.

## 5. Mapa real de callers de reemplazo completo

No existe API `replaceActiveClient`.

Callers de seleccion encontrados:

- `setActiveClientById` en dashboard, client selector, main shell y pending sections.
- `clearActiveClient` en arranque de `MainShellScreen`.

Estos no guardan snapshots parciales; solo cambian la seleccion activa.

## 6. Callers seguros encontrados

Seguros dentro del alcance P1A:

- Las cuatro tabs clinicas migradas guardan con `saveIfDirty()` y `updateActiveClient((prev) { ... })`.
- Los patch helpers clinicos preservan secciones no relacionadas.
- `HistoryClinicScreen` solo delega `saveIfDirty()` a la tab activa.
- `MealPlanScreen` ya no usa `historyClinicVmProvider`; emite `onClientUpdated`.
- `MainShellScreen` recibe el `Client` emitido por MealPlan solo para extraer cambios nutricionales especificos.

## 7. Callers inseguros corregidos

Se corrigio el caller de bajo costo y alto impacto en `MainShellScreen`:

Antes, el patch nutricional usaba `updateActiveClient((prev) => prev.copyWith(nutrition: ...))`.

Despues usa el helper granular:

```dart
await ref
    .read(clientsProvider.notifier)
    .updateActiveClientNutrition((previous) {
  final extra = Map<String, dynamic>.from(previous.extra);
  final updatedExtra = updated.nutrition.extra;
  if (updatedExtra.containsKey(NutritionExtraKeys.mealPlanRecords)) {
    extra[NutritionExtraKeys.mealPlanRecords] =
        updatedExtra[NutritionExtraKeys.mealPlanRecords];
  }
  if (updatedExtra.containsKey(
    NutritionExtraKeys.selectedMealPlanRecordDateIso,
  )) {
    extra[NutritionExtraKeys.selectedMealPlanRecordDateIso] =
        updatedExtra[NutritionExtraKeys.selectedMealPlanRecordDateIso];
  }

  return previous.copyWith(
    extra: extra,
    dailyMealPlans:
        updated.nutrition.dailyMealPlans ?? previous.dailyMealPlans,
  );
}, expectedClientId: updated.id);
```

## 8. Callers inseguros pendientes y por que quedaron fuera de scope

Pendientes reales:

- `lib/features/main_shell/widgets/inactive_clients_screen.dart`: usa `updateActiveClient((prev) => updatedClient)`. Es un snapshot completo de un cliente inactivo seleccionado, no un patch claro sobre el cliente activo. Corregirlo requiere revisar el flujo funcional de reactivacion de clientes, no solo cambiar el helper.
- `lib/features/training_feature/tabs/training_interview_tab.dart`: copia `updatedClient.training`. Esta fuera de alcance porque el sprint prohibe tocar entrenamiento fuera de campos ya usados por historia clinica.
- `lib/features/training_feature/*` y `lib/features/nutrition_feature/*`: varios callers siguen usando `updateActiveClient` para patches de `training.extra` o `nutrition.extra`. La mayoria transforma `current` o `prev`, pero no se migraron para evitar refactor masivo.
- `lib/data/repositories/nutrition_plan_repository.dart`: conserva rutas nutricionales especificas con `updateActiveClient`; queda fuera del alcance de este hardening incremental.
- `ClientsNotifier._updateActiveClientLegacy`: conserva wide merge interno detras de `FeatureFlags.useLegacyClientUpdate`.

## 9. Helpers granulares agregados

En `ClientsNotifier`:

```dart
Future<Client?> updateActiveClientProfile(
  ClientProfile Function(ClientProfile previous) transform,
)

Future<Client?> updateActiveClientHistory(
  ClinicalHistory Function(ClinicalHistory previous) transform,
)

Future<Client?> updateActiveClientNutrition(
  NutritionSettings Function(NutritionSettings previous) transform, {
  String? expectedClientId,
})

Future<Client?> updateActiveClientTraining(
  TrainingProfile Function(TrainingProfile previous) transform,
)
```

Cada helper llama internamente a `updateActiveClient((prev) { ... })` y modifica solo su seccion.

## 10. Callers migrados a helpers granulares

- `lib/features/main_shell/screen/main_shell_screen.dart`
  - `_applyMealPlanNutritionPatch(Client updated)` migro a `updateActiveClientNutrition`.
  - El helper usa `expectedClientId: updated.id` para evitar aplicar el patch si el cliente activo cambio antes de persistir.

Las tabs clinicas no se migraron porque ya usan patch helpers especificos contra `prev` y migrarlas en este sprint no reducia riesgo proporcional.

## 11. Evidencia de que Historia Clinica no reintrodujo wide merge

`lib/features/history_clinic_feature/viewmodel/history_clinic_view_model.dart`:

```dart
class HistoryClinicViewModel {
  const HistoryClinicViewModel();
}
```

No existe `saveClient(Client updated)`.

Las tabs clinicas mantienen:

```dart
Future<void> saveIfDirty()
```

El canary `history_clinic_wide_merge_final_closeout_test.dart` paso.

## 12. Evidencia de que MealPlan no usa viewmodel clinico

Busqueda:

```text
rg -n "onClientUpdated|historyClinicVmProvider|updateActiveClient|saveIfDirty" lib\features\meal_plan_feature\screen\meal_plan_screen.dart
```

Resultado relevante:

```text
18:  final Function(Client) onClientUpdated;
23:    required this.onClientUpdated,
36:  Future<void> saveIfDirty() async {
294:  Future<void> saveIfDirty() async {
```

No aparece `historyClinicVmProvider`.

## 13. Evidencia de que MainShell no remezcla profile/history desde snapshot

Busqueda final:

```text
rg -n "profile: client\.profile|history: client\.history" lib/features/main_shell/screen/main_shell_screen.dart
```

No hubo coincidencias.

El unico patch derivado de MealPlan en `MainShellScreen` ahora pasa por `updateActiveClientNutrition`.

## 14. Tests creados o ajustados

Creado:

- `test/features/main_shell/providers/clients_provider_hardening_test.dart`

Casos cubiertos:

- Helpers granulares preservan secciones no relacionadas.
- `HistoryClinicViewModel` no reintroduce `saveClient(Client updated)`.
- `MainShellScreen` no contiene `profile: client.profile` ni `history: client.history`.
- `MealPlanScreen` no usa `historyClinicVmProvider`.
- Tabs clinicas mantienen `Future<void> saveIfDirty()` y no `Future<Client?> saveIfDirty()`.

## 15. Comandos ejecutados con salida textual

```text
& C:\src\flutter\bin\flutter.bat test test\features\main_shell\providers\clients_provider_hardening_test.dart --reporter expanded
00:00 +5: All tests passed!
```

```text
& C:\src\flutter\bin\flutter.bat test test\features\history_clinic_feature\history_clinic_wide_merge_final_closeout_test.dart --reporter expanded
00:00 +4: All tests passed!
```

```text
& C:\src\flutter\bin\flutter.bat test test\features\history_clinic_feature\history_clinic_merge_closeout_test.dart --reporter expanded
00:00 +3: All tests passed!
```

```text
& C:\src\flutter\bin\flutter.bat test test\features\history_clinic_feature\clinical_tabs_stale_drafts_test.dart --reporter expanded
00:00 +8: All tests passed!
```

```text
& C:\src\flutter\bin\flutter.bat test test\data\repositories\client_repository_outbox_test.dart --reporter expanded
00:02 +5: All tests passed!
```

```text
& C:\src\flutter\bin\flutter.bat test test\data\repositories\clinical_records_outbox_test.dart --reporter expanded
00:01 +5: All tests passed!
```

```text
& C:\src\flutter\bin\flutter.bat test test\data\repositories\client_repository_sync_test.dart --reporter expanded
00:00 +8: All tests passed!
```

```text
& C:\src\flutter\bin\flutter.bat analyze --no-pub
Analyzing hcs_app_lap...
No issues found! (ran in 133.4s)
```

## 16. Comandos cancelados, si aplica

Si aplica:

- Un primer `flutter analyze --no-pub` imprimio `Analyzing hcs_app_lap...` y luego quedo sin salida nueva por 90 segundos. Se detuvieron procesos Dart/DartVM asociados antes del reintento.
- El reintento tambien quedo sin salida nueva durante 90 segundos despues del mensaje inicial; se limpiaron procesos residuales, y la sesion finalmente cerro con exit 0 y `No issues found! (ran in 133.4s)`.
- Un proceso `dart.exe` residual del test de sync anterior a esta continuacion fue detenido antes de repetir `client_repository_sync_test.dart`; el reintento paso.

## 17. Archivos modificados

Modificados para PROVIDER-P1A-D:

- `lib/features/main_shell/providers/clients_provider.dart`
- `lib/features/main_shell/screen/main_shell_screen.dart`
- `test/features/main_shell/providers/clients_provider_hardening_test.dart`
- `lib/audit/AUDIT_PROVIDER_P1A_D_CLIENTS_PROVIDER_HARDENING_REPORT.md`

## 18. Archivos no tocados

No se tocaron:

- UI visual.
- Layout.
- Labels visibles.
- Motor V3.
- Logica cientifica.
- Firebase rules.
- Dependencias.
- `pubspec.yaml`.
- Agenda/pagos.
- Migraciones SQLite.
- Outbox Client productivo.
- Outbox clinical productivo.
- Modelos grandes.

## 19. Riesgos pendientes reales

- `updateActiveClient` sigue siendo publico y todavia acepta cualquier `Client Function(Client)`. El contrato y los helpers reducen riesgo, pero no lo eliminan por compilador.
- El provider conserva wide merge interno para compatibilidad y para el path legacy.
- Hay callers fuera del scope que todavia usan secciones completas o snapshots amplios, especialmente `InactiveClientsScreen` y entrenamiento.
- Migrar todo nutricion/entrenamiento a helpers granulares debe hacerse por sprint separado para no mezclar hardening con refactor masivo.

## 20. Veredicto

PROVIDER-P1A-D CERRADO.

El alcance incremental quedo cerrado: contrato documentado, helpers granulares agregados, caller nutricional de MainShell migrado, canaries P1A/P0 ejecutados, y `analyze --no-pub` limpio. No se declara eliminacion total del riesgo sistemico; la deuda restante quedo mapeada para un siguiente sprint.
