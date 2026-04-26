# Forensic Heavy Conflict Audit

## Contrato
`exercise_slot_conflict_rules_v3.json`:
- `maxHeavySamePatternPerSession = 1`
- segundo heavy solo si patrón distinto y subordinado a A.

## Evidencia Runtime
- Builder ejecuta `_resolveHeavyPatternConflictsInSession(...)`.
- Si hay conflicto de patrón heavy, intenta sustitución a medium/light vía equivalencias y reglas de elegibilidad.
- Si no existe resolución válida, lanza bloqueo (`StateError`) con contexto.
- Validator vuelve a checar y bloquea si hay patrón heavy duplicado en sesión.

Referencias:
- `lib/domain/training_v3/services/cycle_template_builder.dart` (resolución de conflictos heavy)
- `lib/domain/training_v3/validators/training_plan_forensic_validator.dart` (regla `2.7_daily_feasibility` para conflicto heavy)

## Hallazgos
1. Existe doble capa de seguridad (builder + validador), correcta para un contrato crítico.
2. La degradación de heavy conflict depende de disponibilidad real en pool/equivalencias.
3. El contrato se cumple de forma robusta cuando hay alternativas; sin alternativas, el flujo bloquea (correcto por diseño forense).

## Riesgo
- **P1**: En pools escasos por músculo, probabilidad de bloqueo aumenta; no hay estrategia de contingencia más allá del fail-fast.

## Veredicto
- **Integridad de heavy conflict**: `ALTA`.
- **Resiliencia ante catálogo limitado**: `MEDIA`.
