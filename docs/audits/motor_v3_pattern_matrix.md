# Motor V3 Pattern Matrix

## Fuente
- `movementPattern` del catalogo real.
- seleccion estructural por bloque en builder.

## Patrones oficiales torso (contrato)
| Patron | Region | Familias compatibles (catalogo) | Slots | Puede ser A | Puede ir en biserie | Parejas compatibles |
|---|---|---|---|---|---|---|
| empuje horizontal pesado | torso | horizontal_press, horizontal_adduction | A/B | si | condicional | jalon vertical, remo horizontal, deltoide posterior |
| empuje horizontal secundario | torso | horizontal_press, shoulder_flexion | B/C | no preferente | si | jalon vertical, biceps |
| empuje vertical | torso | vertical_press, shoulder_flexion | A/B/C | si | condicional | jalon vertical, deltoide posterior |
| jalon vertical | torso | vertical_pull | A/B/C | si | si | empuje horizontal/vertical, triceps |
| remo horizontal | torso | horizontal_pull | A/B/C | si | si | empuje horizontal, deltoide lateral |
| deltoide lateral | torso | shoulder_abduction | C/D | no | si | biceps, triceps, abdomen |
| deltoide posterior | torso | shoulder_horizontal_abduction, shoulder_extension | B/C/D | no | si | empuje horizontal, biceps |
| flexion de codo | torso | elbow_flexion | C/D | no | si | triceps, deltoide lateral |
| extension de triceps | torso | elbow_extension | C/D | no | si | biceps, deltoide posterior |

## Patrones oficiales pierna (contrato)
| Patron | Region | Familias compatibles (catalogo) | Slots | Puede ser A | Puede ir en biserie | Parejas compatibles |
|---|---|---|---|---|---|---|
| dominante de rodilla | pierna | knee_dominant, knee_extension | A/B | si | condicional | femoral, pantorrilla |
| dominante de cadera | pierna | hip_hinge, hip_extension | A/B | si | condicional | rodilla secundaria, abdomen |
| flexion de rodilla/isquios | pierna | knee_flexion | B/C | no preferente | si | quads, gluteo accesorio |
| gluteo accesorio | pierna | glute_bridge, hip_abduction | C/D | no | si | femoral, abdomen |
| pantorrilla | pierna | calf_raise | D | no | si | abdomen, biceps/triceps |
| abdomen | pierna/torso soporte | trunk_flexion | D | no | si | pantorrilla, accesorios |

## Nota forense
Catagolo provee patrones granulares; contrato funcional agrupa en patrones de negocio. Esta matriz alinea ambos niveles.
