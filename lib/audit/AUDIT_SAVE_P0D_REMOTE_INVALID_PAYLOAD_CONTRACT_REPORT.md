# AUDIT_SAVE_P0D_REMOTE_INVALID_PAYLOAD_CONTRACT_REPORT

## 1. Resumen ejecutivo

SAVE-P0D cerrado.

`ClientFirestoreDataSource.upsertClient()` ya no puede completar normalmente cuando el payload remoto validado para Firestore es invalido. El bloqueo ocurre antes de `set(..., merge: true)`, registra `clientId` e `invalidPath`, y lanza `StateError` con el marker `[SAVE][REMOTE_PAYLOAD_INVALID]`.

## 2. P0 inicial

Archivo:

- `lib/data/datasources/remote/client_firestore_datasource.dart`

Codigo anterior documentado en `lib/audit/AUDIT_FULL_REPO_VSCODE_CODE_QUALITY_REPORT.md`:

```dart
final invalidPath = findInvalidFirestorePath(fullPayload);
if (invalidPath != null) {
  logger.warning(
    'Skipping remote client sync due to invalid Firestore payload',
    {'clientId': client.id, 'invalidPath': invalidPath},
  );
  return;
}
```

Era P0 porque `return` convertia una no-escritura remota en completion normal. Los callers (`ClientRepository` y `BackgroundSyncService`) interpretan completion normal como exito remoto, por lo que podian marcar el cliente como synced o cerrar `sync_queue` sin que Firestore hubiera recibido `set()`.

## 3. Archivos inspeccionados

- `lib/audit/AUDIT_FULL_REPO_VSCODE_CODE_QUALITY_REPORT.md`
- `lib/data/datasources/remote/client_firestore_datasource.dart`
- `lib/data/repositories/client_repository.dart`
- `lib/core/services/background_sync_service.dart`
- `lib/core/services/sync_service.dart`
- `lib/data/datasources/local/sync_queue_helper.dart`
- `lib/utils/firestore_sanitizer.dart`
- `lib/domain/entities/training_profile.dart`
- `test/data/repositories/client_repository_sync_test.dart`
- `test/data/repositories/client_repository_outbox_test.dart`
- `test/core/services/background_sync_service_outbox_test.dart`

## 4. Archivos modificados

- `lib/data/datasources/remote/client_firestore_datasource.dart`
- `test/data/datasources/remote/client_firestore_datasource_payload_contract_test.dart`
- `test/data/repositories/client_repository_sync_test.dart`
- `test/data/repositories/client_repository_outbox_test.dart`
- `test/core/services/background_sync_service_outbox_test.dart`
- `lib/audit/AUDIT_SAVE_P0D_REMOTE_INVALID_PAYLOAD_CONTRACT_REPORT.md`

## 5. Cambio aplicado

Antes:

```dart
final invalidPath = findInvalidFirestorePath(fullPayload);
if (invalidPath != null) {
  logger.warning(
    'Skipping remote client sync due to invalid Firestore payload',
    {'clientId': client.id, 'invalidPath': invalidPath},
  );
  return;
}
```

Despues:

```dart
void validateRemoteClientPayloadOrThrow({
  required String clientId,
  required Map<String, dynamic> fullPayload,
}) {
  final invalidPath = findInvalidFirestorePath(fullPayload);
  if (invalidPath != null) {
    final invalidPaths = listInvalidFirestorePaths(fullPayload, limit: 12);
    final auditFindings = listFirestoreAuditFindings(fullPayload, limit: 12);
    logger.warning(
      'Remote client sync blocked due to invalid Firestore payload',
      {
        'clientId': clientId,
        'invalidPath': invalidPath,
        'invalidPaths': invalidPaths,
        'auditFindings': auditFindings,
      },
    );
    throw StateError(
      '[SAVE][REMOTE_PAYLOAD_INVALID] '
      'clientId=$clientId invalidPath=$invalidPath',
    );
  }
}
```

Uso en `upsertClient()`:

```dart
validateRemoteClientPayloadOrThrow(
  clientId: client.id,
  fullPayload: fullPayload,
);

await ref.set(fullPayload, SetOptions(merge: true));
```

## 6. Contrato nuevo

- Remote success: `ref.set(fullPayload, SetOptions(merge: true))` completa; solo entonces los callers pueden marcar synced o queue success.
- Permission-denied: se loguea contexto y se relanza como error; no es exito silencioso.
- Payload invalido: se loguea `clientId`, `invalidPath`, `invalidPaths` y `auditFindings`; se lanza `StateError('[SAVE][REMOTE_PAYLOAD_INVALID] ...')`; no se ejecuta `set()`.
- No auth: fast-path deja pending sin push remoto; background retorna `pending`.
- Background sync con payload invalido: `processClientOutboxItem()` registra warning y retorna `retryableFailure`; no llama `markClientAsSynced` ni `markSuccess`.
- Fast-path con payload invalido: `_pushClientRemote()` captura y loguea failure; no llama `_markClientAsSyncedIfCurrent()` ni `_markQueueItemSuccessIfCurrent()`.

## 7. Tests creados/ajustados

- Creado `test/data/datasources/remote/client_firestore_datasource_payload_contract_test.dart`
  - `throws on invalid Firestore payload`
  - `accepts valid Firestore payload`
- Ajustado `test/data/repositories/client_repository_sync_test.dart`
  - `payload invalid does not mark synced`
- Ajustado `test/data/repositories/client_repository_outbox_test.dart`
  - `remote invalid payload keeps queue pending via retry path`
- Ajustado `test/core/services/background_sync_service_outbox_test.dart`
  - `invalid remote payload does not close queue as success`

## 8. Resultado de tests

Nota de entorno: dentro del sandbox, `flutter test` no podia abrir el lockfile/cache del SDK Flutter. Se re-ejecutaron las suites con permisos elevados solo para permitir acceso al SDK cache.

```text
& C:\src\flutter\bin\flutter.bat test test\data\datasources\remote\client_firestore_datasource_payload_contract_test.dart --reporter expanded
00:00 +2: All tests passed!

& C:\src\flutter\bin\flutter.bat test test\data\repositories\client_repository_sync_test.dart --reporter expanded
00:00 +8: All tests passed!

& C:\src\flutter\bin\flutter.bat test test\data\repositories\client_repository_outbox_test.dart --reporter expanded
00:00 +5: All tests passed!

& C:\src\flutter\bin\flutter.bat test test\core\services\background_sync_service_outbox_test.dart --reporter expanded
00:00 +5: All tests passed!

& C:\src\flutter\bin\flutter.bat test test\data\repositories\clinical_records_outbox_test.dart --reporter expanded
00:00 +5: All tests passed!
```

## 9. Resultado flutter analyze

```text
& C:\src\flutter\bin\flutter.bat analyze --no-pub
Analyzing hcs_app_lap...
No issues found! (ran in 120.5s)
```

## 10. Riesgos pendientes

- `upsertClientMeta()` conserva su contrato previo para payload meta invalido; no fue parte de SAVE-P0D.
- `SyncService.markFailure()` guarda `error_message` generico (`sync failed`) para failures retryables; el contexto completo queda en logs de `BackgroundSyncService`.
- El worktree ya contenia cambios previos de contrato Firestore contra HEAD; este sprint solo cerro el contrato de payload remoto invalido.

## 11. Que NO se toco

- UI visual.
- Layout.
- Labels/textos visibles.
- Motor V3.
- Firebase rules.
- Dependencias.
- `pubspec.yaml`.
- Agenda/pagos.
- Nutricion.
- Entrenamiento.
- Migraciones SQLite.
- Outbox Client productivo salvo la verificacion del contrato de error.
- Outbox clinical productivo.
- Providers clinicos PROVIDER-P1A salvo canary indirecto.

## 12. Siguiente sprint recomendado

Opcion A: PROVIDER-P1A-B.

Justificacion: SAVE-P0D queda cerrado. El siguiente riesgo mas alineado con los reportes locales es el merge amplio residual y los stale drafts clinicos pendientes de hardening; priorizarlo reduce overwrite silencioso entre tabs sin ampliar sync/outbox ni tocar deletes granulares.
