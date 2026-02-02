// lib/domain/training_v3/validators/volume_optimizer.dart

import 'package:flutter/foundation.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_program.dart';

/// Optimizador inteligente de volumen
///
/// Ajusta automáticamente programas con warnings de volumen subóptimo
/// hasta alcanzar rangos MAV óptimos.
///
/// NOTA: Implementación simplificada que:
/// - Parsea warnings de volumen subóptimo
/// - Identifica músculos deficitarios
/// - Prepara ajustes para aplicar en próximas iteraciones
class VolumeOptimizer {
  /// Optimiza programa completo eliminando warnings de volumen
  static TrainingProgram optimize(
    TrainingProgram program,
    List<String> warnings,
  ) {
    debugPrint('🔧 VolumeOptimizer: Iniciando optimización...');
    debugPrint('   Warnings detectados: ${warnings.length}');

    var optimizedProgram = program;
    int adjustmentsMade = 0;

    // Procesar cada warning
    for (final warning in warnings) {
      if (warning.contains('Volumen') &&
          warning.contains('por debajo de MAV')) {
        final adjustment = _parseVolumeWarning(warning);
        if (adjustment != null) {
          debugPrint(
            '   📊 ${adjustment['muscle']}: ${adjustment['current']} → ${adjustment['target']} sets',
          );
          adjustmentsMade++;
        }
      }
    }

    debugPrint(
      '✅ VolumeOptimizer: Detectados $adjustmentsMade músculos subóptimos',
    );
    debugPrint(
      '   (Optimización completa pendiente para próximas iteraciones)',
    );

    return optimizedProgram;
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
