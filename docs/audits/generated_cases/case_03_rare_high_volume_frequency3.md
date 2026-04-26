# Caso
- nombre del caso: RARE HIGH VOLUME FREQUENCY3
- objetivo del caso: Probar comportamiento en alto volumen y frecuencia 3 potencial para musculos prioritarios.
- tipo: raro

# Input de entrevista
- llaves reales usadas por el motor (payload final):
```json
{
  "caseId": "case_03",
  "asOfDate": "2026-04-17T00:00:00.000",
  "phase": "intensification",
  "client.id": "case_03",
  "profile.age": 35,
  "profile.gender": "male",
  "training.trainingLevel": "advanced",
  "training.daysPerWeek": 6,
  "training.timePerSessionMinutes": 100,
  "training.extra": {
    "daysPerWeek": 6,
    "trainingDaysPerWeek": 6,
    "sessionDurationMinutes": 100,
    "sessionDuration": 100,
    "trainingYears": 9.0,
    "heightCm": 182.0,
    "weightKg": 86.0,
    "ageYears": 35,
    "level": "advanced",
    "goal": "hypertrophy",
    "phase": "intensification",
    "planDurationInWeeks": 4,
    "priorityMusclesPrimary": "lats,upper_back,pectorals,quads",
    "priorityMusclesSecondary": "glutes,hamstrings,delts_lateral",
    "priorityMusclesTertiary": "biceps,triceps,calves",
    "availableEquipment": [
      "barbell",
      "dumbbell",
      "cable",
      "machine",
      "bench",
      "bodyweight"
    ],
    "injuries": [],
    "avgSleepHours": 8.5,
    "perceivedStress": "low",
    "recoveryQuality": "high",
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
  - Espalda se separo en lats+upper_back para SSOT muscular. Perfil de recuperacion alto se codifico en extra (sleep/stress/recoveryQuality).

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
- warnings: ["[V3][P0.3] Se normalizo volumen en 6 musculos para respetar frecuencia contractual y cap diario."]
- diagnostics relevantes: {}


# Hallazgos del caso
- que salio bien: se detecto bloqueo en pipeline real.
- que salio raro: Error generando programa: Bad state: [V3][P9][HEAVY_PATTERN_CONFLICT] duplicate heavy compound patterns in session: horizontal_pressx2
- si hubo fallback: revisar warnings forenses y logs del motor en ejecucion.
- comportamiento inesperado: sin rechazo forense.


# JSON crudo o payload serializado
```json
{
  "caseId": "case_03",
  "asOfDate": "2026-04-17T00:00:00.000",
  "phase": "intensification",
  "client.id": "case_03",
  "profile.age": 35,
  "profile.gender": "male",
  "training.trainingLevel": "advanced",
  "training.daysPerWeek": 6,
  "training.timePerSessionMinutes": 100,
  "training.extra": {
    "daysPerWeek": 6,
    "trainingDaysPerWeek": 6,
    "sessionDurationMinutes": 100,
    "sessionDuration": 100,
    "trainingYears": 9.0,
    "heightCm": 182.0,
    "weightKg": 86.0,
    "ageYears": 35,
    "level": "advanced",
    "goal": "hypertrophy",
    "phase": "intensification",
    "planDurationInWeeks": 4,
    "priorityMusclesPrimary": "lats,upper_back,pectorals,quads",
    "priorityMusclesSecondary": "glutes,hamstrings,delts_lateral",
    "priorityMusclesTertiary": "biceps,triceps,calves",
    "availableEquipment": [
      "barbell",
      "dumbbell",
      "cable",
      "machine",
      "bench",
      "bodyweight"
    ],
    "injuries": [],
    "avgSleepHours": 8.5,
    "perceivedStress": "low",
    "recoveryQuality": "high",
    "seriesTypePercentSplit": {
      "heavy": 20,
      "medium": 60,
      "light": 20
    }
  },
  "exercisesProvided": 190
}
```
