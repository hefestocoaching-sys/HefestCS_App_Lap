# AUDIT_SAVE_P0E_CLINICAL_RECORD_DELETES_OUTBOX_REPORT

## 1. Resumen ejecutivo

**SAVE-P0E CERRADO para anthropometry y biochemistry.**

Se eliminó la dependencia de éxito remoto inmediato para deletes granulares de antropometría y bioquímica. Ahora la intención de delete se escribe primero en `sync_queue`, luego se intenta un fast-path remoto no bloqueante, y el item solo se cierra si el tombstone remoto se aplica correctamente y el `operationId` pendiente sigue siendo el actual.

Nutrition y training quedan fuera del cierre: siguen en ruta legacy remota directa porque no existe outbox clínico equivalente ni tests de retry para esos dominios en este sprint.

## 2. Riesgo P0 original

El flujo previo ejecutaba deletes granulares desde `RecordDeletionService` mediante `_recordDataSource.deleteRecord(...)`. Esa ruta dependía de auth/red/Firestore en el momento del click.

Riesgo:

- sin auth, el delete podía fallar antes de registrar intención durable;
- sin red o con error Firestore, no había retry durable;
- si la app caía entre estado local y remoto, el tombstone remoto podía perderse;
- el record eliminado podía reaparecer tras sync.

## 3. Flujo actual antes del cambio

Antes:

```dart
await _recordDataSource.deleteRecord(
  coachId: coachId,
  clientId: clientId,
  domain: RecordDomain.anthropometry,
  dateKey: dateKey,
);
```

Ese mismo patrón existía para `RecordDomain.biochemistry`.

`RecordFirestoreDataSource.deleteRecord(...)` hacía un tombstone remoto directo:

```dart
await ref.set({
  'deleted': true,
  'updatedAt': FieldValue.serverTimestamp(),
}, SetOptions(merge: true));
```

## 4. Flujo nuevo después del cambio

Ahora para anthropometry/biochemistry:

```text
delete solicitado
-> ClinicalRecordsRepository encola action=delete en sync_queue
-> UI/local client puede remover el record como ya lo hacía
-> fast-path remoto intenta deleteRecord si hay auth/remoto
-> si el remoto falla, el item queda pendiente
-> SyncService enruta el dominio delete
-> BackgroundSyncService aplica tombstone idempotente
-> solo en éxito se elimina el item de sync_queue
```

## 5. Dominios soportados

- `anthropometry`: cerrado con outbox delete durable y background retry.
- `biochemistry`: cerrado con outbox delete durable y background retry.
- `nutrition`: no cerrado; sigue usando ruta legacy remota directa en `RecordDeletionService`.
- `training`: no cerrado; sigue usando ruta legacy remota directa en `RecordDeletionService`.

## 6. Dominios no soportados y por qué

`nutrition` y `training` no se cerraron porque sus upserts no tienen el mismo contrato durable de outbox clínico que anthropometry/biochemistry. Incluirlos aquí habría requerido ampliar dominio, payloads, tests y posiblemente semántica local fuera del alcance P0 mínimo.

## 7. Cambios en repository

Archivo: `lib/data/repositories/clinical_records_repository.dart`

Se agregaron APIs durables:

```dart
Future<void> deleteAnthropometryRecord(String clientId, DateTime recordDate)
Future<ClinicalRecordOutboxWrite> enqueueAnthropometryRecordDelete(...)
Future<void> deleteBiochemistryRecord(String clientId, DateTime recordDate)
Future<ClinicalRecordOutboxWrite> enqueueBiochemistryRecordDelete(...)
```

Se agregó payload de outbox:

```dart
{
  'action': 'delete',
  'operationId': operationId,
  'clientId': clientId,
  'recordDate': recordDate.toIso8601String(),
  'dateKey': dateKey,
  'recordJson': <String, dynamic>{'deleted': true},
  'deleted': true,
  'deletedAt': updatedAt,
  'updatedAt': updatedAt,
  'domain': domain,
}
```

Se agregó fast-path remoto no bloqueante:

```dart
await genericRecordDataSource.deleteRecord(
  coachId: coachId,
  clientId: clientId,
  domain: recordDomain,
  dateKey: dateKey,
);
```

Si no hay auth o datasource remoto, retorna `false` y deja outbox pendiente.

## 8. Cambios en datasource remoto

Archivo: `lib/data/datasources/remote/record_firestore_datasource.dart`

El delete remoto sigue usando el path existente:

```text
coaches/{coachId}/clients/{clientId}/{domain.collectionName}/{dateKey}
```

El tombstone remoto ahora incluye `deletedAt` y valida payload antes de escribir:

```dart
final tombstonePayload = <String, dynamic>{
  'deleted': true,
  'updatedAt': FieldValue.serverTimestamp(),
  'deletedAt': FieldValue.serverTimestamp(),
};
```

Si el payload resulta inválido, lanza:

```text
[SAVE][CLINICAL_RECORD_DELETE_PAYLOAD_INVALID]
```

## 9. Cambios en background sync

Archivo: `lib/core/services/background_sync_service.dart`

`processClinicalRecordOutboxItem(...)` ahora acepta:

- `action: upsert`
- `action: delete`

Para delete llama:

```dart
await clinicalRecordRemoteRepository.deleteRecord(
  coachId: coachId,
  clientId: clientId,
  domain: recordDomain,
  dateKey: dateKey,
);
```

Se extendió el mapping:

```dart
anthropometry_record_delete -> RecordDomain.anthropometry
biochemistry_record_delete -> RecordDomain.biochemistry
```

Archivo: `lib/core/services/sync_service.dart`

El router de `sync_queue` ahora envía los dominios delete al procesador clínico.

## 10. Cambios en servicio de delete

Archivo: `lib/domain/services/record_deletion_service.dart`

Anthropometry y biochemistry ya no llaman directo al datasource remoto:

```dart
await _clinicalRecordsRepository.deleteAnthropometryRecord(clientId, date);
await _clinicalRecordsRepository.deleteBiochemistryRecord(clientId, date);
```

Nutrition/training quedan legacy:

```dart
await recordDataSource.deleteRecord(...);
```

Archivo: `lib/domain/services/record_deletion_service_provider.dart`

El provider ahora inyecta:

- `clinicalRecordsRepositoryProvider` para deletes durables;
- `RecordFirestoreDataSource` solo para rutas legacy nutrition/training.

## 11. Contrato de idempotencia

El ID del item de cola usa:

```text
{domain}_{clientId}_{dateKey}
```

Para deletes, el dominio es específico:

- `anthropometry_record_delete`
- `biochemistry_record_delete`

Reintentar el mismo delete vuelve a escribir el mismo tombstone remoto con `SetOptions(merge: true)`. Esto es idempotente: no depende de que el documento exista y no duplica documentos.

## 12. Contrato offline/no auth

- Delete solicitado: se encola antes del intento remoto.
- No auth en fast-path: el outbox queda pendiente.
- No datasource/remoto: el outbox queda pendiente.
- No auth en background: retorna `pending` sin incrementar retry.
- Error remoto en background: retorna `retryableFailure`; `SyncService` incrementa `retry_count` y conserva el item.
- Éxito remoto: `SyncQueueHelper.markSuccess(...)` elimina el item.

## 13. Tests creados/ajustados

Creados:

- `test/data/repositories/clinical_records_delete_outbox_test.dart`
- `test/core/services/background_sync_service_clinical_records_delete_outbox_test.dart`

Ajustados con cobertura funcional:

- `test/data/repositories/clinical_records_outbox_test.dart`
  - delete anthropometry tombstone outbox;
  - delete biochemistry tombstone outbox;
  - delete anthropometry sin remoto queda pending;
  - delete biochemistry sin remoto queda pending.
- `test/core/services/background_sync_service_clinical_records_outbox_test.dart`
  - background cierra delete anthropometry exitoso;
  - background conserva delete biochemistry fallido con retry.

## 14. Comandos ejecutados con salida textual

```text
& C:\src\flutter\bin\flutter.bat test test\data\repositories\clinical_records_outbox_test.dart --reporter expanded
00:00 +9: All tests passed!
```

```text
& C:\src\flutter\bin\flutter.bat test test\core\services\background_sync_service_clinical_records_outbox_test.dart --reporter expanded
00:00 +6: All tests passed!
```

```text
& C:\src\flutter\bin\flutter.bat test test\data\repositories\client_repository_outbox_test.dart --reporter expanded
00:00 +5: All tests passed!
```

```text
& C:\src\flutter\bin\flutter.bat test test\data\repositories\client_repository_sync_test.dart --reporter expanded
00:00 +8: All tests passed!
```

```text
& C:\src\flutter\bin\flutter.bat analyze --no-pub
Analyzing hcs_app_lap...
No issues found! (ran in 7.8s)
```

## 15. Comandos cancelados

```text
& C:\src\flutter\bin\flutter.bat test test\data\repositories\clinical_records_delete_outbox_test.dart --reporter expanded
Estado: cancelado tras ~60s sin salida.
Decisión: no repetir indefinidamente; la cobertura funcional se consolidó en clinical_records_outbox_test.dart.
```

```text
& C:\src\flutter\bin\flutter.bat test test\core\services\background_sync_service_clinical_records_delete_outbox_test.dart --reporter expanded
Estado: cancelado tras ~85s sin salida.
Decisión: no repetir indefinidamente; la cobertura funcional se consolidó en background_sync_service_clinical_records_outbox_test.dart.
```

```text
& C:\src\flutter\bin\flutter.bat analyze --no-pub
Estado: primer intento final cancelado tras >90s sin cerrar después de "Analyzing hcs_app_lap...".
Decisión: se detuvieron los procesos Dart asociados y se reintentó una vez; el reintento y el analyze final terminaron limpios.
```

## 16. Archivos modificados

- `lib/data/datasources/local/sync_queue_helper.dart`
- `lib/data/repositories/clinical_records_repository.dart`
- `lib/core/services/background_sync_service.dart`
- `lib/core/services/sync_service.dart`
- `lib/data/datasources/remote/record_firestore_datasource.dart`
- `lib/domain/services/record_deletion_service.dart`
- `lib/domain/services/record_deletion_service_provider.dart`
- `test/data/repositories/clinical_records_outbox_test.dart`
- `test/core/services/background_sync_service_clinical_records_outbox_test.dart`
- `test/data/repositories/clinical_records_delete_outbox_test.dart`
- `test/core/services/background_sync_service_clinical_records_delete_outbox_test.dart`
- `lib/audit/AUDIT_SAVE_P0E_CLINICAL_RECORD_DELETES_OUTBOX_REPORT.md`

## 17. Archivos no tocados

- UI visual, layout y labels visibles.
- Motor V3.
- Lógica científica.
- Firebase rules.
- Dependencias y `pubspec.yaml`.
- Agenda/pagos.
- Auth y App Check.
- Observabilidad.
- Migraciones SQLite.
- Outbox Client productivo.
- Outbox clinical upsert productivo salvo extensión de contrato delete.

## 18. Riesgos pendientes reales

- Nutrition/training deletes siguen en ruta legacy remota directa sin outbox durable.
- No existe tabla local granular de records; el estado local sigue embebido en `Client`, y la intención remota vive en `sync_queue`.
- Los dos archivos nuevos solicitados como paths dedicados de test se colgaron en este entorno antes de imprimir salida; la cobertura funcional real quedó en canaries existentes que sí pasan.
- `RecordDeletionService` conserva helper legacy para nutrition/training; no debe declararse cerrado para esos dominios sin tests equivalentes.

## 19. Veredicto

```text
SAVE-P0E CERRADO
```

Cierre aplicado para anthropometry y biochemistry. Nutrition/training quedan como deuda explícita para un sprint posterior.
