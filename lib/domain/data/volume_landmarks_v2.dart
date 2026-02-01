// lib/domain/data/volume_landmarks_v2.dart

import 'package:hcs_app_lap/core/enums/muscle_group.dart';
import 'package:hcs_app_lap/core/enums/gender.dart';

/// Nivel de entrenamiento
enum TrainingLevel {
  beginner, // 0-1 años
  intermediate, // 1-3 años
  advanced, // 3+ años
}

/// Landmark de volumen por músculo (MEV/MAV/MRV)
class VolumeLandmark {
  /// Minimum Effective Volume (sets/semana mínimos para hipertrofia)
  final int mev;

  /// Maximum Adaptive Volume (sets/semana óptimos para mayoría)
  final int mav;

  /// Maximum Recoverable Volume (sets/semana máximos recuperables)
  final int mrv;

  /// Frecuencia óptima (veces por semana)
  final int optimalFrequency;

  /// Rango de reps óptimo para hipertrofia
  final String repRange;

  const VolumeLandmark({
    required this.mev,
    required this.mav,
    required this.mrv,
    required this.optimalFrequency,
    required this.repRange,
  });

  /// Valida que MEV <= MAV <= MRV
  bool get isValid => mev <= mav && mav <= mrv;

  /// Rango de volumen total (MEV a MRV)
  int get volumeRange => mrv - mev;

  Map<String, dynamic> toJson() => {
    'mev': mev,
    'mav': mav,
    'mrv': mrv,
    'optimalFrequency': optimalFrequency,
    'repRange': repRange,
  };
}

/// Tabla de Volume Landmarks V2 (Israetel 2024 + Schoenfeld + Contreras)
class VolumeLandmarksV2 {
  // ════════════════════════════════════════════════════════════════
  // TABLA BASE (INTERMEDIATE LEVEL, MALE, NO ANABOLICS)
  // Fuente: Renaissance Periodization (Israetel 2024)
  // ════════════════════════════════════════════════════════════════

  static const _baseLandmarks = <MuscleGroup, VolumeLandmark>{
    // PECHO
    MuscleGroup.chest: VolumeLandmark(
      mev: 10,
      mav: 16,
      mrv: 22,
      optimalFrequency: 2,
      repRange: '5-30',
    ),

    // ESPALDA
    MuscleGroup.lats: VolumeLandmark(
      mev: 8,
      mav: 14,
      mrv: 20,
      optimalFrequency: 2,
      repRange: '6-20',
    ),
    MuscleGroup.upperBack: VolumeLandmark(
      mev: 12,
      mav: 18,
      mrv: 25,
      optimalFrequency: 2,
      repRange: '8-20',
    ),
    MuscleGroup.traps: VolumeLandmark(
      mev: 6,
      mav: 12,
      mrv: 18,
      optimalFrequency: 2,
      repRange: '8-20',
    ),

    // HOMBROS
    MuscleGroup.shoulderAnterior: VolumeLandmark(
      mev: 6,
      mav: 10,
      mrv: 16,
      optimalFrequency: 2,
      repRange: '6-20',
    ),
    MuscleGroup.shoulderLateral: VolumeLandmark(
      mev: 8,
      mav: 14,
      mrv: 20,
      optimalFrequency: 2,
      repRange: '8-25',
    ),
    MuscleGroup.shoulderPosterior: VolumeLandmark(
      mev: 8,
      mav: 14,
      mrv: 20,
      optimalFrequency: 2,
      repRange: '10-25',
    ),

    // BRAZOS
    MuscleGroup.biceps: VolumeLandmark(
      mev: 8,
      mav: 14,
      mrv: 20,
      optimalFrequency: 2,
      repRange: '8-15',
    ),
    MuscleGroup.triceps: VolumeLandmark(
      mev: 8,
      mav: 14,
      mrv: 20,
      optimalFrequency: 2,
      repRange: '8-20',
    ),

    // PIERNAS
    MuscleGroup.quads: VolumeLandmark(
      mev: 10,
      mav: 16,
      mrv: 24,
      optimalFrequency: 2,
      repRange: '6-20',
    ),
    MuscleGroup.hamstrings: VolumeLandmark(
      mev: 8,
      mav: 14,
      mrv: 20,
      optimalFrequency: 2,
      repRange: '6-20',
    ),
    MuscleGroup.glutes: VolumeLandmark(
      mev: 8,
      mav: 14,
      mrv: 22,
      optimalFrequency: 2,
      repRange: '6-20',
    ),
    MuscleGroup.calves: VolumeLandmark(
      mev: 8,
      mav: 14,
      mrv: 20,
      optimalFrequency: 2,
      repRange: '8-15',
    ),

    // CORE
    MuscleGroup.abs: VolumeLandmark(
      mev: 6,
      mav: 12,
      mrv: 20,
      optimalFrequency: 3,
      repRange: '10-25',
    ),
  };

  // ════════════════════════════════════════════════════════════════
  // OBTENER LANDMARK CON AJUSTES
  // ════════════════════════════════════════════════════════════════

  /// Obtiene landmark ajustado por nivel, género, edad y anabólicos
  static VolumeLandmark getLandmark({
    required MuscleGroup muscle,
    TrainingLevel level = TrainingLevel.intermediate,
    Gender? gender,
    int? ageYears,
    bool usesAnabolics = false,
  }) {
    // 1. Obtener baseline
    final base = _baseLandmarks[muscle];
    if (base == null) {
      // Fallback para músculos no mapeados (ej: shoulders genérico)
      return const VolumeLandmark(
        mev: 8,
        mav: 14,
        mrv: 20,
        optimalFrequency: 2,
        repRange: '8-20',
      );
    }

    // 2. Calcular multiplicadores
    double mevMultiplier = 1.0;
    double mavMultiplier = 1.0;
    double mrvMultiplier = 1.0;

    // AJUSTE POR NIVEL
    switch (level) {
      case TrainingLevel.beginner:
        // Principiantes: -30% MRV, -20% MAV, MEV sin cambio
        mevMultiplier = 1.0;
        mavMultiplier = 0.8;
        mrvMultiplier = 0.7;
        break;
      case TrainingLevel.intermediate:
        // Base (sin cambios)
        break;
      case TrainingLevel.advanced:
        // Avanzados: +10% MAV/MRV (mayor capacidad)
        mavMultiplier = 1.1;
        mrvMultiplier = 1.1;
        break;
    }

    // AJUSTE POR GÉNERO
    if (gender != null) {
      if (gender == Gender.female) {
        // Mujeres: glúteos +20%, upper body -10%
        if (muscle == MuscleGroup.glutes) {
          mrvMultiplier *= 1.2;
          mavMultiplier *= 1.2;
        } else if (muscle.isUpper) {
          mrvMultiplier *= 0.9;
          mavMultiplier *= 0.9;
        }
      }
    }

    // AJUSTE POR EDAD
    if (ageYears != null) {
      if (ageYears > 50) {
        mrvMultiplier *= 0.8; // -20%
        mavMultiplier *= 0.9; // -10%
      } else if (ageYears > 40) {
        mrvMultiplier *= 0.9; // -10%
        mavMultiplier *= 0.95; // -5%
      } else if (ageYears > 30) {
        mrvMultiplier *= 0.95; // -5%
      }
    }

    // AJUSTE POR ANABÓLICOS
    if (usesAnabolics) {
      mrvMultiplier *= 1.3; // +30% MRV
      mavMultiplier *= 1.2; // +20% MAV
    }

    // 3. Aplicar multiplicadores
    final adjustedMev = (base.mev * mevMultiplier).round();
    final adjustedMav = (base.mav * mavMultiplier).round();
    final adjustedMrv = (base.mrv * mrvMultiplier).round();

    // 4. Validar orden MEV <= MAV <= MRV
    final finalMev = adjustedMev;
    final finalMav = adjustedMav.clamp(finalMev, adjustedMrv);
    final finalMrv = adjustedMrv.clamp(finalMav, 100); // Max 100 sets/semana

    // 5. Validación adicional: principiantes nunca >16 sets/semana
    final cappedMrv = level == TrainingLevel.beginner
        ? finalMrv.clamp(0, 16)
        : finalMrv;

    return VolumeLandmark(
      mev: finalMev,
      mav: finalMav,
      mrv: cappedMrv,
      optimalFrequency: base.optimalFrequency,
      repRange: base.repRange,
    );
  }

  /// Obtiene todos los landmarks para los 14 músculos canónicos
  static Map<MuscleGroup, VolumeLandmark> getAllLandmarks({
    TrainingLevel level = TrainingLevel.intermediate,
    Gender? gender,
    int? ageYears,
    bool usesAnabolics = false,
  }) {
    final result = <MuscleGroup, VolumeLandmark>{};

    for (final muscle in canonicalMuscleGroups) {
      result[muscle] = getLandmark(
        muscle: muscle,
        level: level,
        gender: gender,
        ageYears: ageYears,
        usesAnabolics: usesAnabolics,
      );
    }

    return result;
  }

  /// Calcula volumen recomendado inicial (percentil dentro de MEV-MRV)
  static int getRecommendedStartVolume({
    required MuscleGroup muscle,
    TrainingLevel level = TrainingLevel.intermediate,
    Gender? gender,
    int? ageYears,
    bool usesAnabolics = false,
    double percentile = 0.5, // 0.5 = 50% entre MEV y MRV (default conservador)
  }) {
    final landmark = getLandmark(
      muscle: muscle,
      level: level,
      gender: gender,
      ageYears: ageYears,
      usesAnabolics: usesAnabolics,
    );

    // Calcular volumen inicial como percentil entre MEV y MRV
    final range = landmark.mrv - landmark.mev;
    final recommended = landmark.mev + (range * percentile).round();

    // Clamp entre MEV y MRV
    return recommended.clamp(landmark.mev, landmark.mrv);
  }

  /// Valida que un volumen esté dentro de MEV-MRV
  static bool isVolumeValid({
    required MuscleGroup muscle,
    required int weeklyVolume,
    TrainingLevel level = TrainingLevel.intermediate,
    Gender? gender,
    int? ageYears,
    bool usesAnabolics = false,
  }) {
    final landmark = getLandmark(
      muscle: muscle,
      level: level,
      gender: gender,
      ageYears: ageYears,
      usesAnabolics: usesAnabolics,
    );

    return weeklyVolume >= landmark.mev && weeklyVolume <= landmark.mrv;
  }
}

/// Extensión para calcular nivel desde años de entrenamiento
extension TrainingLevelFromYears on TrainingLevel {
  static TrainingLevel fromYears(int years) {
    if (years < 1) return TrainingLevel.beginner;
    if (years < 3) return TrainingLevel.intermediate;
    return TrainingLevel.advanced;
  }
}
