import 'package:flutter/material.dart';
import 'package:hcs_app_lap/core/enums/gender.dart';
import 'package:hcs_app_lap/utils/theme.dart'; // Para los colores
import 'package:hcs_app_lap/utils/widgets/bio_analysis_result.dart';


// 3. El "Cerebro" Analizador
class BiochemistryAnalyzer {

  // Colores estándar
  static const Color _alertColor = Color(0xFFE57373); // Rojo suave (Riesgo grave)
  static const Color _warningColor = Color(0xFFFFB74D); // Naranja suave (Precaución)
  static const Color _normalColor = Color(0xFF81C784); // Verde suave (Aceptable)
  static const Color _optimalColor = kPrimaryColor; // Tu color primario (Óptimo)

  // --- FUNCIONES AUXILIARES ORIGINALES (SIMPLE) ---

  static BioAnalysisResult _analyzeLowIsBetter(double value, double optimal, double normal, double high) {
    if (value <= optimal) {
      return BioAnalysisResult(status: BioStatus.optimal, color: _optimalColor, interpretation: "Nivel óptimo.", recommendation: "Mantener estilo de vida saludable.");
    }
    if (value <= normal) {
      return BioAnalysisResult(status: BioStatus.normal, color: _normalColor, interpretation: "Nivel aceptable/normal.", recommendation: "Mantener estilo de vida saludable.");
    }
    if (value <= high) {
      return BioAnalysisResult(status: BioStatus.high, color: _warningColor, interpretation: "Nivel en el límite alto (borderline).", recommendation: "Revisar dieta, ejercicio y otros factores de riesgo.");
    }
    return BioAnalysisResult(status: BioStatus.criticallyHigh, color: _alertColor, interpretation: "Nivel elevado. Indica riesgo.", recommendation: "Requiere intervención dietética, de estilo de vida y/o médica.");
  }

  static BioAnalysisResult _analyzeHighIsBetter(double value, double low, double normal, double optimal) {
    if (value >= optimal) {
      return BioAnalysisResult(status: BioStatus.optimal, color: _optimalColor, interpretation: "Nivel óptimo.", recommendation: "¡Excelente! Mantener hábitos actuales.");
    }
    if (value >= normal) {
      return BioAnalysisResult(status: BioStatus.normal, color: _normalColor, interpretation: "Nivel aceptable/normal.", recommendation: "Mantener buenos hábitos.");
    }
    if (value >= low) {
      return BioAnalysisResult(status: BioStatus.low, color: _warningColor, interpretation: "Nivel en el límite bajo (borderline).", recommendation: "Considerar mejoras en dieta o estilo de vida para optimizar.");
    }
    return BioAnalysisResult(status: BioStatus.criticallyLow, color: _alertColor, interpretation: "Nivel bajo. Indica deficiencia o riesgo.", recommendation: "Requiere intervención para aumentar los niveles (dieta, suplementación).");
  }

  static BioAnalysisResult _analyzeInRange(double value, double low, double high, {double? optimalLow, double? optimalHigh}) {
    optimalLow ??= low;
    optimalHigh ??= high;

    if (value < low) {
      return BioAnalysisResult(status: BioStatus.low, color: _alertColor, interpretation: "Nivel bajo. Posible deficiencia o problema subyacente.", recommendation: "Investigar causa y considerar suplementación o ajuste dietético.");
    }
    if (value > high) {
      return BioAnalysisResult(status: BioStatus.high, color: _alertColor, interpretation: "Nivel alto. Posible toxicidad o problema subyacente.", recommendation: "Investigar causa y considerar ajuste dietético o médico.");
    }
    if (value >= optimalLow && value <= optimalHigh) {
      return BioAnalysisResult(status: BioStatus.optimal, color: _optimalColor, interpretation: "Nivel óptimo.", recommendation: "Mantener hábitos actuales.");
    }
    // Si está en rango normal pero no óptimo
    return BioAnalysisResult(status: BioStatus.normal, color: _normalColor, interpretation: "Nivel dentro del rango de referencia estándar.", recommendation: "Nivel aceptable. Considerar optimización si está cerca de los límites.");
  }

  // --- MÉTODO PRINCIPAL DE ANÁLISIS ---
  static BioAnalysisResult? analyze(String biomarkerKey, double? value, {String? gender}) {
    if (value == null || value <= 0) return null;

    bool isMale = parseGender(gender) == Gender.male;

    switch (biomarkerKey) {

    // --- Panel 1: Glucosa ---
      case 'glucose':
        if (value > 125) return BioAnalysisResult(status: BioStatus.criticallyHigh, color: _alertColor, interpretation: "Valor muy elevado, indicador de Diabetes Mellitus.", recommendation: "Evaluación médica inmediata. Confirmar con HbA1c y curva de tolerancia.");
        if (value > 99) return BioAnalysisResult(status: BioStatus.high, color: _warningColor, interpretation: "Glucosa en ayunas elevada (Prediabetes).", recommendation: "Reducir carbohidratos refinados, aumentar fibra y ejercicio.");
        if (value < 70) return BioAnalysisResult(status: BioStatus.low, color: _warningColor, interpretation: "Posible hipoglucemia.", recommendation: "Revisar tiempos de ayuno o medicación. Consumir carbohidratos si hay síntomas.");
        return _analyzeInRange(value, 70, 99, optimalLow: 70, optimalHigh: 85);

      case 'hba1c':
        if (value > 6.4) return BioAnalysisResult(status: BioStatus.criticallyHigh, color: _alertColor, interpretation: "Nivel diagnóstico de Diabetes Mellitus.", recommendation: "Requiere plan de manejo médico-nutricional inmediato.");
        if (value > 5.6) return BioAnalysisResult(status: BioStatus.high, color: _warningColor, interpretation: "Nivel elevado (Prediabetes). Indica alto riesgo metabólico.", recommendation: "Intervención nutricional y de estilo de vida crucial.");
        if (value < 4.8) return BioAnalysisResult(status: BioStatus.low, color: _warningColor, interpretation: "Nivel bajo. Menos común, puede indicar hipoglucemias.", recommendation: "Asegurar ingesta calórica y de carbohidratos adecuada.");
        return _analyzeLowIsBetter(value, 5.0, 5.6, 6.4);

      case 'fastingInsulin':
        if (value > 10) return BioAnalysisResult(status: BioStatus.high, color: _warningColor, interpretation: "Nivel elevado. Fuerte indicador de Resistencia a la Insulina.", recommendation: "Dieta baja en azúcar y carbohidratos simples. Incluir ejercicio de fuerza y cardiovascular.");
        return _analyzeInRange(value, 2, 25, optimalLow: 2, optimalHigh: 6);

    // --- Panel 2: Lípidos (ACTUALIZADO) ---
      case 'cholesterolTotal':
        return _analyzeLowIsBetter(value, 180, 200, 239);
      case 'ldl':
        return _analyzeLowIsBetter(value, 70, 100, 159);
      case 'hdl':
        double normalLimit = isMale ? 40 : 50;
        double optimalLimit = 60;
        if (value >= optimalLimit) return BioAnalysisResult(status: BioStatus.optimal, color: _optimalColor, interpretation: "Nivel óptimo. Factor cardioprotector.", recommendation: "Mantener ingesta de grasas saludables y ejercicio.");
        if (value >= normalLimit) return BioAnalysisResult(status: BioStatus.normal, color: _normalColor, interpretation: "Nivel aceptable.", recommendation: "Continuar buenos hábitos.");
        // ALERTA EAA: HDL bajo
        return BioAnalysisResult(status: BioStatus.low, color: _alertColor, interpretation: "Nivel bajo. **Riesgo Cardiovascular ELEVADO** (Común con EAAs).", recommendation: "Priorizar ejercicio aeróbico, suspender tabaquismo y reducir carbohidratos simples. **Evaluar el uso de sustancias (si aplica).**");
      case 'cholesterolNoHDL':
        return _analyzeLowIsBetter(value, 100, 130, 189);
      case 'triglycerides':
        if (value > 500) return BioAnalysisResult(status: BioStatus.criticallyHigh, color: _alertColor, interpretation: "Nivel críticamente alto. Riesgo de pancreatitis aguda.", recommendation: "Intervención médica inmediata. Eliminar azúcares, alcohol y grasas saturadas. Reducir el consumo de fructosa.");
        return _analyzeLowIsBetter(value, 100, 150, 199);
      case 'apoB': // NUEVO
        if (value > 120) return BioAnalysisResult(status: BioStatus.criticallyHigh, color: _alertColor, interpretation: "Nivel alto. Fuerte predictor de riesgo cardiovascular.", recommendation: "Requiere intervención dietética intensiva y médica.");
        return _analyzeLowIsBetter(value, 70, 90, 119);
      case 'apoA1': // NUEVO
        if (value < 100) return BioAnalysisResult(status: BioStatus.low, color: _alertColor, interpretation: "Nivel bajo. Correlaciona con bajo HDL. Mayor riesgo cardiovascular.", recommendation: "Aumentar ejercicio y grasas saludables (Omega-3).");
        return _analyzeInRange(value, 100, 200, optimalLow: 140, optimalHigh: 200);
      case 'apoBRatio': // Calculado (Ratio ApoB/ApoA1)
        double optimalRatio = isMale ? 0.8 : 0.7;
        if (value > 1.0) return BioAnalysisResult(status: BioStatus.criticallyHigh, color: _alertColor, interpretation: "Ratio muy alto. **INDICADOR DE ALTO RIESGO CARDIOVASCULAR.**", recommendation: "Intervención nutricional y de estilo de vida intensiva. Consultar cardiólogo.");
        return _analyzeLowIsBetter(value, optimalRatio, 0.9, 1.0);


    // --- Panel 3: Hepático (Riesgo EAAs) ---
      case 'ast':
      case 'alt':
        double highLimit = isMale ? 40 : 30;
        if (value > highLimit * 3) return BioAnalysisResult(status: BioStatus.criticallyHigh, color: _alertColor, interpretation: "Nivel muy alto. **INDICADOR DE DAÑO HEPÁTICO AGUDO/HEPATOTOXICIDAD.**", recommendation: "**SUSPENSIÓN INMEDIATA DE SUSTANCIAS ORALES O TÓXICAS.** Consultar gastroenterólogo.");
        if (value > highLimit) return BioAnalysisResult(status: BioStatus.high, color: _warningColor, interpretation: "Nivel elevado. Posible hígado graso, alcohol o estrés hepático por ejercicio o sustancias orales.", recommendation: "Eliminar alcohol, revisar fármacos/suplementos y EAAs. Mejorar dieta. Monitoreo cercano.");
        return _analyzeInRange(value, 10, highLimit, optimalHigh: isMale ? 25 : 20);
      case 'ggt':
        if (value > 60) return BioAnalysisResult(status: BioStatus.high, color: _warningColor, interpretation: "Nivel elevado. Indicador sensible de consumo crónico de alcohol o colestasis.", recommendation: "Eliminar alcohol y revisar fármacos/suplementos. Monitoreo de función biliar.");
        return _analyzeInRange(value, 5, 40, optimalHigh: 25);
      case 'alkalinePhosphatase':
        return _analyzeInRange(value, 40, 120);
      case 'bilirubinTotal':
        return _analyzeInRange(value, 0.2, 1.2);
      case 'albumin':
        return _analyzeInRange(value, 3.5, 5.0, optimalLow: 4.0, optimalHigh: 5.0);
      case 'totalProteins':
        return _analyzeInRange(value, 6.0, 8.0);

    // --- Panel 4: Renal / Electrolitos ---
      case 'creatinine':
        double highLimit = isMale ? 1.3 : 1.1;
        if (value > highLimit) return BioAnalysisResult(status: BioStatus.high, color: _warningColor, interpretation: "Nivel elevado. Puede ser por alta masa muscular, deshidratación, o potencialmente **daño renal**.", recommendation: "Asegurar hidratación. Evaluar junto con BUN y eGFR. Reducir ingesta excesiva de proteínas.");
        return _analyzeInRange(value, 0.6, highLimit);
      case 'ureaBUN':
        return _analyzeInRange(value, 7, 20, optimalLow: 10, optimalHigh: 15);
      case 'bunCreatinineRatio':
        return _analyzeInRange(value, 10, 20, optimalLow: 12, optimalHigh: 16);
      case 'egfr':
        if (value < 60) return BioAnalysisResult(status: BioStatus.criticallyLow, color: _alertColor, interpretation: "Tasa de filtración baja. **INDICADOR DE ENFERMEDAD RENAL CRÓNICA.**", recommendation: "Referir a nefrólogo. Evaluación urgente.");
        return _analyzeHighIsBetter(value, 60, 90, 90);
      case 'sodium':
        return _analyzeInRange(value, 135, 145);
      case 'potassium':
        return _analyzeInRange(value, 3.5, 5.0);
      case 'chloride':
        return _analyzeInRange(value, 98, 107);
      case 'bicarbonate':
        return _analyzeInRange(value, 22, 28);
      case 'serumOsmolality':
        return _analyzeInRange(value, 275, 295);
      case 'urineDensity':
        return _analyzeInRange(value, 1.005, 1.030);
      case 'uricAcid':
        return _analyzeInRange(value, 3.5, 7.0, optimalHigh: 6.0);

    // --- Panel 5: Hematología/Hierro (ACTUALIZADO CON ÍNDICES) ---
      case 'hemoglobin':
        double low = isMale ? 13.5 : 12.0;
        double high = isMale ? 17.5 : 15.5;
        return _analyzeInRange(value, low, high);
      case 'hematocrit':
        double low = isMale ? 41 : 36;
        double high = isMale ? 50 : 44;
        if (value > (isMale ? 52 : 48)) return BioAnalysisResult(status: BioStatus.criticallyHigh, color: _alertColor, interpretation: "Hematocrito Críticamente Alto (**POLICITEMIA**). **RIESGO GRAVE DE TROMBOSIS/ACV.** (Común con EAAs).", recommendation: "**SUSPENSIÓN INMEDIATA DE EAAs.** Referir a Hematólogo para flebotomía terapéutica.");
        return _analyzeInRange(value, low, high);
      case 'leukocytes':
        return _analyzeInRange(value, 4.0, 11.0, optimalLow: 5.0, optimalHigh: 8.0);
      case 'platelets':
        return _analyzeInRange(value, 150, 450);
      case 'mcv': // NUEVO
        return _analyzeInRange(value, 80, 100, optimalLow: 85, optimalHigh: 95);
      case 'mch': // NUEVO
        return _analyzeInRange(value, 27, 33);
      case 'rdw': // NUEVO
        if (value > 15) return BioAnalysisResult(status: BioStatus.high, color: _warningColor, interpretation: "RDW alto. Indica alta variación en el tamaño de glóbulos rojos (anisocitosis).", recommendation: "Evaluar junto con Ferritina y MCV. Sugiere proceso anémico en desarrollo.");
        return _analyzeInRange(value, 11.5, 14.5);
      case 'ferritin':
        double low = isMale ? 30 : 20;
        double high = isMale ? 300 : 200;
        double optimalLow = isMale ? 50 : 40;
        double optimalHigh = isMale ? 150 : 120;
        return _analyzeInRange(value, low, high, optimalLow: optimalLow, optimalHigh: optimalHigh);
      case 'serumIron':
        return _analyzeInRange(value, 60, 170);
      case 'transferrinTIBC':
        return _analyzeInRange(value, 250, 450);
      case 'transferrinSaturation': // NUEVO
        if (value > 45) return BioAnalysisResult(status: BioStatus.high, color: _alertColor, interpretation: "Saturación de Transferrina alta. Puede indicar sobrecarga de hierro (hemocromatosis).", recommendation: "Investigar causas y referir a especialista. Suspender suplementación con hierro.");
        if (value < 20) return BioAnalysisResult(status: BioStatus.low, color: _warningColor, interpretation: "Saturación baja. Indicador temprano de deficiencia de hierro.", recommendation: "Aumentar ingesta de hierro/Vitamina C. Evaluar absorción.");
        return _analyzeInRange(value, 20, 45);
      case 'uibc': // NUEVO
        return _analyzeInRange(value, 150, 350, optimalLow: 150, optimalHigh: 350);

    // --- Panel 6: Vitaminas / Minerales ---
      case 'vitaminD':
        if (value < 20) return BioAnalysisResult(status: BioStatus.low, color: _alertColor, interpretation: "Deficiencia severa. Afecta salud ósea e inmunológica.", recommendation: "Suplementación con dosis alta bajo supervisión médica.");
        return _analyzeInRange(value, 20, 100, optimalLow: 40, optimalHigh: 60);
      case 'vitaminB12':
        return _analyzeInRange(value, 200, 900, optimalLow: 400, optimalHigh: 800);
      case 'vitaminB6':
        return _analyzeInRange(value, 5, 50);
      case 'vitaminB1':
        return _analyzeInRange(value, 2.5, 7.5);
      case 'vitaminE':
        return _analyzeInRange(value, 5.5, 17);
      case 'vitaminA':
        return _analyzeInRange(value, 30, 80);
      case 'vitaminK':
        return _analyzeInRange(value, 0.2, 3.2);
      case 'magnesium':
        return _analyzeInRange(value, 1.8, 2.4, optimalLow: 2.0, optimalHigh: 2.4);
      case 'zinc':
        return _analyzeInRange(value, 70, 120);
      case 'copper':
        return _analyzeInRange(value, 70, 140);
      case 'selenium':
        return _analyzeInRange(value, 60, 120);
      case 'folate':
        return _analyzeInRange(value, 3, 20);

    // --- Panel 7: Riesgo Cardio ---
      case 'pcrUs': // hs-CRP
        return _analyzeLowIsBetter(value, 1.0, 1.0, 3.0);
      case 'homocysteine':
        return _analyzeLowIsBetter(value, 7, 10, 15);
      case 'fibrinogen':
        return _analyzeInRange(value, 200, 400);

    // --- Panel 8: Tiroides (ACTUALIZADO CON LIBRES) ---
      case 'tsh':
        if (value > 10) return BioAnalysisResult(status: BioStatus.criticallyHigh, color: _alertColor, interpretation: "TSH muy elevada. Hipotiroidismo severo.", recommendation: "Referir a endocrinólogo para tratamiento de reemplazo hormonal.");
        if (value < 0.1) return BioAnalysisResult(status: BioStatus.criticallyLow, color: _alertColor, interpretation: "TSH muy baja. Hipertiroidismo o supeditación de fármacos tiroideos.", recommendation: "Referir a endocrinólogo para evaluación y ajuste de dosis.");
        return _analyzeInRange(value, 0.5, 4.5, optimalLow: 1.0, optimalHigh: 2.5);
      case 't4Total':
        return _analyzeInRange(value, 4.5, 11.7);
      case 't4Free': // NUEVO
        if (value < 0.8) return BioAnalysisResult(status: BioStatus.low, color: _alertColor, interpretation: "T4 libre baja. Posible hipotiroidismo primario/central. T4 libre es la forma activa.", recommendation: "Evaluar junto con TSH y T3 libre. Consultar endocrinólogo.");
        if (value > 1.8) return BioAnalysisResult(status: BioStatus.high, color: _alertColor, interpretation: "T4 libre alta. Posible hipertiroidismo. Alta actividad tiroidea.", recommendation: "Evaluar junto con TSH y T3 libre. Consultar endocrinólogo.");
        return _analyzeInRange(value, 0.8, 1.8, optimalLow: 1.0, optimalHigh: 1.5);
      case 't3Total':
        return _analyzeInRange(value, 80, 200);
      case 't3Free': // NUEVO
        if (value < 2.3) return BioAnalysisResult(status: BioStatus.low, color: _alertColor, interpretation: "T3 libre baja. Posible hipotiroidismo o conversión deficiente de T4 a T3.", recommendation: "Evaluar conversión periférica. Consultar endocrinólogo.");
        if (value > 4.2) return BioAnalysisResult(status: BioStatus.high, color: _alertColor, interpretation: "T3 libre alta. Posible hipertiroidismo o exceso de conversión.", recommendation: "Evaluar conversión periférica. Consultar endocrinólogo.");
        return _analyzeInRange(value, 2.3, 4.2, optimalLow: 3.0, optimalHigh: 4.0);

    // --- Panel 9: Marcadores Musculares ---
      case 'ck':
        double highLimit = isMale ? 200 : 150;
        if (value > highLimit) return BioAnalysisResult(status: BioStatus.high, color: _warningColor, interpretation: "Nivel elevado. Común post-ejercicio intenso (rabdomiólisis).", recommendation: "Evaluar contexto. Si no es por ejercicio, investigar causa muscular o cardíaca.");
        return _analyzeInRange(value, 30, highLimit);
      case 'ldh':
        return _analyzeInRange(value, 140, 280);
      case 'restingLactate':
        return _analyzeInRange(value, 0.5, 2.0);

    // --- Panel 10: Hormonal (Riesgo Supresión EAAs) ---
      case 'testosteroneTotal':
        if (value > 1500 && isMale) return BioAnalysisResult(status: BioStatus.criticallyHigh, color: _alertColor, interpretation: "**NIVEL CRÍTICAMENTE ALTO.** Sobrecarga androgénica masiva (uso de EAAs).", recommendation: "**SUSPENSIÓN INMEDIATA Y EVALUACIÓN DE RIESGOS** (cardíaco y hepático). Consultar endocrinólogo.");
        if (value < 250 && isMale) return BioAnalysisResult(status: BioStatus.low, color: _alertColor, interpretation: "Nivel muy bajo. Hipogonadismo severo o supresión de eje HPG.", recommendation: "Consultar endocrinólogo para plan de recuperación (PCT) o Terapia de Reemplazo.");
        if (isMale) return _analyzeInRange(value, 300, 1000, optimalLow: 500, optimalHigh: 800);
        return _analyzeInRange(value, 15, 70); // Mujer
      case 'testosteroneFree':
        if (!isMale) return _analyzeInRange(value, 0.1, 6.4); // Mujer
        return _analyzeInRange(value, 9, 30); // Hombre (ng/dL)
      case 'shbg':
        if (value < 15 && isMale) return BioAnalysisResult(status: BioStatus.low, color: _warningColor, interpretation: "Nivel bajo. Común con EAAs. Aumenta la Testosterona Libre.", recommendation: "Monitorear Testosterona Libre. **Alto riesgo de efectos androgénicos (acné, calvicie).**");
        if (value > 100) return BioAnalysisResult(status: BioStatus.high, color: _warningColor, interpretation: "Nivel elevado. Reduce la Testosterona Libre efectiva.", recommendation: "Evaluar función tiroidea y hepática.");
        if (isMale) return _analyzeInRange(value, 10, 80);
        return _analyzeInRange(value, 20, 140); // Mujer
      case 'estradiol':
        if (value > 60 && isMale) return BioAnalysisResult(status: BioStatus.high, color: _alertColor, interpretation: "Nivel elevado. **RIESGO DE GINECOMASTIA Y RETENCIÓN HÍDRICA.** (Común con EAAs).", recommendation: "**CONSULTAR MÉDICO** para manejo de aromatización. Reducir la dosis de sustancia (si aplica).");
        return _analyzeInRange(value, 10, 50);
      case 'progesteroneLuteal':
        return _analyzeInRange(value, 5, 20);
      case 'lh':
      case 'fsh':
        if (value < 0.5) return BioAnalysisResult(status: BioStatus.criticallyLow, color: _alertColor, interpretation: "**SUPRESIÓN DEL EJE HPG.** Indica que la producción de hormonas está inactiva (común con EAAs).", recommendation: "**SUSPENSIÓN INMEDIATA DE EAAs.** Referir a endocrinólogo para evaluación y posible Terapia Post-Ciclo (PCT).");
        return _analyzeInRange(value, 1.5, 12);
      case 'prolactin':
        return _analyzeInRange(value, 4, 23);
      case 'dheaS':
        return _analyzeInRange(value, 100, 500);
      case 'morningCortisol':
        return _analyzeInRange(value, 6, 23);

      default:
        return null;
    }
  }
}
