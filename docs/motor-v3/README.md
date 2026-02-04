# Motor V3 - Sistema de Generación de Planes de Entrenamiento Científico

## 🎯 Introducción

El **Motor V3** es el sistema de generación de planes de entrenamiento basado en evidencia científica (7 documentos de fundamento). Implementa un pipeline completo que va desde la ingesta de datos del cliente hasta la generación de un plan personalizado y científicamente validado.

---

## 🏗️ Arquitectura

### Componentes Principales

```
┌─────────────────────────────────────────────────────────────────┐
│                    TrainingOrchestratorV3                       │
│                      (API Pública)                              │
│  - Convierte Client → UserProfile                              │
│  - Valida datos mínimos                                         │
│  - Retorna TrainingProgramV3Result tipado                       │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                   HybridOrchestratorV3                          │
│                (Pipeline Científico + ML)                       │
│  1. Generación científica pura (MotorV3Orchestrator)           │
│  2. Extracción de features (45 características)                │
│  3. Refinamientos ML opcionales                                 │
│  4. Registro de predicciones                                    │
│  5. Generación de explicabilidad                                │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                   MotorV3Orchestrator                           │
│              (Generación Científica Pura)                       │
│  Integra 7 engines científicos                                 │
└─────────────────────────────────────────────────────────────────┘
```

## 📚 Documentación Científica

Ver `/docs/scientific-foundation/` para los 7 documentos base.

## 🔧 Uso del Motor V3

```dart
final orchestrator = TrainingOrchestratorV3(
  strategy: RuleBasedStrategy(),
  recordPredictions: false,
);

final result = await orchestrator.generatePlan(
  client: myClient,
  exercises: exerciseCatalog,
  asOfDate: DateTime.now(),
);
```

Ver ejemplos completos en el README extendido.
