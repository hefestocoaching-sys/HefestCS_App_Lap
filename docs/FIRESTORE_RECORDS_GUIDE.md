# Firestore Records por Dominio - Guía de Uso

## Resumen

Este sistema extiende Firestore para soportar registros por dominio y fecha, manteniendo el documento actual de `coaches/{coachId}/clients/{clientId}` intacto.

## Estructura Firestore

```
coaches/{coachId}/
  ├── clients/{clientId}/              ← Documento principal (sin cambios)
  │   ├── anthropometry_records/
  │   │   ├── 2025-01-15/              ← dateKey como document ID
  │   │   │   ├── dateKey: "2025-01-15"
  │   │   │   ├── schemaVersion: 1
  │   │   │   ├── updatedAt: <serverTimestamp>
  │   │   │   ├── deleted: false
  │   │   │   └── payload: { ... }     ← AnthropometryRecord.toJson()
  │   │   └── 2025-01-20/
  │   ├── biochemistry_records/
  │   │   └── {yyyy-MM-dd}/
  │   ├── nutrition_records/
  │   │   └── {yyyy-MM-dd}/
  │   └── training_records/
  │       └── {yyyy-MM-dd}/
```

## Dominios Soportados

Definidos en `RecordDomain` enum:

- `anthropometry` → `anthropometry_records`
- `biochemistry` → `biochemistry_records`
- `nutrition` → `nutrition_records`
- `training` → `training_records`

## Datasources Creados

### 1. `RecordFirestoreDataSource` (Genérico)

**Ubicación:** `lib/data/datasources/remote/record_firestore_datasource.dart`

Datasource genérico que maneja la lógica común para todos los dominios.

**API:**
```dart
// Upsert record por fecha
await datasource.upsertRecordByDate(
  coachId: coachId,
  clientId: clientId,
  domain: RecordDomain.anthropometry,
  dateKey: '2025-01-15',
  payload: record.toJson(),
  deleted: false,
);

// Fetch records de un dominio
final snapshots = await datasource.fetchRecords(
  coachId: coachId,
  clientId: clientId,
  domain: RecordDomain.anthropometry,
  since: DateTime(2025, 1, 1), // Opcional
);

// Soft delete
await datasource.deleteRecord(
  coachId: coachId,
  clientId: clientId,
  domain: RecordDomain.anthropometry,
  dateKey: '2025-01-15',
);
```

### 2. `AnthropometryFirestoreDataSource` (Específico)

**Ubicación:** `lib/data/datasources/remote/anthropometry_firestore_datasource.dart`

Wrapper específico con tipado fuerte para AnthropometryRecords.

**Ejemplo de uso:**
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hcs_app_lap/data/datasources/remote/anthropometry_firestore_datasource.dart';
import 'package:hcs_app_lap/domain/entities/anthropometry_record.dart';

// 1. Inicializar datasource
final datasource = AnthropometryFirestoreDataSource(
  FirebaseFirestore.instance,
);

final coachId = FirebaseAuth.instance.currentUser!.uid;
final clientId = 'client-123';

// 2. Crear y guardar record
final record = AnthropometryRecord(
  date: DateTime(2025, 1, 15),
  weightKg: 75.5,
  heightCm: 175.0,
  waistCircNarrowest: 85.0,
  hipCircMax: 95.0,
);

await datasource.upsertAnthropometryRecord(
  coachId: coachId,
  clientId: clientId,
  record: record,
);

// 3. Actualizar record existente (misma fecha)
final updatedRecord = AnthropometryRecord(
  date: DateTime(2025, 1, 15),
  weightKg: 76.0, // Cambio
  heightCm: 175.0,
  waistCircNarrowest: 84.0, // Cambio
  hipCircMax: 95.0,
);

await datasource.upsertAnthropometryRecord(
  coachId: coachId,
  clientId: clientId,
  record: updatedRecord,
);

// 4. Fetch todos los records
final records = await datasource.fetchAnthropometryRecords(
  coachId: coachId,
  clientId: clientId,
);

for (final rec in records) {
  print('${rec.date}: ${rec.weightKg} kg');
}

// 5. Fetch records desde una fecha
final recentRecords = await datasource.fetchAnthropometryRecords(
  coachId: coachId,
  clientId: clientId,
  since: DateTime(2025, 1, 10),
);

// 6. Soft delete
await datasource.deleteAnthropometryRecord(
  coachId: coachId,
  clientId: clientId,
  date: DateTime(2025, 1, 15),
);
```

## Estructura del Documento

Cada documento en `{domain}_records/{dateKey}`:

```json
{
  "dateKey": "2025-01-15",
  "schemaVersion": 1,
  "updatedAt": Timestamp(2025-01-15T10:30:00Z),
  "deleted": false,
  "payload": {
    "date": "2025-01-15T00:00:00.000",
    "weightKg": 75.5,
    "heightCm": 175.0,
    "waistCircNarrowest": 85.0,
    "hipCircMax": 95.0,
    // ... otros campos del record
  }
}
```

## Reglas de Firestore

**Actualizado:** `firestore.rules`

```rules
match /coaches/{coachId} {
  allow read, write: if request.auth != null
                      && request.auth.uid == coachId;

  match /clients/{clientId} {
    allow read, write: if request.auth != null
                        && request.auth.uid == coachId;

    match /anthropometry_records/{dateKey} {
      allow read, write: if request.auth != null
                          && request.auth.uid == coachId;
    }

    match /biochemistry_records/{dateKey} {
      allow read, write: if request.auth != null
                          && request.auth.uid == coachId;
    }

    match /nutrition_records/{dateKey} {
      allow read, write: if request.auth != null
                          && request.auth.uid == coachId;
    }

    match /training_records/{dateKey} {
      allow read, write: if request.auth != null
                          && request.auth.uid == coachId;
    }
  }
}
```

## Smoke Test

**Ubicación:** `test/manual/anthropometry_records_firestore_test.dart`

**Ejecutar:**
```bash
# 1. Autenticarse en la app de escritorio
# 2. Ejecutar test sin skip
flutter test test/manual/anthropometry_records_firestore_test.dart
```

El test verifica:
1. ✅ Upsert de nuevo record
2. ✅ Upsert de otro record (diferente fecha)
3. ✅ Update de record existente (misma fecha)
4. ✅ Fetch todos los records
5. ✅ Soft delete
6. ✅ Verificar que soft delete funciona

## Siguientes Pasos

### Para BiochemistryRecords:

```dart
class BiochemistryFirestoreDataSource {
  final RecordFirestoreDataSource _recordDataSource;
  
  BiochemistryFirestoreDataSource(FirebaseFirestore firestore)
      : _recordDataSource = RecordFirestoreDataSource(firestore);

  Future<void> upsertBiochemistryRecord({
    required String coachId,
    required String clientId,
    required BioChemistryRecord record,
  }) async {
    final dateKey = DateFormat('yyyy-MM-dd').format(record.date);
    
    await _recordDataSource.upsertRecordByDate(
      coachId: coachId,
      clientId: clientId,
      domain: RecordDomain.biochemistry,
      dateKey: dateKey,
      payload: record.toJson(),
    );
  }

  Future<List<BioChemistryRecord>> fetchBiochemistryRecords({
    required String coachId,
    required String clientId,
    DateTime? since,
  }) async {
    final snapshots = await _recordDataSource.fetchRecords(
      coachId: coachId,
      clientId: clientId,
      domain: RecordDomain.biochemistry,
      since: since,
    );

    return snapshots
        .where((snap) => !snap.deleted)
        .map((snap) => BioChemistryRecord.fromJson(snap.payload))
        .toList();
  }
}
```

Repetir para `nutrition` y `training` dominios.

## Características Clave

1. **No destructivo:** No afecta `coaches/{coachId}/clients/{clientId}` existente
2. **Genérico:** Un datasource base para todos los dominios
3. **Tipado fuerte:** Wrappers específicos por dominio
4. **Soft delete:** Campo `deleted` en vez de eliminar documentos
5. **Schema versioning:** Campo `schemaVersion` para migraciones futuras
6. **Server timestamps:** `updatedAt` para sincronización incremental
7. **Date-based IDs:** `yyyy-MM-dd` como document ID para queries eficientes

## Notas

- **No implementado:** Pull automático ni listeners (por diseño)
- **Formato de fecha:** `yyyy-MM-dd` como document ID
- **Payload:** Resultado de `entity.toJson()` sin modificaciones
- **Timestamps:** `FieldValue.serverTimestamp()` para consistencia
