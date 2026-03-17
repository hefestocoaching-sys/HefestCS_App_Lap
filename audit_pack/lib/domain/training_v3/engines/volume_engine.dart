// lib/domain/training_v3/engines/volume_engine.dart

import 'package:hcs_app_lap/core/utils/app_logger.dart';
import '../models/volume_landmarks.dart';

/// Motor de cálculo de volumen óptimo por músculo
///
/// VERSIÓN 2.0 - Sistema Adaptativo Granular
///
/// CAMBIOS DESDE V1:
/// - MAV → VOP (Volumen Óptimo Personalizado)
/// - MRV → VMR (Máximo Recuperable)
/// - VMR Target según prioridad (100%/75%/VOP)
/// - Progresión porcentual (+18-22%) no lineal
///
/// FUNDAMENTO CIENTÍFICO:
/// - VME: Volumen Mínimo Efectivo (Israetel et al. 2020)
/// - VOP: Punto de partida conservador (VME + 35% hacia VMR)
/// - VMR: Volumen Máximo Recuperable
/// - Progresión adaptativa según rendimiento
///
/// Versión: 2.0.0
class VolumeEngine {
  /// Calcula el volumen semanal óptimo INICIAL para un músculo
  ///
  /// Este método ahora solo se usa para INICIALIZACIÓN.
  /// Para progresión semanal, usar WeeklyAdaptationEngine.
  ///
  /// RETORNA: VOP (Volumen Óptimo Personalizado)
  static int calculateOptimalVolume({
    required String muscle,
    required String trainingLevel,
    required int priority,
    required int age,
    int? currentVolume,
  }) {
    _validateInputs(
      muscle: muscle,
      trainingLevel: trainingLevel,
      priority: priority,
      age: age,
    );

    final landmarks = VolumeLandmarks.calculate(
      muscle: muscle,
      priority: priority,
      trainingLevel: trainingLevel,
      age: age,
    );

    final double ageMultiplier = _getAgeMultiplier(age);
    final int ageAdjustedBase = (landmarks.vme * ageMultiplier).round();
    final int ageAdjustedMav = (landmarks.vop * ageMultiplier).round();
    final int ageAdjustedMrv = (landmarks.vmr * ageMultiplier).round();

    final optimal = ageAdjustedMav.clamp(ageAdjustedBase, ageAdjustedMrv);

    logger.info(
      'Volume calculated for $muscle: VOP=$optimal '
      '(VME=$ageAdjustedBase, VMR=$ageAdjustedMrv, Target=${landmarks.vmrTarget}, age=$age)',
    );

    return optimal;
  }

  static void _validateInputs({
    required String muscle,
    required String trainingLevel,
    required int priority,
    required int age,
  }) {
    if (muscle.trim().isEmpty) {
      throw ArgumentError('muscle no puede estar vacío');
    }
    if (priority < 1 || priority > 5) {
      throw ArgumentError('priority debe estar entre 1 y 5');
    }
    if (!{'novice', 'intermediate', 'advanced'}.contains(trainingLevel)) {
      throw ArgumentError('trainingLevel inválido: $trainingLevel');
    }
    if (age < 18 || age > 80) {
      throw ArgumentError('age debe estar entre 18 y 80');
    }
  }

  static double _getAgeMultiplier(int age) {
    if (age < 25) return 1.10;
    if (age <= 39) return 1.00;
    if (age <= 54) return 0.90;
    return 0.80;
  }

  /// Calcula landmarks completos para un músculo
  ///
  /// NUEVO MÉTODO V2.0
  static VolumeLandmarks calculateLandmarks({
    required String muscle,
    required String trainingLevel,
    required int priority,
    required int age,
  }) {
    return VolumeLandmarks.calculate(
      muscle: muscle,
      priority: priority,
      trainingLevel: trainingLevel,
      age: age,
    );
  }

  /// Valida que el volumen esté en rango óptimo
  ///
  /// ACTUALIZADO V2.0: Ahora verifica contra VMR Target
  static bool isVolumeOptimal({
    required int volume,
    required VolumeLandmarks landmarks,
  }) {
    return volume >= landmarks.vop && volume <= landmarks.vmrTarget;
  }

  /// Calcula volumen total semanal
  static int calculateTotalWeeklyVolume(Map<String, int> volumeByMuscle) {
    return volumeByMuscle.values.fold(0, (sum, vol) => sum + vol);
  }

  /// Verifica si un músculo está en VME
  static bool isAtMinimumEffective({
    required int volume,
    required VolumeLandmarks landmarks,
  }) {
    return volume >= landmarks.vme;
  }

  /// Verifica si un músculo alcanzó su VMR Target
  static bool hasReachedTarget({
    required int volume,
    required VolumeLandmarks landmarks,
  }) {
    return volume >= landmarks.vmrTarget;
  }
}
