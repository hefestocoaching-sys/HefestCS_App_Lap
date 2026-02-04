import 'package:hcs_app_lap/domain/training_v3/engines/periodization_engine.dart';
import 'package:hcs_app_lap/domain/training_v3/models/exercise_set.dart';
import 'package:hcs_app_lap/domain/training_v3/models/intensified_set.dart';

/// Enum que define las técnicas de intensificación disponibles.
///
/// - `none`: Sin técnica de intensificación (por defecto)
/// - `restPause`: Técnica de descanso-pausa (mini-series con descanso corto)
/// - `dropSet`: Series descendentes (reducción de peso progresiva)
/// - `antagonistSuperset`: Superset con ejercicio antagonista
enum IntensificationTechnique { none, restPause, dropSet, antagonistSuperset }

/// Motor científico de técnicas de intensificación.
///
/// Implementa técnicas avanzadas de intensificación basadas en:
/// - Goto et al. (2004) sobre efectividad del rest-pause en hipertrofia
/// - Fink et al. (2018) sobre drop sets y fatiga neuromuscular
///
/// Las técnicas de intensificación permiten exceder el volumen de
/// entrenamiento convencional sin aumentar el número de series.
class IntensificationTechniquesEngine {
  /// Selecciona la técnica de intensificación más apropiada según contexto.
  ///
  /// **Criterios de selección (evaluados en orden):**
  /// 1. Si `userLevel == 'beginner'` → `none` (técnicas avanzadas no recomendadas)
  /// 2. Si `phase != intensification` → `none` (técnicas solo en pico)
  /// 3. Si ejercicio es complejo (squat/deadlift/olympic) → `none` (riesgo técnico)
  /// 4. Si `equipment == 'machine' || equipment == 'cable'` → `dropSet` (seguro)
  /// 5. Resto → `restPause` (versátil y seguro)
  ///
  /// Parámetros:
  /// - `exerciseName`: nombre/ID del ejercicio
  /// - `phase`: fase de periodización actual
  /// - `userLevel`: nivel del atleta ('beginner', 'intermediate', 'advanced')
  ///
  /// Retorna:
  /// - `IntensificationTechnique` seleccionada
  static IntensificationTechnique selectTechnique({
    required String exerciseName,
    required TrainingPhase phase,
    required String userLevel,
  }) {
    // Criterio 1: Principiantes no usan técnicas avanzadas
    if (userLevel == 'beginner') {
      return IntensificationTechnique.none;
    }

    // Criterio 2: Técnicas solo en fase de intensificación
    if (phase != TrainingPhase.intensification) {
      return IntensificationTechnique.none;
    }

    // Criterio 3: Ejercicios complejos no recomendados (riesgo de fallo técnico)
    final complexExercises = [
      'squat',
      'barbell squat',
      'deadlift',
      'snatch',
      'clean',
      'jerk',
    ];
    if (complexExercises.any((e) => exerciseName.toLowerCase().contains(e))) {
      return IntensificationTechnique.none;
    }

    // Criterio 4: Máquinas y cables → Drop set (seguro y efectivo)
    // Nota: Se asume que la información de equipamiento viene en el nombre
    if (exerciseName.toLowerCase().contains('machine') ||
        exerciseName.toLowerCase().contains('cable')) {
      return IntensificationTechnique.dropSet;
    }

    // Criterio 5: Resto → Rest-pause (mancuernas, barra, etc.)
    return IntensificationTechnique.restPause;
  }

  /// Aplica la técnica de rest-pause a una serie.
  ///
  /// **Protocolo rest-pause:**
  /// 1. Ejecutar serie hasta cerca del fallo (RIR = 1-2)
  /// 2. Descansar 15 segundos
  /// 3. Mini-serie 1: máximo de reps con mismo peso
  /// 4. Descansar 15 segundos
  /// 5. Mini-serie 2: máximo de reps con mismo peso
  ///
  /// **Base científica (Goto et al. 2004):**
  /// El rest-pause genera estrés metabólico significativo con menor
  /// riesgo técnico que otras técnicas, ideal para hipertrofia.
  ///
  /// Parámetros:
  /// - `baseSet`: serie base con reps y peso inicial
  ///
  /// Retorna:
  /// - `IntensifiedSet` con protocolo rest-pause configurado
  static IntensifiedSet applyRestPause(ExerciseSet baseSet) {
    return IntensifiedSet(
      baseSet: baseSet,
      technique: IntensificationTechnique.restPause,
      restPauseProtocol: {
        'initialReps': baseSet.reps,
        'restDuration': 15, // segundos
        'miniSets': 2,
      },
      dropSetProtocol: null,
    );
  }

  /// Aplica la técnica de drop set a una serie.
  ///
  /// **Protocolo drop set:**
  /// 1. Ejecutar serie hasta fallo o RIR = 0
  /// 2. Reducir peso inmediatamente en 25%
  /// 3. Ejecutar máximo de reps posibles
  /// 4. Reducir peso nuevamente en 25%
  /// 5. Ejecutar máximo de reps posibles
  ///
  /// **Base científica (Fink et al. 2018):**
  /// Los drop sets extienden la serie más allá del fallo mecánico,
  /// generando estrés metabólico extremo. Muy efectivos para máquinas
  /// donde el cambio de peso es rápido y seguro.
  ///
  /// Parámetros:
  /// - `baseSet`: serie base con peso inicial
  ///
  /// Retorna:
  /// - `IntensifiedSet` con protocolo drop set configurado
  static IntensifiedSet applyDropSet(ExerciseSet baseSet) {
    return IntensifiedSet(
      baseSet: baseSet,
      technique: IntensificationTechnique.dropSet,
      restPauseProtocol: null,
      dropSetProtocol: {
        'initialWeight': baseSet.weight,
        'drops': [
          {'reduction': 0.25}, // Reducción 25%
          {'reduction': 0.25}, // Reducción 25%
        ],
      },
    );
  }

  /// Aplica técnica de superset antagonista.
  ///
  /// **Protocolo superset antagonista:**
  /// 1. Ejercicio 1: serie completa
  /// 2. Sin descanso
  /// 3. Ejercicio 2 (antagonista): serie completa
  ///
  /// Los ejercicios antagonistas (opuestos) son aquellos que trabajan
  /// músculos antagonistas: pecho/espalda, bíceps/tríceps, etc.
  ///
  /// Parámetros:
  /// - `baseSet`: serie base del ejercicio principal
  /// - `antagonistSetConfig`: configuración del set antagonista
  ///
  /// Retorna:
  /// - `IntensifiedSet` con protocolo de superset configurado
  static IntensifiedSet applyAntagonistSuperset(
    ExerciseSet baseSet,
    Map<String, dynamic> antagonistSetConfig,
  ) {
    return IntensifiedSet(
      baseSet: baseSet,
      technique: IntensificationTechnique.antagonistSuperset,
      restPauseProtocol: null,
      dropSetProtocol: null,
      supersetConfig: {
        'antagonistExercise': antagonistSetConfig['exerciseId'],
        'antagonistReps': antagonistSetConfig['reps'],
        'antagonistWeight': antagonistSetConfig['weight'],
        'restBetween': 0, // Sin descanso
      },
    );
  }
}
