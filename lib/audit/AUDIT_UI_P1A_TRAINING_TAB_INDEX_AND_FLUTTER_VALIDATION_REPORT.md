# AUDIT UI P1A: Training tab index and Flutter validation report

## Resumen ejecutivo
Se corrigio el P1 runtime/UI en [TrainingWorkspaceScreen](../features/training_feature/screens/training_workspace_screen.dart): el CTA de Landmarks que avanzaba a Intensidad usaba un indice fuera de rango y ahora apunta al tab correcto. La pantalla mantiene 6 tabs, 6 children y un controlador de longitud 6.

## Entorno confirmado
- Windows PowerShell.
- No se usaron comandos Unix como head, tail, grep, sed, awk, rm, touch, find, wc, xargs ni WSL.
- Flutter 3.44.0, channel stable.
- Dart 3.12.0.

## Archivos modificados
- [lib/features/training_feature/screens/training_workspace_screen.dart](../features/training_feature/screens/training_workspace_screen.dart)
- [lib/audit/AUDIT_UI_P1A_TRAINING_TAB_INDEX_AND_FLUTTER_VALIDATION_REPORT.md](lib/audit/AUDIT_UI_P1A_TRAINING_TAB_INDEX_AND_FLUTTER_VALIDATION_REPORT.md)

## Archivos inspeccionados
- [lib/features/training_feature/screens/training_workspace_screen.dart](../features/training_feature/screens/training_workspace_screen.dart)
- [lib/domain/training_v3/models/training_flow_stage.dart](../domain/training_v3/models/training_flow_stage.dart)
- [lib/presentation/screens/training/motor_v3_dashboard_screen.dart](../presentation/screens/training/motor_v3_dashboard_screen.dart)
- [lib/features/biochemistry_feature/screen/biochemistry_screen.dart](../features/biochemistry_feature/screen/biochemistry_screen.dart)
- [lib/features/anthropometry_feature/screen/anthropometry_screen.dart](../features/anthropometry_feature/screen/anthropometry_screen.dart)
- [lib/features/anthropometry_feature/screens/anthropometry_record_detail_screen.dart](../features/anthropometry_feature/screens/anthropometry_record_detail_screen.dart)
- [lib/features/training_feature/screens/training_dashboard_screen.dart](../features/training_feature/screens/training_dashboard_screen.dart)
- [lib/features/shared/record_detail/record_detail_shell.dart](../features/shared/record_detail/record_detail_shell.dart)
- [lib/features/meal_plan_feature/screen/meal_plan_screen.dart](../features/meal_plan_feature/screen/meal_plan_screen.dart)
- [lib/features/nutrition_feature/screen/nutrition_screen.dart](../features/nutrition_feature/screen/nutrition_screen.dart)
- [lib/features/nutrition_feature/screens/equivalents_by_day_screen.dart](../features/nutrition_feature/screens/equivalents_by_day_screen.dart)
- [lib/features/nutrition_feature/widgets/general_equivalents_tab.dart](../features/nutrition_feature/widgets/general_equivalents_tab.dart)
- [lib/features/nutrition_feature/widgets/day_equivalents_tab.dart](../features/nutrition_feature/widgets/day_equivalents_tab.dart)
- [lib/features/history_clinic_feature/screen/history_clinic_screen.dart](../features/history_clinic_feature/screen/history_clinic_screen.dart)
- [lib/features/history_clinic_feature/widgets/clinic_client_header_with_tabs.dart](../features/history_clinic_feature/widgets/clinic_client_header_with_tabs.dart)

## Evidencia del bug
En [TrainingWorkspaceScreen](../features/training_feature/screens/training_workspace_screen.dart#L78-L81) el controlador se declara con longitud 6.

El bloque de tabs en [TabBar](../features/training_feature/screens/training_workspace_screen.dart#L655-L670) contiene 6 tabs reales:
- Entrevista
- Landmarks
- Intensidad
- Preferencias de ejercicios
- Plan
- Monitoreo

El [TabBarView](../features/training_feature/screens/training_workspace_screen.dart#L673-L720) también tiene 6 children reales.

El CTA de Landmarks que dice Confirmar Landmarks y pasar a Intensidad ahora llama a animateTo(2), que es el índice correcto para Intensidad. En el diff local se confirmó que antes llamaba a animateTo(6), lo que era inválido para un controlador de longitud 6.

El enum [TrainingFlowStage](../domain/training_v3/models/training_flow_stage.dart) confirma 6 etapas con índices 0 a 5.

## Causa exacta
La pantalla no necesitaba un séptimo tab. El problema era un índice incorrecto en el CTA de Landmarks. El destino funcional esperado era Intensidad, no un tab inexistente.

## Corrección aplicada
Se cambió el CTA de Landmarks de animateTo(6) a animateTo(2).

No se cambió layout, nombres de tabs, providers, navegación global ni lógica de entrenamiento.

## Confirmación de consistencia
- TabController.length: 6.
- TabBar.tabs.length: 6.
- TabBarView.children.length: 6.
- animateTo usados en el archivo: 0, 2, 4 y el target dinámico derivado de TrainingFlowStage.
- No queda animateTo fuera de rango en TrainingWorkspaceScreen.

## Resultado de búsqueda de otros TabController/animateTo
Se ejecutó una búsqueda global en lib para TabController, DefaultTabController, animateTo, TabBar y TabBarView.

Resultado resumido:
- Se encontró el P1 confirmado en TrainingWorkspaceScreen y quedó corregido.
- Otros casos revisados usan longitudes y children alineados o dependen de la misma fuente dinámica.
- No se confirmó otro P0/P1 idéntico y local que justificara cambios adicionales.

## Confirmación de que no se tocó Motor V3
No se modificaron estos archivos ni su lógica:
- [lib/domain/training_v3/services/cycle_template_builder.dart](../domain/training_v3/services/cycle_template_builder.dart)
- [lib/domain/training_v3/services/motor_v3_orchestrator.dart](../domain/training_v3/services/motor_v3_orchestrator.dart)
- [lib/domain/training_v3/engines/exercise_selection_engine.dart](../domain/training_v3/engines/exercise_selection_engine.dart)
- [lib/domain/training_v3/engines/session_structure_engine.dart](../domain/training_v3/engines/session_structure_engine.dart)
- [lib/domain/policies/pairing_contract.dart](../domain/policies/pairing_contract.dart)
- [lib/domain/training_v3/engines/antagonist_pairing_engine.dart](../domain/training_v3/engines/antagonist_pairing_engine.dart)
- [lib/core/registry/muscle_registry.dart](../core/registry/muscle_registry.dart)
- DB, modelos, repositorios y Firebase no fueron tocados.

## Resultado de flutter --version
- Flutter 3.44.0
- channel stable
- Dart 3.12.0

## Resultado de flutter analyze --no-pub
- Resultado: No issues found.
- Tiempo reportado: 12.5 s.

## Tests ejecutados
1. flutter test test/domain/training_v3/regression/pairing_callsites_fixtures_regression_test.dart --reporter expanded
2. flutter test test/domain/training_v3/regression/pairing_helpers_fixtures_regression_test.dart --reporter expanded
3. flutter test test/domain/training_v3/regression/session_structure_engine_fixtures_regression_test.dart --reporter expanded
4. flutter test test/domain/training_v3/regression/exercise_selection_engine_fixtures_regression_test.dart --reporter expanded
5. flutter test test/domain/training_v3/regression/weekly_volume_planner_fixtures_regression_test.dart --reporter expanded
6. flutter test test/core/registry/muscle_registry_strict_test.dart test/features/training_feature/domain/exercise_preferences_muscle_key_mapper_strict_test.dart test/domain/training_v3/resolvers/muscle_to_catalog_resolver_strict_test.dart test/domain/training_v3/utils/muscle_key_adapter_v3_strict_test.dart test/domain/training_v3/validators/training_plan_forensic_validator_muscle_ssot_test.dart test/domain/training/models/mev_table_strict_muscle_test.dart test/domain/training/validation/vop_validator_strict_muscle_test.dart test/domain/training_v3/validators/volume_validator_strict_muscle_test.dart --reporter expanded

## Resultado de cada test
- Pairing callsites: passed.
- Pairing helpers: passed.
- SessionStructureEngine: passed.
- ExerciseSelectionEngine: passed.
- WeeklyVolumePlanner: passed.
- Suite SSOT focalizada: passed.

## Riesgos pendientes
- La búsqueda global mostró más pantallas con tabs; cualquier cambio futuro en sus longitudes o children debería validarse con el mismo criterio de consistencia.
- El worktree contiene cambios no relacionados fuera del alcance de esta auditoría; no se tocaron.

## Siguiente sprint recomendado
Seguir con D1R9 / D1-C8 ahora que el P1 UI quedó resuelto y la validación de Flutter quedó en verde.
