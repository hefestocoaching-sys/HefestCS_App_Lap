# A11 - FINDINGS PRIORIZADOS (FORMATO FORENSE ESTRICTO)

## HALLAZGO P0-01
- Clasificación: IMPLEMENTACION NOMINAL NO OPERATIVA
- Archivo exacto: lib/core/services/sync_service.dart
- Clase exacta: SyncService
- Metodo exacto: _syncItem
- Variable exacta: domain, clientId, dateKey, payload
- Bloque/línea aproximada: ~49-57
- Flujo real: la cola entrega item al método, pero la implementación visible solo imprime debug en branch anthropometry y no persiste remoto.

## HALLAZGO P0-02
- Clasificación: IMPLEMENTACION NOMINAL NO OPERATIVA
- Archivo exacto: lib/data/repositories/clinical_records_repository.dart
- Clase exacta: ClinicalRecordsRepository
- Metodo exacto: pushTrainingRecord
- Variable exacta: recordJson
- Bloque/línea aproximada: ~310-317
- Flujo real: API pública de push training recibe parámetros pero retorna de inmediato y no llama _doPushTrainingRecord.

## HALLAZGO P0-03
- Clasificación: GUARDADO SILENCIOSO
- Archivo exacto: lib/data/repositories/client_repository.dart
- Clase exacta: ClientRepository
- Metodo exacto: _pushClientRemote
- Variable exacta: _remoteSyncTemporarilyDisabled
- Bloque/línea aproximada: ~100, ~120-121
- Flujo real: ante permission-denied, activa flag de deshabilitación de sync remoto y retorna sin romper el guardado local.

## HALLAZGO P1-01
- Clasificación: VIOLACION DE SSOT
- Archivo exacto A: lib/data/repositories/appointment_repository.dart
- Clase exacta A: AppointmentRepository
- Metodo exacto A: getAppointmentsStream
- Variable exacta A: _collection = 'appointments'
- Bloque/línea aproximada A: ~7, ~10
- Archivo exacto B: lib/data/repositories/appointment_firestore_datasource.dart
- Clase exacta B: AppointmentFirestoreDataSource
- Metodo exacto B: _appointmentsCollection
- Variable exacta B: userId
- Bloque/línea aproximada B: ~20-26
- Flujo real: el mismo dominio appointments tiene dos rutas de almacenamiento distintas.

## HALLAZGO P1-02
- Clasificación: VIOLACION DE SSOT
- Archivo exacto A: lib/data/repositories/transaction_repository.dart
- Clase exacta A: TransactionRepository
- Metodo exacto A: getTransactionsStream
- Variable exacta A: _collection = 'transactions'
- Bloque/línea aproximada A: ~7, ~10
- Archivo exacto B: lib/data/repositories/transaction_firestore_datasource.dart
- Clase exacta B: TransactionFirestoreDataSource
- Metodo exacto B: _transactionsCollection
- Variable exacta B: userId
- Bloque/línea aproximada B: ~21-27
- Flujo real: el mismo dominio transactions usa dos verdades de colección.

## HALLAZGO P1-03
- Clasificación: GUARDADO SILENCIOSO
- Archivo exacto: lib/data/datasources/remote/client_firestore_datasource.dart
- Clase exacta: ClientFirestoreDataSource
- Metodo exacto: upsertClient
- Variable exacta: hasAuditIssues
- Bloque/línea aproximada: ~259-278
- Flujo real: si hay inconsistencias de payload, registra warning y hace return sin lanzar error.

## HALLAZGO P1-04
- Clasificación: LOGICA EN CAPA ERRONEA
- Archivo exacto: lib/features/nutrition_feature/screens/equivalents_by_day_screen.dart
- Clase exacta: _EquivalentsByDayScreenState
- Metodo exacto: saveIfDirty
- Variable exacta: mergedExtra, updatedRecords
- Bloque/línea aproximada: ~86, ~105-121
- Flujo real: la pantalla UI muta y persiste claves de dominio en nutrition.extra mediante updateActiveClient.

## HALLAZGO P1-05
- Clasificación: LATEST POTENCIALMENTE INCORRECTO
- Archivo exacto: lib/features/nutrition_feature/screens/equivalents_by_day_screen.dart
- Clase exacta: _EquivalentsByDayScreenState
- Metodo exacto: _buildEquivalentsHistoryGrid
- Variable exacta: dateA, dateB, recordDate
- Bloque/línea aproximada: ~242-243, ~300
- Flujo real: en parse fallido de fecha se reemplaza por DateTime.now(), alterando orden y selección de latest según el momento de ejecución.

## HALLAZGO P2-01
- Clasificación: NORMALIZACION INCONSISTENTE
- Archivo exacto A: lib/data/repositories/clinical_records_repository.dart
- Clase exacta A: ClinicalRecordsRepository
- Metodo exacto A: _doPushBiochemistryRecord / _doPushNutritionRecord
- Variable exacta A: _dateFormat = DateFormat('yyyy-MM-dd'), dateKey
- Bloque/línea aproximada A: ~29, ~182, ~280
- Archivo exacto B: lib/features/nutrition_feature/screens/equivalents_by_day_screen.dart
- Clase exacta B: _EquivalentsByDayScreenState
- Metodo exacto B: _normalizeDateIso / _buildEquivalentsHistoryGrid
- Variable exacta B: dateIso, dateAStr
- Bloque/línea aproximada B: ~242-243, ~485-490
- Flujo real: el sistema mezcla normalización por formato fijo yyyy-MM-dd con parseo flexible/fallback en UI.

## HALLAZGO P2-02
- Clasificación: LATEST SENSIBLE A NORMALIZACION
- Archivo exacto: lib/features/training_feature/providers/training_plan_provider.dart
- Clase exacta: TrainingPlanNotifier
- Metodo exacto: _latestRecordByDate
- Variable exacta: latestDate, recordDate
- Bloque/línea aproximada: ~199-212
- Flujo real: la selección latest compara strings (compareTo) y asume formato homogéneo en forDateIso.

## HALLAZGO P2-03
- Clasificación: IMPLEMENTACION OPERATIVA CON UMBRAL FIJO DE REINTENTOS
- Archivo exacto: lib/data/datasources/local/sync_queue_helper.dart
- Clase exacta: SyncQueueHelper
- Metodo exacto: getPendingItems
- Variable exacta: whereArgs: [5]
- Bloque/línea aproximada: ~45, ~51-52
- Flujo real: items con retry_count >= 5 dejan de ser devueltos como pendientes por esta consulta.

## REGLA DE DEPURACION FORENSE APLICADA
- Se eliminaron conclusiones no verificables en código.
- Cada hallazgo aquí contiene archivo, clase, método, variable, línea aproximada y flujo real.
