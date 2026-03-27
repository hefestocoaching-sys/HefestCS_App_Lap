# A03 - FLUJOS E2E REALES (EVIDENCIA MATERIAL)

## Flujo 01 - Guardado transversal al cambiar contexto
- Archivo exacto: lib/features/main_shell/screen/main_shell_screen.dart
- Clase exacta: MainShellScreen
- Metodo exacto: _saveActiveModuleIfNeeded
- Variable exacta: module (iteracion de _allModules)
- Bloque/línea aproximada: ~179, ~194-195
- Flujo real:
  1) La pantalla itera todos los modulos saveables.
  2) Ejecuta await module.saveIfDirty() por cada modulo.
  3) El guardado se dispara desde capa UI/screen antes de navegar.
- Marca forense: LOGICA EN CAPA ERRONEA (orquestacion de persistencia en screen UI).

## Flujo 02 - Persistencia local-first de cliente + push remoto diferido
- Archivo exacto: lib/data/repositories/client_repository.dart
- Clase exacta: ClientRepository
- Metodo exacto: saveClient
- Variable exacta: _pendingRemotePush, _remotePushDebounce
- Bloque/línea aproximada: ~23-35
- Flujo real:
  1) Guarda primero en datasource local (_local.saveClient).
  2) Agenda push remoto con debounce de 700ms.
  3) El push remoto corre fire-and-forget.

## Flujo 03 - Guardado remoto silencioso por payload inválido
- Archivo exacto: lib/data/datasources/remote/client_firestore_datasource.dart
- Clase exacta: ClientFirestoreDataSource
- Metodo exacto: upsertClient
- Variable exacta: hasAuditIssues, rawInvalidPaths, rawAuditFindings, invalidPath
- Bloque/línea aproximada: ~259-278
- Flujo real:
  1) Se audita payload con find/list invalid paths.
  2) Si hasAuditIssues=true, se registra warning.
  3) Se hace return sin excepción.
- Marca forense: GUARDADO SILENCIOSO.

## Flujo 04 - Cola de sync con implementación nominal
- Archivo exacto: lib/core/services/sync_service.dart
- Clase exacta: SyncService
- Metodo exacto: _syncItem
- Variables exactas: domain, clientId, dateKey, payload
- Bloque/línea aproximada: ~49-57
- Flujo real:
  1) Lee datos del item de cola.
  2) Solo branch domain == 'anthropometry'.
  3) Solo ejecuta debugPrint, no write remoto.
- Marca forense: IMPLEMENTACION NOMINAL NO OPERATIVA.

## Flujo 05 - Push de training deshabilitado
- Archivo exacto: lib/data/repositories/clinical_records_repository.dart
- Clase exacta: ClinicalRecordsRepository
- Metodo exacto: pushTrainingRecord
- Variable exacta: recordJson
- Bloque/línea aproximada: ~310-317
- Flujo real:
  1) Metodo expuesto para push training.
  2) Contiene comentario temporal.
  3) Retorna inmediatamente.
- Marca forense: IMPLEMENTACION NOMINAL NO OPERATIVA.

## Flujo 06 - Guardado nutrición desde Screen
- Archivo exacto: lib/features/nutrition_feature/screens/equivalents_by_day_screen.dart
- Clase exacta: _EquivalentsByDayScreenState
- Metodo exacto: saveIfDirty
- Variables exactas: mergedExtra, updatedRecords, displayedDateIso
- Bloque/línea aproximada: ~86, ~105-121
- Flujo real:
  1) Screen serializa payload del provider.
  2) Escribe directamente en clientsProvider.updateActiveClient.
  3) Actualiza claves nutrition.extra (equivalentsRecords/equivalentsByDay/selectedEquivalentsRecordDateIso).
- Marca forense: LOGICA EN CAPA ERRONEA.

## Flujo 07 - Selección "latest" por orden lexicográfico
- Archivo exacto: lib/features/training_feature/providers/training_plan_provider.dart
- Clase exacta: TrainingPlanNotifier
- Metodo exacto: _latestRecordByDate
- Variable exacta: latestDate, recordDate
- Bloque/línea aproximada: ~199-212
- Flujo real:
  1) Recorre records y compara strings con recordDate.compareTo(latestDate).
  2) No parsea DateTime en ese método.
  3) Depende de normalización previa del string forDateIso.
- Marca forense: LATEST SENSIBLE A NORMALIZACION DE STRING.

## Flujo 08 - Ordenamiento de registros con fallback a DateTime.now
- Archivo exacto: lib/features/nutrition_feature/screens/equivalents_by_day_screen.dart
- Clase exacta: _EquivalentsByDayScreenState
- Metodo exacto: _buildEquivalentsHistoryGrid
- Variable exacta: dateA, dateB, recordDate
- Bloque/línea aproximada: ~242-243 y ~300
- Flujo real:
  1) Intenta parsear dateIso.
  2) Si falla parse, usa DateTime.now().
  3) El orden y la selección pueden depender del instante actual.
- Marca forense: NORMALIZACION INCONSISTENTE / LATEST POTENCIALMENTE INCORRECTO.

## Flujo 09 - Degradación silenciosa en gate de autenticación
- Archivo exacto: lib/features/auth/presentation/auth_gate.dart
- Clase exacta: AuthGate
- Metodo exacto: build
- Variable exacta: authStream
- Bloque/línea aproximada: ~17-20
- Flujo real:
  1) Intenta crear authStateChanges.
  2) Si falla, captura excepción.
  3) Retorna LoginScreen sin cortar la app.
- Marca forense: DEGRADACION SILENCIOSA.
