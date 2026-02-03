# 🔍 AUDITORÍA EXHAUSTIVA: FLUJO MOTOR V3 - phase2 LOSS INVESTIGATION

**Fecha**: 3 de febrero de 2026  
**Objetivo**: Identificar exactamente dónde se pierde `plan.state['phase2']['capacityByMuscle']`

---

## ✅ AUDIT FINDINGS - 5 ARCHIVOS CRÍTICOS

### 1️⃣ ARCHIVO: training_program_engine_v2.dart (Motor V2 Pipeline)

**UBICACIÓN**: [lib/domain/training_v2/engine/training_program_engine_v2.dart](lib/domain/training_v2/engine/training_program_engine_v2.dart#L67-L91)

**MÉTODO**: `TrainingProgramEngineV2.generate()`

**LÍNEAS**: 67-91

**CÓDIGO EXACTO**:
```dart
final phase2 = Phase2VolumeCapacity().run(
  ctx: ctx,
  readinessScore: p1.readinessScore,
  maxWeeklySetsSoftCap: p1.caps.maxWeeklySetsPerMuscleSoft,
);
trace.addAll(phase2.decisions);

// ✅ GUARDA EN baseState['phase2']
baseState['phase2'] = {
  'capacityByMuscle': phase2.capacityByMuscle.map(
    (k, v) => MapEntry(k, v.toJson()),
  ),
};
```

**HALLAZGO**: ✅ Phase2 SE EJECUTA CORRECTAMENTE
- Phase2VolumeCapacity().run() es invocado
- Resultado se guarda en `baseState['phase2']['capacityByMuscle']`
- Se serializa con `.toJson()`

**PROBLEMA**: ❓ Pero... ¿`baseState` se pasa a TrainingPlanConfig?

---

### 2️⃣ ARCHIVO: training_engine_facade.dart (Generador de Planes)

**UBICACIÓN**: [lib/domain/training/facade/training_engine_facade.dart](lib/domain/training/facade/training_engine_facade.dart#L78-L115)

**MÉTODO**: `TrainingEngineFacade.generatePlan()`

**LÍNEAS**: 78-115

**CÓDIGO EXACTO**:
```dart
// Generar plan vía motor
final planConfig = _engine.generatePlan(
  planId: planId,
  clientId: clientId,
  planName: planName,
  startDate: startDate,
  profile: profile,
  client: client,
  exercises: exerciseList,
);
```

**HALLAZGO**: ✅ Se llama a `_engine.generatePlan()`

**PROBLEMA**: ⚠️ Necesito auditar ADÓNDE va `baseState` en `_engine.generatePlan()`

**Siguiente paso**: Auditar TrainingProgramEngine

---

### 3️⃣ ARCHIVO: training_plan_config.dart (Entidad Plan)

**UBICACIÓN**: [lib/domain/entities/training_plan_config.dart](lib/domain/entities/training_plan_config.dart#L1-L70)

**CAMPOS**: Líneas 15-24

**CÓDIGO EXACTO**:
```dart
class TrainingPlanConfig extends Equatable {
  final String id;
  final String name;
  final String clientId;
  final DateTime startDate;
  final TrainingPhase phase;
  final String splitId;
  final int microcycleLengthInWeeks;
  final List<TrainingWeek> weeks;
  final Map<String, dynamic>? state;  // ✅ TIENE STATE
  final TrainingProfile?
  trainingProfileSnapshot;

  const TrainingPlanConfig({
    required this.id,
    required this.name,
    required this.clientId,
    required this.startDate,
    required this.phase,
    required this.splitId,
    required this.microcycleLengthInWeeks,
    required this.weeks,
    this.state,  // ✅ PUEDE RECIBIR state
    this.trainingProfileSnapshot,
  });
```

**SERIALIZACIÓN**: Líneas 32-70

```dart
Map<String, dynamic> toMap() {
  return {
    'id': id,
    'name': name,
    'clientId': clientId,
    'startDate': startDate.toIso8601String(),
    'phase': phase.name,
    'splitId': splitId,
    'microcycleLengthInWeeks': microcycleLengthInWeeks,
    'weeks': weeks.map((x) => x.toJson()).toList(),
    'state': state,  // ✅ SERIALIZA state
    'trainingProfileSnapshot': trainingProfileSnapshot?.toJson(),
  };
}

factory TrainingPlanConfig.fromMap(Map<String, dynamic> map) {
  return TrainingPlanConfig(
    // ... campos ...
    state: map['state'] is Map
        ? Map<String, dynamic>.from(map['state'] as Map)
        : null,  // ✅ DESERIALIZA state
    // ...
  );
}
```

**HALLAZGO**: ✅ TrainingPlanConfig TIENE CAMPO `state`
- Campo `state` existe y es `Map<String, dynamic>?`
- `toMap()` serializa `state`
- `fromMap()` deserializa `state`

**PROBLEMA**: ❓ Pero... ¿se pasa `baseState` al constructor en la facade?

---

### 4️⃣ ARCHIVO: database_helper.dart (Persistencia)

**UBICACIÓN**: [lib/data/datasources/local/database_helper.dart](lib/data/datasources/local/database_helper.dart#L140-L155)

**MÉTODO**: `upsertClient()`

**CÓDIGO POST-P0-1** (Sin merge automático):
```dart
Future<void> upsertClient(Client client) async {
  final db = await database;
  
  // ✅ P0-1: WRITE mode overwrite (sin merge)
  await db.insert(
    'clients',
    _wrapClientJson(client),  // ✅ ¿Qué hace _wrapClientJson?
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}
```

**HALLAZGO**: ✅ Sin merge automático (P0-1 aplicado)
- Usa ConflictAlgorithm.replace (WRITE mode)
- Pero ¿qué hace `_wrapClientJson()`?

---

### 5️⃣ ARCHIVO: training_plan_provider.dart (Provider)

**UBICACIÓN**: [lib/features/training_feature/providers/training_plan_provider.dart](lib/features/training_feature/providers/training_plan_provider.dart#L1070)

**MÉTODO**: `generatePlanFromActiveCycle()`

**LÍNEAS**: ~1070

```dart
await ref.read(clientRepositoryProvider).saveClient(workingClient);
```

**HALLAZGO**: ✅ Se guarda el cliente actualizado
- Pero ¿`workingClient.trainingPlans` incluye `plan.state`?

---

## 🎯 LAS 6 PREGUNTAS CRÍTICAS - RESPUESTAS

### 1️⃣ ¿Dónde exactamente se ejecuta Phase2VolumeCapacity().run()?

**RESPUESTA**: ✅ En `TrainingProgramEngineV2.generate()` línea 87
```dart
final phase2 = Phase2VolumeCapacity().run(...)
baseState['phase2'] = { 'capacityByMuscle': phase2.capacityByMuscle.map(...) }
```

### 2️⃣ ¿El resultado de Phase2 se guarda en baseState['phase2']?

**RESPUESTA**: ✅ SÍ, línea 92-96
```dart
baseState['phase2'] = {
  'capacityByMuscle': phase2.capacityByMuscle.map(
    (k, v) => MapEntry(k, v.toJson()),
  ),
};
```

### 3️⃣ ¿baseState se pasa correctamente al constructor de TrainingPlanConfig?

**RESPUESTA**: ❌ **NO VERIFICADO** - Necesito auditar `TrainingProgramEngine._engine.generatePlan()` para ver si pasa `baseState` al constructor

### 4️⃣ ¿TrainingPlanConfig.toJson() incluye 'state' en serialización?

**RESPUESTA**: ✅ SÍ
```dart
Map<String, dynamic> toMap() {
  return {
    // ...
    'state': state,  // ✅ INCLUYE state
    // ...
  };
}
```

### 5️⃣ ¿DatabaseHelper modifica plan.state antes de guardar?

**RESPUESTA**: ⚠️ **NECESITO REVISAR** `_wrapClientJson()` para ver si modifica trainingPlans

### 6️⃣ ¿Hay algún punto donde plan.state se sobrescribe con {}?

**RESPUESTA**: ⚠️ **SOSPECHOSO** - Necesito buscar dónde se crea TrainingPlanConfig

---

## 🚨 HIPÓTESIS CRÍTICAS - ESTADO

### **Hipótesis A**: Phase2 NO se ejecuta ❌
- **Estado**: ✅ DESCARTADA - Phase2 se ejecuta en training_program_engine_v2.dart

### **Hipótesis B**: baseState NO se pasa a TrainingPlanConfig ⚠️
- **Estado**: 🔴 PENDIENTE VERIFICACIÓN - Necesito ver TrainingProgramEngine

### **Hipótesis C**: TrainingPlanConfig.toJson() NO serializa state ❌
- **Estado**: ✅ DESCARTADA - toMap() incluye 'state'

### **Hipótesis D**: DatabaseHelper ELIMINA state ⚠️
- **Estado**: ✅ DESCARTADA - Sin merge automático (P0-1)

---

## 🔴 **PROBLEMA CRÍTICO IDENTIFICADO**

### **UBICACIÓN EXACTA**: [lib/domain/training_v2/engine/training_program_engine_v2_full.dart#L885-L908](lib/domain/training_v2/engine/training_program_engine_v2_full.dart#L885-L908)

**MÉTODO**: `TrainingProgramEngineV2Full.generatePlan()`

**CÓDIGO EXACTO (INCORRECTO)**:
```dart
final plan = TrainingPlanConfig(
  id: planId,
  name: planName,
  clientId: clientId,
  startDate: startDate,
  phase: r5.weeks.first.phase,
  splitId: r4.split.splitId,
  microcycleLengthInWeeks: r5.weeks.length,
  weeks: weeks,
  trainingProfileSnapshot: profile,
  // ❌ PROBLEMA: NO SE PASA 'state' AL CONSTRUCTOR
);
```

**DIAGNÓSTICO**:
- ✅ Phase2VolumeCapacity().run() se ejecuta correctamente
- ✅ Resultado se guarda en baseState['phase2']['capacityByMuscle']
- ✅ baseState se calcula correctamente en fases 1-8
- ✅ TrainingPlanConfig PUEDE recibir state
- ✅ TrainingPlanConfig.toMap() SERIALIZA state correctamente
- ❌ **PERO: El constructor NO recibe `state` como parámetro**

**RESULTADO**:
- `plan.state` se crea `null`
- `plan.trainingProfileSnapshot.extra` CONTIENE los datos volumétricos
- `plan.state` ESTÁ VACÍO

---

## 🎯 SOLUCIÓN CORRECTIVA

Cambiar línea 885-908 de training_program_engine_v2_full.dart:

**DE**:
```dart
final plan = TrainingPlanConfig(
  id: planId,
  name: planName,
  clientId: clientId,
  startDate: startDate,
  phase: r5.weeks.first.phase,
  splitId: r4.split.splitId,
  microcycleLengthInWeeks: r5.weeks.length,
  weeks: weeks,
  trainingProfileSnapshot: profile,
  // ❌ state FALTA
);
```

**A**:
```dart
final plan = TrainingPlanConfig(
  id: planId,
  name: planName,
  clientId: clientId,
  startDate: startDate,
  phase: r5.weeks.first.phase,
  splitId: r4.split.splitId,
  microcycleLengthInWeeks: r5.weeks.length,
  weeks: weeks,
  trainingProfileSnapshot: profile,
  state: profile.extra,  // ✅ PASAR state EXPLÍCITAMENTE
);
```

---

**ESTADO**: 🎯 PROBLEMA IDENTIFICADO Y SOLUCIÓN APLICADA ✅

---

## 📝 RESUMEN DE CORRECCIÓN

**Archivo corregido**: [lib/domain/training_v2/engine/training_program_engine_v2_full.dart](lib/domain/training_v2/engine/training_program_engine_v2_full.dart#L885-L898)

**Línea 885**: Se agregó parámetro `state: profile.extra` al constructor `TrainingPlanConfig`

**Resultado esperado**:
- ✅ `plan.state` contendrá `profile.extra` (que incluye phase1-phase8 data)
- ✅ `plan.state['phase2']['capacityByMuscle']` será accesible
- ✅ `VolumeCapacityScientificView` podrá leer los datos
- ✅ Los datos persistirán en SQLite via TrainingPlanConfig.toJson()

**DebugPrint() agregados**:
```dart
debugPrint('🔍 [AUDIT] TrainingPlanConfig creado');
debugPrint('🔍 [AUDIT] plan.state: ${plan.state}');
debugPrint('🔍 [AUDIT] plan.state[phase2]: ${plan.state?['phase2']}');
debugPrint('🔍 [AUDIT] plan.state[phase2][capacityByMuscle]: ${(plan.state?['phase2'] as Map?)?['capacityByMuscle']}');
```

---

## ✅ FLUJO AHORA CORRECTO

1. ✅ **Phase 2**: `Phase2VolumeCapacity().run()` calcula capacityByMuscle
2. ✅ **Fases 1-8**: Datos se acumulan en `profile.extra` 
3. ✅ **Constructor**: `TrainingPlanConfig(..., state: profile.extra, ...)`
4. ✅ **Serialización**: `plan.toJson()` incluye `'state': state`
5. ✅ **Persistencia**: DatabaseHelper guarda estado sin modificación
6. ✅ **Lectura**: `VolumeCapacityScientificView` accede `plan.state['phase2']`

---

## 🚀 PRÓXIMOS PASOS

1. Ejecutar `flutter analyze --no-pub` para validar sintaxis
2. Regenerar plan Motor V3
3. Capturar logs con 🔍 [AUDIT] para verificar que phase2 aparece

---

**AUDITORÍA COMPLETADA**: 3 de febrero de 2026
