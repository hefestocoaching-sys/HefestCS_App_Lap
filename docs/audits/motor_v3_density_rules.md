# Motor V3 Density Rules Audit

## Evidencia runtime
1. Cap diario por musculo: 10 sets (`_defaultDailyCapPerMuscle`).
2. Soft session sets: 40 (warning), hard: 50 (blocking) en validator forense.
3. Builder bloquea violacion de cap diario.

## Hallazgos
1. Hay warnings de sesion alta que no bloquean hasta 50 sets.
2. Puede existir concentracion >=75% de sesion en un musculo como warning.
3. Contrato funcional pide bloquear absurdos; regla de warning debe endurecerse en ciertos casos.

## Propuesta contractual por split y nivel
### x3
- Novato:
  - primario: 3-4 sets/sesion
  - secundario: 2-3
  - terciario: 1-2
  - total sesion sugerido: 14-24
- Intermedio:
  - primario: 4-6
  - secundario: 2-4
  - terciario: 1-3
  - total sesion sugerido: 18-30

### x4
- Novato: 12-22 sets/sesion.
- Intermedio: 16-28 sets/sesion.
- Avanzado: 18-32 sets/sesion.

### x5
- Novato: 12-22.
- Intermedio: 16-28.
- Avanzado: 18-34.

### x6
- Novato: 10-20.
- Intermedio: 14-26.
- Avanzado: 16-30.

## Reglas blocking sugeridas
1. Si un musculo supera 65% de sesion y ademas >8 sets directos: blocking.
2. Si sesion >45 sets: blocking.
3. Si un dia mete 2 compuestos pesados del mismo patron dominante: blocking.
