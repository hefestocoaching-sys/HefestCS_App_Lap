# Motor V3 Frequency Distribution Audit

## Frecuencia nominal (de papel)
- Nominal historica: derivada de `VolumeToFrequencyRule.frequencyForWeeklyVolume(...)`.

## Frecuencia real observada (runtime)
1. Frecuencia efectiva se calcula por split + dias elegibles del musculo.
2. `frequency_feasibility_resolver` valida capacidad (`maxAssignable = effectiveFrequency * dailyCap`).
3. `volume_feasibility_normalizer` ajusta target cuando excede capacidad manteniendo frecuencia fija.
4. Validator forense exige `actualFrequency == expectedFrequency` por musculo.

## Contradicciones detectadas
1. En x5/x6, la arquitectura real de tipo de dia no esta 100% materializada en builder (hoy hay sesgo upper/lower fallback).
2. Frecuencia nominal sola no describe bien distribucion por tipo de dia.

## Contrato recomendado
1. Frecuencia se define por split+tipo de dia+musculo elegible.
2. Numero nominal solo se usa para chequeo de consistencia, no para construir dias.
3. Si target excede capacidad: normalizar volumen, no elevar frecuencia.

## Estado de cierre
Contrato de normalizacion pre-motor esta implementado; falta cerrar completamente matriz x5/x6 por tipo de dia runtime.
