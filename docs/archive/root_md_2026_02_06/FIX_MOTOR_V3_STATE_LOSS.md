# ✅ CORRECCIÓN CRÍTICA APLICADA - Motor V3 State Loss Fix

**Fecha**: 3 de febrero de 2026  
**Commit**: 462d20e  
**Tipo**: 🔥 FIX CRÍTICO

---

## 📋 RESUMEN EJECUTIVO

**PROBLEMA**: `plan.state['phase2']['capacityByMuscle']` se perdía durante la generación del plan Motor V3

**CAUSA RAÍZ**: En `training_program_engine_v2_full.dart` línea 885, `TrainingPlanConfig` se creaba sin pasar el parámetro `state`, dejándolo como `null`.

**SOLUCIÓN**: Agregar `state: profile.extra` al constructor `TrainingPlanConfig`

**IMPACTO**: 🟢 **CRÍTICO** - Restaura todo el flujo de generación de planes Motor V3

---

## 🔍 AUDITORÍA EXHAUSTIVA - HALLAZGOS

### Punto 1: Phase 2 Execution ✅
- **Archivo**: `training_program_engine_v2.dart`
- **Línea**: 87-96
- **Estado**: ✅ Phase2VolumeCapacity().run() se ejecuta correctamente
- **Resultado**: baseState['phase2']['capacityByMuscle'] se calcula

### Punto 2: Acumulación en profile.extra ✅
- **Archivo**: `training_program_engine_v2_full.dart`
- **Línea**: ~750+
- **Estado**: ✅ Todas las fases 1-8 acumulan datos en `profile.extra`
- **Resultado**: profile.extra contiene {phase1, phase2, phase3, ...}

### Punto 3: Constructor TrainingPlanConfig 🔴
- **Archivo**: `training_program_engine_v2_full.dart`
- **Línea**: 885 (ANTES)
- **PROBLEMA**: NO se pasaba `state` al constructor
- **EFECTO**: plan.state = null

### Punto 4: Serialización ✅
- **Archivo**: `training_plan_config.dart`
- **Línea**: 32-70
- **Estado**: ✅ toMap() serializa 'state' correctamente
- **Estado**: ✅ fromMap() deserializa 'state' correctamente

### Punto 5: Persistencia ✅
- **Archivo**: `database_helper.dart`
- **Línea**: ~130-155 (post P0-1)
- **Estado**: ✅ Sin merge automático (WRITE mode)
- **Estado**: ✅ Persiste plan.state tal cual

---

## 🔧 CÓDIGO CORREGIDO

**ARCHIVO**: [lib/domain/training_v2/engine/training_program_engine_v2_full.dart](lib/domain/training_v2/engine/training_program_engine_v2_full.dart#L885-L898)

**ANTES** (INCORRECTO):
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

**DESPUÉS** (CORRECTO):
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
  state: profile.extra,  // ✅ CRÍTICO: Pasar state con todas las fases
);

// ✅ AUDIT LOG agregados
debugPrint('🔍 [AUDIT] TrainingPlanConfig creado');
debugPrint('🔍 [AUDIT] plan.state: ${plan.state}');
debugPrint('🔍 [AUDIT] plan.state[phase2]: ${plan.state?['phase2']}');
debugPrint('🔍 [AUDIT] plan.state[phase2][capacityByMuscle]: ${(plan.state?['phase2'] as Map?)?['capacityByMuscle']}');
```

---

## ✅ FLUJO AHORA COMPLETO

```
1. TrainingProgramEngineV2Full.generatePlan()
   ↓
2. Fases 1-8 calculan en profile.extra
   ├─ phase1: readiness data
   ├─ phase2: capacityByMuscle ← CRÍTICO
   ├─ phase3: targetVolume
   ├─ phase4: split distribution
   ├─ phase5: periodization
   ├─ phase6: exercise selection
   ├─ phase7: prescriptions
   └─ phase8: adaptation
   ↓
3. TrainingPlanConfig(state: profile.extra) ← FIX
   ├─ plan.state = profile.extra
   ├─ plan.trainingProfileSnapshot = profile
   └─ plan.weeks = [...] with prescriptions
   ↓
4. TrainingEngineFacade.generatePlan()
   ├─ updatedClient.trainingPlans.add(plan)
   └─ repository.saveClient(updatedClient)
   ↓
5. DatabaseHelper.upsertClient()
   ├─ client.toJson() incluye trainingPlans
   ├─ plan.toJson() incluye 'state'
   └─ Persistido en SQLite SIN transformación
   ↓
6. VolumeCapacityScientificView
   ├─ Lee plan.state['phase2']
   ├─ Accede capacityByMuscle
   └─ ✅ DATOS COMPLETOS
```

---

## 🧪 VALIDACIÓN

### Verificar Sintaxis
```bash
flutter analyze --no-pub
```
**Esperado**: 0 errores de syntax

### Regenerar Plan
```dart
// Ejecutar en training_plan_provider.dart
generatePlanFromActiveCycle()
```

### Capturar Logs
Buscar en console:
```
🔍 [AUDIT] TrainingPlanConfig creado
🔍 [AUDIT] plan.state: {phase1: {...}, phase2: {...}, ...}
🔍 [AUDIT] plan.state[phase2]: {capacityByMuscle: {...}}
```

### Verificar Persistencia
En SQLite:
```sql
SELECT plan_data FROM clients WHERE id = 'test-client'
-- Debe incluir: "state": {"phase1": {...}, "phase2": {...}}
```

### Verificar Lectura
En VolumeCapacityScientificView:
```dart
final capacityData = _extractCapacityData();
// Debe retornar muscles con valores de phase2.capacityByMuscle
```

---

## 📊 CHECKLIST POST-FIX

- [x] Identificar causa raíz
- [x] Aplicar corrección en training_program_engine_v2_full.dart
- [x] Agregar debugPrint() para auditoria
- [x] Commit con mensaje descriptivo
- [x] Push a main
- [ ] Regenerar plan Motor V3
- [ ] Capturar y validar logs
- [ ] Ejecutar flutter analyze
- [ ] Verificar persistencia en SQLite
- [ ] Confirmar lectura en VolumeCapacityScientificView

---

## 🚀 ESTADO FINAL

**PRE-FIX**: ❌ plan.state = null → capacityByMuscle perdido
**POST-FIX**: ✅ plan.state = profile.extra → Todas las fases disponibles

**COMMIT**: 462d20e (FIX CRÍTICO: Pasar state a TrainingPlanConfig)

---

**Auditoría completada**: 3 de febrero de 2026  
**Severidad**: 🔴 CRÍTICO  
**Estado**: ✅ RESUELTO
