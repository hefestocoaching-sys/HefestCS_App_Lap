# Training Motor Contract Impact Matrix - Phase 2

Fecha: 2026-04-17

## Matriz por contrato

| Contrato | Consumidores actuales | Archivos impactados | Pseudo-SSOT afectados | Riesgo | Plan de migracion |
|---|---|---|---|---|---|
| SSOT muscular | TrainingWorkspace, TrainingProfileFormMapper, TrainingProfile, provider/orchestrator V3 | `lib/features/training_feature/screens/training_workspace_screen.dart`, `lib/features/training_feature/services/training_profile_form_mapper.dart`, `lib/core/utils/muscle_key_normalizer.dart` | mapa local `labelToKeyMap`, mapper UI `chest/deltoide_*` | Medio | mantener `muscle_key_normalizer` como adapter hasta limpiar consumidores legacy; no crear nuevas normalizaciones locales |
| Frecuencia por volumen | `FrequencyByVolume`, `CycleTemplateBuilder` | `lib/domain/constants/volume_to_frequency_rule.dart`, `lib/domain/constants/frequency_by_volume.dart`, `lib/domain/training_v3/services/cycle_template_builder.dart` | threshold legacy `<=20/>=21` | Medio | migrar consumidores a `VolumeToFrequencyRule`; retirar constante legacy en fase posterior |
| Intensidad por tamano | politicas y validaciones futuras; sin cambio de engine en esta fase | `lib/domain/policies/muscle_size_intensity_policy.dart` | split global hardcoded en varios puntos (deuda) | Bajo | usar politica en capa de asignacion cuando se habilite refactor de intensidad |
| Inicio de semana | distribucion UL en CycleTemplateBuilder | `lib/domain/policies/week_start_policy.dart`, `lib/domain/training_v3/services/cycle_template_builder.dart` | inicio fijo torso implcito por paridad | Medio | extender a otros splits (PPL/fullbody) cuando se abra refactor de distribucion |
| Inicio de dia | orden diario block-first del builder | `lib/domain/policies/day_start_policy.dart`, `lib/domain/training_v3/services/cycle_template_builder.dart` | logica inline de musculo primario | Bajo | mantener contrato y reutilizar en futuros ordenadores de sesion |
| Pairing | SessionStructureEngine y CycleTemplateBuilder | `lib/domain/policies/pairing_contract.dart`, `lib/domain/training_v3/engines/session_structure_engine.dart`, `lib/domain/training_v3/services/cycle_template_builder.dart` | ausencia de regla formal same_primary prohibido | Medio | consolidar validaciones en pairing engine dedicado en fase de refactor |
| Orden estructural base | OrderingEngine, ExerciseOrderingRules, DayExerciseOrderingPolicy | `lib/domain/policies/structural_exercise_order_contract.dart`, `lib/domain/training_v3/engines/ordering_engine.dart`, `lib/domain/training_v3/data/exercise_ordering_rules.dart`, `lib/domain/policies/day_exercise_ordering_policy.dart` | heuristicas duplicadas de score/orden | Medio | mantener contrato unico y eliminar engine/rules legacy no usados en fase posterior |

## Rutas prohibidas (no tocadas)

- `lib/domain/services/training_program_engine.dart`
- `lib/domain/services/deterministic_session_composer.dart`
- `lib/domain/training_v3/services/phase_1_data_ingestion_service.dart`
- `lib/domain/training_v3/services/phase_2_readiness_evaluation_service.dart`
- `lib/domain/training_v3/services/phase_3_volume_capacity_model_service.dart`
- `lib/domain/training_v3/services/phase_4_split_distribution_service.dart`
- `lib/domain/training_v3/services/phase_5_periodization_service.dart`
- `lib/domain/training_v3/services/phase_6_exercise_selection_service.dart`
- `lib/domain/training_v3/services/phase_7_prescription_service.dart`
- `lib/domain/training_v3/services/phase_8_adaptation_service.dart`

Motivo: fuera de alcance de fase controlada; solo deuda tecnica documentada.
