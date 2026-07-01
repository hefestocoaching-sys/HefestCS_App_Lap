# SAVE-P0A Remote Sync Truth Contract Report

Fecha de corte: 2026-06-02

## 1. Resumen ejecutivo

SAVE-P0A cerró el riesgo inmediato de falso sincronizado remoto en `ClientRepository` y en el sync en background. El contrato nuevo ya no marca `isSynced=1` si Firestore no confirmó realmente la escritura, si el usuario no está autenticado, si Firebase no puede resolver el coach actual, o si el snapshot remoto quedó obsoleto frente al estado local actual.

También se corrigió el datasource remoto de clientes para que `permission-denied` y el payload inválido no se conviertan en éxito silencioso. La outbox persistente por dominios no se implementó todavía; eso queda para SAVE-P0B.

## 2. Estado inicial

Antes de este sprint:

- `ClientRepository.saveClient()` guardaba local primero y programaba un push remoto diferido con `Timer`.
- `ClientFirestoreDataSource.upsertClient()` podía tragar errores de permiso y regresar sin fallar.
- `ClientRepository._pushClientRemote()` marcaba `isSynced=1` apenas terminaba el push remoto, sin verificar si el cliente local había cambiado después.
- `BackgroundSyncService` marcaba synced después de `upsertClient()` sin un contrato explícito de verdad remota.
- No existía una verificación de snapshot obsoleto entre la subida y el estado local actual.

## 3. Archivos inspeccionados

- `lib/data/repositories/client_repository.dart`
- `lib/data/datasources/remote/client_firestore_datasource.dart`
- `lib/core/services/background_sync_service.dart`
- `lib/data/datasources/local/database_helper.dart`
- `lib/data/datasources/local/local_client_datasource.dart`
- `lib/data/datasources/local/local_client_datasource_impl.dart`
- `test/data/repositories/client_repository_sync_test.dart`

## 4. Archivos modificados

- `lib/data/repositories/client_repository.dart`
- `lib/data/datasources/remote/client_firestore_datasource.dart`
- `lib/core/services/background_sync_service.dart`
- `lib/data/datasources/local/database_helper.dart`
- `lib/data/datasources/local/local_client_datasource.dart`
- `lib/data/datasources/local/local_client_datasource_impl.dart`
- `test/data/repositories/client_repository_sync_test.dart`

## 5. Contrato anterior de `saveClient`

`saveClient()` hacía esto:

1. Guardaba local primero.
2. Guardaba el cliente en `_pendingRemotePush`.
3. Programaba un `Timer` de 700 ms.
4. En el timer llamaba `_pushClientRemote()`.
5. `_pushClientRemote()` obtenía el usuario actual desde `FirebaseAuth.instance.currentUser`.
6. Si Firestore escribía sin lanzar excepción, llamaba `markClientAsSynced(client.id)`.

Problemas:

- `permission-denied` podía terminar convertido en retorno silencioso desde el datasource remoto.
- No existía comparación contra el estado local actual antes de marcar synced.
- Un push viejo podía terminar después de un save nuevo y dejar `isSynced=1` aunque el local ya tenía una versión posterior.
- Si no había usuario o Firebase no estaba disponible, el sistema no marcaba synced, pero el contrato no quedaba explícito ni trazado.

## 6. Bugs confirmados

- `permission-denied` tragado: confirmado y corregido.
- Falso success remoto: confirmado y corregido.
- `markSynced` sin versión/snapshot: confirmado y corregido con comparación de snapshot local actual.
- Push viejo vs save nuevo: confirmado y corregido con verificación de `updatedAt` contra el cliente local persistido.

## 7. Cambios aplicados

### `ClientFirestoreDataSource.upsertClient()`

- Sigue usando `SetOptions(merge: true)`.
- Sigue sanitizando el payload.
- Sigue respetando la whitelist de `training.extra`.
- Ahora lanza error si detecta payload inválido.
- Ahora lanza `FirebaseException` o relanza el error equivalente si ocurre `permission-denied`.
- Ya no retorna éxito silencioso en `permission-denied`.

### `ClientRepository`

- Ahora resuelve el coach actual mediante un proveedor inyectable y seguro.
- `saveClient()` guarda local y luego captura el snapshot persistido para usarlo en el push remoto.
- `deleteClient()` hace lo mismo con el snapshot local incluyendo borrados.
- `_pushClientRemote()` solo marca synced después de una subida remota exitosa y de verificar que el cliente local actual sigue coincidiendo con el snapshot subido.
- Si el snapshot local actual cambió, no marca synced y emite log de stale push.
- `permission-denied` mantiene el backoff de sesión, pero no se considera éxito.

### `BackgroundSyncService`

- Usa el mismo contrato de verdad remota.
- No marca synced si la subida remota falla.
- No marca synced si el snapshot local actual ya cambió.
- No depende de que FirebaseAuth esté inicializado para poder construirse en tests.

### Persistencia local

- Se añadió acceso a cliente incluyendo borrados para poder comparar el snapshot persistido real antes de marcar synced.
- No se cambió el esquema ni hubo migración grande.

## 8. Contrato nuevo

### Si remote success

- `upsertClient()` completa sin error.
- `ClientRepository` y `BackgroundSyncService` comparan el snapshot subido con el cliente local actual.
- Solo si ambos coinciden, se llama `markClientAsSynced()`.

### Si remote permission-denied

- `upsertClient()` falla explícitamente.
- No se considera éxito.
- No se llama `markClientAsSynced()`.
- El cliente queda pendiente local.
- El backoff de sesión puede permanecer activo, pero no equivale a synced.

### Si no auth user

- No se intenta sincronizar remotamente.
- No se marca synced.
- El cliente permanece pendiente local.

### Si Firebase no está inicializado

- La resolución del coach se trata como no disponible.
- No se marca synced.
- El cliente permanece pendiente local.

### Si payload inválido

- `upsertClient()` lanza `StateError('[SAVE][REMOTE_PAYLOAD_INVALID] ...')`.
- No se considera éxito.
- No se marca synced.

### Si un push viejo termina después de un save nuevo

- La comparación de `updatedAt` detecta que el snapshot subido ya quedó obsoleto.
- No se llama `markClientAsSynced()`.
- Se loguea `[SAVE][REMOTE_PUSH_STALE] uploaded snapshot older than local current`.

## 9. Tests creados

Archivo: `test/data/repositories/client_repository_sync_test.dart`

Casos cubiertos:

- save local success + remote success.
- remote `permission-denied`.
- remote payload inválido.
- no auth user.
- stale push que termina después de un save nuevo.
- background sync success.
- background sync `permission-denied`.
- background sync sin auth.

## 10. Resultado de tests

Suite ejecutada:

- `flutter test test/data/repositories/client_repository_sync_test.dart --reporter expanded`

Resultado:

- Todos los tests pasaron.

## 11. Resultado `flutter analyze`

Comando ejecutado:

- `flutter analyze --no-pub`

Resultado:

- `No issues found! (ran in 44.7s)`

## 12. Riesgos pendientes

- La cola `sync_queue` sigue sin ser una outbox real conectada a los saves de dominio.
- Citas y transacciones siguen siendo online-first.
- El contrato de comparación usa `updatedAt`; mientras no exista una revisión local explícita, sigue siendo una defensa mínima, no una outbox transaccional.
- El `Timer` de debounce sigue existiendo; si la app se cierra antes de disparar, el push pendiente puede perderse hasta el próximo arranque o reintento.

## 13. Qué NO se tocó

- UI visual.
- Motor V3.
- Lógica científica de entrenamiento.
- Modelos de entrenamiento.
- Nutrición.
- Antropometría.
- Agenda/pagos.
- Firebase rules.
- Dependencias.
- `pubspec.yaml`.
- Migraciones grandes.
- Refactor global.
- Outbox completa por dominios.

## 14. Siguiente sprint recomendado

SAVE-P0B: implementar una outbox persistente transaccional para `Client`, con reintento observable, reconciliación por evento y separación explícita entre:

- guardado local,
- encolado de sync,
- confirmación remota,
- estado visible al usuario.
