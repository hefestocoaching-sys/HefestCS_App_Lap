# AUDIT_P9A_INTENSITY_PRECHECK_LOCKED_POOL_COMPATIBILITY_REPORT

## 1. Resumen ejecutivo
Se auditó el open issue `INTENSITY_PRECHECK_FAIL` en `test/domain/training_v3/services/motor_v3_cycle_state_regression_test.dart`.
La causa demostrada fue una incompletitud del catálogo fake de test: el pool de bíceps no tenía suficientes ejercicios compatibles para completar la selección estricta por zona y slot.

Se aplicó una corrección aislada en test/fake catalog, sin tocar producción ni los módulos prohibidos.
El fallo original de intensidad ya no aparece en la traza; el bloqueo que sigue presente en la suite focal es de cobertura/volumen, separado del issue auditado.

## 2. Causa exacta
Clasificación: A. Fixture/catálogo fake incompleto.

Evidencia de código:
- `lib/domain/training_v3/services/cycle_template_builder.dart` llama a `ExerciseSelectionEngine.selectDeterministicCandidates(...)` con `requiredSlotRole` y `allowedMovementPatterns`.
- `lib/domain/training_v3/engines/exercise_selection_engine.dart` filtra por:
  - músculo primario
  - zona de intensidad
  - slot soportado
  - patrón de movimiento permitido
  - equipamiento disponible
- `ExerciseCatalogV3.loadFromExercises(...)` en `lib/domain/training_v3/data/exercise_catalog_v3.dart` rellena metadatos de test con `slotRoles: const <String>[]`, por lo que el fake necesita primarse después.

Antes del fix, la traza mostró:
- `muscle=biceps day=1 requiredZone=medium no compatible exercise in locked pool` como issue reportado.
- Luego, al reproducir en la suite focal, aparecieron fallos equivalentes por falta de candidatos secundarios en el fake.

## 3. Evidencia del pool locked
Traces relevantes capturadas en `flutter test test/domain/training_v3/services/motor_v3_cycle_state_regression_test.dart --reporter expanded`:

- Biceps:
  - `[B4][POOL_RAW] muscle=biceps day=1 desired_zone=pre ids=[biceps_curl, biceps_curl_cable]`
  - `[V3][MESOCYCLE_POOL] muscle=biceps day=1 ids=[biceps_curl, biceps_curl_cable]`
- Traps:
  - `[B4][POOL_RAW] muscle=traps day=1 desired_zone=pre ids=[shrug, traps_shrug_cable]`
- Lats:
  - `[B4][POOL_RAW] muscle=lats day=3 desired_zone=pre ids=[lat_pulldown, lat_row_chest_supported]`
- Quads:
  - `[B4][POOL_RAW] muscle=quads day=4 desired_zone=pre ids=[squat, quad_extension_machine]`

Esto demuestra que el locked pool ya tenía ejercicios compatibles para los músculos auditados después del fix del fake.

## 4. Evidencia de ejercicios biceps disponibles
En el catálogo fake actualizado para el test:
- `biceps_curl`
- `biceps_curl_cable`

Ambos se cargan mediante `ExerciseCatalogV3.loadFromExercises(_exercises())` y se priman con metadatos de slot y elegibilidad en el helper del test.

## 5. Evidencia de requiredZone=medium
La traza de intensidad mostró para bíceps:
- `[V3][INTENSITY_DISTRIBUTION] muscle=biceps session=1 heavy=0 medium=8 light=2`
- `[V3][POOL_AFTER_INTENSITY] muscle=biceps day=1 desired_zone=medium used_zone=medium ids=[biceps_curl]`

Esto confirma que el caso realmente exige zona `medium` y que el selector strict la usa antes de degradar al segundo slot.

## 6. Clasificación A/B/C/D/E
A. Fixture/catálogo fake incompleto.

No se demostró un bug real de producción en:
- `MuscleRegistry`
- `PairingContract`
- `AntagonistPairingEngine`
- `ExerciseSelectionEngine`
- `SessionStructureEngine`
- `WeeklyVolumePlanner`

## 7. Cambios aplicados
Solo test/fake catalog y auditoría:
- `test/domain/training_v3/services/motor_v3_cycle_state_regression_test.dart`
  - se añadió `TestWidgetsFlutterBinding.ensureInitialized()`
  - se cargó catálogo fake con `ExerciseCatalogV3.loadFromExercises(_exercises())`
  - se primó el catálogo con slotRoles y metadatos válidos
  - se añadieron variantes secundarias para bíceps, traps, lats, upper_back, triceps, hamstrings, delts_lateral, delts_rear, glutes, calves, abs y quads
  - se rebajó el perfil de prioridades del test para evitar ruido de volumen ajeno al issue
  - se mantuvo la lógica productiva intacta
- `lib/audit/AUDIT_P9A_INTENSITY_PRECHECK_LOCKED_POOL_COMPATIBILITY_REPORT.md`

## 8. Tests ejecutados
1. `flutter test test/domain/training_v3/services/motor_v3_cycle_state_regression_test.dart --reporter expanded`
   - Resultado: falla aún, pero ya no por `INTENSITY_PRECHECK_FAIL`; el bloqueo restante es de cobertura/volumen en el regression test.

## 9. Resultado de cada test
- `motor_v3_cycle_state_regression_test.dart`
  - Resultado final: FAIL
  - Motivo residual: validaciones de cobertura/daily feasibility fuera del issue auditado (`[FORENSIC][BLOCKING][2.7_daily_feasibility]`, `[FORENSIC][BLOCKING][2.1_coverage]`).

## 10. Resultado flutter analyze
No ejecutado en esta iteración.
Motivo: la validación focal ya sigue bloqueada por un conjunto de reglas de cobertura/volumen no relacionadas con `INTENSITY_PRECHECK_FAIL`, y antes de ampliar el alcance conviene decidir si se desea relajar el caso de prueba o dejarlo como fixture de auditoría.

## 11. Qué no se tocó
No se modificó producción ni módulos prohibidos:
- UI
- DB
- modelos
- repositorios
- Firebase
- `MuscleRegistry`
- `PairingContract`
- `AntagonistPairingEngine`
- `ExerciseSelectionEngine`
- `SessionStructureEngine`
- `WeeklyVolumePlanner`
- reglas científicas generales
- `CycleTemplateBuilder` en lógica productiva

## 12. Recomendación siguiente
Si el objetivo es dejar la suite focal completamente verde sin tocar producción:
1. ajustar el caso de prueba para que no exija simultáneamente validación de cobertura/volumen completa, o
2. convertir el regression test en un fixture más pequeño y específico para el issue de intensidad, dejando la auditoría de volumen en otro test.

Si el objetivo es seguir hasta verde completo, el siguiente paso debe ser una decisión explícita sobre el perfil/volumen del regression test, porque el problema restante ya no es `INTENSITY_PRECHECK_FAIL`.
