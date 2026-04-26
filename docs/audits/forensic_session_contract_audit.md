# Forensic Session Contract Audit

## Contrato Esperado
`exercise_slot_conflict_rules_v3.json` define:
- slots válidos: `A, B1, B2, C1, C2, D1, D2`
- `oneA = true`
- `dOptional = true`
- `noExtraSlots = true`

## Evidencia De Implementación
- Builder define plan de slots por bloque:
  - `A -> [A]`
  - `B -> [B1, B2]`
  - `C -> [C1, C2]`
  - `D -> [D1, D2]`
- Ranking estructural de slots también está hardcoded en `_slotRank`.
- Validator bloquea combinaciones inválidas de `blockLabel` y `slotLabel`.

Referencias:
- `assets/data/training_v3/catalog/exercise_slot_conflict_rules_v3.json`
- `lib/domain/training_v3/services/cycle_template_builder.dart` (`_slotPlanForBlock`, `_slotRank`)
- `lib/domain/training_v3/validators/training_plan_forensic_validator.dart` (validación block/slot)

## Hallazgos
1. El set de slots válido sí se respeta en runtime.
2. La coherencia block/slot se valida con bloqueo forense.
3. Parte del contrato está codificada en lógica (hardcoded) y no completamente ejecutada desde JSON de reglas (`oneA`, `dOptional`, `noExtraSlots`).

## Riesgo
- **P1**: Si cambia el contrato en JSON sin actualizar código hardcoded, aparece drift silencioso.

## Veredicto
- **Cumplimiento actual de estructura base A/B/C/D**: `ALTO`.
- **Ejecución data-driven completa del contrato de sesión**: `PARCIAL`.
