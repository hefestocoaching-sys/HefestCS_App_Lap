# Fase 9 - Contract Alignment (Validator as SSOT)

## Cambios aplicados

1. Frecuencia rigida por contrato
- Se elimino el auto-escalado de frecuencia en el resolver de factibilidad.
- Se elimino el forzado de frecuencia minima f2 para split upper/lower en 4 dias.
- Se elimino el aumento de frecuencia por minDaysNeeded en distribuidores UL y FullBody.
- Si frecuencia base no soporta cap diario, ahora falla temprano con error explicito de factibilidad.

2. SSOT unico para frecuencia
- Validator ahora usa VolumeToFrequencyRule para calcular frecuencia esperada.
- Se elimina duplicacion semantica de reglas de frecuencia.

3. Pairing seguro en builder
- Asignacion de pairGroupId ahora solo ocurre si:
  - musculos primarios distintos,
  - y PairingContract permite la biserie.
- Si no cumple, fallback automatico a single (sin pairGroupId) y traza de evento.

4. Orden estructural heavy-first
- Se aplica orden final por categoria de carga (heavy -> medium -> light) antes de cerrar sesion.
- Se conserva orden relativo original dentro de la misma categoria.

5. Precheck de intensidad
- Se agrega precheck por musculo/dia para exigir al menos un candidato compatible con zona primaria seleccionada.
- Si no existe candidato, se retorna fallo explicito de precheck.

## Archivos modificados
- lib/domain/training_v3/services/frequency_feasibility_resolver.dart
- lib/domain/training_v3/services/cycle_template_builder.dart
- lib/domain/training_v3/validators/training_plan_forensic_validator.dart

## Validacion ejecutada

1. Runner manual 5 casos
- Comando: flutter test test/manual/training_v3_case_audit_runner_test.dart
- Resultado tecnico: ejecuta correctamente y regenera evidencia.
- Resultado funcional: 0/5 generados.
- Nuevo patron de fallo: fail-fast de factibilidad P0.2 por conflicto entre frecuencia contractual f1 y cap diario 10 cuando target semanal supera 10 en varios musculos.

2. Analisis estatico
- Comando: flutter analyze
- Resultado: sin errores de compilacion en cambios de Fase 9; persisten warnings/info preexistentes del proyecto.

## Estado de criterios Phase 9

- Criterio: desaparicion/reduccion fuerte de errores 2.2/2.6/2.5 por contradiccion motor-validator.
  - Estado: logrado en el flujo ejecutado; el pipeline corta antes con error de factibilidad contractual.

- Criterio: >=3/5 casos generados.
  - Estado: no logrado (0/5).

## Conclusiones
La alineacion de contrato fue aplicada correctamente: el motor ya no contradice al validator en frecuencia y pairing estructural, y falla temprano cuando el problema es matematicamente inviable bajo las reglas actuales.

El bloqueo actual es de politica global, no de contradiccion de implementacion:
- frecuencia contractual para 11-12 series es f1,
- cap diario por musculo es 10,
- por tanto hay configuraciones de entrada intrinsecamente inviables sin ajustar una de esas dos politicas.
