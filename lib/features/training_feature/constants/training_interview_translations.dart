// Traducciones y mapeos de enums internos a etiquetas visibles en español.
// Este archivo es la fuente única de verdad (SSOT) para toda la presentación del Bloque 1.

class TrainingInterviewTranslations {
  // ====================================================================
  // SECCIÓN 1: DATOS BASE - TOOLTIPS
  // ====================================================================

  static const String heightCmTooltip =
      'Ingresa la estatura actual del asesorado en centímetros. Este dato se usa para clasificar el contexto corporal general del atleta.';

  static const String weightKgTooltip =
      'Ingresa el peso corporal actual en kilogramos. Este dato ayuda a ajustar el rango de volumen del sujeto.';

  static const String ageYearsTooltip =
      'Ingresa la edad actual del asesorado en años. La edad modifica la tolerancia general al volumen.';

  static const String trainingDurationTooltip =
      'Ingresa el tiempo real que el asesorado lleva entrenando fuerza de forma continua y estructurada. Puedes capturarlo en meses o años. El sistema convierte este valor a meses y detecta automáticamente el nivel.';

  // ====================================================================
  // SECCIÓN 2: FACTORES VME/VMR - TOOLTIPS
  // ====================================================================

  static const String strengthLevelTooltip =
      'Selecciona el nivel de fuerza actual del asesorado. Usa la opción que mejor describa su fuerza relativa y desempeño actual en ejercicios de fuerza.';

  static const String workCapacityTooltip =
      'Indica cuánta carga total de entrenamiento suele tolerar el asesorado. 1 = tolera poco volumen. 5 = tolera mucho volumen.';

  static const String recoveryHistoryTooltip =
      'Indica qué tan bien se recupera normalmente del entrenamiento. 1 = recuperación pobre. 5 = recuperación muy buena.';

  static const String externalRecoverySupportTooltip =
      'Marca Sí si el asesorado cuenta con apoyo externo que favorezca su recuperación, por ejemplo masaje, fisioterapia de soporte, recuperación guiada o condiciones externas favorables.';

  static const String programNoveltyTooltip =
      'Indica qué tan diferente será este programa respecto a lo que el asesorado ya viene haciendo. Nulo = muy acostumbrado. Alto = el programa será muy nuevo.';

  static const String externalPhysicalStressTooltip =
      'Evalúa el desgaste físico externo al entrenamiento: trabajo físico, deporte adicional, caminatas demandantes, carga laboral o actividades pesadas.';

  static const String nonPhysicalStressTooltip =
      'Evalúa el estrés no físico: trabajo, familia, dinero, escuela, problemas personales. Bajo = manejable. Alto = frecuentemente sobrepasado.';

  static const String restQualityTooltip =
      'Evalúa la calidad del descanso reciente. No se trata solo de horas, sino de qué tan reparador ha sido el sueño.';

  static const String dietHabitsTooltip =
      'Selecciona el estado energético actual del asesorado. Esto representa si está comiendo por encima, igual o por debajo de mantenimiento.';

  static const String usesAnabolicsTooltip =
      'Marca Sí solo si actualmente existe uso de anabólicos. Este dato modifica la capacidad de recuperación y tolerancia al volumen.';

  // ====================================================================
  // SECCIÓN 3: LESIONES - TOOLTIPS
  // ====================================================================

  static const String injuryRegionTooltip =
      'Marca la región donde el asesorado presenta molestia, lesión activa o antecedente relevante para tenerlo registrado como historia clínica.';

  static const String injuryPatternTooltip =
      'Selecciona el patrón de movimiento que más suele agravar esa región. Esto se registra como historia clínica para tenerlo en cuenta en la programación.';

  static const String injurySeverityTooltip =
      'Indica la severidad actual de la molestia o lesión.';

  static const String injuryStatusTooltip =
      'Indica si la molestia está activa actualmente, aparece por episodios o solo queda como antecedente.';

  // ====================================================================
  // SECCIÓN 4: PRIORIDADES MUSCULARES - TOOLTIPS
  // ====================================================================

  static const String backFocusTooltip =
      'Selecciona qué parte de la espalda quieres enfatizar en este ciclo. Esto ayuda a definir el sesgo de distribución dentro del trabajo de espalda.';

  static const String primaryMusclesLabel = 'Músculos primarios';
  static const String primaryMusclesTooltip =
      'Selecciona los músculos con máxima prioridad del ciclo.';

  static const String secondaryMusclesLabel = 'Músculos secundarios';
  static const String secondaryMusclesTooltip =
      'Selecciona los músculos con prioridad intermedia del ciclo.';

  static const String tertiaryMusclesLabel = 'Músculos terciarios';
  static const String tertiaryMusclesTooltip =
      'Selecciona los músculos con menor prioridad relativa del ciclo.';

  // ====================================================================
  // MAPEOS: TRAINING LEVEL (beginner, intermediate, advanced → español)
  // ====================================================================

  static String trainingLevelToSpanish(String? level) {
    switch (level?.toLowerCase()) {
      case 'beginner':
        return 'Principiante';
      case 'intermediate':
        return 'Intermedio';
      case 'advanced':
        return 'Avanzado';
      default:
        return '-';
    }
  }

  // ====================================================================
  // MAPEOS: STRENGTH LEVEL CLASS (B, M, A, MA → español)
  // ====================================================================

  static const Map<String, String> strengthLevelMap = {
    'B': 'Baja',
    'M': 'Media',
    'A': 'Alta',
    'MA': 'Muy alta',
  };

  static String? strengthLevelVisibleLabel(String? internalCode) {
    return internalCode != null ? strengthLevelMap[internalCode] : null;
  }

  // ====================================================================
  // MAPEOS: PROGRAM NOVELTY CLASS (N, B, I, A → español)
  // ====================================================================

  static const Map<String, String> programNoveltyMap = {
    'N': 'Nulo',
    'B': 'Bajo',
    'I': 'Intermedio',
    'A': 'Alto',
  };

  static String? programNoveltyVisibleLabel(String? internalCode) {
    return internalCode != null ? programNoveltyMap[internalCode] : null;
  }

  // ====================================================================
  // MAPEOS: PHYSICAL STRESS LEVEL (N, B, I, A → español)
  // ====================================================================

  static const Map<String, String> physicalStressMap = {
    'N': 'Nulo',
    'B': 'Bajo',
    'I': 'Intermedio',
    'A': 'Alto',
  };

  static String? physicalStressVisibleLabel(String? internalCode) {
    return internalCode != null ? physicalStressMap[internalCode] : null;
  }

  // ====================================================================
  // MAPEOS: NON-PHYSICAL STRESS LEVEL (B, P, A → español)
  // ====================================================================

  static const Map<String, String> nonPhysicalStressMap = {
    'B': 'Bajo',
    'P': 'Promedio',
    'A': 'Alto',
  };

  static String? nonPhysicalStressVisibleLabel(String? internalCode) {
    return internalCode != null ? nonPhysicalStressMap[internalCode] : null;
  }

  // ====================================================================
  // MAPEOS: REST QUALITY (B, P, A → español)
  // ====================================================================

  static const Map<String, String> restQualityMap = {
    'B': 'Bajo',
    'P': 'Promedio',
    'A': 'Alto',
  };

  static String? restQualityVisibleLabel(String? internalCode) {
    return internalCode != null ? restQualityMap[internalCode] : null;
  }

  // ====================================================================
  // MAPEOS: DIET HABITS CLASS (SCA, SCM, SCB, ISO, DCA, DCM, DCB → español)
  // ====================================================================

  static const Map<String, String> dietHabitsMap = {
    'SCA': 'Superávit alto',
    'SCM': 'Superávit medio',
    'SCB': 'Superávit bajo',
    'ISO': 'Mantenimiento',
    'DCB': 'Déficit bajo',
    'DCM': 'Déficit medio',
    'DCA': 'Déficit alto',
  };

  static String? dietHabitsVisibleLabel(String? internalCode) {
    return internalCode != null ? dietHabitsMap[internalCode] : null;
  }

  // ====================================================================
  // MAPEOS: INJURY REGION (claves internas → español)
  // ====================================================================

  static const Map<String, String> injuryRegionMap = {
    'neck_upper_back': 'Cuello / espalda alta',
    'shoulder': 'Hombro',
    'elbow': 'Codo',
    'wrist': 'Muñeca',
    'lower_back': 'Espalda baja',
    'hip': 'Cadera',
    'knee': 'Rodilla',
    'ankle': 'Tobillo',
  };

  static String? injuryRegionVisibleLabel(String? internalCode) {
    return internalCode != null ? injuryRegionMap[internalCode] : null;
  }

  // ====================================================================
  // MAPEOS: INJURY PATTERNS (camelCase → español)
  // ====================================================================

  static const Map<String, String> injuryPatternMap = {
    // Shoulder patterns
    'verticalPress': 'Empuje vertical',
    'horizontalPress': 'Empuje horizontal',
    'lateralRaise': 'Elevación lateral',
    'overheadEndRange': 'Rango final overhead',
    'wideGripPress': 'Press con agarre amplio',
    'none': 'Ninguno en particular',

    // Knee patterns
    'squat': 'Sentadilla',
    'lunge': 'Zancada / lunge',
    'deepKneeFlexion': 'Flexión profunda de rodilla',
    'heavyKneeExtension': 'Extensión de rodilla pesada',
    'jumpsImpact': 'Saltos / impactos',
    'unilateralWork': 'Trabajo unilateral',

    // Lower back patterns
    'axialLoading': 'Carga axial',
    'hipHinge': 'Bisagra de cadera',
    'deadliftRdl': 'Peso muerto / RDL',
    'bentOverRow': 'Remo inclinado',
    'deepLumbarFlexion': 'Flexión lumbar profunda',

    // Hip patterns
    'deepHipFlexion': 'Flexión profunda de cadera',
    'splitSquatLunge': 'Split squat / zancada',

    // Elbow patterns
    'bicepsCurl': 'Curl de bíceps',
    'tricepsExtension': 'Extensión de tríceps',
    'pullDownChinUp': 'Jalón / dominada',
    'pressing': 'Press',
    'strongGrip': 'Agarre fuerte',

    // Wrist patterns
    'barbellPress': 'Press con barra',
    'frontRack': 'Front rack',
    'curling': 'Curl',
    'extendedWristSupport': 'Apoyo extendido de muñeca',
    'heavyGrip': 'Agarre pesado',

    // Ankle patterns
    'deepDorsiflexion': 'Dorsiflexión profunda',

    // Neck/Upper back patterns
    'highAxialLoading': 'Carga axial alta',
    'heavyRow': 'Remo pesado',
    'shrugs': 'Encogimientos',
    'overheadPress': 'Press overhead',
    'prolongedPosturalTension': 'Tensión postural prolongada',
  };

  static String? injuryPatternVisibleLabel(String? internalCode) {
    return internalCode != null ? injuryPatternMap[internalCode] : null;
  }

  // ====================================================================
  // MAPEOS: INJURY SEVERITY (mild, moderate, high → español)
  // ====================================================================

  static const Map<String, String> injurySeverityMap = {
    'mild': 'Leve',
    'moderate': 'Moderada',
    'high': 'Alta',
  };

  static String? injurySeverityVisibleLabel(String? internalCode) {
    return internalCode != null ? injurySeverityMap[internalCode] : null;
  }

  // ====================================================================
  // MAPEOS: INJURY STATUS (active, intermittent, historyNoCurrentPain → español)
  // ====================================================================

  static const Map<String, String> injuryStatusMap = {
    'active': 'Activa',
    'intermittent': 'Intermitente',
    'historyNoCurrentPain': 'Antecedente sin dolor actual',
  };

  static String? injuryStatusVisibleLabel(String? internalCode) {
    return internalCode != null ? injuryStatusMap[internalCode] : null;
  }

  // ====================================================================
  // MAPEOS: BACK FOCUS (lats, upper_back → español)
  // ====================================================================

  static const Map<String, String> backFocusMap = {
    'lats': 'Dorsal',
    'upper_back': 'Espalda alta',
  };

  static String? backFocusVisibleLabel(String? internalCode) {
    return internalCode != null ? backFocusMap[internalCode] : null;
  }

  // ====================================================================
  // REVERSE MAPEOS (español → interno) - Para guardado bidireccional
  // ====================================================================

  static const Map<String, String> strengthLevelReverseMap = {
    'Baja': 'B',
    'Media': 'M',
    'Alta': 'A',
    'Muy alta': 'MA',
  };

  static const Map<String, String> programNoveltyReverseMap = {
    'Nulo': 'N',
    'Bajo': 'B',
    'Intermedio': 'I',
    'Alto': 'A',
  };

  static const Map<String, String> physicalStressReverseMap = {
    'Nulo': 'N',
    'Bajo': 'B',
    'Intermedio': 'I',
    'Alto': 'A',
  };

  static const Map<String, String> nonPhysicalStressReverseMap = {
    'Bajo': 'B',
    'Promedio': 'P',
    'Alto': 'A',
  };

  static const Map<String, String> restQualityReverseMap = {
    'Bajo': 'B',
    'Promedio': 'P',
    'Alto': 'A',
  };

  static const Map<String, String> dietHabitsReverseMap = {
    'Superávit alto': 'SCA',
    'Superávit medio': 'SCM',
    'Superávit bajo': 'SCB',
    'Mantenimiento': 'ISO',
    'Déficit bajo': 'DCB',
    'Déficit medio': 'DCM',
    'Déficit alto': 'DCA',
  };

  static const Map<String, String> injurySeverityReverseMap = {
    'Leve': 'mild',
    'Moderada': 'moderate',
    'Alta': 'high',
  };

  static const Map<String, String> injuryStatusReverseMap = {
    'Activa': 'active',
    'Intermitente': 'intermittent',
    'Antecedente sin dolor actual': 'historyNoCurrentPain',
  };

  static const Map<String, String> backFocusReverseMap = {
    'Dorsal': 'lats',
    'Espalda alta': 'upper_back',
  };
}
