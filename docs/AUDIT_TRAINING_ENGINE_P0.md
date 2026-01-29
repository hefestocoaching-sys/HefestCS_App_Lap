# AUDITORÍA MOTOR ENTRENAMIENTO 8 FASES + TRAINING_EXTRA_KEYS

**Generado**: 19 de enero 2026  
**Estado**: CRÍTICO - Plan de remediar keys string-literal y SSOT de VOP

---

## RESUMEN EJECUTIVO

### Hallazgos P0

1. **Keys string-literal sin constante**: `trainingExtra['algo']` aparece sin usar `TrainingExtraKeys.<constant>`
   - RIESGO: Typos silenciosos, merge destructivo, cambios de esquema invisible
   - FIX: Crear constantes en `TrainingExtraKeys` para TODA lectura/escritura de `training.extra`

2. **VOP (Volume of Pressure) sin SSOT claro**: 
   - Datos viven en múltiples keys: `finalTargetSetsByMuscleUi`, `targetSetsByMuscle`, etc.
   - Tabs 2/3/4 leen sources distintas → inconsistencia
   - FIX: Crear `vopSnapshot` canónico (SSOT singular), normalizar + expandir grupos, persistir 1× en Tab 2

3. **Muscle keys no canónicos internamente**:
   - UI muestra español ("Pectoral", "Espalda")
   - Motor usa inglés legacy (chest, back, shoulders)
   - Nuevos IDs existen (deltoide_anterior, upper_back) sin unificación
   - FIX: Canon interno = 14 músculos individuales (MuscleKeys.all), adapters en normalizer

4. **Fallback silencioso en Tabs 3/4**:
   - Si falta VOP para un músculo, mostrar genérico "falta vop para back"
   - No se identifica qué key se busca vs qué keys tiene el snapshot
   - FIX: Migración automática + validación explícita + error granular por músculo

---

## 8 FASES DEL MOTOR (Versión 2 Full)

### Fase 1: DATA INGESTION & VALIDATION

**Archivo**: `lib/domain/services/phase_1_data_ingestion_service.dart`

| Concepto | Detalle |
|----------|---------|
| **Entrada** | `TrainingProfile.extra` (perfil + histórico + overrides manuales) |
| **Keys leídas** | `manualOverrides`, `priorityMuscles*`, `trainingLevel`, `daysPerWeek`, `timePerSessionMinutes`, `avgSleepHours`, `restBetweenSetsSeconds`, `trainingYears` |
| **Validación** | Detecta datos críticos faltantes; bloquea si métricas esenciales ausentes |
| **Salida** | `Phase1Result` con `isValid`, `missingData`, `derivedContext` (atleta + historial procesado) |
| **DecisionTrace** | INFO/WARNING/CRITICAL por campo validado |

**P0 Detectado**: Lectura de `profile.extra['manualOverrides']` sin constante.

---

### Fase 2: READINESS EVALUATION

**Archivo**: `lib/domain/services/phase_2_readiness_evaluation_service.dart`

| Concepto | Detalle |
|----------|---------|
| **Entrada** | `TrainingProfile`, `TrainingHistory`, `latestFeedback`, `derivedContext` de Fase 1 |
| **Keys leídas** | `perceivedStress`, `recoveryQuality`, `avgSleepHours`, `usesAnabolics`, `trainingYears` |
| **Adaptación** | Calcula factor ajuste volumen global (0.8–1.2) + readiness por músculo (based on bitácora) |
| **Salida** | `volumeAdjustmentFactor`, `readinessByMuscle` (Map<String, double>) |
| **DecisionTrace** | INFO por ajuste aplicado |

**P0 Detectado**: Lectura de keys sin constante en algunos puntos.

---

### Fase 3: VOLUME CAPACITY MODEL (MEV/MRV)

**Archivo**: `lib/domain/services/phase_3_volume_capacity_model_service.dart`

| Concepto | Detalle |
|----------|---------|
| **Entrada** | `TrainingProfile`, `readinessAdjustment` (Fase 2), `readinessByMuscle`, `manualOverride` |
| **Keys leídas** | `trainingLevel`, `trainingYears`, `daysPerWeek`, `avgSleepHours`, `usesAnabolics`, `activeInjuries`, `heightCm`, `weightKg` |
| **Cálculo** | MEV/MRV base → ajustes por músculos canónicos → recommendedStartVolume por músculo |
| **Salida** | `volumeLimitsByMuscle` (Map<String, VolumeLimits>) con MEV/MAV/MRV/recommendedStartVolume |
| **Validación Final** | Clamp a [MEV, MRV]; principiantes: MRV ≤ 16 sets/sem |
| **DecisionTrace** | WARNING si volumen debe ser ajustado; CRITICAL si seguridad comprometida |

**P0 Detectado**:
- ✅ Keys usadas son constantes (TrainingExtraKeys.*)
- ⚠️ Volumen recomendado se calcula PER MÚSCULO pero NO se persiste en SSOT

---

### Fase 4: SPLIT DISTRIBUTION

**Archivo**: `lib/domain/services/phase_4_split_distribution_service.dart`

| Concepto | Detalle |
|----------|---------|
| **Entrada** | `TrainingProfile`, `volumeByMuscle` (Fase 3), `readinessAdjustment`, `derivedContext`, `manualOverride` |
| **Selección Split** | Elige plantilla (Push/Pull/Legs, Upper/Lower, Full Body) según `daysPerWeek` + `timePerSession` |
| **Keys leídas** | `weeklySplitTemplateId` (override manual), `priorityMuscles*`, `selectedSplitId` |
| **Distribución** | Asigna músculos a días según plantilla; respeta prioridad primaria (más freq); aplica readiness |
| **Salida** | `TrainingSplit` con `dayToMuscles` (Map<int, List<String>>) distribuidos por semana |
| **DecisionTrace** | INFO por split elegido; WARNING si prioridades fuerzan cambios |

**P0 Detectado**:
- `weeklySplitTemplateId` y `selectedSplitId` se leen sin definición clara de diferencia
- `priorityMuscles*` se leen via `profile.extra` pero no usados explícitamente en distribución

---

### Fase 5: PERIODIZATION (RIR + Rep Ranges)

**Archivo**: `lib/domain/services/phase_5_periodization_service.dart`

| Concepto | Detalle |
|----------|---------|
| **Entrada** | `TrainingProfile`, `baseSplit` (Fase 4), `manualOverride` |
| **Periodización** | Genera 52 semanas: fases Accumulation/Intensification/Deload (4-sem bloques) |
| **RIR Target** | Accumulation: 2–4 RIR; Intensification: 0–2 RIR; Deload: 3–4 RIR |
| **Rep Ranges** | Asigna rangos (6-8, 8-10, 10-12, 12-15) según volumen + fase |
| **Salida** | `List<TrainingWeek>` (52 elem) con `phase`, `rirTargets`, `repRanges`, `expectedVolume` |
| **DecisionTrace** | INFO por semana; WARNING si volumen esperado excede MRV |

**P0 Detectado**: No persiste `targetSetsByMuscle` POR SEMANA en SSOT.

---

### Fase 6: EXERCISE SELECTION

**Archivo**: `lib/domain/services/phase_6_exercise_selection_service.dart`

| Concepto | Detalle |
|----------|---------|
| **Entrada** | `TrainingProfile`, `baseSplit`, `catalog` (Exercise[]), `weeks`, `derivedContext`, `logs` |
| **Selección** | Búsqueda en catálogo por músculo primario; respeta limitaciones (lesiones, equipamiento) |
| **Variación** | Rota ejercicios cada 3-4 semanas para evitar meseta; usa historial de logs |
| **Salida** | `ExerciseSelectionResult` con `selections` (Map<String, List<Exercise>>) por músculo/semana |
| **DecisionTrace** | WARNING si catálogo vacío para un músculo; CRITICAL si sin cobertura |

**P0 Detectado**:
- Catálogo se indexa por `primaryMuscle` (key de ExerciseCatalog)
- Si `MuscleKeys.all` cambia, mapping puede no encontrar ejercicios
- Necesario validar que catálogo esté indexado por músculos canónicos

---

### Fase 7: PRESCRIPTION (Sets/Reps/RIR/Descanso)

**Archivo**: `lib/domain/services/phase_7_prescription_service.dart`

| Concepto | Detalle |
|----------|---------|
| **Entrada** | `baseSplit`, `periodization` (Fase 5), `selections` (Fase 6), `volumeLimitsByMuscle` (Fase 3), `trainingLevel`, `derivedContext`, `manualOverride` |
| **Distribución VOP** | Asigna sets/semana a cada día según volumen recomendado + patrón split |
| **RIR Mapping** | Traduce RIR target → sets/reps concretos (ej: 2 RIR, 10 reps → 3×8) |
| **Descanso** | Calcula descanso inter-sets según volumen + ejercicio |
| **Técnicas** | Drop sets, superseries, cardio si recuperación permite |
| **Salida** | `weekDayPrescriptions` (Map<int, Map<int, List<ExercisePrescription>>>) con sesiones detalladas |
| **DecisionTrace** | INFO por semana de sets totales; WARNING si intensidad muy alta o baja |

**P0 Detectado**:
- VOP se consume desde `volumeLimitsByMuscle` (resultado Fase 3)
- NO hay SSOT persistido; cada vez que se recalcula, puede variar

---

### Fase 8: ADAPTATION & LEARNING (Final)

**Archivo**: `lib/domain/services/phase_8_adaptation_service.dart`

| Concepto | Detalle |
|----------|---------|
| **Entrada** | `latestFeedback`, `history`, `logs`, `weekDayPrescriptions` (Fase 7), `volumeLimitsByMuscle` (Fase 3), `trainingLevel`, `manualOverride` |
| **Adaptación** | Ajusta futuras semanas según feedback (RPE, dolor, fatiga) |
| **Aprendizaje MRV** | Calcula MRV observado por músculo basado en bitácora (conservador) |
| **Bloqueo Progresión** | Detecta si adaptación no es posible (fatiga crónica) |
| **Salida** | `TrainingAdaptationResult` con `volumeDeltas`, `rirDeltas`, `exerciseSwaps`, `muscleVolumeProfiles` actualizado |
| **DecisionTrace** | INFO/WARNING por ajuste; CRITICAL si bloqueo de progresión |

**P0 Detectado**:
- `muscleVolumeProfiles` se actualiza pero SOLO al final (Fase 8)
- SSOT de VOP inicial se escribe en Fase 3 pero NO en `training.extra`

---

## MAPA DE KEYS EN TRAINING.EXTRA

### Keys LEÍDAS por motor (Entrada):

| Key | Fase(s) | Tipo | Actual | Recomendado |
|-----|---------|------|--------|-------------|
| `manualOverrides` | 1 | Map | ❌ Sin constante | `TrainingExtraKeys.manualOverrides` |
| `priorityMusclesPrimary` | 1, 4 | List<String> | ✅ Constante | `TrainingExtraKeys.priorityMusclesPrimary` |
| `priorityMusclesSecondary` | 1, 4 | List<String> | ✅ Constante | `TrainingExtraKeys.priorityMusclesSecondary` |
| `priorityMusclesTertiary` | 1, 4 | List<String> | ✅ Constante | `TrainingExtraKeys.priorityMusclesTertiary` |
| `trainingLevel` | 1, 2, 3, 7, 8 | String | ✅ Constante | `TrainingExtraKeys.trainingLevel` |
| `daysPerWeek` | 1, 3, 4 | int | ✅ Constante | `TrainingExtraKeys.daysPerWeek` |
| `timePerSessionMinutes` | 1, 4 | int | ✅ Constante | `TrainingExtraKeys.timePerSessionMinutes` |
| `trainingYears` | 1, 2, 3 | int | ✅ Constante | `TrainingExtraKeys.trainingYears` |
| `avgSleepHours` | 1, 2, 3 | double | ✅ Constante | `TrainingExtraKeys.avgSleepHours` |
| `restBetweenSetsSeconds` | 1, 2 | int | ✅ Constante | `TrainingExtraKeys.restBetweenSetsSeconds` |
| `weeklySplitTemplateId` | 4 | String | ❌ Sin constante | `TrainingExtraKeys.weeklySplitTemplateId` |
| `selectedSplitId` | 4 | String | ✅ Constante | `TrainingExtraKeys.selectedSplitId` |
| `perceivedStress` | 2 | int | ✅ Constante | `TrainingExtraKeys.perceivedStress` |
| `recoveryQuality` | 2 | int | ✅ Constante | `TrainingExtraKeys.recoveryQuality` |
| `usesAnabolics` | 2, 3 | bool | ✅ Constante | `TrainingExtraKeys.usesAnabolics` |
| `activeInjuries` | 3 | List | ❌ Sin constante | Crear: `TrainingExtraKeys.activeInjuries` |
| `heightCm` | 3 | double | ✅ Constante | `TrainingExtraKeys.heightCm` |
| `weightKg` | 3 | double | ❌ Sin constante | Crear: `TrainingExtraKeys.weightKg` |
| `mevIndividual` | 3 (calc) | double | ✅ Constante (persiste) | `TrainingExtraKeys.mevIndividual` |
| `mrvIndividual` | 3 (calc) | double | ✅ Constante (persiste) | `TrainingExtraKeys.mrvIndividual` |
| `targetSetsByMuscle` | 3, 7 | Map<String,int> | ⚠️ Sin persistencia oficial | **NUEVO**: `TrainingExtraKeys.vopSnapshot` (SSOT) |
| `finalTargetSetsByMuscleUi` | 3 | Map<String,int> | ❌ Sin constante | Deprecar; usar `vopSnapshot` |

### Keys ESCRITAS por motor (Salida):

| Key | Fase(s) | Tipo | Actual | Recomendado |
|-----|---------|------|--------|-------------|
| `generatedPlan` | 7 | Map (TrainingPlanConfig) | ✅ Constante | `TrainingExtraKeys.generatedPlan` |
| `generatedAtIso` | 7 | String | ✅ Constante | `TrainingExtraKeys.generatedAtIso` |
| `forDateIso` | 7 | String | ✅ Constante | `TrainingExtraKeys.forDateIso` |
| `decisionTraceRecords` | 1-8 | List<Map> | ✅ Constante | `TrainingExtraKeys.decisionTraceRecords` |
| `trainingPlanConfig` | 7 | Map | ✅ Constante | `TrainingExtraKeys.trainingPlanConfig` |
| `trainingExtraVersion` | 8 | String | ✅ Constante | `TrainingExtraKeys.trainingExtraVersion` |
| `progressionBlocked` | 8 | bool | ✅ Constante | `TrainingExtraKeys.progressionBlocked` |
| `manualOverrideActive` | 8 | bool | ✅ Constante | `TrainingExtraKeys.manualOverrideActive` |
| `muscleVolumeProfiles` | 8 | Map<String,dynamic> | ✅ Constante | `TrainingExtraKeys.muscleVolumeProfiles` |
| **`vopSnapshot`** | **3 (write), 2/3/4 (read)** | **VopSnapshot (Map)** | **❌ NO ESCRITA** | **NUEVO SSOT** |

---

## VOP (VOLUME OF PRESSURE) - FLUJO ACTUAL VS IDEAL

### Actual (Problemático):

```
Tab 2 [finalTargetSetsByMuscleUi]
       → Sin persistencia explícita
       → Puede ser sobrescrito sin notice
       
Tab 3 (Macrocycle)
   → Lee training.extra['targetSetsByMuscle'] (clave sin constante)
   → Si no existe, fallback silencioso "falta vop para back"
   → No expande grupos (e.g., back_group → [lats, upper_back, traps])
   
Tab 4 (Weekly)
   → Lee finalTargetSetsByMuscleUi (literal)
   → Intenta lookup de 'back' vs 'back_group' (inconsistencia)
```

### Ideal (Propuesto):

```
1. Tab 2 escribre SSOT vopSnapshot:
   - Normaliza finalTargetSetsByMuscleUi (ES/EN → canónico)
   - Expande grupos a músuculos individuales
   - Persiste en training.extra[TrainingExtraKeys.vopSnapshot]
   - 14 keys canónicos solo (chest, lats, upper_back, traps, ...)
   
2. Migración automática (al entrar Tab 3/4):
   - Si vopSnapshot no existe pero targetSetsByMuscle sí → migrar
   - VopSnapshotMigrator.ensure(extra) retorna VopSnapshot o null
   - Si null → error explícito "Falta generar plan en Tab 2"
   
3. Tab 3/4 leen vopSnapshot:
   - VopContext.ensure() retorna contexto + snapshot validado
   - No fallback; error si falta
   - Per-muscle baseline (no grupo suma)
```

---

## UI TABS QUE CONSUMEN VOP

### Tab 1 - Volume/Intensity (Entrada manual)
- Lee: `baseSeries` (input usuario)
- Escribe: `finalTargetSetsByMuscleUi` (candidato para normalizar → vopSnapshot)

### Tab 2 - Volume Range (Auditoría + Manual override)
- Lee: `volumeLimitsByMuscle` (calculado Fase 3, si existe)
- Lee: `finalTargetSetsByMuscleUi` (de Tab 1)
- Escribe: ❌ **NO ESCRIBE SSOT** (P0: debe escribir vopSnapshot)
- Widget: `VolumeRangeMuscleTable`

### Tab 3 - Macrocycle Overview (Progresión 52 sem)
- Lee: `targetSetsByMuscle` o fallback `finalTargetSetsByMuscleUi`
- Lee: `generatedPlan` (para semanas)
- Renderiza: Gráfico volumen semanal por músculo
- Widget: `MacrocycleOverviewTab`
- **P0**: Si falta VOP para un músculo, muestra "falta vop para back" genérico

### Tab 4 - Weekly Plan (Distribución semanal + ejercicios)
- Lee: `weeklySplitTemplateId` o `selectedSplitId`
- Lee: `finalTargetSetsByMuscleUi` (literal)
- Lee: `generatedPlan` (ejercicios)
- Widget: `WeeklyPlanTab`
- **P0**: Si grupo no expandido → búsqueda ejercicio por 'back' falla, muestra placeholder

---

## PROBLEMAS CRÍTICOS (P0) IDENTIFICADOS

### 1. Keys sin constante (Typo Risk)

```dart
// ANTES (RIESGO: typo silencioso)
final vop = extra['finalTargetSetsByMuscleUi'];  // Está... o no?
final override = extra['manualOverrides'];        // Literal sin definición

// DESPUÉS (SEGURO)
final vop = extra[TrainingExtraKeys.vopSnapshot];
final override = extra[TrainingExtraKeys.manualOverrides];
```

**Archivos afectados**:
- `lib/features/training_feature/widgets/volume_range_muscle_table.dart` (Tab 2)
- `lib/features/training_feature/widgets/macrocycle_overview_tab.dart` (Tab 3)
- `lib/features/training_feature/widgets/weekly_plan_tab.dart` (Tab 4)
- `lib/features/training_feature/providers/training_plan_provider.dart`
- `lib/domain/services/training_program_engine.dart`

---

### 2. VOP sin SSOT (Merge Destructivo)

**Síntoma**: Tab 3 pide "falta vop para back" aunque Tab 2 generó datos.

**Causa root**:
- Tab 2 calcula `finalTargetSetsByMuscleUi` pero NO lo persiste con clave determinista
- Cada re-carga del cliente, datos pueden perder
- Tabs 3/4 leen keys distintas (`targetSetsByMuscle` vs `finalTargetSetsByMuscleUi`)

**Fix**:
- Crear `VopSnapshot` modelo canónico
- Tab 2 → escribe `vopSnapshot` (SSOT singular)
- Migración automática: si `vopSnapshot` no existe, construir desde legacy keys
- Tabs 3/4 → leen SOLO `vopSnapshot`

---

### 3. Músculos no canónicos (Grupo vs Individual)

**Síntoma**: Tab 4 busca ejercicios por 'back' pero catálogo indexado por 'lats', 'upper_back', 'traps'.

**Causa root**:
- Normalizer mapea "Espalda" → 'back_group'
- 'back_group' NO se expande a individuales antes de persistir
- Tab 4 intenta lookup por 'back', no encuentra → placeholder

**Fix**:
- Expand groups ANTES de persistir snapshot
- `vopSnapshot.setsByMuscle` SOLO contiene 14 individuales
- UI puede mostrar grupos, pero SSOT es per-músculo

---

## CRITERIOS DE ACEPTACIÓN

✅ **Analyzer**: Sin errores de compilación (flutter analyze limpio)

✅ **Fase 1**: Lectura de todos los inputs desde `training.extra` usa constantes `TrainingExtraKeys.*`

✅ **Fases 2-8**: Cada fase registra decisions en DecisionTrace; no fallback silencioso

✅ **SSOT VOP**: `vopSnapshot` es Key singular en `training.extra`; Escrito UNA VEZ (Tab 2); Leído sin merge destructivo

✅ **Tab 2**: Escribe `vopSnapshot` canónico (14 músculos) + migración legacy

✅ **Tab 3**: Lee `vopSnapshot`; no "falta vop para X" si existe snapshot; per-músculo baseline

✅ **Tab 4**: Lee `vopSnapshot`; distribuye per-músculo VOP; lookups de ejercicio usan canónicos

✅ **Muscle Keys**: `MuscleKeys.all` contiene 14 individuales; normalizer expande grupos; adapters en UI

✅ **Catálogo**: ExerciseSelection indexa por músculos canónicos; sin placeholders si catálogo vacío

---

## PRÓXIMOS PASOS (ORDEN EJECUCIÓN)

1. Reparar keys string-literal → TrainingExtraKeys (FASE 2)
2. Crear MuscleKeys canon + normalizer (FASE 3)
3. Crear VopSnapshot + Migrator (FASE 4)
4. Implementar Tab 2 escritura + Tab 3/4 lectura (FASE 5)
5. Auditar motor 8 fases wiring (FASE 6)
6. Tests unitarios P0 (FASE 7)
7. Integración + validación end-to-end (FASE 8)

---

**Fin de auditoría**. Proceder a FASE 2: Congelación de keys.
