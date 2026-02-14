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
    int? currentVolume,
  }) {
    final landmarks = VolumeLandmarks.calculate(
      muscle: muscle,
      priority: priority,
      trainingLevel: trainingLevel,
      age: 30,
    );

    logger.info(
      'Volume calculated for $muscle: VOP=${landmarks.vop} '
      '(VME=${landmarks.vme}, VMR=${landmarks.vmr}, Target=${landmarks.vmrTarget})',
    );

    return landmarks.vop;
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
