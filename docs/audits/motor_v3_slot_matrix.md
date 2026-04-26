# Motor V3 Slot Matrix

## Slots runtime detectados
Motor real usa bloques: A, B, C, D.

| Slot/Bloque | Obligatorio | Individual/Biserie | Reglas runtime | Patrones esperados |
|---|---|---|---|---|
| A | si | individual | main lift unico, `isMainLift=true` | patron dominante del dia |
| B1-B2 | condicional | biserie preferente | antagonista o baja interferencia/synergy | antagonistas o compatibles con A |
| C1-C2 | condicional | individual o biserie | soporte secundario, evita conflicto con B | secundarios no conflictivos |
| D1-D2 | condicional | individual o biserie baja demanda | accesorios, baja carga sistemica | aislamiento y complementos |

## Reglas de estructura observadas
1. A siempre individual (contrato cumplido).
2. B/C/D pueden tener pares si `PairingContract.isAllowedBiserie(...)`.
3. Si pairing no es valido, degrada a single.
4. En runtime no existe bloque E operativo.

## Gap contractual
1. Pedido funcional menciona B/C/D/E, pero runtime actual materializa A-D.
2. Se requiere decidir si E entra como nuevo bloque formal o se mantiene A-D.
