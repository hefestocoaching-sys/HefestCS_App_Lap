# T04 - COMPONENTES NOMINALES VS OPERATIVOS

## Operativos (evidencia de invocacion real)
- TrainingWorkspaceScreen
- TrainingPlanProvider.generatePlan
- TrainingPlanProvider.generatePlanFromActiveCycle
- TrainingOrchestratorV3.generatePlan
- MotorV3Orchestrator.generateProgram
- ExerciseSelectionEngine.selectExercises
- TrainingCycleRepositoryImpl.createCycle/upsertCycle

Evidencia:
- lib/features/training_feature/screens/training_workspace_screen.dart:3065
- lib/features/training_feature/providers/training_plan_provider.dart:684
- lib/features/training_feature/providers/training_plan_provider.dart:1414
- lib/domain/training_v3/orchestrator/training_orchestrator_v3.dart:111
- lib/domain/training_v3/services/motor_v3_orchestrator.dart:133
- lib/domain/training_v3/services/motor_v3_orchestrator.dart:1533
- lib/data/repositories/training/training_cycle_repository_impl.dart:45

## Nominales / no operativos (en este runtime auditado)
1. IntensitySplitAllocator
- Solo aparece la declaracion de clase.
- No hay llamadas detectadas.

2. SplitGeneratorEngine
- Existe clase, pero sin invocacion real detectada.
- Solo referencia en comentario dentro de motor.

3. UnifiedTrainingProvider
- Existe provider dedicado, sin consumidores detectados.

4. TrainingDashboardScreen
- Pantalla implementada, no montada por entrada principal de training.

Evidencia:
- lib/domain/training_v3/engines/intensity_split_allocator.dart:21
- lib/domain/training_v3/engines/split_generator_engine.dart:24
- lib/domain/training_v3/services/motor_v3_orchestrator.dart:105
- lib/features/training_feature/providers/unified_training_provider.dart:24
- lib/features/training_feature/training_screen.dart:9
- lib/features/training_feature/screens/training_dashboard_screen.dart:50

## Clasificacion
- IMPLEMENTACION NOMINAL NO OPERATIVA:
  - IntensitySplitAllocator
  - SplitGeneratorEngine
  - UnifiedTrainingProvider (no usado)
  - TrainingDashboardScreen (no usado en entrada real)
