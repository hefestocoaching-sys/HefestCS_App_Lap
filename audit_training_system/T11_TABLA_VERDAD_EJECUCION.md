# T11 - TABLA DE VERDAD DE EJECUCION

| Escenario | Entry UI | Metodo provider | Motor/orquestador | Persistencia plan | Resultado esperado |
|---|---|---|---|---|---|
| Generar inicial (Workspace) | TrainingWorkspaceScreen._generarPlan | generatePlan | UnifiedTrainingService -> TrainingOrchestratorV3 -> MotorV3Orchestrator | Si | Plan nuevo + activePlanId actualizado |
| Adaptar (Workspace) | _adaptarPlan | generatePlanFromActiveCycle | TrainingOrchestratorV3 -> MotorV3Orchestrator | Si | Regeneracion desde ciclo activo/freeze |
| Deload (Workspace) | boton deload | generatePlanFromActiveCycle | TrainingOrchestratorV3 -> MotorV3Orchestrator | Si | Plan con ruta de ciclo activo |
| Dashboard generar (legacy) | _generarPlan | generatePlanFromActiveCycle | TrainingOrchestratorV3 -> MotorV3Orchestrator | Si | Funciona si se monta dashboard |
| Plan activo no resoluble por ID | dashboard/workspace resolver | n/a | n/a | n/a | fallback a plan mas reciente |
| Push training granular | cualquier guardado record training | pushTrainingRecord | n/a | No remoto | retorno inmediato (sin sync) |

Evidencia:
- training_workspace_screen.dart:3065
- training_workspace_screen.dart:3264
- training_plan_provider.dart:684
- training_plan_provider.dart:1414
- training_dashboard_screen.dart:1928
- training_dashboard_screen.dart:134
- clinical_records_repository.dart:306
