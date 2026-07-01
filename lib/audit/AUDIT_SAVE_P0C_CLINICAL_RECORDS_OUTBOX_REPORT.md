# SAVE-P0C Clinical Records Outbox Report

Fecha de corte: 2026-06-03

## 1. Resumen ejecutivo

SAVE-P0C queda implementado para antropometria y bioquimica. Ambos dominios ahora escriben un evento durable en `sync_queue` despues del guardado local exitoso y antes de dejar el push remoto como fast-path en background.

El resultado:

- Antropometria encola `anthropometry_record_upsert`.
- Bioquimica encola `biochemistry_record_upsert`.
- El push remoto inmediato sigue existiendo, pero ya no es la unica garantia.
- `SyncService` rutea ambos dominios hacia `BackgroundSyncService`.
- `BackgroundSyncService` sube el record granular y cierra el item solo si el `operationId` sigue vigente.
- Remote failure conserva el item y `SyncService` incrementa retry.
- No auth conserva el item pending sin retry bump.
- Misma fecha reemplaza payload pendiente; distinta fecha crea item distinto.
- No se marca `Client` synced por un record granular.

## 2. Flujo anterior por record

### Antropometria

- Guardado local: `AnthropometryMeasuresTab._saveRecord()` arma `AnthropometryRecord`, lo mergea por fecha con `upsertRecordByDate`, y persiste dentro del JSON de `Client` via `clientsProvider.updateActiveClient()`.
- Persistencia local final: `ClientRepository.saveClient()` -> `LocalClientDataSourceImpl.saveClient()` -> `DatabaseHelper.upsertClient()` -> tabla `clients`, columna `json`.
- Push remoto granular: `ClinicalRecordsRepository.pushAnthropometryRecord()`.
- Datasource remoto: `AnthropometryFirestoreDataSource`.
- Path Firestore: `coaches/{coachId}/clients/{clientId}/anthropometry_records/{yyyy-MM-dd}`.
- Fallo anterior: se logueaba y el record quedaba local, pero no habia evento durable granular para retry.

### Bioquimica

- Guardado local: `BiochemistryTab._saveRecord()` arma `BioChemistryRecord`, lo mergea por fecha con `upsertRecordByDate`, y persiste dentro del JSON de `Client` via `clientsProvider.updateActiveClient()`.
- Persistencia local final: `ClientRepository.saveClient()` -> `LocalClientDataSourceImpl.saveClient()` -> `DatabaseHelper.upsertClient()` -> tabla `clients`, columna `json`.
- Push remoto granular: `ClinicalRecordsRepository.pushBiochemistryRecord()`.
- Datasource remoto: `RecordFirestoreDataSource`.
- Path Firestore: `coaches/{coachId}/clients/{clientId}/biochemistry_records/{yyyy-MM-dd}`.
- Fallo anterior: se logueaba y el record quedaba local, pero no habia evento durable granular para retry.

### Otros records clinicos

- Nutricion: varios records viven en `Client.nutrition.extra` usando helpers como `readNutritionRecordList`; existe soporte remoto generico `nutrition_records`, pero no se conecto en este sprint.
- Entrenamiento logs: `Client.trainingLogs` y keys en `training.extra`; existe soporte remoto generico `training_records`, pero no se conecto en este sprint.
- Progress photos: no se encontro flujo granular equivalente dentro del alcance inspeccionado.

## 3. Riesgo confirmado

Antes de SAVE-P0C, una caida de Firestore/offline despues del guardado local podia dejar antropometria o bioquimica solo en SQLite dentro del JSON de `Client`, sin operacion granular durable para reintento remoto.

## 4. Archivos inspeccionados

- `lib/data/repositories/clinical_records_repository.dart`
- `lib/data/datasources/remote/record_firestore_datasource.dart`
- `lib/data/datasources/remote/anthropometry_firestore_datasource.dart`
- `lib/features/anthropometry_feature/widgets/anthropometry_measures_tab.dart`
- `lib/features/biochemistry_feature/widgets/biochemistry_tab.dart`
- `lib/data/datasources/local/sync_queue_helper.dart`
- `lib/core/services/sync_service.dart`
- `lib/core/services/background_sync_service.dart`
- `lib/data/datasources/local/database_helper.dart`
- `lib/data/repositories/client_repository.dart`
- `lib/domain/entities/client.dart`
- `lib/domain/services/record_deletion_service.dart`
- `lib/audit/AUDIT_SAVE_P0B_CLIENT_OUTBOX_TRANSACTIONAL_REPORT.md`

## 5. Archivos modificados

- `lib/data/repositories/clinical_records_repository.dart`
- `lib/data/datasources/local/sync_queue_helper.dart`
- `lib/core/services/sync_service.dart`
- `lib/core/services/background_sync_service.dart`
- `lib/features/anthropometry_feature/widgets/anthropometry_measures_tab.dart`
- `lib/features/biochemistry_feature/widgets/biochemistry_tab.dart`
- `test/data/repositories/clinical_records_outbox_test.dart`
- `test/core/services/background_sync_service_clinical_records_outbox_test.dart`
- `lib/audit/AUDIT_SAVE_P0C_CLINICAL_RECORDS_OUTBOX_REPORT.md`

## 6. Dominios sync_queue agregados

- `anthropometry_record_upsert`
- `biochemistry_record_upsert`

`client` queda intacto para SAVE-P0B.

## 7. Payload de outbox

Payload por item:

```json
{
  "action": "upsert",
  "operationId": "uuid",
  "clientId": "client-id",
  "recordDate": "2026-06-01T00:00:00.000",
  "dateKey": "2026-06-01",
  "recordJson": {},
  "updatedAt": "iso-now",
  "domain": "anthropometry_record_upsert"
}
```

El `id` del item sigue el patron deterministico:

```text
{domain}_{clientId}_{dateKey}
```

## 8. Regla por fecha

- Misma fecha: mismo `dateKey`, mismo `id` de queue, `ConflictAlgorithm.replace`, payload mas reciente.
- Distinta fecha: distinto `dateKey`, distinto item.
- Firestore usa documento deterministico por fecha: `{collection}/{yyyy-MM-dd}`.
- Retry no crea documentos duplicados; vuelve a hacer `set(..., merge: true)` sobre el mismo doc remoto.

## 9. Flujo nuevo de antropometria

1. UI construye `AnthropometryRecord`.
2. UI persiste local en `Client.anthropometry`.
3. UI espera `ClinicalRecordsRepository.pushAnthropometryRecord()`.
4. El repositorio encola `anthropometry_record_upsert`.
5. El push remoto queda en background.
6. Si fast-path remoto termina bien, cierra el item solo si el `operationId` sigue vigente.
7. Si fast-path falla, el item queda pending para `SyncService`.

## 10. Flujo nuevo de bioquimica

1. UI construye `BioChemistryRecord`.
2. UI persiste local en `Client.biochemistry`.
3. UI espera `ClinicalRecordsRepository.pushBiochemistryRecord()`.
4. El repositorio encola `biochemistry_record_upsert`.
5. El push remoto queda en background.
6. Si fast-path remoto termina bien, cierra el item solo si el `operationId` sigue vigente.
7. Si fast-path falla, el item queda pending para `SyncService`.

## 11. Comportamiento por caso

- Remote success: `BackgroundSyncService` sube el record y `SyncQueueHelper.markSuccess()` elimina el item.
- Remote failure: devuelve `retryableFailure`; `SyncService` llama `markFailure()` y sube `retry_count`.
- No auth/no coach: devuelve `pending`; no se cierra ni aumenta retry.
- Retry: conserva `clientId + domain + dateKey`; Firestore sobrescribe el mismo documento remoto.
- Misma fecha: reemplaza payload pending con snapshot mas reciente.
- Distinta fecha: crea item distinto.

## 12. Tests creados

- `test/data/repositories/clinical_records_outbox_test.dart`
- `test/core/services/background_sync_service_clinical_records_outbox_test.dart`

Cobertura:

- Antropometria local success encola outbox.
- Bioquimica local success encola outbox.
- Remote success cierra item.
- Remote failure conserva item e incrementa retry.
- No auth conserva pending.
- Retry de mismo `dateKey` no duplica remoto.
- Mismo `dateKey` actualiza payload pending.
- Distinta fecha crea evento distinto.
- Fast-path remoto ya no es la unica garantia.

## 13. Resultado de tests

- `flutter test test/data/repositories/clinical_records_outbox_test.dart --reporter expanded`: passed, 5 tests.
- `flutter test test/core/services/background_sync_service_clinical_records_outbox_test.dart --reporter expanded`: passed, 4 tests.
- `flutter test test/data/repositories/client_repository_outbox_test.dart --reporter expanded`: passed, 4 tests.
- `flutter test test/core/services/background_sync_service_outbox_test.dart --reporter expanded`: passed, 4 tests.

Nota de entorno: la primera corrida sandbox de Flutter quedo colgada sin salida; se limpiaron procesos/lockfiles generados por esa corrida y las validaciones finales se ejecutaron correctamente.

## 14. Resultado flutter analyze

- `flutter analyze --no-pub`: `No issues found!`

## 15. Riesgos pendientes

- La escritura local del record clinico y el enqueue granular no estan en la misma transaccion SQLite porque el record vive dentro del JSON de `Client` y el flujo existente persiste desde `clientsProvider.updateActiveClient()`.
- La brecha se redujo esperando el enqueue inmediatamente despues del local success y antes del feedback final de guardado.
- Nutricion, training records y deletes granulares siguen fuera del alcance de SAVE-P0C.

## 16. Que NO se toco

- UI visual.
- Motor V3.
- Logica cientifica de entrenamiento.
- Agenda/pagos.
- Firebase rules.
- Dependencias.
- `pubspec.yaml`.
- Migraciones grandes.
- Refactor global.
- Client outbox SAVE-P0B.

## 17. Siguiente sprint recomendado

SAVE-P0D recomendado:

- Extender el mismo contrato a deletes granulares de antropometria/bioquimica.
- Auditar si nutricion y training records deben entrar a outbox granular o si deben quedarse dentro del contrato `Client`.
- Evaluar una API transaccional unica para `Client JSON + clinical outbox` si se requiere cero brecha entre local save y enqueue.
