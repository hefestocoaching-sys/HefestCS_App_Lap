# Training Motor Phase 6 - Selector Determinístico por Zona

## Resumen ejecutivo
Se endureció la selección de ejercicios del Motor V3 para que la compatibilidad por zona sea una condición obligatoria en selección primaria y en fallback.

## Archivos modificados
- lib/domain/training_v3/services/cycle_template_builder.dart
- lib/domain/training_v3/engines/exercise_selection_engine.dart
- lib/domain/entities/exercise.dart

## Contrato final de selección
1. La selección determinística requiere `intensityZone` explícita.
2. Un ejercicio solo es elegible si:
   - `ExerciseCatalogV3.allowsZone(id, zone) == true`
   - `Exercise.allowsZone(zone) == true`
3. Si no hay candidatos directos, el único fallback permitido es por equivalenceGroup con compatibilidad de zona.
4. Si no hay candidatos válidos tras fallback, se lanza error explícito y trazable.

## Cambios relevantes
### cycle_template_builder
- Se removió fallback no filtrado por zona en slot secundario.
- Si no hay segundo ejercicio válido por zona, se retorna error explícito (`STRICT_ZONE_SELECTION_FAIL`) en vez de degradar a selección silenciosa.

### exercise_selection_engine
- `selectDeterministicCandidates` ahora opera en modo estricto por zona.
- Se agregó fallback por equivalenceGroup con deduplicación y orden determinístico.
- Se agregó error explícito cuando no hay candidatos compatibles.

### exercise entity
- Defaults de zonas se hicieron restrictivos para evitar permisividad con metadata ausente.

## Riesgos residuales
- El endurecimiento puede exponer huecos reales del catálogo (faltan variantes por zona en algunos grupos/músculos).
- Es esperado que aparezcan errores explícitos en casos con cobertura de catálogo insuficiente.

## Validación
La validación se realiza con:
- runner manual de 5 casos: `test/manual/training_v3_case_audit_runner_test.dart`
- `flutter analyze`

Resultados y evidencia post-fix: ver `docs/audits/generated_cases/` y `docs/audits/training_motor_phase6_catalog_issues.md`.

## Resultado post-fix (esta ejecución)
- `ZONE_VALIDATION_FAIL`: 0 apariciones en los 5 casos.
- Nuevos bloqueos explícitos: 5 casos con `STRICT_ZONE_SELECTION_FAIL` por falta real de segundo candidato compatible en zona heavy para algunos músculos/equivalence groups.
- Planes generados: 0/5 en este corte.

Interpretación:
- Se eliminó el bug de selección inválida por zona (objetivo principal de Phase 6).
- Quedó expuesta una limitación real de cobertura del catálogo para ciertos músculos/zonas.
