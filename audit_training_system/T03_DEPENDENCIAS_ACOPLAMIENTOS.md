# T03 - DEPENDENCIAS Y ACOPLAMIENTOS REALES

## Grafo operativo principal
TrainingWorkspaceScreen
-> trainingPlanProvider
-> (generatePlan) UnifiedTrainingService
-> TrainingOrchestratorV3
-> MotorV3Orchestrator
-> ExerciseCatalogV3
-> TrainingCycleRepositoryImpl
-> ClientRepository
-> Local DB + push remoto no bloqueante

## Acoplamientos criticos
1. Provider con logica de dominio pesada
- `training_plan_provider.dart` concentra reglas de negocio, bootstrap de ciclo, validaciones hard, decision semanal, persistencia de plan y estado UI.

2. Multiples rutas de generacion activas
- `generatePlan()` (ruta Unified service)
- `generatePlanFromActiveCycle()` (ruta ciclo activo)
- `generatePlanV3()` (ruta directa)

3. Dependencia dual de estado
- Estado de plan activo en `training.extra.activePlanId`.
- Estado de ciclo activo en `client.activeCycleId` top-level.
- Tambien existe limpieza de `activeCycleId` en `training.extra`, generando dualidad semantica.

4. Dependencia remota parcialmente desactivada
- `ClinicalRecordsRepository.pushTrainingRecord()` retorna inmediato (sync entrenamiento deshabilitada).
- `SyncService` solo procesa `anthropometry` en cola.

## Evidencia clave
- lib/features/training_feature/providers/training_plan_provider.dart:684
- lib/features/training_feature/providers/training_plan_provider.dart:1414
- lib/features/training_feature/providers/training_plan_provider.dart:2384
- lib/domain/entities/client.dart:60
- lib/features/training_feature/providers/training_plan_provider.dart:2551
- lib/data/repositories/clinical_records_repository.dart:306
- lib/core/services/sync_service.dart:47
