/// Estado inmutable para el plan de entrenamiento Motor V3
///
/// SSOT único para UI + persistencia:
/// - result: TrainingProgramV3Result (semanas/sesiones/ejercicios)
/// - plan: TrainingPlanConfig (configuración del programa)
/// - error: Mensaje de error si falla generación
/// - isLoading: Estado de carga
///
/// NO contiene ningún modelo legacy (GeneratedPlan, TrainingPlanBuilder, etc.)
library;

import 'package:hcs_app_lap/domain/entities/training_plan_config.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_program_v3_result.dart';

class TrainingPlanV3State {
  /// Indicador de carga (generando plan científico)
  final bool isLoading;

  /// Mensaje de error si falla la generación o persistencia
  final String? error;

  /// Resultado completo del Motor V3 (semanas/sesiones/ejercicios)
  /// SSOT para la UI: contiene plan (TrainingPlanConfig) y metadata
  final TrainingProgramV3Result? result;

  /// Acceso directo al plan de configuración (result?.plan)
  /// Facilita navegación en UI sin null-coalescing excesivo
  /// Contiene: weeks (List&lt;TrainingWeek&gt;) con sesiones y ejercicios
  final TrainingPlanConfig? plan;

  const TrainingPlanV3State({
    this.isLoading = false,
    this.error,
    this.result,
    this.plan,
  });

  /// Estado vacío (inicial)
  static const empty = TrainingPlanV3State();

  /// Verdadero si hay un plan válido para mostrar
  bool get hasValidPlan => result != null && plan != null;

  /// Número total de semanas en el programa
  int get totalWeeks => plan?.weeks.length ?? 0;

  /// Total de sesiones en el programa
  int get totalSessions {
    if (plan == null) return 0;
    int total = 0;
    for (final week in plan!.weeks) {
      total += week.sessions.length;
    }
    return total;
  }

  /// copyWith para facilitar transformaciones de estado
  TrainingPlanV3State copyWith({
    bool? isLoading,
    String? error,
    TrainingProgramV3Result? result,
    TrainingPlanConfig? plan,
  }) {
    return TrainingPlanV3State(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      result: result ?? this.result,
      plan: plan ?? this.plan,
    );
  }

  @override
  String toString() =>
      'TrainingPlanV3State(isLoading: $isLoading, error: $error, weeks: ${plan?.weeks.length}, sessions: $totalSessions)';
}
