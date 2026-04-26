# Motor V3 Phase Contracts

## Fases requeridas por negocio
AA, HF1, HF2, APC, AT, T.

## Lo que existe hoy en codigo runtime
1. `core/enums/training_phase.dart`: accumulation, intensification, deload.
2. Estado interno de ciclo en motor: adaptation, accumulation, microDeload, maintenance, deload.
3. UI macrocycle muestra bloques AA/HF1/HF2 para visualizacion 52 semanas.

## Gap forense
1. AA/HF1/HF2/APC/AT/T no estan como contrato tecnico unico en runtime.
2. Existe mezcla entre fase de visualizacion, fase de progresion y fase de generacion.

## Parametros requeridos por fase (contrato a cerrar)
| Fase | sets por slot | reps | RER/RIR | densidad | intensificacion |
|---|---|---|---|---|---|
| AA | si | si | si | si | no |
| HF1 | si | si | si | si | opcional |
| HF2 | si | si | si | si | opcional |
| APC | si | si | si | si | controlada |
| AT | si | si | si | si | alta |
| T | si | si | si | si | taper/deload dirigido |

## Estado actual por parametro
1. sets/reps/rir existen pero por reglas generales, no por AA/HF1/HF2/APC/AT/T.
2. densidad existe parcial via caps globales.
3. intensificacion existe en mantenimiento y reglas por ejercicio, no tabla completa por fase de negocio.

## Decision funcional pendiente
Definir mapeo canonico de AA/HF1/HF2/APC/AT/T hacia fases runtime del motor y sus parametros tabulares.
