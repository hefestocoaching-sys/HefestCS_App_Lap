// lib/domain/training_v3/services/motor_v3_orchestrator.dart

import 'package:hcs_app_lap/domain/training_v3/models/user_profile.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_program.dart';
import 'package:hcs_app_lap/domain/training_v3/models/split_config.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/volume_engine.dart';
import 'package:hcs_app_lap/domain/training_v3/engines/split_generator_engine.dart';
import 'package:hcs_app_lap/domain/training_v3/validators/volume_validator.dart';
import 'package:hcs_app_lap/domain/training_v3/validators/configuration_validator.dart';

/// Orquestador principal del Motor V3
///
/// Coordina todos los engines y validadores para generar un programa completo:
/// 1. Genera split óptimo
/// 2. Calcula volumen por músculo
/// 3. Selecciona ejercicios
/// 4. Asigna intensidades
/// 5. Asigna RIR
/// 6. Ordena ejercicios
/// 7. Valida programa completo
///
/// FUNDAMENTO CIENTÍFICO:
/// - Pipeline completo basado en Semanas 1-7
/// - Validación científica en cada paso
///
/// Versión: 1.0.0
class MotorV3Orchestrator {
  /// Genera un programa de entrenamiento completo
  ///
  /// ALGORITMO COMPLETO:
  /// 1. Validar entrada (UserProfile)
  /// 2. Generar split óptimo (SplitGeneratorEngine)
  /// 3. Calcular volumen por músculo (VolumeEngine)
  /// 4. Validar volumen (VolumeValidator)
  /// 5. [PLACEHOLDER: Seleccionar ejercicios]
  /// 6. [PLACEHOLDER: Asignar intensidades]
  /// 7. [PLACEHOLDER: Asignar RIR]
  /// 8. [PLACEHOLDER: Ordenar ejercicios]
  /// 9. Construir TrainingProgram
  /// 10. Validar configuración final
  ///
  /// PARÁMETROS:
  /// - [userProfile]: Perfil completo del usuario
  /// - [phase]: Fase del programa ('accumulation'|'intensification'|'deload')
  /// - [durationWeeks]: Duración en semanas
  ///
  /// RETORNA:
  /// - TrainingProgram completo y validado
  static Future<Map<String, dynamic>> generateProgram({
    required UserProfile userProfile,
    required String phase,
    required int durationWeeks,
  }) async {
    // PASO 0: Validar entrada
    if (!userProfile.isValid) {
      throw ArgumentError('UserProfile inválido');
    }

    final errors = <String>[];
    final warnings = <String>[];

    // PASO 1: Generar split óptimo
    final split = SplitGeneratorEngine.generateOptimalSplit(
      availableDays: userProfile.availableDays,
      goal: userProfile.primaryGoal,
    );

    // PASO 2: Calcular volumen por músculo
    final volumeByMuscle = _calculateVolumeByMuscle(userProfile);

    // PASO 3: Validar volumen
    final volumeValidation = VolumeValidator.validateProgram(
      volumeByMuscle: volumeByMuscle,
      trainingLevel: userProfile.trainingLevel,
    );

    if (!volumeValidation['is_valid']) {
      errors.addAll(volumeValidation['errors'] as List<String>);
    }
    warnings.addAll(volumeValidation['warnings'] as List<String>);

    // PASO 4: Validar configuración
    final configValidation = ConfigurationValidator.validateConfiguration(
      split: split,
      phase: phase,
      durationWeeks: durationWeeks,
      totalExercises: 0, // PLACEHOLDER: calcular cuando tengamos ejercicios
    );

    if (!configValidation['is_valid']) {
      errors.addAll(configValidation['errors'] as List<String>);
    }
    warnings.addAll(configValidation['warnings'] as List<String>);

    // PASO 5: Si hay errores críticos, retornar sin generar
    if (errors.isNotEmpty) {
      return {
        'success': false,
        'errors': errors,
        'warnings': warnings,
        'program': null,
      };
    }

    // PASO 6: Construir programa (simplificado por ahora)
    final program = _buildProgram(
      userProfile: userProfile,
      split: split,
      phase: phase,
      durationWeeks: durationWeeks,
      volumeByMuscle: volumeByMuscle,
    );

    return {
      'success': true,
      'errors': [],
      'warnings': warnings,
      'program': program,
      'volume_validation': volumeValidation,
      'config_validation': configValidation,
    };
  }

  /// Calcula volumen óptimo para cada músculo según prioridades
  static Map<String, int> _calculateVolumeByMuscle(UserProfile profile) {
    final volumeByMuscle = <String, int>{};

    // Calcular volumen para cada músculo con prioridad
    profile.musclePriorities.forEach((muscle, priority) {
      final volume = VolumeEngine.calculateOptimalVolume(
        muscle: muscle,
        trainingLevel: profile.trainingLevel,
        priority: priority,
        currentVolume: null, // Primera vez, no hay volumen previo
      );

      volumeByMuscle[muscle] = volume;
    });

    return volumeByMuscle;
  }

  /// Construye el programa completo (simplificado por ahora)
  ///
  /// NOTA: Este es un placeholder. La versión completa incluirá:
  /// - Selección de ejercicios (ExerciseSelectionEngine)
  /// - Asignación de intensidades (IntensityEngine)
  /// - Asignación de RIR (EffortEngine)
  /// - Ordenamiento (OrderingEngine)
  /// - Construcción de sesiones completas
  static TrainingProgram _buildProgram({
    required UserProfile userProfile,
    required SplitConfig split,
    required String phase,
    required int durationWeeks,
    required Map<String, int> volumeByMuscle,
  }) {
    final now = DateTime.now();

    // PLACEHOLDER: Crear sesiones vacías por ahora
    final sessions = List.generate(
      split.daysPerWeek,
      (index) => {
        'id': 'session_${index + 1}',
        'dayNumber': index + 1,
        'name': 'Sesión ${index + 1}',
        'exercises': [], // PLACEHOLDER
      },
    );

    return TrainingProgram(
      id: 'program_${now.millisecondsSinceEpoch}',
      userId: userProfile.id,
      name: '${split.name} - ${_capitalize(phase)} - ${durationWeeks}w',
      split: split,
      phase: phase,
      durationWeeks: durationWeeks,
      currentWeek: 1,
      sessions:
          [], // PLACEHOLDER: convertir sesiones cuando tengamos modelo completo
      weeklyVolumeByMuscle: volumeByMuscle.map(
        (k, v) => MapEntry(k, v.toDouble()),
      ),
      startDate: now,
      estimatedEndDate: now.add(Duration(days: durationWeeks * 7)),
      createdAt: now,
      notes: 'Generado por Motor V3 - Versión simplificada',
    );
  }

  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Calcula score de calidad total del programa generado
  static Map<String, dynamic> calculateProgramQuality({
    required TrainingProgram program,
    required UserProfile profile,
  }) {
    // Calcular scores individuales
    final volumeScore = VolumeValidator.calculateVolumeQualityScore(
      volumeByMuscle: program.weeklyVolumeByMuscle.map(
        (k, v) => MapEntry(k, v.toInt()),
      ),
      trainingLevel: profile.trainingLevel,
    );

    // PLACEHOLDER: Otros scores cuando tengamos engines completos
    final intensityScore = 1.0; // PLACEHOLDER
    final effortScore = 1.0; // PLACEHOLDER

    final overallScore = ConfigurationValidator.calculateOverallQualityScore(
      split: program.split,
      phase: program.phase,
      durationWeeks: program.durationWeeks,
      totalExercises: program.sessions.length, // PLACEHOLDER
      volumeScore: volumeScore,
      intensityScore: intensityScore,
      effortScore: effortScore,
    );

    return {
      'overall_score': overallScore,
      'volume_score': volumeScore,
      'intensity_score': intensityScore,
      'effort_score': effortScore,
      'quality_level': _getQualityLevel(overallScore),
    };
  }

  static String _getQualityLevel(double score) {
    if (score >= 0.9) return 'Excelente';
    if (score >= 0.75) return 'Bueno';
    if (score >= 0.6) return 'Aceptable';
    if (score >= 0.4) return 'Subóptimo';
    return 'Deficiente';
  }
}
