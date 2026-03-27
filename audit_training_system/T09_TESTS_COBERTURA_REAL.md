# T09 - TESTS Y COBERTURA REAL (FORENSE)

## Inventario training tests detectados
- test/domain/training_v3/integration_test.dart
- test/domain/training_v3/integration/motor_v3_integration_test.dart
- test/domain/training_v3/forensic_motor_trace_test.dart
- test/domain/training_v3/verification/motor_v3_volume_verification_test.dart
- test/domain/training_v3/verification/cycle_template_allocation_audit_test.dart
- test/domain/training_v3/p0_verification_test.dart
- test/training_persistence_test.dart
- test/training_audit_persistence_test.dart

## Cobertura funcional visible por lectura de nombres/targets
- Fuerte en dominio MotorV3 y validaciones de volumen.
- Presencia de tests forenses de traza.

## Gaps de cobertura observables
1. No se detecta suite focalizada en `TrainingPlanProvider.generatePlanFromActiveCycle` end-to-end (bootstrap + cleanup + persist + refresh).
2. No se detecta suite focalizada en dualidad `activeCycleId` top-level vs extra.
3. No se detecta test de integracion para la ruta real de pantalla `TrainingWorkspaceScreen` (generate/adapt/regenerate con pipelines distintos).
4. No se detecta test de sync training granular deshabilitado como decision explicita (guardrail de regresion).

## Evidencia
- Busqueda de referencias de `MotorV3Orchestrator.generateProgram` en tests: multiples matches.
- Sin matches equivalentes para `TrainingPlanProvider.generatePlanFromActiveCycle` en carpeta test.
