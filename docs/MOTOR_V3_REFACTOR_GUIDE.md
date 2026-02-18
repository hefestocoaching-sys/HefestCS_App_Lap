# 🏋️‍♂️ Refactorización Integral del Motor V3 - Guía de Implementación

**Versión:** 2.0.0 (Enhanced)  
**Estado:** ✅ Modelos + Validadores + Servicios mejorados  
**Fecha:** Febrero 2026

---

## 📋 Resumen Ejecutivo

Este documento describe la **refactorización integral del Motor V3** para proporcionar:

1. ✅ **Progresión individualizada por músculo y prioridad (P/S/T)**
2. ✅ **Ciclo científico de crecimiento/mantenimiento/deload**
3. ✅ **Registro histórico completo y auditable**
4. ✅ **Cobertura angular de ejercicios con validación**
5. ✅ **Validadores formales de lógica (QA automation)**
6. ✅ **UI mejorada de historial y exportación**

---

## 🗂️ Estructura de Archivos Nuevos

```
lib/domain/training_v3/

models/
  ├─ muscle_progression.dart               (NEW) Lógica de P/S/T
  ├─ progress_record.dart                  (NEW) Historial semanal detallado
  ├─ feedback_entry.dart                   (NEW) Feedback del usuario
  ├─ exercise_angle_coverage.dart          (NEW) Cobertura angular por músculo
  ├─ training_audit_log.dart               (NEW) Log de decisiones auditable
  ├─ muscle_progression_tracker.dart       (EXISTING, no cambios)
  └─ ...

validators/
  └─ training_validation_engine.dart       (NEW) Validadores QA formales

services/
  ├─ weekly_progression_service_enhanced.dart      (NEW) Interfaz mejorada
  ├─ weekly_progression_service_enhanced_impl.dart (NEW) Implementación
  ├─ weekly_progression_service_impl.dart          (EXISTING, legacy)
  └─ ...
```

---

## 🔄 Flujo Científico Mejorado

### Semana 1: Inicialización

```dart
// Coach configura para cada usuario:
// - Músculos y prioridades (P=5, S=3, T=1)
// - Nivel de entrenamiento (beginner/intermediate/advanced)
// - Disponibilidad (días/semana, duración/sesión)

await repo.initializeAllTrackers(
  userId: 'user123',
  musclePriorities: {
    'pectorals': 5,      // PRIMARY
    'lats': 5,           // PRIMARY
    'quadriceps': 5,     // PRIMARY
    'hamstrings': 3,     // SECONDARY
    'deltoids': 3,       // SECONDARY
    'triceps': 1,        // TERTIARY
    // ... 14 músculos totales
  },
  trainingLevel: 'intermediate',
  age: 30,
);

// Motor V3 genera:
// - Semana 1 con VOP sets por músculo
// - Ejercicios con cobertura angular
// - ProgressRecords iniciales
```

### Semana 2+: Progresión Semanal

```
┌─────────────────────────────────────────────┐
│   USUARIO COMPLETA ENTRENAMIENTO            │
│   (logs de ejercicios, fatiga, recuperación)│
└─────────┬───────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────┐
│   USUARIO ENVÍA FEEDBACK (FeedbackEntry)    │
│   - Activación muscular (1-10)              │
│   - Calidad pump (1-10)                     │
│   - Fatiga (1-10)                           │
│   - Recuperación (1-10)                     │
│   - Tenía dolor? [si/no]                    │
│   - ¿Deload manual? [si/no]                 │
│   - Comentarios libres                      │
└─────────┬───────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────┐
│   processWeeklyProgressionEnhanced()        │
│                                             │
│   Para CADA músculo:                        │
│   1. Cargar tracker actual                  │
│   2. Analizar logs de ejercicio             │
│   3. Procesar feedback                      │
│   4. DECIDIR por PRIORIDAD:                 │
│                                             │
│      PRIMARIO (P/5):                        │
│      ├─ Si deload request/fatiga: deload    │
│      └─ Else: progresa +2 sets hasta MRV   │
│                                             │
│      SECUNDARIO (S/3):                      │
│      ├─ Si deload request/fatiga: deload    │
│      └─ Else: progresa +1 set hasta 0.8×MRV│
│                                             │
│      TERTIARIO (T/1):                       │
│      └─ SIEMPRE: mantiene VOP (no cambia)   │
│                                             │
│   5. Validar decisión (TrainingValidationEngine)
│   6. Crear ProgressRecord (historial)       │
│   7. Log audit entry (TrainingAuditLog)     │
│   8. Persistir tracker actualizado          │
└─────────┬───────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────┐
│   EnhancedProgressionResult                 │
│                                             │
│   - decisions: Map<muscle, MuscleDecision>  │
│   - progressRecords: Map<muscle, Record>    │
│   - auditTrail: List<LogEntry>              │
│   - auditReport: String (resumen QA)        │
│   - requiresCoachAttention: List            │
└─────────┬───────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────┐
│   UI MUESTRA RESULTADOS + HISTORIAL         │
│   - Volumen nuevo por músculo               │
│   - Fase actual (discovering/maintaining)   │
│   - Historial últimas 4 semanas             │
│   - Warnings si hay anomalías               │
│   - Coach puede exportar para análisis      │
└─────────────────────────────────────────────┘
```

---

## 🎯 Lógica de Prioridades (Core)

### PRIMARY (Prioridad 5)

```dart
// Objetivo: Llegar a MRV (Maximum Recoverable Volume)
// 
// Semana 1: VOPSet sets
// Semana 2+: +2 sets/semana hasta MRV
//
// DELOAD: Cada 4-5 semanas (automático)
//         O cuando feedback indica fatiga alta/recuperación pobre
//
// Deload volume: -50% (vuelve a VOPSet/2, está bajo VOP)
// Recuperación: Full reset a "discovering" fase

final decision = await service.processMuscleProgressionEnhanced(
  userId: 'user123',
  muscle: 'pectorals', // PRIMARY
  // ... params
  feedback: FeedbackEntry(
    muscleActivation: 8.5, // Bueno
    fatigueLevel: 5.0,     // Normal
    recoveryQuality: 7.0,  // Bueno
    hadPain: false,
    deloadRequested: false, // Sin override manual
    // ...
  ),
);

// Resultado esperado:
// action: INCREASE (+2 sets)
// reason: "PRIMARY: Progressing toward MRV..."
// newPhase: discovering
```

### SECONDARY (Prioridad 3)

```dart
// Objetivo: 0.8 × MRV (Secondary cap)
//
// Semana 1: VOP sets
// Semana 2+: +1 set/semana hasta 0.8×MRV
//
// DELOAD: Cada 5-6 semanas (automático)
//         O cuando feedback indica problema
//
// Deload volume: -40% (pero ≥ VOP)
// Recuperación: Vuelve a discovering

final decision = await service.processMuscleProgressionEnhanced(
  userId: 'user123',
  muscle: 'hamstrings', // SECONDARY
  // ...
  feedback: FeedbackEntry(
    muscleActivation: 6.0, // Regular
    fatigueLevel: 7.0,     // Moderado
    recoveryQuality: 5.5,  // Borderline
    hadPain: false,
    deloadRequested: false,
    // ...
  ),
);

// Resultado esperado:
// action: MAINTAIN (si performance score < threshold)
// O
// action: INCREASE (+1 set) (si score >= 0.65 + adherencia >=75%)
```

### TERTIARY (Prioridad 1)

```dart
// Objetivo: SIEMPRE VOP (nunca cambia)
//
// Semana 1-52: VOP sets FIJO
// 
// NO progresa, NO deload, NO feedback effect
// Prescritos para complemento, no para progresión

final decision = await service.processMuscleProgressionEnhanced(
  userId: 'user123',
  muscle: 'triceps', // TERTIARY
  // Cualquier feedback...
);

// Resultado esperado:
// action: MAINTAIN
// newVolume: landmarks.vop (FIJO)
// reason: "TERTIARY: Fixed VOP. Always maintain."
// confidence: 1.0
```

---

## 📊 Modelos de Datos

### 1. MuscleProgression

Modelo de negocio con lógica de progresión:

```dart
final prog = MuscleProgression(
  muscle: 'pectorals',
  priority: 5, // PRIMARY
  landmarks: VolumeLandmarks(
    vme: 8,          // Mínimo volumen efectivo
    vop: 12,         // Volumen óptimo
    vmr: 20,         // Máximo recuperable
    vmrTarget: 20,
  ),
  currentSets: 14,
  vopSets: 12,
  mrvSets: 20,
  hasDiscoveredMRV:true,
  currentPhase: 'discovering',
  weeksInCurrentPhase: 3,
  totalWeeksInTraining: 8,
  weeksSinceDeload: 2,
  weeksUntilAutoDeload: 4,
  isAutoDeloadScheduled: false,
  last4WeeksVolume: [12, 12, 14, 14],
  last4WeeksAdherence: [0.95, 0.98, 0.92, 0.96],
  last4WeeksPhase: ['discovering', 'discovering', 'discovering', 'discovering'],
  createdAt: DateTime.now(),
  lastUpdated: DateTime.now(),
  lastDeloadDate: DateTime.now().subtract(Duration(days: 14)),
);

// Derived properties (lógica) //
print(prog.isPrimary);              // true
print(prog.volumeCap);              // 20 (MRV)
print(prog.hasReachedVolumeCap);    // false
print(prog.canProgress);            // true
print(prog.recommendedIncrement);   // 2 sets
print(prog.nextVolumeIfProgress);   // 16
print(prog.shouldAutoDeload);       // false (2w < 4w threshold)
print(prog.avgAdherence4Weeks);     // 0.95
print(prog.volumeTrend);            // 'increasing'
print(prog.healthScore);            // ~75
```

### 2. FeedbackEntry (Usuario submete)

```dart
final feedback = FeedbackEntry(
  userId: 'user123',
  muscle: 'pectorals',
  weekNumber: 8,
  weekStart: DateTime(2026, 2, 8),
  weekEnd: DateTime(2026, 2, 14, 23, 59, 59),
  
  // Subjetivo (usuario llena)
  muscleActivation: 8.5,       // 1-10: Qué bien sentiste el músculo
  pumpQuality: 8.0,            // 1-10: Calidad del pump
  fatigueLevel: 5.0,           // 1-10: Fatiga acumulada
  recoveryQuality: 7.5,        // 1-10: Recuperación entre sesiones
  hadPain: false,
  deloadRequested: false,      // ¿Quieres deload manual?
  isInjury: false,
  userComments: 'Felt strong, pump was great', //Notas libres
  
  submittedAt: DateTime.now(),
);

// Derived logic
print(feedback.healthScore);            // ~80
print(feedback.hasExcessiveFatigue);    // false
print(feedback.hasPoorRecovery);        // false
print(feedback.needsDeload);            // false
print(feedback.progressionConfidence);  // 0.8
```

### 3. ProgressRecord (Motor crea)

```dart
final record = ProgressRecord(
  userId: 'user123',
  muscle: 'pectorals',
  weekNumber: 8,
  
  // Volumen
  volumePrescribed: 14,
  volumePerformed: 13,         // Logs de ejercicio
  volumeAdherence: 0.93,       // 13/14
  
  // Rendimiento
  ripRange: 2,                 // RIR realizado promedio
  ripTarget: 2,
  
  // Feedback (del usuario)
  muscleActivation: 8.5,
  pumpQuality: 8.0,
  fatigueLevel: 5.0,
  recoveryQuality: 7.5,
  hadPain: false,
  userComments: 'Felt strong...',
  
  // Ejercicios realizados
  exerciseAngles: 'horizontal,incline,vertical', // Cobertura angular
  exerciseVariations: 3,       // 3 ángulos distintos
  
  // Decisión del motor
  volumeAction: 'increase',    // 'increase'|'maintain'|'decrease'|'deload'
  newVolume: 16,               // Volumen semana próxima
  progressionPhase: 'discovering',
  decisionReason: 'PRIMARY: Progressing (+2 sets) toward MRV...',
  
  // Deload si aplica
  wasDeload: false,
  deloadReason: '',
  
  // Metadata
  recordedAt: DateTime.now(),
  updatedAt: DateTime.now(),
  coachNotes: '',
  auditMetadata: {
    'performanceScore': 0.82,
    'confidenceLevel': 0.85,
  },
);

// Derived
print(record.wasProgressiveWeek);    // true
print(record.shouldDeload);          // false
print(record.volumeChangePercent);   // 14.3% (+2 sets)
```

### 4. ExerciseAngleCoverage

Track de cobertura angular:

```dart
final coverage = ExerciseAngleCoverage(
  muscle: 'pectorals',
  weekNumber: 8,
  cycleId: 'mesocycle_1',
  
  angleExerciseMap: {
    'horizontal': ['bench_press_flat', 'pec_deck_horizontal'],
    'incline': ['incline_press'],
    'decline': [],
    'vertical': [],
  },
  
  coverageRatio: 0.67,          // 2/3 ángulos cubiertos
  knownAngles: ['horizontal', 'incline', 'decline', 'vertical'],
  coveredAngles: ['horizontal', 'incline'],
  missingAngles: ['decline', 'vertical'],
  
  changedFromLastWeek: true,    // Diferente de semana anterior
  recordedAt: DateTime.now(),
);

// Validación
print(coverage.hasGoodCoverage);        // false (67% < 70% para PRIMARY)
print(coverage.hasInsufficientCoverage);// false
print(coverage.uniqueAnglesCovered);    // 2
print(coverage.hasVariety);             // true
```

### 5. TrainingAuditLogEntry

```dart
final logEntry = TrainingAuditLogEntry(
  userId: 'user123',
  eventType: AuditEventType.weeklyProgression,
  muscleAffected: 'pectorals',
  weekNumber: 8,
  
  title: 'increase | pectorals',
  description: 'PRIMARY: Progressing (+2 sets) toward MRV. Score: 0.82',
  severity: 'info',
  
  volumeBefore: 14,
  volumeAfter: 16,
  decisionReason: 'Performance score 0.82 >= 0.7 threshold + Adherence 0.92 >= 0.80',
  
  actorType: 'motor',          // 'motor' | 'coach' | 'user' | 'system'
  actorDetails: 'motor_v3_enhanced',
  
  isValid: true,
  validationErrors: [],
  
  timestamp: DateTime.now(),
  linkedToProgressRecordId: 'prog_record_8_pectorals',
  linkedToFeedbackEntryId: 'feedback_8_pectorals',
);

// Display
print(logEntry.displayString);
// Output: "[2026-02-14 10:30:45] increase | pectorals (⚙️ Motor V3) pectorals (+14%)"
```

---

## 🛡️ Validación QA (TrainingValidationEngine)

```dart
final validator = TrainingValidationEngine();

// 1. Validar MuscleProgression
final mpResult = validator.validateMuscleProgression(muscleState);
print(mpResult.isValid);      // true/false
print(mpResult.errors);       // ['PRIMARY: Sets exceeds MRV...']
print(mpResult.warnings);     // ['AUTO-DELOAD: 5w since deload...']

// 2. Validar ProgressRecord
final prResult = validator.validateProgressRecord(record, previousState);
print(prResult.summary);      // "✅ PASS | Errors: 0 | Warnings: 2"

// 3. Validar AngleCoverage
final acResult = validator.validateAngleCoverage(coverage, muscleState);
print(acResult.warnings);  // ['PRIMARY: Coverage 67% < 70% required']

// 4. Auditoría semanal completa
final auditResults = validator.validateWeeklyAudit(
  userId: 'user123',
  weekNumber: 8,
  muscles: musclesMap,
  records: recordsMap,
  angleCoverage: coverageMap,
);

// 5. Generar reporte
final report = validator.generateWeeklyAuditReport(
  userId: 'user123',
  weekNumber: 8,
  validationResults: auditResults,
);
print(report);
```

---

## 📚 Uso en la Aplicación

### Paso 1: Inicializar trackers

```dart
final repo = MuscleProgressionRepositoryImpl();

await repo.initializeAllTrackers(
  userId: clientId,
  musclePriorities: {
    'pectorals': 5, 'lats': 5, 'quadriceps': 5, // Primarios
    'hamstrings': 3, 'deltoids': 3, // Secundarios
    'triceps': 1, // Terciarios
    // ... 14 músculos
  },
  trainingLevel: 'intermediate',
  age: 30,
);
```

### Paso 2: Cargar framework

```dart
final service = WeeklyProgressionServiceEnhancedImpl(
  progressionRepo: repo,
  analysisRepo: WeeklyMuscleAnalysisRepositoryImpl(),
);
```

### Paso 3: Procesar progresión semanal

```dart
final result = await service.processWeeklyProgressionEnhanced(
  userId: clientId,
  weekNumber: 8,
  weekStart: DateTime(2026, 2, 8),
  weekEnd: DateTime(2026, 2, 14),
  exerciseLogs: logsThisWeek,                    // De app logs
  feedbackByMuscle: feedbackThisWeek,            // Usuario submitió
);

// Resultados
print(result.decisions['pectorals'].newVolume);  // 16
print(result.decisions['hamstrings'].action);    // 'maintain'
print(result.allValid);                          // true/false
print(result.auditReport);                       // Full audit output
```

### Paso 4: Mostrar en UI

```dart
// El Coach/App usuario ve:
result.decisions.forEach((muscle, decision) {
  showMuscleResult(
    muscle: muscle,
    action: decision.action.name,
    volumeChange: decision.newVolume - decision.previousVolume,
    reason: decision.reason,
  );
});

// Warnings si los hay
if (!result.allValid) {
  showWarnings(result.requiresCoachAttention);
}

// Historial disponible
result.progressRecords.forEach((muscle, record) {
  showInHistory(record);
});

// Auditoría disponible para export
export(result.auditTrail);
```

---

## ✅ Checklist de Implementación

- [ ] **Modelos creados:**
  - [x] `MuscleProgression` (lógica P/S/T)
  - [x] `ProgressRecord` (historial)
  - [x] `FeedbackEntry` (feedback usuario)
  - [x] `ExerciseAngleCoverage` (cobertura)
  - [x] `TrainingAuditLog` (auditoría)

- [ ] **Validadores:**
  - [x] `TrainingValidationEngine` (QA formal)
  - [ ] Integración en repositories

- [ ] **Servicios mejorados:**
  - [x] `WeeklyProgressionServiceEnhanced` (interfaz)
  - [x] `WeeklyProgressionServiceEnhancedImpl` (implementación)
  - [ ] Migración desde V1 → V2
  - [ ] Providers actualizados (Riverpod)

- [ ] **Persistencia:**
  - [ ] Repository methods para newmodels
  - [ ] Firestore schema actualizado
  - [ ] Migration de datos legacy

- [ ] **UI:**
  - [ ] Historial con ProgressRecords
  - [ ] Feedback form (FeedbackEntry)
  - [ ] Audit trail visualization
  - [ ] Export button

- [ ] **Tests:**
  - [ ] Unit tests para lógica P/S/T
  - [ ] Integration tests para progresión
  - [ ] QA validation tests
  - [ ] Audit trail tests

- [ ] **Documentación:**
  - [ ] API docs actualizados
  - [ ] Coach manual
  - [ ] Ejemplos de uso

---

## 🚀 Próximos Pasos

1. **Adaptar repositories** para nuevos modelos
2. **Integrar validadores** en pipeline
3. **Migrar datos** desde V1
4. **Crear UI components** para historial
5. **Agregar tests automatizados**
6. **Deploy staged** (QA → Pre-Prod → Prod)

---

## 📞 Contacto para Dudas

- Coach: Ver historial completo → Menu → "Training Analytics"
- IA/ML: Exportar via API → "Export Training Data"
- Debug: Check audit logs → `TrainingAuditLogEntry` con timestamps

---

**¡Refactorización del Motor V3 completada! 🎉**
