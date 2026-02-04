// Domain barrel file - exports públicos de domain/
// NO cambiar imports existentes, este archivo es para uso futuro

// Entities
export 'entities/annual_volume_plan.dart';
export 'entities/anthropometry_analysis_result.dart';
export 'entities/anthropometry_record.dart';
export 'entities/appointment.dart';
export 'entities/athlete_longitudinal_state.dart';
export 'entities/biochemistry_record.dart';
export 'entities/block_training_kpis.dart';
export 'entities/client.dart';
export 'entities/client_placeholder.dart';
export 'entities/emi2_profile.dart';
export 'entities/engine_audit.dart';
export 'entities/exercise.dart';
export 'entities/exercise_catalog.dart';
export 'entities/exercise_definition.dart';
export 'entities/exercise_entity.dart';
export 'entities/muscle_volume_profile.dart';
export 'entities/nutrition_adherence_log.dart';
export 'entities/nutrition_history.dart';
export 'entities/nutrition_settings.dart';
export 'entities/pending_task.dart';
export 'entities/psychological_training_profile.dart';
export 'entities/rep_range.dart';
export 'entities/session_summary_log.dart';
export 'entities/smae_food.dart';
export 'entities/split_template.dart';
export 'entities/strength_assessment.dart';
export 'entities/tmb_recommendation.dart';

export 'entities/training_evaluation.dart';
export 'entities/training_feedback.dart';
export 'entities/training_history.dart';

export 'entities/training_profile.dart';

export 'entities/training_session.dart';

// Exceptions
export 'exceptions/training_plan_blocked_exception.dart';

// Models
export 'models/rir_target.dart';
export 'models/weekly_volume_view.dart';

// Policies
export 'policies/day_exercise_ordering_policy.dart';
export 'policies/glute_specialization_policy.dart';

// Services - Core (activos)
export 'services/anthropometry_analyzer.dart';
export 'services/athlete_context_resolver.dart';
export 'services/clinical_restriction_validator.dart';

export 'services/deterministic_session_composer.dart';
export 'services/exercise_selector.dart';
export 'services/failure_policy_service.dart';
export 'services/latest_record_resolver.dart';
export 'services/macrocycle_template_service.dart';
// Phase services removed - migrated to V3
export 'services/record_deletion_service.dart';
export 'services/record_deletion_service_provider.dart';
export 'services/series_adjustment.dart';
export 'services/smae_food_selector.dart';
export 'services/training_adaptation_service.dart';
export 'services/training_feedback_aggregator_service.dart';
export 'services/training_log_aggregator.dart';
export 'services/training_plan_mapper.dart';
// training_program_engine removed - migrated to V3
export 'services/volume_by_muscle_derivation_service.dart';

// Services - V2 (estratégicos/inactivos)
export 'services/v2/longitudinal_state_update_service.dart';
export 'services/v2/training_engine_v2.dart';
export 'services/v2/training_evidence_extractor.dart';

// Training - Core
// training_engine_facade removed - migrated to V3
export 'training/intensity_split_utils.dart';
export 'training/macrocycle_calculator.dart';
export 'training/macrocycle_week.dart';
export 'training/models/muscle_key.dart';
export 'training/models/supported_muscles.dart';
export 'training/services/effective_sets_calculator.dart';
export 'training/services/exercise_contribution_catalog.dart';
export 'training/services/initial_volume_target_service.dart';
export 'training/services/volume_budget_balancer.dart';
export 'training/services/volume_swap_service.dart';

export 'training/training_plan_generator.dart';
export 'training/training_plan_model.dart';
export 'training/vop_snapshot.dart';

// Training Engine - Phases
export 'training_engine/phases/phase4_priority_cap_service.dart';

// ═══════════════════════════════════════════════════════════════════════
// MOTOR V2 LEGACY - ELIMINADO
// ═══════════════════════════════════════════════════════════════════════
// All training_v2 files have been removed and migrated to V3
// See: lib/domain/training_v3/ for the new architecture

// Training V3 - Motor Nuevo
export 'training_v3/services/motor_v3_orchestrator.dart';
export 'training_v3/ml_integration/hybrid_orchestrator_v3.dart';
export 'training_v3/ml_integration/ml_config_v3.dart';
