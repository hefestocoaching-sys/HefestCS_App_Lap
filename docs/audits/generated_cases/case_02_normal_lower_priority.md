# Caso
- nombre del caso: NORMAL LOWER PRIORITY
- objetivo del caso: Validar arranque y alternancia de prioridad pierna (cuadriceps/gluteo) en 6 dias.
- tipo: normal

# Input de entrevista
- llaves reales usadas por el motor (payload final):
```json
{
  "caseId": "case_02",
  "asOfDate": "2026-04-17T00:00:00.000",
  "phase": "accumulation",
  "client.id": "case_02",
  "profile.age": 29,
  "profile.gender": "female",
  "training.trainingLevel": "intermediate",
  "training.daysPerWeek": 6,
  "training.timePerSessionMinutes": 75,
  "training.extra": {
    "daysPerWeek": 6,
    "trainingDaysPerWeek": 6,
    "sessionDurationMinutes": 75,
    "sessionDuration": 75,
    "trainingYears": 3.5,
    "heightCm": 165.0,
    "weightKg": 62.0,
    "ageYears": 29,
    "level": "intermediate",
    "goal": "hypertrophy",
    "phase": "accumulation",
    "planDurationInWeeks": 4,
    "priorityMusclesPrimary": "quads,glutes",
    "priorityMusclesSecondary": "hamstrings,calves",
    "priorityMusclesTertiary": "pectorals,lats,upper_back,delts_front,delts_lateral,delts_rear,biceps,triceps",
    "availableEquipment": [
      "barbell",
      "dumbbell",
      "cable",
      "machine",
      "bench",
      "bodyweight"
    ],
    "injuries": [],
    "avgSleepHours": 7.0,
    "perceivedStress": "medium",
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
  - "Pierna" se mapeo a quads/glutes/hamstrings/calves. Torso completo se expandio a pectorals+lats+upper_back+delts+biceps+triceps.

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
- split elegido: pushPullLegs
- phase: accumulation
- microcycleLengthInWeeks: 4
- volumePerMuscle: {"pectorals":13,"lats":10,"upper_back":8,"traps":8,"delts_front":9,"delts_lateral":9,"delts_rear":9,"biceps":10,"triceps":10,"quads":14,"hamstrings":10,"glutes":10,"calves":7,"abs":6}
- frecuencia observada (sample): fullBody:f2 | lats:f1 | quads:f2 | back:f1


# Plan generado
## Semana 1 (accumulation)
- Dia/Sesion 1: Day 1
  - slot: - | musculo: fullBody | ejercicio: Press de banca agarre cerrado (press_de_banca_agarre_cerrado) | zona: medium | reps: 8-12 | sets: 6 | pairing: -
  - slot: - | musculo: fullBody | ejercicio: Apertura con mancuernas declinado (apertura_con_mancuernas_declinado) | zona: medium | reps: 8-12 | sets: 7 | pairing: -
  - slot: - | musculo: fullBody | ejercicio: Press militar con barra sentado (press_militar_con_barra_sentado) | zona: heavy | reps: 6-8 | sets: 9 | pairing: -
  - slot: - | musculo: fullBody | ejercicio: Copa a 1 mano (copa_a_single_arm) | zona: light | reps: 15-20 | sets: 4 | pairing: -
- Dia/Sesion 2: Day 2
  - slot: - | musculo: lats | ejercicio: Pajaros con mancuerna (pajaros_con_mancuerna) | zona: medium | reps: 8-12 | sets: 5 | pairing: -
  - slot: - | musculo: lats | ejercicio: Pullover con mancuerna (pullover_con_mancuerna) | zona: medium | reps: 8-12 | sets: 10 | pairing: -
  - slot: - | musculo: lats | ejercicio: Caminata de granjero (caminata_de_granjero) | zona: medium | reps: 8-12 | sets: 8 | pairing: -
  - slot: - | musculo: lats | ejercicio: Jalón al rostro con cuerda en polea alta (jalon_al_rostro_con_cuerda_en_polea_alta) | zona: light | reps: 15-20 | sets: 4 | pairing: -
- Dia/Sesion 3: Day 3
  - slot: - | musculo: quads | ejercicio: Sentadilla sumo con barra (sentadilla_sumo_con_barra) | zona: heavy | reps: 6-8 | sets: 10 | pairing: -
  - slot: - | musculo: quads | ejercicio: Sentadilla (sentadilla) | zona: heavy | reps: 6-8 | sets: 7 | pairing: -
  - slot: - | musculo: quads | ejercicio: Costurera (costurera) | zona: medium | reps: 8-12 | sets: 7 | pairing: -
- Dia/Sesion 4: Day 4
  - slot: - | musculo: fullBody | ejercicio: Press banca plano con barra (press_banca_plano_con_barra) | zona: medium | reps: 8-12 | sets: 3 | pairing: -
  - slot: - | musculo: fullBody | ejercicio: Elevación lateral a 1 mano (elevacion_lateral_a_single_arm) | zona: medium | reps: 8-12 | sets: 9 | pairing: -
  - slot: - | musculo: fullBody | ejercicio: Apertura con mancuernas declinado (apertura_con_mancuernas_declinado) | zona: light | reps: 15-20 | sets: 3 | pairing: -
- Dia/Sesion 5: Day 5
  - slot: - | musculo: back | ejercicio: Remo con barra agarre prono (remo_con_barra_agarre_prono) | zona: heavy | reps: 6-8 | sets: 8 | pairing: -
  - slot: - | musculo: back | ejercicio: Curl de biceps bayesian con mancuerna (curl_de_biceps_bayesian_con_mancuerna) | zona: medium | reps: 8-12 | sets: 10 | pairing: -
- Dia/Sesion 6: Day 6
  - slot: - | musculo: quads | ejercicio: Peso muerto rumado con barra (peso_muerto_rumado_con_barra) | zona: heavy | reps: 6-8 | sets: 10 | pairing: -
  - slot: - | musculo: quads | ejercicio: Sentadilla (sentadilla) | zona: medium | reps: 8-12 | sets: 3 | pairing: -
  - slot: - | musculo: quads | ejercicio: Extensión de pierna (extension_de_pierna) | zona: light | reps: 15-20 | sets: 4 | pairing: -
  - slot: - | musculo: quads | ejercicio: Elevación de rodillas colgado (hanging_knee_raise) | zona: light | reps: 15-20 | sets: 3 | pairing: -
  - slot: - | musculo: quads | ejercicio: Sit up declinado (decline_situp) | zona: light | reps: 15-20 | sets: 3 | pairing: -
## Semana 2 (accumulation)
- Dia/Sesion 1: Day 1
  - slot: - | musculo: fullBody | ejercicio: Press de banca agarre cerrado (press_de_banca_agarre_cerrado) | zona: medium | reps: 8-12 | sets: 6 | pairing: -
  - slot: - | musculo: fullBody | ejercicio: Apertura con mancuernas declinado (apertura_con_mancuernas_declinado) | zona: medium | reps: 8-12 | sets: 8 | pairing: -
  - slot: - | musculo: fullBody | ejercicio: Press militar con barra sentado (press_militar_con_barra_sentado) | zona: heavy | reps: 6-8 | sets: 10 | pairing: -
  - slot: - | musculo: fullBody | ejercicio: Copa a 1 mano (copa_a_single_arm) | zona: light | reps: 15-20 | sets: 4 | pairing: -
- Dia/Sesion 2: Day 2
  - slot: - | musculo: lats | ejercicio: Pajaros con mancuerna (pajaros_con_mancuerna) | zona: medium | reps: 8-12 | sets: 6 | pairing: -
  - slot: - | musculo: lats | ejercicio: Pullover con mancuerna (pullover_con_mancuerna) | zona: medium | reps: 8-12 | sets: 10 | pairing: -
  - slot: - | musculo: lats | ejercicio: Caminata de granjero (caminata_de_granjero) | zona: medium | reps: 8-12 | sets: 9 | pairing: -
  - slot: - | musculo: lats | ejercicio: Jalón al rostro con cuerda en polea alta (jalon_al_rostro_con_cuerda_en_polea_alta) | zona: light | reps: 15-20 | sets: 4 | pairing: -
- Dia/Sesion 3: Day 3
  - slot: - | musculo: quads | ejercicio: Sentadilla sumo con barra (sentadilla_sumo_con_barra) | zona: heavy | reps: 6-8 | sets: 10 | pairing: -
  - slot: - | musculo: quads | ejercicio: Sentadilla (sentadilla) | zona: heavy | reps: 6-8 | sets: 8 | pairing: -
  - slot: - | musculo: quads | ejercicio: Costurera (costurera) | zona: medium | reps: 8-12 | sets: 8 | pairing: -
- Dia/Sesion 4: Day 4
  - slot: - | musculo: fullBody | ejercicio: Press banca plano con barra (press_banca_plano_con_barra) | zona: medium | reps: 8-12 | sets: 4 | pairing: -
  - slot: - | musculo: fullBody | ejercicio: Elevación lateral a 1 mano (elevacion_lateral_a_single_arm) | zona: medium | reps: 8-12 | sets: 10 | pairing: -
  - slot: - | musculo: fullBody | ejercicio: Apertura con mancuernas declinado (apertura_con_mancuernas_declinado) | zona: light | reps: 15-20 | sets: 3 | pairing: -
- Dia/Sesion 5: Day 5
  - slot: - | musculo: back | ejercicio: Remo con barra agarre prono (remo_con_barra_agarre_prono) | zona: heavy | reps: 6-8 | sets: 9 | pairing: -
  - slot: - | musculo: back | ejercicio: Curl de biceps bayesian con mancuerna (curl_de_biceps_bayesian_con_mancuerna) | zona: medium | reps: 8-12 | sets: 10 | pairing: -
- Dia/Sesion 6: Day 6
  - slot: - | musculo: quads | ejercicio: Peso muerto rumado con barra (peso_muerto_rumado_con_barra) | zona: heavy | reps: 6-8 | sets: 10 | pairing: -
  - slot: - | musculo: quads | ejercicio: Sentadilla (sentadilla) | zona: medium | reps: 8-12 | sets: 4 | pairing: -
  - slot: - | musculo: quads | ejercicio: Extensión de pierna (extension_de_pierna) | zona: light | reps: 15-20 | sets: 4 | pairing: -
  - slot: - | musculo: quads | ejercicio: Elevación de rodillas colgado (hanging_knee_raise) | zona: light | reps: 15-20 | sets: 4 | pairing: -
  - slot: - | musculo: quads | ejercicio: Sit up declinado (decline_situp) | zona: light | reps: 15-20 | sets: 3 | pairing: -
## Semana 3 (accumulation)
- Dia/Sesion 1: Day 1
  - slot: - | musculo: fullBody | ejercicio: Press de banca agarre cerrado (press_de_banca_agarre_cerrado) | zona: medium | reps: 8-12 | sets: 6 | pairing: -
  - slot: - | musculo: fullBody | ejercicio: Apertura con mancuernas declinado (apertura_con_mancuernas_declinado) | zona: medium | reps: 8-12 | sets: 9 | pairing: -
  - slot: - | musculo: fullBody | ejercicio: Press militar con barra sentado (press_militar_con_barra_sentado) | zona: heavy | reps: 6-8 | sets: 10 | pairing: -
  - slot: - | musculo: fullBody | ejercicio: Copa a 1 mano (copa_a_single_arm) | zona: light | reps: 15-20 | sets: 4 | pairing: -
- Dia/Sesion 2: Day 2
  - slot: - | musculo: lats | ejercicio: Pajaros con mancuerna (pajaros_con_mancuerna) | zona: medium | reps: 8-12 | sets: 6 | pairing: -
  - slot: - | musculo: lats | ejercicio: Pullover con mancuerna (pullover_con_mancuerna) | zona: medium | reps: 8-12 | sets: 10 | pairing: -
  - slot: - | musculo: lats | ejercicio: Caminata de granjero (caminata_de_granjero) | zona: medium | reps: 8-12 | sets: 10 | pairing: -
  - slot: - | musculo: lats | ejercicio: Jalón al rostro con cuerda en polea alta (jalon_al_rostro_con_cuerda_en_polea_alta) | zona: light | reps: 15-20 | sets: 4 | pairing: -
- Dia/Sesion 3: Day 3
  - slot: - | musculo: quads | ejercicio: Sentadilla sumo con barra (sentadilla_sumo_con_barra) | zona: heavy | reps: 6-8 | sets: 10 | pairing: -
  - slot: - | musculo: quads | ejercicio: Sentadilla (sentadilla) | zona: heavy | reps: 6-8 | sets: 9 | pairing: -
  - slot: - | musculo: quads | ejercicio: Costurera (costurera) | zona: medium | reps: 8-12 | sets: 10 | pairing: -
- Dia/Sesion 4: Day 4
  - slot: - | musculo: fullBody | ejercicio: Press banca plano con barra (press_banca_plano_con_barra) | zona: medium | reps: 8-12 | sets: 4 | pairing: -
  - slot: - | musculo: fullBody | ejercicio: Elevación lateral a 1 mano (elevacion_lateral_a_single_arm) | zona: medium | reps: 8-12 | sets: 10 | pairing: -
  - slot: - | musculo: fullBody | ejercicio: Apertura con mancuernas declinado (apertura_con_mancuernas_declinado) | zona: light | reps: 15-20 | sets: 4 | pairing: -
- Dia/Sesion 5: Day 5
  - slot: - | musculo: back | ejercicio: Remo con barra agarre prono (remo_con_barra_agarre_prono) | zona: heavy | reps: 6-8 | sets: 10 | pairing: -
  - slot: - | musculo: back | ejercicio: Curl de biceps bayesian con mancuerna (curl_de_biceps_bayesian_con_mancuerna) | zona: medium | reps: 8-12 | sets: 10 | pairing: -
- Dia/Sesion 6: Day 6
  - slot: - | musculo: quads | ejercicio: Peso muerto rumado con barra (peso_muerto_rumado_con_barra) | zona: heavy | reps: 6-8 | sets: 10 | pairing: -
  - slot: - | musculo: quads | ejercicio: Sentadilla (sentadilla) | zona: medium | reps: 8-12 | sets: 4 | pairing: -
  - slot: - | musculo: quads | ejercicio: Extensión de pierna (extension_de_pierna) | zona: light | reps: 15-20 | sets: 5 | pairing: -
  - slot: - | musculo: quads | ejercicio: Elevación de rodillas colgado (hanging_knee_raise) | zona: light | reps: 15-20 | sets: 5 | pairing: -
  - slot: - | musculo: quads | ejercicio: Sit up declinado (decline_situp) | zona: light | reps: 15-20 | sets: 4 | pairing: -
## Semana 4 (accumulation)
- Dia/Sesion 1: Day 1
  - slot: - | musculo: fullBody | ejercicio: Press de banca agarre cerrado (press_de_banca_agarre_cerrado) | zona: medium | reps: 8-12 | sets: 6 | pairing: -
  - slot: - | musculo: fullBody | ejercicio: Apertura con mancuernas declinado (apertura_con_mancuernas_declinado) | zona: medium | reps: 8-12 | sets: 9 | pairing: -
  - slot: - | musculo: fullBody | ejercicio: Press militar con barra sentado (press_militar_con_barra_sentado) | zona: heavy | reps: 6-8 | sets: 10 | pairing: -
  - slot: - | musculo: fullBody | ejercicio: Copa a 1 mano (copa_a_single_arm) | zona: light | reps: 15-20 | sets: 4 | pairing: -
- Dia/Sesion 2: Day 2
  - slot: - | musculo: lats | ejercicio: Pajaros con mancuerna (pajaros_con_mancuerna) | zona: medium | reps: 8-12 | sets: 7 | pairing: -
  - slot: - | musculo: lats | ejercicio: Pullover con mancuerna (pullover_con_mancuerna) | zona: medium | reps: 8-12 | sets: 10 | pairing: -
  - slot: - | musculo: lats | ejercicio: Caminata de granjero (caminata_de_granjero) | zona: medium | reps: 8-12 | sets: 10 | pairing: -
  - slot: - | musculo: lats | ejercicio: Jalón al rostro con cuerda en polea alta (jalon_al_rostro_con_cuerda_en_polea_alta) | zona: light | reps: 15-20 | sets: 3 | pairing: -
- Dia/Sesion 3: Day 3
  - slot: - | musculo: quads | ejercicio: Sentadilla sumo con barra (sentadilla_sumo_con_barra) | zona: heavy | reps: 6-8 | sets: 10 | pairing: -
  - slot: - | musculo: quads | ejercicio: Sentadilla (sentadilla) | zona: heavy | reps: 6-8 | sets: 9 | pairing: -
  - slot: - | musculo: quads | ejercicio: Costurera (costurera) | zona: medium | reps: 8-12 | sets: 10 | pairing: -
- Dia/Sesion 4: Day 4
  - slot: - | musculo: fullBody | ejercicio: Press banca plano con barra (press_banca_plano_con_barra) | zona: medium | reps: 8-12 | sets: 5 | pairing: -
  - slot: - | musculo: fullBody | ejercicio: Elevación lateral a 1 mano (elevacion_lateral_a_single_arm) | zona: medium | reps: 8-12 | sets: 10 | pairing: -
  - slot: - | musculo: fullBody | ejercicio: Apertura con mancuernas declinado (apertura_con_mancuernas_declinado) | zona: light | reps: 15-20 | sets: 4 | pairing: -
- Dia/Sesion 5: Day 5
  - slot: - | musculo: back | ejercicio: Remo con barra agarre prono (remo_con_barra_agarre_prono) | zona: heavy | reps: 6-8 | sets: 10 | pairing: -
  - slot: - | musculo: back | ejercicio: Curl de biceps bayesian con mancuerna (curl_de_biceps_bayesian_con_mancuerna) | zona: medium | reps: 8-12 | sets: 10 | pairing: -
- Dia/Sesion 6: Day 6
  - slot: - | musculo: quads | ejercicio: Peso muerto rumado con barra (peso_muerto_rumado_con_barra) | zona: heavy | reps: 6-8 | sets: 10 | pairing: -
  - slot: - | musculo: quads | ejercicio: Sentadilla (sentadilla) | zona: medium | reps: 8-12 | sets: 5 | pairing: -
  - slot: - | musculo: quads | ejercicio: Extensión de pierna (extension_de_pierna) | zona: light | reps: 15-20 | sets: 5 | pairing: -
  - slot: - | musculo: quads | ejercicio: Elevación de rodillas colgado (hanging_knee_raise) | zona: light | reps: 15-20 | sets: 5 | pairing: -
  - slot: - | musculo: quads | ejercicio: Sit up declinado (decline_situp) | zona: light | reps: 15-20 | sets: 4 | pairing: -


# Validacion forense
- isValid: false
- blockingErrors: ["[FORENSIC][BLOCKING][2.10_selector_coherence] week=1 day=1 exercise=press_de_banca_agarre_cerrado  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=1 day=1 exercise=apertura_con_mancuernas_declinado  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=1 day=1 exercise=press_militar_con_barra_sentado  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=1 day=1 exercise=copa_a_single_arm  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=1 day=2 exercise=pajaros_con_mancuerna  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=1 day=2 exercise=pullover_con_mancuerna  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=1 day=2 exercise=caminata_de_granjero  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=1 day=2 exercise=jalon_al_rostro_con_cuerda_en_polea_alta  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=1 day=3 exercise=sentadilla_sumo_con_barra  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=1 day=3 exercise=sentadilla  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=1 day=3 exercise=costurera  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=1 day=4 exercise=press_banca_plano_con_barra  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=1 day=4 exercise=elevacion_lateral_a_single_arm  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=1 day=4 exercise=apertura_con_mancuernas_declinado  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=1 day=5 exercise=remo_con_barra_agarre_prono  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=1 day=5 exercise=curl_de_biceps_bayesian_con_mancuerna  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=1 day=6 exercise=peso_muerto_rumado_con_barra  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=1 day=6 exercise=sentadilla  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=1 day=6 exercise=extension_de_pierna  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=1 day=6 exercise=hanging_knee_raise  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=1 day=6 exercise=decline_situp  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=2 day=1 exercise=press_de_banca_agarre_cerrado  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=2 day=1 exercise=apertura_con_mancuernas_declinado  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=2 day=1 exercise=press_militar_con_barra_sentado  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=2 day=1 exercise=copa_a_single_arm  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=2 day=2 exercise=pajaros_con_mancuerna  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=2 day=2 exercise=pullover_con_mancuerna  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=2 day=2 exercise=caminata_de_granjero  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=2 day=2 exercise=jalon_al_rostro_con_cuerda_en_polea_alta  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=2 day=3 exercise=sentadilla_sumo_con_barra  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=2 day=3 exercise=sentadilla  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=2 day=3 exercise=costurera  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=2 day=4 exercise=press_banca_plano_con_barra  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=2 day=4 exercise=elevacion_lateral_a_single_arm  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=2 day=4 exercise=apertura_con_mancuernas_declinado  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=2 day=5 exercise=remo_con_barra_agarre_prono  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=2 day=5 exercise=curl_de_biceps_bayesian_con_mancuerna  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=2 day=6 exercise=peso_muerto_rumado_con_barra  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=2 day=6 exercise=sentadilla  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=2 day=6 exercise=extension_de_pierna  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=2 day=6 exercise=hanging_knee_raise  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=2 day=6 exercise=decline_situp  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=3 day=1 exercise=press_de_banca_agarre_cerrado  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=3 day=1 exercise=apertura_con_mancuernas_declinado  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=3 day=1 exercise=press_militar_con_barra_sentado  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=3 day=1 exercise=copa_a_single_arm  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=3 day=2 exercise=pajaros_con_mancuerna  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=3 day=2 exercise=pullover_con_mancuerna  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=3 day=2 exercise=caminata_de_granjero  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=3 day=2 exercise=jalon_al_rostro_con_cuerda_en_polea_alta  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=3 day=3 exercise=sentadilla_sumo_con_barra  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=3 day=3 exercise=sentadilla  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=3 day=3 exercise=costurera  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=3 day=4 exercise=press_banca_plano_con_barra  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=3 day=4 exercise=elevacion_lateral_a_single_arm  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=3 day=4 exercise=apertura_con_mancuernas_declinado  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=3 day=5 exercise=remo_con_barra_agarre_prono  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=3 day=5 exercise=curl_de_biceps_bayesian_con_mancuerna  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=3 day=6 exercise=peso_muerto_rumado_con_barra  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=3 day=6 exercise=sentadilla  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=3 day=6 exercise=extension_de_pierna  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=3 day=6 exercise=hanging_knee_raise  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=3 day=6 exercise=decline_situp  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=4 day=1 exercise=press_de_banca_agarre_cerrado  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=4 day=1 exercise=apertura_con_mancuernas_declinado  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=4 day=1 exercise=press_militar_con_barra_sentado  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=4 day=1 exercise=copa_a_single_arm  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=4 day=2 exercise=pajaros_con_mancuerna  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=4 day=2 exercise=pullover_con_mancuerna  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=4 day=2 exercise=caminata_de_granjero  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=4 day=2 exercise=jalon_al_rostro_con_cuerda_en_polea_alta  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=4 day=3 exercise=sentadilla_sumo_con_barra  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=4 day=3 exercise=sentadilla  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=4 day=3 exercise=costurera  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=4 day=4 exercise=press_banca_plano_con_barra  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=4 day=4 exercise=elevacion_lateral_a_single_arm  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=4 day=4 exercise=apertura_con_mancuernas_declinado  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=4 day=5 exercise=remo_con_barra_agarre_prono  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=4 day=5 exercise=curl_de_biceps_bayesian_con_mancuerna  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=4 day=6 exercise=peso_muerto_rumado_con_barra  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=4 day=6 exercise=sentadilla  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=4 day=6 exercise=extension_de_pierna  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=4 day=6 exercise=hanging_knee_raise  Slot o bloque inválido: block= slot=.","[FORENSIC][BLOCKING][2.10_selector_coherence] week=4 day=6 exercise=decline_situp  Slot o bloque inválido: block= slot=."]
- warnings: []
- diagnostics relevantes:
  - totals: {"weeks":4,"sessions":24,"exercises":84,"sets":587}
  - weeklyFrequencyByMuscle: {"1":{"triceps":1,"pectorals":2,"delts_front":1,"delts_rear":1,"lats":1,"traps":1,"glutes":1,"quads":2,"calves":1,"delts_lateral":1,"upper_back":1,"biceps":1,"hamstrings":1,"abs":1},"2":{"triceps":1,"pectorals":2,"delts_front":1,"delts_rear":1,"lats":1,"traps":1,"glutes":1,"quads":2,"calves":1,"delts_lateral":1,"upper_back":1,"biceps":1,"hamstrings":1,"abs":1},"3":{"triceps":1,"pectorals":2,"delts_front":1,"delts_rear":1,"lats":1,"traps":1,"glutes":1,"quads":2,"calves":1,"delts_lateral":1,"upper_back":1,"biceps":1,"hamstrings":1,"abs":1},"4":{"triceps":1,"pectorals":2,"delts_front":1,"delts_rear":1,"lats":1,"traps":1,"glutes":1,"quads":2,"calves":1,"delts_lateral":1,"upper_back":1,"biceps":1,"hamstrings":1,"abs":1}}
  - weeklySetsByMuscle: {"1":{"triceps":10,"pectorals":13,"delts_front":9,"delts_rear":9,"lats":10,"traps":8,"glutes":10,"quads":14,"calves":7,"delts_lateral":9,"upper_back":8,"biceps":10,"hamstrings":10,"abs":6},"2":{"triceps":10,"pectorals":15,"delts_front":10,"delts_rear":10,"lats":10,"traps":9,"glutes":10,"quads":16,"calves":8,"delts_lateral":10,"upper_back":9,"biceps":10,"hamstrings":10,"abs":7},"3":{"triceps":10,"pectorals":17,"delts_front":10,"delts_rear":10,"lats":10,"traps":10,"glutes":10,"quads":18,"calves":10,"delts_lateral":10,"upper_back":10,"biceps":10,"hamstrings":10,"abs":9},"4":{"triceps":10,"pectorals":18,"delts_front":10,"delts_rear":10,"lats":10,"traps":10,"glutes":10,"quads":19,"calves":10,"delts_lateral":10,"upper_back":10,"biceps":10,"hamstrings":10,"abs":9}}


# Hallazgos del caso
- que salio bien: pipeline real ejecuto y devolvio plan.
- que salio raro: sin bloqueo estructural en generacion.
- si hubo fallback: revisar warnings forenses y logs del motor en ejecucion.
- comportamiento inesperado: validacion forense rechazo estructura generada.


# JSON crudo o payload serializado
```json
{
  "caseId": "case_02",
  "asOfDate": "2026-04-17T00:00:00.000",
  "phase": "accumulation",
  "client.id": "case_02",
  "profile.age": 29,
  "profile.gender": "female",
  "training.trainingLevel": "intermediate",
  "training.daysPerWeek": 6,
  "training.timePerSessionMinutes": 75,
  "training.extra": {
    "daysPerWeek": 6,
    "trainingDaysPerWeek": 6,
    "sessionDurationMinutes": 75,
    "sessionDuration": 75,
    "trainingYears": 3.5,
    "heightCm": 165.0,
    "weightKg": 62.0,
    "ageYears": 29,
    "level": "intermediate",
    "goal": "hypertrophy",
    "phase": "accumulation",
    "planDurationInWeeks": 4,
    "priorityMusclesPrimary": "quads,glutes",
    "priorityMusclesSecondary": "hamstrings,calves",
    "priorityMusclesTertiary": "pectorals,lats,upper_back,delts_front,delts_lateral,delts_rear,biceps,triceps",
    "availableEquipment": [
      "barbell",
      "dumbbell",
      "cable",
      "machine",
      "bench",
      "bodyweight"
    ],
    "injuries": [],
    "avgSleepHours": 7.0,
    "perceivedStress": "medium",
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
