# T02 - MAPA DE EJECUCION REAL (RUNTIME)

## 1) Entrada real de modulo
1. Main shell monta `TrainingScreen` en indice 7.
2. `TrainingScreen` renderiza `TrainingWorkspaceRoot`.
3. `TrainingWorkspaceRoot` renderiza `TrainingWorkspaceScreen`.

Evidencia:
- lib/features/main_shell/screen/main_shell_screen.dart:431
- lib/features/training_feature/training_screen.dart:9
- lib/features/training_feature/screens/training_workspace_root.dart:24

## 2) Flujo A (Generar en Workspace)
1. UI llama `_generarPlan()` en `TrainingWorkspaceScreen`.
2. `_generarPlan()` llama `trainingPlanProvider.generatePlan(profile, landmarks, intensitySplit)`.
3. `generatePlan()` valida flujo estructurado y campos.
4. `generatePlan()` recarga cliente desde repositorio.
5. `generatePlan()` ejecuta `UnifiedTrainingService.generateFullProgram(...)`.
6. `UnifiedTrainingService` llama `TrainingOrchestratorV3.generatePlan(...)`.
7. `TrainingOrchestratorV3` llama `MotorV3Orchestrator.generateProgram(...)`.
8. Provider crea ciclo freeze, persiste ciclo, persiste plan en `trainingPlans`, actualiza `activePlanId`, y vuelve a guardar.

Evidencia:
- lib/features/training_feature/screens/training_workspace_screen.dart:3065
- lib/features/training_feature/providers/training_plan_provider.dart:684
- lib/features/training_feature/providers/training_plan_provider.dart:912
- lib/domain/training_v3/services/unified_training_service.dart:28
- lib/domain/training_v3/orchestrator/training_orchestrator_v3.dart:111
- lib/domain/training_v3/orchestrator/training_orchestrator_v3.dart:186
- lib/domain/training_v3/services/motor_v3_orchestrator.dart:133
- lib/features/training_feature/providers/training_plan_provider.dart:1065

## 3) Flujo B (Adaptar / Deload en Workspace)
1. UI llama `generatePlanFromActiveCycle(now)`.
2. Provider carga cliente + ciclo activo.
3. Si hay freeze snapshot: retorna plan desde snapshot sin regenerar.
4. Si no hay ciclo/snapshot: bootstrap de ciclo base y persistencia.
5. Provider ejecuta `TrainingOrchestratorV3.generatePlan(...)`.
6. Provider valida hard constraints, persiste plan y `activePlanId`.

Evidencia:
- lib/features/training_feature/screens/training_workspace_screen.dart:3264
- lib/features/training_feature/providers/training_plan_provider.dart:1414
- lib/features/training_feature/providers/training_plan_provider.dart:1480
- lib/features/training_feature/providers/training_plan_provider.dart:1547
- lib/features/training_feature/providers/training_plan_provider.dart:1739
- lib/features/training_feature/providers/training_plan_provider.dart:1933

## 4) Flujo C (Dashboard legacy)
`TrainingDashboardScreen` existe y llama `generatePlanFromActiveCycle`, pero no es la pantalla usada por el entrypoint real de `TrainingScreen`.

Evidencia:
- lib/features/training_feature/screens/training_dashboard_screen.dart:1928
- lib/features/training_feature/training_screen.dart:9
- busqueda de uso de symbol `TrainingDashboardScreen` sin referencias de montaje runtime fuera del propio archivo.

## 5) Orden exacto de persistencia observada (plan)
1. `trainingPlans` se actualiza en objeto `Client`.
2. `training.extra.activePlanId` se actualiza.
3. `ClientRepository.saveClient()` guarda local (`_local.saveClient`).
4. `DatabaseHelper.upsertClient()` serializa JSON completo y lo guarda en tabla `clients`.
5. Push remoto se intenta en segundo plano con debounce; no bloquea.

Evidencia:
- lib/features/training_feature/providers/training_plan_provider.dart:1942
- lib/features/training_feature/providers/training_plan_provider.dart:1954
- lib/data/repositories/client_repository.dart:23
- lib/data/datasources/local/local_client_datasource_impl.dart:22
- lib/data/datasources/local/database_helper.dart:275
- lib/data/repositories/client_repository.dart:28
