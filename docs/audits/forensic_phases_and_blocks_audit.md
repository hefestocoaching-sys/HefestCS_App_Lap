# Forensic Phases And Blocks Audit

## Fases (Business Layer)
Mapeo observado:
- adaptation -> `AA`
- accumulation -> `HF1/HF2/HF3`
- maintenance -> `maintenance_early` / `maintenance_late`
- microDeload/deload -> `regeneration`

Factores de volumen:
- `AA` = 0.85
- `HF1` = 1.0
- `HF2` = 1.05
- `HF3` = 1.10
- `regeneration` = 0.5

## Bloques/Slots
- Builder y validator operan sobre estructura A/B/C/D con slots `A/B1/B2/C1/C2/D1/D2`.
- Orden estructural y resolución de conflictos se aplican post-construcción de sesión.

Referencias:
- `lib/domain/training_v3/services/motor_v3_orchestrator.dart` (resolución de fase, factor de volumen, metadata `business_phase_by_week`)
- `lib/domain/training_v3/services/cycle_template_builder.dart` (plan/rank de slots)
- `lib/domain/training_v3/validators/training_plan_forensic_validator.dart` (bloqueo block/slot inválido)

## Hallazgos
1. El pipeline persiste `business_phase_by_week` como artefacto trazable.
2. Las fases sí impactan volumen e intensificación.
3. La semántica de contrato de sesión viene parcialmente hardcoded en código además de JSON de reglas.

## Riesgo
- **P1**: Cambios de contrato en JSON pueden no propagarse automáticamente a runtime por duplicidad de fuente (data + código).

## Veredicto
- **Motor fase/bloque**: `FUNCIONAL`.
- **Gobernanza 100% data-driven**: `NO COMPLETA`.
