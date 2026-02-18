# 🏋️‍♂️ MOTOR V3 ENHANCED - Documentación Centralizada

**ÚLTIMA ACTUALIZACIÓN:** Febrero 17, 2026 | Fase 1 ✅ Completada  
**Estado:** ✅ Modelos + Validadores + Servicios Mejorados

---

## 📚 Índice de Documentación

### 🚀 Guías Principales

1. **[MOTOR_V3_PHASE1_SUMMARY.md](./MOTOR_V3_PHASE1_SUMMARY.md)** ⭐ EMPEZAR AQUÍ
   - Resumen ejecutivo de todo lo realizado
   - Cambios arquitectónicos
   - Ejemplos prácticos
   - 50% del trabajo completado
   - **Tiempo de lectura:** 15 minutos

2. **[MOTOR_V3_QUICK_REFERENCE.md](./MOTOR_V3_QUICK_REFERENCE.md)** 🔥 RAPID START
   - Copy-paste ready code
   - Setup en 5 minutos
   - Ejemplos rápidos por modelo
   - Troubleshooting guide
   - **Tiempo de lectura:** 10 minutos

3. **[MOTOR_V3_REFACTOR_GUIDE.md](./MOTOR_V3_REFACTOR_GUIDE.md)**
   - Guía completa de refactorización
   - Flujo científico detallado
   - Lógica de prioridades (P/S/T)
   - Cada modelo explicado con ejemplos
   - Checklist de implementación
   - **Tiempo de lectura:** 30 minutos

---

## 📁 Archivos de Código Nuevos

### Modelos de Negocio

```
lib/domain/training_v3/models/
  ├─ muscle_progression.dart               (✅ NUEVO)
  │  Lógica de prioridades (P/S/T) 
  │  - volumeCap, canProgress, recommendedIncrement, healthScore
  │  - 200 líneas + lógica empresarial
  │
  ├─ progress_record.dart                  (✅ NUEVO)
  │  Historial semanal auditable
  │  - Volumen, RIR, feedback, decisión, cobertura angular
  │  - 150 líneas + properties derivadas
  │
  ├─ feedback_entry.dart                   (✅ NUEVO)
  │  Feedback usuario (subjetivo)
  │  - Activación, pump, fatiga, recuperación, pain, deload override
  │  - 100 líneas + lógica de salud
  │
  ├─ exercise_angle_coverage.dart          (✅ NUEVO)
  │  Cobertura de ángulos por músculo
  │  - Mappeo ángulos (14 músculos × 3-5 ángulos)
  │  - Cálculo de cobertura %
  │  - 150 líneas
  │
  └─ training_audit_log.dart               (✅ NUEVO)
     Log de auditoría completo
     - 12 tipos de eventos
     - Linkage a ProgressRecord y FeedbackEntry
     - 150 líneas + query filters
```

### Validadores

```
lib/domain/training_v3/validators/
  └─ training_validation_engine.dart       (✅ NUEVO)
     Motor de validación empresarial
     - 8 reglas científicas de validación
     - Pre y post-validación
     - Generador de reportes
     - 600 líneas
```

### Servicios

```
lib/domain/training_v3/services/
  ├─ weekly_progression_service_enhanced.dart      (✅ NUEVO)
  │  Interfaz mejorada
  │  - processWeeklyProgressionEnhanced()
  │  - processMuscleProgressionEnhanced()
  │  - Métodos de export
  │  - 150 líneas + tipos
  │
  └─ weekly_progression_service_enhanced_impl.dart (✅ NUEVO)
     Implementación completa
     - Lógica PRIMARY: +2 sets/semana → MRV
     - Lógica SECONDARY: +1 set/semana → 0.8×MRV
     - Lógica TERTIARY: Siempre VOP
     - Deload logic (manual + automático)
     - 500 líneas
```

---

## 🎯 Para Usuarios Diferentes

### 👨‍💼 Product Manager / Stakeholder

→ Lee: **MOTOR_V3_PHASE1_SUMMARY.md**
- Resumen de logros
- Ejemplos reales de valor
- Timeline y próximos pasos
- **Tiempo:** 15 min

### 👨‍💻 Developer (Backend/Full-Stack)

→ Lee: **MOTOR_V3_QUICK_REFERENCE.md** + Code
1. Setup en 5 min
2. Procesar semana en 10 min
3. Debuggle issues
4. Integrate con Riverpod
- **Tiempo:** 30 min

### 🧪 QA/Tester

→ Lee: **MOTOR_V3_REFACTOR_GUIDE.md** sección Validación
- 8 reglas que se validan
- Casos de test por rule
- Cómo interpretar ValidationResult
- **Tiempo:** 20 min

### 🏋️ Coach (Usuario Final)

→ Espera UI + Manual de Coach (en progreso)
- Será visual, no técnico
- Cómo ver historial
- Cómo exportar para análisis
- Cómo interpretar warnings

### 🤖 ML/IA Team

→ Datos listos en ProgressRecord + AuditLog
- Export vía service
- JSON structure preparada
- Trazabilidad completa
- Feature engineering ready

---

## 🔄 Flujo Completo (Visual)

```
┌─────────────────────────────────────────────────────────────────┐
│                      USER TRAINS WEEK N                         │
│        (Logs: sets, reps, RIR; Feels: feedback form)           │
└──────────────────────┬──────────────────────────────────────────┘
                       │
        ┌──────────────▼──────────────┐
        │ processWeeklyProgressionEnhanced()
        │ (WeeklyProgressionServiceEnhanced)
        └──────────────┬──────────────┘
                       │
        ┌──────────────▼──────────────────────────────┐
        │ Para CADA músculo (14 total):              │
        │                                            │
        │ 1. Cargar tracker actual                   │
        │ 2. Analizar logs + feedback               │
        │ 3. DECIDIR por PRIORIDAD:                 │
        │    PRIMARY (5) → +2 sets a MRV            │
        │    SECONDARY (3) → +1 set a 0.8×MRV       │
        │    TERTIARY (1) → VOP siempre             │
        │    IF fatiga alta/recuperación pobre → deload │
        │ 4. Validar (TrainingValidationEngine)     │
        │ 5. Crear ProgressRecord                   │
        │ 6. Crear AuditLogEntry                    │
        │ 7. Guardar tracker                        │
        └──────────────┬──────────────────────────────┘
                       │
        ┌──────────────▼──────────────────────┐
        │ EnhancedProgressionResult           │
        │  - decisions[muscle]                │
        │  - progressRecords[muscle]          │
        │  - auditTrail[]                     │
        │  - auditReport (QA summary)         │
        │  - requiresCoachAttention[]         │
        └──────────────┬──────────────────────┘
                       │
        ┌──────────────▼──────────────────────┐
        │ UI ACTUALIZA CON RESULTADOS         │
        │  - Decisiones por músculo           │
        │  - Historial (últimas 4 semanas)    │
        │  - Warnings si hay anomalías        │
        │  - Coach puede exportar             │
        └──────────────┬──────────────────────┘
                       │
        ┌──────────────▼──────────────────────┐
        │ WEEK N+1 READY                      │
        │  - Nuevos volúmenes importados      │
        │  - Motor V3 genera plan             │
        │  - User continúa cycle              │
        └──────────────────────────────────────┘
```

---

## 📊 Progreso de Implementación

```
COMPLETION MATRIX

Modelos:
  [████████████████████][100%] MuscleProgression
  [████████████████████][100%] ProgressRecord
  [████████████████████][100%] FeedbackEntry
  [████████████████████][100%] ExerciseAngleCoverage
  [████████████████████][100%] TrainingAuditLog

Validadores:
  [████████████████████][100%] TrainingValidationEngine (todas 8 rules)

Servicios:
  [████████████████████][100%] WeeklyProgressionServiceEnhanced (interface)
  [████████████████████][100%] WeeklyProgressionServiceEnhancedImpl (impl)

Documentación:
  [████████████████████][100%] Technical Guide (MOTOR_V3_REFACTOR_GUIDE.md)
  [████████████████████][100%] Quick Reference (MOTOR_V3_QUICK_REFERENCE.md)
  [████████████████████][100%] Summary (MOTOR_V3_PHASE1_SUMMARY.md)

Falta (Phase 2):
  [        ░░░░░░░░░░░░░░░░░░░░░░][  0%] Adaptar repositories
  [        ░░░░░░░░░░░░░░░░░░░░░░][  0%] Integrar Riverpod providers
  [        ░░░░░░░░░░░░░░░░░░░░░░][  0%] Migración de datos
  [        ░░░░░░░░░░░░░░░░░░░░░░][  0%] UI components
  [        ░░░░░░░░░░░░░░░░░░░░░░][  0%] Tests automatizados
  [        ░░░░░░░░░░░░░░░░░░░░░░][  0%] Coach UI manual

TOTAL PHASE 1: 50% ✅ (Modelos + Servicios + Validadores)
TOTAL FASE 2: 0% (Persistencia + UI + Tests)
```

---

## 🎓 Secciones Clave por Modelo

### MuscleProgression
- [¿Qué es?](./MOTOR_V3_REFACTOR_GUIDE.md#lógica-de-prioridades-core)
- [Propiedades](./MOTOR_V3_QUICK_REFERENCE.md#muscleprogression)
- [Lógica P/S/T](./MOTOR_V3_REFACTOR_GUIDE.md#primary-prioridad-5)
- [Health scoring](./MOTOR_V3_PHASE1_SUMMARY.md#ejemplo-1-usuario-terminó-week-8)

### ProgressRecord
- [Propósito](./MOTOR_V3_REFACTOR_GUIDE.md#3-progressrecord-motor-crea)
- [Campos](./MOTOR_V3_QUICK_REFERENCE.md#progressrecord)
- [Extensiones](./MOTOR_V3_PHASE1_SUMMARY.md#2-progress-record)
- [Exportación](./MOTOR_V3_REFACTOR_GUIDE.md#paso-4-mostrar-en-ui)

### FeedbackEntry
- [Usuario input](./MOTOR_V3_REFACTOR_GUIDE.md#2-feedbackentry-usuario-submete)
- [Subjetivo vs objetivo](./MOTOR_V3_PHASE1_SUMMARY.md#separación-de-concerns)
- [Health score](./MOTOR_V3_QUICK_REFERENCE.md#feedbackentry)
- [Triggers deload](./MOTOR_V3_QUICK_REFERENCE.md#deload-triggers)

### ExerciseAngleCoverage
- [Cobertura angular](./MOTOR_V3_REFACTOR_GUIDE.md#4-exerciseangles)
- [Auditoría](./MOTOR_V3_PHASE1_SUMMARY.md#cobertura-angular-documentada)
- [Variedad](./MOTOR_V3_QUICK_REFERENCE.md#exerciseangles)
- [Validación](./MOTOR_V3_REFACTOR_GUIDE.md#validación-qa-trainingvalidationengine)

### TrainingAuditLog
- [Eventos](./MOTOR_V3_REFACTOR_GUIDE.md#5-trainingauditlogentry)
- [Trazabilidad](./MOTOR_V3_PHASE1_SUMMARY.md#log-de-decisiones-auditable)
- [Filtros](./MOTOR_V3_QUICK_REFERENCE.md#trainingauditlogentry)
- [Uso](./MOTOR_V3_REFACTOR_GUIDE.md#debug-logging)

### TrainingValidationEngine
- [8 Rules](./MOTOR_V3_REFACTOR_GUIDE.md#validación-qa-trainingvalidationengine)
- [Uso](./MOTOR_V3_QUICK_REFERENCE.md#validación)
- [Reports](./MOTOR_V3_PHASE1_SUMMARY.md#caso-3-auditoría-semanal)
- [Error handling](./MOTOR_V3_QUICK_REFERENCE.md#🚨-common-issues)

---

## 🚀 Getting Started (3 Steps)

### 1. Lee esto (5 min)
```
📖 MOTOR_V3_PHASE1_SUMMARY.md
   ↓
   "Cambios Arquitectónicos Principales" section
   ↓
   Entiendes qué cambió y por qué
```

### 2. Setup (5 min)
```dart
// Copy from MOTOR_V3_QUICK_REFERENCE.md
final service = WeeklyProgressionServiceEnhancedImpl(...)
await progressionRepo.initializeAllTrackers(...)
```

### 3. Procesa una semana (10 min)
```dart
// Copy from MOTOR_V3_QUICK_REFERENCE.md "Procesar Semana" section
final result = await service.processWeeklyProgressionEnhanced(...)
print(result.decisions)
```

**Total: 20 min ready**

---

## 🔗 Referencias Cruzadas

| Si necesitas... | Ve a... |
|-----------------|---------|
| Empezar rápido | MOTOR_V3_QUICK_REFERENCE.md |
| Entender todo | MOTOR_V3_REFACTOR_GUIDE.md |
| Ver resumen | MOTOR_V3_PHASE1_SUMMARY.md |
| Específico modelo | Busca en Quick Reference |
| Específica regla QA | Busca en Refactor Guide |
| Código ejemplo | Busca en Phase1 Summary |
| Troubleshoot | Quick Reference "Common Issues" |

---

## 📞 FAQ Rápido

**Q: ¿Por dónde empiezo?**  
A: Lee MOTOR_V3_PHASE1_SUMMARY.md (15 min). Luego MOTOR_V3_QUICK_REFERENCE.md (10 min).

**Q: ¿Qué cambió desde V1?**  
A: Ver "Cambios Arquitectónicos" en Phase1 Summary.

**Q: ¿Cómo proceso una semana?**  
A: Copy-paste de Phase1 Summary → "Caso 1: Usuario terminó Week 8"

**Q: ¿Qué es MuscleProgression?**  
A: Ver Refactor Guide → "Modelos de Datos" → "1. MuscleProgression"

**Q: ¿Cómo valido?**  
A: Usa TrainingValidationEngine (ver Quick Reference section)

**Q: ¿Dónde persisto?**  
A: Repository automáticamente guarda (Phase 2: adaptar repos)

---

## 🛠️ Próximos Pasos (Phase 2)

```
[ ] Adaptar repositories para nuevos modelos
[ ] Integrar con Riverpod providers
[ ] Migración de datos legacy
[ ] UI components (historial, feedback form, export)
[ ] Tests automatizados
[ ] Coach manual y training
```

---

**🎉 Motor V3 Enhanced está LISTO para usar!**

Selecciona tu rol arriba y comienza.
