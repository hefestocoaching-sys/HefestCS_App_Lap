# AUDIT_FULL_REPO_VSCODE_CODE_QUALITY_REPORT

## 1. Resumen ejecutivo

Estado general: el repositorio compila a nivel estatico con `flutter analyze --no-pub` sin issues, pero la auditoria de codigo real encontro riesgos de guardado y arquitectura que el analyzer no puede ver.

Riesgos P0:

| ID | Riesgo | Estado |
| -- | ------ | ------ |
| P0-01 | `ClientFirestoreDataSource.upsertClient` retorna normalmente cuando detecta payload Firestore invalido; el caller puede marcar local y queue como sincronizados aunque no hubo `set()`. | Confirmado |

Riesgos P1:

| ID | Riesgo | Estado |
| -- | ------ | ------ |
| P1-01 | Deletes granulares de antropometria/bioquimica usan tombstone remoto directo sin outbox durable. | Confirmado |
| P1-02 | Agenda y pagos/transacciones son online-first con rutas Firestore directas y sin tabla/outbox local. | Confirmado |
| P1-03 | `HistoryClinicScreen`/ViewModel conserva rutas de merge amplio de `Client` que pueden reintroducir snapshots viejos fuera del flujo patch-helper. | Parcial |
| P1-04 | `clientPreferencesEffectProvider` devuelve preferencias vacias y no lee preferencias reales del cliente. | Confirmado |

Riesgos P2:

| ID | Riesgo | Estado |
| -- | ------ | ------ |
| P2-01 | Widgets/proveedores muy grandes, con calculos y filtros en `build`, elevan costo de mantenimiento y rebuild. | Confirmado |
| P2-02 | Controllers creados sin `dispose()` en pantallas/modales puntuales. | Confirmado |
| P2-03 | Dependencias declaradas sin uso local observado (`provider`, `firebase_storage`, `firebase_analytics`, `shared_preferences`, `http`, `google_fonts`, `mockito`). | Confirmado |

Siguiente sprint recomendado: `SAVE-P0D`, porque hay un P0 real en el contrato de exito remoto: payload invalido puede cerrar sincronizacion sin escritura remota.

## 2. Comandos ejecutados

| Comando | Resultado | Observaciones |
| ------- | --------- | ------------- |
| `flutter analyze --no-pub` | Iniciado, sin salida util en el alias del entorno. | Se uso SDK directo para cerrar validacion sin dejar proceso colgado. |
| `C:\src\flutter\bin\flutter.bat analyze --no-pub` | `No issues found! (ran in 306.8s)` | Validacion estatica cerrada. |
| `Get-ChildItem -Path lib -Recurse -Filter *.dart` | Inventario de codigo runtime. | Usado para estructura y archivos grandes. |
| `Get-ChildItem -Path test -Recurse -Filter *.dart` | Inventario de tests. | No se ejecuto suite completa. |
| `rg -n "...patrones..." lib test` | Busquedas focalizadas. | Providers, SQLite, Firestore, deprecated, TODO, performance, tests y dependencias. |
| `Get-Content ruta | Select-Object -First/-Last` | Lectura de archivos clave. | Solo lectura. |

## 3. Inventario del repo

| Area | Carpetas/archivos clave | Responsabilidad | Riesgo inicial |
| ---- | ----------------------- | --------------- | -------------- |
| App/Core | `lib/main.dart`, `lib/core/**` | Bootstrap, servicios, flags, locks, sync, utilidades. | Medio: servicios de sync tienen rutas antiguas y nuevas. |
| Data/local | `lib/data/datasources/local/database_helper.dart`, `local_client_datasource_impl.dart`, `sync_queue_helper.dart` | SQLite, WAL, clients, outbox, training interviews, workout logs. | Alto: JSON blob grande y dominios sin outbox. |
| Data/remote | `lib/data/datasources/remote/**` | Firestore clients y records clinicos. | Alto: rutas duplicadas y payload invalido tratado como no-op exitoso. |
| Repositories | `lib/data/repositories/**` | Contratos local/remoto, agenda, pagos, clinicos, training. | Alto: algunos repos son offline-first, otros online-first. |
| Domain | `lib/domain/**` | Modelos y logica de entrenamiento/nutricion/validadores. | Medio: archivos muy grandes; Motor V3 no fue modificado. |
| Features | `lib/features/**` | UI y providers por dominio. | Alto: widgets grandes, flows de guardado mezclados, agenda/pagos online-first. |
| Tests | `test/**` | Unit/widget/regresion/canaries/manuales. | Medio: buena cobertura en save/outbox, gaps en UI y dominios online-first. |
| Config | `pubspec.yaml`, `analysis_options.yaml` | Dependencias y reglas lint. | Medio: deps sobrantes probables, ignores puntuales. |

Estructura principal observada:

| Carpeta | Conteo aproximado | Observacion |
| ------- | ----------------- | ----------- |
| `lib/domain` | 314 Dart | Dominio mas grande; incluye `training_v3`. |
| `lib/features` | 202 Dart | UI/providers por feature. |
| `lib/core` | 72 Dart | Servicios transversales, sync y locks. |
| `lib/data` | 23 Dart | Datasources y repositorios. |
| `test/training_v3` | 36 Dart | Mayor grupo de tests. |
| `test/` raiz | 32 Dart | Canaries y regresiones dispersas. |

Archivos especialmente grandes:

| Archivo | Lineas aprox. | Riesgo |
| ------- | ------------- | ------ |
| `lib/features/anthropometry_feature/widgets/anthropometry_measures_tab.dart` | 2850 | Widget con IO, validacion, UI y guardado. |
| `lib/domain/training_v3/services/motor_v3_orchestrator.dart` | 2840 | Complejidad alta; no tocar en sprint de guardado. |
| `lib/features/training_feature/widgets/muscle_detail_modal.dart` | 2755 | UI/modal de alta superficie. |
| `lib/features/training_feature/screens/training_workspace_screen.dart` | 2749 | Pantalla grande con tabs y estado. |
| `lib/features/training_feature/providers/training_plan_provider.dart` | 2184 | Provider grande con IO y metodos legacy. |
| `lib/features/biochemistry_feature/widgets/biochemistry_tab.dart` | 2138 | Widget grande con guardado clinico y calculos. |

## 4. Flutter/Dart/deprecados

Resultado de analyzer:

| Item | Estado |
| ---- | ------ |
| `flutter analyze --no-pub` | Sin issues usando SDK directo. |
| `use_build_context_synchronously` | Configurado como error en `analysis_options.yaml`, pero hay ignores puntuales. |
| `avoid_print` | Configurado como error, con ignore puntual en datasource legacy. |

| Hallazgo | Severidad | Archivo | Codigo real | Riesgo | Recomendacion |
| -------- | --------- | ------- | ----------- | ------ | ------------- |
| Ignore global de `use_build_context_synchronously` | P2 | `lib/features/history_clinic_feature/tabs/personal_data_tab.dart` | `// ignore_for_file: use_build_context_synchronously` | Oculta futuros usos inseguros de `BuildContext` despues de `await`. | Quitar ignore en sprint focalizado y corregir usos reales con `mounted`/context local seguro. |
| Ignore de elemento sin uso | P2 | `lib/data/repositories/clinical_records_repository.dart` | `// ignore: unused_element` | Puede ocultar codigo muerto en contrato de sync clinico. | Revisar en cleanup despues de cerrar P0/P1. |
| Ignore de `avoid_print` | P2 | `lib/data/datasources/remote/anthropometry_firestore_datasource.dart` | `// ignore_for_file: avoid_print` | Logging no estandar en datasource remoto. | Migrar a logger cuando se toque ese datasource. |
| APIs marcadas deprecated locales | Info | `training_plan_provider.dart`, `volume_range_muscle_table.dart`, `adaptive_equivalents_engine.dart` | `@Deprecated(...)`, `@deprecated` | No es deprecado Flutter, pero indica rutas legacy vivas. | No tocar Motor V3 ahora; planificar cleanup despues de guardado. |
| Uso moderno de color | Info | Varios | `.withValues(alpha: ...)` | No se observo patron dominante de `withOpacity`. | Mantener. |

Fragmento relevante:

```dart
// archivo: lib/features/history_clinic_feature/tabs/personal_data_tab.dart
// funcion/clase: archivo completo
// lineas aproximadas: 1
// ignore_for_file: use_build_context_synchronously
```

## 5. Providers/Riverpod/estado

| Provider/archivo | Responsabilidad | Patron actual | Riesgo | Codigo evidencia | Accion recomendada |
| ---------------- | --------------- | ------------- | ------ | ---------------- | ------------------ |
| `clientsProvider` / `clients_provider.dart` | Estado global de clientes y active client. | `AsyncNotifier`, locks por cliente, refetch fresco antes de guardar. | Bajo/medio: conserva rama legacy por flag. | `await _repository.saveClient(mergedClient);` dentro de lock. | No romper; usarlo como ruta canonica de guardado. |
| `trainingPlanProvider` / `training_plan_provider.dart` | Plan de entrenamiento y persistencia de planes. | Provider muy grande, observa `clientsProvider`, usa repo directo y metodos deprecated. | P2: rebuild/IO/logica acoplada. | `final clientsState = ref.watch(clientsProvider);` + metodos `@Deprecated`. | Refactor posterior, no dentro de SAVE-P0D. |
| `clientPreferencesEffectProvider` | Preferencias de ejercicio por cliente. | Retorna objeto vacio constante. | P1: preferencias reales no afectan seleccion. | `return const ExercisePreferencesByMuscle();` | Sprint `TRAINING-PREF-P1`. |
| `weeklyProgressionProvider` | Progresion semanal. | `flutter_riverpod/legacy.dart` con `ChangeNotifierProvider.autoDispose`. | P2: provider legacy, mayor riesgo de side effects. | `final weeklyProgressionProvider = ChangeNotifierProvider.autoDispose...` | Migrar solo si se toca ese flujo. |
| `saveIndicatorProvider` | Estado visual de guardado. | `Future.delayed` sin timer cancelable explicito. | P2: transicion tardia si cambia ciclo de vida. | `Future.delayed(const Duration(seconds: 2), () { ... });` | Usar timer cancelable/autoDispose en cleanup UI-state. |

Fragmento bueno de `clientsProvider`:

```dart
// archivo: lib/features/main_shell/providers/clients_provider.dart
// funcion/clase: ClientsNotifier.updateActiveClient
// lineas aproximadas: updateActiveClient
await lock.synchronized(() async {
  final currentState = state.valueOrNull;
  final activeClient = currentState?.activeClient;
  if (activeClient == null) {
    return;
  }
  final latestClient =
      await _repository.getClientById(activeClient.id) ?? activeClient;
  final mergedClient = transform(latestClient);
  await _repository.saveClient(mergedClient);
  ...
});
```

Fragmento riesgoso:

```dart
// archivo: lib/features/training_feature/providers/client_preferences_effect_provider.dart
// funcion/clase: clientPreferencesEffectProvider
// lineas aproximadas: 7-18
final clientPreferencesEffectProvider = FutureProvider<ExercisePreferencesByMuscle?>((ref) async {
  final clientsState = ref.watch(clientsProvider);

  return clientsState.when(
    data: (state) {
      final activeClient = state.activeClient;
      if (activeClient == null) return null;
      return const ExercisePreferencesByMuscle();
    },
    error: (_, _) => null,
    loading: () => null,
  );
});
```

## 6. SQLite/local persistence

| Tabla | Campos | Indices | Uso | Riesgo |
| ----- | ------ | ------- | --- | ------ |
| `clients` | `id`, `json`, `isSynced`, `isDeleted`, `updatedAt` | `idx_clients_synced`, `idx_clients_deleted`, `idx_clients_updated` | Fuente local principal de `Client`. | JSON blob grande; cambios granulares pueden reescribir todo. |
| `sync_queue` | `id`, `domain`, `client_id`, `date_key`, `payload`, `retry_count`, `created_at`, `last_attempt`, `error_message` | `idx_sync_queue_retry` | Outbox durable para client y records clinicos upsert. | Sin indice compuesto por dominio/cliente/date, aunque `id` es deterministico. |
| `training_interviews` | `id`, `client_id`, `version`, `status`, `data`, timestamps, `is_synced` | `idx_training_interviews_client`, `idx_training_interviews_synced` | Entrevistas de entrenamiento. | OK; FK con cascade. |
| `app_state` | `key`, `value` | PK | Estado app. | Bajo. |
| `workout_logs` | `id`, `userId`, `programId`, `exerciseLogs`, `startTime`, `endTime`, `status`, `notes` | No observado en creacion. | Logs entrenamiento. | P2: queries por user/program/fecha sin indices visibles. |

| Flujo | Transaccional | Outbox | Riesgo residual | Evidencia |
| ----- | ------------- | ------ | --------------- | --------- |
| `saveClient` | Si, `clients` + `sync_queue` en misma transaccion local. | Si, dominio `client`. | Bajo salvo payload invalido remoto P0. | `upsertClientWithOutbox`. |
| `deleteClient` | Si, tombstone local + `sync_queue`. | Si, dominio `client`. | Bajo. | `softDeleteClientWithOutbox`. |
| Anthropometry/Biochemistry upsert | Parcial: primero `Client` JSON por provider, luego outbox clinico. | Si, dominio por record/date. | Brecha corta entre save client y enqueue clinico si falla segundo paso. | `pushAnthropometryRecord`, `pushBiochemistryRecord`. |
| Anthropometry/Biochemistry delete | No granular durable. | No. | P1: delete remoto puede fallar y perder tombstone granular. | `RecordDeletionService`. |

Fragmento de transaccion client + outbox:

```dart
// archivo: lib/data/datasources/local/database_helper.dart
// funcion/clase: upsertClientWithOutbox
// lineas aproximadas: 322-376
return db.transaction((txn) async {
  final clientJson = await _wrapClientJson(client);
  await txn.insert(
    'clients',
    clientJson,
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
  ...
  final operationId = const Uuid().v4();
  final queueItemId = 'client_${client.id}_';
  final queuePayload = <String, dynamic>{
    'action': 'upsert',
    'operationId': operationId,
    'updatedAt': persistedClient.updatedAt.toIso8601String(),
    'client': persistedClient.toJson(),
  };
  await SyncQueueHelper.enqueueOn(
    txn,
    id: queueItemId,
    domain: 'client',
    clientId: client.id,
    dateKey: '',
    payload: jsonEncode(queuePayload),
  );
});
```

Fragmento de `sync_queue`:

```dart
// archivo: lib/data/datasources/local/sync_queue_helper.dart
// funcion/clase: SyncQueueDomains / ensureSchema
// lineas aproximadas: 5-45
class SyncQueueDomains {
  static const client = 'client';
  static const anthropometryRecordUpsert = 'anthropometry_record_upsert';
  static const biochemistryRecordUpsert = 'biochemistry_record_upsert';
}

CREATE TABLE IF NOT EXISTS sync_queue (
  id TEXT PRIMARY KEY,
  domain TEXT NOT NULL,
  client_id TEXT NOT NULL,
  date_key TEXT NOT NULL,
  payload TEXT NOT NULL,
  retry_count INTEGER DEFAULT 0,
  created_at TEXT NOT NULL,
  last_attempt TEXT,
  error_message TEXT
)
```

## 7. Firestore/remote persistence

| Dominio | Ruta Firestore | Archivo | Operacion | Riesgo |
| ------- | -------------- | ------- | --------- | ------ |
| Client actual | `coaches/{coachId}/clients/{clientId}` | `client_firestore_datasource.dart` | `set(..., merge: true)` | P0 si payload invalido retorna sin throw. |
| Client legacy | `clients/{clientId}` | `remote_client_datasource_impl.dart` | `set`, `delete`, `get` | P1/Info: ruta duplicada top-level. |
| Clinical records | `coaches/{coachId}/clients/{clientId}/{collection}/{dateKey}` | `record_firestore_datasource.dart` | `set(..., merge: true)` | Upsert OK; delete sin outbox. |
| Appointments nested | `coaches/{uid}/appointments` | `appointment_firestore_datasource.dart` | CRUD directo | P1: online-first, no outbox. |
| Appointments legacy | `appointments` | `appointment_repository.dart` | CRUD directo con `trainerId` | P1: ruta duplicada. |
| Transactions nested | `coaches/{uid}/transactions` | `transaction_firestore_datasource.dart` | CRUD directo | P1: online-first, no outbox. |
| Transactions legacy | `transactions` | `transaction_repository.dart` | CRUD directo con `trainerId` | P1: ruta duplicada. |

| Ruta duplicada/legacy | Evidencia | Riesgo | Recomendacion |
| --------------------- | --------- | ------ | ------------- |
| `clients/{id}` vs `coaches/{coachId}/clients/{id}` | `RemoteClientDataSourceImpl` usa top-level; provider principal usa `ClientFirestoreDataSource`. | Datos bifurcados si alguien conecta datasource legacy. | Deprecar/remover en sprint de cleanup posterior a P0. |
| `appointments` vs `coaches/{uid}/appointments` | Hay repository top-level y datasource nested. | Doble fuente de verdad para agenda. | Elegir una ruta y envolver en local/outbox. |
| `transactions` vs `coaches/{uid}/transactions` | Hay repository top-level y datasource nested. | Doble fuente de verdad para pagos. | Elegir una ruta y envolver en local/outbox. |

Fragmento P0:

```dart
// archivo: lib/data/datasources/remote/client_firestore_datasource.dart
// funcion/clase: ClientFirestoreDataSource.upsertClient
// lineas aproximadas: payload validation
final invalidPath = findInvalidFirestorePath(fullPayload);
if (invalidPath != null) {
  logger.warning(
    'Skipping remote client sync due to invalid Firestore payload',
    {'clientId': client.id, 'invalidPath': invalidPath},
  );
  return;
}
```

Fragmento de manejo correcto de permission-denied:

```dart
// archivo: lib/data/datasources/remote/client_firestore_datasource.dart
// funcion/clase: ClientFirestoreDataSource.upsertClient
// lineas aproximadas: catch FirebaseException
} on FirebaseException catch (e) {
  if (e.code == 'permission-denied') {
    _logPermissionDenied(coachId: coachId, clientId: client.id, error: e);
  }
  rethrow;
}
```

## 8. SAVE-P0A verification

| Contrato SAVE-P0A | Estado | Evidencia codigo | Riesgo residual |
| ----------------- | ------ | ---------------- | --------------- |
| `permission-denied` no es exito silencioso. | Refutado como bug. | `ClientFirestoreDataSource` captura y `rethrow`. | Bajo. |
| Payload invalido no se considera exito. | Confirmado como bug. | `findInvalidFirestorePath(fullPayload)` hace `return` normal. | P0: puede marcar synced/queue success sin escritura. |
| `markClientAsSynced` solo ocurre despues de exito remoto. | Parcial. | Caller espera `await _remote.upsertClient`; si datasource retorna no-op, se considera exito. | Depende del P0-01. |
| Push viejo no marca synced sobre save nuevo. | Cerrado. | Compara `current.updatedAt != client.updatedAt` antes de marcar. | Bajo. |
| Queue vieja no cierra queue nueva. | Cerrado. | Compara `operationId` del payload actual. | Bajo. |
| No auth deja pending. | Cerrado en background queue. | `processClientOutboxItem` retorna pending si no hay coach. | Bajo. |
| Firebase no inicializado deja pending. | No concluyente. | No se vio contrato explicito global; errores remotos se reintentan por failure path. | Medio. |

Fragmento de proteccion stale:

```dart
// archivo: lib/core/services/background_sync_service.dart
// funcion/clase: processClientOutboxItem
// lineas aproximadas: stale guards
final current = await _localRepository.fetchClientIncludingDeleted(client.id);
if (current == null) {
  return SyncItemProcessResult.pending;
}
if (current.updatedAt != client.updatedAt) {
  return SyncItemProcessResult.pending;
}
await _localRepository.markClientAsSynced(client.id);
```

## 9. SAVE-P0B verification

| Contrato SAVE-P0B | Estado | Evidencia codigo | Riesgo residual |
| ----------------- | ------ | ---------------- | --------------- |
| `saveClient` escribe Client + outbox. | Cerrado. | `ClientRepository.saveClient` llama `_local.saveClientWithOutbox(client)`. | Bajo. |
| `deleteClient` escribe tombstone + outbox. | Cerrado. | `_local.deleteClientWithOutbox(client)` y payload `deleted: true`. | Bajo. |
| Operacion local atomica. | Cerrado. | `db.transaction((txn) async { ... clients ... sync_queue ... })`. | Bajo. |
| Outbox tiene `operationId`. | Cerrado. | Payload local incluye UUID. | Bajo. |
| Eventos viejos no cierran eventos nuevos. | Cerrado. | `_markQueueItemSuccessIfCurrent` compara `operationId`. | Bajo. |
| Timer remoto solo fast-path. | Cerrado. | Timer hace `_pushClientRemote`; outbox durable ya existe antes. | Bajo. |
| Background sync procesa client. | Cerrado. | `SyncService._syncItem` delega dominio `client`. | Bajo. |
| Remote failure conserva queue. | Cerrado. | Exceptions pasan a `markFailure`, no `markSuccess`. | Bajo. |
| No auth conserva pending. | Cerrado. | `processClientOutboxItem` retorna pending sin usuario. | Bajo. |

Fragmento de timer fast-path:

```dart
// archivo: lib/data/repositories/client_repository.dart
// funcion/clase: ClientRepository.saveClient
// lineas aproximadas: 46-62
final outboxWrite = await _local.saveClientWithOutbox(client);
_pendingRemotePush[client.id] = outboxWrite;
_remotePushDebounce[client.id]?.cancel();
_remotePushDebounce[client.id] = Timer(_remotePushDebounceDuration, () {
  final latest = _pendingRemotePush.remove(client.id);
  if (latest == null) return;
  unawaited(_pushClientRemote(latest, deleted: false).catchError((_) {}));
});
```

## 10. SAVE-P0C verification

| Contrato SAVE-P0C | Estado | Evidencia codigo | Riesgo residual |
| ----------------- | ------ | ---------------- | --------------- |
| `anthropometry_record_upsert` existe. | Cerrado. | `SyncQueueDomains.anthropometryRecordUpsert`. | Bajo. |
| `biochemistry_record_upsert` existe. | Cerrado. | `SyncQueueDomains.biochemistryRecordUpsert`. | Bajo. |
| Payload por `dateKey`. | Cerrado. | Queue id `${domain}_${clientId}_$dateKey`. | Bajo. |
| Same date reemplaza payload. | Cerrado. | `ConflictAlgorithm.replace` en `SyncQueueHelper.enqueue`. | Bajo. |
| Different date crea item distinto. | Cerrado. | `dateKey` forma parte de id. | Bajo. |
| Remote failure conserva item. | Cerrado. | Background incrementa retry, no borra. | Bajo. |
| No auth pending. | Cerrado. | `processClinicalRecordOutboxItem` retorna pending sin coach. | Bajo. |
| No marca `Client` synced por record granular. | Cerrado. | Queue clinica usa `markSuccess` de item, no `markClientAsSynced`. | Bajo. |
| Brecha Client JSON + clinical outbox. | Parcial. | UI primero actualiza `Client`, luego llama `push...Record`. | P1/P2: si falla entre pasos, record queda local en Client sin outbox granular. |

Fragmento upsert clinico:

```dart
// archivo: lib/data/repositories/clinical_records_repository.dart
// funcion/clase: _enqueueClinicalRecordUpsert
// lineas aproximadas: 487-512
final dateKey = _dateFormat.format(recordDate);
final operationId = const Uuid().v4();
final queueItemId = '${domain}_${clientId}_$dateKey';
final payload = <String, dynamic>{
  'action': 'upsert',
  'operationId': operationId,
  'clientId': clientId,
  'recordDate': recordDate.toIso8601String(),
  'dateKey': dateKey,
  'recordJson': recordJson,
  'updatedAt': updatedAt,
  'domain': domain,
};
await SyncQueueHelper.enqueue(
  id: queueItemId,
  domain: domain,
  clientId: clientId,
  dateKey: dateKey,
  payload: jsonEncode(payload),
);
```

Fragmento fire-and-forget aun pendiente para otros records:

```dart
// archivo: lib/data/repositories/clinical_records_repository.dart
// funcion/clase: pushNutritionRecord / pushTrainingRecord
// lineas aproximadas: 302-333
void pushNutritionRecord(
  String clientId,
  Map<String, dynamic> recordJson,
  DateTime date,
) {
  _pushInBackground(() => _doPushNutritionRecord(clientId, recordJson, date));
}

void pushTrainingRecord(
  String clientId,
  Map<String, dynamic> recordJson,
  DateTime date,
) {
  _pushInBackground(() => _doPushTrainingRecord(clientId, recordJson, date));
}
```

## 11. PROVIDER-P1A verification

| Tab | Usa patch | Usa prev fresco | Rehidrata por revision | Test | Estado |
| --- | --------- | --------------- | ---------------------- | ---- | ------ |
| `personal_data_tab.dart` | Si | Si, `updateActiveClient((prev) { ... })` | Si, no si dirty. | `clinical_tabs_stale_drafts_test.dart` | Cerrado en tab, con ignore P2. |
| `background_tab.dart` | Si | Si | Si | `clinical_tabs_stale_drafts_test.dart` | Cerrado en tab. |
| `general_evaluation_tab.dart` | Si | Si | Si | `clinical_tabs_stale_drafts_test.dart` | Cerrado en tab. |
| `gyneco_tab.dart` | Si | Si | Si | `clinical_tabs_stale_drafts_test.dart` | Cerrado en tab. |
| `HistoryClinicScreen` / ViewModel | No directo | Parcial | N/A | No ejecutado | Residual P1 por merge amplio legacy. |

| Helper | Codigo evidencia | Riesgo |
| ------ | ---------------- | ------ |
| `applyPersonalDataTabPatch` | Compara base vs draft y modifica `activeClient.profile/nutrition`. | Bajo. |
| `applyBackgroundTabPatch` | Copia solo keys extra tocadas sobre `activeClient.history`. | Bajo. |
| `applyGeneralEvaluationTabPatch` | Copia alergias, medicamentos y keys especificas. | Bajo/medio por muchas ramas. |
| `applyGynecoTabPatch` | Copia solo campos gineco reales y keys extra. | Bajo. |
| `historyTabRevision` helpers | Hash de campos por tab, no `updatedAt` global. | Bajo. |

Fragmento de patch helper correcto:

```dart
// archivo: lib/features/history_clinic_feature/tabs/clinical_tab_client_patches.dart
// funcion/clase: applyBackgroundTabPatch
// lineas aproximadas: helper
Client applyBackgroundTabPatch({
  required Client activeClient,
  required ClientHistory baseHistory,
  required ClientHistory draftHistory,
}) {
  final patchedHistory = _copyHistoryWithChangedExtraKeys(
    activeHistory: activeClient.history,
    baseHistory: baseHistory,
    draftHistory: draftHistory,
    keys: _backgroundHistoryExtraKeys,
  );
  return activeClient.copyWith(history: patchedHistory);
}
```

Fragmento residual de merge amplio:

```dart
// archivo: lib/features/history_clinic_feature/viewmodel/history_clinic_view_model.dart
// funcion/clase: HistoryClinicViewModel.saveClient
// lineas aproximadas: saveClient
await ref.read(clientsProvider.notifier).updateActiveClient((prev) {
  final mergedNutritionExtra = Map<String, dynamic>.from(prev.nutrition.extra);
  mergedNutritionExtra.addAll(updated.nutrition.extra);
  final mergedTrainingExtra = Map<String, dynamic>.from(prev.training.extra);
  mergedTrainingExtra.addAll(updated.training.extra);
  final mergedTraining = updated.training.copyWith(extra: mergedTrainingExtra);
  return prev.copyWith(
    profile: updated.profile,
    history: updated.history,
    training: mergedTraining,
    nutrition: prev.nutrition.copyWith(
      extra: mergedNutritionExtra,
      dailyMealPlans:
          updated.nutrition.dailyMealPlans ?? prev.nutrition.dailyMealPlans,
    ),
  );
});
```

## 12. Offline-first pending domains

| Dominio | Local | Remote | Outbox | Delete durable | Estado | Prioridad |
| ------- | ----- | ------ | ------ | -------------- | ------ | --------- |
| Clients | `clients` SQLite | `coaches/{coachId}/clients/{id}` | Si | Si | Offline-first, salvo P0 payload invalido. | P0 |
| Anthropometry upsert | Client JSON | Records subcollection por dateKey | Si | N/A | Local-first parcial. | Cerrado para upsert |
| Biochemistry upsert | Client JSON | Records subcollection por dateKey | Si | N/A | Local-first parcial. | Cerrado para upsert |
| Anthropometry delete | Client JSON filtrado | `deleted: true` remoto directo | No | No | Parcial. | P1 |
| Biochemistry delete | Client JSON filtrado | `deleted: true` remoto directo | No | No | Parcial. | P1 |
| Nutrition records | Client JSON/extras | Fire-and-forget record repo | No | No observado | Online/local parcial. | P1/P2 |
| Training records | `workout_logs` y Client training | Fire-and-forget record repo | No | No observado | Parcial. | P1/P2 |
| Progress photos/storage | No observado | Dependency `firebase_storage` declarada sin uso | No | No observado | No implementado o muerto. | P2 |
| Agenda/citas | No tabla local observada | Firestore directo | No | No | Online-first. | P1 |
| Pagos/transacciones | No tabla local observada | Firestore directo | No | No | Online-first. | P1 |

Fragmento delete clinico sin outbox:

```dart
// archivo: lib/domain/services/record_deletion_service.dart
// funcion/clase: deleteAnthropometryByDate / deleteBiochemistryByDate
// lineas aproximadas: delete helpers
await _recordFirestoreDataSource.markRecordDeleted(
  coachId: user.uid,
  clientId: clientId,
  domain: RecordDomain.anthropometry,
  date: date,
);
```

## 13. UI/widgets/layout risks

| Pantalla/widget | Problema | Codigo evidencia | Riesgo UI/performance | Recomendacion |
| --------------- | -------- | ---------------- | --------------------- | ------------- |
| `anthropometry_measures_tab.dart` | Archivo de 2850 lineas con UI + guardado + calculos. | `updateActiveClient` y `pushAnthropometryRecord` dentro del widget. | Alto costo de cambio y regresion. | Extraer coordinador/servicio despues de P0/P1. |
| `biochemistry_tab.dart` | Archivo de 2138 lineas; controllers dinamicos y delete mixto. | `_controllers`, `_saveMeasurements`, `_deleteRecord`. | Riesgo de leaks y doble guardado. | Separar formulario, persistence coordinator y tabla. |
| `biochemistry_comparison_screen.dart` | `Table` sin scroll horizontal visible en comparacion. | `Table(columnWidths: const {...})`. | Overflow probable en pantallas chicas. | Envolver tabla en scroll horizontal si se confirma visualmente. |
| `client_list_screen.dart` | Pantalla mock con controller sin dispose. | `_searchController`, `itemCount: 5`, `Atleta Ejemplo`. | Leak menor y UX falsa si es alcanzable. | Convertir o retirar en cleanup UI-P1A. |
| `food_search_widget.dart` | Controller creado dentro de `build`. | `final controller = TextEditingController();` | Leak/recreacion por rebuild. | Stateful + dispose o controller externo. |
| `workspace_home_screen.dart` | Calcula filtros/listas/totales en build. | `_appointmentsForDay`, `_transactionsForMonth`, `_monthlyTotal`. | Rebuild costoso con muchos registros. | Selectores/memoizacion/paginacion. |

Fragmento de controller sin dispose:

```dart
// archivo: lib/features/client_feature/screen/client_list_screen.dart
// funcion/clase: _ClientListScreenState
// lineas aproximadas: inicio de State
class _ClientListScreenState extends ConsumerState<ClientListScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
```

Fragmento de controller en build:

```dart
// archivo: lib/features/food_database_feature/widgets/food_search_widget.dart
// funcion/clase: FoodSearchWidget.build
// lineas aproximadas: build
final controller = TextEditingController();
```

## 14. Performance risks

| Archivo | Patron | Riesgo | Evidencia | Recomendacion |
| ------- | ------ | ------ | --------- | ------------- |
| `workspace_home_screen.dart` | `where/toList/sort/fold` para agenda, tareas y transacciones en build. | Costo crece con datos. | Helpers `_appointmentsForDay`, `_transactionsForMonth`, `_monthlyTotal`. | Providers derivados o cache por mes/dia. |
| `database_helper.dart` | `jsonEncode/jsonDecode` de `Client` completo. | Bloqueo UI si se llama en flujo visible con clientes grandes. | `json TEXT NOT NULL` + `_wrapClientJson`. | Mantener outbox, pero mover dominios calientes a tablas granulares. |
| `training_plan_provider.dart` | Provider gigante con IO y calculos. | Rebuild y mantenimiento costoso. | 2184 lineas, `ref.watch(clientsProvider)`. | Refactor por casos de uso, fuera del sprint P0. |
| `biochemistry_tab.dart` | Controllers y calculos de ratio en widget grande. | Rebuild/form costoso. | Controllers por medida y ratio text. | Extraer form model/controladores. |
| `SyncService` | Timer periodico de sync. | OK si se cancela; verificar lifecycle al integrar. | `Timer.periodic` observado. | Mantener start/stop centralizado. |

## 15. Tests audit

| Test | Cobertura | Riesgo | Estado | Recomendacion |
| ---- | --------- | ------ | ------ | ------------- |
| `test/data/repositories/client_repository_sync_test.dart` | SAVE-P0A: permission denied, invalid payload, stale push. | Puede usar fakes y no cubrir datasource real que retorna `return`. | Listado, no ejecutado. | Ejecutar despues de P0-01 y agregar test contra `ClientFirestoreDataSource` o contrato typed result. |
| `test/data/repositories/client_repository_outbox_test.dart` | SAVE-P0B local transaction/outbox. | Buen canary. | Listado, no ejecutado. | Mantener. |
| `test/core/services/background_sync_service_outbox_test.dart` | Queue client success/failure/stale. | Buen canary. | Listado, no ejecutado. | Mantener. |
| `test/data/repositories/clinical_records_outbox_test.dart` | SAVE-P0C upsert/dateKey. | Buen canary para clinicos. | Listado, no ejecutado. | Mantener. |
| `test/core/services/background_sync_service_clinical_records_outbox_test.dart` | Sync clinico remoto/no auth/failure. | Buen canary. | Listado, no ejecutado. | Mantener. |
| `test/features/history_clinic_feature/clinical_tabs_stale_drafts_test.dart` | PROVIDER-P1A stale drafts. | No se verifico runtime actual en esta auditoria. | Listado, no ejecutado. | Ejecutar focalizado en sprint PROVIDER-P1A-B. |
| `test/manual/*firestore*` | Smoke manual Firebase. | Depende de Firebase real y esta `skip`. | Manual. | No convertir en CI automatico sin emulator/fakes. |
| `.dart.bak` bajo tests training | Backups no test reales. | Puede confundir busquedas. | Observado por `rg`. | Cleanup posterior, sin borrar ahora. |

No se ejecuto `flutter test` completo por regla explicita. Tests focalizados recomendados despues de fixes:

```powershell
C:\src\flutter\bin\flutter.bat test test\data\repositories\client_repository_sync_test.dart --reporter expanded
C:\src\flutter\bin\flutter.bat test test\data\repositories\client_repository_outbox_test.dart --reporter expanded
C:\src\flutter\bin\flutter.bat test test\core\services\background_sync_service_outbox_test.dart --reporter expanded
C:\src\flutter\bin\flutter.bat test test\data\repositories\clinical_records_outbox_test.dart --reporter expanded
C:\src\flutter\bin\flutter.bat test test\core\services\background_sync_service_clinical_records_outbox_test.dart --reporter expanded
C:\src\flutter\bin\flutter.bat test test\features\history_clinic_feature\clinical_tabs_stale_drafts_test.dart --reporter expanded
```

## 16. Dependencies audit

| Paquete | Version pubspec | Uso encontrado | Estado | Recomendacion |
| ------- | --------------- | -------------- | ------ | ------------- |
| `flutter_riverpod` | `3.0.3` | Uso amplio en providers/widgets. | Necesario. | Mantener. |
| `riverpod` | `3.0.3` | No se observo import directo dominante. | Posible redundancia tecnica con `flutter_riverpod`. | Revisar en DEPS-P2A, no tocar ahora. |
| `riverpod_annotation` | `3.0.0` | No se confirmo uso generado amplio. | Revisar. | Auditar junto con generadores. |
| `provider` | `6.1.5+1` | No se observo `package:provider` en `lib/test`. | Posible sobrante. | Candidato DEPS-P2A. |
| `firebase_core` | `4.2.1` | Bootstrap Firebase. | Necesario. | Mantener. |
| `cloud_firestore` | `6.1.0` | Datasources remote. | Necesario. | Mantener. |
| `firebase_auth` | `6.1.2` | Auth y coach id. | Necesario. | Mantener. |
| `firebase_storage` | `13.0.6` | No se observo import/uso local. | Posible sobrante. | Confirmar antes de remover. |
| `firebase_analytics` | `12.0.0` | No se observo import/uso local. | Posible sobrante. | Confirmar antes de remover. |
| `firebase_app_check` | `0.4.1+4` | Uso en bootstrap. | Necesario si App Check activo. | Mantener. |
| `sqflite` | `^2.4.2` | SQLite runtime. | Necesario. | Mantener. |
| `sqflite_common_ffi` | `^2.3.6` | Desktop/tests. | Necesario. | Mantener. |
| `shared_preferences` | `^2.5.3` | No se observo import. | Posible sobrante. | Confirmar. |
| `http` | `^1.5.0` | No se observo import. | Posible sobrante. | Confirmar. |
| `google_fonts` | `^6.3.2` | No se observo import. | Posible sobrante. | Confirmar. |
| `fl_chart` | `^1.1.1` | Charts. | Necesario. | Mantener. |
| `pdf` / `printing` | `^3.11.3` / `^5.14.2` | Exports/reportes. | Necesario si PDF activo. | Mantener. |
| `flutter_form_builder` | `^10.2.0` | Formularios puntuales. | Usado. | Mantener. |
| `form_builder_validators` | `^11.2.0` | No se observo uso. | Posible sobrante. | Confirmar. |
| `url_launcher` | `^6.3.2` | Links/invitacion/detalles. | Usado. | Mantener. |
| `uuid` | `^4.5.1` | `operationId`. | Necesario. | Mantener. |
| `csv` | `^6.0.0` | Dataset/training export. | Usado. | Mantener. |
| `synchronized` | `^3.4.0` | Locks de update. | Necesario. | Mantener. |
| `mocktail` | `^1.0.4` | Tests. | Usado. | Mantener. |
| `mockito` | `^5.5.1` | No se observo uso. | Posible sobrante dev. | Confirmar. |
| `fake_async` | `^1.3.3` | Tests. | Usado. | Mantener. |

## 17. Bug checklist

| Bug | Estado | Evidencia | Severidad | Accion siguiente |
| --- | ------ | --------- | --------- | ---------------- |
| `permission-denied` tratado como exito. | Refutado. | `rethrow` en `ClientFirestoreDataSource`. | Info | Mantener tests. |
| `markClientAsSynced` sin confirmacion real. | Parcial. | Depende de `await upsertClient`; falla si upsert retorna no-op por payload invalido. | P0 | SAVE-P0D. |
| Push viejo marcando synced sobre save nuevo. | Refutado. | Compara `updatedAt`. | Info | Mantener. |
| Queue item viejo cerrando queue nueva. | Refutado. | Compara `operationId`. | Info | Mantener. |
| Record clinico local sin outbox. | Parcial. | Upserts antropometria/bioquimica tienen outbox; nutrition/training no. | P1/P2 | SAVE-P0E. |
| Delete clinico sin outbox. | Confirmado. | `RecordDeletionService` remoto directo. | P1 | SAVE-P0E. |
| Tabs clinicas devolviendo `Client` viejo. | Parcial. | Tabs usan patch; screen/viewmodel conserva merge amplio. | P1 | PROVIDER-P1A-B. |
| `HistoryClinicScreen` mezclando snapshot viejo. | Parcial. | `save()`/ViewModel hacen merge amplio de `updated`. | P1 | PROVIDER-P1A-B. |
| Agenda/pagos Firestore directo. | Confirmado. | Appointment/transaction datasources/repositories. | P1 | SYNC-P1A. |
| Rutas Firestore duplicadas. | Confirmado. | `clients`, `appointments`, `transactions` top-level y nested. | P1 | SYNC-P1A. |
| Provider de preferencias de entrenamiento vacio. | Confirmado. | Retorna `const ExercisePreferencesByMuscle()`. | P1 | TRAINING-PREF-P1. |
| Imports de `provider` sin uso. | Confirmado como dependencia sin uso observado. | No se observo `package:provider`. | P2 | DEPS-P2A. |
| Firebase Storage declarado pero no usado. | Confirmado como uso no observado. | No se observo import `firebase_storage`. | P2 | DEPS-P2A. |
| Analytics declarado pero no usado. | Confirmado como uso no observado. | No se observo import `firebase_analytics`. | P2 | DEPS-P2A. |
| Tests colgados. | No concluyente actual. | No se corrieron tests; analyzer alias si quedo colgado. | Info | Ejecutar focalizados. |
| Timers sin cancelacion. | Parcial. | `SaveIndicatorNotifier` usa `Future.delayed`; repos cancelan debounce. | P2 | UI-P1A. |
| Controllers sin dispose. | Confirmado. | `client_list_screen`, `food_search_widget`. | P2 | UI-P1A. |
| Listeners sin cancelar. | No concluyente. | No se confirmo listener leak critico. | Info | Revisar por feature. |
| `setState` despues de dispose. | No concluyente. | Analyzer limpio; algunos ignores pueden ocultar context, no setState. | Info | Quitar ignores focalizados. |
| UI overflow probable. | Confirmado probable. | `Table` sin scroll horizontal en comparacion bioquimica. | P2 | UI-P1A. |
| Navegacion con indices fuera de rango. | Refutado en pantalla revisada. | `TrainingWorkspaceScreen` tiene 6 tabs y controller length 6. | Info | Mantener test/regresion. |
| `TabController.length` inconsistente. | Refutado en pantalla revisada. | Tabs y views alineadas. | Info | Mantener. |
| Datos entrenamiento regenerados en vez de cargar snapshot. | No concluyente. | Provider grande con metodos legacy; no se audito Motor V3 profundo por regla. | Info/P2 | No tocar Motor V3 ahora. |
| Nutricion/records pisan extra maps. | Parcial. | Patches clinicos protegen; nutrition records fire-and-forget. | P1/P2 | SAVE-P0E/PROVIDER-P1A-B. |
| Deletes sin tombstone. | Confirmado para durable local; remoto si escribe tombstone directo. | Sin outbox granular. | P1 | SAVE-P0E. |

## 18. P0 findings

| ID | Hallazgo | Archivo | Evidencia | Accion |
| -- | -------- | ------- | --------- | ------ |
| P0-01 | Payload Firestore invalido retorna exito logico. | `lib/data/datasources/remote/client_firestore_datasource.dart` | `if (invalidPath != null) { ... return; }` antes de `ref.set`. | `SAVE-P0D`: convertir en error/retryable result y cubrir con test contra datasource/caller. |

## 19. P1 findings

| ID | Hallazgo | Archivo | Evidencia | Accion |
| -- | -------- | ------- | --------- | ------ |
| P1-01 | Deletes clinicos sin outbox durable. | `record_deletion_service.dart`, `record_firestore_datasource.dart` | `markRecordDeleted` directo a Firestore. | `SAVE-P0E`. |
| P1-02 | Agenda online-first y rutas duplicadas. | `appointment_firestore_datasource.dart`, `appointment_repository.dart` | `coaches/{uid}/appointments` y `appointments`. | `SYNC-P1A`. |
| P1-03 | Pagos online-first y rutas duplicadas. | `transaction_firestore_datasource.dart`, `transaction_repository.dart` | `coaches/{uid}/transactions` y `transactions`. | `SYNC-P1A`. |
| P1-04 | Merge amplio residual en historia clinica. | `history_clinic_view_model.dart`, `history_clinic_screen.dart` | `prev.copyWith(profile: updated.profile, history: updated.history, ...)`. | `PROVIDER-P1A-B`. |
| P1-05 | Preferencias de entrenamiento vacias. | `client_preferences_effect_provider.dart` | `return const ExercisePreferencesByMuscle();`. | `TRAINING-PREF-P1`. |

## 20. P2 findings

| ID | Hallazgo | Archivo | Evidencia | Accion |
| -- | -------- | ------- | --------- | ------ |
| P2-01 | Widgets/proveedores gigantes. | Varios | Archivos de 2000+ lineas. | Refactor gradual por feature. |
| P2-02 | Controllers sin dispose. | `client_list_screen.dart`, `food_search_widget.dart` | Controllers creados y no dispuestos. | `UI-P1A`. |
| P2-03 | Calculos en build. | `workspace_home_screen.dart` | `where/toList/sort/fold` por build. | Selectores/memoizacion. |
| P2-04 | Ignores de lints. | Varios | `ignore_for_file`, `ignore`. | Cleanup focalizado. |
| P2-05 | Dependencias sin uso observado. | `pubspec.yaml` | `provider`, `firebase_storage`, `firebase_analytics`, etc. | `DEPS-P2A`. |
| P2-06 | `workout_logs` sin indices visibles. | `database_helper.dart` | Tabla creada sin index observado. | Revisar queries y migracion. |

## 21. Codigo critico citado

### P0: payload invalido remoto no falla

```dart
// archivo: lib/data/datasources/remote/client_firestore_datasource.dart
// funcion/clase: ClientFirestoreDataSource.upsertClient
// lineas aproximadas: payload validation
final invalidPath = findInvalidFirestorePath(fullPayload);
if (invalidPath != null) {
  logger.warning(
    'Skipping remote client sync due to invalid Firestore payload',
    {'clientId': client.id, 'invalidPath': invalidPath},
  );
  return;
}
```

### SAVE-P0B: client + queue transaccional

```dart
// archivo: lib/data/datasources/local/database_helper.dart
// funcion/clase: upsertClientWithOutbox
// lineas aproximadas: 322-376
return db.transaction((txn) async {
  final clientJson = await _wrapClientJson(client);
  await txn.insert(
    'clients',
    clientJson,
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
  final operationId = const Uuid().v4();
  final queueItemId = 'client_${client.id}_';
  final queuePayload = <String, dynamic>{
    'action': 'upsert',
    'operationId': operationId,
    'updatedAt': persistedClient.updatedAt.toIso8601String(),
    'client': persistedClient.toJson(),
  };
  await SyncQueueHelper.enqueueOn(
    txn,
    id: queueItemId,
    domain: 'client',
    clientId: client.id,
    dateKey: '',
    payload: jsonEncode(queuePayload),
  );
});
```

### SAVE-P0C: outbox granular por fecha

```dart
// archivo: lib/data/repositories/clinical_records_repository.dart
// funcion/clase: _enqueueClinicalRecordUpsert
// lineas aproximadas: 487-512
final dateKey = _dateFormat.format(recordDate);
final operationId = const Uuid().v4();
final queueItemId = '${domain}_${clientId}_$dateKey';
final payload = <String, dynamic>{
  'action': 'upsert',
  'operationId': operationId,
  'clientId': clientId,
  'recordDate': recordDate.toIso8601String(),
  'dateKey': dateKey,
  'recordJson': recordJson,
  'updatedAt': updatedAt,
  'domain': domain,
};
await SyncQueueHelper.enqueue(
  id: queueItemId,
  domain: domain,
  clientId: clientId,
  dateKey: dateKey,
  payload: jsonEncode(payload),
);
```

### PROVIDER-P1A: patch por rama

```dart
// archivo: lib/features/history_clinic_feature/tabs/clinical_tab_client_patches.dart
// funcion/clase: applyGynecoTabPatch
// lineas aproximadas: helper
Client applyGynecoTabPatch({
  required Client activeClient,
  required GynecoObstetricHistory baseGyneco,
  required GynecoObstetricHistory draftGyneco,
  required ClientHistory baseHistory,
  required ClientHistory draftHistory,
}) {
  var gyneco = activeClient.history.gynecoObstetric;
  if (draftGyneco.menarcheAge != baseGyneco.menarcheAge) {
    gyneco = gyneco.copyWith(menarcheAge: draftGyneco.menarcheAge);
  }
  ...
}
```

### Provider vacio de preferencias

```dart
// archivo: lib/features/training_feature/providers/client_preferences_effect_provider.dart
// funcion/clase: clientPreferencesEffectProvider
// lineas aproximadas: 7-18
return clientsState.when(
  data: (state) {
    final activeClient = state.activeClient;
    if (activeClient == null) return null;
    return const ExercisePreferencesByMuscle();
  },
  error: (_, _) => null,
  loading: () => null,
);
```

## 22. Que esta bien y no conviene romper

| Decision correcta | Evidencia | No romper |
| ----------------- | --------- | -------- |
| Riverpod como patron principal. | `AsyncNotifier`, `ConsumerState`, providers por feature. | No mezclar con `provider` legacy. |
| `clientsProvider.updateActiveClient` con lock y cliente fresco. | Refetch local antes de transformar. | Mantener como ruta canonica para cambios de Client. |
| Client outbox transaccional. | `upsertClientWithOutbox` / `softDeleteClientWithOutbox`. | No volver a guardado local + queue separado. |
| `sync_queue` con `operationId`. | Protege eventos viejos. | Mantener comparacion antes de `markSuccess`. |
| SAVE-P0C upserts por `dateKey`. | `domain_clientId_dateKey`. | Mantener idempotencia por fecha. |
| Patch helpers clinicos. | `clinical_tab_client_patches.dart`. | No volver a devolver drafts completos. |
| Material moderno. | Uso de `withValues(alpha:)`. | Mantener APIs actuales. |
| SQLite WAL/busy timeout/FK. | `PRAGMA journal_mode = WAL`, `busy_timeout`, `foreign_keys = ON`. | No quitar. |
| Tests canary de save/outbox. | Tests focalizados existentes. | Ejecutarlos antes/despues de tocar guardado. |

## 23. Siguiente sprint recomendado

Sprint recomendado: `SAVE-P0D`.

Justificacion: antes de ampliar offline-first o limpiar UI, hay un contrato P0 roto: si el payload remoto del cliente es invalido, `ClientFirestoreDataSource.upsertClient` registra warning y retorna normalmente. Como `ClientRepository` y `BackgroundSyncService` tratan la ausencia de exception como exito, el cliente puede quedar `isSynced=1` y la queue puede cerrarse sin escritura real en Firestore.

Criterio de cierre minimo:

| Item | Cierre |
| ---- | ------ |
| Invalid payload remoto | Debe producir exception o resultado fallido, nunca success silencioso. |
| `markClientAsSynced` | Solo despues de `set()` remoto confirmado. |
| Queue | No debe `markSuccess` si `upsertClient` no escribio. |
| Tests | Cubrir caller y datasource/contrato real con invalid payload. |
| Analyzer | `flutter analyze --no-pub` limpio. |

## 24. Backlog ordenado

| Sprint | Objetivo | Severidad | Archivos probables | Criterio de cierre |
| ------ | -------- | --------- | ------------------ | ------------------ |
| `SAVE-P0D` | Hacer que payload invalido remoto falle y conserve pending. | P0 | `client_firestore_datasource.dart`, `client_repository.dart`, tests sync. | Invalid payload no marca synced ni cierra queue. |
| `SAVE-P0E` | Outbox durable para deletes granulares clinicos. | P1 | `record_deletion_service.dart`, `clinical_records_repository.dart`, `sync_queue_helper.dart`, `background_sync_service.dart`. | Delete antropometria/bioquimica tiene tombstone local durable y retry. |
| `PROVIDER-P1A-B` | Eliminar/encapsular merges amplios residuales de historia clinica. | P1 | `history_clinic_screen.dart`, `history_clinic_view_model.dart`, tabs clinicas. | Ninguna tab/screen pisa ramas no editadas con snapshot viejo. |
| `SYNC-P1A` | Definir ruta unica y contrato offline-first para agenda/pagos. | P1 | Appointment/transaction repos/datasources/providers. | Una ruta Firestore canonica y cola local o decision explicita online-first. |
| `TRAINING-PREF-P1` | Conectar preferencias reales de cliente al motor de preferencias. | P1 | `client_preferences_effect_provider.dart`, modelos training prefs. | Provider no devuelve objeto vacio salvo ausencia real. |
| `SAVE-P0F` | Extender outbox a nutrition/training records si son datos clinicos criticos. | P1/P2 | `clinical_records_repository.dart`, features nutrition/training. | No fire-and-forget para records que deban sobrevivir offline. |
| `UI-P1A` | Corregir leaks/controladores y overflows confirmados. | P2 | `client_list_screen.dart`, `food_search_widget.dart`, `biochemistry_comparison_screen.dart`. | Sin controllers sin dispose y sin overflow reproducible. |
| `DEPS-P2A` | Depurar dependencias no usadas. | P2 | `pubspec.yaml`, imports. | Cada paquete declarado tiene uso confirmado o se elimina en PR separado. |
| `TEST-P1A` | Fortalecer canaries y ejecutar suite focalizada. | P1/P2 | Tests save/outbox/provider. | Canaries pasan y cubren P0D/P0E/P1A-B. |

## 25. Conclusion

Estado de cierre de esta auditoria: cerrado.

Estado funcional auditado:

| Area | Resultado |
| ---- | --------- |
| Flutter analyzer | Cerrado: sin issues. |
| SAVE-P0A | Parcial: permission-denied y stale push estan protegidos, pero payload invalido remoto es P0. |
| SAVE-P0B | Cerrado para Client local/outbox transaccional. |
| SAVE-P0C | Cerrado para upserts antropometria/bioquimica; parcial por deletes y otros records. |
| PROVIDER-P1A | Parcial: tabs principales usan patch helpers, pero quedan merges amplios residuales. |
| Offline-first | Parcial: clients y upserts clinicos cubiertos; agenda/pagos/deletes/nutrition/training pendientes. |
| UI/performance | Requiere seguimiento P2, no antes de P0/P1 de guardado. |
| Dependencias | Requiere cleanup P2, no tocar antes de estabilizar guardado. |

No tocar todavia: Motor V3, UI visual amplia, dependencias, pubspec y migraciones grandes. El siguiente trabajo debe ser `SAVE-P0D`.
