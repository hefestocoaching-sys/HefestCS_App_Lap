# A06 - NORMALIZACION, SERIALIZACION Y SCHEMA

## 1) Serializacion local
- Archivo: lib/data/datasources/local/database_helper.dart
- Evidencia:
  - Client -> JSON completo en columna clients.json.
  - payload incluye schemaVersion y migratedAt.
- Riesgo P2: evolución de schema depende de migraciones manuales y compat de fromJson.

## 2) Sanitizacion para Firestore
- Archivo: lib/data/datasources/remote/client_firestore_datasource.dart
- Evidencia:
  - sanitizeForFirestore
  - listInvalidFirestorePaths / listFirestoreAuditFindings
  - _safeJsonEncode para control de tamaño
- Hallazgo P1:
  - sanitizacion robusta, pero con politica de skip silencioso cuando payload invalido.

## 3) Filtrado de payload remoto
- Archivo: lib/data/datasources/remote/client_firestore_datasource.dart
- Evidencia:
  - _remoteExcludedKeys y _trainingExtraWhitelist
- Riesgo P1:
  - posible perdida intencional de campos entre local y remoto (no espejo completo).

## 4) Date keys y normalizacion temporal
- Archivo: lib/data/repositories/clinical_records_repository.dart
- Evidencia: DateFormat('yyyy-MM-dd') para id/dateKey remoto.
- Riesgo P2: timezone/corte diario puede variar entre cliente y backend si no se fija zona.

## 5) Conclusión
- La app prioriza seguridad de escritura y no-crash sobre consistencia estricta remota.
- El costo es deuda de observabilidad y divergencia silenciosa local-remoto.
