# T08 - MATRIZ DE REGLAS, CLASIFICACION Y EVIDENCIA

## Reglas observadas
1. Generacion bloqueada si flow stage != plan.
- Evidencia: training_plan_provider.dart:2193

2. Intensity split debe ser valido antes de generar.
- Evidencia: training_plan_provider.dart:2199

3. En generatePlanFromActiveCycle hay validaciones hard pre-persistencia (weeks, volumePerMuscle, split).
- Evidencia: training_plan_provider.dart:1868, 1894, 1918

4. Persistencia local primero, remoto no bloqueante.
- Evidencia: client_repository.dart:23, 28

## Violaciones clasificadas

### VIOLACION DE SSOT
- V1: Doble semantica de `activeCycleId` (entidad top-level y borrado en extra).
  - Evidencia: client.dart:60, training_plan_provider.dart:2551

- V2: Resolucion de plan activo con fallback si `activePlanId` no encuentra plan.
  - Evidencia: training_dashboard_screen.dart:134, training_workspace_provider.dart:69

### IMPLEMENTACION NOMINAL NO OPERATIVA
- N1: `IntensitySplitAllocator` sin invocaciones.
  - Evidencia: intensity_split_allocator.dart:21

- N2: `SplitGeneratorEngine` sin invocacion runtime (solo comentario).
  - Evidencia: split_generator_engine.dart:24, motor_v3_orchestrator.dart:105

- N3: `unifiedTrainingProvider` sin consumidores.
  - Evidencia: unified_training_provider.dart:24

- N4: `TrainingDashboardScreen` no montado por entrypoint real.
  - Evidencia: training_screen.dart:9, training_dashboard_screen.dart:50

### DEGRADACION SILENCIOSA
- D1: Desactivacion de sync remota por sesion ante `permission-denied`.
  - Evidencia: client_repository.dart:107

- D2: `pushTrainingRecord` deshabilitado por retorno inmediato.
  - Evidencia: clinical_records_repository.dart:306

- D3: Sync queue sin branch training.
  - Evidencia: sync_service.dart:47

### VIOLACION DE CAPAS
- C1: `training_plan_provider.dart` concentra logica de dominio + persistencia + transformaciones SSOT + control de flujo UI.
  - Evidencia: training_plan_provider.dart:684-2200 (bloques de negocio + repositorio + estado)

- C2: UI decide rutas diferentes de generacion segun accion (generate vs adapt/deload), disparando pipelines distintos desde pantalla.
  - Evidencia: training_workspace_screen.dart:3065, 3264
