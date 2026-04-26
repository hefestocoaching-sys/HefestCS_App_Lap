# Forensic Full Pipeline Audit (Motor V3 + Catalog V3)

## Objetivo
Auditar el pipeline real activo de generación V3 extremo a extremo (entrada real desde provider, orquestación, motor, builder, validador) y detectar rutas paralelas/legacy que puedan afectar la trazabilidad contractual.

## Evidencia De Pipeline Real
- `TrainingPlanProvider` usa el flujo unificado en `generatePlanFromActiveCycle` y llama a `UnifiedTrainingService.generateFullProgram(...)`.
- `UnifiedTrainingService` instancia `TrainingOrchestratorV3` y delega generación.
- `TrainingOrchestratorV3` delega explícitamente a `MotorV3Orchestrator.generateProgram(...)`.
- `MotorV3Orchestrator` fuerza carga de catálogo runtime con `ExerciseCatalogV3.ensureLoaded()`.
- `MotorV3Orchestrator` ejecuta validación forense (`TrainingPlanForensicValidator.validate`) antes de devolver plan exitoso.

Referencias clave:
- `lib/features/training_feature/providers/training_plan_provider.dart` (aprox. líneas 949, 955-962, 987)
- `lib/domain/training_v3/services/unified_training_service.dart` (aprox. líneas 37+)
- `lib/domain/training_v3/orchestrator/training_orchestrator_v3.dart` (aprox. líneas 148, 180)
- `lib/domain/training_v3/services/motor_v3_orchestrator.dart` (aprox. líneas 198, 264, 343)

## Hallazgos
1. Pipeline principal V3 está correctamente encadenado y validado forensemente al final.
2. El motor ignora lista externa de ejercicios y usa SSOT runtime assets (log explícito de ignore).
3. Existen rutas legacy/paralelas todavía presentes en provider/orchestrator que incrementan complejidad operativa.

## Riesgos
- **P1**: Múltiples entradas de generación en `TrainingPlanProvider` (directo a `MotorV3Orchestrator`, flujo unificado y ruta deprecated `generatePlanV3`) aumentan riesgo de drift funcional.
- **P2**: Existe ruta legacy de sesión marcada como deprecated en motor (`_buildSessions`) aunque no canónica.

## Veredicto
- **Estado pipeline real**: `OPERATIVO` (ruta principal sólida).
- **Estado de hardening arquitectónico**: `PARCIAL` (deuda por rutas legacy coexistentes).

## Acción Recomendada
1. Congelar entrada oficial única en provider y encapsular otras rutas detrás de flags internos no invocables.
2. Dejar ruta legacy como test-only o eliminarla cuando no haya dependencias.
