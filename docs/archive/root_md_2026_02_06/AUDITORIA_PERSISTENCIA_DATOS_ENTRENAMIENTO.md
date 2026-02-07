# 🔴 AUDITORÍA EXHAUSTIVA: PERSISTENCIA DE DATOS DE ENTRENAMIENTO

**Fecha**: 3 de febrero de 2026  
**Objetivo**: Identificar dónde Motor V2 guarda datos que interfieren con Motor V3  
**Estado**: ✅ Auditoría completada

---

## HALLAZGO CRÍTICO: **Motor V2 y Motor V3 COMPARTEN `client.training.extra`**

La persistencia tiene un **problema arquitectónico grave**: ambos motores escriben simultáneamente al mismo mapa `client.training.extra`, creando conflictos de datos y pérdidas de información.

---

## ARCHIVO 1: `lib/features/main_shell/providers/clients_provider.dart`

### Líneas Clave: 150-225

### Código Problemático:
```dart
// updateActiveClient() lines 150-225
final mergedTrainingExtra = Map<String, dynamic>.from(
  persisted.training.extra,
);
mergedTrainingExtra.addAll(updated.training.extra);

final mergedTraining = updated.training.copyWith(
  extra: mergedTrainingExtra,
);

final mergedClient = persisted.copyWith(
  profile: updated.profile,
  history: updated.history,
  nutrition: mergedNutrition,
  training: mergedTraining,
  trainingPlans: updated.trainingPlans,
  trainingWeeks: updated.trainingWeeks,
  trainingSessions: updated.trainingSessions,
  status: updated.status,
);

await _repository.saveClient(mergedClient);
```

### Problema:
- `updateActiveClient()` hace **merge superficial** de `training.extra`
- Si UI actualiza `training.extra['key1']`, se copia a la BD
- **NO hay lógica de limpieza** de claves antiguas de Motor V2
- Motor V2 data persiste indefinidamente en la BD aunque Motor V3 esté activo

### Evidencia:
- Línea 158-168: `mergeTrainingExtra` suma AMBOS diccionarios sin eliminar deprecated keys
- Esto mantiene vivo `activePlanId` (Motor V2), `mevByMuscle`, `targetSetsByMuscle` incluso después de regeneración

### Solución:
```dart
final mergedTrainingExtra = Map<String, dynamic>.from(
  persisted.training.extra,
);
mergedTrainingExtra.addAll(updated.training.extra);

// ✅ AGREGAR: Eliminar claves legacy de Motor V2
const legacyV2Keys = [
  'activePlanId',  // Motor V2 solo
  'mevByMuscle',   // Motor V2 output
  'mrvByMuscle',   // Motor V2 output
  'mavByMuscle',   // Motor V2 output
];
legacyV2Keys.forEach(mergedTrainingExtra.remove);

final mergedTraining = updated.training.copyWith(
  extra: mergedTrainingExtra,
);
```

---

## ARCHIVO 2: `lib/features/training_feature/providers/training_plan_provider.dart`

### Líneas Clave: 864-1200 (método `generatePlanFromActiveCycle`)

### SUBPROBLEMA 2A: Limpieza Parcial de Plan

**Líneas**: 1029-1044

#### Código Problemático:
```dart
// Línea 1029
final hasActivePlanId =
    workingClient.training.extra[TrainingExtraKeys.activePlanId] != null;

if (workingClient.trainingPlans.isNotEmpty || hasActivePlanId) {
  debugPrint(
    '♻️ [Motor V2] Forzando regeneración del plan: limpiando semanas previas',
  );

  final updatedExtra = Map<String, dynamic>.from(
    workingClient.training.extra,
  )..remove(TrainingExtraKeys.activePlanId);  // ← SOLO elimina activePlanId

  workingClient = workingClient.copyWith(
    training: workingClient.training.copyWith(extra: updatedExtra),
    trainingPlans: const [],  // ← Borra planes
  );

  await ref.read(clientRepositoryProvider).saveClient(workingClient);

  debugPrint('✅ [Motor] Plan limpiado en SQLite, recargando...');

  // ✅ CRÍTICO: Recargar desde SQLite
  workingClient =
      await ref.read(clientRepositoryProvider).getClientById(clientId) ??
      workingClient;

  debugPrint(
    '🔍 [Motor] Verificación post-limpieza: trainingPlans.length=${workingClient.trainingPlans.length}',
  );
}
```

#### Problema:
- **Línea 1036**: Solo elimina `activePlanId`, pero NO elimina:
  - `mevByMuscle`, `mrvByMuscle`, `mavByMuscle` (cálculos volumétricos Motor V2)
  - `targetSetsByMuscle` (distribución de series Motor V2)
  - `mevTable`, `seriesTypePercentSplit` (metadata)
  
- Estos datos **persisten en `training.extra`** y pueden interferir con Motor V3 al leer datos

#### Evidencia:
- Línea 1147 usa `training.extra[TrainingExtraKeys.mevByMuscle]` → si no se limpió, puede tener valores stale
- Línea 1098 crea `VopContext` con extra sin garantía de limpieza previa
- El plan se regenera pero `training.extra` mantiene "ruido" de la generación anterior

### SUBPROBLEMA 2B: `training.extra` se modifica en Facade sin sincronización

**Líneas**: En `lib/domain/training/facade/training_engine_facade.dart` (110-155)

#### Código Problemático:
```dart
// training_engine_facade.dart línea 110-155
// 3. Actualizar training.extra con SSOT del ciclo: activePlanId
final updatedExtra = Map<String, dynamic>.from(client.training.extra);
updatedExtra[TrainingExtraKeys.activePlanId] = normalizedPlanConfig.id;

// Nota: NO borramos nada del extra, solo escribimos activePlanId.
final updatedTraining = client.training.copyWith(extra: updatedExtra);

final updatedClient = client.copyWith(
  training: updatedTraining,
  trainingPlans: updatedTrainingPlans,  // ← Planes en trainingPlans
  trainingWeeks: updatedTrainingWeeks,
  trainingSessions: updatedTrainingSessions,
);

// 5. GUARDAR EN REPOSITORIO (commit)
await repository.saveClient(updatedClient);

// 6. Retornar el plan recién generado (es el vigente por definición del SSOT)
return normalizedPlanConfig;
```

#### Problema:
- **Línea 152**: Comentario explícito **"NO borramos nada del extra"**
- Motor V3 guarda plan en `client.trainingPlans` (correcto)
- Pero en `training.extra` quedan **datos obsoletos de generaciones previas**
- Si usuario regenera 3 veces: `extra` acumula 3 generaciones de `mevByMuscle`, `targetSetsByMuscle`, etc.

#### Evidencia:
- Línea 152 del comentario: literalmente dice que NO limpia extra
- Esto explica por qué VolumeCapacityScientificView a veces lee datos stale

### Solución para training_plan_provider.dart:

**En generatePlanFromActiveCycle (línea 1036)**:
```dart
final updatedExtra = Map<String, dynamic>.from(
  workingClient.training.extra,
);

// ✅ AGREGAR: Eliminar TODAS las claves de Motor V2 antes de regenerar
const legacyV2Keys = [
  'activePlanId',
  'mevByMuscle',
  'mrvByMuscle', 
  'mavByMuscle',
  'targetSetsByMuscle',
  'mevTable',
  'seriesTypePercentSplit',
];
legacyV2Keys.forEach(updatedExtra.remove);

workingClient = workingClient.copyWith(
  training: workingClient.training.copyWith(extra: updatedExtra),
  trainingPlans: const [],
);

await ref.read(clientRepositoryProvider).saveClient(workingClient);
```

---

## ARCHIVO 3: `lib/domain/entities/client.dart`

### Líneas Clave: 150-400 (serialización)

### Código Problemático:
```dart
// Línea 250-260 (toJson)
Map<String, dynamic> toJson() => {
  'id': id,
  'profile': profile.toJson(),
  'history': history.toJson(),
  'training': training.toJson(),
  'nutrition': nutrition.toJson(),
  'createdAt': createdAt.toIso8601String(),
  'updatedAt': updatedAt.toIso8601String(),
  'status': status.name,

  'trainingHistory': trainingHistory?.toJson(),
  'nutritionHistory': nutritionHistory?.toJson(),

  'anthropometry': anthropometry.map((e) => e.toJson()).toList(),
  'biochemistry': biochemistry.map((e) => e.toJson()).toList(),
  'tracking': tracking.map((e) => e.toJson()).toList(),

  'trainingPlans': trainingPlans.map((e) => e.toJson()).toList(),
  'trainingWeeks': trainingWeeks.map((e) => e.toJson()).toList(),
  'trainingSessions': trainingSessions.map((e) => e.toJson()).toList(),
  'trainingLogs': trainingLogs.map((e) => e.toJson()).toList(),
  'sessionLogs': sessionLogs.map((e) => e.toJson()).toList(),

  'trainingCycles': trainingCycles.map((e) => e.toMap()).toList(),
  'activeCycleId': activeCycleId,

  'trainingEvaluation': trainingEvaluation?.toJson(),
  'exerciseMotivation': exerciseMotivation?.toJson(),
  'gluteSpecializationProfile': gluteSpecializationProfile?.toJson(),

  'mobilityAssessments': mobilityAssessments.map((e) => e.toJson()).toList(),
  'movementPatternAssessments': movementPatternAssessments.map((e) => e.toJson()).toList(),
  'strengthAssessments': strengthAssessments.map((e) => e.toJson()).toList(),
  'volumeToleranceProfiles': volumeToleranceProfiles.map((e) => e.toJson()).toList(),
  'psychologicalTrainingProfiles': psychologicalTrainingProfiles.map((e) => e.toJson()).toList(),

  'paidWeeks': paidWeeks,
  'invitationCode': invitationCode,
};

// Línea 200-220 (fromJson)
factory Client.fromJson(Map<String, dynamic> json) {
  return Client(
    id: json['id'] as String,

    profile: ClientProfile.fromJson(
      json['profile'] is String
          ? jsonDecode(json['profile'])
          : json['profile'],
    ),

    history: ClinicalHistory.fromJson(
      json['history'] is String
          ? jsonDecode(json['history'])
          : json['history'],
    ),

    training: json['training'] != null
        ? TrainingProfile.fromJson(
            json['training'] is String
                ? jsonDecode(json['training'])
                : json['training'],
          )
        : TrainingProfile.empty(),

    nutrition: NutritionSettings.fromJson(
      json['nutrition'] is String
          ? jsonDecode(json['nutrition'])
          : json['nutrition'],
    ),
    // ...
  );
}
```

### Problema:
- Client serializa `training.extra` junto con `trainingPlans`
- **Ambos se persisten en la misma fila de BD**: en la columna `json` de tabla `clients`
- No hay separación entre:
  - Motor V2 data: `training.extra['mevByMuscle']`
  - Motor V3 data: `trainingPlans[0].state['phase2']`

### Evidencia:
- Línea 340: `'training': training.toJson()` guarda el Training completo con `extra`
- Línea 341: `'trainingPlans': trainingPlans.map(...).toList()` guarda planes en lista
- Si `trainingPlans` está vacío pero `training.extra` tiene mevByMuscle de generación anterior, coexisten

### Problema Arquitectónico:
No hay **"marker de eliminación"** para saber cuándo limpiar `training.extra`. Sistema no distingue entre:
- `extra` legítimo (p.ej., `activePlanId` del plan actual)
- `extra` obsoleto (p.ej., `mevByMuscle` de un plan que ya no existe)

---

## ARCHIVO 4: `lib/features/training_feature/screens/training_dashboard_screen.dart`

### Líneas Clave: 100-115

### Código Problemático:
```dart
// Línea 104
final activePlanId =
    client.training.extra[TrainingExtraKeys.activePlanId] as String?;

if (activePlanId == null) {
  return _buildNoPlanState(client);
}

// Línea 110
final plan = client.trainingPlans
    .cast<TrainingPlanConfig?>()
    .firstWhere((p) => p?.id == activePlanId, orElse: () => null);

if (plan == null) {
  return _buildPlanNotFoundState(activePlanId);
}

// ✅ RENDERIZAR TABS MOTOR V3
return _buildMotorV3Workspace(plan, client);
```

### Problema:
- **Línea 104**: Lee `activePlanId` de **`training.extra`** (Motor V2 location)
- Debería leer de SSOT que es `trainingPlans[0].id` (más reciente por fecha)
- Si `activePlanId` en extra es de una generación anterior, **puede no existir** en `trainingPlans` actual
- Resultado: pantalla muestra "Plan no encontrado" aunque Motor V3 generó planes nuevos

### Evidencia:
- El botón "Regenerar" (línea 189) llama `_regenerarPlan()` → `generatePlanFromActiveCycle()`
- Pero después de regenerar, el `activePlanId` antiguo en `extra` puede no coincidir con nuevo plan
- Race condition: si dos regeneraciones ocurren rápidamente, `extra` puede quedar stale

### Solución:
```dart
// Línea 104 — CAMBIAR DE ESTO:
// ❌ final activePlanId = client.training.extra[TrainingExtraKeys.activePlanId] as String?;
// if (activePlanId == null) {
//   return _buildNoPlanState(client);
// }
// final plan = client.trainingPlans
//     .cast<TrainingPlanConfig?>()
//     .firstWhere((p) => p?.id == activePlanId, orElse: () => null);

// ✅ A ESTO:
// Usar SSOT: último plan por fecha
final plan = client.trainingPlans.isEmpty 
    ? null 
    : client.trainingPlans.reduce(
        (a, b) => a.startDate.isAfter(b.startDate) ? a : b,
      );

if (plan == null) {
  return _buildNoPlanState(client);
}

// El activePlanId ya no es necesario — usamos el plan actual directamente
return _buildMotorV3Workspace(plan, client);
```

---

## ARCHIVO 5: `lib/data/repositories/client_repository.dart`

### Líneas Clave: 10-40

### Código (Correcto):
```dart
class ClientRepository {
  final LocalClientDataSource _local;
  final ClientRemoteDataSource _remote;

  ClientRepository({
    required LocalClientDataSource local,
    required ClientRemoteDataSource remote,
  }) : _local = local,
       _remote = remote;

  // === Local operations with remote push ===
  Future<void> saveClient(Client client) async {
    // 1) Guardado local (fuente de verdad)
    await _local.saveClient(client);

    // 2) Push remoto inmediato (fire-and-forget)
    await _pushClientRemote(client, deleted: false);
  }

  Future<List<Client>> getClients() => _local.getAllClients();

  Future<Client?> getClientById(String id) => _local.fetchClient(id);

  Future<void> deleteClient(String id) async {
    // 1) Obtener cliente antes de eliminar (para push con deleted:true)
    final client = await _local.fetchClient(id);
    if (client == null) return;

    // 2) Eliminación local (soft-delete)
    await _local.deleteClient(id);

    // 3) Push remoto inmediato (marcar como deleted en Firestore)
    await _pushClientRemote(client, deleted: true);
  }

  /// Helper privado: push silencioso a Firestore (no rompe flujos locales)
  Future<void> _pushClientRemote(Client client, {required bool deleted}) async {
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (_) {
      // Firebase no inicializado (p.ej. tests). La fuente de verdad es local.
      return;
    }
    if (user == null) return; // Sin usuario autenticado, no hay push

    try {
      await _remote.upsertClient(
        coachId: user.uid,
        client: client,
        deleted: deleted,
      );
    } catch (e) {
      // Ignorar error: Firestore es réplica, no fuente de verdad
      // El cambio ya está en SQLite (guardado localmente)
    }
  }
}
```

### Análisis:
- ✅ El repositorio **está correcto**: local es SSOT, Firestore es réplica
- ✅ No hay lógica de migración fallida aquí

**PERO**: El problema es que **`_local.saveClient()` (DatabaseHelper) hace merge automático**

---

## ARCHIVO 6: `lib/data/datasources/local/database_helper.dart` - **CRÍTICO**

### Líneas Clave: 120-155

### Código Problemático:
```dart
class DatabaseHelper {
  // ...

  /// PROBLEMA CRÍTICO: Merge automático mantiene datos stale
  Future<void> upsertClient(Client client) async {
    final db = await database;

    // BLINDAJE CRÍTICO: Hacer merge de extra antes de guardar
    // Esto asegura que NO se pierdan datos clínicos en actualizaciones parciales
    Client clientToSave = client;

    // Intentar obtener cliente previo para hacer merge de extra
    try {
      final clientId = client.id;
      if (clientId.isNotEmpty) {
        final existing = await getClientById(clientId);
        if (existing != null) {
          // ❌ PROBLEMA: Hace DEEP merge de extra con datos previos
          final mergedExtra = deepMerge(
            existing.training.extra,      // ← Datos VIEJOS
            client.training.extra,        // ← Datos NUEVOS
          );

          final mergedTraining = client.training.copyWith(extra: mergedExtra);

          // Importante: conservar el training NUEVO (client.training) y solo mergear el extra
          final mergedTraining = client.training.copyWith(extra: mergedExtra);

          // Crear Client con Training actualizado
          clientToSave = client.copyWith(training: mergedTraining);

          // 🔍 VALIDACIÓN: Confirmar merge
          debugPrint('💾 SQLite upsert - training.extra merge:');
          debugPrint(
            '   yearsTrainingContinuous: ${mergedExtra['yearsTrainingContinuous']}',
          );
          debugPrint(
            '   sessionDurationMinutes: ${mergedExtra['sessionDurationMinutes']}',
          );
          debugPrint(
            '   restBetweenSetsSeconds: ${mergedExtra['restBetweenSetsSeconds']}',
          );
          debugPrint('   avgSleepHours: ${mergedExtra['avgSleepHours']}');
        }
      }
    } catch (_) {
      // Si falla la lectura, usar cliente tal como viene (no es crítico)
    }

    await db.insert(
      'clients',
      _wrapClientJson(clientToSave),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Client?> getClientById(String id) async {
    final db = await database;
    final result = await db.query(
      'clients',
      where: 'id = ? AND isDeleted = 0',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return _unwrapClientJson(result.first);
  }

  Future<List<Client>> getAllClients() async {
    final db = await database;
    final result = await db.query('clients', where: 'isDeleted = 0');
    return result.map(_unwrapClientJson).toList();
  }

  Future<void> softDeleteClient(String id) async {
    final db = await database;
    await db.update(
      'clients',
      {"isDeleted": 1, "updatedAt": DateTime.now().toIso8601String()},
      where: "id = ?",
      whereArgs: [id],
    );
  }

  Future<void> markClientAsSynced(String id) async {
    final db = await database;
    await db.update(
      'clients',
      {"isSynced": 1},
      where: "id = ?",
      whereArgs: [id],
    );
  }

  Future<List<Client>> getUnsyncedClients() async {
    final db = await database;
    final result = await db.query(
      'clients',
      where: 'isSynced = 0 AND isDeleted = 0',
    );
    return result.map(_unwrapClientJson).toList();
  }

  // --- Compat helpers (mantienen API usada en otras capas) ---
  Future<void> insertClient(Client client) => upsertClient(client);

  Future<void> updateClient(Client client) => upsertClient(client);
}
```

### Problema CRÍTICO:
- **Línea 135-140**: `deepMerge(existing.extra, client.extra)` **SUMA** diccionarios
- `deepMerge` NO elimina claves que existían en `existing` pero NO en `client.extra`
- Resultado: **Datos obsoletos de Motor V2 NUNCA se borran** de la BD

### Ejemplo de Escenario:
1. Motor V2 genera plan → guarda `mevByMuscle: {chest: 12, back: 14}` en extra
2. Motor V3 regenera → no incluye `mevByMuscle` en nuevo extra
3. `deepMerge` ve:
   - `existing.extra` tiene `mevByMuscle: {chest: 12, back: 14}`
   - `client.extra` no tiene `mevByMuscle`
4. `deepMerge` mantiene el `mevByMuscle` viejo
5. **Datos stale persisten para siempre en la BD**

### Evidencia:
- Línea 135: `deepMerge(existing.training.extra, client.training.extra)`
- `deepMerge` es una unión (union), NO una reemplazo (replacement)
- Si `existing` tiene 50 claves y `client` tiene 30, resultado tiene 50+ claves

### Solución DEFINITIVA:
**NO hacer merge automático en upsertClient**. Dejar que la capa superior (providers) controle la limpieza:

```dart
Future<void> upsertClient(Client client) async {
  final db = await database;
  
  // ✅ Simplemente guardar el cliente tal como viene
  // Sin merge automático — el provider es responsable de limpieza de legacy keys
  
  await db.insert(
    'clients',
    _wrapClientJson(client),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}
```

---

## RESPUESTAS A PREGUNTAS ESPECÍFICAS

### 1️⃣ **¿Cuándo se ejecuta `generatePlanFromActiveCycle()`, elimina `client.training.extra` COMPLETAMENTE?**

**RESPUESTA**: ❌ **NO** — Línea 1036 de training_plan_provider.dart:
```dart
final updatedExtra = Map<String, dynamic>.from(workingClient.training.extra);
updatedExtra.remove(TrainingExtraKeys.activePlanId);  // ← Solo elimina activePlanId
```

**Detalles**:
- **Solo elimina una clave** (`activePlanId`)
- Deja intactos: `mevByMuscle`, `targetSetsByMuscle`, `mrvByMuscle`, `mavByMuscle`
- Estos datos **interfieren con siguiente lectura**
- El comentario en línea 1028 dice "limpiando semanas previas" pero solo limpia 1 clave

---

### 2️⃣ **¿Existe lógica que COPIA datos de Motor V2 a Motor V3 (migración)?**

**RESPUESTA**: ❌ **NO hay migración explícita** — Pero hay **contaminación accidental**:

```dart
// training_plan_provider.dart línea 1147
final mevRaw =
    planConfig.trainingProfileSnapshot?.extra[TrainingExtraKeys
        .mevByMuscle] ??
    workingClient.training.extra[TrainingExtraKeys.mevByMuscle];  // ← Fallback a extra viejo
```

**Detalles**:
- Si existe `training.extra[mevByMuscle]` de generación anterior, se usa (aunque sea stale)
- No hay indicador de "estos datos son de 5 días atrás"
- Contamina el plan nuevo con datos volumétricos obsoletos

---

### 3️⃣ **¿TrainingDashboardScreen lee PRIMERO de `client.training.extra` o de `client.trainingPlans`?**

**RESPUESTA**: ❌ **Lee de extra PRIMERO** — Línea 104:

```dart
final activePlanId =
    client.training.extra[TrainingExtraKeys.activePlanId] as String?;

if (activePlanId == null) {
  return _buildNoPlanState(client);
}

final plan = client.trainingPlans
    .cast<TrainingPlanConfig?>()
    .firstWhere((p) => p?.id == activePlanId, orElse: () => null);
```

**Detalles**:
- Debería ser: **Lee de trainingPlans** (SSOT más reciente por fecha)
- `activePlanId` en extra es stale después de regenerar
- Si el plan no existe, muestra error aunque haya planes nuevos en `trainingPlans`

---

### 4️⃣ **¿El botón "Regenerar" ejecuta `generatePlanFromActiveCycle()` CORRECTAMENTE?**

**RESPUESTA**: ⚠️ **Sí pero con datos stale** — Línea 189 (training_dashboard_screen.dart):

```dart
void _regenerarPlan() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Regenerar Plan'),
      content: Text('¿Regenerar plan completo Motor V3?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _generarPlan();  // ← Llama generatePlanFromActiveCycle()
          },
          child: Text('Regenerar'),
        ),
      ],
    ),
  );
}

void _generarPlan() async {
  try {
    final now = DateTime.now();
    await ref
        .read(trainingPlanProvider.notifier)
        .generatePlanFromActiveCycle(now);
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar plan: $e'),
          backgroundColor: kErrorColor,
        ),
      );
    }
  }
}
```

**Detalles**:
- ✅ Ejecuta correctamente
- ❌ Pero `training.extra` aún contiene datos de regeneración anterior
- ❌ Nueva generación puede leer `training.extra[TrainingExtraKeys.mevByMuscle]` stale (línea 1147)

---

### 5️⃣ **¿Firestore persiste AMBOS `client.training.extra` Y `client.trainingPlans` (duplicación)?**

**RESPUESTA**: ✅ **SÍ, duplicación completa**:

```dart
// client_firestore_datasource.dart línea 106
Future<void> upsertClient({
  required String coachId,
  required Client client,
  required bool deleted,
}) async {
  // El payload contiene el Client.toJson() completo, sanitizado para Firestore
  final clientJson = client.toJson();  // ← Incluye training.extra Y trainingPlans

  final fullPayload = <String, dynamic>{
    'payload': clientJson,
    'deleted': deleted,
    'timestamp': FieldValue.serverTimestamp(),
  };

  debugPrint(
    '[Firestore] Upserting client=$clientId',
  );
  debugPrint(
    '   training.extra keys: ${client.training.extra.keys.join(', ')}',
  );
  debugPrint(
    '   trainingPlans: ${client.trainingPlans.length} plans',
  );

  await _db
      .collection('coaches')
      .doc(coachId)
      .collection('clients')
      .doc(clientId)
      .set(fullPayload, SetOptions(merge: true));
}
```

**Detalles**:
- `client.training.extra` → Guardado en `training.toJson()` (Firestore colección `coaches/{coachId}/clients`)
- `client.trainingPlans` → Guardado en `trainingPlans.toJson()` (misma colección)
- Ambos en el **mismo documento Firestore**
- Resultado: **Si existen datos de 3 generaciones en extra, todas se replican a Firestore**
- Firestore esencialmente **replica el problema** de la BD local

---

## 📋 RESUMEN ARQUITECTÓNICO

| Aspecto | Motor V2 | Motor V3 | Problema |
|---------|----------|----------|----------|
| **Ubicación de datos** | `training.extra` | `trainingPlans[].state` | ❌ Comparten `training.extra` |
| **Limpieza en regeneración** | Parcial (solo activePlanId) | ❌ No limpia | ❌ Datos stale persisten |
| **SSOT para plan activo** | `training.extra['activePlanId']` | ❌ No implementado | ❌ Leer de extra es stale |
| **Merge en BD** | ✅ No (ya desactivo) | ❌ deepMerge suma claves | ❌ Imposible limpiar |
| **Firestore sync** | ✅ Correcto (réplica) | ✅ Correcto | ❌ Replica datos stale también |
| **Race conditions** | ⚠️ Posibles | ⚠️ Posibles | ❌ Sin locking explícito |

---

## 🔧 PLAN DE CORRECCIÓN (ORDEN DE PRIORIDAD)

### **P0 - CRÍTICO** (Causa bugs ahora):

#### 1. **Eliminar `deepMerge` de `database_helper.upsertClient()`**
- **Archivo**: `lib/data/datasources/local/database_helper.dart`
- **Líneas**: 126-155
- **Acción**: Borrar bloque try/catch que hace merge automático
- **Razón**: Imposibilita limpiar datos stale de Motor V2

#### 2. **Limpiar TODAS las claves Motor V2 en `generatePlanFromActiveCycle()`**
- **Archivo**: `lib/features/training_feature/providers/training_plan_provider.dart`
- **Líneas**: 1036
- **Acción**: Agregar eliminación de claves legacy
- **Razón**: Impide contaminación de nuevo plan con datos obsoletos

### **P1 - IMPORTANTE** (Previene bugs futuros):

#### 3. **Cambiar SSOT de activePlan en TrainingDashboardScreen**
- **Archivo**: `lib/features/training_feature/screens/training_dashboard_screen.dart`
- **Líneas**: 104-115
- **Acción**: Leer de `trainingPlans` (más reciente por fecha) en lugar de `training.extra['activePlanId']`
- **Razón**: Evita mostrar "Plan no encontrado" cuando existen planes nuevos

#### 4. **Eliminar comentario engañoso en training_engine_facade.dart**
- **Archivo**: `lib/domain/training/facade/training_engine_facade.dart`
- **Líneas**: 152
- **Acción**: Cambiar comentario o agregar limpieza
- **Razón**: Documentar el comportamiento correcto

### **P2 - DEUDA TÉCNICA**:

#### 5. Crear constante para listar qué limpiar
```dart
// core/constants/training_extra_keys.dart
abstract class TrainingExtraLegacyV2Keys {
  static const String activePlanId = 'activePlanId';
  static const String mevByMuscle = 'mevByMuscle';
  static const String mrvByMuscle = 'mrvByMuscle';
  static const String mavByMuscle = 'mavByMuscle';
  static const String targetSetsByMuscle = 'targetSetsByMuscle';
  static const String mevTable = 'mevTable';
  static const String seriesTypePercentSplit = 'seriesTypePercentSplit';
  
  static const List<String> allKeys = [
    activePlanId,
    mevByMuscle,
    mrvByMuscle,
    mavByMuscle,
    targetSetsByMuscle,
    mevTable,
    seriesTypePercentSplit,
  ];
}
```

#### 6. Documentar que `training.extra` es legacy
- Agregar JSDoc comentarios en `TrainingProfile` explicando que `extra` es para datos legacy
- Motor V3 NUNCA debe escribir en `extra`, solo leer si existe

---

## 📝 CONCLUSIÓN

El problema fundamental es que **Motor V2 y Motor V3 no tienen separación clara de ubicaciones de datos**. Motor V2 usa `training.extra`, Motor V3 usa `trainingPlans[].state`, pero el merge automático en la BD y la falta de limpieza explícita causa que datos obsoletos persistan.

**La solución requiere 2 cambios nucleares**:
1. **Eliminar merge automático en BD** → Delegar responsabilidad a providers
2. **Limpiar claves Motor V2 en regeneración** → Garantizar que "extra" no tenga datos stale

Sin estos cambios, Tab Volumen seguirá mostrando datos incorrectos y el sistema será propenso a race conditions.
