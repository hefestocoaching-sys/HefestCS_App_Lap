# A08 - MATRIZ SSOT (SOLO EVIDENCIA VERIFICABLE)

## Regla SSOT-01 - Appointments
- Estado: VIOLACION DE SSOT
- Verdad A (ruta flat)
  - Archivo exacto: lib/data/repositories/appointment_repository.dart
  - Clase exacta: AppointmentRepository
  - Metodo exacto: getAppointmentsStream
  - Variable exacta: _collection = 'appointments'
  - Bloque/línea aproximada: ~7, ~10
- Verdad B (ruta por coach)
  - Archivo exacto: lib/data/repositories/appointment_firestore_datasource.dart
  - Clase exacta: AppointmentFirestoreDataSource
  - Metodo exacto: _appointmentsCollection
  - Variable exacta: userId
  - Bloque/línea aproximada: ~20-26
- Flujo real: dos implementaciones acceden a colecciones distintas para el mismo dominio.

## Regla SSOT-02 - Transactions
- Estado: VIOLACION DE SSOT
- Verdad A (ruta flat)
  - Archivo exacto: lib/data/repositories/transaction_repository.dart
  - Clase exacta: TransactionRepository
  - Metodo exacto: getTransactionsStream
  - Variable exacta: _collection = 'transactions'
  - Bloque/línea aproximada: ~7, ~10
- Verdad B (ruta por coach)
  - Archivo exacto: lib/data/repositories/transaction_firestore_datasource.dart
  - Clase exacta: TransactionFirestoreDataSource
  - Metodo exacto: _transactionsCollection
  - Variable exacta: userId
  - Bloque/línea aproximada: ~21-27
- Flujo real: coexisten dos caminos de acceso para la misma regla de datos.

## Regla SSOT-03 - Active cycle ID
- Estado: VIOLACION DE SSOT
- Verdad A
  - Archivo exacto: lib/features/training_feature/providers/training_plan_provider.dart
  - Clase exacta: TrainingPlanNotifier
  - Metodo exacto: generatePlanFromActiveCycle (flujo de bootstrap)
  - Variable exacta: workingClient.activeCycleId
  - Bloque/línea aproximada: ~1525, ~1590, ~1615
- Verdad B
  - Archivo exacto: lib/features/training_feature/providers/training_plan_provider.dart
  - Clase exacta: TrainingPlanNotifier
  - Metodo exacto: deletePlan
  - Variable exacta: updatedExtra.remove('activeCycleId')
  - Bloque/línea aproximada: ~2551
- Flujo real: el estado de ciclo activo se manipula tanto como propiedad estructurada como key dinámica en extra.

## Regla SSOT-04 - Sync training remoto
- Estado: IMPLEMENTACION NOMINAL NO OPERATIVA
- Evidencia
  - Archivo exacto: lib/data/repositories/clinical_records_repository.dart
  - Clase exacta: ClinicalRecordsRepository
  - Metodo exacto: pushTrainingRecord
  - Variable exacta: recordJson
  - Bloque/línea aproximada: ~310-317
- Flujo real: API pública existe para sync training, pero retorna sin ejecutar envío.

## Regla SSOT-05 - Sync queue execution
- Estado: IMPLEMENTACION NOMINAL NO OPERATIVA
- Evidencia
  - Archivo exacto: lib/core/services/sync_service.dart
  - Clase exacta: SyncService
  - Metodo exacto: _syncItem
  - Variables exactas: domain, clientId, dateKey, payload
  - Bloque/línea aproximada: ~49-57
- Flujo real: la cola procesa items, pero el branch visible termina en debugPrint.
