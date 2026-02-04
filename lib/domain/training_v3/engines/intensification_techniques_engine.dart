import 'package:hcs_app_lap/domain/training_v3/engines/periodization_engine.dart';

/// Enum que define las técnicas de intensificación disponibles.
///
/// - `none`: Sin técnica de intensificación (por defecto)
/// - `restPause`: Técnica de descanso-pausa (mini-series con descanso corto)
/// - `dropSet`: Series descendentes (reducción de peso progresiva)
/// - `antagonistSuperset`: Superset con ejercicio antagonista
///
/// **Referencia científica:** docs/scientific-foundation/07-intensification-techniques.md
enum IntensificationTechnique { none, restPause, dropSet, antagonistSuperset }

/// Motor científico de técnicas de intensificación para hipertrofia.
///
/// **FUNDAMENTO CIENTÍFICO** (07-intensification-techniques.md):
///
/// **Rest-Pause (Goto et al. 2004):**
/// - Permite extender el tiempo bajo tensión sin incrementar series formales
/// - Genera estrés metabólico significativo con menor fatiga neuromuscular
/// - Ideal para ejercicios de aislamiento con peso moderado
///
/// **Drop Sets (Fink et al. 2018):**
/// - Extienden la serie más allá del fallo mecánico inicial
/// - Maximizan estrés metabólico y reclutamiento de unidades motoras
/// - Muy efectivos en máquinas donde el cambio de peso es rápido y seguro
///
/// **Criterios de aplicación:**
/// - Solo para usuarios intermedios/avanzados
/// - Solo en fase de intensificación (semana 5)
/// - Evitar en ejercicios complejos (squat, deadlift, olímpicos)
class IntensificationTechniquesEngine {
  /// Selecciona la técnica de intensificación más apropiada según contexto.
  ///
  /// **ALGORITMO DE SELECCIÓN** (07-intensification-techniques.md):
  ///
  /// 1. **Filtro de experiencia:** Principiantes → `none`
  ///    - Las técnicas avanzadas requieren dominio técnico previo
  ///
  /// 2. **Filtro de fase:** Solo en `intensification` (semana 5)
  ///    - Las técnicas de intensificación se reservan para el pico del mesociclo
  ///
  /// 3. **Filtro de complejidad:** Ejercicios complejos → `none`
  ///    - Squat, deadlift, olímpicos: riesgo de fallo técnico
  ///
  /// 4. **Máquinas y cables → `dropSet`**
  ///    - Cambio de peso rápido y seguro
  ///    - Menor riesgo de lesión en fatiga extrema
  ///
  /// 5. **Ejercicios de aislamiento → `restPause`**
  ///    - Control técnico más sencillo
  ///    - Efectivo para brazos, hombros, pantorrillas
  ///
  /// 6. **Caso contrario → `none`**
  ///
  /// **Parámetros:**
  /// - `exerciseName`: nombre del ejercicio (usado para detectar tipo)
  /// - `phase`: fase de periodización actual
  /// - `userLevel`: nivel del atleta ('beginner', 'intermediate', 'advanced')
  /// - `equipment`: tipo de equipo (opcional: 'machine', 'cable', 'barbell', 'dumbbell')
  /// - `category`: categoría del ejercicio (opcional: 'compound', 'isolation')
  ///
  /// **Retorna:**
  /// - `IntensificationTechnique` seleccionada
  static IntensificationTechnique selectTechnique({
    required String exerciseName,
    required TrainingPhase phase,
    required String userLevel,
    String? equipment,
    String? category,
  }) {
    // ═══════════════════════════════════════════════════════════════════════
    // CRITERIO 1: Principiantes no usan técnicas avanzadas
    // ═══════════════════════════════════════════════════════════════════════
    if (userLevel == 'beginner') {
      return IntensificationTechnique.none;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // CRITERIO 2: Técnicas solo en fase de intensificación
    // ═══════════════════════════════════════════════════════════════════════
    if (phase != TrainingPhase.intensification) {
      return IntensificationTechnique.none;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // CRITERIO 3: Ejercicios complejos no recomendados
    // ═══════════════════════════════════════════════════════════════════════
    // Riesgo de fallo técnico en fatiga extrema
    final complexExercises = [
      'squat',
      'deadlift',
      'snatch',
      'clean',
      'jerk',
      'olympic',
    ];

    final exerciseNameLower = exerciseName.toLowerCase();
    if (complexExercises.any((e) => exerciseNameLower.contains(e))) {
      return IntensificationTechnique.none;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // CRITERIO 4: Máquinas y cables → Drop set
    // ═══════════════════════════════════════════════════════════════════════
    // Seguro y efectivo: cambio de peso rápido
    if (equipment == 'machine' || equipment == 'cable') {
      return IntensificationTechnique.dropSet;
    }

    // Detectar por nombre si no se proporciona equipment
    if (exerciseNameLower.contains('machine') ||
        exerciseNameLower.contains('cable')) {
      return IntensificationTechnique.dropSet;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // CRITERIO 5: Ejercicios de aislamiento → Rest-pause
    // ═══════════════════════════════════════════════════════════════════════
    if (category == 'isolation') {
      return IntensificationTechnique.restPause;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // CRITERIO 6: Caso contrario → ninguna técnica
    // ═══════════════════════════════════════════════════════════════════════
    return IntensificationTechnique.none;
  }

  /// Aplica la técnica de rest-pause a una serie.
  ///
  /// **PROTOCOLO REST-PAUSE** (Goto et al. 2004):
  ///
  /// 1. **Serie inicial:** Ejecutar hasta RIR 1-2 (cerca del fallo)
  /// 2. **Descanso:** 15 segundos
  /// 3. **Mini-serie 1:** Máximo de reps con el mismo peso
  /// 4. **Descanso:** 15 segundos
  /// 5. **Mini-serie 2:** Máximo de reps con el mismo peso
  ///
  /// **Beneficios científicos:**
  /// - Extiende el tiempo bajo tensión sin incrementar series formales
  /// - Genera estrés metabólico significativo (acumulación de metabolitos)
  /// - Menor fatiga neuromuscular comparado con otras técnicas
  /// - Ideal para hipertrofia con menor riesgo de lesión
  ///
  /// **Parámetros:**
  /// - `targetReps`: número de reps objetivo de la serie inicial
  /// - `weight`: peso usado (opcional, para instrucciones)
  ///
  /// **Retorna:**
  /// - `Map<String, dynamic>` con protocolo completo y instrucciones
  static Map<String, dynamic> applyRestPause({
    required int targetReps,
    double? weight,
  }) {
    final weightStr = weight != null ? '${weight}kg' : 'el mismo peso';

    return {
      'technique': 'rest_pause',
      'protocol': {
        'initial_reps': targetReps,
        'rest_duration_seconds': 15,
        'mini_sets': 2,
        'instructions':
            '''
TÉCNICA REST-PAUSE:

1. Ejecuta $targetReps repeticiones con $weightStr hasta RIR 1-2
   (dejar 1-2 reps en reserva)

2. DESCANSO: 15 segundos exactos

3. MINI-SERIE 1: Ejecuta el máximo de reps posibles con el mismo peso
   (probablemente 3-5 reps)

4. DESCANSO: 15 segundos exactos

5. MINI-SERIE 2: Ejecuta el máximo de reps posibles con el mismo peso
   (probablemente 2-3 reps)

NOTA: El objetivo es extender la serie total más allá del fallo inicial,
maximizando el estrés metabólico sin incrementar el riesgo de lesión.
''',
      },
    };
  }

  /// Aplica la técnica de drop set a una serie.
  ///
  /// **PROTOCOLO DROP SET** (Fink et al. 2018):
  ///
  /// 1. **Serie inicial:** Ejecutar hasta el fallo mecánico (RIR 0)
  /// 2. **Reducción 1:** Reducir peso 25% inmediatamente
  /// 3. **Serie 2:** Ejecutar máximo de reps al fallo
  /// 4. **Reducción 2:** Reducir peso otro 25%
  /// 5. **Serie 3:** Ejecutar máximo de reps al fallo
  ///
  /// **Beneficios científicos:**
  /// - Extiende la serie más allá del fallo mecánico inicial
  /// - Maximiza estrés metabólico (acumulación extrema de lactato)
  /// - Recluta progresivamente más unidades motoras
  /// - Muy efectivo en máquinas (cambio de peso rápido y seguro)
  ///
  /// **Advertencia:**
  /// - Solo aplicar en ejercicios con cambio de peso rápido (máquinas, cables)
  /// - Evitar en ejercicios con barra libre (riesgo de lesión)
  /// - Requiere asistente o sistema de pines/selectores
  ///
  /// **Parámetros:**
  /// - `initialWeight`: peso inicial de la serie
  ///
  /// **Retorna:**
  /// - `Map<String, dynamic>` con protocolo completo y instrucciones
  static Map<String, dynamic> applyDropSet({required double initialWeight}) {
    final weight1 = initialWeight * 0.75; // Reducción 25%
    final weight2 = weight1 * 0.75; // Reducción otro 25%

    return {
      'technique': 'drop_set',
      'protocol': {
        'initial_weight': initialWeight,
        'drops': [
          {
            'weight_reduction': 0.25,
            'target_reps': null, // Al fallo
            'calculated_weight': weight1,
          },
          {
            'weight_reduction': 0.25,
            'target_reps': null, // Al fallo
            'calculated_weight': weight2,
          },
        ],
        'instructions':
            '''
TÉCNICA DROP SET:

1. Ejecuta la serie con ${initialWeight}kg hasta el FALLO TOTAL (RIR 0)
   No dejes reps en reserva

2. INMEDIATAMENTE reduce el peso a ${weight1.toStringAsFixed(1)}kg (-25%)
   Sin descanso

3. Ejecuta el MÁXIMO de reps posibles hasta el fallo
   (probablemente 6-10 reps)

4. INMEDIATAMENTE reduce el peso a ${weight2.toStringAsFixed(1)}kg (-25%)
   Sin descanso

5. Ejecuta el MÁXIMO de reps posibles hasta el fallo
   (probablemente 8-12 reps)

NOTA: Esta técnica genera fatiga extrema. Usa solo en ejercicios
con cambio de peso rápido y seguro (máquinas, cables con pines).
NO usar en ejercicios con barra libre.
''',
      },
    };
  }
}
