// lib/domain/training_v3/models/client_profile.dart

/// Perfil científico del cliente para cálculos del Motor V3
///
/// Este perfil contiene los factores necesarios para aplicar los ajustes
/// científicos descritos en los documentos 01-07:
/// - Ajustes de volumen por edad, recuperación, déficit calórico
/// - Nivel de experiencia para determinar MEV/MAV/MRV
/// - Restricciones (lesiones, equipo disponible)
/// - Factores genéticos (calibrados tras 4-8 semanas de seguimiento)
///
/// FUENTE CIENTÍFICA: 01-volume.md
class ClientProfile {
  /// ID del cliente
  final String clientId;

  /// Nivel de experiencia
  /// Determina landmarks de volumen base (MEV/MAV/MRV)
  final ExperienceLevel experience;

  /// Edad del cliente (años)
  /// Factor de ajuste: 0.75-1.0
  /// - <30 años: 1.0x
  /// - 30-40 años: 0.95x
  /// - 40-50 años: 0.9x
  /// - 50-60 años: 0.85x
  /// - 60+ años: 0.75x
  final int age;

  /// Días disponibles por semana para entrenar
  /// Determina el tipo de split óptimo
  final int availableDaysPerWeek;

  /// Objetivo principal del cliente
  final Goal goal;

  // ═══════════════════════════════════════════════════════════════════
  // FACTORES DE RECUPERACIÓN (0.8 - 1.2)
  // ═══════════════════════════════════════════════════════════════════

  /// Calidad del sueño (escala 1-10)
  /// 1-3: Muy mala, 4-6: Regular, 7-8: Buena, 9-10: Excelente
  final int sleepQuality;

  /// Nivel de estrés (escala 0-10)
  /// 0-2: Muy bajo, 3-4: Bajo, 5-6: Moderado, 7-8: Alto, 9-10: Muy alto
  final int stressLevel;

  /// Nivel de energía (escala 1-10)
  /// 1-3: Muy bajo, 4-6: Moderado, 7-8: Alto, 9-10: Muy alto
  final int energyLevel;

  // ═══════════════════════════════════════════════════════════════════
  // ESTADO METABÓLICO
  // ═══════════════════════════════════════════════════════════════════

  /// Balance calórico actual
  final CaloricBalance caloricBalance;

  /// Déficit o superávit calórico (kcal/día)
  /// Negativo = déficit, Positivo = superávit
  /// Ejemplo: -500 = déficit de 500 kcal
  final int deficitOrSurplus;

  // ═══════════════════════════════════════════════════════════════════
  // RESTRICCIONES
  // ═══════════════════════════════════════════════════════════════════

  /// Lesiones o restricciones físicas
  /// Ejemplo: ['rodilla_derecha', 'hombro_izquierdo']
  final List<String> injuries;

  /// Equipo disponible
  final List<Equipment> availableEquipment;

  // ═══════════════════════════════════════════════════════════════════
  // FACTORES GENÉTICOS Y OVERRIDES
  // ═══════════════════════════════════════════════════════════════════

  /// Factor de respuesta genética (0.5 - 1.5)
  /// Calibrado por ML tras 4-8 semanas de seguimiento
  /// - 0.5-0.8: Low responder (requiere más volumen)
  /// - 0.9-1.1: Average responder
  /// - 1.2-1.5: High responder (menos volumen suficiente)
  final double geneticResponseFactor;

  /// Override manual del coach para MAV
  /// Si el coach identifica que un cliente necesita volumen personalizado
  /// Estructura: {'pectorals': 16, 'quads': 20, ...}
  final Map<String, int>? manualMAVOverride;

  const ClientProfile({
    required this.clientId,
    required this.experience,
    required this.age,
    required this.availableDaysPerWeek,
    required this.goal,
    this.sleepQuality = 7,
    this.stressLevel = 5,
    this.energyLevel = 7,
    this.caloricBalance = CaloricBalance.maintenance,
    this.deficitOrSurplus = 0,
    this.injuries = const [],
    this.availableEquipment = const [],
    this.geneticResponseFactor = 1.0,
    this.manualMAVOverride,
  });

  // ═══════════════════════════════════════════════════════════════════
  // FACTORES CALCULADOS
  // ═══════════════════════════════════════════════════════════════════

  /// Factor de recuperación combinado (0.8 - 1.2)
  ///
  /// Calcula el factor de ajuste basado en sueño, estrés y energía.
  /// Usado para ajustar MAV:
  /// - 1.2: Excelente recuperación → +20% volumen
  /// - 1.1: Buena recuperación → +10% volumen
  /// - 1.0: Recuperación normal
  /// - 0.9: Recuperación subóptima → -10% volumen
  /// - 0.8: Mala recuperación → -20% volumen
  double get recoveryFactor {
    // Excelente: Sueño ≥8 Y estrés ≤2
    if (sleepQuality >= 8 && stressLevel <= 2) return 1.2;

    // Buena: Sueño ≥7 Y estrés ≤4
    if (sleepQuality >= 7 && stressLevel <= 4) return 1.1;

    // Normal: Sueño ≥6 Y estrés ≤6
    if (sleepQuality >= 6 && stressLevel <= 6) return 1.0;

    // Subóptima: Sueño <6 O estrés >6
    if (sleepQuality < 6 || stressLevel > 6) return 0.9;

    // Mala: Sueño <5 Y estrés >8
    if (sleepQuality < 5 && stressLevel > 8) return 0.8;

    return 1.0; // Default
  }

  /// Factor de edad (0.75 - 1.0)
  ///
  /// Ajuste de volumen por edad según literatura científica.
  /// La capacidad de recuperación disminuye con la edad.
  double get ageFactor {
    if (age < 30) return 1.0;
    if (age < 40) return 0.95;
    if (age < 50) return 0.9;
    if (age < 60) return 0.85;
    return 0.75;
  }

  /// Factor calórico (0.7 - 1.1)
  ///
  /// Ajuste de volumen según balance calórico.
  /// Déficit calórico reduce capacidad de recuperación.
  double get caloricFactor {
    if (deficitOrSurplus <= -600) return 0.7; // Déficit severo
    if (deficitOrSurplus <= -300) return 0.85; // Déficit moderado
    if (deficitOrSurplus < 200) return 1.0; // Mantenimiento
    return 1.1; // Superávit
  }

  /// Factor combinado de ajuste (producto de todos los factores)
  ///
  /// Se aplica al MAV base para obtener el MAV individualizado.
  /// Rango típico: 0.50 - 1.50
  double get totalAdjustmentFactor {
    return recoveryFactor * ageFactor * caloricFactor * geneticResponseFactor;
  }

  /// Indica si el cliente necesita deload inmediato
  ///
  /// Criterios de deload:
  /// - Sueño <5 Y estrés >8
  /// - Energía <4
  bool get needsDeload {
    if (sleepQuality < 5 && stressLevel > 8) return true;
    if (energyLevel < 4) return true;
    return false;
  }

  /// Convierte el perfil a un Map (para serialización)
  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'experience': experience.name,
      'age': age,
      'availableDaysPerWeek': availableDaysPerWeek,
      'goal': goal.name,
      'sleepQuality': sleepQuality,
      'stressLevel': stressLevel,
      'energyLevel': energyLevel,
      'caloricBalance': caloricBalance.name,
      'deficitOrSurplus': deficitOrSurplus,
      'injuries': injuries,
      'availableEquipment': availableEquipment.map((e) => e.name).toList(),
      'geneticResponseFactor': geneticResponseFactor,
      'manualMAVOverride': manualMAVOverride,
    };
  }

  @override
  String toString() {
    return 'ClientProfile(\n'
        '  id: $clientId\n'
        '  experience: ${experience.name}\n'
        '  age: $age (factor: ${ageFactor.toStringAsFixed(2)})\n'
        '  recovery: ${recoveryFactor.toStringAsFixed(2)}\n'
        '  caloric: ${caloricFactor.toStringAsFixed(2)}\n'
        '  total adjustment: ${totalAdjustmentFactor.toStringAsFixed(2)}\n'
        '  needsDeload: $needsDeload\n'
        ')';
  }
}

/// Nivel de experiencia del cliente
///
/// REFERENCIAS: 01-volume.md
/// - Ultra Beginner: <3 meses de entrenamiento
/// - Beginner: 3-12 meses
/// - Intermediate: 1-3 años
/// - Advanced: 3-5 años
/// - Elite: 5+ años
enum ExperienceLevel {
  /// <3 meses de entrenamiento estructurado
  ultraBeginner,

  /// 3-12 meses de entrenamiento consistente
  beginner,

  /// 1-3 años de entrenamiento consistente
  intermediate,

  /// 3-5 años de entrenamiento consistente
  advanced,

  /// 5+ años de entrenamiento consistente
  elite,
}

/// Objetivo principal del entrenamiento
enum Goal {
  /// Maximizar hipertrofia muscular
  hypertrophy,

  /// Maximizar fuerza (1-5 reps)
  strength,

  /// Resistencia muscular (15-30 reps)
  endurance,

  /// Fitness general (mix de objetivos)
  general,
}

/// Balance calórico actual
enum CaloricBalance {
  /// Déficit severo (>-500 kcal)
  deficitSevere,

  /// Déficit moderado (-200 a -500 kcal)
  deficitModerate,

  /// Mantenimiento (-200 a +200 kcal)
  maintenance,

  /// Superávit (+200 kcal o más)
  surplus,
}

/// Equipo disponible para entrenar
enum Equipment {
  /// Barra olímpica
  barbell,

  /// Mancuernas
  dumbbells,

  /// Máquinas de gimnasio
  machine,

  /// Poleas/cables
  cable,

  /// Peso corporal
  bodyweight,

  /// Bandas elásticas
  bands,
}
