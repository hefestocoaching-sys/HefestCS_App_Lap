# Caso
- nombre del caso: RARE LOW RECOVERY CONFLICT
- objetivo del caso: Evaluar conflicto entre 6 dias declarados y baja recuperacion/fatiga externa alta.
- tipo: raro

# Input de entrevista
- llaves reales usadas por el motor (payload final):
```json
{
  "caseId": "case_05",
  "asOfDate": "2026-04-17T00:00:00.000",
  "phase": "accumulation",
  "client.id": "case_05",
  "profile.age": 27,
  "profile.gender": "female",
  "training.trainingLevel": "beginner",
  "training.daysPerWeek": 6,
  "training.timePerSessionMinutes": 60,
  "training.extra": {
    "daysPerWeek": 6,
    "trainingDaysPerWeek": 6,
    "sessionDurationMinutes": 60,
    "sessionDuration": 60,
    "trainingYears": 1.2,
    "heightCm": 163.0,
    "weightKg": 61.0,
    "ageYears": 27,
    "level": "beginner",
    "goal": "hypertrophy",
    "phase": "accumulation",
    "planDurationInWeeks": 4,
    "priorityMusclesPrimary": "glutes",
    "priorityMusclesSecondary": "quads,delts_lateral",
    "priorityMusclesTertiary": "hamstrings,calves,pectorals,lats,upper_back,biceps,triceps",
    "availableEquipment": [
      "dumbbell",
      "barbell",
      "cable",
      "machine",
      "bodyweight"
    ],
    "injuries": [
      "fatigue_limited_tolerance"
    ],
    "avgSleepHours": 5.6,
    "perceivedStress": "high",
    "recoveryQuality": "low",
    "seriesTypePercentSplit": {
      "heavy": 20,
      "medium": 60,
      "light": 20
    }
  },
  "exercisesProvided": 172
}
```
- mapeo negocio -> campos reales:
  - "Principiante-intermedia" se mapeo a beginner para sesgo conservador. Baja recuperacion se represento en extra: avgSleepHours 5.6, perceivedStress high, recoveryQuality low.

# Suposiciones tecnicas minimas
- valores necesarios por contrato del modelo: age, gender, daysPerWeek, sessionDurationMinutes, level, goal, prioridades, equipo.
- fuente: Client.training + Client.training.extra consumido por TrainingOrchestratorV3._convertClientToUserProfile.
- defaults usados del codigo: split/intensity default cuando no se fuerza explicitamente.

# Ruta de ejecucion usada
- metodo exacto invocado: TrainingOrchestratorV3.generatePlan(...)
- cadena real: training_plan_provider.generatePlanFromActiveCycle -> unified service -> training_orchestrator_v3.generatePlan -> motor_v3_orchestrator.generateProgram -> cycle_template_builder -> training_plan_forensic_validator
- archivos relevantes:
  - lib/features/training_feature/providers/training_plan_provider.dart
  - lib/domain/training_v3/services/unified_training_service.dart
  - lib/domain/training_v3/orchestrator/training_orchestrator_v3.dart
  - lib/domain/training_v3/services/motor_v3_orchestrator.dart
  - lib/domain/training_v3/services/cycle_template_builder.dart
  - lib/domain/training_v3/validators/training_plan_forensic_validator.dart

# Resultado del calculo previo
- plan no generado


# Plan generado
- No se genero plan.


# Validacion forense
- isValid: false
- blockingErrors: ["[FORENSIC][BLOCKING][2.1_coverage] week=3 day=2 muscle=biceps  Terciario excede VOP: sets=9 vop=8.. [FORENSIC][BLOCKING][2.1_coverage] week=3 day=3 muscle=biceps  Terciario excede VOP: sets=9 vop=8.. [FORENSIC][BLOCKING][2.1_coverage] week=3 day=4 muscle=biceps  Terciario excede VOP: sets=9 vop=8.. [FORENSIC][BLOCKING][2.1_coverage] week=3 day=4 muscle=triceps  Terciario excede VOP: sets=9 vop=8.. [FORENSIC][BLOCKING][2.1_coverage] week=3 day=5 muscle=biceps  Terciario excede VOP: sets=9 vop=8.. [FORENSIC][BLOCKING][2.1_coverage] week=3 day=5 muscle=triceps  Terciario excede VOP: sets=9 vop=8.. [FORENSIC][BLOCKING][2.1_coverage] week=3 day=5 muscle=upper_back  Secundario excede 75% de VMR: sets=9 cap=8 vmr=11.. [FORENSIC][BLOCKING][2.1_coverage] week=3 day=6 muscle=biceps  Terciario excede VOP: sets=9 vop=8.. [FORENSIC][BLOCKING][2.1_coverage] week=3 day=6 muscle=triceps  Terciario excede VOP: sets=9 vop=8.. [FORENSIC][BLOCKING][2.1_coverage] week=3 day=6 muscle=upper_back  Secundario excede 75% de VMR: sets=9 cap=8 vmr=11.. [FORENSIC][BLOCKING][2.1_coverage] week=4 day=2 muscle=biceps  Terciario excede VOP: sets=9 vop=8.. [FORENSIC][BLOCKING][2.1_coverage] week=4 day=3 muscle=biceps  Terciario excede VOP: sets=9 vop=8.. [FORENSIC][BLOCKING][2.1_coverage] week=4 day=4 muscle=biceps  Terciario excede VOP: sets=9 vop=8.. [FORENSIC][BLOCKING][2.1_coverage] week=4 day=4 muscle=triceps  Terciario excede VOP: sets=9 vop=8.. [FORENSIC][BLOCKING][2.1_coverage] week=4 day=5 muscle=biceps  Terciario excede VOP: sets=9 vop=8.. [FORENSIC][BLOCKING][2.1_coverage] week=4 day=5 muscle=triceps  Terciario excede VOP: sets=9 vop=8.. [FORENSIC][BLOCKING][2.1_coverage] week=4 day=5 muscle=upper_back  Secundario excede 75% de VMR: sets=9 cap=8 vmr=11.. [FORENSIC][BLOCKING][2.1_coverage] week=4 day=6 muscle=biceps  Terciario excede VOP: sets=9 vop=8.. [FORENSIC][BLOCKING][2.1_coverage] week=4 day=6 muscle=triceps  Terciario excede VOP: sets=9 vop=8.. [FORENSIC][BLOCKING][2.1_coverage] week=4 day=6 muscle=upper_back  Secundario excede 75% de VMR: sets=9 cap=8 vmr=11."]
- warnings: ["[V3][P0.3] Se normalizo volumen en 1 musculos para respetar frecuencia contractual y cap diario."]
- diagnostics relevantes: {}


# Hallazgos del caso
- que salio bien: se detecto bloqueo en pipeline real.
- que salio raro: [FORENSIC][BLOCKING][2.1_coverage] week=3 day=2 muscle=biceps  Terciario excede VOP: sets=9 vop=8.. [FORENSIC][BLOCKING][2.1_coverage] week=3 day=3 muscle=biceps  Terciario excede VOP: sets=9 vop=8.. [FORENSIC][BLOCKING][2.1_coverage] week=3 day=4 muscle=biceps  Terciario excede VOP: sets=9 vop=8.. [FORENSIC][BLOCKING][2.1_coverage] week=3 day=4 muscle=triceps  Terciario excede VOP: sets=9 vop=8.. [FORENSIC][BLOCKING][2.1_coverage] week=3 day=5 muscle=biceps  Terciario excede VOP: sets=9 vop=8.. [FORENSIC][BLOCKING][2.1_coverage] week=3 day=5 muscle=triceps  Terciario excede VOP: sets=9 vop=8.. [FORENSIC][BLOCKING][2.1_coverage] week=3 day=5 muscle=upper_back  Secundario excede 75% de VMR: sets=9 cap=8 vmr=11.. [FORENSIC][BLOCKING][2.1_coverage] week=3 day=6 muscle=biceps  Terciario excede VOP: sets=9 vop=8.. [FORENSIC][BLOCKING][2.1_coverage] week=3 day=6 muscle=triceps  Terciario excede VOP: sets=9 vop=8.. [FORENSIC][BLOCKING][2.1_coverage] week=3 day=6 muscle=upper_back  Secundario excede 75% de VMR: sets=9 cap=8 vmr=11.. [FORENSIC][BLOCKING][2.1_coverage] week=4 day=2 muscle=biceps  Terciario excede VOP: sets=9 vop=8.. [FORENSIC][BLOCKING][2.1_coverage] week=4 day=3 muscle=biceps  Terciario excede VOP: sets=9 vop=8.. [FORENSIC][BLOCKING][2.1_coverage] week=4 day=4 muscle=biceps  Terciario excede VOP: sets=9 vop=8.. [FORENSIC][BLOCKING][2.1_coverage] week=4 day=4 muscle=triceps  Terciario excede VOP: sets=9 vop=8.. [FORENSIC][BLOCKING][2.1_coverage] week=4 day=5 muscle=biceps  Terciario excede VOP: sets=9 vop=8.. [FORENSIC][BLOCKING][2.1_coverage] week=4 day=5 muscle=triceps  Terciario excede VOP: sets=9 vop=8.. [FORENSIC][BLOCKING][2.1_coverage] week=4 day=5 muscle=upper_back  Secundario excede 75% de VMR: sets=9 cap=8 vmr=11.. [FORENSIC][BLOCKING][2.1_coverage] week=4 day=6 muscle=biceps  Terciario excede VOP: sets=9 vop=8.. [FORENSIC][BLOCKING][2.1_coverage] week=4 day=6 muscle=triceps  Terciario excede VOP: sets=9 vop=8.. [FORENSIC][BLOCKING][2.1_coverage] week=4 day=6 muscle=upper_back  Secundario excede 75% de VMR: sets=9 cap=8 vmr=11.
- si hubo fallback: revisar warnings forenses y logs del motor en ejecucion.
- comportamiento inesperado: sin rechazo forense.


# JSON crudo o payload serializado
```json
{
  "caseId": "case_05",
  "asOfDate": "2026-04-17T00:00:00.000",
  "phase": "accumulation",
  "client.id": "case_05",
  "profile.age": 27,
  "profile.gender": "female",
  "training.trainingLevel": "beginner",
  "training.daysPerWeek": 6,
  "training.timePerSessionMinutes": 60,
  "training.extra": {
    "daysPerWeek": 6,
    "trainingDaysPerWeek": 6,
    "sessionDurationMinutes": 60,
    "sessionDuration": 60,
    "trainingYears": 1.2,
    "heightCm": 163.0,
    "weightKg": 61.0,
    "ageYears": 27,
    "level": "beginner",
    "goal": "hypertrophy",
    "phase": "accumulation",
    "planDurationInWeeks": 4,
    "priorityMusclesPrimary": "glutes",
    "priorityMusclesSecondary": "quads,delts_lateral",
    "priorityMusclesTertiary": "hamstrings,calves,pectorals,lats,upper_back,biceps,triceps",
    "availableEquipment": [
      "dumbbell",
      "barbell",
      "cable",
      "machine",
      "bodyweight"
    ],
    "injuries": [
      "fatigue_limited_tolerance"
    ],
    "avgSleepHours": 5.6,
    "perceivedStress": "high",
    "recoveryQuality": "low",
    "seriesTypePercentSplit": {
      "heavy": 20,
      "medium": 60,
      "light": 20
    }
  },
  "exercisesProvided": 172
}
```
