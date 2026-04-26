# Catalog V3 Integration Audit

Fecha: 2026-04-19

## Ruta anterior (legacy)
- Loader principal legacy en `lib/domain/training_v3/data/exercise_catalog_v3.dart` apuntaba a `assets/data/exercises/exercise_catalog_gym.json`.
- Loader auxiliar usado por provider en `lib/data/datasources/local/exercise_catalog_loader.dart` también apuntaba a `assets/data/exercises/exercise_catalog_gym.json`.
- Servicio legacy adicional en `lib/services/exercise_catalog_service.dart` cargaba `assets/data/exercises/exercise_catalog_gym.json` y degradaba silenciosamente en error.

## Archivos/rutas legacy detectados
- `lib/domain/training_v3/repositories/exercise_database_repository.dart`
: catálogo mock embebido hardcodeado (no SSOT runtime).
- `lib/services/exercise_catalog_service.dart`
: ruta de asset legacy + fallback no bloqueante.
- `lib/domain/training_v3/utils/muscle_key_adapter_v3.dart`
: documentación referenciaba archivo legacy de catálogo.

## Ruta nueva runtime (SSOT real)
- Runtime principal: `assets/data/training_v3/catalog/exercise_catalog_v3_runtime.json`
- Registros auxiliares cargados junto al runtime:
  - `assets/data/training_v3/catalog/exercise_pattern_registry_v3.json`
  - `assets/data/training_v3/catalog/exercise_muscle_zone_defaults_v3.json`
  - `assets/data/training_v3/catalog/exercise_slot_conflict_rules_v3.json`
  - `assets/data/training_v3/catalog/exercise_media_library_v3.json`

## Integración ejecutada
- `ExerciseCatalogV3` fue reescrito para cargar únicamente los assets de `assets/data/training_v3/catalog/`.
- Se eliminó fallback silencioso en carga de runtime y se forzó fallo explícito ante JSON inválido o asset faltante.
- El `MotorV3Orchestrator` ignora listas externas de ejercicios para impedir override de catálogo en runtime real.
- Se agregó modelo tipado fuerte `ExerciseCatalogV3Entry` para campos V3 de selección, conflicto, slot y rotación.

## Riesgos de coexistencia
- Riesgo residual 1: existen clases legacy aún compilables (`ExerciseDatabaseRepository`, `ExerciseCatalogService`) para compatibilidad histórica.
- Mitigación aplicada: marcadas como `@Deprecated` y fuera del carril runtime real del Motor V3.
- Riesgo residual 2: consumidores no-Motor podrían seguir usando rutas legacy si se invocan manualmente.
- Mitigación recomendada siguiente paso: migrar consumidores legacy no críticos a `ExerciseCatalogV3` y luego retirar rutas antiguas.

## Estado final esperado del runtime real
- El Motor V3 usa exclusivamente catálogo runtime V3 desde assets de `training_v3/catalog`.
- La selección en ciclo/builder usa metadatos del catálogo (slotRoles, allowed zones, patterns, conflictPatterns, heavy eligibility).
- El validador forense bloquea incoherencias de slot/zona/A/heavy conflict contra contrato V3.
