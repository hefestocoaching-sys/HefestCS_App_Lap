# T06 - SINCRONIZACION, OFFLINE Y DEGRADACION

## Comportamiento real de sync
1. Save local es obligatorio y primero.
2. Push remoto de cliente es fire-and-forget con debounce.
3. Si Firestore devuelve `permission-denied`, se desactiva sync remota en la sesion.
4. Sync queue service procesa solo domain `anthropometry` en la version auditada.
5. Push de training records en `ClinicalRecordsRepository` esta deshabilitado (return inmediato).

Evidencia:
- lib/data/repositories/client_repository.dart:23
- lib/data/repositories/client_repository.dart:28
- lib/data/repositories/client_repository.dart:107
- lib/core/services/sync_service.dart:47
- lib/data/repositories/clinical_records_repository.dart:306

## Filtrado remoto de training.extra
Al sincronizar cliente completo, `ClientFirestoreDataSource` filtra `training.extra` por whitelist.

Riesgo:
- Campos de entrenamiento no whitelisteados no se reflejan remoto.
- Puede haber divergencia local/remoto sin error funcional local.

Evidencia:
- lib/data/datasources/remote/client_firestore_datasource.dart:55
- lib/data/datasources/remote/client_firestore_datasource.dart:150

## Clasificacion
- DEGRADACION SILENCIOSA:
  - Desactivacion de sync remota por sesion sin detener flujo local.
  - Push training granular deshabilitado sin bloqueo de UX.
  - Queue processor sin branch training.
