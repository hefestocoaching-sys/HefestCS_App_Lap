# Motor V3 Adaptation Contract

## Estado actual
1. Bitacora real:
   - `weeklyVolumeHistory` en `training.extra`.
   - `recordCompletedSession(...)` agrega registros por musculo.
2. Estado de progresion:
   - `trainingProgressionStateV1`.
3. Decisiones semanales:
   - `weeklyDecisionArtifactsV1`.
4. Servicios paralelos:
   - `weekly_progression_service_impl` (tracker por musculo).

## Contrato propuesto (futuro cercano)
1. No ajustar en tiempo real dentro de la sesion.
2. Evaluar al cierre semanal (fin de semana o cierre explicito).
3. Aplicar cambios SOLO para semana siguiente.
4. No reescribir toda la macro de golpe.

## 52 semanas
### No competidor
- Historico longitudinal 52 semanas por musculo, real+programado.
- Objetivo: tendencia de adherencia y progresion sostenible.

### Competidor
- Timeline hacia fecha objetivo (`weeksToCompetition`, `peakPhaseWindow`).
- Contrato: microciclos orientados a pico y taper en ventana final.

## Gap
1. Timeline de competidor no esta cerrado como contrato runtime end-to-end.
2. Convivencia de carriles de progresion requiere unificar writer oficial.
