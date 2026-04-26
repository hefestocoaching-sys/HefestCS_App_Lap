# Caso
- nombre del caso: NORMAL TORSO PRIORITY
- objetivo del caso: Validar inicio y prioridad de torso con orden coherente pectoral/espalda.
- tipo: normal

# Input de entrevista
- llaves reales usadas por el motor (payload final):
```json
{
  "caseId": "case_01",
  "asOfDate": "2026-04-17T00:00:00.000",
  "phase": "accumulation",
  "client.id": "case_01",
  "profile.age": 31,
  "profile.gender": "male",
  "training.trainingLevel": "intermediate",
  "training.daysPerWeek": 4,
  "training.timePerSessionMinutes": 90,
  "training.extra": {
    "daysPerWeek": 4,
    "trainingDaysPerWeek": 4,
    "sessionDurationMinutes": 90,
    "sessionDuration": 90,
    "trainingYears": 3.0,
    "heightCm": 176.0,
    "weightKg": 79.0,
    "ageYears": 31,
    "level": "intermediate",
    "goal": "hypertrophy",
    "phase": "accumulation",
    "planDurationInWeeks": 4,
    "priorityMusclesPrimary": "pectorals,lats,upper_back",
    "priorityMusclesSecondary": "delts_lateral,biceps,triceps",
    "priorityMusclesTertiary": "quads,glutes,hamstrings,calves",
    "availableEquipment": [
      "barbell",
      "dumbbell",
      "cable",
      "machine",
      "bench",
      "bodyweight"
    ],
    "injuries": [],
    "avgSleepHours": 7.5,
    "perceivedStress": "medium_low",
    "recoveryQuality": "normal",
    "seriesTypePercentSplit": {
      "heavy": 20,
      "medium": 60,
      "light": 20
    }
  },
  "exercisesProvided": 190
}
```
- mapeo negocio -> campos reales:
  - "Torso" se mapeo a pectorals+lats+upper_back. Deltoide lateral se mapeo a delts_lateral. Pierna completa se expandio a quads/glutes/hamstrings/calves.

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
- blockingErrors: ["Error generando programa: Bad state: [V3][P9][HEAVY_PATTERN_CONFLICT] duplicate heavy compound patterns in session: horizontal_pressx2"]
- warnings: ["[V3][P0.3] Se normalizo volumen en 2 musculos para respetar frecuencia contractual y cap diario."]
- diagnostics relevantes: {}


# Hallazgos del caso
- que salio bien: se detecto bloqueo en pipeline real.
- que salio raro: Error generando programa: Bad state: [V3][P9][HEAVY_PATTERN_CONFLICT] duplicate heavy compound patterns in session: horizontal_pressx2
- si hubo fallback: revisar warnings forenses y logs del motor en ejecucion.
- comportamiento inesperado: sin rechazo forense.


# JSON crudo o payload serializado
```json
{
  "caseId": "case_01",
  "asOfDate": "2026-04-17T00:00:00.000",
  "phase": "accumulation",
  "client.id": "case_01",
  "profile.age": 31,
  "profile.gender": "male",
  "training.trainingLevel": "intermediate",
  "training.daysPerWeek": 4,
  "training.timePerSessionMinutes": 90,
  "training.extra": {
    "daysPerWeek": 4,
    "trainingDaysPerWeek": 4,
    "sessionDurationMinutes": 90,
    "sessionDuration": 90,
    "trainingYears": 3.0,
    "heightCm": 176.0,
    "weightKg": 79.0,
    "ageYears": 31,
    "level": "intermediate",
    "goal": "hypertrophy",
    "phase": "accumulation",
    "planDurationInWeeks": 4,
    "priorityMusclesPrimary": "pectorals,lats,upper_back",
    "priorityMusclesSecondary": "delts_lateral,biceps,triceps",
    "priorityMusclesTertiary": "quads,glutes,hamstrings,calves",
    "availableEquipment": [
      "barbell",
      "dumbbell",
      "cable",
      "machine",
      "bench",
      "bodyweight"
    ],
    "injuries": [],
    "avgSleepHours": 7.5,
    "perceivedStress": "medium_low",
    "recoveryQuality": "normal",
    "seriesTypePercentSplit": {
      "heavy": 20,
      "medium": 60,
      "light": 20
    }
  },
  "exercisesProvided": 190
}
```
