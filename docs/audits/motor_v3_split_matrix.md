# Motor V3 Split Matrix

## Regla base
Split contractual se evalua por arquitectura de dia, no por numero abstracto.

## Matriz oficial consolidada
| Split | Orden semanal base | Tipo de dia | Dominancia | Frecuencia compatible real | Estado runtime |
|---|---|---|---|---|---|
| x3 | D1 Torso, D2 Pierna, D3 Mixto/Posterior | full body rotatorio | rotacion torso/pierna/mixto | f2-f3 segun volumen por musculo | soportado via `TrainingSplit.fullBody` |
| x4 | Torso A, Pierna A, Torso B, Pierna B | upper/lower alternado | torso/pierna equilibrado | f2 dominante; f1 en terciarios | soportado via `TrainingSplit.upperLower` |
| x5 | Torso/Pierna/Empuje/Jalon/Pierna o Empuje/Jalon/Pierna/Torso/Pierna | hibrido UL+PPL | prioridad segun objetivo | f2 en primarios, f1-f2 secundarios | parcial (hoy cae en upper/lower extendido) |
| x6 | Empuje/Jalon/Pierna/Empuje/Jalon/Pierna | PPL repetido | push/pull/legs | f2 base | hoy `TrainingSplit.pushPullLegs` con distribucion tipo upper/lower fallback en builder |

## Observaciones forenses
1. `_resolveSplit(...)` solo expone `fullBody`, `upperLower`, `pushPullLegs`.
2. En `CycleTemplateBuilder`, si no es full body, la asignacion actual usa logica upper/lower.
3. x5 y x6 oficiales funcionales necesitan matriz explicita por tipo de dia en builder para cierre total.

## Contrato objetivo por tipo de dia
1. x3:
   - D1 torso dominante.
   - D2 pierna dominante.
   - D3 mixto/posterior.
2. x4:
   - D1 Torso A.
   - D2 Pierna A.
   - D3 Torso B.
   - D4 Pierna B.
3. x5:
   - variante A: Torso/Pierna/Empuje/Jalon/Pierna.
   - variante B: Empuje/Jalon/Pierna/Torso/Pierna.
4. x6:
   - Push/Pull/Legs x2.
