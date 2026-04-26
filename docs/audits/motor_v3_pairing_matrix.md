# Motor V3 Pairing Matrix

## Regla contractual de biserie
Permitido SOLO si:
1. antagonista
2. baja interferencia
3. synergy compatible

Prohibido si:
1. mismo musculo primario
2. mismo patron dominante pesado del bloque A
3. dos demandas sistemicas altas simultaneas

## Matriz
| Patron A | Patron B | Estado | Motivo fisiologico/estructural | Bloques permitidos |
|---|---|---|---|---|
| empuje horizontal pesado | jalon vertical/remo horizontal | permitido | antagonista o baja interferencia | B, C |
| empuje vertical | jalon vertical | permitido condicionado | alternancia empuje/jalon | B, C |
| flexion de codo | extension de triceps | permitido | antagonista directo | C, D |
| quads dominante rodilla | isquios flexion | permitido condicionado | antagonista parcial de rodilla | B, C |
| bisagra de cadera pesada | dominante rodilla pesada | prohibido | doble compuesto pesado alta fatiga | ninguno |
| mismo patron dominante | mismo patron dominante | prohibido | redundancia y fatiga local | ninguno |
| accesorio bajo costo | accesorio bajo costo | permitido condicionado | baja demanda sistemica | D |

## Estado runtime
1. `PairingContract` permite antagonist/lowInterference/synergy.
2. `SessionStructureEngine` y `CycleTemplateBuilder` aplican fallback a single si no cumple.
3. Bloque E no existe aun en runtime.
