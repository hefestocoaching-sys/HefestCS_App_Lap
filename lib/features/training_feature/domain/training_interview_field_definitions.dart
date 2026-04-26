import 'package:hcs_app_lap/features/training_feature/domain/injury_pattern_maps.dart';

class InterviewOption<T> {
  final T value;
  final String label;

  const InterviewOption({required this.value, required this.label});
}

class TrainingInterviewFieldDefinitions {
  TrainingInterviewFieldDefinitions._();

  static const String baseSectionTitle = '1. DATOS BASE';
  static const String volumeSectionTitle = '2. FACTORES PARA AJUSTE VME/VMR';
  static const String injurySectionTitle = '3. LESIONES / HISTORIA CLÍNICA';
  static const String prioritiesSectionTitle = '4. PRIORIDADES MUSCULARES';

  static const String heightLabel = '1. Estatura (cm)';
  static const String weightLabel = '2. Peso actual (kg)';
  static const String ageLabel = '3. Edad (años)';
  static const String trainingTimeLabel =
      '4. ¿Cuánto tiempo llevas entrenando fuerza de forma consistente?';
  static const String trainingUnitLabel = 'Unidad';
  static const String trainingDetectedLabel = 'Nivel detectado';

  static const String strengthLevelLabel = '5. Nivel de fuerza actual';
  static const String workCapacityLabel = '6. Capacidad de trabajo';
  static const String recoveryHistoryLabel = '7. Historial de recuperación';
  static const String externalRecoverySupportLabel =
      '8. ¿Cuentas con apoyo externo para tu recuperación?';
  static const String programNoveltyLabel =
      '9. ¿Qué tan nuevo será este programa para ti?';
  static const String externalPhysicalStressLabel =
      '10. Fuera del gimnasio, ¿qué tanto desgaste físico tienes en tu vida diaria?';
  static const String nonPhysicalStressLabel =
      '11. Durante las últimas 4 semanas, ¿qué tanto estrés no físico has sentido en tu vida diaria?';
  static const String restQualityLabel =
      '12. ¿Cómo calificarías tu descanso y sueño recientemente?';
  static const String dietHabitsLabel =
      '13. ¿En qué estado energético estás actualmente?';
  static const String usesAnabolicsLabel = '14. ¿Usas anabólicos actualmente?';

  static const String injuryRegionLabel =
      '15. Región con molestia o lesión activa';
  static const String injuryPatternLabel =
      '16. Patrón principal que suele molestar';
  static const String injurySeverityLabel = '17. Severidad actual';
  static const String injuryStatusLabel = '18. Estado';

  static const String backFocusLabel =
      '19. En espalda, ¿qué enfoque quieres priorizar?';
  static const String primaryMusclesLabel = '20. Músculos primarios';
  static const String secondaryMusclesLabel = '21. Músculos secundarios';
  static const String tertiaryMusclesLabel = '22. Músculos terciarios';

  static const List<InterviewOption<String>> strengthLevelOptions = [
    InterviewOption(value: 'B', label: 'Baja'),
    InterviewOption(value: 'M', label: 'Media'),
    InterviewOption(value: 'A', label: 'Alta'),
    InterviewOption(value: 'MA', label: 'Muy alta'),
  ];

  static const List<InterviewOption<int>> workCapacityOptions = [
    InterviewOption(value: 1, label: '1'),
    InterviewOption(value: 2, label: '2'),
    InterviewOption(value: 3, label: '3'),
    InterviewOption(value: 4, label: '4'),
    InterviewOption(value: 5, label: '5'),
  ];

  static const List<InterviewOption<int>> recoveryHistoryOptions = [
    InterviewOption(value: 1, label: '1'),
    InterviewOption(value: 2, label: '2'),
    InterviewOption(value: 3, label: '3'),
    InterviewOption(value: 4, label: '4'),
    InterviewOption(value: 5, label: '5'),
  ];

  static const List<InterviewOption<bool>> yesNoOptions = [
    InterviewOption(value: true, label: 'Sí'),
    InterviewOption(value: false, label: 'No'),
  ];

  static const List<InterviewOption<String>> programNoveltyOptions = [
    InterviewOption(value: 'N', label: 'Nulo'),
    InterviewOption(value: 'B', label: 'Bajo'),
    InterviewOption(value: 'I', label: 'Intermedio'),
    InterviewOption(value: 'A', label: 'Alto'),
  ];

  static const List<InterviewOption<String>> externalStressOptions = [
    InterviewOption(value: 'N', label: 'Nulo'),
    InterviewOption(value: 'B', label: 'Bajo'),
    InterviewOption(value: 'I', label: 'Intermedio'),
    InterviewOption(value: 'A', label: 'Alto'),
  ];

  static const List<InterviewOption<String>> nonPhysicalStressOptions = [
    InterviewOption(value: 'B', label: 'Bajo'),
    InterviewOption(value: 'P', label: 'Promedio'),
    InterviewOption(value: 'A', label: 'Alto'),
  ];

  static const List<InterviewOption<String>> restQualityOptions = [
    InterviewOption(value: 'B', label: 'Bajo'),
    InterviewOption(value: 'P', label: 'Promedio'),
    InterviewOption(value: 'A', label: 'Alto'),
  ];

  static const List<InterviewOption<String>> dietHabitsOptions = [
    InterviewOption(value: 'SCA', label: 'Superávit alto'),
    InterviewOption(value: 'SCM', label: 'Superávit medio'),
    InterviewOption(value: 'SCB', label: 'Superávit bajo'),
    InterviewOption(value: 'ISO', label: 'Mantenimiento'),
    InterviewOption(value: 'DCB', label: 'Déficit bajo'),
    InterviewOption(value: 'DCM', label: 'Déficit medio'),
    InterviewOption(value: 'DCA', label: 'Déficit alto'),
  ];

  static const List<InterviewOption<String>> injurySeverityOptions = [
    InterviewOption(value: 'mild', label: 'Leve'),
    InterviewOption(value: 'moderate', label: 'Moderada'),
    InterviewOption(value: 'high', label: 'Alta'),
  ];

  static const List<InterviewOption<String>> injuryStatusOptions = [
    InterviewOption(value: 'active', label: 'Activa'),
    InterviewOption(value: 'intermittent', label: 'Intermitente'),
    InterviewOption(
      value: 'historyNoCurrentPain',
      label: 'Antecedente sin dolor actual',
    ),
  ];

  static const List<InterviewOption<String>> backFocusOptions = [
    InterviewOption(value: 'lats', label: 'Dorsal'),
    InterviewOption(value: 'upper_back', label: 'Espalda alta'),
  ];

  static const List<InterviewOption<String>> injuryRegionOptions = [
    InterviewOption(value: 'neck_upper_back', label: 'Cuello / espalda alta'),
    InterviewOption(value: 'shoulder', label: 'Hombro'),
    InterviewOption(value: 'elbow', label: 'Codo'),
    InterviewOption(value: 'wrist', label: 'Muñeca'),
    InterviewOption(value: 'lower_back', label: 'Espalda baja'),
    InterviewOption(value: 'hip', label: 'Cadera'),
    InterviewOption(value: 'knee', label: 'Rodilla'),
    InterviewOption(value: 'ankle', label: 'Tobillo'),
  ];

  static List<InterviewOption<String>> injuryPatternOptions(String region) {
    return [
      for (final code in InjuryPatternMaps.patternsByRegion[region] ?? const [])
        InterviewOption(
          value: code,
          label: InjuryPatternMaps.patternLabel(code),
        ),
    ];
  }

  static String detectedLevelLabel(String? derivedLevelName) {
    switch (derivedLevelName) {
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
}
