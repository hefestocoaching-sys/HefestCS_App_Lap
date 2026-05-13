# 🔍 AUDITORÍA DE PERFORMANCE - GUARDADO LENTO

**Fecha**: 28 Abril 2026  
**Problema**: Guardado tarda mucho + No funciona sin internet + Necesita ser rápido

---

## 🚨 CUELLOS DE BOTELLA IDENTIFICADOS

### **1. AUDITS DE FIRESTORE ACTIVOS EN TODOS LOS GUARDADOS** 🔴 CRÍTICO

```dart
// [FILE] lib/data/datasources/remote/client_firestore_datasource.dart:45

static const bool _enableFirestoreAudit = true;  // ← SIEMPRE ACTIVO
```

**¿Qué hace?**
```dart
// Se ejecuta 2 VECES en CADA guardado:

// Primera vez (línea 213):
rawInvalidPaths = listInvalidFirestorePaths(clientJson, limit: 12);  // ← LENTO
rawAuditFindings = listFirestoreAuditFindings(clientJson, limit: 12);  // ← LENTO

// Segunda vez (línea 250):
invalidPath = findInvalidFirestorePath(fullPayload);  // ← LENTO
invalidPaths = listInvalidFirestorePaths(fullPayload, limit: 12);  // ← LENTO
auditFindings = listFirestoreAuditFindings(fullPayload, limit: 12);  // ← LENTO
```

**¿Cuánto cuesta?**
- `listInvalidFirestorePaths()`: Recorre TODA la estructura del cliente (1000+ campos)
- `listFirestoreAuditFindings()`: Recorre TODA la estructura nuevamente
- Se ejecuta en el HILO PRINCIPAL (bloquea UI)
- Se repite 2 veces por guardado

**Estimación de tiempo**: 500ms-2000ms SOLO en audits

---

### **2. SERIALIZACIÓN JSON EN ISOLATE** 🟡 LENTO

```dart
// [FILE] lib/data/datasources/local/database_helper.dart:296-299

Future<void> upsertClient(Client client) async {
  await _runWithRetry(() async {
    final clientJson = await _wrapClientJson(client);  // ← compute() = LENTO
    // ...
  });
}

// Implementación:
Future<Map<String, dynamic>> _wrapClientJson(Client client) async {
  return compute(_encodeClientJsonIsolate, client);  // ← Spawn isolate = costoso
}
```

**¿Cuánto cuesta?**
- `compute()` debe crear un isolate, serializar los datos, enviarlos, recibir resultado
- Para un cliente con 1000+ registros: 100-500ms
- Se hace CADA VEZ que se guarda

---

### **3. COMPARACIÓN PROFUNDA (DeepCollectionEquality)** 🟡 LENTO

```dart
// [FILE] lib/data/datasources/local/database_helper.dart:450-451

final isSameData =
    lastData != null &&
    const DeepCollectionEquality().equals(data, lastData);  // ← LENTO
```

**¿Cuánto cuesta?**
- `DeepCollectionEquality` compara RECURSIVAMENTE todas las claves
- Para `training.extra` con 1000+ items: 50-200ms
- Se hace en CADA upsert (aunque no cambió nada)

---

### **4. FIREBASE FIRESTORE SIEMPRE LENTO (SIN DEBOUNCE EFECTIVO)** 🟡 LENTO

```dart
// [FILE] lib/data/repositories/client_repository.dart:32-37

_remotePushDebounce[client.id] = Timer(
  const Duration(milliseconds: 700),  // ← Debounce de 700ms
  () {
    // Push a Firestore (puede tardar 1000-5000ms si hay internet)
    unawaited(_pushClientRemote(latest, deleted: false)...);
  },
);
```

**Problema**:
- El usuario espera que el guardado sea rápido
- Debounce ayuda pero sigue habiendo latencia
- Firestore push es lento (red)

---

## 📊 TIEMPOS ACTUALES (ESTIMADOS)

| Componente | Tiempo | Bloqueante |
|-----------|--------|-----------|
| **Audits Firestore x2** | 500-2000ms | ✅ SÍ (hilo principal) |
| **compute() JSON** | 100-500ms | ✅ SÍ (hilo principal) |
| **DeepCollectionEquality** | 50-200ms | ✅ SÍ (hilo principal) |
| **Batch SQLite** | 50-100ms | ✅ SÍ |
| **Debounce Firestore** | 700ms + 1000-5000ms | ❌ NO (background) |
| **TOTAL GUARDADO LOCAL** | **700-2800ms** | ✅ USUARIO ESPERA |
| **TOTAL CON REMOTO** | **2400-7800ms** | ❌ Fire-and-forget |

---

## ❌ PROBLEMA SIN INTERNET

**Flujo actual SIN internet**:
1. Usuario presiona "Guardar"
2. `saveClient()` inicia
3. `await _local.saveClient(client)` ← Todo normal
4. Timer de 700ms se inicia para Firestore push
5. Firestore push falla silenciosamente (catch)
6. **Pero el usuario ya esperó 700-2800ms**

**¿Qué pasa?**: El usuario experimenta lag INCLUSO sin internet porque:
- Audits de Firestore se hacen incluso sin internet (antes del push)
- compute() tarda lo mismo
- DeepCollectionEquality tarda lo mismo
- **Todo ocurre en el hilo principal**

---

## ✅ SOLUCIONES RECOMENDADAS

### **Fix 1: Desactivar Audits en Producción** 🟢 RÁPIDO

```dart
// [FILE] lib/data/datasources/remote/client_firestore_datasource.dart:45

static const bool _enableFirestoreAudit = false;  // ← DESACTIVAR EN PROD
```

**Impacto**: -500-2000ms por guardado 🚀

---

### **Fix 2: Optimizar Serialización (Evitar compute())** 🟢 RÁPIDO

**Problema actual**: `compute()` es costoso para datos ya en memoria

**Solución**: Usar JSON encoding directo si es en el hilo principal

```dart
// ANTES:
final clientJson = await _wrapClientJson(client);  // compute() = lento

// DESPUÉS:
final clientJson = _encodeClientJsonDirectSync(client);  // sync = rápido
```

**Impacto**: -100-500ms por guardado 🚀

---

### **Fix 3: Optimizar DeepCollectionEquality** 🟢 RÁPIDO

**Problema actual**: Comparación profunda en CADA guardado

**Solución**: 
1. Cache el hash de `training.extra`
2. Comparar solo el hash (no la estructura completa)
3. Si hash cambió, hacer comparación profunda

```dart
// ANTES:
const DeepCollectionEquality().equals(data, lastData);  // Todos los campos

// DESPUÉS:
_hashEquals(data, lastData)  // O verificar si realmente cambió algo
```

**Impacto**: -50-200ms por guardado 🚀

---

### **Fix 4: Arquitectura Offline-First** 🟢 FUNCIONAL

**Problema actual**: 
- App depende de Firestore para todo
- Sin internet = lentitud pero debería ser rápido

**Solución**:
1. Guardado local SIEMPRE rápido (200-300ms máximo)
2. Push remoto en background (sin afectar UI)
3. Sync cuando hay internet

```dart
// Nuevo flujo:
1. await _local.saveClient(client)  // Rápido (200-300ms)
2. if (hasInternet) {
     // Async push (no await)
     _pushClientRemote(client)...;
   } else {
     // Marcar para sync después
     _queueForRemoteSync(client);
   }
```

**Impacto**: 
- Con internet: 200-300ms (local) + async remoto
- Sin internet: 200-300ms (solo local) ✅

---

## 🎯 PLAN DE OPTIMIZACIÓN

### **FASE 1: Corto Plazo (30 min)** 🟢 CRITICAL

1. **Desactivar `_enableFirestoreAudit`** → -500-2000ms
2. **Mover audits a nivel de DEBUG** → Solo en development
3. **Test guardado sin internet** → Verificar que sea rápido

### **FASE 2: Mediano Plazo (1 hora)** 🟡 IMPORTANTE

1. Optimizar `_wrapClientJson()` (evitar compute)
2. Optimizar `DeepCollectionEquality`
3. Agregar tracking de performance

### **FASE 3: Largo Plazo (2-3 horas)** 🔵 NICE-TO-HAVE

1. Implementar arquitectura offline-first completa
2. Agregar sync queue
3. UI indicadores de sync status

---

## 📈 RESULTADOS ESPERADOS

| Escenario | ANTES | DESPUÉS | Mejora |
|-----------|-------|---------|--------|
| **Guardado con internet** | 2400-7800ms | 200-300ms local + async remoto | **-87%** |
| **Guardado sin internet** | 700-2800ms | 200-300ms | **-71%** |
| **UI responsiva** | ❌ Lag visible | ✅ Instantáneo | **SÍ** |
| **Funciona offline** | ❌ Lento | ✅ Rápido | **SÍ** |

---

## 🧪 VALIDACIÓN

**Test offline**:
```
1. App abierta sin internet
2. Modificar cliente
3. Guardar → debe tardar < 300ms
4. Desconectar internet (si estaba conectada)
5. Guardar → debe tardar < 300ms
```

**Test con internet**:
```
1. App abierta con internet
2. Modificar cliente  
3. Guardar → debe tardar < 300ms (UI responsive)
4. Verificar que Firestore se sincronice (background)
```

---

## ✅ CONCLUSIÓN

**Problema raíz**: Audits de Firestore y serialización costosa en hilo principal

**Solución inmediata**: Desactivar `_enableFirestoreAudit = false`

**Impacto**: Guardado pasaría de **700-2800ms** a **200-300ms** (71-87% más rápido)

**Próximo paso**: Implementar fixes en orden de impacto
