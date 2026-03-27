# 1. PROPOSITO DEL SISTEMA
El sistema de entrenamiento implementado busca generar, mantener y adaptar un plan semanal/ciclo para un cliente, usando una cadena que inicia en UI (workspace), valida estado de entrevista/flujo, construye input fisiologico y de configuracion, ejecuta orquestacion Motor V3, congela estructura en ciclo, persiste plan activo y mantiene metadatos en training.extra.

En runtime real, el objetivo operativo no es solo “generar un plan”, sino sostener tres capas simultaneas:
- capa de plan (client.trainingPlans + activePlanId),
- capa de ciclo (client.trainingCycles + activeCycleId + freezePlanSnapshot),
- capa de metadatos UI/flujo (training.extra: flow stage, split de intensidad, landmarks, snapshots, mapas derivados).

Evidencia principal:
- lib/features/training_feature/screens/training_workspace_screen.dart, clase TrainingWorkspaceScreen, metodo _generarPlan (linea 3065) y botones de accion.
- lib/features/training_feature/providers/training_plan_provider.dart, clase TrainingPlanNotifier, metodos generatePlan (linea 684), generatePlanFromActiveCycle (linea 1414), loadPersistedActivePlanIfAny (linea 463).
- lib/domain/training_v3/orchestrator/training_orchestrator_v3.dart, clase TrainingOrchestratorV3, metodo generatePlan (linea 101).
- lib/domain/training_v3/services/motor_v3_orchestrator.dart, clase MotorV3Orchestrator, metodo generateProgram (linea 121).

# 2. ENTRADA REAL DEL SISTEMA
## 2.1 Entrada desde pantalla y accion de usuario
- Regla esperada:
  - El usuario entra por TrainingScreen/TrainingWorkspaceRoot, y desde TrainingWorkspaceScreen dispara generar/adaptar/regenerar/deload.
- Regla ejecutada:
  - TrainingScreen solo envuelve TrainingWorkspaceRoot.
  - TrainingWorkspaceRoot monta TrainingWorkspaceScreen fullscreen.
  - La accion principal de generacion en esta ruta es _generarPlan(), que llama generatePlanFromActiveCycle(DateTime.now()).
  - Adaptar y regenerar tambien convergen en generatePlanFromActiveCycle, excepto una ruta legacy que llama generatePlanV3.
- Evidencia:
  - lib/features/training_feature/training_screen.dart, clase TrainingScreen, build (linea 5).
  - lib/features/training_feature/screens/training_workspace_root.dart, clase TrainingWorkspaceRoot, build (linea 8).
  - lib/features/training_feature/screens/training_workspace_screen.dart, _generarPlan (linea 3065), llamada a provider (linea 3092), _adaptarPlan (linea 3237+), _regenerarPlan (linea 3138+), ruta legacy con generatePlanV3 (linea 2776).
- Posible desvio:
  - DESVIO DE FLUJO: existen multiples rutas de generacion en el mismo provider (generatePlan, generatePlanFromActiveCycle, generatePlanV3), pero la UI principal usa generatePlanFromActiveCycle.
  - NOMINAL NO OPERATIVA: trainingPlanV3Provider se observa para deloadAlert en UI, pero generateV3 no tiene invocaciones encontradas.

## 2.2 Provider que entra y validaciones previas
- Regla esperada:
  - Antes de pasar al motor se valida entrevista completa, etapa de flujo, split de intensidad y landmarks.
- Regla ejecutada:
  - trainingWorkspaceProvider calcula canGeneratePlan con entrevista valida + flowStage plan + split valido.
  - _generarPlan revisa canGeneratePlan.
  - generatePlanFromActiveCycle vuelve a validar flujo con _validateStructuredFlow.
  - _validateStructuredFlow exige: trainingFlowStage=plan, split valido, landmarks no vacios.
- Evidencia:
  - lib/features/training_feature/providers/training_workspace_provider.dart, trainingWorkspaceProvider (linea 29), canGeneratePlan (linea 52), _resolvePlanOutdatedFlag (linea 60).
  - lib/features/training_feature/screens/training_workspace_screen.dart, _generarPlan (linea 3065-3067).
  - lib/features/training_feature/providers/training_plan_provider.dart, generatePlanFromActiveCycle (linea 1414), _validateStructuredFlow (linea 2189), uso en generatePlan (linea 692 y 778) y generatePlanFromActiveCycle (linea 1467).
- Posible desvio:
  - DESVIO DE FLUJO: el boton “Generar con deload” dispara generatePlanFromActiveCycle directo (sin pasar por _generarPlan), aunque sigue protegido por _validateStructuredFlow dentro del provider.

## 2.3 Datos minimos exigidos
- Regla esperada:
  - Edad, genero, dias, duracion de sesion, landmarks e intensidad validos.
- Regla ejecutada:
  - generatePlan valida campos de perfil y puede bloquear por faltantes.
  - generatePlanFromActiveCycle valida flujo estructurado.
  - TrainingOrchestratorV3 bloquea si no hay edad o genero.
- Evidencia:
  - lib/features/training_feature/providers/training_plan_provider.dart, generatePlan (linea 684+), validaciones de missingFields (lineas 700+), validacion de genero/edad (lineas 812+).
  - lib/domain/training_v3/orchestrator/training_orchestrator_v3.dart, generatePlan (linea 101), bloqueos por edad/genero (lineas 120-140 aprox).
- Posible desvio:
  - DEGRADACION SILENCIOSA: en conversion a UserProfile hay defaults (edad, genero, altura, peso) si faltan ciertos campos; convive con bloqueos previos y puede enmascarar parcialmente faltantes dependiendo de ruta.

# 3. CONSTRUCCION DEL INPUT DEL MOTOR
## 3.1 Que deberia pasar
- Unico input consolidado desde Client + training.extra + snapshots, con llaves canonicamente normalizadas y campos obligatorios validados antes de ejecutar motor.

## 3.2 Que pasa realmente
- El input se arma en capas:
  - Capa 1 (Client): profile/training/top-level lists (trainingPlans, trainingCycles, activeCycleId).
  - Capa 2 (training.extra): flow stage, split intensidad, landmarks, snapshots V1, activePlanId, vopSnapshot, mapas UI.
  - Capa 3 (orquestador): conversion Client -> UserProfile con lectura prioritaria de setupV1/evalV1 y fallback a legacy keys.
- MotorV3Orchestrator recibe:
  - userProfile,
  - phase,
  - durationWeeks,
  - splitId/trainingDays,
  - intensityProfilePercentSplit,
  - muscleLandmarks,
  - client y exercises.

Evidencia:
- lib/domain/training_v3/orchestrator/training_orchestrator_v3.dart:
  - generatePlan (linea 101),
  - _convertClientToUserProfile (linea 223),
  - TrainingSsotV1Service.readSetup/readEvaluation (lineas 152, 234, 235),
  - _readIntensitySplitFromExtra (linea 490).
- lib/domain/training_v3/services/motor_v3_orchestrator.dart:
  - generateProgram (linea 121),
  - _resolveVolumeTargets (linea 2084 aprox),
  - _resolveIntensitySplit (linea 2043),
  - _resolveSplit (linea 1474).
- lib/features/training_feature/providers/training_plan_provider.dart:
  - _validateStructuredFlow (linea 2189),
  - _readIntensitySplitPercent (linea 2716 aprox),
  - VopContext.ensure (lineas 126 y 1996).

## 3.3 Donde puede romper
- Si trainingFlowStage != plan, split invalido o landmarks vacios -> bloquea.
- Si no hay edad/genero en ruta orquestador -> bloquea.
- Si volumen objetivo no es asignable por cap diario/frecuencia -> motor falla por feasibility.

Desvios detectados:
- VIOLACION DE SSOT: coexisten setup/evaluation V1 y llaves legacy espejadas para lo mismo (daysPerWeek, timePerSessionMinutes, planDurationInWeeks, prioridades musculares).
  - Evidencia: lib/domain/training_domain/training_ssot_v1_service.dart, writeSetup/writeEvaluation (espejo legacy).
- DEGRADACION SILENCIOSA: _resolveIntensitySplit normaliza cualquier total a 100 y cae a 20/60/20 si total <= 0.
  - Evidencia: lib/domain/training_v3/services/motor_v3_orchestrator.dart, _resolveIntensitySplit (linea 2043).

# 4. ORDEN REAL DE EJECUCION
Paso 1
- archivo: lib/features/training_feature/training_screen.dart
- clase: TrainingScreen
- metodo: build
- proposito real: entrada minima que enruta a TrainingWorkspaceRoot.
- regla aplicada: delegacion total.
- desvio: no.

Paso 2
- archivo: lib/features/training_feature/screens/training_workspace_root.dart
- clase: TrainingWorkspaceRoot
- metodo: build
- proposito real: contenedor visual independiente para entrenamiento.
- regla aplicada: monta TrainingWorkspaceScreen.
- desvio: no.

Paso 3
- archivo: lib/features/training_feature/screens/training_workspace_screen.dart
- clase: _TrainingWorkspaceScreenState
- metodo: _generarPlan (linea 3065)
- proposito real: gate UI para generar.
- regla aplicada: canGeneratePlan + gobernanza _checkPlanActionAllowed.
- desvio: no en esta ruta.

Paso 4
- archivo: lib/features/training_feature/providers/training_workspace_provider.dart
- clase: Provider<TrainingWorkspaceState>
- metodo: trainingWorkspaceProvider (linea 29)
- proposito real: computar readiness del flujo.
- regla aplicada: entrevista valida + flowStage=plan + split valido.
- desvio: no.

Paso 5
- archivo: lib/features/training_feature/providers/training_plan_provider.dart
- clase: TrainingPlanNotifier
- metodo: generatePlanFromActiveCycle (linea 1414)
- proposito real: pipeline principal runtime de generacion/adaptacion.
- regla aplicada:
  - valida flujo estructurado,
  - intenta freeze-first,
  - bootstrapea ciclo si falta,
  - ejecuta orquestador,
  - valida plan,
  - persiste plan/ciclo,
  - valida VOP,
  - refresca estado.
- desvio:
  - DESVIO DE FLUJO: coexistencia de 3 metodos de generacion (generatePlan, generatePlanFromActiveCycle, generatePlanV3).

Paso 6
- archivo: lib/domain/training_v3/orchestrator/training_orchestrator_v3.dart
- clase: TrainingOrchestratorV3
- metodo: generatePlan (linea 101)
- proposito real: adaptador Client -> UserProfile + invocacion del motor.
- regla aplicada: bloqueos por edad/genero, resolucion de intensidad/split/duracion.
- desvio:
  - VIOLACION DE SSOT: mezcla setup/eval V1 con fallbacks legacy para mismos campos.

Paso 7
- archivo: lib/domain/training_v3/services/motor_v3_orchestrator.dart
- clase: MotorV3Orchestrator
- metodo: generateProgram (linea 121)
- proposito real: coordinacion de reglas de split/volumen/intensidad/coverage y construccion del plan.
- regla aplicada:
  - _resolveSplit,
  - _feasibilityErrors,
  - _buildRealTrainingPlan,
  - _validateExerciseCoverage.
- desvio:
  - DESVIO DE FLUJO: aunque comentarios mencionan SplitGeneratorEngine y ExerciseSelectionEngine, la ruta efectiva usa _resolveSplit + CycleTemplateBuilder.

Paso 8
- archivo: lib/domain/training_v3/services/cycle_template_builder.dart
- clase: CycleTemplateBuilder
- metodo: buildBaseWeek (linea 95)
- proposito real: construir semana base congelada (sesiones, ejercicios, caps).
- regla aplicada:
  - cap por sesion,
  - max ejercicios por musculo/dia,
  - reparto de intensidad semanal por apariciones,
  - validacion de coverage local.
- desvio:
  - DEGRADACION SILENCIOSA: cuando no se asigna todo por caps, se emite warning en lugar de fallo duro en algunas rutas (UNASSIGNED_SETS/UNSATISFIABLE_DAILY_CAP).

Paso 9
- archivo: lib/features/training_feature/providers/training_plan_provider.dart
- clase: TrainingPlanNotifier
- metodo: generatePlanFromActiveCycle (bloque persistencia)
- proposito real: persistir plan y estado activo.
- regla aplicada:
  - guarda TrainingPlanConfig en client.trainingPlans,
  - escribe activePlanId en training.extra,
  - crea/actualiza ciclo en repositorio de ciclos,
  - guarda extras derivados (UI maps, vopSnapshot).
- desvio:
  - VIOLACION DE SSOT: plan activo se puede resolver por activePlanId, por ultimo plan o por freezePlanSnapshot.

Paso 10
- archivo: lib/data/repositories/client_repository.dart
- clase: ClientRepository
- metodo: saveClient (linea 23)
- proposito real: persistencia local-first y push remoto diferido.
- regla aplicada:
  - write local inmediato,
  - debounce remoto 700ms,
  - push remoto best-effort.
- desvio:
  - DEGRADACION SILENCIOSA: si hay permission-denied, se deshabilita sync remoto para la sesion y no revienta el flujo local.

Paso 11
- archivo: lib/data/repositories/training/training_cycle_repository_impl.dart
- clase: TrainingCycleRepositoryImpl
- metodo: createCycle/upsertCycle (lineas 48 y 144)
- proposito real: mantener unicidad de ciclo activo.
- regla aplicada: al crear activo, cierra cualquier ciclo activo previo.
- desvio: no.

Paso 12
- archivo: lib/core/services/sync_service.dart + lib/main.dart
- clase: SyncService
- metodo: start/_processPendingQueue/_syncItem (lineas 13/29/49), llamado en main (linea 66)
- proposito real: job de sync en background cada 5 min.
- regla aplicada: procesa cola local sync_queue.
- desvio:
  - NOMINAL NO OPERATIVA parcial: no se encontraron llamadas a SyncQueueHelper.enqueue, por lo que la cola de training puede no poblarse.

# 5. REGLAS DEL MOTOR, EXPLICADAS EN PALABRAS
## 5.1 Split
- Regla esperada:
  - Seleccion por dias y objetivo usando SplitGeneratorEngine.
- Regla ejecutada:
  - La ruta principal usa MotorV3Orchestrator._resolveSplit (splitId + availableDays), no SplitGeneratorEngine.generateOptimalSplit.
  - Mapeo efectivo:
    - splitId explicito (UL, fullbody, ppl) tiene prioridad,
    - si no: days>=6 -> PPL, days==4 -> UL, resto -> FullBody.
- Evidencia exacta:
  - lib/domain/training_v3/services/motor_v3_orchestrator.dart, _resolveSplit (linea 1474).
  - lib/domain/training_v3/engines/split_generator_engine.dart, generateOptimalSplit (linea 38) sin invocaciones encontradas.
- Desvio detectado:
  - NOMINAL NO OPERATIVA: SplitGeneratorEngine existe, pero no gobierna la ruta principal.
  - DESVIO DE FLUJO: documentacion/comentarios del motor mencionan SplitGeneratorEngine como paso operativo.

## 5.2 Volumen
- Regla esperada:
  - Volumen objetivo por musculo definido de forma consistente y validado contra factibilidad.
- Regla ejecutada:
  - Si hay muscleLandmarks, toma VOP desde ahi; si no, calcula con _calculateVolumeByMuscleV2 (VolumeLandmarksCalculator).
  - Antes de construir plan, corre _feasibilityErrors (hard fail).
  - En week build usa progresion por fase y luego cobertura exacta target vs asignado.
- Evidencia exacta:
  - lib/domain/training_v3/services/motor_v3_orchestrator.dart, _resolveVolumeTargets (linea 2084 aprox), _feasibilityErrors (linea 2363), _validateExerciseCoverage (linea 1692), _buildWeeks (linea 629+).
- Desvio detectado:
  - DESVIO DE FLUJO: parte de la logica de volumen tambien se ajusta luego en provider (VOP snapshot, derivaciones UI), no queda solo en dominio.
  - VIOLACION DE SSOT: volumen vive en varios lugares (plan.volumePerMuscle, cycle.vopByMuscle, training.extra.vopSnapshot, mapas UI).

## 5.3 Frecuencia
- Regla esperada:
  - Frecuencia por musculo coherente con split y sets objetivo.
- Regla ejecutada:
  - El motor deriva frecuencia por musculo con _deriveFrequencyByMuscle + _effectiveFrequencyForSplit.
  - El provider ademas recalcula cycle.frequency via FrequencyInference.inferFromVmr desde training.extra.targetSetsByMuscle.
- Evidencia exacta:
  - lib/domain/training_v3/services/motor_v3_orchestrator.dart, _deriveFrequencyByMuscle / _effectiveFrequencyForSplit (bloque 2340+).
  - lib/features/training_feature/providers/training_plan_provider.dart, generatePlanFromActiveCycle (lineas ~1710-1760, inferFromVmr y persistencia).
- Desvio detectado:
  - VIOLACION DE SSOT: frecuencia se determina en motor y tambien se reescribe desde provider con otra fuente.

## 5.4 Intensidad
- Regla esperada:
  - Distribucion heavy/medium/light aplicada por componente unico en runtime.
- Regla ejecutada:
  - Operativo real: IntensityDistributionEngine (target semanal y por aparicion) usado desde _buildWeeks/CycleTemplateBuilder.
  - Existe IntensitySplitAllocator, pero no se encontraron invocaciones.
- Evidencia exacta:
  - lib/domain/training_v3/services/motor_v3_orchestrator.dart, _buildWeeks (lineas 662-691, buildWeeklyTargets).
  - lib/domain/training_v3/engines/intensity_distribution_engine.dart, splitWeeklySets/distributeAcrossAppearances (lineas 31/80).
  - lib/domain/training_v3/engines/intensity_split_allocator.dart, clase y allocateForSession (linea 21/22) sin usos.
- Desvio detectado:
  - NOMINAL NO OPERATIVA: IntensitySplitAllocator no gobierna runtime actual.
  - DEGRADACION SILENCIOSA: normalizacion de split invalido a 20/60/20 (orquestador/provider) evita fallo duro.

## 5.5 Seleccion de ejercicios
- Regla esperada:
  - Motor de seleccion dedicado (ExerciseSelectionEngine) decide candidatos y fallbacks.
- Regla ejecutada:
  - En la ruta principal, la seleccion efectiva sucede dentro de CycleTemplateBuilder (pool por musculo, locking mesociclo, caps y orden).
  - ExerciseSelectionEngine.selectExercises aparece en _buildSessions de MotorV3Orchestrator, pero _buildSessions no esta invocado por la ruta principal.
- Evidencia exacta:
  - lib/domain/training_v3/services/cycle_template_builder.dart, buildBaseWeek (linea 95) y flujo interno de seleccion.
  - lib/domain/training_v3/services/motor_v3_orchestrator.dart, _buildSessions (linea 1495) con llamada a ExerciseSelectionEngine.selectExercises (linea 1533), sin llamadas a _buildSessions.
  - lib/domain/training_v3/engines/exercise_selection_engine.dart, clase y metodos (linea 43+).
- Desvio detectado:
  - NOMINAL NO OPERATIVA parcial: ExerciseSelectionEngine existe pero no manda en la ruta principal de generacion.
  - DEGRADACION SILENCIOSA: cuando faltan candidatos, el engine tiene fallback a “tomar cualquiera”; en ruta principal hay warnings/caps en builder antes que hard-fail en algunos casos.

## 5.6 Validaciones
- Regla esperada:
  - Validacion previa (input), validacion de construccion (factibilidad), validacion final (cobertura exacta), fallos criticos cuando corresponde.
- Regla ejecutada:
  - Pre-motor: _validateStructuredFlow (flow stage/split/landmarks).
  - En provider: validaciones P0 de weeks/volume/split antes de persistir en generatePlanFromActiveCycle.
  - En motor: _feasibilityErrors + _validateExerciseCoverage.
  - En rutas de fallback: varios warnings sin throw.
- Evidencia exacta:
  - lib/features/training_feature/providers/training_plan_provider.dart, _validateStructuredFlow (linea 2189), validaciones P0 en generatePlanFromActiveCycle (bloque 1860+).
  - lib/domain/training_v3/services/motor_v3_orchestrator.dart, _feasibilityErrors (linea 2363), _validateExerciseCoverage (linea 1692).
- Desvio detectado:
  - DEGRADACION SILENCIOSA: warnings de asignacion/caps sin fallo duro en ciertos puntos del builder/provider.
  - NOMINAL NO OPERATIVA: training_validation_engine.dart no aparece en esta cadena de generacion principal.

# 6. PERSISTENCIA, EXPLICADA EN PALABRAS
- Regla esperada:
  - Persistir plan/ciclo/estado activo con una sola fuente de verdad por concepto.
- Regla ejecutada:
  - Plan:
    - se guarda en client.trainingPlans (TrainingPlanConfig).
    - activePlanId se guarda en client.training.extra.
  - Ciclo:
    - se guarda en client.trainingCycles.
    - activeCycleId se guarda top-level en Client.
    - freezePlanSnapshot queda dentro de cada ciclo.
  - Metadatos:
    - training.extra tambien guarda vopSnapshot, targetSetsByMuscleUi, finalTargetSetsByMuscleUi, generatedPlanRecords, etc.
- Evidencia:
  - lib/features/training_feature/providers/training_plan_provider.dart, persistencia trainingPlans + activePlanId (lineas 1020-1072 y 1950-1977), write VOP snapshot/mapas UI (lineas 1098-1194).
  - lib/data/repositories/training/training_cycle_repository_impl.dart, createCycle/upsertCycle y activeCycleId (lineas 48-87, 144-196).
  - lib/domain/entities/client.dart, campos trainingPlans/trainingCycles/activeCycleId (linea 60 y bloque de serializacion).
- Desvio:
  - VIOLACION DE SSOT: para “estado activo” de plan hay 3 criterios en lectura (activePlanId, latest plan, freeze snapshot).
    - Evidencia: lib/features/training_feature/providers/training_plan_provider.dart, loadPersistedActivePlanIfAny (linea 463) y build/_findActivePlanConfigById (lineas 222+).
  - VIOLACION DE SSOT: para volumen operativo hay duplicacion entre plan, ciclo y extra.

# 7. SYNC Y OFFLINE
- Regla esperada:
  - Local-first: guardar local inmediato y sincronizar remoto sin romper flujo.
- Regla ejecutada:
  - ClientRepository.saveClient guarda local primero y empuja remoto con debounce 700ms.
  - En error remoto (permission-denied), deshabilita sync remoto de la sesion.
  - SyncService corre cada 5 minutos y procesa sync_queue.
- Evidencia:
  - lib/data/repositories/client_repository.dart, saveClient (linea 23), debounce (linea 31), _pushClientRemote (linea 99), disable remoto temporal (linea 121).
  - lib/core/services/sync_service.dart, start/_processPendingQueue (lineas 13/29).
  - lib/main.dart, inicio de SyncService condicionado por FeatureFlags.enableBackgroundSync (lineas 65-66).
- Que sincroniza realmente:
  - Cambios de Client completos (incluye trainingPlans/trainingCycles/training.extra) via _pushClientRemote.
- Que no sincroniza / deshabilitado:
  - No se encontraron usos de SyncQueueHelper.enqueue, por lo que la cola periodica puede no tener items de training.
  - ClinicalRecordsRepository tiene pushTrainingRecord, pero _doPushTrainingRecord esta marcado como unused_element y no se encontraron invocaciones externas.
- Desvio:
  - DEGRADACION SILENCIOSA: falla remota no bloquea local (correcto local-first), pero puede dejar sesion sin sync remoto sin freno visible de alto nivel.
  - NOMINAL NO OPERATIVA: parte de la infraestructura de sync por cola no gobierna el flujo de training observado.

# 8. RESOLUCION DE ESTADO ACTIVO
- Regla esperada:
  - Resolver plan/ciclo activo desde una clave unica estable.
- Regla ejecutada:
  - Plan activo:
    1) busca activePlanId en training.extra,
    2) si no resuelve, cae al plan mas reciente,
    3) si hay ciclo activo con freeze snapshot, puede priorizar snapshot para derivar plan UI.
  - Ciclo activo:
    1) busca por client.activeCycleId,
    2) fallback a primer ciclo con status='active'.
- Evidencia:
  - lib/features/training_feature/providers/training_plan_provider.dart:
    - _findActivePlanConfigById (linea 222),
    - loadPersistedActivePlanIfAny (linea 463),
    - _findActiveCycle (linea 260),
    - build() con fallbacks (lineas 120-170 aprox).
- Desvio:
  - VIOLACION DE SSOT: la resolucion del plan activo no depende de una sola llave.
  - DEGRADACION SILENCIOSA: fallback al plan mas reciente/snapshot cuando activePlanId no encuentra match, sin bloqueo duro.

# 9. DONDE ESTA MAL EL FLUJO
## 9.1 Paso correcto
- UI principal valida readiness (interview + flow stage + intensidad) antes de generar.
- Provider principal valida de nuevo en backend de estado.
- Motor aplica factibilidad y cobertura.
- Persistencia local-first se mantiene robusta.

## 9.2 Paso incorrecto
- Se declara un conjunto de engines/proveedores como si mandaran runtime, pero la ruta real usa otros puntos.
  - SplitGeneratorEngine: no se invoca en la ruta principal.
  - IntensitySplitAllocator: no se invoca.
  - ExerciseSelectionEngine: no lidera la ruta principal (queda en funcion no usada).

## 9.3 Regla mal definida
- Regla de “activo unico” de plan no esta cerrada en una unica fuente de lectura.
  - Se combina activePlanId + latestPlan + freeze snapshot.

## 9.4 Regla bien definida pero mal implementada
- Se promueve SSOT para setup/evaluation V1, pero se espeja a llaves legacy y se sigue leyendo fallback legacy en conversion de input.

## 9.5 Pieza nominal que confunde
- trainingPlanV3Provider y su deloadAlert:
  - se observa en UI,
  - generateV3 no tiene invocaciones encontradas.
- unified_training_provider existe, pero no se observaron consumos en la ruta principal de workspace.
- training_engine_v3_provider existe sin consumo encontrado.
- ClinicalRecordsRepository.pushTrainingRecord existe, pero su ejecucion interna esta marcada como unused.

## 9.6 Pieza de UI/provider haciendo trabajo de dominio
- TrainingPlanNotifier realiza logica de dominio adicional (inferir frecuencia de ciclo, construir VOP snapshot, limpieza de llaves legacy, fallback VOP auto-generado), ademas de orquestar persistencia.
- Esto desplaza reglas de dominio fuera del motor.

# 10. CONCLUSION OPERATIVA
Que hace bien el sistema:
- La cadena principal UI -> provider -> orquestador -> motor -> persistencia funciona y tiene guardrails reales.
- Hay validaciones previas y posteriores relevantes (flujo estructurado, factibilidad, cobertura, checks P0 de plan).
- El modelo local-first protege continuidad incluso con fallos remotos.

Que hace mal el sistema:
- Conviven demasiadas rutas y capas para la misma responsabilidad (generacion, activo, volumen, snapshots).
- Varias piezas declaradas como “motor operativo” no gobiernan la ejecucion principal.
- Parte de las degradaciones son silenciosas (fallbacks y normalizaciones) y dificultan detectar desalineaciones en tiempo real.

Que parte del flujo esta sana:
- Ruta principal con generatePlanFromActiveCycle, freeze de ciclo, persistencia de trainingPlans y control de activeCycle unico.

Que parte del flujo esta rota:
- Coherencia SSOT del estado activo de plan (multi-criterio).
- Coherencia entre “componentes declarados” y “componentes realmente ejecutados” (split/intensidad/seleccion).

Que parte del flujo esta ambigua:
- Frontera dominio vs provider (ajustes de frecuencia/VOP/fallbacks en provider).
- Convivencia V1/legacy/V3 para input del motor.
- Sincronizacion de training por cola periodica frente a push remoto directo por ClientRepository.