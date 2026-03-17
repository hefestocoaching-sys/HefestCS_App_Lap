// lib/domain/training_v3/validators/volume_optimizer.dart

import 'package:flutter/foundation.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_program.dart';

/// Optimizador inteligente de volumen
///
/// Ajusta automáticamente programas con warnings de volumen subóptimo
/// hasta alcanzar rangos MAV óptimos.
class VolumeOptimizer {
  /// Optimiza programa completo eliminando warnings de volumen
  static TrainingProgram optimize(
    TrainingProgram program,
    List<String> warnings,
  ) {
    debugPrint('🔧 VolumeOptimizer: Iniciando optimización...');
    debugPrint('   Warnings detectados: ${warnings.length}');

    // Ajustar volumen basado en warnings
    final adjustedVolume = <String, double>{...program.weeklyVolumeByMuscle};
    int adjustmentsMade = 0;

    // Procesar cada warning
    for (final warning in warnings) {
      if (warning.contains('Volumen') &&
          warning.contains('por debajo de MAV')) {
        final adjustment = _parseVolumeWarning(warning);
        if (adjustment != null) {
          final muscle = adjustment['muscle']!;
          final target = int.parse(adjustment['target']!);
          final current = adjustedVolume[muscle]?.toInt() ?? 0;

          if (target > current) {
            debugPrint('   🎯 Ajustando $muscle: $current → $target sets');
            adjustedVolume[muscle] = target.toDouble();
            adjustmentsMade++;
          }
        }
      }
    }

    debugPrint('✅ VolumeOptimizer: $adjustmentsMade ajustes aplicados');

    // Si no hubo cambios, retornar programa original
    if (adjustmentsMade == 0) {
      return program;
    }

    // Usar copyWith para crear nueva versión con volumen ajustado
    return program.copyWith(
      weeklyVolumeByMuscle: adjustedVolume,
      notes: '${program.notes ?? ""}\n[Auto-optimizado por VolumeOptimizer]',
    );
  }

  /// Parsea warning para extraer músculo y sets
  static Map<String, String>? _parseVolumeWarning(String warning) {
    // Formato: "muscle: Volumen (X sets) por debajo de MAV (Y sets)."
    final muscleMatch = RegExp(r'^(\w+):').firstMatch(warning);
    final currentMatch = RegExp(r'Volumen \((\d+) sets\)').firstMatch(warning);
    final targetMatch = RegExp(r'MAV \((\d+) sets\)').firstMatch(warning);

    if (muscleMatch != null && currentMatch != null && targetMatch != null) {
      return {
        'muscle': muscleMatch.group(1)!,
        'current': currentMatch.group(1)!,
        'target': targetMatch.group(1)!,
      };
    }

    return null;
  }
}
