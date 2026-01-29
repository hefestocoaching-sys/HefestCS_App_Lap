import 'dart:math';

import 'package:hcs_app_lap/core/enums/gender.dart';

import '../entities/anthropometry_analysis_result.dart';
import '../entities/anthropometry_record.dart';

class AnthropometryAnalyzer {
  /// SUM6 preferente para Yuhasz: TR + SB + AB + TH + CA + (supraspinal o suprailiaco).
  double? sumOfSkinfolds(AnthropometryRecord r) {
    final supra = r.supraspinalFold ?? r.suprailiacFold;
    final list = [
      r.tricipitalFold,
      r.subscapularFold,
      supra,
      r.abdominalFold,
      r.thighFold,
      r.calfFold,
    ];
    if (list.any((e) => e == null || (e) <= 0)) return null;
    return list.whereType<double>().fold<double>(0.0, (p, e) => p + e);
  }

  double? _yuhaszBodyFat(double sum6, Gender? gender) {
    if (gender == null) return null;
    final isMale = gender == Gender.male;
    final result = isMale ? 0.1051 * sum6 + 2.585 : 0.1548 * sum6 + 3.580;
    if (result.isNaN || result.isInfinite) return null;
    return result;
  }

  /// % grasa Jackson & Pollock 4 sitios (triceps, abdominal, muslo, suprailiaco).
  double? _jacksonPollock4(
    double triceps,
    double abdominal,
    double thigh,
    double suprailiac,
    int age,
    Gender gender,
  ) {
    final s = triceps + abdominal + thigh + suprailiac;
    if (gender == Gender.male) {
      return 0.29288 * s - 0.0005 * s * s + 0.15845 * age - 5.76377;
    }
    return 0.29669 * s - 0.00043 * s * s + 0.02963 * age + 1.4072;
  }

  /// Relacion cintura/cadera
  double? waistHipRatio(double? waist, double? hip) {
    if (waist == null || hip == null || hip == 0) return null;
    return waist / hip;
  }

  /// Clasificacion de cintura/cadera
  String classifyWaistHip(double ratio, String gender) {
    final isMale = parseGender(gender) == Gender.male;
    if (isMale) {
      if (ratio < 0.9) return "Normal";
      if (ratio < 1.0) return "Riesgo moderado";
      return "Alto riesgo cardiometabolico";
    } else {
      if (ratio < 0.8) return "Normal";
      if (ratio < 0.85) return "Riesgo moderado";
      return "Alto riesgo cardiometabolico";
    }
  }

  double? _bmi(double? weightKg, double? heightCm) {
    if (weightKg == null || heightCm == null || heightCm == 0) return null;
    final h = heightCm / 100.0;
    if (h <= 0) return null;
    return weightKg / (h * h);
  }

  String? _classifyBmi(double? bmi) {
    if (bmi == null) return null;
    if (bmi < 18.5) return "Bajo peso";
    if (bmi < 25) return "Normal";
    if (bmi < 30) return "Sobrepeso";
    return "Obesidad";
  }

  double? _muscleIndex(double? muscleKg, double? heightCm) {
    if (muscleKg == null || heightCm == null || heightCm <= 0) return null;
    final meters = heightCm / 100;
    return muscleKg / (meters * meters);
  }

  String? _classifyMuscleIndex(double? muscleIndex, Gender? gender) {
    if (muscleIndex == null) return null;
    final isMale = gender == Gender.male;
    final low = isMale ? 7.0 : 5.7;
    final high = isMale ? 9.5 : 7.5;
    if (muscleIndex < low) return "Bajo";
    if (muscleIndex < high) return "Adecuado";
    return "Alto";
  }

  /// Masa grasa = peso * %grasa
  double? _fatMassKg(double? weight, double? bfPercent) {
    if (weight == null || bfPercent == null) return null;
    return weight * (bfPercent / 100);
  }

  /// Masa magra
  double? _leanMassKg(double? weight, double? fatMass) {
    if (weight == null || fatMass == null) return null;
    return weight - fatMass;
  }

  double? _boneMassKgRocha({
    required double? heightCm,
    required double? wristDiameterCm,
    required double? kneeDiameterCm,
  }) {
    if (heightCm == null ||
        wristDiameterCm == null ||
        kneeDiameterCm == null ||
        heightCm <= 0 ||
        wristDiameterCm <= 0 ||
        kneeDiameterCm <= 0) {
      return null;
    }
    final composite = pow(
      heightCm * heightCm * wristDiameterCm * kneeDiameterCm * 400,
      0.712,
    );
    if (composite.isNaN || composite.isInfinite) return null;
    return 3.02 * composite;
  }

  double? _boneMassKg({
    required double? weightKg,
    required double? heightCm,
    required double? wristDiameterCm,
    required double? kneeDiameterCm,
  }) {
    if (weightKg == null) return null;

    // Intento Rocha con chequeo de plausibilidad (5%-30% del peso)
    final rocha = _boneMassKgRocha(
      heightCm: heightCm,
      wristDiameterCm: wristDiameterCm,
      kneeDiameterCm: kneeDiameterCm,
    );
    if (rocha != null) {
      final minKg = weightKg * 0.05;
      final maxKg = weightKg * 0.30;
      if (rocha >= minKg && rocha <= maxKg) {
        return rocha;
      }
    }

    // Fallback historico (~14% del peso ajustado por frame)
    const baseFraction = 0.14;
    if (heightCm == null ||
        heightCm <= 0 ||
        wristDiameterCm == null ||
        kneeDiameterCm == null) {
      return weightKg * baseFraction;
    }

    final boneIndex = (wristDiameterCm + kneeDiameterCm) / heightCm;
    const referenceIndex = 0.077;

    double frameFactor = boneIndex / referenceIndex;
    frameFactor = frameFactor.clamp(0.8, 1.2);

    return weightKg * baseFraction * frameFactor;
  }

  /// Masa muscular Lee 2000 (modelo 1) cuando hay datos completos
  double? _muscleMassLeeModel({
    required double? armFlexedCirc,
    required double? midThighCirc,
    required double? maxCalfCirc,
    required double? tricepsMm,
    required double? thighMm,
    required double? calfMm,
    required double? heightCm,
    required int? age,
    required Gender? gender,
  }) {
    if (armFlexedCirc == null ||
        midThighCirc == null ||
        maxCalfCirc == null ||
        tricepsMm == null ||
        thighMm == null ||
        calfMm == null ||
        heightCm == null ||
        age == null ||
        age <= 0 ||
        heightCm <= 0) {
      return null;
    }

    final tr = tricepsMm / 10;
    final th = thighMm / 10;
    final ca = calfMm / 10;

    final cag = armFlexedCirc - pi * tr;
    final ctg = midThighCirc - pi * th;
    final ccg = maxCalfCirc - pi * ca;

    if (cag <= 0 || ctg <= 0 || ccg <= 0) return null;

    final sex = (gender ?? Gender.other) == Gender.male ? 1 : 0;
    const race = 0.0; // placeholder (0 por defecto)
    final ht = heightCm / 100;

    final sm =
        ht *
            (0.00744 * pow(cag, 2) +
                0.00088 * pow(ctg, 2) +
                0.00441 * pow(ccg, 2)) +
        2.4 * sex -
        0.048 * age +
        race +
        7.8;

    if (sm.isNaN || sm.isInfinite) return null;
    return sm;
  }

  /// Masa muscular aproximada (fallback 4C simplificado)
  double? _fallbackMuscleMassKg({
    required double? leanMassKg,
    required double? boneMassKg,
    required double? weightKg,
  }) {
    if (leanMassKg == null || weightKg == null) return null;
    if (boneMassKg != null) {
      // Residual ~20% del peso (Ross/Drinkwater)
      final residual = weightKg * 0.20;
      final muscle = leanMassKg - boneMassKg - residual;
      return muscle > 0 ? muscle : null;
    }
    return leanMassKg * 0.60; // aproximacion fija cuando no hay datos oseos
  }

  double? _percent(double? part, double? total) {
    if (part == null || total == null || total == 0) return null;
    return (part / total) * 100;
  }

  /// Estimacion simple de potencial natural LBM (placeholder basado en multiplicador)
  Map<String, double?> _naturalPotential({
    required double? leanMassKg,
    required double? muscleMassKg,
    required double? boneMassKg,
    required Gender gender,
  }) {
    // Si no tenemos hueso, caemos al comportamiento viejo (lean * 1.15)
    if (boneMassKg == null || boneMassKg <= 0) {
      if (leanMassKg == null) {
        return {'potential': null, 'percent': null};
      }
      final potential = leanMassKg * 1.15;
      final percent = potential > 0 ? (leanMassKg / potential) * 100 : null;
      return {'potential': potential, 'percent': percent};
    }

    // Potencial muscular "natural" (kg) en funcion del hueso
    final musclePotentialKg = boneMassKg * (gender == Gender.male ? 3.4 : 3.1);

    // Estimamos LBM potencial sumando:
    // - musculo potencial
    // - el resto de LBM (osea + residual) basado en la LBM actual si la tenemos
    double potentialLbm;

    if (leanMassKg != null && muscleMassKg != null) {
      final nonMuscleLbm = leanMassKg - muscleMassKg;
      potentialLbm = musclePotentialKg + (nonMuscleLbm > 0 ? nonMuscleLbm : 0);
    } else if (leanMassKg != null) {
      // Si no sabemos musculo actual, usamos un fallback suave
      potentialLbm = leanMassKg * 1.15;
    } else {
      // Fallback total: musculo potencial + hueso
      potentialLbm = musclePotentialKg + boneMassKg;
    }

    final current = leanMassKg ?? muscleMassKg;
    final percent = (current != null && potentialLbm > 0)
        ? (current / potentialLbm) * 100
        : null;

    return {'potential': potentialLbm, 'percent': percent};
  }

  AnthropometryAnalysisResult analyze({
    required AnthropometryRecord record,
    required int? age,
    required String? gender,
  }) {
    final sumSkf = sumOfSkinfolds(record);
    final parsedGender = parseGender(gender ?? '');

    double? bodyFat;

    // 1. Intentar leer estimación básica (si existe)
    final basicBodyFatList = record.individualMeasurements?['basicBodyFat'];
    if (basicBodyFatList != null && basicBodyFatList.isNotEmpty) {
      final basicValue = basicBodyFatList.first;
      if (basicValue is double && basicValue > 0) {
        bodyFat = basicValue;
      }
    }

    // 2. Si no hay estimación básica, intentar Yuhasz
    if (bodyFat == null && sumSkf != null && parsedGender != null) {
      bodyFat = _yuhaszBodyFat(sumSkf, parsedGender);
    }

    final hasJacksonPollock4 =
        age != null &&
        parsedGender != null &&
        record.tricipitalFold != null &&
        record.abdominalFold != null &&
        record.thighFold != null &&
        record.suprailiacFold != null &&
        record.tricipitalFold! > 0 &&
        record.abdominalFold! > 0 &&
        record.thighFold! > 0 &&
        record.suprailiacFold! > 0;

    // 3. Si no hay Yuhasz ni básica, intentar Jackson-Pollock 4
    if (bodyFat == null && hasJacksonPollock4) {
      bodyFat = _jacksonPollock4(
        record.tricipitalFold!,
        record.abdominalFold!,
        record.thighFold!,
        record.suprailiacFold!,
        age,
        parsedGender,
      );
    } else if (bodyFat == null &&
        sumSkf != null &&
        age != null &&
        gender != null) {
      // Fallback a ecuacion previa simplificada si falta algun pliegue clave.
      bodyFat = _legacyEstimateBodyFat(sumSkf, age, gender);
    }

    final fat = _fatMassKg(record.weightKg, bodyFat);
    final lean = _leanMassKg(record.weightKg, fat);
    double? leanPercent = _percent(lean, record.weightKg);
    leanPercent ??= bodyFat != null ? 100 - bodyFat : null;

    final bmi = _bmi(record.weightKg, record.heightCm);
    final bmiCategory = _classifyBmi(bmi);

    final boneMass = _boneMassKg(
      weightKg: record.weightKg,
      heightCm: record.heightCm,
      wristDiameterCm: record.wristDiameter,
      kneeDiameterCm: record.kneeDiameter,
    );

    final muscleMassLee = _muscleMassLeeModel(
      armFlexedCirc: record.armFlexedCirc,
      midThighCirc: record.midThighCirc,
      maxCalfCirc: record.maxCalfCirc,
      tricepsMm: record.tricipitalFold,
      thighMm: record.thighFold,
      calfMm: record.calfFold,
      heightCm: record.heightCm,
      age: age,
      gender: parsedGender,
    );

    final muscleMass =
        muscleMassLee ??
        _fallbackMuscleMassKg(
          leanMassKg: lean,
          boneMassKg: boneMass,
          weightKg: record.weightKg,
        );

    final musclePercent = _percent(muscleMass, record.weightKg);
    final bonePercent = _percent(boneMass, record.weightKg);
    final muscleBoneRatio =
        (muscleMass != null && boneMass != null && boneMass > 0)
        ? muscleMass / boneMass
        : null;

    final muscleIdx = _muscleIndex(muscleMass, record.heightCm);
    final muscleIdxClass = _classifyMuscleIndex(muscleIdx, parsedGender);

    final natural = _naturalPotential(
      leanMassKg: lean,
      muscleMassKg: muscleMass,
      boneMassKg: boneMass,
      gender: parsedGender ?? Gender.other,
    );

    final ratio = waistHipRatio(record.waistCircNarrowest, record.hipCircMax);
    final ratioClass = ratio != null && gender != null
        ? classifyWaistHip(ratio, gender)
        : null;

    double? visceralMass;
    double? visceralPercent;
    if (record.weightKg != null &&
        fat != null &&
        boneMass != null &&
        muscleMass != null) {
      final residual = record.weightKg! - (fat + boneMass + muscleMass);
      if (residual >= 0) {
        visceralMass = residual;
        visceralPercent = _percent(residual, record.weightKg);
      }
    }

    final overall = _overallInterpretation(bodyFat, ratio, ratioClass);

    return AnthropometryAnalysisResult(
      sumOfSkinfolds: sumSkf,
      bodyFatPercentage: bodyFat,
      fatMassKg: fat,
      leanMassKg: lean,
      leanMassPercent: leanPercent,
      bmi: bmi,
      bmiCategory: bmiCategory,
      muscleMassKg: muscleMass,
      muscleMassPercent: musclePercent,
      muscleIndex: muscleIdx,
      muscleIndexClass: muscleIdxClass,
      boneMassKg: boneMass,
      boneMassPercent: bonePercent,
      visceralMassKg: visceralMass,
      visceralMassPercent: visceralPercent,
      muscleBoneRatio: muscleBoneRatio,
      naturalLbmPotentialKg: natural['potential'],
      naturalLbmPotentialPercent: natural['percent'],
      waistHipRatio: ratio,
      waistHipClassification: ratioClass,
      overallInterpretation: overall,
    );
  }

  double? _legacyEstimateBodyFat(double sumSkinfolds, int age, String gender) {
    final isMale = parseGender(gender) == Gender.male;
    if (isMale) {
      return 0.000807 * sumSkinfolds +
          0.000002 * pow(sumSkinfolds, 2) -
          0.0003 * age +
          8.0;
    } else {
      return 0.000490 * sumSkinfolds +
          0.000002 * pow(sumSkinfolds, 2) -
          0.0003 * age +
          16.0;
    }
  }

  String? _overallInterpretation(
    double? bf,
    double? ratio,
    String? ratioClass,
  ) {
    if (bf == null) return null;
    if (bf > 30) {
      return "Alto porcentaje de grasa. Enfoque recomendado: deficit calorico + fuerza.";
    }
    if (bf > 25) return "Ligeramente elevado. Posible recomposicion corporal.";
    if (bf >= 15) return "Rango saludable.";
    if (bf >= 10) return "Atleta / definido.";
    return "Extremadamente bajo -> posible riesgo hormonal.";
  }
}
