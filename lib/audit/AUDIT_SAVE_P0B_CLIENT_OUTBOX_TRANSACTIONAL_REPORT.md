# SAVE-P0B Client Outbox Transactional Report

Fecha de corte: 2026-06-03

## 1. Resumen ejecutivo

SAVE-P0B conectó `sync_queue` como outbox persistente transaccional para operaciones de `Client`. El objetivo fue dejar de depender solo de un `Timer` en memoria para la intención de sincronizacion y asegurar que cada guardado local importante deje una operacion durable en SQLite antes de intentar el push remoto.

El resultado final es este:

- `saveClient()` y `deleteClient()` dejan un evento durable en `sync_queue` dentro de la misma transaccion local que persiste el cliente.
- El push remoto sigue existiendo como fast-path, pero ya no es el unico mecanismo de sincronizacion.
- El scheduler de sync puede procesar la outbox de `client` sin depender de que el `Timer` dispare a tiempo.
- No se marca synced si el remoto falla, si el snapshot local ya cambio, o si el item de outbox fue reemplazado por una operacion mas nueva.
- Cerrar la app antes de que corra el `Timer` ya no pierde la intencion de sync, porque la intencion queda escrita en SQLite.

## 2. Estado inicial

Antes de este sprint:

- `ClientRepository` dependia del `Timer` de memoria para disparar el push remoto.
- La cola `sync_queue` existia, pero no estaba conectada como outbox durable para `Client`.
- Un guardado local importante no dejaba necesariamente una operacion persistente separada del objeto `Client`.
- El background sync conocia la cola, pero no tenia un contrato explicito por evento para `Client`.
- Si la app se cerraba antes del timer, la intencion de sync podia perderse.

## 3. Archivos inspeccionados

- `lib/data/repositories/client_repository.dart`
- `lib/data/datasources/local/database_helper.dart`
- `lib/data/datasources/local/local_client_datasource.dart`
- `lib/data/datasources/local/local_client_datasource_impl.dart`
- `lib/data/datasources/local/sync_queue_helper.dart`
- `lib/core/services/background_sync_service.dart`
- `lib/core/services/sync_service.dart`
- `lib/data/datasources/remote/client_firestore_datasource.dart`
- `test/data/repositories/client_repository_sync_test.dart`
- `test/data/repositories/client_repository_outbox_test.dart`
- `test/core/services/background_sync_service_outbox_test.dart`

## 4. Archivos modificados

- `lib/data/repositories/client_repository.dart`
- `lib/data/datasources/local/database_helper.dart`
- `lib/data/datasources/local/local_client_datasource.dart`
- `lib/data/datasources/local/local_client_datasource_impl.dart`
- `lib/data/datasources/local/sync_queue_helper.dart`
- `lib/core/services/background_sync_service.dart`
- `lib/core/services/sync_service.dart`
- `test/data/repositories/client_repository_sync_test.dart`
- `test/data/repositories/client_repository_outbox_test.dart`
- `test/core/services/background_sync_service_outbox_test.dart`

## 5. Contrato anterior

El flujo anterior hacia esto:

1. Guardar el cliente localmente.
2. Guardar el snapshot en memoria en `_pendingRemotePush`.
3. Lanzar un `Timer` de 700 ms.
4. Intentar el push remoto en el callback.
5. Marcar synced solo si el push remoto terminaba sin lanzar excepcion.

Problemas:

- La intencion de sync no quedaba durable si la app cerraba antes del timer.
- No habia outbox transaccional por operacion.
- Un save nuevo podia reemplazar el estado local, pero un push viejo podia seguir intentando cerrar el flujo.
- El contrato dependia demasiado de memoria y del tiempo real.

## 6. Cambios aplicados

### `DatabaseHelper`

- Se agregaron operaciones transaccionales para `Client` + outbox en una sola escritura.
- `upsertClientWithOutbox(Client)` persiste el cliente y encola el evento durable en la misma transaccion.
- `softDeleteClientWithOutbox(Client)` hace lo mismo para el tombstone.
- `softDeleteClient()` tambien alinea el JSON persistido con `updatedAt` para que el snapshot no diverja.

### `SyncQueueHelper`

- Se agrego escritura sobre un `DatabaseExecutor` con `enqueueOn(...)` para poder encolar dentro de una transaccion.
- Se agrego `getItemById(String id)` para verificar si un item sigue siendo la operacion actual.
- La cola se usa como outbox persistente, no solo como lista de pendientes.

### `LocalClientDataSource`

- Se amplio el contrato para exponer escrituras con outbox.
- `saveClientWithOutbox(Client)` y `deleteClientWithOutbox(Client)` devuelven el snapshot persistido, el id del item de cola y el `operationId`.

### `ClientRepository`

- `saveClient()` ahora guarda local + outbox durable antes de cualquier push remoto.
- `deleteClient()` hace lo mismo con el tombstone.
- El `Timer` sigue existiendo como fast-path, pero ahora su papel es secundario.
- Se agrego un debounce configurable para pruebas, sin cambiar el comportamiento por defecto de produccion.
- El cierre remoto solo marca synced si el item de outbox sigue siendo la operacion actual y el snapshot local no quedo obsoleto.

### `BackgroundSyncService`

- Se agrego `processClientOutboxItem(...)` para procesar items de outbox de `client`.
- El metodo devuelve `success`, `retryableFailure` o `pending` segun el estado real.
- No cierra la cola si el item fue reemplazado por otro save mas nuevo.
- No marca synced si el snapshot local ya no coincide con el que se subio.

### `SyncService`

- Se agrego `processPendingQueueOnce()` para pruebas y ejecuciones puntuales.
- Se ajusto el scheduler para procesar eventos de `client` desde la outbox persistente.
- Se agrego inyeccion de `BackgroundSyncService` para pruebas, evitando depender del singleton real de Firebase.

### `ClientFirestoreDataSource`

- Se conserva el contrato de SAVE-P0A: no tragar `permission-denied` y no convertir payload invalido en exito silencioso.
- Sigue usando `merge: true` y la sanitizacion existente.

## 7. Contrato nuevo

### Si el save local termina bien

- El `Client` se persiste localmente.
- El evento de outbox se escribe en `sync_queue` dentro de la misma transaccion.
- La app ya no depende solo del timer para no perder la intencion de sync.

### Si el remoto responde con exito

- Se compara el snapshot persistido con el estado local actual.
- Solo si ambos coinciden se marca `isSynced=1`.
- El item de outbox se cierra solo si sigue siendo la operacion actual.

### Si el remoto falla

- No se marca synced.
- El item de outbox queda pendiente o se reintenta segun el tipo de fallo.

### Si no hay auth

- El item queda pendiente.
- No se cierra la intencion de sync.

### Si un save nuevo reemplaza uno viejo

- La operacion vieja no puede cerrar la cola nueva.
- El sistema detecta el `operationId` vigente y evita borrar la intencion mas reciente.

### Si la app se cierra antes del timer

- La intencion ya quedo escrita en SQLite.
- Al reiniciar, la outbox sigue disponible para ser procesada.

## 8. Riesgos y limites

- El `Timer` de fast-path sigue existiendo, aunque ya no es la unica garantia de durabilidad.
- El alcance de este sprint se limito a `Client`; otros dominios siguen fuera de este contrato.
- La politica de reintento sigue siendo simple; el siguiente paso seria uniformar mas dominios sobre el mismo patron de outbox.

## 9. Tests creados o ajustados

- `test/data/repositories/client_repository_outbox_test.dart`
- `test/core/services/background_sync_service_outbox_test.dart`
- `test/data/repositories/client_repository_sync_test.dart`

Cobertura funcional validada:

- Save durable con outbox.
- Delete durable con tombstone.
- Background success que cierra cola y marca synced.
- `permission-denied` que deja la cola pendiente.
- Stale queue item que no cierra una operacion mas nueva.
- No auth que deja la cola pendiente.

## 10. Resultado de validacion

Suite ejecutada:

- `flutter test test/data/repositories/client_repository_outbox_test.dart --reporter expanded`
- `flutter test test/core/services/background_sync_service_outbox_test.dart --reporter expanded`

Resultado:

- Todas las pruebas pasaron.

Analisis ejecutado:

- `flutter analyze --no-pub`

Resultado:

- `No issues found! (ran in 3.5s)`

## 11. Que no se toco

- UI visual.
- Motor V3.
- Nutricion granular.
- Antropometria granular.
- Agenda/pagos.
- Firebase rules.
- Dependencias.
- `pubspec.yaml`.
- Migraciones grandes fuera de `sync_queue`.
- Refactor global.

## 12. Cierre

SAVE-P0B deja `Client` con una outbox durable transaccional real. El sistema ya no depende solo del timer en memoria para conservar la intencion de sincronizacion, y el cierre remoto ahora respeta el estado local vigente y la vigencia del evento de cola.
