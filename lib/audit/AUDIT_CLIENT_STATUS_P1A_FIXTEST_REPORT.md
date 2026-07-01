# AUDIT CLIENT-STATUS-P1A-FIXTEST REPORT

## 1. Resumen ejecutivo

Se corrigio exclusivamente el test contractual:

`test/features/main_shell/providers/client_status_reactivation_contract_test.dart`

El test ahora valida el contrato real de `ClientsNotifier.updateClientStatusById` con un `ClientRepository` in-memory que sobreescribe `getClients`, `getClientById`, `saveClient` y `deleteClient`.

No se ejecuto `flutter test`.

## 2. Por que CLIENT-STATUS-P1A estaba parcial

CLIENT-STATUS-P1A quedo parcial porque el codigo productivo ya habia corregido el riesgo principal, pero el test contractual nuevo se colgo dos veces sin salida y fue cancelado.

Estado productivo confirmado:

- `InactiveClientsScreen` llama `updateClientStatusById(clientId: client.id, isActive: true)`.
- `ClientsNotifier` expone `updateClientStatusById({required String clientId, required bool isActive, bool makeActive = false})`.
- `flutter analyze --no-pub` quedo limpio.
- Canaries previos pasaron en el sprint anterior.

## 3. Causa probable del hang

El test anterior mezclaba:

- `ProviderContainer`;
- `DatabaseHelper.instance.database` en `setUpAll`;
- `DatabaseHelper.instance.setActiveClientId`;
- `ClientRepository` real;
- `ClientRepository.saveClient`, que programa remote push mediante debounce/timer aunque el remote sea noop.

Aunque se habia cambiado `remotePushDebounceDuration` a `Duration.zero`, el harness seguia dependiendo de la ruta real de `ClientRepository.saveClient`, que no es necesaria para validar el contrato del notifier y puede dejar tareas async/timers pendientes.

## 4. Que se cambio en el test

Se reemplazo el harness anterior por:

- `_InMemoryClientRepository extends ClientRepository`;
- override de `getClients`;
- override de `getClientById`;
- override de `saveClient`;
- override de `deleteClient`;
- `_NeverUsedLocalClientDataSource` solo para satisfacer el constructor base, sin ejecutarse.

El test ya no usa:

- fake local datasource con `saveClientWithOutbox`;
- ruta real de `ClientRepository.saveClient`;
- `remotePushDebounceDuration`;
- remote push;
- background sync;
- Firestore/Auth.

## 5. Codigo productivo

No se toco codigo productivo.

Archivos productivos inspeccionados:

- `lib/features/main_shell/providers/clients_provider.dart`
- `lib/features/main_shell/widgets/inactive_clients_screen.dart`

## 6. Aislamiento de timers/debounce/sync

El test no llama al `saveClient` productivo de `ClientRepository`.

`_InMemoryClientRepository.saveClient` solo actualiza un `Map<String, Client>` en memoria:

```dart
_clients[client.id] = client.copyWith(updatedAt: ...);
```

No crea:

- `Timer`;
- debounce;
- remote push;
- outbox;
- sync queue;
- background sync.

La busqueda estatica no encontro:

- `Future.delayed(const Duration(seconds:`
- `Timer(`
- `Completer(`
- `await Future.any(`
- `while (`
- `runAsync(`

## 7. Garantia de ProviderContainer dispose

Cada harness crea un `ProviderContainer` y registra:

```dart
addTearDown(container.dispose);
```

Tambien limpia el active client persistido por el contrato actual:

```dart
addTearDown(() => DatabaseHelper.instance.setActiveClientId(null));
```

Nota: el test todavia usa `DatabaseHelper` solo para el `activeClientId`, porque `ClientsNotifier.build` y `_persistActiveClientId` dependen hoy de ese singleton. No se persisten clientes reales en DB durante este test.

## 8. Casos cubiertos

El archivo conserva cinco casos:

1. A activo seleccionado, B inactivo; reactivar B con `makeActive: false`.
   - B queda `ClientStatus.active`.
   - A sigue seleccionado.
   - A conserva `profile/history/training/nutrition`.

2. A activo seleccionado, B inactivo; reactivar B con `makeActive: true`.
   - B queda `ClientStatus.active`.
   - `activeClient.id == B.id`.
   - A no se modifica.

3. Desactivar A seleccionado.
   - A queda `ClientStatus.inactive`.
   - `activeClientId == null`.
   - A conserva ramas.

4. Canary textual de `InactiveClientsScreen`.
   - Falla si vuelve `updateActiveClient((prev) => updatedClient)`.
   - Falla si vuelve `prev) => updatedClient`.

5. Canary textual de `ClientsNotifier`.
   - Confirma `updateClientStatusById`.
   - Confirma `required String clientId`.
   - Confirma `required bool isActive`.
   - Niega `Client updatedClient`.

## 9. Validacion estatica realizada

Canary contra patrones de hang:

```powershell
rg -n "Future\.delayed\(const Duration\(seconds:|Timer\(|Completer\(|await Future\.any\(|while \(|runAsync\(" test\features\main_shell\providers\client_status_reactivation_contract_test.dart
```

Salida:

```text
Sin coincidencias.
```

Canary contra snapshot completo en UI:

```powershell
rg -n "updateActiveClient\(\(prev\) => updatedClient\)|prev\) => updatedClient|return updatedClient" lib\features\main_shell\widgets\inactive_clients_screen.dart
```

Salida:

```text
Sin coincidencias.
```

Canary de contrato por id:

```powershell
rg -n "updateClientStatusById|required String clientId|required bool isActive|Client updatedClient" lib\features\main_shell\providers\clients_provider.dart test\features\main_shell\providers\client_status_reactivation_contract_test.dart
```

Salida relevante:

```text
lib\features\main_shell\providers\clients_provider.dart:151:  Future<Client?> updateClientStatusById({
lib\features\main_shell\providers\clients_provider.dart:152:    required String clientId,
lib\features\main_shell\providers\clients_provider.dart:153:    required bool isActive,
```

Canary de cleanup:

```powershell
rg -n "ProviderContainer|addTearDown\(container\.dispose\)|remotePushDebounceDuration|BackgroundSyncService|SyncService|Firestore|FirebaseAuth" test\features\main_shell\providers\client_status_reactivation_contract_test.dart
```

Salida:

```text
116:  final ProviderContainer container;
255:  final container = ProviderContainer(
258:  addTearDown(container.dispose);
```

No hay coincidencias para `remotePushDebounceDuration`, `BackgroundSyncService`, `SyncService`, `Firestore` ni `FirebaseAuth`.

## 10. Resultado de analyze

Primer intento:

```powershell
& C:\src\flutter\bin\flutter.bat analyze --no-pub
```

Estado:

```text
Imprimio "Analyzing hcs_app_lap..." y no finalizo en ~90 s.
Cancelado segun protocolo.
```

Reintento unico:

```powershell
& C:\src\flutter\bin\flutter.bat analyze --no-pub
```

Salida:

```text
Analyzing hcs_app_lap...
No issues found! (ran in 27.8s)
```

## 11. Comandos ejecutados

Lecturas:

```powershell
Get-Content test\features\main_shell\providers\client_status_reactivation_contract_test.dart | Select-Object -First 240
Get-Content test\features\main_shell\providers\client_status_reactivation_contract_test.dart | Select-Object -Last 220
Get-Content test\features\main_shell\providers\clients_provider_hardening_test.dart | Select-Object -First 240
Get-Content lib\features\main_shell\providers\clients_provider.dart | Select-Object -First 240
Get-Content lib\features\main_shell\widgets\inactive_clients_screen.dart | Select-Object -First 180
Get-Content test\data\repositories\client_repository_outbox_test.dart | Select-Object -First 140
Get-Content test\data\repositories\client_repository_sync_test.dart | Select-Object -First 230
```

Busquedas:

```powershell
rg -n "remotePushDebounceDuration|ProviderContainer|DatabaseHelper|LocalClientDataSource|ClientRepository|Fake|Mock|Completer|Timer|Future.delayed|pump|dispose|tearDown|safeClientUpdate|UpdateLock|_clientWriteLocks|saveClient|getClientById" test\features\main_shell\providers lib\features\main_shell\providers test\data\repositories
rg -n "Future\.delayed\(const Duration\(seconds:|Timer\(|Completer\(|await Future\.any\(|while \(|runAsync\(" test\features\main_shell\providers\client_status_reactivation_contract_test.dart
rg -n "updateActiveClient\(\(prev\) => updatedClient\)|prev\) => updatedClient|return updatedClient" lib\features\main_shell\widgets\inactive_clients_screen.dart
rg -n "updateClientStatusById|required String clientId|required bool isActive|Client updatedClient" lib\features\main_shell\providers\clients_provider.dart test\features\main_shell\providers\client_status_reactivation_contract_test.dart
rg -n "ProviderContainer|addTearDown\(container\.dispose\)|remotePushDebounceDuration|BackgroundSyncService|SyncService|Firestore|FirebaseAuth" test\features\main_shell\providers\client_status_reactivation_contract_test.dart
```

Analyze:

```powershell
& C:\src\flutter\bin\flutter.bat analyze --no-pub
```

El primer analyze fue cancelado por timeout operativo; el segundo paso limpio.

Empaquetado solicitado:

```powershell
Compress-Archive -Path lib -DestinationPath lib.zip -Force
Compress-Archive -Path test -DestinationPath test.zip -Force
```

Salida:

```text
Sin salida. Exit code 0.
```

## 12. Comandos prohibidos no ejecutados

No se ejecuto:

- `flutter test`
- `flutter test test/...`
- `dart test`
- `dart run`
- `flutter pub get`
- `flutter pub upgrade`
- `dart fix`
- `dart format`

## 13. Archivos modificados

- `test/features/main_shell/providers/client_status_reactivation_contract_test.dart`
- `lib/audit/AUDIT_CLIENT_STATUS_P1A_FIXTEST_REPORT.md`

## 14. Riesgos pendientes

1. Por instruccion explicita del sprint no se ejecuto `flutter test`; por tanto el cierre es estatico, no runtime.
2. El test usa `DatabaseHelper` para active id porque el contrato productivo actual lo usa internamente. Se limpia con `setActiveClientId(null)` en teardown.
3. Si en un sprint futuro se inyecta almacenamiento de active id como provider, este test podria eliminar tambien esa dependencia de DB.

## 15. Veredicto

CLIENT-STATUS-P1A-FIXTEST CERRADO
