# Push Granular por Dominio - Migración Completada

## Resumen

Reemplazo del push automático del cliente completo por **pushes granulares por dominio**, manteniendo el guardado local como fuente de verdad.

## Cambios Implementados

### 1. ClinicalRecordsRepository

**Archivo:** `lib/data/repositories/clinical_records_repository.dart`

Repositorio dedicado para push granular de records clínicos a Firestore.

**Métodos:**
- `pushAnthropometryRecord(clientId, record)` → `anthropometry_records/{dateKey}`
- `pushBiochemistryRecord(clientId, record)` → `biochemistry_records/{dateKey}`
- `pushNutritionRecord(clientId, recordJson, date)` → `nutrition_records/{dateKey}`
- `pushTrainingRecord(clientId, recordJson, date)` → `training_records/{dateKey}`

**Características:**
- ✅ Fire-and-forget (no lanza excepciones)
- ✅ No afecta guardado local si falla
- ✅ Push SOLO del record modificado, NO del cliente completo

### 2. Provider

**Archivo:** `lib/data/repositories/clinical_records_repository_provider.dart`

```dart
final clinicalRecordsRepositoryProvider = Provider<ClinicalRecordsRepository>(
  (ref) => ClinicalRecordsRepository(
    firestore: FirebaseFirestore.instance,
  ),
);
```

### 3. Integración en Tabs

#### AnthropometryMeasuresTab

**Archivo:** `lib/features/anthropometry_feature/widgets/anthropometry_measures_tab.dart`

```dart
await ref.read(clientsProvider.notifier).updateActiveClient((current) {
  final updated = upsertRecordByDate<AnthropometryRecord>(
    existingRecords: current.anthropometry,
    newRecord: newRecord,
    dateExtractor: (record) => record.date,
  );
  return current.copyWith(anthropometry: updated);
});

// Push granular a Firestore (fire-and-forget, no afecta guardado local)
final recordsRepo = ref.read(clinicalRecordsRepositoryProvider);
await recordsRepo.pushAnthropometryRecord(client.id, newRecord);
```

#### BiochemistryTab

**Archivo:** `lib/features/biochemistry_feature/widgets/biochemistry_tab.dart`

```dart
await ref.read(clientsProvider.notifier).updateActiveClient((current) {
  final updatedRecords = upsertRecordByDate<BioChemistryRecord>(
    existingRecords: current.biochemistry,
    newRecord: newRecord,
    dateExtractor: (record) => record.date,
  );
  return current.copyWith(biochemistry: updatedRecords);
});

// Push granular a Firestore (fire-and-forget, no afecta guardado local)
final recordsRepo = ref.read(clinicalRecordsRepositoryProvider);
await recordsRepo.pushBiochemistryRecord(client.id, newRecord);
```

### 4. Client Meta (Opcional)

**Archivo:** `lib/data/datasources/remote/client_firestore_datasource.dart`

Agregado método `upsertClientMeta()` para actualizar solo información identitaria del cliente sin re-subir todos los records:

```dart
await datasource.upsertClientMeta(
  coachId: 'coach123',
  clientId: 'client456',
  metaData: {
    'fullName': 'Juan Pérez',
    'email': 'juan@example.com',
    'phone': '+123456789',
  },
);
```

## Estructura Firestore Resultante

```
coaches/{coachId}/
  └── clients/{clientId}/
      ├── (documento principal - meta opcional)
      ├── anthropometry_records/
      │   └── 2025-01-15/
      │       ├── dateKey: "2025-01-15"
      │       ├── schemaVersion: 1
      │       ├── updatedAt: <serverTimestamp>
      │       ├── deleted: false
      │       └── payload: { ... AnthropometryRecord.toJson() }
      ├── biochemistry_records/
      │   └── 2025-01-20/
      ├── nutrition_records/
      │   └── {yyyy-MM-dd}/
      └── training_records/
          └── {yyyy-MM-dd}/
```

## Comportamiento Antes vs Después

### ❌ Antes (Push Completo)

1. Usuario guarda 1 registro de antropometría (75 KB)
2. Sistema guarda en SQLite ✅
3. Sistema sube **TODO el cliente** a Firestore (5 MB)
   - Incluye todos los records históricos
   - Incluye todos los dominios (anthro, biochem, nutrition, training)
   - Desperdicio de ancho de banda

### ✅ Después (Push Granular)

1. Usuario guarda 1 registro de antropometría (75 KB)
2. Sistema guarda en SQLite ✅
3. Sistema sube **SOLO ese registro** a Firestore (75 KB)
   - Path: `anthropometry_records/2025-01-15`
   - Solo el record modificado
   - Eficiencia óptima

## Ventajas

1. **Rendimiento:** Reducción de ~98% en datos transferidos por operación
2. **Escalabilidad:** Queries eficientes por dominio y fecha
3. **Flexibilidad:** Cada dominio puede evolucionar independientemente
4. **Resiliencia:** Fallas en Firestore NO afectan guardado local
5. **Costos:** Reducción significativa en operaciones de escritura

## Flujo de Guardado

```
1. Usuario modifica record en UI
2. Tab valida datos
3. updateActiveClient() → SQLite (fuente de verdad) ✅
4. pushXxxRecord() → Firestore (fire-and-forget) 🔥
5. Si Firestore falla → ignorar, SQLite ya tiene el dato
6. UI actualiza con datos de SQLite
```

## Patrón de Integración

Para agregar push granular a otros tabs:

```dart
// 1. Importar provider
import 'package:hcs_app_lap/data/repositories/clinical_records_repository_provider.dart';

// 2. Después de updateActiveClient
await ref.read(clientsProvider.notifier).updateActiveClient((current) {
  // ... guardar en SQLite
});

// 3. Push granular (fire-and-forget)
final recordsRepo = ref.read(clinicalRecordsRepositoryProvider);
await recordsRepo.pushXxxRecord(client.id, newRecord);
```

## Reglas Críticas

1. ✅ **Local primero:** SQLite es fuente de verdad, NUNCA falla por Firestore
2. ✅ **Fire-and-forget:** Push a Firestore NO lanza excepciones
3. ✅ **Granular:** Push SOLO el record modificado, NO el cliente completo
4. ✅ **Opcional:** Si no hay autenticación, skip push (no rompe flujo)

## Archivos Modificados

1. ✅ `lib/data/repositories/clinical_records_repository.dart` (NUEVO)
2. ✅ `lib/data/repositories/clinical_records_repository_provider.dart` (NUEVO)
3. ✅ `lib/features/anthropometry_feature/widgets/anthropometry_measures_tab.dart`
4. ✅ `lib/features/biochemistry_feature/widgets/biochemistry_tab.dart`
5. ✅ `lib/data/datasources/remote/client_firestore_datasource.dart`

## Próximos Pasos (Opcionales)

1. Integrar push granular en:
   - NutritionTab (depletion_tab.dart)
   - TrainingDashboard (training_dashboard_screen.dart)

2. Deprecar `_pushClientRemote()` en ClientRepository cuando todos los dominios migren

3. Considerar sincronización pull incremental usando `since` parameter

## Validación

```bash
flutter analyze
# ✅ 0 errors, 8 warnings (solo prints en test manual)
```

## Testing

Ver smoke test en: `test/manual/anthropometry_records_firestore_test.dart`

Ejecutar:
```bash
# 1. Autenticarse en app desktop
# 2. Ejecutar test
flutter test test/manual/anthropometry_records_firestore_test.dart
```
