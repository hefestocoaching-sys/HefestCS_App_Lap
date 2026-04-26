# Motor V3 Pipeline Forensic

## Objetivo
Mapear el pipeline REAL activo del Motor V3, con flujo de datos y puntos de riesgo legacy.

## Entrypoint real activo
1. UI invoca `TrainingPlanNotifier.generatePlanFromActiveCycle(...)`.
2. Archivo: `lib/features/training_feature/providers/training_plan_provider.dart`.
3. Este es el entrypoint canonico de generacion y persistencia actual.

## Flujo E2E real
1. Gate funcional:
   - `TrainingPipelineGuard.allowedStage(...)` valida entrevista/landmarks/intensidad.
2. Carga cliente + ciclo:
   - `clientRepositoryProvider.getClientById(...)`.
   - `trainingCycleRepositoryProvider.getActiveCycle(...)`.
3. Bootstrap defensivo de ciclo:
   - `ActiveCycleBootstrapper.buildDefaultCycle(...)` si no hay ciclo util.
4. Catalogo de ejercicios:
   - `ExerciseCatalogLoader.load()`.
5. Adaptador V3:
   - `TrainingOrchestratorV3.generatePlan(...)`.
6. Motor V3 real:
   - `MotorV3Orchestrator.generateProgram(...)`.
   - Resuelve split/volumen/intensidad/pool.
   - Ejecuta normalizacion de volumen factible pre-builder.
7. Builder estructural:
   - `CycleTemplateBuilder.buildBaseWeek(...)`.
   - Estructura A/B/C/D, pairing y caps.
8. Validator final:
   - `TrainingPlanForensicValidator.validate(...)`.
   - Si falla, bloquea retorno.
9. Persistencia final:
   - `client.trainingPlans` + `training.extra.activePlanId`.
   - `TrainingCycle.freezePlanSnapshot`.
   - `training.extra.weeklyDecisionArtifactsV1` (cuando aplica cierre semanal).

## Servicios intermedios clave
- `lib/domain/training_v3/orchestrator/training_orchestrator_v3.dart`
- `lib/domain/training_v3/services/motor_v3_orchestrator.dart`
- `lib/domain/training_v3/services/cycle_template_builder.dart`
- `lib/domain/training_v3/validators/training_plan_forensic_validator.dart`
- `lib/domain/training_v3/data/exercise_catalog_v3.dart`

## Selector real
El selector final de ejercicio por musculo/dia ocurre en:
- `CycleTemplateBuilder._selectExercisesForMuscleDay(...)`
- Soporte de roles: `ExerciseRoleEngine.classify(...)`
- Compatibilidad de zona: `ExerciseCatalogV3.allowsZone(...)`

## Validator real
Validator forense consolidado:
- `TrainingPlanForensicValidator`
Reglas criticas:
- cobertura por musculo
- frecuencia esperada vs real
- cap diario
- coherencia de zonas por ejercicio
- pairing valido

## Legacy detectado (aun presente)
1. `training_plan_v3_provider.dart` (deprecated).
2. `generatePlanV3(...)` en `training_plan_provider.dart` (deprecated, early return).
3. `_buildSessions(...)` en `motor_v3_orchestrator.dart` (ruta antigua, no camino canonico actual).
4. `split_templates.dart` en dominio legacy de split.

## Rutas no usadas pero peligrosas
1. Split legacy paralelos (`split_templates.dart`) pueden confundir SSOT de split.
2. Enums de fase duplicados (`training_v3/engines/periodization_engine.dart`, `training_v3/enums/training_enums.dart`) no son contrato runtime principal del motor real.
3. Servicios de progresion enhanced/legacy coexistentes sin unificador unico de runtime.

## Conclusiones forenses
1. El pipeline real SI esta activo y productivo.
2. El entrypoint unico operativo esta en `training_plan_provider.dart`.
3. El camino builder+forensic validator es el contrato real de generacion.
4. Persisten rutas legacy que deben quedar marcadas como no-SSOT.
