# Training Motor V3 - Fase 5: Resolver de Factibilidad de Frecuencia

## Objetivo

Eliminar bloqueos por infactibilidad de volumen diario causados por usar frecuencia base no escalada, sin recortar sets objetivo ni crear rutas alternas al pipeline real V3.

## Punto del bug (auditado)

- En el flujo real, la frecuencia base se deriva por volumen semanal y luego se valida factibilidad por cap diario.
- Cuando `targetSets > effectiveFrequency * dailyCap`, antes se bloqueaba sin intentar escalar frecuencia de forma estructurada.
- El problema ocurria en pre-chequeo y en construccion de base week, con diferencias de contexto entre split y dias elegibles.

## Solucion Fase 5 implementada

### 1) Resolver dedicado

Se creo `frequency_feasibility_resolver.dart` con:

- `FrequencyFeasibilityResolver.resolveFeasibleFrequency(...)`
- Escaneo secuencial `baseFrequency..maxFrequency`
- Uso de `effectiveFrequencyForCandidate` provisto por el caller (sin inventar logica paralela)
- Resultado estructurado con:
  - `targetSets`
  - `baseFrequency`
  - `finalFrequency`
  - `effectiveFrequency`
  - `dailyCap`
  - `maxAssignable`
  - `wasAdjusted`
  - `isFeasible`
  - `reason`
  - `blockingError`

### 2) Integracion en pipeline real (motor)

En `motor_v3_orchestrator.dart`:

- `_deriveFrequencyByMuscle(...)` ahora:
  - usa `VolumeToFrequencyRule.frequencyForWeeklyVolume(...)` como contrato base
  - ejecuta resolver con `_effectiveFrequencyForSplit(...)`
  - usa `effectiveFrequency` final para construir prioridad por dia
- `_feasibilityErrors(...)` ahora:
  - usa el mismo resolver para detectar bloqueos reales
  - produce errores estructurados solo cuando no existe frecuencia factible

### 3) Integracion en construccion real (builder)

En `cycle_template_builder.dart`:

- `_calculateMuscleConfigOrFail(...)` ahora recibe `split`
- por musculo:
  - calcula frecuencia base por contrato
  - ejecuta resolver con `_effectiveFrequencyForMuscle(...)`
  - construye config con `effectiveFrequency` final
  - bloquea solo si `isFeasible=false`
- se mantiene `hard-fail` cuando realmente no existe capacidad

## Garantias de contrato

- No hay recorte silencioso de sets objetivo.
- La unica estrategia automatica es escalar frecuencia dentro de capacidad real del split/dias.
- Si aun asi no cabe, se devuelve bloqueo explicito con trazabilidad.

## Trazabilidad agregada

Se agrego traza estructurada por musculo:

- `[V3][P0.2][FREQ_TRACE] muscle=... target=... base=... final=... effective=... dailyCap=... maxAssignable=... adjusted=... feasible=... reason=...`

Esto permite auditar por que se ajusto o bloqueo cada musculo.

## Validacion ejecutada

### Runner de 5 casos reales

Comando ejecutado:

- `flutter test test/manual/training_v3_case_audit_runner_test.dart`

Resultado:

- Test runner: OK (`All tests passed`).
- Se regeneraron los markdown de casos bajo `docs/audits/generated_cases/`.
- Estado funcional del pack sigue bloqueado por errores de `ZONE_VALIDATION_FAIL` (fuera del alcance de Fase 5), no por crash ni por throw no controlado de factibilidad.

### Analisis estatico

Comando ejecutado:

- `flutter analyze`

Resultado:

- Sin errores en los archivos modificados de Fase 5.
- El workspace mantiene warnings/info preexistentes en otros modulos.

## Archivos tocados en Fase 5

- `lib/domain/training_v3/services/frequency_feasibility_resolver.dart` (nuevo)
- `lib/domain/training_v3/services/motor_v3_orchestrator.dart`
- `lib/domain/training_v3/services/cycle_template_builder.dart`

## Impacto esperado

- Menos bloqueos falsos por frecuencia base insuficiente cuando la frecuencia puede escalarse y sigue siendo valida en split/dias.
- Bloqueos residuales quedan explicitamente trazados cuando la capacidad real del split no alcanza.
- Pipeline V3 real permanece intacto y sin rutas alternas.
