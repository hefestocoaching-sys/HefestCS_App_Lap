# Motor V3 SSOT Audit

## Alcance auditado
- `TrainingPlanConfig`
- `SplitTableSSOT`
- tablas de split
- normalizadores musculares
- catalogo y metadata
- validator forense
- constants y adapters legacy

## SSOT reales (runtime)
1. Flujo de plan activo:
   - `trainingPlanProvider.generatePlanFromActiveCycle(...)`.
2. Estructura de ciclo congelado:
   - `TrainingCycle.freezePlanSnapshot`.
3. Volumen esperado del plan:
   - `TrainingPlanConfig.volumePerMuscle`.
4. Validacion final bloqueante:
   - `TrainingPlanForensicValidator`.
5. Llaves canonicales musculares:
   - `muscle_registry` + `normalizeMuscleKey`.
6. Catalogo de ejercicios:
   - `assets/data/exercises/exercise_catalog_gym.json` via `ExerciseCatalogV3`.

## Pseudo-SSOT detectados
1. `SplitTableSSOT` solo aporta prioridades/templates base, no define todo el split runtime.
2. `split_generator_engine.dart` y `split_config.dart` contienen narrativa de split no 100% alineada al flujo builder real.
3. `split_templates.dart` (legacy) mantiene tablas paralelas de split.
4. Enums de fase duplicados en varios modulos.
5. Vistas UI con modelos de bloques AA/HF1/HF2 no necesariamente iguales al runtime de motor.

## Duplicaciones
1. Fase:
   - `core/enums/training_phase.dart`
   - `training_v3/enums/training_enums.dart`
   - `periodization_engine.dart`
2. Split:
   - `TrainingSplit` runtime
   - `SplitConfig`/`split_generator_engine`
   - `split_templates.dart` legacy
3. Progresion:
   - `recordCompletedSession` y `trainingProgressionStateV1` en provider
   - `weekly_progression_service_impl` paralelo

## Conflictos funcionales
1. Frecuencia como numero teorico vs frecuencia efectiva por tipo de dia.
2. Matrices AA/HF1/HF2 en UI vs fases runtime actuales del motor (cycle phase state).
3. Tracking semanal existe en dos carriles sin agregador contractual unico.

## Recomendaciones SSOT
1. Declarar SSOT de split runtime = `TrainingSplit + CycleTemplateBuilder`.
2. Declarar `split_templates.dart` como legacy no operativo para motor V3.
3. Mantener `TrainingPlanForensicValidator` como gate final obligatorio pre-persistencia.
4. Consolidar contrato de fase en un solo enum de runtime para motor.
5. Mantener `trainingPlanProvider.generatePlanFromActiveCycle` como unica entrada de generacion real.
