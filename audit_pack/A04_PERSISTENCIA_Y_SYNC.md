# A04 - PERSISTENCIA Y SYNC (FORENSE)

## 1) Persistencia local (SQLite)
- Archivo: lib/data/datasources/local/database_helper.dart
- Evidencia:
  - Tabla clients (json, isSynced, isDeleted, updatedAt).
  - Enable WAL, busy_timeout, foreign_keys.
  - Ensure de tabla sync_queue en onOpen/onCreate/onUpgrade.
- Conclusión: la base local esta bien establecida como SSOT operativo.

## 2) Cola de sync
- Archivo: lib/data/datasources/local/sync_queue_helper.dart
- Evidencia:
  - getPendingItems(where retry_count < 5)
  - markFailure incrementa retry_count y guarda error_message
- Riesgo P1:
  - items con retry_count >= 5 dejan de salir como pendientes sin estrategia de replay/manual recovery.

## 3) Servicio de sync periodico
- Archivo: lib/core/services/sync_service.dart
- Evidencia:
  - start() cada 5 minutos + primer barrido inmediato.
  - _syncItem actualmente solo hace debugPrint para anthropometry (linea ~49+).
- Hallazgo P0:
  - pipeline de cola existe, pero la ejecucion real de push por item no esta implementada de forma completa.

## 4) Repositorio cliente local-first
- Archivo: lib/data/repositories/client_repository.dart
- Evidencia:
  - saveClient: primero _local.saveClient, luego push remoto con debounce 700ms.
  - _pushClientRemote: captura errores y no rompe flujo local.
  - _remoteSyncTemporarilyDisabled = true en permission-denied (linea ~121).
- Hallazgo P0:
  - ante permission-denied, la sesion desactiva sync remoto para todo cliente y no se observa reintento de re-habilitacion automatica.

## 5) Remoto Firestore de cliente
- Archivo: lib/data/datasources/remote/client_firestore_datasource.dart
- Evidencia:
  - Sanitiza payload, filtra keys, audita invalid paths.
  - Si hay hallazgos de auditoria, retorna sin lanzar (skip).
- Hallazgo P1:
  - múltiples early-return de seguridad evitan crash, pero facilitan degradacion silenciosa de replicacion.

## 6) Registros clinicos granulares
- Archivo: lib/data/repositories/clinical_records_repository.dart
- Evidencia:
  - pushAnthropometryRecord/pushBiochemistryRecord/pushNutritionRecord en background.
  - pushTrainingRecord retorna inmediatamente (sync training deshabilitado temporal).
- Hallazgo P0:
  - dominio training no replica a Firestore por diseno actual (desactivado).
