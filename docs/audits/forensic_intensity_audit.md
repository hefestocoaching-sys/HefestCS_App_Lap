# Forensic Intensity Audit

## Contrato Observado
- Regla por zona:
  - heavy -> `dropSet`
  - medium -> `restPause`
  - light -> `isometricHold`
- Fases que permiten intensificación por zona: `HF2`, `HF3`, `maintenance_late`.
- Elegibilidad de ejercicio aplica filtros biomecánicos (core/carry/neural lower heavy, etc.).

## Evidencia
- Política de elegibilidad: `IntensificationEligibility`.
- Aplicación por semana/fase: `_applyZoneIntensificationContract`.
- Validación bloqueante de tipo de intensificación y parámetros: `_validateIntensificationContract`.

Referencias:
- `lib/domain/training_v3/policies/intensification_eligibility.dart`
- `lib/domain/training_v3/services/motor_v3_orchestrator.dart` (`_applyZoneIntensificationContract`, `_intensificationRuleForZone`)
- `lib/domain/training_v3/validators/training_plan_forensic_validator.dart` (`2.3_intensity_correctness`)

## Hallazgos
1. Contrato de intensidad sí está implementado y con enforcement forense.
2. El validador bloquea cuando una fase requiere intensificación y el ejercicio no la trae.
3. Existe divergencia entre metadata JSON `intensificationEligibleZones` y política runtime real (no gobernada por ese campo).

## Riesgo
- **P1**: Drift semántico catálogo-vs-runtime para intensificación.

## Veredicto
- **Intensidad runtime**: `ROBUSTA`.
- **Alineación completa con metadata expandida de catálogo**: `PARCIAL`.
