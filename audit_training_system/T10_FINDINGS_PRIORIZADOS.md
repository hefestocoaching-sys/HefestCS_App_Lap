# T10 - FINDINGS PRIORIZADOS (P0/P1/P2)

## P0

### P0-01: Dualidad de ciclo activo (SSOT inconsistente)
- Tipo: VIOLACION DE SSOT
- Severidad: P0
- Descripcion: El ciclo activo es top-level (`client.activeCycleId`), pero hay operaciones que manipulan `activeCycleId` dentro de `training.extra`.
- Riesgo: desalineacion de lectura/escritura entre providers/repositorios y decisiones sobre ciclo activo.
- Evidencia:
  - lib/domain/entities/client.dart:60
  - lib/features/training_feature/providers/training_plan_provider.dart:2551

### P0-02: Ruta de sync training granular no operativa
- Tipo: DEGRADACION SILENCIOSA
- Severidad: P0
- Descripcion: `pushTrainingRecord()` retorna sin ejecutar push; el sistema aparenta flujo normal local.
- Riesgo: divergencia sistematica local/remoto para training records.
- Evidencia:
  - lib/data/repositories/clinical_records_repository.dart:306

## P1

### P1-01: Multiples pipelines de generacion activos
- Tipo: VIOLACION DE CAPAS
- Severidad: P1
- Descripcion: Workspace usa rutas distintas (`generatePlan` vs `generatePlanFromActiveCycle`) segun accion UI.
- Riesgo: comportamiento no uniforme, regresiones por caminos divergentes.
- Evidencia:
  - lib/features/training_feature/screens/training_workspace_screen.dart:3065
  - lib/features/training_feature/screens/training_workspace_screen.dart:3264
  - lib/features/training_feature/providers/training_plan_provider.dart:684
  - lib/features/training_feature/providers/training_plan_provider.dart:1414

### P1-02: Fallback de plan activo cuando activePlanId no resuelve
- Tipo: VIOLACION DE SSOT
- Severidad: P1
- Descripcion: Si `activePlanId` no coincide, se usa plan mas reciente.
- Riesgo: seleccion de plan operativo distinta al puntero SSOT.
- Evidencia:
  - lib/features/training_feature/screens/training_dashboard_screen.dart:134

### P1-03: Queue sync sin rama training
- Tipo: DEGRADACION SILENCIOSA
- Severidad: P1
- Descripcion: `_syncItem` procesa solo `anthropometry`.
- Riesgo: items training en cola no tendran procesamiento equivalente.
- Evidencia:
  - lib/core/services/sync_service.dart:47

## P2

### P2-01: Componentes nominales no operativos
- Tipo: IMPLEMENTACION NOMINAL NO OPERATIVA
- Severidad: P2
- Descripcion: clases/providers/pantallas presentes sin invocacion runtime observada.
- Evidencia:
  - lib/domain/training_v3/engines/intensity_split_allocator.dart:21
  - lib/domain/training_v3/engines/split_generator_engine.dart:24
  - lib/features/training_feature/providers/unified_training_provider.dart:24
  - lib/features/training_feature/screens/training_dashboard_screen.dart:50

### P2-02: Concentracion de responsabilidades en provider
- Tipo: VIOLACION DE CAPAS
- Severidad: P2
- Descripcion: `training_plan_provider.dart` mezcla logica de dominio, SSOT, persistencia y estado UI.
- Evidencia:
  - lib/features/training_feature/providers/training_plan_provider.dart:684-2205
