# Forensic Rotation Audit

## Objetivo
Verificar si el contrato de rotación del catálogo V3 gobierna realmente la variación entre bloques/semanas.

## Evidencia
- El catálogo expone `rotationGroup`, `variantTier`, `canPromoteToHeavyNextBlock`, `canDemoteToMediumNextBlock`.
- Runtime sí usa:
  - `variantTier` para ordenación/selección.
  - `canDemoteToMediumNextBlock` en resolución de conflictos heavy.
- No se encontró uso efectivo de `rotationGroup` en decisiones de rotación semanal/inter-bloque.
- Validator controla redundancia por `equivalenceGroup`, pero no valida explícitamente contrato de rotación por `rotationGroup`.

Referencias:
- `lib/domain/training_v3/data/exercise_catalog_v3.dart`
- `lib/domain/training_v3/services/cycle_template_builder.dart`
- `lib/domain/training_v3/engines/exercise_selection_engine.dart`
- `lib/domain/training_v3/validators/training_plan_forensic_validator.dart`

## Hallazgos
1. Hay variación parcial soportada por equivalencias/tiers.
2. El eje `rotationGroup` está modelado pero no plenamente operativo como contrato runtime.

## Riesgo
- **P1**: Rotación real incompleta; riesgo de repetición subóptima en mesociclo.

## Veredicto
- **Rotación contractual completa**: `NO`.
- **Rotación heurística parcial**: `SI`.
