/// Excepción de dominio que indica que el plan de entrenamiento no puede generarse
/// debido a restricciones clínicas o técnicas válidas.
///
/// Esta excepción NUNCA debe usarse para errores de programación.
/// Solo para situaciones donde el motor no puede generar un plan válido con los
/// parámetros dados.
class TrainingPlanBlockedException implements Exception {
  final String message;
  final String details;
  final String actionableFix;
  final String reason;
  final Map<String, dynamic> context;
  final List<String> suggestions;

  const TrainingPlanBlockedException({
    String? message,
    this.details = '',
    this.actionableFix = '',
    String? reason,
    this.context = const {},
    this.suggestions = const [],
  }) : message = message ?? reason ?? 'Error en la generación del plan',
       reason = reason ?? message ?? 'Error en la generación del plan';

  @override
  String toString() {
    final buffer = StringBuffer('No se puede generar el plan: $reason');
    if (details.isNotEmpty) {
      buffer.write('\nDetalles: $details');
    }
    if (actionableFix.isNotEmpty) {
      buffer.write('\nSolución: $actionableFix');
    }
    if (suggestions.isNotEmpty) {
      buffer.write('\n\nSugerencias:');
      for (final suggestion in suggestions) {
        buffer.write('\n• $suggestion');
      }
    }
    return buffer.toString();
  }

  /// Crea excepción por catálogo insuficiente
  factory TrainingPlanBlockedException.insufficientCatalog({
    required int availableExercises,
    required List<String> equipment,
    required List<String> restrictions,
  }) {
    return TrainingPlanBlockedException(
      reason: 'Catálogo de ejercicios insuficiente',
      context: {
        'availableExercises': availableExercises,
        'equipment': equipment,
        'restrictions': restrictions,
      },
      suggestions: [
        'Ampliar el equipamiento disponible',
        'Reducir las restricciones de movimiento',
        'Verificar que el catálogo de ejercicios esté completo',
      ],
    );
  }

  /// Crea excepción por volumen no distribuible
  factory TrainingPlanBlockedException.unableToDistributeVolume({
    required int daysPerWeek,
    required Map<String, int> requiredVolume,
    required int timePerSession,
  }) {
    return TrainingPlanBlockedException(
      reason:
          'No se puede distribuir el volumen requerido en $daysPerWeek días',
      context: {
        'daysPerWeek': daysPerWeek,
        'requiredVolume': requiredVolume,
        'timePerSession': timePerSession,
      },
      suggestions: [
        'Aumentar días de entrenamiento por semana',
        'Reducir el volumen objetivo por músculo',
        'Aumentar el tiempo disponible por sesión',
      ],
    );
  }

  /// Crea excepción por día con ejercicios insuficientes
  factory TrainingPlanBlockedException.insufficientExercisesPerDay({
    required int week,
    required int day,
    required int count,
    required int minimum,
  }) {
    return TrainingPlanBlockedException(
      reason:
          'El día $day de la semana $week solo tiene $count ejercicios (mínimo: $minimum)',
      context: {'week': week, 'day': day, 'count': count, 'minimum': minimum},
      suggestions: [
        'Ampliar el equipamiento disponible',
        'Reducir las restricciones de movimiento',
        'Verificar que el catálogo contenga suficientes ejercicios para este split',
        'Revisa selección muscular (Phase3) y dayMuscles (Phase4)',
      ],
    );
  }

  /// Crea excepción por datos críticos faltantes
  factory TrainingPlanBlockedException.missingCriticalData({
    required List<String> missingFields,
  }) {
    return TrainingPlanBlockedException(
      reason: 'Faltan datos críticos del perfil de entrenamiento',
      context: {'missingFields': missingFields},
      suggestions: [
        'Complete los siguientes campos: ${missingFields.join(', ')}',
        'Vuelva a la configuración del perfil de entrenamiento',
      ],
    );
  }
}
