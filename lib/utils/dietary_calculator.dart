import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:hcs_app_lap/utils/client_extensions.dart';
import 'package:hcs_app_lap/domain/entities/tmb_recommendation.dart';

import '../domain/entities/client.dart';

class DietaryCalculator {
  // ============================================
  // NORMALIZADORES — FUENTES ÚNICAS (P0)
  // ============================================

  /// Normaliza género desde múltiples formatos a booleano seguro
  /// Retorna: true = masculino, false = femenino
  /// MAPEO:
  ///   "Hombre", "Masculino", "male", "Male" → true (M)
  ///   "Mujer", "Femenino", "female", "Female" → false (F)
  /// Fallback: false (conservador)
  static bool _normalizeGenderToMale(String? rawGender) {
    if (rawGender == null || rawGender.isEmpty) return false;
    final normalized = rawGender.toLowerCase().trim();
    // Variantes masculinas
    if (normalized == 'hombre' ||
        normalized == 'masculino' ||
        normalized == 'male' ||
        normalized == 'm') {
      return true;
    }
    // Variantes femeninas (incluyendo fallback)
    return false;
  }

  /// Resuelve edad desde fuente única y estable
  /// REGLA:
  ///   1. Si age > 0 → usarla (explícita)
  ///   2. Si no, calcular desde birthDate
  ///   3. Si no hay ambas → retornar 0 (bloquea cálculos)
  ///
  /// NOTA: Esta implementación en DietaryCalculator está DEPRECADA.
  /// La función está duplicada en DietaryProvider._resolveFinalAge para mayor
  /// cohesión. Se mantiene aquí como referencia únicamente.
  // ignore: unused_element
  static int _resolveFinalAge(int? explicitAge, DateTime? birthDate) {
    // Regla 1: Si hay edad explícita y válida, usarla
    if (explicitAge != null && explicitAge > 0) {
      if (kDebugMode) {
        debugPrint('[DietaryCalculator] Edad usada (explícita): $explicitAge');
      }
      return explicitAge;
    }

    // Regla 2: Si hay fecha de nacimiento, calcular con precisión
    if (birthDate != null) {
      final today = DateTime.now();
      int calculatedAge = today.year - birthDate.year;
      // Ajustar si el cumpleaños aún no ha ocurrido este año
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        calculatedAge--;
      }
      // Validar que la edad calculada sea razonable (3-130 años)
      if (calculatedAge > 0 && calculatedAge < 130) {
        if (kDebugMode) {
          debugPrint(
            '[DietaryCalculator] Edad calculada desde birthDate: $calculatedAge '
            '(dob: ${birthDate.toString().split(' ')[0]})',
          );
        }
        return calculatedAge;
      }
    }

    // Regla 3: Fallback seguro (bloquea cálculos)
    if (kDebugMode) {
      debugPrint(
        '[DietaryCalculator] ⚠️ ADVERTENCIA: No hay edad explícita ni birthDate válida. '
        'Bloqueando cálculo TMB.',
      );
    }
    return 0;
  }

  // --- 1. TASA METABÓLICA BASAL (TMB) ---

  // Fórmula 1: Mifflin-St. Jeor
  // ✅ NORMALIZADO: Usa género enum-safe + edad resuelta
  static double calculateMifflin(
    double weightKg,
    double heightCm,
    int age,
    String gender,
  ) {
    if (weightKg <= 0 || heightCm <= 0 || age <= 0) return 0.0;

    final isMale = _normalizeGenderToMale(gender);
    double base = (10 * weightKg) + (6.25 * heightCm) - (5 * age);

    // ✅ Mifflin: +5 (M) o -161 (F)
    return isMale ? base + 5 : base - 161;
  }

  // Fórmula 2: Harris-Benedict
  // ✅ NORMALIZADO: Usa género enum-safe
  static double calculateHarrisBenedict(
    double weightKg,
    double heightCm,
    int age,
    String gender,
  ) {
    if (weightKg <= 0 || heightCm <= 0 || age <= 0) return 0.0;

    final isMale = _normalizeGenderToMale(gender);
    return isMale
        ? 66.5 + (13.75 * weightKg) + (5.003 * heightCm) - (6.755 * age)
        : 655.1 + (9.563 * weightKg) + (1.850 * heightCm) - (4.676 * age);
  }

  // Fórmula 3: Katch-McArdle
  static double calculateKatchMcArdle(double leanBodyMassKg) {
    if (leanBodyMassKg <= 0) return 0.0;
    return 370 + (21.6 * leanBodyMassKg);
  }

  // Fórmula 4: Cunningham
  static double calculateCunningham(double leanBodyMassKg) {
    if (leanBodyMassKg <= 0) return 0.0;
    return 500 + (22 * leanBodyMassKg);
  }

  // Fórmula 5: Mifflin Ajustado (Obesidad)
  // ✅ NORMALIZADO: Usa género enum-safe
  static double calculateMifflinAdjusted(
    double weightKg,
    double heightCm,
    int age,
    String gender,
    double bodyFatPercentage,
  ) {
    if (weightKg <= 0 || heightCm <= 0 || age <= 0) {
      return 0.0;
    }

    final isMale = _normalizeGenderToMale(gender);
    final hasBodyFat = bodyFatPercentage > 0;
    final bool useAdjustedFromBodyFat =
        hasBodyFat &&
        ((isMale && bodyFatPercentage > 30) ||
            (!isMale && bodyFatPercentage > 35));

    final double heightInches = heightCm / 2.54;
    double ibw = isMale
        ? (50 + 2.3 * (heightInches - 60))
        : (45.5 + 2.3 * (heightInches - 60));
    ibw = max(40.0, ibw);

    // Peso ajustado:
    // - Con %grasa válido: ajuste clásico 40%
    // - Sin %grasa: ajuste conservador 25% sobre exceso de peso (ABW)
    double adjustedBodyWeight = useAdjustedFromBodyFat
        ? ibw + 0.4 * (weightKg - ibw)
        : ibw + 0.25 * (weightKg - ibw);

    double weightToUse = adjustedBodyWeight > 0 ? adjustedBodyWeight : weightKg;
    double base = (10 * weightToUse) + (6.25 * heightCm) - (5 * age);
    final result = isMale ? base + 5 : base - 161;
    return result > 0 ? result : 0.0;
  }

  // Fórmula 6: Tinsley
  // ✅ NORMALIZADO: Usa género enum-safe
  static double calculateTinsley(double leanBodyMassKg, String gender) {
    if (leanBodyMassKg <= 0) return 0.0;

    final isMale = _normalizeGenderToMale(gender);
    return isMale
        ? (24.6 * leanBodyMassKg) + 466
        : (25.1 * leanBodyMassKg) + 514;
  }

  // --- Implementaciones Adicionales ---

  // Fórmula 7: Henry (Oxford) - Simplificada
  // ✅ NORMALIZADO: Usa género enum-safe
  static double calculateHenryOxford(double weightKg, int age, String gender) {
    if (weightKg <= 0 || age < 3) return 0.0;

    final isMale = _normalizeGenderToMale(gender);

    // Ecuaciones por género (normalizado)
    if (isMale) {
      if (age >= 18 && age <= 29) return (15.057 * weightKg) + 692.2;
      if (age >= 30 && age <= 59) return (11.472 * weightKg) + 873.1;
      if (age >= 60) return (11.711 * weightKg) + 587.7;
    } else {
      // Femenino
      if (age >= 18 && age <= 29) return (14.818 * weightKg) + 486.6;
      if (age >= 30 && age <= 59) return (8.126 * weightKg) + 845.6;
      if (age >= 60) return (9.082 * weightKg) + 658.5;
    }
    debugPrint("Advertencia: Henry (Oxford) usando ecuaciones simplificadas.");
    return 0.0; // Rango de edad no cubierto o no aplicable
  }

  // Fórmula 8: Müller (Obesidad)
  // ✅ NORMALIZADO: Usa género enum-safe
  static double calculateMullerObesity(
    double weightKg,
    double leanBodyMassKg,
    int age,
    String gender,
  ) {
    if (weightKg <= 0 ||
        leanBodyMassKg <= 0 ||
        leanBodyMassKg >= weightKg ||
        age <= 0) {
      debugPrint(
        "Advertencia: Müller (Obesidad) requiere peso, MLG y edad válidos.",
      );
      return 0.0;
    }

    final isMale = _normalizeGenderToMale(gender);
    double fatMassKg = weightKg - leanBodyMassKg;
    int sexFactor = isMale ? 1 : 0;

    // Fórmula de Müller et al. 2004 (simplificada)
    double tmb =
        (13.587 * leanBodyMassKg) +
        (9.613 * fatMassKg) +
        (198 * sexFactor) -
        (3.351 * age) +
        674;
    return tmb > 0 ? tmb : 0.0;
  }

  // Fórmulas Clínicas Eliminadas (PSU, Ireton-Jones)

  // Fórmula Consenso - Promedio de Fórmulas Seleccionadas VÁLIDAS
  static double calculateTMBMean(List<double> selectedTmbs) {
    if (selectedTmbs.isEmpty) return 0.0;
    final validTmbs = selectedTmbs.where((tmb) => tmb > 0).toList();
    if (validTmbs.isEmpty) return 0.0;
    final sum = validTmbs.reduce((a, b) => a + b);
    return sum / validTmbs.length;
  }

  // --- 2. GASTO ENERGÉTICO TOTAL (GET) BASADO EN NAF y METs ---
  /// Calcula GET = TMB * NAF + EAT (sin doble conteo de masa corporal)
  ///
  /// FÓRMULA:
  /// - GET = TMB + (TMB * (NAF - 1)) + EAT
  /// - EAT = metMinutesPerDay * bodyWeightKg * 0.0175
  ///
  /// NOTA CIENTÍFICA (Helms, Pyramid 2.0):
  /// - EAT debe usar peso corporal TOTAL, no masa libre de grasa
  /// - NAF es el multiplicador de actividad (no incluye ejercicio, solo NEAT)
  /// - No usar TMB/24 como fallback para masa: si no hay peso, retornar 0
  static double calculateTotalEnergyExpenditure({
    required double tmb,
    required double selectedNafFactor,
    required double metMinutesPerDay,
    required double bodyWeightKg,
  }) {
    if (tmb <= 0 || bodyWeightKg <= 0) return 0.0;
    final nafAdjustmentKcal = tmb * (selectedNafFactor - 1.0);
    // Corrección científica: EAT debe usar peso corporal real, no masa libre de grasa
    final eatKcal = metMinutesPerDay * bodyWeightKg * 0.0175;
    return tmb + nafAdjustmentKcal + eatKcal;
  }

  // --- 3. DISTRIBUCIÓN DE MACRONUTRIENTES (POR G/KG - Método Determinista) ---
  /// Distribuye calorías objetivo entre macronutrientes de forma determinista
  ///
  /// FLUJO (Helms, Pyramid 2.0 - Nivel 1: Calorías soberanas):
  /// 1. Fijar proteína: g/kg × peso corporal
  /// 2. Fijar grasa: g/kg × peso corporal
  /// 3. Calcular carbohidratos: calorías restantes ÷ 4
  ///
  /// NOTA CRÍTICA:
  /// - El objetivo calórico es soberano (no se redistribuye para "corregir" TEF)
  /// - Se eliminó factor 0.925 opaco que causaba discrepancias
  /// - TEF natural se captura en el objetivo general, no como corrección posterior
  static Map<String, double> distributeMacrosByGrams({
    required double gastoNetoObjetivo,
    required double pesoCorporal,
    required double gProteinaPorKg,
    required double gGrasaPorKg,
  }) {
    if (pesoCorporal <= 0 || gastoNetoObjetivo <= 0) {
      return {
        'proteinGrams': 0,
        'fatGrams': 0,
        'carbGrams': 0,
        'totalKcalToConsume': 0,
      };
    }

    // Corrección científica: flujo directo sin factor opaco
    final gramosProteina = gProteinaPorKg * pesoCorporal;
    final kcalProteina = gramosProteina * 4.0;

    final gramosGrasa = gGrasaPorKg * pesoCorporal;
    final kcalGrasa = gramosGrasa * 9.0;

    // Carbohidratos remanentes (sin redistribuciones ocultas)
    final kcalRestantes = gastoNetoObjetivo - kcalProteina - kcalGrasa;
    final gramosCarbs = (kcalRestantes > 0) ? kcalRestantes / 4.0 : 0.0;

    return {
      'proteinGrams': gramosProteina,
      'fatGrams': gramosGrasa,
      'carbGrams': gramosCarbs,
      'totalKcalToConsume': gastoNetoObjetivo,
    };
  }

  // --- Función de Déficit ---
  static double calculateDeficitForWeightGoal(double weightGoalKg, int days) {
    if (days <= 0) return 0.0;
    final kcalPerGoal = weightGoalKg * 7700.0;
    return kcalPerGoal / days;
  }

  // --- 4. FUNCIÓN DE RECOMENDACIÓN DE FÓRMULA TMB ---
  static TMBRecommendation recommendTMBFormula(Client client) {
    final age = client.age ?? 30;
    final gender = client.gender ?? 'Hombre';
    final level = client.clientLevel ?? 'Recreativo/Salud';
    final history = client.personalPathologicalHistory ?? [];
    final latestAnt = client.latestAnthropometryRecord;

    final hasLBM = (latestAnt?.leanBodyMassKg ?? 0.0) > 0;
    final bfp = latestAnt?.bodyFatPercentage ?? 0.0;
    final weightKg = latestAnt?.weightKg ?? 0.0;
    final heightCm = latestAnt?.heightCm ?? 0.0;

    final isObese =
        (history.contains('Obesidad')) ||
        (gender == 'Hombre' && bfp > 30) ||
        (gender == 'Mujer' && bfp > 35);

    String profileSummary = '$gender de $age años, nivel $level.';

    // --- Lógica de Decisión Jerárquica ---

    // 1. Atletas con datos de composición corporal
    if (hasLBM &&
        (level == 'Competidor Amateur' || level == 'Profesional/Élite')) {
      final lbm = latestAnt?.leanBodyMassKg ?? 0.0;
      return TMBRecommendation(
        formulaKey: 'Tinsley',
        title: '🏋️ Fórmula para Atletas de Alto Rendimiento',
        clientProfileSummary:
            '$profileSummary\n📊 Masa Libre de Grasa: ${lbm.toStringAsFixed(1)} kg\n📈 % Grasa Corporal: ${bfp.toStringAsFixed(1)}%',
        reasoning:
            '🔬 Fundamento Científico:\n\n'
            '• La fórmula de Tinsley es específica para atletas de fuerza y fisiculturistas, basándose en MLG (masa libre de grasa) en lugar del peso total.\n\n'
            '• PRECISIÓN: 62% de la variación en TMB se explica por diferencias en MLG (Johnstone et al., 2005).\n\n'
            '• VENTAJA: Elimina la sobrestimación que ocurre con fórmulas convencionales en individuos con masa muscular superior a la media.\n\n'
            '• APLICACIÓN: Específicamente validada para atletas que realizan entrenamiento de resistencia intenso.',
        alternativeConsiderations:
            '💡 Alternativas Válidas:\n\n'
            '• Katch-McArdle: También basada en MLG (R² = 0.64 con TMB medido).\n\n'
            '• Cunningham: Misma ecuación que Katch-McArdle, comúnmente citada para deportistas.\n\n'
            '⚠️ NO se recomienda:\n'
            '• Mifflin-St. Jeor puede subestimar hasta un 15% el gasto energético en atletas con alta masa muscular.',
      );
    }

    // 2. Población con obesidad y datos de composición corporal
    if (isObese && hasLBM) {
      final lbm = latestAnt?.leanBodyMassKg ?? 0.0;
      return TMBRecommendation(
        formulaKey: 'Müller (Obesidad)',
        title: '⚕️ Fórmula Especializada para Obesidad',
        clientProfileSummary:
            '$profileSummary\n⚖️ Peso actual: ${weightKg.toStringAsFixed(1)} kg\n📊 MLG disponible: ${lbm.toStringAsFixed(1)} kg\n📈 % Grasa: ${bfp.toStringAsFixed(1)}%',
        reasoning:
            '🔬 Validación Científica:\n\n'
            '• La fórmula de Müller (2001) fue diseñada específicamente para población con obesidad severa y mórbida.\n\n'
            '• PRECISIÓN MEJORADA: Diferencia entre masa grasa (metabólicamente menos activa) y MLG (tejido activo).\n\n'
            '• EVIDENCIA: En un estudio con 8,780 sujetos con obesidad, las ecuaciones basadas en MLG explicaron el 59-60% de la variación en TMB (Lazzer et al., 2010).\n\n'
            '• APLICACIÓN CLÍNICA: Reduce el error de sobrestimación que presentan las fórmulas convencionales basadas solo en peso total.',
        alternativeConsiderations:
            '💡 Opciones Secundarias:\n\n'
            '• Mifflin-St. Jeor con peso ajustado: Si MLG no estuviera disponible (requiere conocer % grasa).\n\n'
            '• Lazzer (2010): Ecuaciones específicas validadas en población italiana con obesidad.\n\n'
            '⚠️ EVITAR:\n'
            '• Harris-Benedict: Sobrestima TMB ~5% en obesidad (Frankenfield et al., 2005).\n'
            '• Fórmulas generales sin ajuste por composición corporal.',
      );
    }

    // 3. Población con obesidad sin datos de composición corporal
    if (isObese && weightKg > 0 && heightCm > 0 && bfp > 0) {
      return TMBRecommendation(
        formulaKey: 'Mifflin (Ajustado)',
        title: '⚕️ Mifflin-St. Jeor Ajustado para Obesidad',
        clientProfileSummary:
            '$profileSummary\n⚖️ Peso: ${weightKg.toStringAsFixed(1)} kg\n📏 Estatura: ${heightCm.toStringAsFixed(0)} cm\n📈 % Grasa estimado: ${bfp.toStringAsFixed(1)}%',
        reasoning:
            '🔬 Metodología de Ajuste:\n\n'
            '• PROBLEMA: En obesidad, el tejido adiposo tiene baja tasa metabólica (~4.5 kcal/kg/día) vs. tejido magro (~13 kcal/kg/día).\n\n'
            '• SOLUCIÓN: Ajuste de peso = Peso × (1 - %grasa/100) + (Peso × %grasa/100 × 0.35)\n\n'
            '• VALIDACIÓN: Mifflin-St. Jeor (1990) es la ecuación más fiable para obesidad cuando MLG no está disponible, prediciendo TMB dentro del ±10% en el 82% de casos (Frankenfield et al., 2005).\n\n'
            '• MEJORA vs. Harris-Benedict: ~5% más precisa y no sobreestima como la ecuación clásica de 1919.',
        alternativeConsiderations:
            '💡 Si dispones de MLG:\n\n'
            '• Müller (Obesidad): Fórmula específica para obesidad con datos de composición corporal.\n\n'
            '• Katch-McArdle: Alternativa basada exclusivamente en MLG.\n\n'
            '⚠️ Limitaciones:\n'
            '• El ajuste por porcentaje de grasa es una aproximación. La medición directa de MLG (DEXA, BIA) ofrece mayor precisión.',
      );
    }

    // 4. Adultos mayores
    if (age > 65) {
      return TMBRecommendation(
        formulaKey: 'Mifflin-St. Jeor',
        title: '👴 Ecuación para Adultos Mayores',
        clientProfileSummary:
            '$profileSummary\n⚖️ Peso: ${weightKg > 0 ? "${weightKg.toStringAsFixed(1)} kg" : "No registrado"}\n📏 Estatura: ${heightCm > 0 ? "${heightCm.toStringAsFixed(0)} cm" : "No registrada"}',
        reasoning:
            '🔬 Evidencia Gerontológica:\n\n'
            '• DECLIVE METABÓLICO: TMB disminuye ~1-2% por década después de los 20 años, principalmente por pérdida de masa libre de grasa (Manini, 2010).\n\n'
            '• ECUACIÓN ÓPTIMA: Mifflin-St. Jeor (1990) validada como la más precisa en adultos mayores, superando a Harris-Benedict en ~5% de exactitud.\n\n'
            '• CONSIDERACIÓN ESPECIAL: El factor edad (-5 kcal/año en hombres, -4.92 kcal/año en general) ajusta por cambios metabólicos asociados al envejecimiento.\n\n'
            '• META-ANÁLISIS: Frankenfield et al. (2005) confirmó que predice TMB dentro del ±10% en >70% de adultos mayores.',
        alternativeConsiderations:
            '💡 Optimización con Datos de Composición:\n\n'
            '• SARCOPENIA: Si se detecta pérdida muscular significativa, considerar Katch-McArdle con MLG medida.\n\n'
            '• LAZZER (2010): Ecuación específica que reduce el efecto del género en adultos mayores cuando se usa MLG.\n\n'
            '📊 Recomendación:\n'
            '• Medir MLG mediante BIA o DEXA puede mejorar precisión hasta R² = 0.71 (vs. 0.56 solo con peso).\n\n'
            '• Monitorear cambios en composición corporal cada 6-12 meses.',
      );
    }

    // 5. Caso por defecto: Población general
    return TMBRecommendation(
      formulaKey: 'Mifflin-St. Jeor',
      title: '⭐ Ecuación Estándar de Oro (Población General)',
      clientProfileSummary:
          '$profileSummary\n⚖️ Peso: ${weightKg > 0 ? "${weightKg.toStringAsFixed(1)} kg" : "No registrado"}\n📏 Estatura: ${heightCm > 0 ? "${heightCm.toStringAsFixed(0)} cm" : "No registrada"}',
      reasoning:
          '🔬 Validación Científica Gold Standard:\n\n'
          '• DESARROLLO: Mifflin et al. (1990) - Estudio con 498 sujetos sanos (247 mujeres, 251 hombres, 19-78 años).\n\n'
          '• PRECISIÓN SUPERIOR: R² = 0.71 (71% de varianza explicada). Predice TMB dentro del ±10% en 82% de población general (Frankenfield et al., 2005).\n\n'
          '• ECUACIÓN ACTUALIZADA:\n'
          '  Hombres: TMB = 10×peso + 6.25×altura - 5×edad + 5\n'
          '  Mujeres: TMB = 10×peso + 6.25×altura - 5×edad - 161\n\n'
          '• REEMPLAZA: Harris-Benedict (1919) que sobrestima ~5% el TMB medido.\n\n'
          '• VALIDACIÓN INDEPENDIENTE: Múltiples estudios confirman como la ecuación más fiable para adultos sanos normopeso y con sobrepeso.',
      alternativeConsiderations:
          '💡 Mejora de Precisión Futura:\n\n'
          '📊 Con datos de composición corporal (MLG):\n'
          '• Katch-McArdle: R² = 0.64 solo con MLG\n'
          '• Tinsley: Específica para atletas de fuerza\n'
          '• Müller: Especializada en obesidad\n\n'
          '🏋️ Si inicias entrenamiento de fuerza:\n'
          '• Al aumentar masa muscular >5 kg, considerar ecuaciones basadas en MLG.\n'
          '• La masa muscular tiene ~55 kJ/kg/día vs. 4.5 kJ/kg/día del tejido adiposo.\n\n'
          '📈 Próximos pasos recomendados:\n'
          '• Realizar análisis de composición corporal (BIA, DEXA, pliegues cutáneos).\n'
          '• Reevaluar fórmula si cambia nivel de actividad o composición corporal significativamente.',
    );
  }

  // ============================================
  // v2: DÉFICIT PORCENTUAL + ESTIMACIONES
  // ============================================

  static const double kcalPerKgFatApprox = 7700.0;

  /// Target diario con déficit porcentual + piso clínico relativo al TMB
  static double calculateTargetCaloriesPct({
    required double tmb,
    required double get,
    required double deficitPct, // 0.10..0.25
    double floorPct = 0.95,
  }) {
    final prelim = get * (1.0 - deficitPct);
    final floor = tmb * floorPct;
    return max(prelim, floor);
  }

  /// Déficit real (kcal) de un día, ya con piso aplicado
  static double calculateDailyDeficitKcal({
    required double get,
    required double target,
  }) {
    return max(0.0, get - target);
  }

  /// Déficit promedio diario real (post-piso)
  static double calculateAverageDailyDeficitKcal({
    required Map<String, double> dailyGet,
    required Map<String, int> dailyTargetKcal,
  }) {
    if (dailyGet.isEmpty) return 0.0;
    double sum = 0.0;
    int n = 0;
    dailyGet.forEach((day, get) {
      final target = (dailyTargetKcal[day] ?? get.round()).toDouble();
      sum += calculateDailyDeficitKcal(get: get, target: target);
      n++;
    });
    return n == 0 ? 0.0 : (sum / n);
  }

  /// Estimación kg/semana y kg/mes basado en déficit real
  static Map<String, double> estimateWeightLossFromDeficit({
    required double avgDailyDeficitKcal,
  }) {
    final weeklyDeficit = avgDailyDeficitKcal * 7.0;
    final kgWeek = weeklyDeficit / kcalPerKgFatApprox;
    final kgMonth = kgWeek * 4.3;
    return {'kgWeek': kgWeek, 'kgMonth': kgMonth};
  }

  /// MIGRACIÓN: Convertir kcalAdjustment (legacy) a deficitPct aproximado
  /// deficitPct ~= (-kcalAdjustment) / avgGet  (clamp)
  static double migrateDeficitPctFromLegacy({
    required double kcalAdjustment,
    required double avgGet,
  }) {
    if (avgGet <= 0) return 0.15;
    final pct = (-kcalAdjustment) / avgGet;
    return pct.clamp(0.05, 0.30);
  }
} // Fin de DietaryCalculator
