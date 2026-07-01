# AUDIT CLIENT-STATUS-P1A REACTIVATION CONTRACT REPORT

## 1. Resumen ejecutivo

Se implemento un contrato explicito por id para cambiar el estado activo/inactivo de clientes desde `ClientsNotifier`:

- `updateClientStatusById({required String clientId, required bool isActive, bool makeActive = false})`
- `InactiveClientsScreen` ya no construye ni envia un snapshot completo `updatedClient`.
- La reactivacion desde la pantalla de inactivos no cambia la seleccion activa por defecto, porque el flujo anterior no demostraba una seleccion intencional del cliente reactivado.
- El contrato soporta `makeActive: true` para seleccionar explicitamente al cliente reactivado.
- El contrato soporta `isActive: false`; si se desactiva el cliente seleccionado, limpia `activeClientId`.

Verificacion parcial: `flutter analyze --no-pub` y los canaries existentes pasaron. El nuevo test contractual fue creado, pero su ejecucion se colgo dos veces sin salida y se cancelo segun protocolo.

## 2. Riesgo P1 original

El flujo anterior en `lib/features/main_shell/widgets/inactive_clients_screen.dart` usaba:

```dart
updateActiveClient((prev) => updatedClient)
```

Ese patron era inseguro porque:

- dependia del `activeClient`, no del cliente inactivo de la lista;
- pasaba un snapshot completo creado por UI;
- podia copiar ramas completas de un cliente B sobre el cliente activo A;
- no garantizaba que el cliente reactivado fuera el mismo que el cliente seleccionado globalmente;
- violaba el hardening incremental de `clientsProvider`.

## 3. Flujo anterior

Flujo real encontrado:

1. `InactiveClientsScreen` leia `state.clients`.
2. Filtraba inactivos con `c.status == ClientStatus.inactive`.
3. Al confirmar reactivacion, creaba `updatedClient = client.copyWith(status: ClientStatus.active)`.
4. Llamaba `updateActiveClient((prev) => updatedClient)`.
5. `updateActiveClient` rehidrataba el cliente activo persistido y creaba `mergedClient = persisted.copyWith(...)`.

Riesgo concreto: si A era `activeClient` y B era el cliente inactivo mostrado en la lista, la operacion se ejecutaba sobre A. Como `copyWith` no copiaba `id` desde B, el save podia preservar `id == A` mientras copiaba ramas de B.

## 4. Flujo nuevo

`InactiveClientsScreen` ahora llama:

```dart
await ref
    .read(clientsProvider.notifier)
    .updateClientStatusById(
      clientId: client.id,
      isActive: true,
    );
```

`ClientsNotifier.updateClientStatusById`:

1. recibe `clientId`;
2. busca el cliente fresco con `_repository.getClientById(clientId)`;
3. calcula `ClientStatus.active` o `ClientStatus.inactive`;
4. si el status cambia, persiste con `_repository.saveClient(updatedClient)`;
5. rehidrata el cliente guardado;
6. reemplaza solo el cliente con ese `id` en `state.clients`;
7. no toca `activeClientId` si el cliente activo actual es otro;
8. selecciona el cliente solo con `makeActive: true`;
9. limpia seleccion si se desactiva el cliente seleccionado.

## 5. Campo real de activo/inactivo

El campo real es:

```dart
Client.status
```

Tipo:

```dart
enum ClientStatus { active, inactive, archived }
```

No existe un campo `isActive` en `Client`.

## 6. Metodo usado

Metodo nuevo:

```dart
Future<Client?> updateClientStatusById({
  required String clientId,
  required bool isActive,
  bool makeActive = false,
})
```

No requiere `Client updatedClient` desde UI.

## 7. Seleccion al reactivar

La reactivacion desde `InactiveClientsScreen` no selecciona automaticamente al cliente reactivado.

Motivo: el flujo anterior no demostraba una seleccion explicita de B. Usaba `updateActiveClient`, que depende de la seleccion global previa. Para seleccionar B, el contrato nuevo exige `makeActive: true`.

## 8. Como evita modificar el active client equivocado

La operacion ya no toma `current.activeClient` como base. Usa `clientId` y `_repository.getClientById(clientId)`.

El reemplazo de estado es por id:

```dart
client.id == clientId ? savedClient : client
```

Si A es `activeClient` y se reactiva B con `makeActive: false`, A queda seleccionado y no se modifica.

## 9. Preservacion de ramas de Client

El cambio de status usa:

```dart
persisted.copyWith(status: nextStatus)
```

Por lo tanto se preservan las ramas existentes en el cliente persistido:

- `profile`
- `history`
- `training`
- `nutrition`
- `trainingPlans`
- `trainingWeeks`
- `trainingSessions`
- resto de ramas de `Client`

La persistencia sigue pasando por `ClientRepository.saveClient`, por lo que conserva el outbox/sync existente.

## 10. Cambios en ClientsNotifier

Archivo:

`lib/features/main_shell/providers/clients_provider.dart`

Cambios:

- agregado `updateClientStatusById`;
- uso de lock existente `UpdateLock.instance.safeClientUpdate`;
- uso de `_clientWriteLocks[clientId]`;
- lookup fresco por repository;
- save estandar por `_repository.saveClient`;
- actualizacion local por reemplazo de id;
- `activeClientId` solo cambia si `makeActive` es verdadero o si se desactiva el seleccionado.

## 11. Cambios en InactiveClientsScreen

Archivo:

`lib/features/main_shell/widgets/inactive_clients_screen.dart`

Cambios:

- eliminado `final updatedClient = client.copyWith(...)`;
- eliminado `updateActiveClient((prev) => updatedClient)`;
- reemplazado por `updateClientStatusById(clientId: client.id, isActive: true)`.

No se cambio UI visual, layout, labels visibles, navegacion ni estilos.

## 12. Tests creados/ajustados

Archivo nuevo:

`test/features/main_shell/providers/client_status_reactivation_contract_test.dart`

Cobertura incluida:

1. Reactivar B inactivo no pisa A activo.
2. Reactivar B con `makeActive: true` selecciona B sin wide merge.
3. Desactivar A seleccionado limpia seleccion y preserva ramas.
4. Canary textual: `InactiveClientsScreen` no contiene snapshot completo.
5. Canary textual: `ClientsNotifier` expone contrato por id y no requiere `Client updatedClient`.

Nota de validacion: el archivo fue creado y `flutter analyze --no-pub` lo analiza sin issues, pero `flutter test` del archivo se colgo dos veces sin salida y fue cancelado segun protocolo.

## 13. Comandos ejecutados con salida textual

### Busqueda de flujo general

```powershell
rg -n "InactiveClientsScreen|updateActiveClient|updatedClient|isActive|inactive|reactivat|desactiv|archive|restore|delete|clearActiveClient|setActiveClientById" lib test
```

Salida relevante:

```text
Warning: truncated output
lib\features\main_shell\widgets\inactive_clients_screen.dart:10:class InactiveClientsScreen extends ConsumerWidget {
lib\features\main_shell\widgets\inactive_clients_screen.dart:33:              .where((c) => c.status == ClientStatus.inactive)
lib\features\main_shell\widgets\inactive_clients_screen.dart:147:                status: ClientStatus.active,
lib\domain\entities\client.dart:34:enum ClientStatus { active, inactive, archived }
```

### Busqueda focalizada en ClientsNotifier

```powershell
rg -n "class ClientsNotifier|updateActiveClient|updateActiveClientProfile|updateActiveClientHistory|updateActiveClientNutrition|updateActiveClientTraining|setActiveClientById|clearActiveClient|createClient|refresh" lib/features/main_shell/providers/clients_provider.dart
```

Salida:

```text
51:class ClientsNotifier extends AsyncNotifier<ClientsState> {
91:  Future<void> refresh() async {
113:  Future<void> createClient(Client client) async {
136:  Future<void> setActiveClientById(String id) async {
160:  Future<void> updateActiveClient(Client Function(Client) transform) async {
241:  Future<Client?> updateActiveClientProfile(
252:  Future<Client?> updateActiveClientHistory(
263:  Future<Client?> updateActiveClientNutrition(
278:  Future<Client?> updateActiveClientTraining(
387:  Future<void> clearActiveClient() async {
```

### Busqueda repository/status

```powershell
rg -n "saveClient|updateClient|insertClient|deleteClient|archive|restore|isActive|active" lib/data lib/features/main_shell test
```

Salida relevante:

```text
lib/data/repositories/client_repository.dart:46:  Future<void> saveClient(Client client) async {
lib/data/repositories/client_repository.dart:69:  Future<void> deleteClient(String id) async {
lib/features/main_shell\widgets\inactive_clients_screen.dart:33:              .where((c) => c.status == ClientStatus.inactive)
lib/features/main_shell\widgets\inactive_clients_screen.dart:147:                status: ClientStatus.active,
lib/data/datasources/local/local_client_datasource.dart:21:  Future<void> saveClient(Client client);
lib/data/datasources/local/local_client_datasource.dart:22:  Future<ClientOutboxWrite> saveClientWithOutbox(Client client);
```

### Archivo pedido con spelling no existente

```powershell
Get-Content lib\data\datasources\local\local_client_data_source.dart | Select-Object -First 140
```

Salida:

```text
No se encuentra la ruta de acceso ...\local_client_data_source.dart porque no existe.
```

Archivo real inspeccionado:

`lib/data/datasources/local/local_client_datasource.dart`

### Impl pedido con spelling no existente

```powershell
Get-Content lib\data\datasources\local\local_client_data_source_impl.dart | Select-Object -First 220
```

Salida:

```text
No se encuentra la ruta de acceso ...\local_client_data_source_impl.dart porque no existe.
```

Archivo real inspeccionado:

`lib/data/datasources/local/local_client_datasource_impl.dart`

### Test nuevo

```powershell
& C:\src\flutter\bin\flutter.bat test test\features\main_shell\providers\client_status_reactivation_contract_test.dart --reporter expanded
```

Salida:

```text
Sin salida durante ~90 s.
Cancelado.
```

Reintento:

```powershell
& C:\src\flutter\bin\flutter.bat test test\features\main_shell\providers\client_status_reactivation_contract_test.dart --reporter expanded
```

Salida:

```text
Sin salida durante ~90 s.
Cancelado.
```

Decision: no se ejecuto un tercer intento. Se ajusto el harness del test a `remotePushDebounceDuration: Duration.zero` para evitar timers largos pendientes.

### Hardening previo

```powershell
& C:\src\flutter\bin\flutter.bat test test\features\main_shell\providers\clients_provider_hardening_test.dart --reporter expanded
```

Salida:

```text
00:00 +5: All tests passed!
```

### Client outbox

```powershell
& C:\src\flutter\bin\flutter.bat test test\data\repositories\client_repository_outbox_test.dart --reporter expanded
```

Salida:

```text
00:00 +5: All tests passed!
```

### Client sync

```powershell
& C:\src\flutter\bin\flutter.bat test test\data\repositories\client_repository_sync_test.dart --reporter expanded
```

Salida:

```text
00:00 +8: All tests passed!
```

### Clinical records outbox

```powershell
& C:\src\flutter\bin\flutter.bat test test\data\repositories\clinical_records_outbox_test.dart --reporter expanded
```

Salida:

```text
00:00 +9: All tests passed!
```

### Background clinical sync

```powershell
& C:\src\flutter\bin\flutter.bat test test\core\services\background_sync_service_clinical_records_outbox_test.dart --reporter expanded
```

Salida:

```text
00:00 +6: All tests passed!
```

### Analyze intermedio

```powershell
& C:\src\flutter\bin\flutter.bat analyze --no-pub
```

Salida:

```text
4 issues found.
```

Issues:

```text
avoid_redundant_argument_values
```

Decision: se corrigieron argumentos redundantes.

### Analyze final

```powershell
& C:\src\flutter\bin\flutter.bat analyze --no-pub
```

Salida:

```text
Analyzing hcs_app_lap...
No issues found! (ran in 3.4s)
```

### Canary textual manual post-patch

```powershell
rg -n "updateActiveClient\(\(prev\) => updatedClient\)|return updatedClient|prev\) => updatedClient" lib\features\main_shell\widgets\inactive_clients_screen.dart
```

Salida:

```text
Sin coincidencias.
```

### Firma por id post-patch

```powershell
rg -n "updateClientStatusById|required String clientId|required bool isActive|Client updatedClient" lib\features\main_shell\providers\clients_provider.dart
```

Salida:

```text
151:  Future<Client?> updateClientStatusById({
152:    required String clientId,
153:    required bool isActive,
```

### Artefactos preparados

```powershell
Compress-Archive -Path lib -DestinationPath lib.zip -Force
```

Salida:

```text
Sin salida. Exit code 0.
```

```powershell
Compress-Archive -Path test -DestinationPath test.zip -Force
```

Salida:

```text
Sin salida. Exit code 0.
```

`lib.zip` se regenero despues de la ultima actualizacion del reporte.

```powershell
Get-Item lib.zip,test.zip,pubspec.yaml,analysis_options.yaml | Select-Object Name,Length
```

Salida:

```text
lib.zip existe
test.zip existe
pubspec.yaml existe sin cambios
analysis_options.yaml existe sin cambios
```

## 14. Comandos cancelados

Cancelado 1:

```powershell
& C:\src\flutter\bin\flutter.bat test test\features\main_shell\providers\client_status_reactivation_contract_test.dart --reporter expanded
```

Estado:

```text
Sin salida durante ~90 s.
Cancelado mediante Stop-Process de procesos dart/powershell asociados al test.
```

Cancelado 2:

```powershell
& C:\src\flutter\bin\flutter.bat test test\features\main_shell\providers\client_status_reactivation_contract_test.dart --reporter expanded
```

Estado:

```text
Sin salida durante ~90 s.
Cancelado mediante Stop-Process de la powershell del reintento.
No se hizo tercer intento por protocolo.
```

## 15. Archivos modificados

- `lib/features/main_shell/providers/clients_provider.dart`
- `lib/features/main_shell/widgets/inactive_clients_screen.dart`
- `test/features/main_shell/providers/client_status_reactivation_contract_test.dart`
- `lib/audit/AUDIT_CLIENT_STATUS_P1A_REACTIVATION_CONTRACT_REPORT.md`

Artefactos preparados:

- `lib.zip`
- `test.zip`
- `pubspec.yaml` disponible sin cambios
- `analysis_options.yaml` disponible sin cambios

## 16. Archivos no tocados

No se tocaron:

- `pubspec.yaml`
- `analysis_options.yaml`
- Firebase rules
- dependencias
- Motor V3
- logica cientifica
- agenda/pagos
- auth
- App Check
- observabilidad
- outbox clinico
- SAVE-P0E
- Historia Clinica
- Nutricion
- Entrenamiento
- Macros
- Antropometria
- Bioquimica

## 17. Riesgos pendientes reales

1. El test nuevo existe y analiza limpio, pero no quedo validado por runtime porque `flutter test` se colgo dos veces sin salida.
2. No se encontro un flujo real de desactivacion que ponga `ClientStatus.inactive`; por eso no se modifico ninguna UI de desactivacion.
3. El contrato por id soporta desactivacion y limpia seleccion si se desactiva el activo, pero esa ruta no fue conectada a UI porque no habia flujo real en scope.
4. Si el equipo decide que reactivar debe seleccionar automaticamente al cliente, debe llamar `makeActive: true` de forma explicita y agregar validacion runtime del test nuevo.

## 18. Veredicto

CLIENT-STATUS-P1A PARCIAL
