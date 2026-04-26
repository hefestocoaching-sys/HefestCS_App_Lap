# Training Motor Phase 6 Selector Audit

## Objetivo
Eliminar ZONE_VALIDATION_FAIL en la ruta real Motor V3, forzando selección determinística por zona y fallback controlado solo por equivalenceGroup.

## Punto exacto de falla encontrado
En la implementación previa de selección por día, el segundo slot tenía un fallback que volvía a tomar el pool sin filtrar por zona objetivo.

Ruta auditada:
- lib/domain/training_v3/services/cycle_template_builder.dart

Comportamiento observado (antes del fix):
1. Se intentaba seleccionar slot2 con secondaryZone.
2. Si no había candidatos en role/intensity, se caía a un fallback de "same muscle" no filtrado por zona.
3. El ejercicio se etiquetaba con secondaryZone aunque no cumpliera zona en metadata.
4. El post-check lanzaba [V3][ZONE_VALIDATION_FAIL].

## Cambios aplicados
### 1) Eliminación de fallback permisivo en builder
Archivo:
- lib/domain/training_v3/services/cycle_template_builder.dart

Cambio clave:
- Se reemplazó el fallback de segundo ejercicio no filtrado por zona por un fallback equivalente pero con filtro estricto por zona.

Resultado:
- Nunca entra un candidato al slot2 si no cumple la secondaryZone.

### 2) Selector determinístico por zona con fallback controlado
Archivo:
- lib/domain/training_v3/engines/exercise_selection_engine.dart

Cambios clave:
- `selectDeterministicCandidates` ahora exige `intensityZone` no vacío.
- Filtra por `ExerciseCatalogV3.allowsZone` y por `Exercise.allowsZone`.
- Si no hay candidatos directos, aplica fallback exclusivamente mediante `ExerciseCatalogV3.findEquivalentExercisesForZone`.
- Si sigue vacío, lanza error explícito `[ExerciseSelection][STRICT_NO_ZONE_CANDIDATES]`.

Resultado:
- Se elimina fallback implícito/permisivo por ausencia de zona.
- Se formaliza falla clara cuando no existe candidato compatible.

### 3) Endurecimiento de defaults en entidad Exercise
Archivo:
- lib/domain/entities/exercise.dart

Cambios clave:
- Defaults de `allowedIntensityZones` pasan a restrictivos (`heavy=false, medium=false, light=false`) cuando falta metadata.

Resultado:
- Evita que ejercicios sin metadata válida se cuelen en medium/light por default.

## Ruta principal validada
La ruta principal sigue siendo:
training_plan_provider -> unified_training_service -> training_orchestrator_v3 -> motor_v3_orchestrator -> cycle_template_builder

La ruta legacy detectada (`motor_v3_orchestrator._buildSessions` con `ExerciseSelectionEngine.selectExercises`) no es el entrypoint principal.

## Criterio de éxito de esta fase
- No seleccionar ejercicios incompatibles con la zona objetivo.
- Filtrar por zona antes de decidir el ejercicio.
- Fallback solo por equivalenceGroup y solo si también respeta la zona.
- Si no hay candidato válido, emitir error explícito (no degradar silenciosamente).

## Resultado observado post-fix
- Se eliminó `ZONE_VALIDATION_FAIL` en la batería de 5 casos.
- Apareció `STRICT_ZONE_SELECTION_FAIL` cuando no existe segundo candidato compatible por zona en el pool real.
- El nuevo comportamiento es consistente con contrato estricto: falla explícita por insuficiencia de cobertura, sin selección inválida.
