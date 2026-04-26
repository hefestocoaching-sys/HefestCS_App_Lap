# 1. Resumen ejecutivo

## Diagnostico general del motor
El motor actual si genera planes reales end-to-end, pero la separacion de responsabilidades no esta cerrada. El pipeline de generacion convive con logica de bootstrap de ciclo, limpieza de datos legacy, validaciones operativas y persistencia en el mismo borde de entrada.

Punto de entrada dominante:
- lib/features/training_feature/providers/training_plan_provider.dart
- Clase: TrainingPlanNotifier
- Metodo: generatePlanFromActiveCycle

Nucleo de generacion:
- lib/domain/training_v3/orchestrator/training_orchestrator_v3.dart (adaptador)
- lib/domain/training_v3/services/motor_v3_orchestrator.dart (motor)
- lib/domain/training_v3/services/cycle_template_builder.dart (materializacion week 1)

## Estado general del pipeline
Pipeline real actual (no ideal):
1. UI/screens llaman trainingPlanProvider.notifier.generatePlanFromActiveCycle(...)
2. Provider valida gate de flujo (TrainingPipelineGuard) y carga Client
3. Provider resuelve/crea ciclo activo y carga catalogo
4. Provider instancia TrainingOrchestratorV3
5. TrainingOrchestratorV3 adapta Client -> UserProfile y delega en MotorV3Orchestrator.generateProgram
6. MotorV3Orchestrator resuelve volumen/split/intensidad/pool y usa CycleTemplateBuilder
7. MotorV3Orchestrator arma TrainingPlanConfig y corre checks (factibilidad/cobertura)
8. Provider persiste plan + activePlanId + freezePlanSnapshot + artefactos semanales

## Principales hallazgos
- Existe SSOT muscular fuerte en lib/core/registry/muscle_registry.dart, pero hay normalizaciones adicionales en UI/provider que introducen duplicidad funcional.
- Hay coexistencia de capas de intensidad:
  - modelo de porcentaje (IntensitySplit)
  - distribucion por sets (IntensityDistributionEngine)
  - asignacion por dia/ejercicio (IntensityEngine)
- El ordenado y acomodado de ejercicios esta repartido en multiples capas:
  - ordering_engine.dart
  - exercise_ordering_rules.dart
  - session_structure_engine.dart
  - cycle_template_builder.dart
- La persistencia de decision/progresion esta fragmentada entre varias llaves de extra y logs.
- Existen componentes legacy aun presentes (por ejemplo training_plan_v3_provider.dart, metodos Deprecated en training_plan_provider.dart).

## Riesgos criticos
- Riesgo de divergencia de estado por doble carril de progresion (motor/proveedor/servicios semanales).
- Riesgo de reglas inconsistentes por pseudo-SSOT de normalizacion en pantalla/proveedor.
- Riesgo de comportamiento silencioso por fallbacks amplios en seleccion/metadata de catalogo.

## Que NO se debe tocar todavia
- No rehacer arquitectura del motor.
- No cambiar contratos publicos de generatePlanFromActiveCycle.
- No redisenar UI.
- No introducir un catalogo V4 ni clasificador estructural nuevo hasta cerrar SSOT y responsabilidades.

# 2. Alcance auditado

## Carpetas y archivos inspeccionados
- lib/features/training_feature/screens/
- lib/features/training_feature/providers/
- lib/features/training_feature/domain/
- lib/features/training_feature/tabs/
- lib/domain/training_v3/
- lib/domain/training/
- lib/core/registry/
- lib/core/utils/
- lib/data/datasources/local/
- lib/data/repositories/training/
- assets/data/exercises/
- test/domain/training_v3/

Archivos clave:
- lib/features/training_feature/providers/training_plan_provider.dart
- lib/features/training_feature/screens/training_workspace_screen.dart
- lib/features/training_feature/domain/training_pipeline_guard.dart
- lib/domain/training_v3/services/motor_v3_orchestrator.dart
- lib/domain/training_v3/services/cycle_template_builder.dart
- lib/domain/training_v3/orchestrator/training_orchestrator_v3.dart
- lib/domain/training_v3/data/exercise_catalog_v3.dart
- lib/domain/entities/exercise.dart
- lib/core/registry/muscle_registry.dart
- lib/core/utils/muscle_key_normalizer.dart
- lib/domain/training_v3/engines/*
- lib/domain/training_v3/validators/*
- lib/domain/training/training_cycle.dart
- lib/data/repositories/training/training_cycle_repository_impl.dart
- assets/data/exercises/exercise_catalog_gym.json

## Fuera de alcance (en esta fase)
- Refactor de arquitectura.
- Cambios funcionales de UI.
- Redefinicion de modelos de dominio para V4.

## Dependencias externas que impactan el analisis
- Riverpod (orquestacion de estado/acciones)
- Persistencia de Client (repositorio)
- WorkoutLogRepository (deload/progresion)

# 3. Pipeline real actual del motor

## Etapa A: UI/Provider trigger
- Archivo: lib/features/training_feature/screens/training_workspace_screen.dart
- Clase: TrainingWorkspaceScreen
- Metodos que disparan: _generarPlan, _regenerarPlan, _adaptarPlan y acciones con deload
- Entrada: accion usuario
- Salida: llamada a generatePlanFromActiveCycle
- Responsabilidad actual: habilitar acciones y disparar regeneracion/adaptacion
- Problemas: pantalla conoce detalle de flujo, progreso y deload (acoplamiento con dominio)

## Etapa B: Gate de pipeline
- Archivo: lib/features/training_feature/domain/training_pipeline_guard.dart
- Clase: TrainingPipelineGuard
- Metodo: allowedStage
- Entrada: training.extra
- Salida: etapa permitida (interview, landmarks, intensity, gymExercises, plan, monitoring)
- Responsabilidad actual: bloquear avance sin entrevista/landmarks/intensidad/preferencias
- Problemas: valida estado por llaves extra dispersas; no existe esquema formal versionado del pipeline

## Etapa C: Orquestacion principal y persistencia
- Archivo: lib/features/training_feature/providers/training_plan_provider.dart
- Clase: TrainingPlanNotifier
- Metodo: generatePlanFromActiveCycle
- Entrada: DateTime + estado cliente activo
- Salida: TrainingPlanConfig? persistido
- Responsabilidad actual:
  - cargar cliente
  - validar flujo estructurado
  - resolver ciclo activo / bootstrap
  - cargar catalogo
  - invocar orquestador
  - persistir plan/ciclo/snapshot/artefactos
- Problemas:
  - mezcla responsabilidades de dominio y persistencia
  - contiene limpieza de llaves legacy
  - opera como borde unico y tambien como capa de proceso interno

## Etapa D: Adaptador de dominio
- Archivo: lib/domain/training_v3/orchestrator/training_orchestrator_v3.dart
- Clase: TrainingOrchestratorV3
- Metodo: generatePlan
- Entrada: Client + exercises + phase + fecha
- Salida: TrainingProgramV3Result
- Responsabilidad actual: convertir Client -> UserProfile y delegar en MotorV3Orchestrator
- Problemas: mezcla lectura SSOT v1/legacy/defaults en un adaptador que idealmente deberia ser mas delgado

## Etapa E: Motor de generacion
- Archivo: lib/domain/training_v3/services/motor_v3_orchestrator.dart
- Clase: MotorV3Orchestrator
- Metodo: generateProgram
- Entrada: UserProfile + split/fase/intensidad/landmarks/pool
- Salida: Map (success, errors, warnings, planConfig/program)
- Responsabilidad actual:
  - resolver volumen y split
  - resolver intensidad
  - resolver pool de ejercicios
  - construir plan real
  - validar factibilidad/cobertura
- Problemas:
  - retorna Map dinamico, no contrato fuerte en toda la cadena
  - contiene varias politicas y fallbacks en el mismo modulo

## Etapa F: Materializacion de semana base
- Archivo: lib/domain/training_v3/services/cycle_template_builder.dart
- Clase: CycleTemplateBuilder
- Metodo: buildBaseWeek
- Entrada: volumen por musculo, pool, split, intensidad
- Salida: TemplateBuildResult (sessions)
- Responsabilidad actual:
  - asignar musculos a dias
  - seleccionar ejercicios
  - asignar zonas de intensidad
  - pairing y slots A/B/C/D
  - caps diarios/sesion
- Problemas:
  - concentra seleccion + ordering + slotting + pairing + cap
  - alta complejidad operativa para un solo builder

## Etapa G: Validacion y post-proceso
- Archivos:
  - lib/domain/training_v3/services/motor_v3_orchestrator.dart (_feasibilityErrors, _validateExerciseCoverage)
  - lib/domain/training_v3/validators/configuration_validator.dart
  - lib/domain/training_v3/validators/volume_validator.dart
  - lib/domain/training_v3/validators/intensity_validator.dart
- Responsabilidad: asegurar plan utilizable
- Problemas: parte de validacion es warning (no bloqueante), parte bloquea; no existe validador forense unico final

## Etapa H: Persistencia final
- Archivos:
  - lib/features/training_feature/providers/training_plan_provider.dart
  - lib/data/repositories/training/training_cycle_repository_impl.dart
  - lib/domain/training/training_cycle.dart
- Salida persistida:
  - client.trainingPlans[]
  - training.extra.activePlanId
  - trainingCycles + activeCycleId + freezePlanSnapshot
  - weeklyDecisionArtifactsV1
- Problemas: snapshots/artefactos/progresion repartidos en multiples llaves

# 4. Call graph real archivo por archivo

Resumen tecnico detallado en:
- docs/audits/training_motor_call_graph.md

Cadena principal real:
- training_workspace_screen.dart
- training_plan_provider.dart::generatePlanFromActiveCycle
- training_cycle_repository_impl.dart
- training_orchestrator_v3.dart::generatePlan
- motor_v3_orchestrator.dart::generateProgram
- cycle_template_builder.dart::buildBaseWeek
- session_structure_engine.dart / ordering_engine.dart / intensity_distribution_engine.dart
- validadores
- training_plan_provider.dart (persistencia)

# 5. Mapa de responsabilidades actuales

## training_plan_provider.dart
- Responsabilidad actual: orquestador real de negocio + persistencia + progresion + acciones de plan.
- Le corresponde: parcialmente.
- Mezcla: alta.
- SSOT: consume y escribe multiples SSOT/pseudo-SSOT.
- Heuristicas: si.

## motor_v3_orchestrator.dart
- Responsabilidad actual: pipeline central de generacion.
- Le corresponde: si, pero esta sobrecargado.
- Mezcla: media-alta.
- SSOT: consume varios (intensidad, landmarks, split, pool).
- Heuristicas: si.

## cycle_template_builder.dart
- Responsabilidad actual: construir semana base completa.
- Le corresponde: si.
- Mezcla: alta (seleccion+pairing+slotting+cap+orden).
- SSOT: usa catalogo/registry pero tambien fallbacks.
- Heuristicas: si.

## exercise_catalog_v3.dart + exercise.dart
- Responsabilidad actual: cargar catalogo y exponer metadata.
- Le corresponde: si.
- Mezcla: media (cache + metadata + mapeo parcial).
- SSOT: asset es fuerte, dominio tipado es parcial.
- Heuristicas: fallback de metadata.

## muscle_registry.dart + muscle_key_normalizer.dart + mappers UI
- Responsabilidad actual: normalizar claves musculares.
- Le corresponde: si (registry), no totalmente (duplicados UI/provider).
- Mezcla: media.
- SSOT: registry si, pero hay pseudo-SSOT secundarios.
- Heuristicas: si, en variantes legacy.

# 6. Inventario de SSOT actuales

## Claves musculares
- SSOT fuerte: lib/core/registry/muscle_registry.dart (canonicalMuscles + normalize + expandGroup).
- Pseudo-SSOTs: lib/core/utils/muscle_key_normalizer.dart y normalizadores locales en pantallas.
- Estado: duplicado funcional.

## Grupos y expansion back/lats/upper_back/traps
- Expansion de grupos: muscle_registry.expandGroup
- Expansion back en volumen: MotorV3Orchestrator.expandBackMuscle
- Estado: no completamente unificado (back se trata en mas de una capa).

## Landmarks de volumen
- Tabla SSOT: lib/domain/training_v3/constants/muscle_volume_landmarks_ssot.dart
- Lectura/escritura en perfil: LandmarkEngine + training.extra.muscleLandmarks
- Estado: fuerte + persistido (dualidad intencional, pero con riesgo de desactualizacion)

## Intensidad heavy/medium/light
- Modelo formal: IntensitySplit
- Distribucion por set y aparicion: IntensityDistributionEngine
- Asignacion por ejercicio legacy/alterna: IntensityEngine
- Estado: implementado, no totalmente consolidado en una sola via.

## Rep ranges
- IntensityEngine.getRepRangeForIntensity
- RepStructureEngine y SessionIntensitySetAllocator
- Estado: existe, pero en varias capas.

## Splits
- TrainingSplit + _resolveSplit + SplitConfig
- Estado: existe, con reglas en varias capas.

## Pairing
- AntagonistPairingEngine + InterferenceMatrix + SessionStructureEngine + CycleTemplateBuilder
- Estado: funcional, pero distribuido.

## Orden de ejercicios
- OrderingEngine
- ExerciseOrderingRules
- SessionStructureEngine / CycleTemplateBuilder
- Estado: pseudo-SSOT multiple.

## Slots A/B/C/D
- Materializacion en SessionStructureEngine/CycleTemplateBuilder
- Persistencia derivada via structureMetadata en TrainingSession
- Estado: existe, no formalizado como contrato independiente.

## Catalogo de ejercicios
- Fuente: assets/data/exercises/exercise_catalog_gym.json (190 ejercicios)
- Cache/metadatos: ExerciseCatalogV3
- Dominio tipado: Exercise
- Estado: SSOT fuente fuerte, mapeo de dominio parcial.

## Progresion y deload
- Recordatorio/progreso en provider (recordCompletedSession)
- WeeklyProgressionServiceImpl (carril semanal separado)
- WeeklyDecisionEngine y DeloadTriggerEngine
- Estado: fragmentado.

## Persistencia de snapshots
- freezePlanSnapshot en TrainingCycle
- activePlanId en training.extra
- weeklyDecisionArtifactsV1 en training.extra
- Estado: multipunto, sin versionado formal de schema de snapshot.

# 7. Auditoria de alineacion contra reglas funcionales ya definidas

## 7.1 Pipeline objetivo esperado

1) Interview/Profile Input Resolver
- Estado: existe/parcial
- Archivos: training_interview_tab.dart, training_pipeline_guard.dart
- Problema: captura+persistencia+gating quedan acoplados

2) Volume Target Resolver
- Estado: existe/parcial
- Archivos: landmark_engine.dart, muscle_volume_landmarks_ssot.dart, motor_v3_orchestrator.dart
- Problema: convive con valores persistidos y fallbacks

3) Intensity Distribution Resolver
- Estado: existe/parcial
- Archivos: intensity_split.dart, intensity_distribution_engine.dart, intensity_engine.dart
- Problema: multiples vias y legacy

4) Exercise Candidate Resolver
- Estado: existe
- Archivos: exercise_selection_engine.dart, exercise_catalog_v3.dart
- Problema: fallbacks amplios y rutas legacy en el mismo archivo

5) Exercise Structural Classifier
- Estado: parcial
- Archivos: ordering_engine.dart, exercise_ordering_rules.dart
- Problema: clasificacion dispersa

6) Pairing Resolver
- Estado: parcial
- Archivos: antagonist_pairing_engine.dart, session_structure_engine.dart, interference_matrix.dart
- Problema: sin contrato unico de tipos de pairing

7) Session Slotting Resolver
- Estado: parcial
- Archivos: session_structure_engine.dart, cycle_template_builder.dart, training_session.dart
- Problema: slotting derivado/refinado en distintas capas

8) Final Validator
- Estado: parcial
- Archivos: validators/* + checks en motor/provider
- Problema: no hay validador forense unico que consolide bloqueos

9) Persistencia de snapshots y decisiones
- Estado: existe/parcial
- Archivos: training_plan_provider.dart, training_cycle_repository_impl.dart
- Problema: llaves dispersas y sin schema versionado

## 7.2 Reglas de intensidad

Verificacion:
- heavy/medium/light: si existe
- rango 15-30 / 40-70 / 15-30: si existe (IntensitySplit, IntensityEngine)
- heavy al inicio: implementado en distribucion por prioridad de apariciones
- light al final: implementado en distribucion inversa
- medium al centro: implementado con middleOrder y fallback
- conexion intensidad -> seleccion ejercicio: parcial (CycleTemplateBuilder filtra allowedIntensityZones, con fallback)
- conexion intensidad -> rep range: existe (IntensityEngine + SetPrescription)

Observacion forense:
- Hay coexistencia de asignacion por porcentaje semanal y asignacion por ejercicio legacy; no todo pasa por una sola tuberia.

## 7.3 Reglas de volumen y landmarks

- VME/VOP/VMR: si, via tabla SSOT + engine
- target sets por musculo: si
- indirectos/solapamiento: parcial (depende de stimulusContribution y VopValidator)
- caps diarios: si (builder)
- cobertura semanal: si (validateExerciseCoverage)
- factibilidad: si (_feasibilityErrors)

Observacion forense:
- Hay reglas duras y reglas degradadas; falta declaracion unica de politica de degradacion.

## 7.4 Reglas de orden y acomodo de ejercicios

- Clasificacion formal completa: no cerrada
- Matriz 1-12: existe en OrderingEngine._pdfOrderIndex
- group size / compound-isolation / intensidad: implementado de forma repartida
- Dependencia de heuristicas: alta (scores, metadata opcional, defaults)

## 7.5 Pairing y estructura de sesion

- Singles: si
- Biseries: si
- Triseries: no formal
- Antagonistas: si
- Baja interferencia: si
- Sinergias: parcial
- Pares prohibidos: parcial/implicito
- Slots A/B1/B2/C1/C2/D1/D2: parcial (A/B/C/D claro; subslots derivados)

## 7.6 Catalogo de ejercicios

- Donde vive: assets/data/exercises/exercise_catalog_gym.json
- Campos reales observados (ejemplo inspeccion):
  id,name,primaryMuscles,secondaryMuscles,tertiaryMuscles,stimulusContribution,movementPattern,equipment,category,unilateral,allowedIntensityZones,recommendedRepRanges,recommendedRirRanges,equivalenceGroup,sourceBank,reviewNeeded,reviewReason,muscleSize,loadCategory,role,fatigueScore,stimulusScore,muscleLength,pairingClass
- Metadata que llega al dominio Exercise: parcial
- Metadata que queda fuera del modelo tipado y se consulta en metadata cache: allowedIntensityZones, equivalenceGroup, fatigueScore, role, loadCategory, etc.
- Robustez para seleccion: media (funciona, pero con fallback amplio)
- soporte gif/equipo/musculos/equivalence groups: parcial (depende de capa)

## 7.7 Normalizacion de claves musculares

- SSOT de normalizacion: muscle_registry.dart
- Aliases: si
- Duplicaciones: si (normalizer utilitario + mappers locales)
- Expansiones inconsistentes potenciales: back/shoulders y mappings UI especificos
- Uso de back virtual/real: convive en mas de una capa
- Divergencias UI/catalogo/engine/validators: potenciales por llaves legacy presentes en tests y helpers

## 7.8 Progresion, monitoreo y deload

- Progresion de series: si (motor y servicios semanales)
- Progresion de carga/reps: parcial
- Deload: si (DeloadTriggerEngine + fase en motor)
- Microdeload: si (estado/ciclo en motor)
- Fatiga: si (weeklyFatigue, logs, engines)
- Bitacora: si (WorkoutLogRepository + weeklyVolumeHistory)
- Snapshots: si (freezePlanSnapshot + weeklyDecisionArtifactsV1)
- Desacople progresion vs construccion: parcial, hay mezcla

Hallazgo puntual:
- llave lastPhaseResolutionV1 se lee en screens pero no se identifico escritura activa en codigo inspeccionado.

# 8. Matriz de gaps

Matriz detallada y accionable en:
- docs/audits/training_motor_gap_matrix.md

Areas minimas cubiertas en la matriz:
- SSOT muscular
- intensidad
- orden de ejercicios
- pairing
- catalogo
- slotting
- validacion
- persistencia
- progresion
- cobertura/factibilidad

# 9. Heuristicas debiles detectadas

1) Fallback de intensidad por metadata faltante
- Archivo: lib/domain/training_v3/data/exercise_catalog_v3.dart
- Logica: getAllowedIntensityZones retorna heavy/medium/light true cuando no hay metadata
- Riesgo: se pierde restriccion real por zona

2) Seleccion con fallback global
- Archivo: lib/domain/training_v3/engines/exercise_selection_engine.dart
- Logica: si no encuentra candidatos, usa availableExercises.keys.take(...)
- Riesgo: puede seleccionar ejercicios no adecuados al musculo objetivo

3) Ordenado duplicado
- Archivos: ordering_engine.dart y exercise_ordering_rules.dart
- Logica: dos motores de orden con criterios distintos
- Riesgo: orden no determinista entre rutas

4) Slotting refinado posterior
- Archivo: session_structure_engine.dart
- Logica: refinePlannedExercises rellena metadata faltante
- Riesgo: responsabilidades de estructura quedan repartidas

5) Validacion heterogenea (warning vs bloqueo)
- Archivos: validators/* y motor/provider
- Logica: unas reglas bloquean, otras solo advierten
- Riesgo: planes cientificamente debiles pasan como validos operativos

6) Multiples stores de progresion
- Archivos: training_plan_provider.dart, weekly_progression_service_impl.dart
- Logica: estado semanal en extra + repositorios/analisis
- Riesgo: divergencia de verdad operativa

# 10. Reglas funcionales declaradas fuera del codigo que aun no estan formalizadas

Con base en el repo inspeccionado, faltan como contrato formal unificado (aunque existan piezas parciales):
- Clasificacion estructural unica y fuerte de orden (equivalente estable tipo 1-12 como contrato global, no solo helper local).
- Perfil tipado fuerte de ejercicio que incluya toda metadata operativa del catalogo en dominio (no solo cache dinamico).
- Contrato unico de pairing por tipo (single/biserie/triserie/antagonista/sinergia/prohibido).
- Validador forense final unico pre-persistencia que consolide factibilidad+cobertura+intensidad+estructura.
- Esquema versionado de snapshots de decisiones y freeze plan.
- Politica unica de degradacion/fallback declarada (cuando bloquear vs cuando capear).

# 11. Prioridad recomendada de implementacion

## P0 bloqueante
- Cerrar SSOT unico de normalizacion muscular y eliminar pseudo-SSOTs locales.
- Definir contrato unico de persistencia de decision/snapshot con version.
- Definir politica de validacion final bloqueante (forense) antes de persistir.

## P1 estructural
- Consolidar ordenado/slotting/pairing en un pipeline declarativo unico (sin cambiar UI aun).
- Consolidar intensidad en una sola tuberia materializada (zona -> ejercicio -> set prescription).

## P2 optimizacion
- Tipar metadata completa de catalogo en dominio y reducir lookups dinamicos.
- Reducir fallbacks silenciosos y explicitar degradaciones con trazas.

## P3 endurecimiento/testeo
- Refuerzo de pruebas de integracion sobre pipeline real de provider->motor->persistencia.
- Pruebas de regresion para snapshot schema y restauracion.

# 12. Riesgos de modificar sin cerrar auditoria

- Rehacer catalogo antes del SSOT: rompe normalizacion y mapeo en engines/validators.
- Rehacer ordering antes del clasificador: fija heuristicas actuales como deuda estructural.
- Rehacer pairing antes de separar responsabilidades: duplica aun mas la logica entre builder y session engine.
- Tocar UI antes de cerrar pipeline: acopla pantallas a contratos inestables.
- Meter V4 sin mapa V3: contamina migracion de snapshots/ciclos/activePlanId.

# 13. Estado final de compilacion

- flutter analyze: ejecutado (15-04-2026).
- Resultado: 8 warnings, 0 errores de compilacion; comando retorna codigo 1 por warnings.
- Warnings detectados (preexistentes del repo):
  - lib/domain/services/volume_individualization_service.dart:184 (_classifyHeight no referenciado)
  - lib/domain/services/volume_individualization_service.dart:192 (_classifyWeight no referenciado)
  - lib/features/training_feature/providers/training_plan_provider.dart:561 (dead_code)
  - lib/features/training_feature/providers/training_plan_provider.dart:731 (dead_code)
  - lib/features/training_feature/providers/training_plan_provider.dart:2434 (dead_code)
  - lib/features/training_feature/screens/training_workspace_screen.dart:742 (_buildProgressionTabPlaceholder no referenciado)
  - lib/features/training_feature/screens/training_workspace_screen.dart:1047 (_buildDecisionsTabPlaceholder no referenciado)
  - lib/features/training_feature/screens/training_workspace_screen.dart:2611 (_cerrarSemana no referenciado)
- Errores/warnings introducidos por esta auditoria: ninguno (solo cambios en Markdown).

# 14. Anexos

## Lista de archivos clave
- lib/features/training_feature/providers/training_plan_provider.dart
- lib/features/training_feature/screens/training_workspace_screen.dart
- lib/features/training_feature/domain/training_pipeline_guard.dart
- lib/domain/training_v3/orchestrator/training_orchestrator_v3.dart
- lib/domain/training_v3/services/motor_v3_orchestrator.dart
- lib/domain/training_v3/services/cycle_template_builder.dart
- lib/domain/training_v3/engines/intensity_distribution_engine.dart
- lib/domain/training_v3/engines/intensity_engine.dart
- lib/domain/training_v3/engines/session_structure_engine.dart
- lib/domain/training_v3/engines/antagonist_pairing_engine.dart
- lib/domain/training_v3/data/interference_matrix.dart
- lib/domain/training_v3/engines/ordering_engine.dart
- lib/domain/training_v3/data/exercise_ordering_rules.dart
- lib/domain/training_v3/data/exercise_catalog_v3.dart
- lib/domain/entities/exercise.dart
- lib/core/registry/muscle_registry.dart
- lib/core/utils/muscle_key_normalizer.dart
- lib/domain/training_v3/constants/muscle_volume_landmarks_ssot.dart
- lib/domain/training_v3/engines/landmark_engine.dart
- lib/domain/training/training_cycle.dart
- lib/data/repositories/training/training_cycle_repository_impl.dart
- assets/data/exercises/exercise_catalog_gym.json
- test/domain/training_v3/integration/motor_v3_integration_test.dart
- test/domain/training_v3/validators/validators_test.dart

## Trazas y observaciones relevantes
- La ruta principal de UI llama generatePlanFromActiveCycle en multiples acciones (generar/regenerar/adaptar).
- Existe provider legacy (training_plan_v3_provider.dart) marcado como Deprecated.
- Existen metodos Deprecated en training_plan_provider.dart que siguen presentes.
- En tests inspeccionados hay uso de claves legacy (chest/back/moderate), senal de deuda de consistencia.

## Decisiones no concluyentes
- No se ejecuto correlacion dinamica de runtime (solo auditoria estatica de codigo).
- No se verifico comportamiento de cada fallback con dataset productivo real.

## Dudas abiertas verificables por codigo
- Definir fuente oficial de verdad para progreso semanal (extra vs repositorios semanales).
- Definir si lastPhaseResolutionV1 debe seguir existiendo o eliminarse del consumo UI.
