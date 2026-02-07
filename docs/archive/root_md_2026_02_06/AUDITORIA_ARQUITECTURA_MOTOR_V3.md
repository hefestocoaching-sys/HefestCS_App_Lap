# 📋 AUDITORÍA ARQUITECTÓNICA — Motor V3 + SSOT

**Fecha:** 5 de febrero de 2026  
**Estado:** ✅ Compilando | Motor V3 Intacto | Riesgos Documentados  
**Scope:** Unificación de contratos, aislamiento legacy, normalización muscular

---

## 1. MAPA DE ARQUITECTURA REAL

```
┌─────────────────────────────────────────────────────────────────────┐
│ MOTOR V3 (Domain puro — SIN TOCAR)                                  │
├─────────────────────────────────────────────────────────────────────┤
│ • MotorV3Orchestrator (orquestación científica)                      │
│ • VolumeEngine (MEV/MAV/MRV calculations)                            │
│ • volume_engine.dart ✅ LOCKED                                       │
│ • Status: Genera volumePerMuscle con 14 músculos                     │
└─────────────────────────────────────────────────────────────────────┘
                              ↓ OUTPUT
┌─────────────────────────────────────────────────────────────────────┐
│ SSOT: TrainingPlanConfig                                             │
│ (lib/domain/entities/training_plan_config.dart)                      │
├─────────────────────────────────────────────────────────────────────┤
│ Campos válidos para UI:                                              │
│ • phase: TrainingPhase enum                                          │
│ • splitId: String                                                    │
│ • microcycleLengthInWeeks: int                                       │
│ • volumePerMuscle: Map<String, int> ← lats, upper_back, traps...    │
│ • landmarks: Map<String, VolumeInfo>?                               │
│ • weeklyVolumeTarget: int?                                           │
│ • weeks: List<TrainingWeek>                                          │
│ • startDate: DateTime                                                │
└─────────────────────────────────────────────────────────────────────┘
                      ↓ CONSUMIDO SOLO POR
┌─────────────────────────────────────────────────────────────────────┐
│ UI V3 LAYER (Features — Lectura Pura)                               │
├─────────────────────────────────────────────────────────────────────┤
│ ✅ VolumeCapacityScientificView                                      │
│    └── Lee: plan.volumePerMuscle, plan.phase, plan.state['split']   │
│                                                                      │
│ ✅ VolumeRangeMuscleTableV3                                          │
│    └── Lee: plan.volumePerMuscle, plan.landmarks                    │
│                                                                      │
│ ✅ SeriesBreakdownTable                                              │
│    └── Lee: plan.volumePerMuscle, plan.weeks                        │
│                                                                      │
│ ✅ WeeklyPlanDetailView                                              │
│    └── Lee: plan.weeks, plan.sessions, plan.volumePerMuscle         │
│                                                                      │
│ ✅ training_dashboard_screen.dart (V3)                              │
│    └── Única lectura: TrainingPlanConfig                            │
└─────────────────────────────────────────────────────────────────────┘
                         ↓ LEGACY (AISLADO)
┌─────────────────────────────────────────────────────────────────────┐
│ MAPPER COMPAT + LEGACY ARTIFACTS                                     │
├─────────────────────────────────────────────────────────────────────┤
│ • TrainingPlanProvider (compat layer)                               │
│   └── Convierte: TrainingPlanConfig → GeneratedPlan (Motor V2)      │
│                                                                      │
│ • GeneratedPlan (Motor V2 struct)                                   │
│   └── Mantiene compat con pantallas legacy antiguas                 │
│                                                                      │
│ • phase2, phase3 (Motor V2 artifacts)                               │
│   └── NO generados por Motor V3, solo para legacy                   │
│                                                                      │
│ • volume_range_muscle_table.dart                                    │
│   └── Lee: state['phase2'], state['phase3'] (deprecated)            │
│                                                                      │
│ • training_dashboard_screen_legacy.dart                             │
│   └── Usa GeneratedPlan (deprecated)                                │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 2. TABLA DE CONTRATOS REALES

| Pantalla / Widget | Fuente de Datos | Tipo Acceso | Riesgo | Estado | Acción |
|---|---|---|---|---|---|
| **training_dashboard_screen.dart** | `TrainingPlanConfig` | Lectura pura | ✅ BAJO | V3 ✅ | Mantener |
| **VolumeCapacityScientificView** | `plan.volumePerMuscle` | Lectura pura | ✅ BAJO | V3 ✅ | Mantener |
| **VolumeRangeMuscleTableV3** | `plan.volumePerMuscle` | Lectura pura | ✅ BAJO | V3 ✅ | Mantener |
| **SeriesBreakdownTable** | `TrainingPlanConfig` | Lectura pura | ✅ BAJO | V3 ✅ | Mantener |
| **WeeklyPlanDetailView** | `plan.weeks, plan.sessions` | Lectura pura | ✅ BAJO | V3 ✅ | Mantener |
| **training_dashboard_screen_legacy.dart** | `state['phase3']`, `GeneratedPlan` | Lectura legacy | ⚠️ ALTO | Legacy ⚠️ | Aislar con @deprecated |
| **volume_range_muscle_table.dart** | `state['phase2']`, `state['phase3']` | Lectura legacy | ⚠️ ALTO | Legacy ⚠️ | Marcar LEGACY |
| **SeriesDistributionEditor** | `trainingExtra` → local state | Mod local | ⚠️ ALTO | NO V3 ❌ | Sin contrato |
| **training_plan_provider.dart** | Mapper V3→V2 | Compat layer | 🔴 CRÍTICO | OK ✅ | Documentar |
| **intensity_split_table.dart** | `normalizeMuscleKey()` | Call SSOT | ✅ BAJO | OK ✅ | Mantener |

---

## 3. HALLAZGOS CRÍTICOS (PRIORIDADES)

### 🔴 P0 — DIVERGENCIA MUSCULAR EN NORMALIZACIÓN

**PROBLEMA:**
Existen DOS normalizadores con reglas DIFERENTES en el codebase:

**1. CENTRAL (SSOT correcto):**
```dart
// lib/core/utils/muscle_key_normalizer.dart
String normalizeMuscleKey(String raw)
  └── Usa: MuscleRegistry (SOURCE OF TRUTH)
  └── 14 músculos canónicos soportados
```
- Importado en **12 archivos** (UI, providers, validators)
- Normaliza variantes clínicas → claves canónicas
- Ejemplos: "espalda alta" → "upper_back", "dorsales" → "lats"

**2. LOCAL (CONFLICTIVO):**
```dart
// lib/domain/entities/training_profile.dart:751
static String _normalizeMuscleKey(String raw)
  └── Hardcoded map con reglas propias
  └── DIVERGE del SSOT central
```
- Mapeos specificos:
  - `'espalda'` → `'lats'` (por defecto, pero NO a `'upper_back'`)
  - `'hombros'` → `'deltoide_lateral'` (por defecto, pero NO a otros deltoides)
- Usado SOLO en: `training_profile.normalize()`

**IMPACTO:**
```
Usuario selecciona "espalda" en entrevista
    ↓
training_selection_widget.dart → guarda 'back'
    ↓
training_profile → normaliza a 'lats' (LOCAL RULE)
vs.
training_plan_provider → normaliza usando SSOT Registry
    ↓
RESULTADO INCONSISTENTE EN volumePerMuscle
    └── Puede faltar 'upper_back' porque fue mapeado a 'lats'
```

**RIESGO CIENTÍFICO:**
- Plan genera volumen SOLO para lats, no para upper_back
- Usuario cree que espalda alta será trabajada
- Falta estímulo a escápulas (romboides, etc)

**CHECKLIST DE CORRECCIÓN:**
- [ ] Auditar dónde se llama `training_profile._normalizeMuscleKey()`
- [ ] Verificar si training_plan_provider puede recibir prioridades sin normalizar
- [ ] Decidir: centralizar en `muscle_key_normalizer.dart` O documentar divergencia
- [ ] Tests: genera plan → `volumePerMuscle` contiene SOLO keys canónicas

---

### 🔴 P0 — CRITERIO DE PLAN ACTIVO AMBIGUO

**PROBLEMA:**
El sistema NO tiene criterio unificado para seleccionar el "plan activo".

**HALLAZGO 1: Carga de plan persistido**
```dart
// training_plan_provider.dart:204
Future<void> loadPersistedActivePlanIfAny() {
  // (A) Priorizar activePlanId if exists
  final activeConfig = _findActivePlanConfigById(client);
  // (B) Si no: usar plan más reciente por startDate
  final chosen = activeConfig ?? _findLatestPlan(client.trainingPlans);
}
```
✅ Lógica clara en este método.

**HALLAZGO 2: Generación de plan**
```dart
// training_plan_provider.dart:450
void generatePlan(...) {
  // Si ya existe plan para esa fecha: retorna el persistido
  // Si no: genera uno nuevo
  
  // ⚠️ PERO: NO actualiza activePlanId después de generar
}
```
❌ Plan nuevo se genera pero NO se activa ("activePlanId" no cambia).

**HALLAZGO 3: FAB (Floating Action Button)**
```dart
// training_dashboard_screen.dart
floatingActionButton: FloatingActionButton(
  onPressed: () => generatePlan(),
  // ⚠️ Después de generar, ¿cuál es el plan activo?
  // Esperado: el que acaba de generar
  // Real: sigue siendo el anterior (activePlanId no cambió)
)
```

**EJEMPLO DE BUG:**
```
Paso 1: 10:00 — generar plan A
        └── activePlanId = "plan_A_uuid"
        └── plan A se muestra en UI ✅

Paso 2: 10:05 — FAB presionado → generatePlan()
        └── Genera plan B (mismo día)
        └── Plan B renderizado en UI ✅
        
        PERO:
        └── activePlanId aún = "plan_A_uuid" ❌
        └── Si user abre "Planes anteriores" → Plan A aparece como activo ❌

Paso 3: User cierra/abre dashboard
        └── loadPersistedActivePlanIfAny() → carga plan A (activePlanId)
        └── UI muestra plan A, no plan B
        └── User confundido: "¿Dónde fue mi plan nuevo?" ❌
```

**RIESGO OPERACIONAL:**
- Confusión sobre cuál plan está activo
- Múltiples planes sin criterio claro de prioridad
- FAB behavior no intuitivo

**CHECKLIST DE CORRECCIÓN:**
- [ ] Documentar regla oficial:
  ```
  Plan activo = activePlanId si existe en training.extra
            OR más reciente por startDate (DESC)
            OR null si no hay planes
  ```
- [ ] FAB → después de generar, llamar `updateActivePlanId(newPlan.id)`
- [ ] Tests: FAB genera → `activePlanId` actualizado automáticamente
- [ ] UI feedback: mostrar badge "Este es el plan activo"

---

### 🟡 P1 — TAB INTENSIDADES SIN CONTRATO V3

**PROBLEMA:**
`SeriesDistributionEditor` está fuera del flujo v3, cambios se ignoran.

**HALLAZGO:**
```dart
// series_distribution_editor.dart:9
class SeriesDistributionEditor extends StatefulWidget {
  final Map<String, dynamic> trainingExtra;
  final Function(Map<String, int>) onDistributionChanged;
  
  // Lee desde trainingExtra['seriesTypePercentSplit']
  // Modifica SOLO trainingExtra (local state)
  // ❌ NO conectado a TrainingPlanConfig
  // ❌ NO conectado a Motor V3 intensity engine
}
```

**¿QUÉ FALTA?**
- Si user selectiona "80% series pesadas" en tab intensidades
- Motor V3 genera plan **ignorando** ese valor
- Cambios se guardan en trainingExtra pero nunca se leen

**ESTADO:**
- ✅ Compila sin errores
- ⚠️ Funciona "en el vacío" (sin persistencia de efecto)
- 🔴 Usuario cree que su selección importa (pero no)

**CHECKLIST DE DECISIÓN:**
- [ ] **OPCIÓN 1:** Conectar a Motor V3
  - [ ] SeriesDistributionEditor lee desde `plan.seriesDistribution`
  - [ ] onDistributionChanged → actualiza plan vía provider
  - [ ] Motor V3 respeta % en step de intensidad
  
- [ ] **OPCIÓN 2:** Deshabilitar (experimental)
  - [ ] Agregar `@deprecated` annotation
  - [ ] Label: "UI experimental — cambios no persisten"
  - [ ] Deshabilitar tab en production

**DECISIÓN PENDIENTE:** ¿Cuál es la intención para esta feature?

---

### 🟡 P1 — UI LEGACY USA state[...] SIN MARCAR

**PROBLEMA:**
Código legacy accede a `state['phase3']` sin advertencia clara.

**HALLAZGO:**
```dart
// volume_range_muscle_table.dart:9
/// LEGACY - Esta versión lee phase2/phase3 que NO son generados por Motor V3.
/// Extrae datos de planJson.state.phase2 y phase3 (LEGACY).

// Línea 97:
final phase3 = state['phase3'] as Map<String, dynamic>?;
```

**ESTADO:**
- ✅ No usado en widgets V3
- ✅ Motor V3 no genera phase3
- ⚠️ Pero puede confundir si código se reutiliza
- ⚠️ Sin `@deprecated` annotations

**CHECKLIST:**
- [ ] Agregar `@deprecated` a toda la clase
- [ ] Agregar comentario: "Use VolumeRangeMuscleTableV3 en su lugar"
- [ ] NO eliminar (compat legacy)

---

## 4. LISTA CENTRALIZADA DE RIESGOS

| ID | Severidad | Área | Descripción | Impacto | Estado |
|---|---|---|---|---|---|
| **MUS-001** | 🔴 P0 | Normalización | Dos normalizadores divergentes (central vs local en training_profile) | Volumen inconsistente, músculos faltantes | **Documentado** ❌ Pendiente corrección |
| **ACT-001** | 🔴 P0 | Plan Activo | Criterio ambiguo + FAB no actualiza activePlanId | Usuario confundido, plan incorrecto seleccionado | **Documentado** ❌ Pendiente corrección |
| **INT-001** | 🟡 P1 | Intensidades | Tab intensidades sin contrato V3, cambios se ignoran | False sense of control, feature no funciona | **Documentado** ❌ Decisión pendiente |
| **LEG-001** | 🟡 P1 | Legacy UI | volume_range_muscle_table.dart lee state[phase3] sin @deprecated | Confusión de mantenimiento | **Documentado** ❌ Aislar |
| **IMP-001** | ✅ OK | Imports | UI NO importa training_v3/models/training_plan_config | N/A — Correcto | **VERIFICADO** ✅ |
| **ISO-001** | ✅ OK | Aislamiento | Motor V3 intacto, legacy aislado, V3 no depende de legacy | N/A — Estable | **VERIFICADO** ✅ |

---

## 5. CHECKLIST DE MIGRACIÓN SEGURA (SIN BREAKING CHANGES)

### PRE-REQUISITOS OBLIGATORIOS

```
Antes de CUALQUIER corrección:

✓ [ ] Git: Commit limpio (sin cambios pendientes)
✓ [ ] Build: flutter analyze = 0 errores
✓ [ ] Test: Smoke test dashboard V3 sin crashes
✓ [ ] Backup: Copiar/documentar estado actual
```

---

### FASE A: NORMALIZACIÓN MUSCULAR (corregir MUS-001)

**Dependencias:** Ninguna (independiente)

```
ACCIÓN 1: Auditar flujo de prioridades
  □ Rastrear: training_profile.extra → training_plan_provider
  □ Log: ¿dónde se normaliza? ¿con qué función?
  □ Documento: comparar normalizaciones (central vs local)

ACCIÓN 2: Centralizar (RECOMENDADO)
  □ En training_profile._normalizeMuscleKey():
    - Replace local hardcoded map
    - Call: normalizeMuscleKey(raw) [SSOT central]
  □ Tests: prioridades → keys canónicas correctas
  □ Validación: volumePerMuscle contiene solo 14 keys

ACCIÓN 3: Testing
  □ Caso 1: user selecciona "espalda" → volumePerMuscle tiene lats + upper_back
  □ Caso 2: user selecciona "hombros" → volumePerMuscle tiene 3 deltoides
  □ Caso 3: generar plan → verificar volumePerMuscle keys

ACCIÓN 4: Rollback plan
  □ Si test falla: git checkout training_profile.dart
  □ Documentar qué salió mal
```

---

### FASE B: PLAN ACTIVO (corregir ACT-001)

**Dependencias:** Ninguna (independiente)

```
ACCIÓN 1: Documentar regla oficial
  □ En training_plan_provider.dart (comentario top):
    """
    REGLA DE PLAN ACTIVO (SSOT):
    Plan activo = activePlanId si existe en training.extra
             OR plan más reciente por startDate (DESC)
             OR null si no hay planes
    """

ACCIÓN 2: Actualizar FAB
  □ En training_dashboard_screen.dart:
    onPressed: () async {
      final newPlan = await generatePlan();
      if (newPlan != null) {
        updateActivePlanId(newPlan.id);  // ← NUEVA LÍNEA
      }
    }

ACCIÓN 3: Testing
  □ Caso 1: FAB genera plan → activePlanId se actualiza
  □ Caso 2: loadPersistedActivePlanIfAny() → respeta regla oficial
  □ Caso 3: Multiple planes mismo día → latest gana

ACCIÓN 4: Rollback plan
  □ Si algo rompe: revert FAB change
  □ Verificar generatePlan() aún funciona
```

---

### FASE C: INTENSIDADES (corregir INT-001)

**Dependencias:** **DECIDIR PRIMERO cuál opción aplicar**

```
DECISIÓN REQUERIDA:
¿SeriesDistributionEditor debe persister cambios en Motor V3?

OPCIÓN 1: SÍ — Conectar a V3
─────────────────────────────
  ACCIÓN 1: Modificar SeriesDistributionEditor
    □ Signature: read plan.seriesDistribution? (vs trainingExtra)
    □ onDistributionChanged → updatePlan vía provider
    
  ACCIÓN 2: Verificar contrato en TrainingPlanConfig
    □ ¿Existe seriesDistribution: Map? field?
    □ Si no: agregar (minor schema change)
    
  ACCIÓN 3: Motor V3 respect seriesDistribution
    □ IntensityEngine lee plan.seriesDistribution
    □ Si user selectiona 80% heavy → genera más series pesadas

OPCIÓN 2: NO — Deshabilitar / Mark Experimental
─────────────────────────────
  ACCIÓN 1: Mark SeriesDistributionEditor
    □ @deprecated
    □ Label: "UI experimental"
    □ Comment: "Cambios NO se persisten"
    
  ACCIÓN 2: Hide from normal flow
    □ Remove tab from training_dashboard_screen.dart
    □ Move to separate "Labs" section (future)

DECIDIR: ¿Cuál camino tomar?
```

---

### FASE D: LEGACY (corregir LEG-001)

**Dependencias:** Ninguna (no toca código lógico)

```
ACCIÓN 1: Marcar volume_range_muscle_table.dart
  □ Agregar @deprecated al inicio de clase
  □ Comentario: "Use VolumeRangeMuscleTableV3 en su lugar"
  
ACCIÓN 2: Marcar training_dashboard_screen_legacy.dart
  □ Agregar @deprecated al inicio de clase
  □ Comentario: "Use training_dashboard_screen.dart (Motor V3)"

ACCIÓN 3: Documentación
  □ README: "Legacy screens, no se tocas"
  □ Commit message: "docs: mark legacy UI as deprecated"

ACCIÓN 4: NO ELIMINAR
  □ Mantener para compat (posibles clientes con Motor V2)
  □ Solo aislar con warnings
```

---

## 6. ORDEN DE EJECUCIÓN RECOMENDADO

**SEMANA 1: Riesgos Críticos**
1. [ ] **FASE A** (MUS-001): Normalización muscular — **P0 CRÍTICO**
2. [ ] **FASE B** (ACT-001): Plan activo — **P0 CRÍTICO**

**SEMANA 2: Riesgos Secundarios**
3. [ ] **Decidir** entre OPCIÓN 1 o 2 para INT-001
4. [ ] **FASE C** (INT-001): Intensidades
5. [ ] **FASE D** (LEG-001): Mark legacy

**Post-FixWeek: Validación**
- [ ] `flutter analyze` = no errors
- [ ] Smoke tests: ambos dashboards (V3 + legacy) cargan
- [ ] Integration test: FAB genera plan, plan es activo
- [ ] Volume test: plan contiene 14 músculos normalizados

---

## 7. ESTADO ACTUAL DEL SISTEMA (Snapshot)

```
✅ MOTOR V3 CIENTÍFICO
  ├── VolumeEngine: 14 músculos canónicos
  ├── Cálculo MEV/MAV/MRV: CORRECTO
  ├── volumePerMuscle: GENERADO POR MOTOR
  └── Output → TrainingPlanConfig: OK

✅ SSOT ENTITY
  └── domain/entities/training_plan_config.dart: OK

✅ UI V3 — LECTURA PURA
  ├── VolumeCapacityScientificView: ✅
  ├── VolumeRangeMuscleTableV3: ✅
  ├── SeriesBreakdownTable: ✅
  ├── WeeklyPlanDetailView: ✅
  └── training_dashboard_screen.dart: ✅

⚠️ NORMALIZACIÓN MUSCULAR
  ├── MuscleRegistry (central): ✅ OK
  ├── muscle_key_normalizer.dart: ✅ OK
  └── training_profile._normalizeMuscleKey(): ❌ DIVERGE
      └── RIESGO: prioridades inconsistentes

⚠️ PLAN ACTIVO
  ├── activePlanId: ✅ Existe como field
  ├── loadPersistedActivePlanIfAny(): ✅ Funciona
  └── FAB generatePlan(): ❌ NO ACTUALIZA activePlanId
      └── RIESGO: usuario confundido

⚠️ INTENSIDADES
  └── SeriesDistributionEditor: ❌ NO CONECTADO A V3
      └── RIESGO: cambios UI se ignoran

✅ LEGACY — AISLADO
  ├── volume_range_muscle_table.dart: OK (no usado en V3)
  ├── training_dashboard_screen_legacy.dart: OK (separate)
  ├── GeneratedPlan: OK (mapper compat only)
  └── phase2/phase3: OK (not generated by V3)

✅ COMPILACIÓN
  └── flutter analyze: 0 errores nuevos

✅ ARQUITECTURA
  └── Motor V3 → TrainingPlanConfig → UI V3
      └── Separation of concerns: LIMPIO
```

---

## 8. RESUMEN EJECUTIVO

### ¿QUÉ FUNCIONA?
- Motor V3 genera planes científicos correctamente
- UI V3 lee TrainingPlanConfig (SSOT) sin problemas
- Legacy está aislado, no rompe V3
- Sistema compila y funciona sin crashes

### ¿QUÉ NECESITA CORRECCIÓN?
1. **MUS-001** (P0): Normalización divergente → inconsistencia de músculos
2. **ACT-001** (P0): Plan activo ambiguo → confusión de usuario
3. **INT-001** (P1): Intensidades desconectadas → false UI control
4. **LEG-001** (P1): Legacy sin warnings → deuda técnica

### CRITERIO DE ÉXITO
```
El sistema:
✓ Sigue compilando (0 errores nuevos)
✓ Motor V3 intacto (sin cambios científicos)
✓ UI no se rompe (todas las pantallas cargan)
✓ Legacy aislado (V3 no depende de legacy)
✓ Contratos claros (documentados, sin ambigüedad)
✓ Riesgos visibles (priorizados, con acciones)
```

---

## 9. APÉNDICE: IMPORTS AUDITADOS

### ✅ UI IMPORTA DESDE domain/entities (CORRECTO)

```
lib/features/training_feature/widgets/volume_capacity_scientific_view.dart:3
  → import 'package:hcs_app_lap/domain/entities/training_plan_config.dart';

lib/features/training_feature/widgets/volume_range_muscle_table_v3.dart:2
  → import 'package:hcs_app_lap/domain/entities/training_plan_config.dart';

lib/features/training_feature/screens/training_dashboard_screen.dart:7
  → import 'package:hcs_app_lap/domain/entities/training_plan_config.dart';

lib/features/training_feature/providers/training_plan_provider.dart:7
  → import 'package:hcs_app_lap/domain/entities/training_plan_config.dart';

[+ 10 más]
```

### ⚠️ MOTOR IMPORTA DESDE domain/training_v3/models (INTENCIONAL)

```
lib/domain/training_v3/services/motor_v3_orchestrator.dart:11
  → import 'package:hcs_app_lap/domain/training_v3/models/training_plan_config.dart';
  → INTERNO DEL MOTOR (version V3 del contrato)

lib/domain/training_v3/orchestrator/training_orchestrator_v3.dart:16
  → import 'package:hcs_app_lap/domain/training_v3/models/training_plan_config.dart' as v3;
  → INTERNO DEL MOTOR (conversión asincrónica)
```
✅ **Correcto: UI NO mezcla con internals del motor**

---

## 10. CONTACTO Y PRÓXIMOS PASOS

**Autor de auditoría:** Arquitecto Flutter + Scientist Training  
**Fecha:** 5 febrero 2026  
**Próxima sincronización:** Después de correcciones P0

### ACCIONES INMEDIATAS (Hoy)
1. ✅ Auditoría completada (este documento)
2. [ ] Revisar hallazgos con team
3. [ ] Priorizar: ¿MUS-001 o ACT-001 primero?

### SEMANA 1
- [ ] Ejecutar FASE A (MUS-001)
- [ ] Ejecutar FASE B (ACT-001)
- [ ] Testing de correcciones

### SEMANA 2
- [ ] Decidir INT-001 (opciones)
- [ ] Ejecutar FASE C
- [ ] Ejecutar FASE D
- [ ] Validación final

---

**FIN DE AUDITORÍA**  
*Documento generado: 5 febrero 2026*  
*Estado: Listo para fase de correcciones*
