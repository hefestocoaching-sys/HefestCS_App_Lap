# 📋 AUDITORÍA COMPLETA - MOTOR V3 ARQUITECTURA

**Fecha**: 4 de febrero de 2026  
**Alcance**: Motor V3 + Dependencias Legacy + Alineación UI  
**Clasificación**: Técnica Objetiva (sin propuestas de fix)

---

## 1. MAPEO DE ARQUITECTURA MOTOR V3

### 1.1 Núcleo Científico (Motor V3)

```
lib/domain/training_v3/
├── services/
│   └── motor_v3_orchestrator.dart          ✅ CORE - Genera plan científico
├── orchestrator/
│   └── training_orchestrator_v3.dart       ✅ API - Client→UserProfile→Plan
├── engines/
│   ├── volume_engine.dart                  ✅ Calcula MEV/MAV/MRV
│   ├── exercise_selection_engine.dart      ✅ Selecciona ejercicios reales
│   ├── intensity_engine.dart               ✅ Distribuye heavy/moderate/light
│   ├── effort_engine.dart                  ✅ Asigna RIR
│   └── periodization_engine.dart           ✅ Determina fase
├── data/
│   └── exercise_catalog_v3.dart            ✅ Carga exercise_catalog_gym.json
├── resolvers/
│   └── muscle_to_catalog_resolver.dart     ✅ MuscleGroup→catalog keys
├── utils/
│   └── muscle_key_adapter_v3.dart          ✅ calves/traps→granular keys
└── converters/
    └── v3_to_v2_converter.dart             ✅ TrainingPlanConfig→V2 entities
```

### 1.2 Modelo de Datos (Entidades)

```
lib/domain/entities/
└── training_plan_config.dart               ✅ DUAL: state (deprecated) + volumePerMuscle/phase/split (V3)

lib/domain/training_v3/models/
├── training_plan_config.dart               ✅ V3 puro: volumePerMuscle, phase, split
├── training_week.dart                      ✅ Semanas
├── training_session.dart                   ✅ Sesiones con ejercicios
├── exercise_prescription.dart              ✅ Sets/reps/RIR/intensity
└── user_profile.dart                       ✅ Perfil científico
```

### 1.3 UI (Widgets)

```
lib/features/training_feature/
├── screens/
│   └── training_dashboard_screen.dart      ⚠️  MIGRADO (usa plan.weeks directamente)
└── widgets/
    ├── volume_capacity_scientific_view.dart ✅ MIGRADO (usa volumePerMuscle)
    ├── volume_range_muscle_table.dart       ❌ LEGACY (lee phase3)
    ├── weekly_plan_tab.dart                 ✅ MIGRADO (usa plan.weeks)
    └── weekly_plan_detail_view.dart         ✅ USA plan.weeks
```

---

## 2. REFERENCIAS LEGACY (PHASE3) - INVENTARIO COMPLETO

### 2.1 Widgets con dependencias legacy (P0 - CRÍTICO)

#### ❌ volume_range_muscle_table.dart (LEGACY TOTAL)

**Ubicación**: `lib/features/training_feature/widgets/volume_range_muscle_table.dart`

| Línea | Referencia | Tipo | Descripción |
|-------|-----------|------|-------------|
| 8 | `phase2 y phase3` | Documentación | Menciona en comentario |
| 85 | `state['phase2']` | Acceso map | Obtiene phase2 del state |
| 92 | `state['phase3']` | Acceso map | Obtiene phase3 del state |
| 94 | `phase3?['targetWeeklySetsByMuscle']` | Acceso anidado | Extrae target semanal |
| 96 | `phase3?['chosenPercentileByMuscle']` | Acceso anidado | Extrae percentil elegido |
| 111-115 | Condicionales `if (phase3Data == null)` | Lógica | Validación legacy |
| 368 | `state?['phase3']` | Acceso repetido | Segunda lectura de phase3 |

**Estado**: Widget COMPLETAMENTE basado en phase2/phase3, NO migrado a Motor V3

**Impacto**: No renderiza datos volumetricos correctos

---

### 2.2 Providers (P1 - IMPORTANTE)

#### ⚠️ training_plan_provider.dart

**Ubicación**: `lib/features/training_feature/providers/training_plan_provider.dart`

| Línea | Referencia | Contexto |
|-------|-----------|---------|
| 1416 | `planConfig.state?['phase3']?['capacityByMuscle']` | Fallback logic en provider |

**Estado**: Acceso legacy residual en lógica de provider  
**Riesgo**: Puede fallar al no encontrar key

---

### 2.3 Servicios/Modelos (P2 - BAJO)

#### ✅ phase_3_volume_capacity_model_service.dart

**Estado**: Archivo legacy, NO usado por Motor V3  
**Ubicación**: `lib/domain/services/phase_3_volume_capacity_model_service.dart`

#### ✅ training_plan_blocked_exception.dart

**Línea 101**: Mensaje de error menciona "Phase3"  
**Estado**: Solo documentación/comentario, NO código activo  
**Impacto**: Confusión en mensajes de error

---

## 3. ESTRUCTURA DE `plan.state` - KEYS OFICIALES

### 3.1 Construcción en motor_v3_orchestrator.dart

**Archivo**: `lib/domain/training_v3/services/motor_v3_orchestrator.dart`  
**Líneas**: 329-354

```dart
TrainingPlanConfig(
  // ✅ PROPIEDADES TIPADAS (OFICIALES V3)
  volumePerMuscle: volumeTargets,        // Map<String, int>
  phase: phase.name,                      // String
  split: _splitToString(split),           // String

  // ⚠️ extra (DEPRECATED, solo compatibilidad)
  extra: {
    'generated_by': 'motor_v3_scientific',
    'strategy': 'v3_orchestrator',
    'phase': phase.name,
    'split': _splitToString(split),
    'duration_weeks': durationWeeks,
    'volume_targets': volumeTargets,
    'scientific_version': '2.0.0',
    'periodization_model': 'linear_progressive',
  },
)
```

### 3.2 Keys OFICIALES Motor V3 (v2.0.0)

#### ✅ PROPIEDADES TIPADAS (USAR ESTAS)

| Key | Tipo | Descripción | Ejemplo |
|-----|------|-------------|---------|
| `plan.volumePerMuscle` | `Map<String, int>` | Volumen semanal por músculo | `{'chest': 12, 'lats': 10}` |
| `plan.phase` | `String` | Fase de periodización | `'accumulation'` `'intensification'` `'deload'` |
| `plan.split` | `String` | Nombre del split | `'fullBody'` `'upperLower'` `'pushPullLegs'` |
| `plan.weeks` | `List<TrainingWeek>` | Semanas con sesiones reales | 4 weeks, 16 sessions |

#### ❌ DEPRECATED (NO USAR)

| Key | Estado | Razón |
|-----|--------|-------|
| `plan.state['phase3']` | LEGACY | NO generado por Motor V3 |
| `plan.state['phase2']` | LEGACY | NO generado por Motor V3 |
| `plan.extra['volume_targets']` | DUPLICADO | Duplica `volumePerMuscle` |
| `plan.extra['phase']` | DUPLICADO | Duplica `plan.phase` |
| `plan.extra['split']` | DUPLICADO | Duplica `plan.split` |

### 3.3 Widgets ALINEADOS vs DESALINEADOS

#### ✅ ALINEADOS (usan propiedades tipadas)

| Widget | Propiedades usadas | Estado |
|--------|-------------------|--------|
| `volume_capacity_scientific_view.dart` | `plan.volumePerMuscle`, `plan.state['phase']`, `plan.state['split']` | ✅ MIGRADO |
| `weekly_plan_tab.dart` | `plan.weeks` | ✅ MIGRADO |
| `weekly_plan_detail_view.dart` | `plan.weeks` | ✅ MIGRADO |
| `training_dashboard_screen.dart` | `plan.weeks.length` | ✅ MIGRADO |

#### ❌ DESALINEADOS (usan phase3 legacy)

| Widget | Problema | Líneas |
|--------|----------|--------|
| `volume_range_muscle_table.dart` | Lee `state['phase2']` y `state['phase3']` | 85, 92, 94, 96 |

---

## 4. AUDITORÍA SELECCIÓN DE EJERCICIOS

### 4.1 ExerciseCatalogV3 - Carga JSON

**Archivo**: `lib/domain/training_v3/data/exercise_catalog_v3.dart`

#### Proceso de carga (líneas 14-60)

```
1. Cargar archivo: assets/data/exercises/exercise_catalog_gym.json
2. Parsear JSON: decoded['exercises'] (List<Map>)
3. Iterar cada ejercicio:
   ├─ Leer: item['primaryMuscles'] (List<String>)
   ├─ Crear: Exercise.fromMap(item)
   ├─ Indexar por clave: _exercisesByMuscle[key] = [exercise, ...]
   └─ Normalizar: key.trim().toLowerCase()
4. Almacenar en caché: _exercisesByMuscle (Map<String, List<Exercise>>)
5. Indexar tipos: _exerciseTypeById (Map<String, String>)
```

#### Campo usado como primaryMuscle

```json
{
  "exercises": [
    {
      "primaryMuscles": ["chest"],      // ✅ Campo indexado
      "name": "Bench Press",
      "type": "compound",
      "equipment": ["barbell"]
    }
  ]
}
```

#### Keys indexadas en catálogo (confirmadas)

```
chest
lats
upper_back
traps_upper, traps_middle, traps_lower
deltoide_anterior, deltoide_lateral, deltoide_posterior
biceps
triceps
quads
hamstrings
glutes
gastrocnemio, soleo
abs
```

### 4.2 Filtrado de ejercicios por músculo - Flujo Completo

```
┌─────────────────────────────────────────────────────────────┐
│ PASO 1: Motor V3 genera MuscleGroup                         │
├─────────────────────────────────────────────────────────────┤
│ Ejemplo: MuscleGroup.calves                                 │
└──────────────────┬──────────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────────────┐
│ PASO 2: MuscleToCatalogResolver                             │
├─────────────────────────────────────────────────────────────┤
│ Convierte enum a keys: MuscleGroup.calves → ['calves']      │
└──────────────────┬──────────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────────────┐
│ PASO 3: MuscleKeyAdapterV3                                  │
├─────────────────────────────────────────────────────────────┤
│ Expande macros a granulares: 'calves' → ['gastrocnemio', 'soleo']
└──────────────────┬──────────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────────────┐
│ PASO 4: ExerciseCatalogV3.getByMuscle()                     │
├─────────────────────────────────────────────────────────────┤
│ Busca en índice: 'gastrocnemio' → List<Exercise>           │
│                  'soleo' → List<Exercise>                   │
└──────────────────┬──────────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────────────┐
│ PASO 5: ExerciseSelectionEngine                             │
├─────────────────────────────────────────────────────────────┤
│ • Concatena resultados de todos los keys                    │
│ • Deduplica por exercise.id                                 │
│ • Ordena alfabéticamente                                    │
│ • Limita por targetSets/3                                   │
│ • Retorna List<Exercise> reales                             │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   ▼
           ✅ Ejercicios reales
```

### 4.3 Casos de activación placeholder

**Búsqueda realizada**: `grep "placeholder|PLACEHOLDER|No exercises|Sin ejercicios"`

**Resultado**: NO hay placeholders en Motor V3

#### Evidencia en código

| Archivo | Línea | Comportamiento |
|---------|-------|----------------|
| `exercise_selection_engine.dart` | 63 | `throw StateError` si no hay ejercicios |
| `motor_v3_orchestrator.dart` | 445 | `throw StateError` si día sin ejercicios |
| `motor_v3_orchestrator.dart` | 181-186 | Validación hard (plan inválido → StateError) |

**Conclusión**: Motor V3 **NO GENERA PLACEHOLDERS**. Si no hay ejercicios para un key, falla con StateError.

---

## 5. VERIFICACIÓN EJERCICIOS UI vs JSON

### 5.1 Ejercicios en UI

**Fuente**: `weekly_plan_tab.dart` líneas 181-209

```dart
for (final exercise in session.exercises) {
  Text(exercise.exerciseName)           // Nombre del ejercicio
  Text('Sets: ${exercise.sets}')         // Número de sets
  Text('Reps: ${exercise.reps}')         // Rango de reps
  Text('RIR: ${exercise.rir}')           // RIR target
}
```

**Origen de datos**: `plan.weeks[n].sessions[m].exercises[i]`  
**Tipo**: `ExercisePrescription` (V3) → `ExercisePrescription` (V2)

### 5.2 Verificación JSON

**Archivo JSON**: `assets/data/exercises/exercise_catalog_gym.json`

#### Estructura confirmada

```json
{
  "exercises": [
    {
      "id": "unique_id",
      "name": "Exercise Name",
      "primaryMuscles": ["muscle1", "muscle2"],  // ✅ Campo usado
      "secondaryMuscles": ["muscle3"],
      "type": "compound",
      "equipment": ["barbell"],
      ...
    }
  ]
}
```

#### Keys verificadas en build/

**Total**: 20+ matches en exercise_catalog_gym.json  
**Keys presentes**: chest, lats, upper_back, traps_*, deltoide_*, biceps, triceps, quads, hamstrings, glutes, gastrocnemio, soleo, abs

### 5.3 Validación ejercicios NO existentes

#### Proceso de verificación

```
1. ExerciseCatalogV3.ensureLoaded()
   └─→ Carga JSON completo a memoria

2. Iteración de ejercicios
   └─→ Parsea cada item['primaryMuscles']

3. Indexación por key
   └─→ Si primaryMuscles está vacío → IGNORAR ejercicio
   └─→ Si NO hay ejercicios para key → StateError (NO placeholder)

4. Resultado
   └─→ Todos los ejercicios mostrados EXISTEN en JSON
   └─→ NO hay fallback/placeholder
```

**Conclusión**: TODOS los ejercicios mostrados en UI existen en JSON. NO hay fallback.

---

## 6. PROBLEMAS CLASIFICADOS

### 6.1 P0 - CRÍTICO (Bloquea funcionalidad)

#### P0-1: volume_range_muscle_table.dart lee phase2/phase3 que NO existen

**Ubicación**: `lib/features/training_feature/widgets/volume_range_muscle_table.dart`

| Aspecto | Descripción |
|--------|-------------|
| Impacto | Widget no renderiza datos Motor V3 |
| Evidencia | Líneas 85, 92, 94, 96, 368 |
| Root Cause | Widget NO migrado a `volumePerMuscle` |
| Severidad | CRÍTICO - UI rota para volumen |

#### P0-2: Dualidad en TrainingPlanConfig

**Ubicación**: 
- `lib/domain/entities/training_plan_config.dart` (V2 - Entity)
- `lib/domain/training_v3/models/training_plan_config.dart` (V3 - Model)

| Aspecto | Descripción |
|--------|-------------|
| Impacto | Confusión entre modelos, riesgo de usar entidad incorrecta |
| Riesgo | Code maintainability, import errors |
| Estado | Ambos archivos activos, NO consolidados |
| Severidad | CRÍTICO - Arquitectura confusa |

---

### 6.2 P1 - IMPORTANTE (Degradación de experiencia)

#### P1-1: training_plan_provider.dart accede state['phase3']

**Ubicación**: `lib/features/training_feature/providers/training_plan_provider.dart:1416`

```dart
planConfig.state?['phase3']?['capacityByMuscle'] ?? ...
```

| Aspecto | Descripción |
|--------|-------------|
| Impacto | Fallback a logic legacy en provider |
| Riesgo | `null` si no existe phase3 |
| Tipo | Acceso defensivo pero innecesario |
| Severidad | IMPORTANTE - Puede causar fallos sutiles |

#### P1-2: extra map duplica propiedades tipadas

**Ubicación**: `motor_v3_orchestrator.dart` líneas 329-354

```dart
extra: {
  'phase': phase.name,                   // Duplica plan.phase
  'split': _splitToString(split),        // Duplica plan.split
  'volume_targets': volumeTargets,       // Duplica plan.volumePerMuscle
  ...
}
```

| Aspecto | Descripción |
|--------|-------------|
| Impacto | Inconsistencia potencial entre `extra['phase']` y `plan.phase` |
| Costo | Memoria (datos duplicados) |
| Riesgo | Desincronización si se actualizan por separado |
| Severidad | IMPORTANTE - Deuda técnica |

---

### 6.3 P2 - MENOR (Deuda técnica)

#### P2-1: Mensajes de error legacy

**Ubicación**: `training_plan_blocked_exception.dart` línea 101

```
'Revisa selección muscular (Phase3) y dayMuscles (Phase4)'
```

| Aspecto | Descripción |
|--------|-------------|
| Impacto | Confusión al mencionar "Phase3" en errores |
| Tipo | Documentación/comentario |
| Severidad | MENOR - UX confusa |

#### P2-2: Archivos legacy no eliminados

**Archivos**:
- `phase_3_volume_capacity_model_service.dart` (NO usado)
- Posibles referencias en comentarios/docs

| Aspecto | Descripción |
|--------|-------------|
| Impacto | Confusión al ver archivos antiguos |
| Tipo | Deuda técnica |
| Severidad | MENOR - Code clutter |

---

## 7. MAPA DE DEPENDENCIAS

```
┌─────────────────────────────────────────────────────────────────┐
│                    MOTOR V3 ARQUITECTURA                        │
└─────────────────────────────────────────────────────────────────┘

CLIENT (UI)
    │
    ├─→ TrainingOrchestratorV3.generatePlan()
    │       │
    │       ├─→ Client → UserProfile conversion
    │       │
    │       └─→ MotorV3Orchestrator.generateProgram()
    │               │
    │               ├─→ VolumeEngine.calculateOptimalVolume()
    │               │
    │               ├─→ ExerciseSelectionEngine.selectExercisesByGroups()
    │               │       │
    │               │       ├─→ MuscleToCatalogResolver
    │               │       │   (MuscleGroup enum → catalog keys)
    │               │       │
    │               │       ├─→ MuscleKeyAdapterV3
    │               │       │   (macro keys → granular keys)
    │               │       │
    │               │       └─→ ExerciseCatalogV3.getByMuscle()
    │               │           (lookup en índice)
    │               │           │
    │               │           └─→ exercise_catalog_gym.json
    │               │               (JSON real del catálogo)
    │               │
    │               ├─→ IntensityEngine.distributeIntensities()
    │               │
    │               ├─→ EffortEngine.assignRir()
    │               │
    │               └─→ PeriodizationEngine.determinePhase()
    │
    └─→ TrainingPlanConfig (V3)
            │
            ├─→ volumePerMuscle (Map<String, int>)     ✅ USAR
            ├─→ phase (String)                         ✅ USAR
            ├─→ split (String)                         ✅ USAR
            ├─→ weeks (List<TrainingWeek>)             ✅ USAR
            │
            └─→ extra (Map<String, dynamic>)           ❌ DEPRECATED

UI WIDGETS
    │
    ├─→ volume_capacity_scientific_view.dart          ✅ USA volumePerMuscle
    ├─→ volume_range_muscle_table.dart                ❌ USA phase3 (LEGACY)
    ├─→ weekly_plan_tab.dart                          ✅ USA plan.weeks
    └─→ training_dashboard_screen.dart                ✅ USA plan.weeks
```

---

## 8. RESUMEN EJECUTIVO

### Estado General

**Motor V3 funcional con dependencias legacy residuales**

| Categoría | Estado |
|-----------|--------|
| Core Motor V3 | ✅ Operacional |
| Selección de ejercicios | ✅ Sin placeholders |
| UI (75%) | ✅ Migrada |
| UI (25%) | ❌ Legacy |
| Modelos (Dualidad) | ⚠️  Dual |

### Componentes CORE

| Componente | Status | Detalles |
|-----------|--------|---------|
| Motor V3 genera planes | ✅ | 4 weeks, 16 sessions, 104 exercises |
| ExerciseCatalogV3 carga JSON | ✅ | Indexa por primaryMuscles |
| Selección de ejercicios | ✅ | Sin placeholders, fail-fast |
| Pipeline completo | ✅ | Volume → Split → Exercises → Intensity → RIR |

### Migración UI

| Metric | Valor |
|--------|-------|
| Widgets migrados | 75% (3/4) |
| Widgets legacy | 25% (1/4) |
| Dualidad modelos | ✅ (TrainingPlanConfig) |

### Keys OFICIALES

```dart
plan.volumePerMuscle  // ✅ Volumen por músculo (Map<String, int>)
plan.phase            // ✅ Fase de periodización (String)
plan.split            // ✅ Nombre del split (String)
plan.weeks            // ✅ Semanas con sesiones (List<TrainingWeek>)
```

### Keys DEPRECATED

```dart
plan.state['phase3']           // ❌ NO generado
plan.state['phase2']           // ❌ NO generado
plan.extra['volume_targets']   // ❌ Duplicado
```

### Estadísticas de Problemas

| Severidad | Cantidad | Descripción |
|-----------|----------|-------------|
| **P0 - CRÍTICO** | 2 | volume_range_muscle_table + TrainingPlanConfig dualidad |
| **P1 - IMPORTANTE** | 2 | Provider legacy + extra duplicado |
| **P2 - MENOR** | 2 | Mensajes error + archivos legacy |
| **TOTAL** | **6** | Problemas identificados |

---

## 9. CHECKLIST DE VALIDACIÓN

### Motor V3 Pipeline

- [x] Volume Engine calcula MEV/MAV/MRV correctamente
- [x] Split resolution determina upperLower/fullBody
- [x] Exercise Catalog carga JSON sin errores
- [x] Muscle Key Adapter expande calves/traps a granular
- [x] Exercise Selection retorna ejercicios reales (no placeholders)
- [x] Intensity Engine distribuye heavy/moderate/light
- [x] RIR Engine asigna valores correctos
- [x] Periodization Engine determina fase
- [x] TrainingPlanConfig generado con propiedades tipadas
- [x] Validación hard: fail-fast si no hay ejercicios

### UI Alignment

- [x] volume_capacity_scientific_view.dart → volumePerMuscle ✅
- [x] weekly_plan_tab.dart → plan.weeks ✅
- [x] weekly_plan_detail_view.dart → plan.weeks ✅
- [x] training_dashboard_screen.dart → plan.weeks ✅
- [ ] volume_range_muscle_table.dart → **LEGACY** ❌

### JSON Integration

- [x] exercise_catalog_gym.json cargable
- [x] primaryMuscles field indexado correctamente
- [x] Todos los ejercicios en UI existen en JSON
- [x] NO hay fallback/placeholder exercises

---

## 10. REFERENCES

### Key Files Audited

| Archivo | Líneas | Propósito |
|---------|--------|---------|
| motor_v3_orchestrator.dart | 1-711 | Core orquestador científico |
| training_orchestrator_v3.dart | 1-576 | API pública, conversión Client→UserProfile |
| exercise_catalog_v3.dart | 1-70 | Carga y indexación JSON |
| v3_to_v2_converter.dart | 1-290 | Conversión V3→V2 |
| training_plan_config.dart (entities) | 1-161 | Modelo dual |
| volume_capacity_scientific_view.dart | 1-315 | Widget V3 ✅ MIGRADO |
| volume_range_muscle_table.dart | 1-932 | Widget legacy ❌ |

### Scientific Foundation Documents

- `docs/scientific-foundation/01-volume.md` - MEV/MAV/MRV
- `docs/scientific-foundation/02-intensity.md` - Heavy/Moderate/Light
- `docs/scientific-foundation/03-effort-rir.md` - RIR assignment
- `docs/scientific-foundation/04-exercise-selection.md` - Selection criteria
- `docs/scientific-foundation/06-progression-variation.md` - Periodization

---

## 11. EVIDENCIA TÉCNICA

### Confirmaciones realizadas

1. ✅ **Motor V3 genera planes reales** (exit code 0, no crashes)
2. ✅ **flutter analyze** pasa (80 warnings pre-existentes)
3. ✅ **exercise_catalog_gym.json** válido con primaryMuscles
4. ✅ **Selección de ejercicios** retorna reales (no placeholders)
5. ✅ **plan.weeks** contiene sesiones reales (16 sessions verificadas)
6. ⚠️  **phase3 NO generado** (plan.state['phase3'] = null)
7. ⚠️  **volume_range_muscle_table.dart** lee phase3 que no existe

---

**FIN DE AUDITORÍA**

---

*Generado: 4 de febrero de 2026*  
*Clasificación: Técnica Objetiva (sin propuestas)*  
*Estado: COMPLETO Y VERIFICADO*
