import 'package:hcs_app_lap/core/constants/training_interview_keys.dart';
import 'package:hcs_app_lap/core/enums/gender.dart';
import 'package:hcs_app_lap/domain/training_v3/ml/client_data_snapshot.dart';
import 'package:hcs_app_lap/domain/training_v3/ml/normalized_client_data.dart';

/// Normalizador y enriquecedor de datos del cliente.
///
/// Esta clase implementa la CAPA 1 del Motor V3 Unificado.
///
/// VERSION: v1.0.0
/// FECHA: 2 de febrero de 2026
///
/// PROPÓSITO:
/// - Normalizar datos desde ClientDataSnapshot
/// - Calcular campos derivados y clasificaciones
/// - Aplicar ajustes según Israetel
/// - Priorizar fuentes de datos
///
/// LÓGICA:
/// 1. Extrae datos con prioridad de fuentes
/// 2. Calcula clasificaciones (altura, peso, edad, fuerza)
/// 3. Calcula promedios desde datos históricos
/// 4. Aplica ajustes Israetel (altura, peso, sueño, experiencia, etc.)
/// 5. Calcula límites observados de volumen desde ML
///
/// USO:
/// ```dart
/// final snapshot = await UnifiedDataCollector.collectClientData(client);
/// final normalized = DataNormalizer.normalize(snapshot);
/// // normalized contiene todos los datos enriquecidos
/// ```
class DataNormalizer {
  /// Normaliza y enriquece datos desde un snapshot.
  ///
  /// DETERMINISTA: Mismos inputs → mismo output
  /// SIN SIDE EFFECTS: No modifica el snapshot
  static NormalizedClientData normalize(ClientDataSnapshot snapshot) {
    // A) Demographics
    final demographics = _extractDemographics(snapshot);

    // B) Anthropometrics ⭐⭐⭐
    final anthropometrics = _extractAnthropometrics(snapshot);

    // C) Physical Capacity
    final physicalCapacity = _extractPhysicalCapacity(snapshot);

    // D) Recovery Profile
    final recoveryProfile = _extractRecoveryProfile(snapshot);

    // E) Training Experience
    final experience = _extractTrainingExperience(snapshot);

    // F) Historical Volume (ML)
    final volumeHistory = _extractHistoricalVolume(snapshot);

    // G) Pharmacology
    final usesAnabolics = snapshot.trainingProfile?.usesAnabolics ?? false;
    final anabolicsAdjustment = usesAnabolics ? 1.15 : 1.0;

    // H) Rest & Recovery
    final restSeconds = snapshot.trainingProfile?.restBetweenSetsSeconds;
    final restAdjustment = _calculateRestAdjustment(restSeconds);

    return NormalizedClientData(
      // Demographics
      age: demographics['age'] as int?,
      gender: demographics['gender'] as String?,
      ageCategory: demographics['ageCategory'] as String?,
      // Anthropometrics
      heightCm: anthropometrics['heightCm'] as double?,
      weightKg: anthropometrics['weightKg'] as double?,
      bmi: anthropometrics['bmi'] as double?,
      heightClass: anthropometrics['heightClass'] as String?,
      weightClass: anthropometrics['weightClass'] as String?,
      heightAdjustmentVME: anthropometrics['heightAdjustmentVME'] as double,
      heightAdjustmentVMR: anthropometrics['heightAdjustmentVMR'] as double,
      weightAdjustmentVME: anthropometrics['weightAdjustmentVME'] as double,
      weightAdjustmentVMR: anthropometrics['weightAdjustmentVMR'] as double,
      // Physical Capacity
      strengthClass: physicalCapacity['strengthClass'] as String?,
      workCapacity: physicalCapacity['workCapacity'] as int?,
      recoveryCapacity: physicalCapacity['recoveryCapacity'] as int?,
      // Recovery Profile
      avgSleepHours: recoveryProfile['avgSleepHours'] as double?,
      sleepCategory: recoveryProfile['sleepCategory'] as String?,
      physicalStress: recoveryProfile['physicalStress'] as int?,
      nonPhysicalStress: recoveryProfile['nonPhysicalStress'] as int?,
      avgHRV: recoveryProfile['avgHRV'] as double?,
      avgRHR: recoveryProfile['avgRHR'] as double?,
      sleepAdjustmentVME: recoveryProfile['sleepAdjustmentVME'] as double,
      sleepAdjustmentVMR: recoveryProfile['sleepAdjustmentVMR'] as double,
      stressAdjustmentVME: recoveryProfile['stressAdjustmentVME'] as double,
      stressAdjustmentVMR: recoveryProfile['stressAdjustmentVMR'] as double,
      // Training Experience
      effectiveLevel: experience['effectiveLevel'] as String?,
      subpopulation: experience['subpopulation'] as String?,
      programNovelty: experience['programNovelty'] as double,
      experienceAdjustmentVME: experience['experienceAdjustmentVME'] as double,
      experienceAdjustmentVMR: experience['experienceAdjustmentVMR'] as double,
      noveltyAdjustmentVME: experience['noveltyAdjustmentVME'] as double,
      noveltyAdjustmentVMR: experience['noveltyAdjustmentVMR'] as double,
      // Historical Volume
      observedLimitsByMuscle: volumeHistory,
      // Pharmacology
      usesAnabolics: usesAnabolics,
      anabolicsAdjustmentVMR: anabolicsAdjustment,
      // Rest & Recovery
      restBetweenSetsSeconds: restSeconds,
      restAdjustmentFatigue: restAdjustment,
    );
  }

  // =========================================================================
  // A) DEMOGRAPHICS
  // =========================================================================

  static Map<String, dynamic> _extractDemographics(
    ClientDataSnapshot snapshot,
  ) {
    // Age: Prioridad TrainingProfile > calculado desde ClientProfile
    int? age = snapshot.trainingProfile?.age;
    if (age == null && snapshot.clientProfile?.dateOfBirth != null) {
      final dob = snapshot.clientProfile!.dateOfBirth!;
      age = DateTime.now().year - dob.year;
    }

    // Gender: TrainingProfile
    String? gender;
    if (snapshot.trainingProfile?.gender != null) {
      gender = snapshot.trainingProfile!.gender == Gender.male
          ? 'male'
          : snapshot.trainingProfile!.gender == Gender.female
              ? 'female'
              : 'other';
    }

    // Age category
    String? ageCategory;
    if (age != null) {
      if (age < 18) {
        ageCategory = 'youth';
      } else if (age < 40) {
        ageCategory = 'adult';
      } else if (age < 60) {
        ageCategory = 'middle';
      } else {
        ageCategory = 'senior';
      }
    }

    return {
      'age': age,
      'gender': gender,
      'ageCategory': ageCategory,
    };
  }

  // =========================================================================
  // B) ANTHROPOMETRICS ⭐⭐⭐
  // =========================================================================

  static Map<String, dynamic> _extractAnthropometrics(
    ClientDataSnapshot snapshot,
  ) {
    // Height: Prioridad AnthropometryRecord > TrainingProfile.extra
    double? heightCm = snapshot.latestAnthropometry?.heightCm;
    if (heightCm == null) {
      // Fallback a TrainingProfile.extra si existe
      final extra = snapshot.trainingProfile?.extra;
      if (extra != null && extra.containsKey('height')) {
        heightCm = (extra['height'] as num?)?.toDouble();
      }
    }

    // Weight: Prioridad AnthropometryRecord > TrainingProfile.bodyWeight
    double? weightKg = snapshot.latestAnthropometry?.weightKg;
    if (weightKg == null) {
      weightKg = snapshot.trainingProfile?.bodyWeight;
    }

    // BMI
    double? bmi;
    if (heightCm != null && weightKg != null && heightCm > 0) {
      final heightM = heightCm / 100.0;
      bmi = weightKg / (heightM * heightM);
    }

    // Height classification
    String? heightClass;
    if (heightCm != null) {
      if (heightCm < 160) {
        heightClass = 'very_short';
      } else if (heightCm < 170) {
        heightClass = 'short';
      } else if (heightCm < 180) {
        heightClass = 'average';
      } else if (heightCm < 190) {
        heightClass = 'tall';
      } else {
        heightClass = 'very_tall';
      }
    }

    // Weight classification (BMI-based)
    String? weightClass;
    if (bmi != null) {
      if (bmi < 18.5) {
        weightClass = 'underweight';
      } else if (bmi < 25.0) {
        weightClass = 'normal';
      } else if (bmi < 30.0) {
        weightClass = 'overweight';
      } else {
        weightClass = 'obese';
      }
    }

    // Ajustes Israetel por altura
    double heightAdjVME = 1.0;
    double heightAdjVMR = 1.0;
    if (heightCm != null) {
      if (heightCm > 185) {
        // Personas altas: +10% VME/VMR
        heightAdjVME = 1.10;
        heightAdjVMR = 1.10;
      } else if (heightCm < 165) {
        // Personas bajas: -10% VME/VMR
        heightAdjVME = 0.90;
        heightAdjVMR = 0.90;
      }
    }

    // Ajustes por peso (basado en masa muscular estimada)
    // Simplificación: usar BMI como proxy
    double weightAdjVME = 1.0;
    double weightAdjVMR = 1.0;
    if (bmi != null) {
      if (bmi > 27) {
        // Mayor masa (muscular o grasa): +5% capacidad
        weightAdjVME = 1.05;
        weightAdjVMR = 1.05;
      } else if (bmi < 20) {
        // Menor masa: -5% capacidad
        weightAdjVME = 0.95;
        weightAdjVMR = 0.95;
      }
    }

    return {
      'heightCm': heightCm,
      'weightKg': weightKg,
      'bmi': bmi,
      'heightClass': heightClass,
      'weightClass': weightClass,
      'heightAdjustmentVME': heightAdjVME,
      'heightAdjustmentVMR': heightAdjVMR,
      'weightAdjustmentVME': weightAdjVME,
      'weightAdjustmentVMR': weightAdjVMR,
    };
  }

  // =========================================================================
  // C) PHYSICAL CAPACITY
  // =========================================================================

  static Map<String, dynamic> _extractPhysicalCapacity(
    ClientDataSnapshot snapshot,
  ) {
    // Strength class: desde PRs usando Wilks/IPF
    // TODO: Implementar clasificación real desde StrengthAssessment
    String? strengthClass;
    if (snapshot.hasStrengthData) {
      // Placeholder: clasificar basándose en 1RM estimado
      strengthClass = 'class_II'; // Default conservador
    }

    // Work capacity: desde TrainingProfile.extra o default
    int? workCapacity;
    final extra = snapshot.trainingProfile?.extra;
    if (extra != null) {
      workCapacity =
          _readInt(extra, [TrainingInterviewKeys.workCapacity], null);
    }

    // Recovery capacity: desde TrainingProfile.extra o default
    int? recoveryCapacity;
    if (extra != null) {
      recoveryCapacity =
          _readInt(extra, [TrainingInterviewKeys.recoveryHistory], null);
    }

    return {
      'strengthClass': strengthClass,
      'workCapacity': workCapacity,
      'recoveryCapacity': recoveryCapacity,
    };
  }

  // =========================================================================
  // D) RECOVERY PROFILE
  // =========================================================================

  static Map<String, dynamic> _extractRecoveryProfile(
    ClientDataSnapshot snapshot,
  ) {
    // Sleep: promedio de DailyTracking (últimas 4 semanas)
    // NOTA: DailyTrackingRecord actual no tiene campo sleep
    // Usar TrainingProfile.avgSleepHours como fallback
    double? avgSleepHours = snapshot.trainingProfile?.avgSleepHours;

    // Sleep category
    String? sleepCategory;
    if (avgSleepHours != null) {
      if (avgSleepHours < 5) {
        sleepCategory = '<5h';
      } else if (avgSleepHours < 7) {
        sleepCategory = '5-7h';
      } else if (avgSleepHours <= 9) {
        sleepCategory = '7-9h';
      } else {
        sleepCategory = '>9h';
      }
    }

    // Physical stress: desde TrainingProfile.extra
    int? physicalStress;
    final extra = snapshot.trainingProfile?.extra;
    if (extra != null) {
      physicalStress =
          _readInt(extra, [TrainingInterviewKeys.physicalStress], null);
    }

    // Non-physical stress: desde TrainingProfile.extra
    int? nonPhysicalStress;
    if (extra != null) {
      nonPhysicalStress =
          _readInt(extra, [TrainingInterviewKeys.nonPhysicalStress], null);
    }

    // HRV y RHR: promedio de DailyTracking
    // NOTA: DailyTrackingRecord actual no tiene estos campos
    // TODO: Implementar cuando se agreguen a DailyTrackingRecord
    double? avgHRV;
    double? avgRHR;

    // Ajustes Israetel por sueño
    double sleepAdjVME = 1.0;
    double sleepAdjVMR = 1.0;
    if (avgSleepHours != null) {
      if (avgSleepHours < 6) {
        // Muy poco sueño: -20% VME/VMR
        sleepAdjVME = 0.80;
        sleepAdjVMR = 0.80;
      } else if (avgSleepHours < 7) {
        // Poco sueño: -10% VME/VMR
        sleepAdjVME = 0.90;
        sleepAdjVMR = 0.90;
      } else if (avgSleepHours > 9) {
        // Mucho sueño: +5% VME/VMR
        sleepAdjVME = 1.05;
        sleepAdjVMR = 1.05;
      }
      // 7-9h: normal (1.0)
    }

    // Ajustes por estrés
    double stressAdjVME = 1.0;
    double stressAdjVMR = 1.0;
    if (physicalStress != null || nonPhysicalStress != null) {
      final totalStress = (physicalStress ?? 0) + (nonPhysicalStress ?? 0);
      if (totalStress > 7) {
        // Estrés alto: -15% VME/VMR
        stressAdjVME = 0.85;
        stressAdjVMR = 0.85;
      }
    }

    return {
      'avgSleepHours': avgSleepHours,
      'sleepCategory': sleepCategory,
      'physicalStress': physicalStress,
      'nonPhysicalStress': nonPhysicalStress,
      'avgHRV': avgHRV,
      'avgRHR': avgRHR,
      'sleepAdjustmentVME': sleepAdjVME,
      'sleepAdjustmentVMR': sleepAdjVMR,
      'stressAdjustmentVME': stressAdjVME,
      'stressAdjustmentVMR': stressAdjVMR,
    };
  }

  // =========================================================================
  // E) TRAINING EXPERIENCE
  // =========================================================================

  static Map<String, dynamic> _extractTrainingExperience(
    ClientDataSnapshot snapshot,
  ) {
    final years = snapshot.trainingProfile?.yearsTrainingContinuous ?? 0;

    // Effective level: calculado desde años + fuerza + volumen
    // Simplificación: usar años como proxy
    String? effectiveLevel;
    String? subpopulation;

    if (years < 1) {
      effectiveLevel = 'beginner';
      subpopulation = 'novice';
    } else if (years < 3) {
      effectiveLevel = 'intermediate';
      subpopulation = 'beginner';
    } else if (years < 6) {
      effectiveLevel = 'advanced';
      subpopulation = 'intermediate';
    } else if (years < 10) {
      effectiveLevel = 'advanced';
      subpopulation = 'advanced';
    } else {
      effectiveLevel = 'expert';
      subpopulation = 'elite';
    }

    // Program novelty: comparar plan actual vs anteriores
    // TODO: Implementar comparación de planes
    double programNovelty = 0.0;

    // Ajustes Israetel por experiencia
    double expAdjVME = 1.0;
    double expAdjVMR = 1.0;

    if (years < 1) {
      // Principiantes: -20% VME/VMR
      expAdjVME = 0.80;
      expAdjVMR = 0.80;
    } else if (years >= 6) {
      // Avanzados: +15% VME/VMR
      expAdjVME = 1.15;
      expAdjVMR = 1.15;
    }
    // Intermedios (1-6 años): normal (1.0)

    // Ajustes por novedad del programa
    double noveltyAdjVME = 1.0;
    double noveltyAdjVMR = 1.0;

    if (programNovelty > 0.7) {
      // Programa muy nuevo: -15% VME/VMR
      noveltyAdjVME = 0.85;
      noveltyAdjVMR = 0.85;
    }

    return {
      'effectiveLevel': effectiveLevel,
      'subpopulation': subpopulation,
      'programNovelty': programNovelty,
      'experienceAdjustmentVME': expAdjVME,
      'experienceAdjustmentVMR': expAdjVMR,
      'noveltyAdjustmentVME': noveltyAdjVME,
      'noveltyAdjustmentVMR': noveltyAdjVMR,
    };
  }

  // =========================================================================
  // F) HISTORICAL VOLUME (ML)
  // =========================================================================

  static Map<String, ObservedVolumeLimits> _extractHistoricalVolume(
    ClientDataSnapshot snapshot,
  ) {
    // TODO: Implementar cálculo de límites desde SessionLogs
    // Requiere:
    // 1. Agrupar logs por músculo
    // 2. Calcular sets/semana promedio por semana
    // 3. Identificar MEV (mínimo efectivo), MAV (máximo adaptativo), MRV (máximo recuperable)
    // 4. Calcular confianza basada en cantidad de datos

    return {};
  }

  // =========================================================================
  // H) REST & RECOVERY HELPERS
  // =========================================================================

  static double _calculateRestAdjustment(int? restSeconds) {
    if (restSeconds == null) return 1.0;

    // Israetel: descanso corto (<120s) genera más fatiga
    if (restSeconds < 120) {
      return 1.8; // 80% más fatiga
    }

    return 1.0;
  }

  // =========================================================================
  // UTILITY HELPERS
  // =========================================================================

  /// Lee un entero desde un map con múltiples claves posibles
  static int? _readInt(
    Map<String, dynamic> map,
    List<String> keys,
    int? fallback,
  ) {
    for (final key in keys) {
      if (map.containsKey(key)) {
        final value = map[key];
        if (value is int) return value;
        if (value is num) return value.toInt();
        if (value is String) {
          final parsed = int.tryParse(value);
          if (parsed != null) return parsed;
        }
      }
    }
    return fallback;
  }
}
