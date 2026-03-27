# A02 - MAPA DE ARQUITECTURA REAL (NO TEORICA)

## 1) Flujo macro observado
UI Widgets/Screen -> Providers/Notifiers Riverpod -> Repositories -> Datasources Local/Remote -> SQLite/Firestore

## 2) Capa de entrada (UI)
- Main shell: lib/features/main_shell/screen/main_shell_screen.dart
- Modulos saveables: implementan contrato SaveableModule (saveIfDirty/resetDrafts)
- Evidencia: metodo _allModules + _saveActiveModuleIfNeeded (bloque aprox lineas 160-220)

## 3) Capa de estado y orquestacion
- Clients state central: lib/features/main_shell/providers/clients_provider.dart
- Evidencia:
  - updateActiveClient (aprox linea 140+) mezcla merge de nutrition/training extras y persiste via repository
  - uso de _clientWriteLocks para serializar escrituras por cliente

## 4) Capa de repositorios
- Cliente local-first + remote push debounce:
  - lib/data/repositories/client_repository.dart
  - saveClient (linea ~23), _pushClientRemote (linea ~99)
- Registros clinicos granulares:
  - lib/data/repositories/clinical_records_repository.dart
  - pushAnthropometryRecord/pushBiochemistryRecord/pushNutritionRecord/pushTrainingRecord
- Nutricion por snapshots:
  - lib/data/repositories/nutrition_plan_repository.dart

## 5) Capa de datasource
- Local SQLite:
  - lib/data/datasources/local/database_helper.dart
  - lib/data/datasources/local/sync_queue_helper.dart
- Remote Firestore:
  - lib/data/datasources/remote/client_firestore_datasource.dart
  - lib/data/datasources/remote/record_firestore_datasource.dart

## 6) Hallazgos de arquitectura (clasificados)
- P0: SSOT local fuerte, pero sync remoto degradado por silencios y desactivaciones de sesion.
- P1: Duplicidad de rutas de datos para appointments/transactions.
- P1: Mezcla de responsabilidades (UI + regla de negocio + persistencia) en widgets/providers grandes.
- P2: Feature flags estaticos no tipados dinamicamente (compilacion, no runtime remoto).

## 7) Ejemplos concretos de mezcla de capas
- equivalents_by_day_screen.dart: saveIfDirty persiste estructura de datos y seleccion activa en nutrition.extra.
- training_workspace_screen.dart: acciones de negocio (generar/regenerar/adaptar/eliminar) disparadas directo desde screen.
- anthropometry_measures_tab.dart y biochemistry_tab.dart: generan records + escriben cliente + push remoto granular.
