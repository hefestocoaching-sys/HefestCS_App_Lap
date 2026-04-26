# 1. RESUMEN EJECUTIVO

- Estado actual real del Bloque 1 hoy: funcional y estable, pero todavia NO canonico contra la entrevista objetivo de Semana 2 (hoja 9 y previas).
- Que ya quedo bien:
	- UI cerrada para historia base, disponibilidad, buckets de recuperacion, lesiones, evaluacion rapida, prioridades musculares y backFocus.
	- Escritura principal en keys canonicas de entrevista (TrainingInterviewKeys) y de entrenamiento (TrainingExtraKeys).
	- Integracion con workspace y flujo V1/V3 sin errores de analyze en archivos del Bloque 1 auditados.
- Que sigue mal:
	- Persisten lecturas/migraciones legacy dentro del tab principal.
	- Factores VME/VMR criticos siguen incompletos en UI y se rellenan con defaults/mapeo parcial.
	- Restricciones por patron/ROM/implemento existen como puente parcial, pero no quedan completamente operativas en el motor V3 activo.
	- Hay mezcla de Bloque 1 con estado de seguimiento (progression/evaluation snapshots) durante guardado de entrevista.
- Severidad:
	- P0: desalineacion de modelo canonico Semana 2, factores VME/VMR faltantes en captura real, restricciones incompletas para motor activo.
	- P1: convivencia legacy prolongada (fallbacks + espejos/formato mixto).
	- P2: deuda de campos ocultos aun vivos en codigo.

# 2. ENTREVISTA ACTUAL REAL

## Secciones actuales reales (UI visible)

1) Perfil de entrenamiento
- Estatura (cm)
- Peso (kg)
- Edad (anos)
- Disciplina

2) Historia de entrenamiento (dato duro)
- Has entrenado fuerza antes
- Total anos entrenados antes
- Pausa larga y meses
- Si entrena actualmente y meses continuos actuales

3) Disponibilidad y capacidad
- Dias reales ultimo mes
- Dias por semana
- Duracion del plan
- Tiempo por sesion (bucket)

4) Tolerancias de entrenamiento
- Descansos tipicos entre series (bucket)

5) Factores de recuperacion
- Sueno (bucket)
- Estres diario (bucket)

6) Lesiones activas
- Regiones activas
- Detalle de hombro (4 checks)

7) Evaluacion rapida (obligatoria)
- strengthLevelClass
- workCapacityScore
- recoveryHistoryScore

8) Prioridades musculares
- backFocus (lats/upper_back)
- Prioridades por tier (primary/secondary/tertiary)

## Campos removidos en Fase 2 (UI)

- usesAnabolics (removido de UI; se envia false desde mapper de tab)
- isCompetitor (removido de UI; se envia false desde mapper de tab)
- competitionCategory / competitionDate (sin captura UI actual)

## Campos que siguen existiendo en codigo pero ya no se muestran

- PRs opcionales: knowsPRs, prSquat, prBench, prDeadlift (cargan/guardan, sin widgets visibles)
- Overrides numericos: trainingYears, sessionDurationMinutes, restBetweenSetsSeconds, avgSleepHours (controladores vivos sin campos visibles en UI)
- movementRestrictions (lista general), restrictedPatterns/restrictedImplements/restrictedRangesOfMotion/preferredPatterns (persisten/inicializan, no entrevista completa visible de estas dimensiones)

# 3. LECTURA Y ESCRITURA ACTUAL

## Que keys lee hoy

### Canonicas
- TrainingInterviewKeys:
	- hasTrainedBefore
	- totalYearsTrainedBefore
	- hadLongPause
	- longestPauseMonths
	- isTrainingNow
	- monthsTrainingNow
- TrainingExtraKeys (principales de Bloque 1):
	- discipline, historicalFrequency, plannedFrequency, daysPerWeek, planDurationInWeeks
	- timePerSessionBucket, restProfile, sleepBucket, stressLevel
	- strengthLevelClass, workCapacityScore, recoveryHistoryScore
	- activeInjuries, movementRestrictionsDetail
	- priorityMusclesPrimary/Secondary/Tertiary, backFocus
	- trainingYears, timePerSessionMinutes, restBetweenSetsSeconds, avgSleepHours
	- ageYears, heightCm, weightKg
	- externalRecoverySupport, programNoveltyClass, externalPhysicalStressLevel
	- nonPhysicalStressLevel2, restQuality2, dietHabitsClass
	- trainingSetupV1, trainingEvaluationSnapshotV1, trainingProgressionStateV1

### Fallback legacy que aun se lee
- TrainingInterviewLegacyKeys:
	- yearsTrainingContinuous
	- avgSleepHours
	- sessionDurationMinutes
	- restBetweenSetsSeconds
	- workCapacity
	- recoveryHistory
	- externalRecovery
	- programNovelty
	- physicalStress
	- dietQuality
	- heightCm
	- weightKg
- Strings legacy directas aun consideradas en algunos parseos:
	- yearsTrainingContinuous, trainingAgeYears, timePerSessionMinutes, sessionDurationMinutes, restBetweenSetsSeconds, avgSleepHours

## Que keys escribe hoy

### Escritura canonica principal
- TrainingInterviewKeys: historia base (6 keys)
- TrainingExtraKeys: buckets, lesiones, prioridades, backFocus, derivados de historia, campos VME/VMR parciales, setup/evaluation/progression V1

### Escritura legacy
- No hay escritura directa a TrainingInterviewLegacyKeys.* en el tab principal.
- Pero NO esta eliminada por completo la capa legacy, porque:
	- Se rellenan keys canonicas con lectura legacy si faltan (migracion en guardado).
	- Se mantiene legacyTrainingLevel.
	- Persisten espejos/formato compat en otros flujos (por ejemplo prioridad muscular CSV en paths de workspace/evaluation).

## Confirmacion solicitada

- "Ya no escribe legacy por completo": NO.
- Resultado real: escritura principal canonica + compatibilidad legacy aun activa por lectura/migracion/espejo.

# 4. ENUMS Y MODELO ACTUAL

## Enums activos en la entrevista actual

- TrainingDiscipline
- TimePerSessionBucket
- RestProfile
- SleepBucket
- StressLevel
- InjuryRegion
- TrainingLevel (derivado por TrainingHistoryDerivationService)
- EffectiveTrainingState (derivado)

## Enums legacy aun vivos

- ProgramNovelty
- InterviewStressLevel
- InterviewRestQuality
- DietQuality

## Enums vivos que ya no deberian seguir en la entrevista (estado actual)

- ProgramNovelty / InterviewStressLevel / InterviewRestQuality / DietQuality estan vivos via fallback/getters legacy, pero la UI actual no los captura directamente como entrevista canonica.

## Modelo de datos actual Bloque 1

- Modelo mixto en 3 capas:
	1) Keys directas en training.extra (canonicas)
	2) Snapshot estructurado V1 (trainingSetupV1, trainingEvaluationSnapshotV1, trainingProgressionStateV1)
	3) Compatibilidad legacy (fallback de lectura + espejos puntuales)

# 5. COMPARACION CONTRA LA ENTREVISTA OBJETIVO (PDF SEMANA 2)

| componente objetivo | ya existe? | esta bien modelado? | que archivo lo implementa hoy? | falta corregir? | prioridad |
| --- | --- | --- | --- | --- | --- |
| experiencia/subpoblacion base | Parcial | Parcial | training_interview_tab.dart, training_history_derivation_service.dart | Si | P0 |
| sexo | Parcial | Parcial (no se captura en UI Bloque 1; se toma de profile/setup) | training_interview_tab.dart, athlete_context_resolver.dart | Si | P1 |
| edad | Si | No (captura UI existe, pero setup V1 la toma de profile.age) | training_interview_tab.dart | Si | P0 |
| altura | Si | Parcial (captura existe; fuente de consumo depende de contexto atletico/antropometria) | training_interview_tab.dart, athlete_context_resolver.dart | Si | P1 |
| peso | Si | Parcial (igual que altura) | training_interview_tab.dart, athlete_context_resolver.dart | Si | P1 |
| fuerza | Si | Si | training_interview_tab.dart, volume_individualization_service.dart | Menor | P2 |
| capacidad de trabajo | Si | Si | training_interview_tab.dart, volume_individualization_service.dart | Menor | P2 |
| recuperacion historica | Si | Si | training_interview_tab.dart, volume_individualization_service.dart | Menor | P2 |
| recuperacion externa | Parcial | No (sin captura UI explicita actual; default/migracion) | training_interview_tab.dart, volume_individualization_service.dart | Si | P0 |
| novedad del programa | Parcial | No (sin captura UI explicita actual; default/migracion) | training_interview_tab.dart, volume_individualization_service.dart | Si | P0 |
| estres fisico | Parcial | No (sin captura directa, depende de default/migracion) | training_interview_tab.dart, volume_individualization_service.dart | Si | P0 |
| estres no fisico | Si | Parcial (deriva de stressLevel) | training_interview_tab.dart, volume_individualization_service.dart | Si | P1 |
| reposo/descanso | Si | Parcial (buckets + derivacion restQuality2) | training_interview_tab.dart, volume_individualization_service.dart | Si | P1 |
| habitos alimenticios | Parcial | No (sin captura UI explicita actual; default/migracion) | training_interview_tab.dart, volume_individualization_service.dart | Si | P0 |
| uso de anabolicos | No (UI) | No (forzado false en mapper de entrevista) | training_interview_tab.dart, training_profile_form_mapper.dart | Si | P0 |
| disponibilidad | Si | Si | training_interview_tab.dart | Menor | P2 |
| restricciones | Parcial | No (detalle hombro y listas puente, pero sin modelo completo por patron/ROM/implemento aplicado en motor V3 activo) | training_interview_tab.dart | Si | P0 |
| prioridades musculares | Si | Si (con observacion de formato mixto en otros flujos) | training_interview_tab.dart, training_profile_form_mapper.dart, training_workspace_screen.dart | Si (normalizacion final) | P1 |
| backFocus | Si | Si | training_interview_tab.dart, motor_v3_orchestrator.dart | Menor | P2 |

# 6. QUE SIGUE MAL EXACTAMENTE

1) Edad inconsistente entre captura de entrevista y trainingSetupV1 persistido.
2) Factores VME/VMR clave no capturados en UI canonica (recuperacion externa, novedad, estres fisico, habitos alimenticios, anabolicos) y cubiertos con defaults/migracion.
3) Restricciones por patron/ROM/implemento no terminan de convertirse en restriccion efectiva del motor V3 activo.
4) Bloque 1 aun depende de fallback legacy en lectura/carga.
5) Capa legacy sigue viva en compatibilidad de entidad, parseos y rutas de workspace.
6) Prioridades musculares quedan en formato mixto (listas en tab, CSV en rutas de workspace/evaluation).
7) Campos ocultos siguen vivos y se guardan/cargan (PRs/overrides), aumentando deuda funcional.
8) Gating de entrevista en workspace valida solo historia base (6 keys), no el set completo requerido por entrevista objetivo.
9) Bloque 1 todavia mezcla entrevista con estado de seguimiento/progresion al guardar.

# 7. QUE FALTA PARA LA FASE 3

1) Cerrar contrato canonico Bloque 1 (Semana 2) con fuente unica, sin fallback legacy como primera via.
2) Corregir coherencia de edad/sexo/antropometria entre UI, setup V1 y resolver de atleta.
3) Incorporar campos UI faltantes para VME/VMR:
- externalRecoverySupport
- programNoveltyClass
- externalPhysicalStressLevel
- dietHabitsClass
- usesAnabolics (si aplica al dominio clinico)
4) Eliminar defaults silenciosos para campos clinicos criticos y reemplazarlos por captura obligatoria o estado parcial bloqueante.
5) Completar modulo de restricciones canonicas (patron/ROM/implemento) y conectarlo a pipeline V3 activo.
6) Unificar prioridades musculares a un solo formato canonico (lista normalizada), retirando CSV de compat.
7) Encapsular legacy en capa de migracion separada y plan de retiro por etapas.
8) Ampliar validator del workspace para validar entrevista completa objetivo, no solo historia base.
9) Separar claramente Bloque 1 (entrevista) de datos de bitacora/progresion en el flujo de guardado.

# 8. RECOMENDACION FINAL

- Falta una Fase 3 del Bloque 1.

Validacion ejecutada:
- flutter analyze lib/features/training_feature/tabs/training_interview_tab.dart lib/features/training_feature/services/training_profile_form_mapper.dart lib/core/constants/training_interview_keys.dart lib/core/constants/training_interview_legacy_keys.dart lib/core/constants/training_extra_keys.dart lib/features/training_feature/domain/training_interview_validator.dart lib/features/training_feature/providers/training_workspace_provider.dart
- Resultado: No issues found.
