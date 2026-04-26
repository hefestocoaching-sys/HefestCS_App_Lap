# Caso
- nombre del caso: RARE EQUIPMENT CONSTRAINTS
- objetivo del caso: Verificar respeto de restricciones de equipo y fallback por equivalence group.
- tipo: raro

# Input de entrevista
- llaves reales usadas por el motor (payload final):
```json
{
  "caseId": "case_04",
  "asOfDate": "2026-04-17T00:00:00.000",
  "phase": "accumulation",
  "client.id": "case_04",
  "profile.age": 32,
  "profile.gender": "male",
  "training.trainingLevel": "intermediate",
  "training.daysPerWeek": 5,
  "training.timePerSessionMinutes": 70,
  "training.extra": {
    "daysPerWeek": 5,
    "trainingDaysPerWeek": 5,
    "sessionDurationMinutes": 70,
    "sessionDuration": 70,
    "trainingYears": 3.0,
    "heightCm": 174.0,
    "weightKg": 78.0,
    "ageYears": 32,
    "level": "intermediate",
    "goal": "hypertrophy",
    "phase": "accumulation",
    "planDurationInWeeks": 4,
    "priorityMusclesPrimary": "pectorals,lats,upper_back",
    "priorityMusclesSecondary": "delts_rear,biceps,triceps",
    "priorityMusclesTertiary": "quads,glutes,hamstrings",
    "availableEquipment": [
      "dumbbell",
      "barbell",
      "bench",
      "cable",
      "pull_up_bar",
      "bodyweight"
    ],
    "injuries": [],
    "avgSleepHours": 6.8,
    "perceivedStress": "medium",
    "recoveryQuality": "normal",
    "seriesTypePercentSplit": {
      "heavy": 20,
      "medium": 60,
      "light": 20
    }
  },
  "exercisesProvided": 140
}
```
- mapeo negocio -> campos reales:
  - Se aplico filtro duro de catalogo por allowedEquipment: mancuernas/barra/banco/poleas equivalen a dumbbell/barbell/bench/cable. Se excluyen maquinas especificas no listadas.

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
- blockingErrors: ["[FORENSIC][BLOCKING][2.1_coverage] week=4 day=5 muscle=quads  Secundario excede 75% de VMR: sets=19 cap=18 vmr=24."]
- warnings: ["[V3][P0.3] Se normalizo volumen en 2 musculos para respetar frecuencia contractual y cap diario.","[FORENSIC][WARNING][2.1_coverage] week=1 day=1 muscle=pectorals  Músculo por debajo de VME: sets=7 vme=8.","[FORENSIC][WARNING][2.7_daily_feasibility] week=1 day=2  Sesion alta en sets: 36 >= 36.","[FORENSIC][WARNING][2.1_coverage] week=1 day=2 muscle=pectorals  Músculo por debajo de VME: sets=7 vme=8.","[FORENSIC][WARNING][2.1_coverage] week=1 day=3 muscle=pectorals  Músculo por debajo de VME: sets=7 vme=8.","[FORENSIC][WARNING][2.1_coverage] week=1 day=3 muscle=quads  Músculo por debajo de VME: sets=7 vme=8.","[FORENSIC][WARNING][2.1_coverage] week=1 day=4 muscle=quads  Músculo por debajo de VME: sets=7 vme=8.","[FORENSIC][WARNING][2.7_daily_feasibility] week=2 day=2  Sesion alta en sets: 38 >= 36.","[FORENSIC][WARNING][2.7_daily_feasibility] week=3 day=2  Sesion alta en sets: 40 >= 36.","[FORENSIC][WARNING][2.7_daily_feasibility] week=4 day=2  Sesion alta en sets: 40 >= 36."]
- diagnostics relevantes: {}


# Hallazgos del caso
- que salio bien: se detecto bloqueo en pipeline real.
- que salio raro: [FORENSIC][BLOCKING][2.1_coverage] week=4 day=5 muscle=quads  Secundario excede 75% de VMR: sets=19 cap=18 vmr=24.
- si hubo fallback: revisar warnings forenses y logs del motor en ejecucion.
- comportamiento inesperado: sin rechazo forense.


# JSON crudo o payload serializado
```json
{
  "caseId": "case_04",
  "asOfDate": "2026-04-17T00:00:00.000",
  "phase": "accumulation",
  "client.id": "case_04",
  "profile.age": 32,
  "profile.gender": "male",
  "training.trainingLevel": "intermediate",
  "training.daysPerWeek": 5,
  "training.timePerSessionMinutes": 70,
  "training.extra": {
    "daysPerWeek": 5,
    "trainingDaysPerWeek": 5,
    "sessionDurationMinutes": 70,
    "sessionDuration": 70,
    "trainingYears": 3.0,
    "heightCm": 174.0,
    "weightKg": 78.0,
    "ageYears": 32,
    "level": "intermediate",
    "goal": "hypertrophy",
    "phase": "accumulation",
    "planDurationInWeeks": 4,
    "priorityMusclesPrimary": "pectorals,lats,upper_back",
    "priorityMusclesSecondary": "delts_rear,biceps,triceps",
    "priorityMusclesTertiary": "quads,glutes,hamstrings",
    "availableEquipment": [
      "dumbbell",
      "barbell",
      "bench",
      "cable",
      "pull_up_bar",
      "bodyweight"
    ],
    "injuries": [],
    "avgSleepHours": 6.8,
    "perceivedStress": "medium",
    "recoveryQuality": "normal",
    "seriesTypePercentSplit": {
      "heavy": 20,
      "medium": 60,
      "light": 20
    }
  },
  "exercisesProvided": 140
}
```
