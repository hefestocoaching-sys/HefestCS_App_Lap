# Fase 10 - Normalizacion de Volumen Factible (Frecuencia Rigida)

## Objetivo
Implementar normalizacion pre-motor para evitar bloqueos por volumen imposible cuando la frecuencia contractual es rigida.

## Regla aplicada
- Frecuencia: no se incrementa automaticamente.
- Capacidad maxima asignable por musculo:
  - maxAssignable = effectiveFrequency * dailyCap
- Si targetSets > maxAssignable:
  - targetFinal = maxAssignable
- Si targetSets <= maxAssignable:
  - targetFinal = targetSets

## Integracion real en pipeline V3
1. Etapa pre-build en orquestador:
   - Se calcula target original por musculo.
   - Se normaliza a target factible con trazabilidad estructurada.
2. Build usa target normalizado.
3. Forensic validator recibe expectedWeeklyVolumeByMuscle normalizado.
4. Se conserva trazabilidad en extra del plan:
   - volume_targets_original
   - volume_targets_final
   - volume_normalization (lista por musculo)

## Componentes agregados/modificados
- Nuevo servicio:
  - lib/domain/training_v3/services/volume_feasibility_normalizer.dart
- Integracion en orquestador:
  - lib/domain/training_v3/services/motor_v3_orchestrator.dart
- Robustez de runner manual para serializacion JSON en markdown:
  - test/manual/training_v3_case_audit_runner_test.dart

## Trazabilidad de logs
Se emite log estructurado por musculo:
- [V3][P0.3][VOLUME_NORMALIZATION] muscle=... original=... final=... maxAssignable=... adjusted=... reason=... freq=... dailyCap=... split=... days=...

## Evidencia de ejecucion
### Runner manual de 5 casos
Comando ejecutado:
- flutter test test/manual/training_v3_case_audit_runner_test.dart

Resultado:
- All tests passed
- Los 5 casos se generan y pasan validacion forense (ver index summary)

Archivo resultado:
- docs/audits/generated_cases/index_summary.md

### Analisis estatico
Comando ejecutado:
- flutter analyze

Resultado:
- Sin errores nuevos de compilacion por Fase 10.
- Persisten warnings/info preexistentes del repositorio.

## Resultado funcional
- Se elimina el bloqueo temprano por infeasibilidad de volumen en entrada.
- El motor continua con frecuencia rigida.
- El objetivo semanal esperado para validacion se alinea con target normalizado factible.

## Nota tecnica
La normalizacion tambien se aplica en el flujo semanal interno (antes de clonado/escalado de sets) para evitar objetivos semanales imposibles en semanas posteriores del ciclo.