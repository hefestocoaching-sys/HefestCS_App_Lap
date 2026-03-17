// lib/domain/training_v3/services/program_generator_service.dart

import 'package:hcs_app_lap/domain/training_v3/models/user_profile.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_program.dart';
import 'package:hcs_app_lap/domain/training_v3/services/motor_v3_orchestrator.dart';

/// Servicio de generación de programas de entrenamiento
///
/// Capa de abstracción sobre el MotorV3Orchestrator.
/// Maneja:
/// - Generación de programas
/// - Regeneración de programas
/// - Validación previa
/// - Historial de generación
///
/// Versión: 1.0.0
class ProgramGeneratorService {
  /// Genera un nuevo programa de entrenamiento
  ///
  /// PARÁMETROS:
  /// - [userProfile]: Perfil del usuario
  /// - [phase]: Fase deseada (default: 'accumulation')
  /// - [durationWeeks]: Duración (default: 4 semanas)
  ///
  /// RETORNA:
  /// - Map con programa y metadata de generación
  static Future<Map<String, dynamic>> generateNewProgram({
    required UserProfile userProfile,
    String phase = 'accumulation',
    int durationWeeks = 4,
  }) async {
    // Validar entrada
    if (!userProfile.isValid) {
      return {
        'success': false,
        'error': 'Perfil de usuario inválido',
        'program': null,
      };
    }

    // Generar programa
    final result = await MotorV3Orchestrator.generateProgram(
      userProfile: userProfile,
      phase: phase,
      durationWeeks: durationWeeks,
    );

    if (!result['success']) {
      return result;
    }

    // Calcular calidad
    final program = result['program'] as TrainingProgram;
    final quality = MotorV3Orchestrator.calculateProgramQuality(
      program: program,
      profile: userProfile,
    );

    return {
      'success': true,
      'program': program,
      'quality': quality,
      'warnings': result['warnings'],
      'generated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Genera siguiente fase del programa (progresión)
  ///
  /// ALGORITMO:
  /// 1. Si fase actual = accumulation → intensification
  /// 2. Si fase actual = intensification → deload
  /// 3. Si fase actual = deload → accumulation (nuevo ciclo)
  static Future<Map<String, dynamic>> generateNextPhase({
    required UserProfile userProfile,
    required TrainingProgram currentProgram,
  }) async {
    String nextPhase;
    int nextDuration;

    switch (currentProgram.phase) {
      case 'accumulation':
        nextPhase = 'intensification';
        nextDuration = 2; // 2-3 semanas
        break;
      case 'intensification':
        nextPhase = 'deload';
        nextDuration = 1; // 1 semana
        break;
      case 'deload':
        nextPhase = 'accumulation';
        nextDuration = 4; // Nuevo ciclo
        break;
      default:
        nextPhase = 'accumulation';
        nextDuration = 4;
    }

    // Calcular volumen actual para progresión
    final updatedProfile = userProfile.copyWith(
      // PLACEHOLDER: aquí se podría actualizar prioridades basado en resultados
    );

    return await generateNewProgram(
      userProfile: updatedProfile,
      phase: nextPhase,
      durationWeeks: nextDuration,
    );
  }

  /// Regenera programa actual con ajustes
  ///
  /// CASOS DE USO:
  /// - Usuario cambió días disponibles
  /// - Usuario cambió prioridades
  /// - Ajuste por feedback
  static Future<Map<String, dynamic>> regenerateProgram({
    required UserProfile updatedProfile,
    required TrainingProgram currentProgram,
  }) async {
    return await generateNewProgram(
      userProfile: updatedProfile,
      phase: currentProgram.phase,
      durationWeeks:
          currentProgram.durationWeeks - (currentProgram.currentWeek - 1),
    );
  }

  /// Valida si es buen momento para generar nuevo programa
  ///
  /// CRITERIOS:
  /// - Programa actual completado O
  /// - Más de 2 semanas de adherencia baja O
  /// - Usuario solicita cambio explícito
  static Map<String, dynamic> validateGenerationTiming({
    required TrainingProgram? currentProgram,
    List<double>? recentAdherence, // Últimas 2 semanas
  }) {
    // Sin programa actual → OK
    if (currentProgram == null) {
      return {
        'should_generate': true,
        'reason': 'No hay programa activo',
        'urgency': 'high',
      };
    }

    // Programa completado → OK
    if (currentProgram.isCompleted) {
      return {
        'should_generate': true,
        'reason': 'Programa actual completado',
        'urgency': 'high',
      };
    }

    // Adherencia baja sostenida → Considerar
    if (recentAdherence != null && recentAdherence.isNotEmpty) {
      final avgAdherence =
          recentAdherence.fold(0.0, (sum, a) => sum + a) /
          recentAdherence.length;

      if (avgAdherence < 70) {
        return {
          'should_generate': false,
          'reason':
              'Adherencia baja (${avgAdherence.toStringAsFixed(1)}%). Resolver causas antes de cambiar programa.',
          'urgency': 'none',
          'recommendation': 'Investigar factores: fatiga, tiempo, motivación',
        };
      }
    }

    // En medio de programa con buena adherencia → NO
    return {
      'should_generate': false,
      'reason': 'Programa activo en progreso. Completar antes de cambiar.',
      'urgency': 'none',
      'weeks_remaining':
          currentProgram.durationWeeks - currentProgram.currentWeek + 1,
    };
  }
}
