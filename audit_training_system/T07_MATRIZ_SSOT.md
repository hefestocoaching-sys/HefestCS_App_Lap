# T07 - MATRIZ SSOT (FUENTE UNICA VS REALIDAD)

| Dominio | SSOT declarada | SSOT operativa observada | Estado | Evidencia |
|---|---|---|---|---|
| Plan activo | training.extra.activePlanId | activePlanId + fallback plan mas reciente si no coincide | Parcialmente consistente | training_plan_provider.dart:487, training_dashboard_screen.dart:134 |
| Planes | client.trainingPlans | client.trainingPlans | Consistente | client.dart:54, training_plan_provider.dart:1942 |
| Ciclo activo | client.activeCycleId | top-level activeCycleId + manipulación de activeCycleId en training.extra en clear | Inconsistente | client.dart:60, training_plan_provider.dart:2551 |
| Ciclos | client.trainingCycles | client.trainingCycles | Consistente | client.dart:59, training_cycle_repository_impl.dart:83 |
| Entrevista estructurada | trainingSetupV1 + trainingEvaluationSnapshotV1 | se leen SSOT V1 con fallback a legacy en orquestador | Mixta (dual) | training_ssot_v1_service.dart:27, training_orchestrator_v3.dart:236 |
| Flow stage | trainingFlowStage | gating en provider/workspace para generar | Consistente local | training_plan_provider.dart:2190, training_workspace_provider.dart:34 |
| Sync training records | deberia existir push granular | deshabilitado (return inmediato) | No operativo | clinical_records_repository.dart:306 |

## Violaciones SSOT detectadas
1. Doble representacion de ciclo activo (top-level vs extra)
- Tipo: VIOLACION DE SSOT
- Evidencia: client.dart:60, training_plan_provider.dart:2551

2. Resolucion de plan activo con fallback al mas reciente si `activePlanId` no resuelve
- Tipo: VIOLACION DE SSOT (degradada por fallback)
- Evidencia: training_dashboard_screen.dart:134, training_dashboard_screen.dart:139
