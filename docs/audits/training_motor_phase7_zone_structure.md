# Training Motor Phase 7 - Estructura de sesion por zona

## Problema previo
El pipeline real V3 estaba exigiendo segundo ejercicio cuando `desiredCount=2` aun en escenarios donde la presencia de zona heavy ya se cubria estructuralmente con un unico ejercicio principal.

Sintoma observado en casos reales:
- `STRICT_ZONE_SELECTION_FAIL`
- `reason=no_second_exercise_candidates`

Esto provocaba bloqueos aunque el primer ejercicio fuera valido y suficiente para materializar heavy.

## Tarea 1 - Punto exacto auditado

### Archivo
- `lib/domain/training_v3/services/cycle_template_builder.dart`

### Metodo
- `_selectExercisesForMuscleDay(...)`

### Condicion exacta del fallo
- Bloque final de seleccion de segundo ejercicio:
  - Se construye `rotatedSecond` para `secondaryZone`.
  - Si `rotatedSecond.isEmpty`, lanzaba:
    - `[V3][STRICT_ZONE_SELECTION_FAIL] ... reason=no_second_exercise_candidates`

### Por que estaba mal
- El contrato funcional de sesion no debe exigir siempre un segundo ejercicio en heavy.
- En la practica, heavy puede y debe materializarse como single por defecto.
- El fallo mezclaba "falta de segundo candidato" con "imposibilidad de construir la sesion", generando un bloqueo estructural incorrecto.

## Regla nueva implementada

### Heavy
- Si en el dia aparece heavy (`primaryZone == heavy` o `secondaryZone == heavy`):
  - se fuerza seleccion principal en heavy;
  - `desiredCount` se fija en 1 por defecto;
  - no se exige segundo ejercicio;
  - si no hay segundo heavy, no falla por ese motivo.

### Medium/Light
- Cuando no hay heavy en el dia:
  - se conserva logica multiejercicio (`desiredCount` segun sets/cap);
  - se mantiene pairing/estructura de bloques ya existente.

## Archivos tocados
- `lib/domain/training_v3/services/cycle_template_builder.dart`
- `docs/audits/training_motor_phase7_zone_structure.md`

## Cambios tecnicos clave
1. En la construccion por musculo/dia:
   - deteccion `heavySingleByDefault`;
   - `selectionPrimaryZone='heavy'` cuando aplica;
   - `requestedExerciseCount=1` en ruta heavy por defecto.

2. En seleccion de segundo ejercicio:
   - cuando `rotatedSecond` queda vacio y `secondaryZone=heavy`, se retorna single en lugar de error.

3. Mensajeria:
   - el error residual multiejercicio se renombro a:
     - `reason=no_second_exercise_candidates_for_multi_slot`
   - evita error obsoleto para el caso heavy-single esperado.

## Efecto sobre estructura de slots
- Heavy queda en ruta single por defecto y converge a estructura principal (single), sin exigir A2 heavy.
- Medium/light mantienen flexibilidad para multiejercicio/biserie bajo reglas vigentes.

## Errores que deben desaparecer
- Patron en heavy:
  - `STRICT_ZONE_SELECTION_FAIL ... no_second_exercise_candidates`

## Riesgos o residuos esperados
- Pueden permanecer fallas por otros contratos (no ligados a exigir segundo heavy), por ejemplo cobertura real de datos o restricciones de otra capa.
- Este cambio no introduce rutas paralelas ni altera frecuencia/catalogo/UI.

## Resultado de ejecucion (post-fix)
- El patron `STRICT_ZONE_SELECTION_FAIL ... no_second_exercise_candidates` desaparecio en la corrida de 5 casos.
- Tambien desaparecio `ZONE_VALIDATION_FAIL` para estos casos.
- Ningun caso genero plan en este corte (0/5), pero por una causa distinta y mas real:
  - `[B4] No exercises available for muscle=... zone=heavy`.

Lectura tecnica:
- Fase 7 resolvio la exigencia estructural incorrecta del segundo ejercicio heavy.
- El bloqueo actual refleja cobertura efectiva insuficiente para materializar heavy en ciertos musculos/contextos del pool del dia.
