# A07 - AUDITORIA DEL MOTOR DE ENTRENAMIENTO V3

## 1) Punto de entrada del motor
- Archivo: lib/domain/training_v3/orchestrator/training_orchestrator_v3.dart
- Evidencia:
  - class TrainingOrchestratorV3 (linea ~47)
  - generatePlan (linea ~101)
  - _convertClientToUserProfile (linea ~223)

## 2) Orquestador cientifico
- Archivo: lib/domain/training_v3/services/motor_v3_orchestrator.dart
- Evidencia:
  - class MotorV3Orchestrator (linea ~62)
  - generateProgram (linea ~121)
  - warnings acumulados (linea ~139)
  - feasibility pre-build _feasibilityErrors (linea ~2363)

## 3) Mecanismos de seguridad observados
- Validacion de perfil invalido: throw ArgumentError('UserProfile inválido')
- Validacion de factibilidad previa: retorno success=false con errors/warnings (no siempre throw)
- Cobertura de ejercicios: _validateExerciseCoverage (linea ~1692)

## 4) Hallazgos forenses
- P0: pipeline complejo con alta carga de estados intermedios (split, landmarks, pools, phases, deload windows).
- P1: coexisten rutas de hard-fail y rutas de warning-only; aumenta complejidad de comportamiento en frontera.
- P1: proveedor de entrenamiento persiste ademas mapas UI derivados en training.extra (acople dominio-UI).

## 5) Evidencia de acople provider <-> motor <-> persistencia
- Archivo: lib/features/training_feature/providers/training_plan_provider.dart
- Bloque ~980-1100:
  - upsert de trainingPlans
  - set de activePlanId
  - saveClient(clientWithPlan)
- Bloque posterior:
  - persistencia de targetSetsByMuscleUi/finalTargetSetsByMuscleUi en training.extra.

## 6) Riesgo operativo
- Alto impacto en regresiones silenciosas de consistencia cuando cambia estructura de training.extra o snapshots.
