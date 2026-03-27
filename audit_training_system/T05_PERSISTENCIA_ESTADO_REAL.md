# T05 - PERSISTENCIA Y ESTADO REAL

## SSOT de persistencia efectiva (observada)
1. Planes: `client.trainingPlans` (top-level entity).
2. Plan activo: `client.training.extra.activePlanId`.
3. Ciclos: `client.trainingCycles` + `client.activeCycleId` (top-level).
4. Entrevista/estructurado: `client.training.extra.trainingSetupV1` y `trainingEvaluationSnapshotV1`.

Evidencia:
- lib/domain/entities/client.dart:54
- lib/core/constants/training_extra_keys.dart:60
- lib/domain/entities/client.dart:59
- lib/domain/entities/client.dart:60
- lib/core/constants/training_extra_keys.dart:145
- lib/core/constants/training_extra_keys.dart:146

## Camino de escritura real
1. Provider construye `updatedClient` con nuevos `trainingPlans` y `activePlanId`.
2. `ClientRepository.saveClient` guarda local primero (fuente de verdad).
3. `LocalClientDataSourceImpl.saveClient` delega a `DatabaseHelper.upsertClient`.
4. `DatabaseHelper` serializa JSON completo y hace upsert en tabla `clients`.
5. Push remoto se intenta en background (debounce), sin bloquear flujo local.

Evidencia:
- lib/features/training_feature/providers/training_plan_provider.dart:1942
- lib/features/training_feature/providers/training_plan_provider.dart:1954
- lib/data/repositories/client_repository.dart:23
- lib/data/datasources/local/local_client_datasource_impl.dart:22
- lib/data/datasources/local/database_helper.dart:275
- lib/data/repositories/client_repository.dart:28

## Hallazgos de dualidad de estado
1. `activeCycleId` top-level existe en entidad.
2. `clearActivePlan()` elimina `activeCycleId` dentro de `training.extra` (string literal), no el top-level.

Implicacion:
- Hay dos ubicaciones semanticas para el mismo concepto de ciclo activo.
- Riesgo de desalineacion entre lectura/escritura por capas distintas.

Evidencia:
- lib/domain/entities/client.dart:60
- lib/features/training_feature/providers/training_plan_provider.dart:2551

## Legacy cleanup en regeneracion
`generatePlanFromActiveCycle()` elimina claves legacy y vacia `trainingPlans`, `trainingWeeks`, `trainingSessions` antes de regenerar.

Evidencia:
- lib/features/training_feature/providers/training_plan_provider.dart:1665
- lib/features/training_feature/providers/training_plan_provider.dart:1686
