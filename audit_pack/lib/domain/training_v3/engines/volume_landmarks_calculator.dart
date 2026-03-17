import 'package:flutter/foundation.dart';
import '../models/volume_landmarks.dart';

/// Calculadora de landmarks de volumen para todos los músculos
class VolumeLandmarksCalculator {
  /// Calcula landmarks para todos los músculos del usuario
  static Map<String, VolumeLandmarks> calculateForAllMuscles({
    required Map<String, int> musclePriorities,
    required String trainingLevel,
    required int age,
  }) {
    final landmarks = <String, VolumeLandmarks>{};

    for (final entry in musclePriorities.entries) {
      final muscle = entry.key;
      final priority = entry.value;

      landmarks[muscle] = VolumeLandmarks.calculate(
        muscle: muscle,
        priority: priority,
        trainingLevel: trainingLevel,
        age: age,
      );

      debugPrint('[LandmarksCalc] $muscle (P$priority):');
      debugPrint('  VME: ${landmarks[muscle]!.vme} sets');
      debugPrint('  VOP: ${landmarks[muscle]!.vop} sets (inicio)');
      debugPrint('  VMR: ${landmarks[muscle]!.vmr} sets (teorico 100%)');
      debugPrint(
        '  Target: ${landmarks[muscle]!.vmrTarget} sets (objetivo por prioridad)',
      );
    }

    return landmarks;
  }

  /// Calcula volumen total inicial (suma de todos los VOP)
  static int calculateInitialTotalVolume(
    Map<String, VolumeLandmarks> landmarks,
  ) {
    return landmarks.values.fold(0, (sum, lm) => sum + lm.vop);
  }

  /// Calcula volumen máximo teórico (suma de todos los targets)
  static int calculateMaxTotalVolume(Map<String, VolumeLandmarks> landmarks) {
    return landmarks.values.fold(0, (sum, lm) => sum + lm.vmrTarget);
  }

  /// Genera reporte detallado de landmarks
  static String generateLandmarksReport(
    Map<String, VolumeLandmarks> landmarks,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('==========================================');
    buffer.writeln('VOLUME LANDMARKS REPORT');
    buffer.writeln('==========================================\n');

    landmarks.forEach((muscle, lm) {
      buffer.writeln('$muscle:');
      buffer.writeln('  VME: ${lm.vme} sets (minimo efectivo)');
      buffer.writeln('  VOP: ${lm.vop} sets (punto partida)');
      buffer.writeln('  VMR: ${lm.vmr} sets (maximo teorico)');
      buffer.writeln('  Target: ${lm.vmrTarget} sets (objetivo real)');
      buffer.writeln('  Rango progresion: ${lm.vop} -> ${lm.vmrTarget} sets');
      buffer.writeln();
    });

    final totalInitial = calculateInitialTotalVolume(landmarks);
    final totalMax = calculateMaxTotalVolume(landmarks);

    buffer.writeln('TOTALES:');
    buffer.writeln('  Inicial (VOP): $totalInitial sets/semana');
    buffer.writeln('  Maximo (targets): $totalMax sets/semana');
    buffer.writeln('  Progresion potencial: +${totalMax - totalInitial} sets');
    buffer.writeln('==========================================');

    return buffer.toString();
  }
}
