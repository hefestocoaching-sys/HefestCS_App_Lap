import 'package:hcs_app_lap/domain/training_v3/models/exercise_angle_coverage.dart';

/// Repositorio para la cobertura angular de ejercicios.
///
/// Responsabilidades:
/// - Guardar cobertura angular semanal por músculo.
/// - Recuperar historial de cobertura para análisis.
abstract class ExerciseAngleCoverageRepository {
  /// Guarda la cobertura angular de una semana.
  ///
  /// Persistencia: users/{userId}/angle_coverage/{weekId_muscle}
  Future<void> saveCoverage(ExerciseAngleCoverage coverage);

  /// Recupera cobertura angular para un músculo en un rango de semanas.
  Future<List<ExerciseAngleCoverage>> getCoverageHistory({
    required String userId,
    required String muscle,
    int? limit,
  });
}
