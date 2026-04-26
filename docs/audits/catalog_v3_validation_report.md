# Catalog V3 Validation Report

Fecha: 2026-04-19

## Alcance
Validación de integridad previa al uso runtime del catálogo V3 en `ExerciseCatalogV3.ensureLoaded()`.

## Validaciones bloqueantes implementadas
- Campo obligatorio `movementPattern` por ejercicio.
- Campo obligatorio `slotRoles` por ejercicio y verificación contra `validSlots` del contrato (`A`, `B1/B2`, `C1/C2`, `D1/D2`).
- Campo obligatorio `allowedIntensityZones` con al menos una zona permitida.
- Campo obligatorio `exerciseOrderClass` con entero positivo.
- Coherencia `heavyRole` vs `allowedIntensityZones.heavy`:
  - `forbidden` no puede permitir heavy.
  - `primary|secondary` deben permitir heavy.
- `primaryMuscles` validado contra SSOT canónico vía `muscle_registry.normalize`.
- `movementPattern` debe existir en `exercise_pattern_registry_v3.json`.
- Si `aEligibility` requiere A, el ejercicio debe incluir slot `A`.
- Formato de `conflictPatterns` no vacío y `pairingClass` no vacío.

## Validaciones warning (no bloqueantes)
- `media.gifPath` fuera de prefijo esperado `assets/media/exercises/gifs/` se registra como warning.
- Warnings de media se exponen al validador forense y no bloquean materialización del plan.

## Aplicación en runtime
- Validación se ejecuta al cargar catálogo antes de generar planes.
- Si hay violación bloqueante, la carga falla con `StateError` explícito.
- No existe fallback silencioso a catálogo legacy.

## Contratos de selección reforzados
- Selector/builder usa `slotRoles` para elegibilidad de slot real.
- Slot `A` exige `aEligibility` válido.
- Heavy secundario exige `secondaryHeavyEligibility`.
- Conflicto heavy usa `conflictPatterns` del JSON, no solo equivalence group.

## Contratos forenses reforzados
- BLOCK si ejercicio se usa en slot no permitido por `slotRoles`.
- BLOCK si ejercicio no A-eligible se usa en slot A.
- BLOCK si patrón no coherente con slot según pattern registry.
- BLOCK si heavy secundario no está permitido por `secondaryHeavyEligibility`.
- BLOCK si hay colisión heavy por conflictPattern en misma sesión.
- Warnings de media se preservan como no bloqueantes.
