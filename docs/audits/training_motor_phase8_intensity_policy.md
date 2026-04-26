# Training Motor Phase 8 - Política de Intensidad por Músculo

## Problema detectado
Después de Fase 7, el pipeline V3 ya no fallaba por estructura de sesión, pero seguía asignando heavy a músculos que no lo sostienen de forma estable en el catálogo o en el pool real de generación.

El síntoma dominante era:
- `[B4] No exercises available ... zone=heavy`

Ese fallo no venía del selector ni del catálogo como tal, sino de la distribución de intensidad que seguía entregando heavy a músculos pequeños o de cobertura no consistente.

## Política aplicada
Se creó una política explícita por músculo en:
- `lib/domain/training_v3/constants/muscle_intensity_policy.dart`

Reglas finales aplicadas en esta fase:
- `pectorals` -> `heavy, medium, light`
- `upper_back` -> `heavy, medium, light`
- `quads` -> `heavy, medium, light`
- `glutes` -> `heavy, medium, light`
- `hamstrings` -> `heavy, medium, light`
- `lats` -> `medium, light` de forma conservadora
- `biceps` -> `medium, light`
- `triceps` -> `medium, light`
- `delts_lateral` -> `medium, light`
- `delts_rear` -> `medium, light`
- `traps` -> `medium, light`
- `calves` -> `medium, light`
- `abs` -> `light`

## Redistribución
La redistribución se implementó en `IntensityDistributionEngine`.

Reglas:
- No se pierden sets.
- No se crean sets nuevos.
- La suma original se conserva.
- Orden de prioridad operativa:
  - heavy -> medium -> light

Traducción práctica:
- si un músculo no permite heavy, sus sets heavy se mueven a medium o light.
- si un músculo no permite medium, sus sets medium se mueven a light o a la mejor zona permitida restante.
- si solo permite una zona, todo el volumen termina ahí.

## Trazabilidad
Se añadió traza estructurada:
- `[V3][INTENSITY_POLICY_TRACE]`

Campos incluidos:
- muscle
- original
- adjusted
- removedZones
- reason

También se agregó warning opcional cuando no hay intersección entre la política y la cobertura efectiva del catálogo.

## Ejemplos reales
### biceps
Ejemplo conceptual:
- input: `heavy=2, medium=6, light=2`
- policy: `medium, light`
- output esperado: `heavy=0, medium=8, light=2`

### delts_rear
- heavy se elimina.
- el volumen se redistribuye a medium y/o light según disponibilidad.

### calves
- heavy no se usa en la práctica de esta fase.
- el volumen se mantiene en medium/light.

### traps
- heavy también se elimina para evitar el bloqueo recurrente que seguía apareciendo en la batería manual.

## Impacto observado
Lo que sí se resolvió en esta fase:
- desapareció la presión sistemática de heavy sobre músculos no adecuados.
- se redujo el patrón de fallo puramente por heavy en varios grupos pequeños.
- el motor ya no depende de un fallback silencioso para corregir intensidad.

Lo que todavía quedó bloqueando los 5 casos:
- `STRICT_ZONE_SELECTION_FAIL` por cobertura de segunda zona en algunos contextos.
- validaciones forenses de pairing y frecuencia que ya son otro frente del pipeline.

## Archivos tocados
- `lib/domain/training_v3/constants/muscle_intensity_policy.dart`
- `lib/domain/training_v3/engines/intensity_distribution_engine.dart`
- `lib/domain/training_v3/services/cycle_template_builder.dart`

## Conclusión
Fase 8 resolvió la política de intensidad por músculo y la redistribución automática sin pérdida de sets. El pipeline sigue sin romperse por intensidad inválida heavy en músculos pequeños, pero todavía quedan bloqueos estructurales/frecuencia/pairing fuera del alcance de esta fase.