# 📚 ÍNDICE DE DOCUMENTACIÓN - CONTRATO DE BITÁCORA

## 🎯 Inicio Rápido

Si eres nuevo en el proyecto, empieza aquí:

1. **[TRAINING_LOG_CONTRACT_FROZEN.md](TRAINING_LOG_CONTRACT_FROZEN.md)** ⭐  
   **Resumen ejecutivo** del contrato congelado v1.0.0.  
   Lectura: ~10 minutos.

2. **[training_log_usage_examples.dart](training_log_usage_examples.dart)**  
   **Ejemplos de código** para app móvil (10 casos de uso).  
   Lectura: ~15 minutos.

3. **[../lib/domain/entities/training_session_log.dart](../lib/domain/entities/training_session_log.dart)**  
   **Código fuente** del contrato con documentación completa.  
   Lectura: ~20 minutos.

---

## 📋 Documentos por Audiencia

### Para **Desarrolladores de App Móvil**

Leer en este orden:

1. [TRAINING_LOG_CONTRACT_FROZEN.md](TRAINING_LOG_CONTRACT_FROZEN.md) → Resumen del contrato
2. [training_log_usage_examples.dart](training_log_usage_examples.dart) → Ejemplos prácticos
3. [../lib/domain/entities/training_session_log.dart](../lib/domain/entities/training_session_log.dart) → Modelo completo
4. [../test/domain/entities/training_session_log_test.dart](../test/domain/entities/training_session_log_test.dart) → Tests (casos edge)

**Tiempo total**: ~45 minutos

---

### Para **Arquitectos de Sistema**

Leer en este orden:

1. [TRAINING_LOG_CONTRACT_AUDIT.md](TRAINING_LOG_CONTRACT_AUDIT.md) → Auditoría técnica completa
2. [TRAINING_LOG_CONTRACT_FROZEN.md](TRAINING_LOG_CONTRACT_FROZEN.md) → Decisiones de diseño
3. [../lib/domain/services/training_feedback_aggregator_service.dart](../lib/domain/services/training_feedback_aggregator_service.dart) → Agregador semanal
4. [../lib/domain/entities/weekly_training_feedback_summary.dart](../lib/domain/entities/weekly_training_feedback_summary.dart) → Resumen derivado

**Tiempo total**: ~60 minutos

---

### Para **Científicos del Ejercicio / Coaches**

Leer en este orden:

1. [TRAINING_LOG_CONTRACT_FROZEN.md](TRAINING_LOG_CONTRACT_FROZEN.md) → Campos y capacidades
2. [TRAINING_LOG_CONTRACT_AUDIT.md](TRAINING_LOG_CONTRACT_AUDIT.md) → Análisis campo por campo
3. [../lib/domain/services/phase_8_adaptation_service.dart](../lib/domain/services/phase_8_adaptation_service.dart) → Lógica de adaptación

**Tiempo total**: ~40 minutos

---

## 🗂️ Todos los Documentos

### Documentación de Contrato

| Documento | Propósito | Audiencia | Estado |
|-----------|-----------|-----------|--------|
| [TRAINING_LOG_CONTRACT_FROZEN.md](TRAINING_LOG_CONTRACT_FROZEN.md) | Resumen ejecutivo del contrato v1.0.0 | Todos | ✅ Congelado |
| [TRAINING_LOG_CONTRACT_AUDIT.md](TRAINING_LOG_CONTRACT_AUDIT.md) | Auditoría técnica completa (campo por campo) | Arquitectos, Backend | ✅ Completo |
| [training_log_usage_examples.dart](training_log_usage_examples.dart) | Ejemplos de código (10 casos de uso) | Móvil, Frontend | ✅ Completo |

### Código Fuente

| Archivo | Propósito | Estado |
|---------|-----------|--------|
| [../lib/domain/entities/training_session_log.dart](../lib/domain/entities/training_session_log.dart) | Modelo `TrainingSessionLogV2` + helpers | ✅ v1.0.0 |
| [../lib/domain/entities/weekly_training_feedback_summary.dart](../lib/domain/entities/weekly_training_feedback_summary.dart) | Resumen semanal derivado | ✅ Completo |
| [../lib/domain/services/training_feedback_aggregator_service.dart](../lib/domain/services/training_feedback_aggregator_service.dart) | Servicio de agregación | ✅ Completo |
| [../lib/domain/services/phase_8_adaptation_service.dart](../lib/domain/services/phase_8_adaptation_service.dart) | Consumidor final (motor) | ✅ Completo |

### Tests

| Archivo | Propósito | Cobertura |
|---------|-----------|-----------|
| [../test/domain/entities/training_session_log_test.dart](../test/domain/entities/training_session_log_test.dart) | Tests unitarios del contrato | ✅ 23/23 |
| [../test/domain/services/training_feedback_aggregator_service_test.dart](../test/domain/services/training_feedback_aggregator_service_test.dart) | Tests del agregador | ✅ Completo |
| [../test/phase_8_adaptation_wiring_test.dart](../test/phase_8_adaptation_wiring_test.dart) | Tests de integración Phase 8 | ✅ 6/6 |

---

## 🔄 Flujo de Datos (Referencia Rápida)

```
┌─────────────────────────────────────────────────────────────────┐
│ 📱 MOBILE APP                                                   │
│ - Usuario registra sesión                                       │
│ - Genera UUID (offline-first)                                   │
│ - Normaliza fecha a medianoche                                  │
│ - Valida con log.validate()                                     │
│ - Guarda en local DB (SQLite/Hive)                             │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼ (sync cuando hay conexión)
┌─────────────────────────────────────────────────────────────────┐
│ ☁️ SERVIDOR (Firebase/Backend)                                  │
│ - Recibe JSON via HTTP POST                                     │
│ - Valida schemaVersion                                          │
│ - Persiste en DB centralizada                                   │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼ (descarga periódica)
┌─────────────────────────────────────────────────────────────────┐
│ 💻 DESKTOP APP                                                  │
│ - Lee logs de última semana                                     │
│ - Pasa a TrainingFeedbackAggregatorService                      │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│ 🧮 TrainingFeedbackAggregatorService                            │
│ - Filtra logs de semana (lunes-domingo)                         │
│ - Calcula adherenceRatio, avgRIR, avgEffort                    │
│ - Determina signal (positive/ambiguous/negative)                │
│ - Determina fatigueExpectation (low/moderate/high)              │
│ - Genera WeeklyTrainingFeedbackSummary                          │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│ 🧠 Phase8AdaptationService                                      │
│ - Lee WeeklyTrainingFeedbackSummary                             │
│ - Decide: maintain / progress / deload                          │
│ - Aplica volumeFactor (0.85 / 1.0 / 1.05-1.08)                 │
│ - Genera plan adaptado                                          │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📊 Campos del Contrato (Referencia Rápida)

### Identificación (7 campos)

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | String | UUID único (offline-first) |
| `clientId` | String | ID del cliente |
| `exerciseId` | String | ID del ejercicio |
| `sessionDate` | DateTime | Fecha normalizada (medianoche) |
| `createdAt` | DateTime | Timestamp de creación |
| `source` | String | 'mobile' \| 'desktop' |
| `schemaVersion` | String | Versión del contrato (ej: 'v1.0.0') |

### Volumen (2 campos)

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `plannedSets` | int | Series planificadas |
| `completedSets` | int | Series completadas |

### Intensidad (2 campos)

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `avgReportedRIR` | double | RIR promedio [0.0-5.0] |
| `perceivedEffort` | int | RPE general [1-10] |

### Alarmas (3 campos)

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `stoppedEarly` | bool | Sesión interrumpida (CRÍTICO) |
| `painFlag` | bool | Dolor reportado (CRÍTICO) |
| `formDegradation` | bool | Degradación técnica |

### Notas (1 campo)

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `notes` | String? | Texto libre (opcional) |

**Total**: 15 campos (14 requeridos + 1 opcional)

---

## 🔧 Helpers Disponibles

| Función | Propósito | Firma |
|---------|-----------|-------|
| `normalizeTrainingLogDate` | Normalizar fecha a medianoche | `DateTime → DateTime` |
| `upsertTrainingSessionLogByDateV2` | Merge offline-first | `List<Log>, Log → List<Log>` |

---

## ✅ Criterios de Validación

```dart
void validate() {
  ✅ avgReportedRIR ∈ [0.0, 5.0]
  ✅ perceivedEffort ∈ [1, 10]
  ✅ completedSets ≥ 0
  ✅ completedSets ≤ plannedSets
  ✅ schemaVersion no vacío
  ✅ source ∈ {'mobile', 'desktop'}
  ✅ completedSets == 0 → stoppedEarly == true
}
```

---

## 🚀 Próximos Pasos (NO HACER AÚN)

⏸️ **PENDIENTE DE APROBACIÓN**:
- DB de ejercicios (catálogo)
- DB de nutrición (macros, alimentos)
- Integración con Firebase
- App móvil (implementación real)

⚠️ **NO AVANZAR SIN CONFIRMACIÓN EXPLÍCITA DEL USUARIO**.

---

## 📞 Contacto

Para dudas sobre este contrato:
1. Leer [TRAINING_LOG_CONTRACT_FROZEN.md](TRAINING_LOG_CONTRACT_FROZEN.md)
2. Revisar [training_log_usage_examples.dart](training_log_usage_examples.dart)
3. Consultar [TRAINING_LOG_CONTRACT_AUDIT.md](TRAINING_LOG_CONTRACT_AUDIT.md)

---

**Versión del Contrato**: v1.0.0  
**Fecha de Congelamiento**: 30 de diciembre de 2025  
**Estado**: ✅ CONGELADO PARA PRODUCCIÓN
