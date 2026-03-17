import 'package:hcs_app_lap/domain/training_domain/training_evaluation_snapshot_v1.dart';
import 'package:hcs_app_lap/domain/training_domain/training_progression_state_v1.dart';
import 'package:hcs_app_lap/domain/training_domain/training_setup_v1.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// E2 GOBERNANZA CLÍNICA DE PLAN (REGENERAR vs ADAPTAR)
/// ═══════════════════════════════════════════════════════════════════════════
///
/// RESPONSABILIDAD ÚNICA:
/// Decidir si el usuario puede generar, regenerar, adaptar o está bloqueado.
///
/// NO toca Motor V3 (core científico).
/// NO cambia la lógica de entrenamiento.
/// SOLO decide qué acción es legal según el estado clínico.
///
/// PRINCIPIO RECTOR:
/// - Motor V3 genera planes
/// - E2 decide SI PUEDE generar o no
/// - La decisión vive fuera del motor
/// - La decisión se persiste
/// ═══════════════════════════════════════════════════════════════════════════

/// Acción legal determinada por el gobernador
enum TrainingPlanAction {
  /// Generar plan inicial (primera vez, sin historial)
  generate,

  /// Regenerar plan completo (wipe + nuevo plan)
  /// Solo permitido si completedWeeksCount == 0 AND regenerationPolicy == "allow"
  regenerate,

  /// Adaptar plan existente (conservar estructura)
  /// Forzado si completedWeeksCount >= 1 AND regenerationPolicy != "locked"
  adapt,

  /// Plan bloqueado (solo micro-ajustes)
  /// Forzado si weeksToCompetition <= 3 OR peakPhaseWindow == true
  locked,
}

/// Gobernador de decisión clínica de plan
class TrainingPlanGovernor {
  /// Decide qué acción es legal según el estado clínico SSOT
  ///
  /// REGLAS CLÍNICAS DEFINITIVAS (CERRADAS):
  ///
  /// R1 — REGENERAR (wipe + nuevo plan)
  /// Permitido solo si:
  /// - completedWeeksCount == 0
  /// - AND regenerationPolicy == "allow"
  ///
  /// R2 — ADAPTAR (conservar estructura)
  /// Forzado si:
  /// - completedWeeksCount >= 1
  /// - AND completedWeeksCount < 3
  /// - AND regenerationPolicy != "locked"
  ///
  /// R3 — BLOQUEADO (solo micro-ajustes)
  /// Forzado si:
  /// - weeksToCompetition <= 3
  /// - OR peakPhaseWindow == true
  ///
  /// R4 — CASO "7 años / 2 off"
  /// Resuelto automáticamente por snapshot:
  /// - profileArchetype = "returning_detrained"
  /// - rampUpRequired = true
  /// - regenerationPolicy = "allow"
  /// Pero si completedWeeksCount >= rampUpWeeksSuggested:
  /// - regenerationPolicy = "adapt_only"
  static TrainingPlanAction decide({
    required TrainingSetupV1 setup,
    required TrainingEvaluationSnapshotV1 snapshot,
    required TrainingProgressionStateV1 progression,
  }) {
    // ═══════════════════════════════════════════════════════════════════════
    // R3 — BLOQUEADO (mayor prioridad)
    // ═══════════════════════════════════════════════════════════════════════

    // R3.1: Ventana de peak (últimas 3 semanas antes de competencia)
    if (snapshot.peakPhaseWindow) {
      return TrainingPlanAction.locked;
    }

    // R3.2: Competencia próxima (≤ 3 semanas)
    if (snapshot.weeksToCompetition != null &&
        snapshot.weeksToCompetition! <= 3) {
      return TrainingPlanAction.locked;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // R1 — REGENERAR (segunda prioridad)
    // ═══════════════════════════════════════════════════════════════════════

    // R1.1: Sin semanas completadas Y política permite regenerar
    if (progression.weeksCompleted == 0 &&
        snapshot.regenerationPolicy == 'allow') {
      return TrainingPlanAction.regenerate;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // R2 — ADAPTAR (tercera prioridad)
    // ═══════════════════════════════════════════════════════════════════════

    // R2.1: Entre 1 y 2 semanas completadas (ventana de adaptación temprana)
    if (progression.weeksCompleted >= 1 &&
        progression.weeksCompleted < 3 &&
        snapshot.regenerationPolicy != 'locked') {
      return TrainingPlanAction.adapt;
    }

    // R2.2: Política es "adapt_only" (caso de returning_detrained después de rampa)
    if (snapshot.regenerationPolicy == 'adapt_only') {
      return TrainingPlanAction.adapt;
    }

    // R2.3: Más de 3 semanas completadas → siempre adaptar (preserve history)
    if (progression.weeksCompleted >= 3) {
      return TrainingPlanAction.adapt;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // DEFAULT: ADAPTAR
    // ═══════════════════════════════════════════════════════════════════════

    // Si no hay historial de progresión pero tampoco se permite regenerar
    // (situación excepcional), usar adaptación conservadora
    return TrainingPlanAction.adapt;
  }

  /// Obtiene un mensaje clínico explicando la decisión
  static String getDecisionRationale(
    TrainingPlanAction action, {
    required TrainingEvaluationSnapshotV1 snapshot,
    required TrainingProgressionStateV1 progression,
  }) {
    switch (action) {
      case TrainingPlanAction.generate:
        return 'Plan inicial sin historial previo';

      case TrainingPlanAction.regenerate:
        return 'Regeneración permitida: sin semanas completadas (${progression.weeksCompleted} semanas) y política de regeneración activa';

      case TrainingPlanAction.adapt:
        if (progression.weeksCompleted >= 3) {
          return 'Adaptación forzada: ${progression.weeksCompleted} semanas completadas (preservar historial de adaptación)';
        }
        if (snapshot.regenerationPolicy == 'adapt_only') {
          return 'Adaptación forzada: política de solo adaptación activa (${snapshot.profileArchetype ?? 'perfil específico'})';
        }
        return 'Adaptación permitida: ${progression.weeksCompleted} semanas completadas (ventana de ajuste temprano)';

      case TrainingPlanAction.locked:
        if (snapshot.peakPhaseWindow) {
          return 'Plan bloqueado: fase de peak activa (solo micro-ajustes intra-sesión)';
        }
        if (snapshot.weeksToCompetition != null) {
          return 'Plan bloqueado: competencia en ${snapshot.weeksToCompetition} semanas (≤ 3 semanas, solo micro-ajustes)';
        }
        return 'Plan bloqueado: fase crítica de competencia activa';
    }
  }

  /// Verifica si una acción específica está permitida
  static bool isActionAllowed(
    TrainingPlanAction desired, {
    required TrainingSetupV1 setup,
    required TrainingEvaluationSnapshotV1 snapshot,
    required TrainingProgressionStateV1 progression,
  }) {
    final actual = decide(
      setup: setup,
      snapshot: snapshot,
      progression: progression,
    );

    // Locked no permite ninguna acción que modifique el plan
    if (actual == TrainingPlanAction.locked) {
      return desired == TrainingPlanAction.locked;
    }

    // Adapt permite adapt (obvio) pero NO regenerate
    if (actual == TrainingPlanAction.adapt) {
      return desired == TrainingPlanAction.adapt;
    }

    // Regenerate permite regenerate
    if (actual == TrainingPlanAction.regenerate) {
      return desired == TrainingPlanAction.regenerate ||
          desired == TrainingPlanAction.generate;
    }

    return false;
  }
}
