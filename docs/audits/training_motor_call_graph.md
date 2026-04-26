# Training Motor Call Graph (Forensic)

## 1) Ruta principal real (pantalla a persistencia)

1. UI trigger
- Archivo: lib/features/training_feature/screens/training_workspace_screen.dart
- Metodos: _generarPlan, _regenerarPlan, _adaptarPlan, accion deload
- Llama: trainingPlanProvider.notifier.generatePlanFromActiveCycle(...)

2. Provider principal
- Archivo: lib/features/training_feature/providers/training_plan_provider.dart
- Clase: TrainingPlanNotifier
- Metodo: generatePlanFromActiveCycle
- Acciones:
  - valida gate de flujo (TrainingPipelineGuard)
  - carga client/ciclo
  - bootstrap de ciclo si aplica
  - carga catalogo
  - ejecuta TrainingOrchestratorV3
  - persiste plan + ciclo + extra

3. Orquestador
- Archivo: lib/domain/training_v3/orchestrator/training_orchestrator_v3.dart
- Metodo: generatePlan
- Accion: adapta Client -> UserProfile y delega en MotorV3Orchestrator

4. Motor
- Archivo: lib/domain/training_v3/services/motor_v3_orchestrator.dart
- Metodo: generateProgram
- Acciones:
  - resolveVolumeTargets
  - resolveSplit
  - feasibilityErrors
  - resolveIntensitySplit
  - resolveMesocycleExercisePoolByMuscle
  - buildRealTrainingPlan

5. Builder de semana
- Archivo: lib/domain/training_v3/services/cycle_template_builder.dart
- Metodo: buildBaseWeek
- Acciones:
  - distribucion por dia
  - seleccion de ejercicios
  - intensidad por aparicion
  - pairing + slots
  - caps

6. Engines llamados en construccion
- lib/domain/training_v3/engines/intensity_distribution_engine.dart
- lib/domain/training_v3/engines/session_structure_engine.dart
- lib/domain/training_v3/engines/ordering_engine.dart
- lib/domain/training_v3/engines/antagonist_pairing_engine.dart
- lib/domain/training_v3/data/interference_matrix.dart

7. Validacion y retorno
- motor_v3_orchestrator.dart:
  - _validateExerciseCoverage
  - checks de factibilidad
- retorna planConfig al provider

8. Persistencia final
- training_plan_provider.dart:
  - client.trainingPlans[]
  - training.extra.activePlanId
  - trainingCycles + freezePlanSnapshot (via repository)
  - weeklyDecisionArtifactsV1

## 2) Subrutas importantes

### 2.1 Gate de flujo
- training_pipeline_guard.dart
- allowedStage:
  interview -> landmarks -> intensity -> gymExercises -> plan

### 2.2 Landmarks
- landmark_engine.dart
- lee muscleLandmarks persistidos o calcula desde tabla SSOT

### 2.3 Catalogo
- exercise_catalog_loader.dart (carga)
- exercise_catalog_v3.dart (cache + metadata)
- exercise.dart (mapeo parcial a dominio)

### 2.4 Progresion y monitoreo
- training_plan_provider.dart::recordCompletedSession
- weekly_progression_service_impl.dart
- weekly_decision_engine.dart
- deload_trigger_engine.dart

## 3) Grafo resumido (texto)

UI(Screen)
-> TrainingPlanNotifier.generatePlanFromActiveCycle
-> TrainingPipelineGuard.allowedStage
-> TrainingCycleRepository.getActiveCycle/upsertCycle
-> ExerciseCatalogLoader.load
-> TrainingOrchestratorV3.generatePlan
-> MotorV3Orchestrator.generateProgram
-> CycleTemplateBuilder.buildBaseWeek
-> SessionStructure/Ordering/Intensity engines
-> coverage/feasibility checks
-> persist Client.trainingPlans + activePlanId + freezePlanSnapshot + weeklyDecisionArtifactsV1

## 4) Zonas de mezcla de responsabilidades

- Borde provider: negocio + persistencia + bootstrap + limpieza legacy.
- Builder de week 1: seleccion + estructura + caps + pairing.
- Ordenado: reglas en mas de un modulo.
- Progresion: varios stores y engines en paralelo.
