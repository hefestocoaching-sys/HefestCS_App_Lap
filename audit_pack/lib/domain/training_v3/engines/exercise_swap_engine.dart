// lib/domain/training_v3/engines/exercise_swap_engine.dart

/// Motor de intercambio inteligente de ejercicios
///
/// Cuando un ejercicio no está funcionando, sugiere alternativas:
/// - Mismo músculo objetivo
/// - Mismo tipo (compound/isolation)
/// - Equipamiento disponible
/// - Evita lesiones conocidas
///
/// FUNDAMENTO CIENTÍFICO:
/// - Semana 5: Variación de ejercicios
/// - Variación previene adaptación específica
/// - Mantiene progresión continua
///
/// Versión: 1.0.0
class ExerciseSwapEngine {
  /// Encuentra ejercicios alternativos para swap
  ///
  /// ALGORITMO:
  /// 1. Identificar características del ejercicio actual
  /// 2. Buscar ejercicios con características similares
  /// 3. Filtrar por equipamiento y lesiones
  /// 4. Ordenar por scoring
  /// 5. Retornar top 3-5 alternativas
  ///
  /// PARÁMETROS:
  /// - [currentExerciseId]: Ejercicio a reemplazar
  /// - [exerciseDatabase]: Base de datos completa
  /// - [availableEquipment]: Equipamiento disponible
  /// - [injuryHistory]: Lesiones del usuario
  ///
  /// RETORNA:
  /// - List de IDs de ejercicios alternativos
  static List<Map<String, dynamic>> findAlternatives({
    required String currentExerciseId,
    required Map<String, Map<String, dynamic>> exerciseDatabase,
    required List<String> availableEquipment,
    required Map<String, String> injuryHistory,
  }) {
    final currentExercise = exerciseDatabase[currentExerciseId];
    if (currentExercise == null) {
      throw ArgumentError('Ejercicio no encontrado: $currentExerciseId');
    }

    // PASO 1: Extraer características
    final targetMuscles =
        (currentExercise['primary_muscles'] as List?)?.cast<String>() ?? [];
    final exerciseType = currentExercise['type'] as String?;

    // PASO 2: Buscar candidatos
    final candidates = exerciseDatabase.entries
        .where((e) => e.key != currentExerciseId) // Excluir actual
        .where((e) => _hasSameMuscles(e.value, targetMuscles)) // Mismo músculo
        .where((e) => e.value['type'] == exerciseType) // Mismo tipo
        .where(
          (e) => _hasEquipment(e.value, availableEquipment),
        ) // Equipamiento
        .where((e) => !_isContraindicated(e.value, injuryHistory)) // Seguro
        .toList();

    // PASO 3: Scoring
    final scored = candidates.map((e) {
      final score = _calculateSimilarityScore(currentExercise, e.value);
      return {
        'exercise_id': e.key,
        'exercise_name': e.value['name'],
        'similarity_score': score,
        'data': e.value,
      };
    }).toList();

    // PASO 4: Ordenar por score
    scored.sort(
      (a, b) => (b['similarity_score'] as double).compareTo(
        a['similarity_score'] as double,
      ),
    );

    // PASO 5: Retornar top 5
    return scored.take(5).toList();
  }

  /// Calcula score de similitud entre ejercicios (0.0-1.0)
  ///
  /// CRITERIOS:
  /// - Músculos primarios (40%)
  /// - Músculos secundarios (20%)
  /// - Patrón de movimiento (20%)
  /// - Curva de resistencia (10%)
  /// - ROM (10%)
  static double _calculateSimilarityScore(
    Map<String, dynamic> original,
    Map<String, dynamic> candidate,
  ) {
    double score = 0.0;

    // Criterio 1: Músculos primarios (40%)
    final origPrimary =
        (original['primary_muscles'] as List?)?.cast<String>() ?? [];
    final candPrimary =
        (candidate['primary_muscles'] as List?)?.cast<String>() ?? [];
    final primaryOverlap =
        origPrimary.where((m) => candPrimary.contains(m)).length /
        origPrimary.length;
    score += primaryOverlap * 0.4;

    // Criterio 2: Músculos secundarios (20%)
    final origSecondary =
        (original['secondary_muscles'] as List?)?.cast<String>() ?? [];
    final candSecondary =
        (candidate['secondary_muscles'] as List?)?.cast<String>() ?? [];
    if (origSecondary.isNotEmpty) {
      final secondaryOverlap =
          origSecondary.where((m) => candSecondary.contains(m)).length /
          origSecondary.length;
      score += secondaryOverlap * 0.2;
    } else {
      score += 0.2; // Si no hay secundarios, dar crédito completo
    }

    // Criterio 3: Patrón de movimiento (20%)
    final origPattern = original['movement_pattern'] as String?;
    final candPattern = candidate['movement_pattern'] as String?;
    if (origPattern == candPattern) {
      score += 0.2;
    }

    // Criterio 4: Curva de resistencia (10%)
    final origCurve = (original['resistance_curve'] as num?)?.toDouble() ?? 5.0;
    final candCurve =
        (candidate['resistance_curve'] as num?)?.toDouble() ?? 5.0;
    final curveSimilarity = 1 - ((origCurve - candCurve).abs() / 10);
    score += curveSimilarity * 0.1;

    // Criterio 5: ROM (10%)
    final origRom = (original['rom'] as num?)?.toDouble() ?? 5.0;
    final candRom = (candidate['rom'] as num?)?.toDouble() ?? 5.0;
    final romSimilarity = 1 - ((origRom - candRom).abs() / 10);
    score += romSimilarity * 0.1;

    return score.clamp(0.0, 1.0);
  }

  /// Genera recomendación de swap con reasoning
  static Map<String, dynamic> generateSwapRecommendation({
    required String currentExerciseId,
    required String currentExerciseName,
    required List<Map<String, dynamic>> alternatives,
    required String swapReason,
  }) {
    if (alternatives.isEmpty) {
      return {
        'can_swap': false,
        'reason': 'No se encontraron alternativas válidas',
      };
    }

    final topAlternative = alternatives.first;

    return {
      'can_swap': true,
      'current_exercise': {
        'id': currentExerciseId,
        'name': currentExerciseName,
      },
      'recommended_swap': {
        'id': topAlternative['exercise_id'],
        'name': topAlternative['exercise_name'],
        'similarity_score': topAlternative['similarity_score'],
      },
      'other_alternatives': alternatives
          .skip(1)
          .take(3)
          .map(
            (a) => {
              'id': a['exercise_id'],
              'name': a['exercise_name'],
              'similarity_score': a['similarity_score'],
            },
          )
          .toList(),
      'swap_reason': swapReason,
      'implementation':
          'Realizar swap en próxima sesión del mismo grupo muscular',
    };
  }

  static bool _hasSameMuscles(
    Map<String, dynamic> exercise,
    List<String> targetMuscles,
  ) {
    final muscles =
        (exercise['primary_muscles'] as List?)?.cast<String>() ?? [];
    return muscles.any((m) => targetMuscles.contains(m));
  }

  static bool _hasEquipment(
    Map<String, dynamic> exercise,
    List<String> available,
  ) {
    final required = (exercise['equipment'] as List?)?.cast<String>() ?? [];
    return required.every((eq) => available.contains(eq));
  }

  static bool _isContraindicated(
    Map<String, dynamic> exercise,
    Map<String, String> injuries,
  ) {
    if (injuries.isEmpty) return false;

    final stressedJoints =
        (exercise['stressed_joints'] as List?)?.cast<String>() ?? [];

    for (final joint in stressedJoints) {
      if (injuries.containsKey(joint)) {
        return true;
      }
    }

    return false;
  }
}
