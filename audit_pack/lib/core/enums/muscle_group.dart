enum MuscleGroup {
  // ════════════════════════════════════════════════════════════════
  // UPPER BODY
  // ════════════════════════════════════════════════════════════════
  chest,
  back, // Espalda alta genérico (compatibilidad V1)
  lats,
  traps,
  shoulders, // Hombros genérico (compatibilidad V1)
  biceps,
  triceps,
  forearms,

  // ════════════════════════════════════════════════════════════════
  // UPPER BODY - ESPECÍFICOS V2 (agregados para motor científico)
  // ════════════════════════════════════════════════════════════════

  /// Espalda superior (trapecios medios, romboides) - separado de lats
  upperBack,

  /// Deltoides anterior (hombro frontal)
  shoulderAnterior,

  /// Deltoides lateral (hombro medio/lateral)
  shoulderLateral,

  /// Deltoides posterior (hombro trasero)
  shoulderPosterior,

  // ════════════════════════════════════════════════════════════════
  // LOWER BODY
  // ════════════════════════════════════════════════════════════════
  quads,
  hamstrings,
  glutes,
  calves,

  // ════════════════════════════════════════════════════════════════
  // CORE
  // ════════════════════════════════════════════════════════════════
  abs,

  // ════════════════════════════════════════════════════════════════
  // SPECIALTY
  // ════════════════════════════════════════════════════════════════

  /// Espalda baja / erectores espinales
  lowerBack,

  /// Ejercicios compuestos globales (burpees, clean & jerk)
  fullBody,
}

extension MuscleGroupX on MuscleGroup {
  String get label {
    switch (this) {
      case MuscleGroup.chest:
        return 'Pectoral';
      case MuscleGroup.back:
        return 'Espalda Alta';
      case MuscleGroup.lats:
        return 'Dorsales';
      case MuscleGroup.traps:
        return 'Trapecios';
      case MuscleGroup.shoulders:
        return 'Hombros';
      case MuscleGroup.biceps:
        return 'Bíceps';
      case MuscleGroup.triceps:
        return 'Tríceps';
      case MuscleGroup.forearms:
        return 'Antebrazos';
      case MuscleGroup.quads:
        return 'Cuádriceps';
      case MuscleGroup.hamstrings:
        return 'Isquiosurales';
      case MuscleGroup.glutes:
        return 'Glúteos';
      case MuscleGroup.calves:
        return 'Pantorrillas';
      case MuscleGroup.abs:
        return 'Abdomen';
      case MuscleGroup.fullBody:
        return 'Cuerpo Completo';

      // ════════════════════════════════════════════════════════════════
      // LABELS V2 (nuevos)
      // ════════════════════════════════════════════════════════════════

      case MuscleGroup.upperBack:
        return 'Espalda Superior';
      case MuscleGroup.shoulderAnterior:
        return 'Hombro Anterior';
      case MuscleGroup.shoulderLateral:
        return 'Hombro Lateral';
      case MuscleGroup.shoulderPosterior:
        return 'Hombro Posterior';
      case MuscleGroup.lowerBack:
        return 'Espalda Baja';
    }
  }

  /// Key canónica para persistencia (compatible con motor V1)
  String get canonicalKey {
    switch (this) {
      case MuscleGroup.chest:
        return 'chest';
      case MuscleGroup.back:
        return 'upper_back';
      case MuscleGroup.lats:
        return 'lats';
      case MuscleGroup.traps:
        return 'traps';
      case MuscleGroup.shoulders:
        return 'deltoide_lateral'; // Default a lateral
      case MuscleGroup.biceps:
        return 'biceps';
      case MuscleGroup.triceps:
        return 'triceps';
      case MuscleGroup.forearms:
        return 'forearms';
      case MuscleGroup.quads:
        return 'quads';
      case MuscleGroup.hamstrings:
        return 'hamstrings';
      case MuscleGroup.glutes:
        return 'glutes';
      case MuscleGroup.calves:
        return 'calves';
      case MuscleGroup.abs:
        return 'abs';
      case MuscleGroup.fullBody:
        return 'full_body';
      case MuscleGroup.upperBack:
        return 'upper_back';
      case MuscleGroup.shoulderAnterior:
        return 'deltoide_anterior';
      case MuscleGroup.shoulderLateral:
        return 'deltoide_lateral';
      case MuscleGroup.shoulderPosterior:
        return 'deltoide_posterior';
      case MuscleGroup.lowerBack:
        return 'lower_back';
    }
  }

  /// Categoría (upper/lower/core)
  String get category {
    switch (this) {
      case MuscleGroup.chest:
      case MuscleGroup.back:
      case MuscleGroup.lats:
      case MuscleGroup.traps:
      case MuscleGroup.shoulders:
      case MuscleGroup.biceps:
      case MuscleGroup.triceps:
      case MuscleGroup.forearms:
      case MuscleGroup.upperBack:
      case MuscleGroup.shoulderAnterior:
      case MuscleGroup.shoulderLateral:
      case MuscleGroup.shoulderPosterior:
        return 'upper';
      case MuscleGroup.quads:
      case MuscleGroup.hamstrings:
      case MuscleGroup.glutes:
      case MuscleGroup.calves:
        return 'lower';
      case MuscleGroup.abs:
      case MuscleGroup.lowerBack:
        return 'core';
      case MuscleGroup.fullBody:
        return 'full_body';
    }
  }

  /// Es músculo upper body
  bool get isUpper => category == 'upper';

  /// Es músculo lower body
  bool get isLower => category == 'lower';

  /// Es músculo core
  bool get isCore => category == 'core';

  /// Es músculo grande (compounds principales)
  bool get isLargeMuscle {
    return [
      MuscleGroup.chest,
      MuscleGroup.lats,
      MuscleGroup.quads,
      MuscleGroup.hamstrings,
      MuscleGroup.glutes,
    ].contains(this);
  }

  /// Es músculo pequeño (accesorios)
  bool get isSmallMuscle => !isLargeMuscle;
}

/// Helper para parsear desde string
MuscleGroup? muscleGroupFromString(String str) {
  final normalized = str.toLowerCase().trim().replaceAll('_', '');

  // Mapeo directo desde enum name
  for (final muscle in MuscleGroup.values) {
    if (muscle.name == normalized) return muscle;
  }

  // Mapeo desde canonical key (compatibilidad V1)
  for (final muscle in MuscleGroup.values) {
    if (muscle.canonicalKey.replaceAll('_', '') == normalized) return muscle;
  }

  // Aliases comunes
  switch (normalized) {
    case 'pecho':
    case 'pectorales':
      return MuscleGroup.chest;
    case 'dorsales':
    case 'espalda':
      return MuscleGroup.lats;
    case 'hombros':
    case 'deltoides':
      return MuscleGroup.shoulders;
    case 'cuadriceps':
      return MuscleGroup.quads;
    case 'femorales':
    case 'isquiotibiales':
      return MuscleGroup.hamstrings;
    case 'gluteos':
      return MuscleGroup.glutes;
    case 'pantorrillas':
    case 'gemelos':
      return MuscleGroup.calves;
    case 'abdominales':
    case 'core':
      return MuscleGroup.abs;
    case 'deltoideanterior':
    case 'hombroanterior':
      return MuscleGroup.shoulderAnterior;
    case 'deltoidelateral':
    case 'hombrolateral':
      return MuscleGroup.shoulderLateral;
    case 'deltoideposterior':
    case 'hombroposterior':
      return MuscleGroup.shoulderPosterior;
    case 'espaldaalta':
    case 'espaldas':
      return MuscleGroup.upperBack;
    case 'espaldabaja':
      return MuscleGroup.lowerBack;
    default:
      return null;
  }
}

/// Grupos musculares canónicos (14 principales para motor V2)
const List<MuscleGroup> canonicalMuscleGroups = [
  MuscleGroup.chest,
  MuscleGroup.lats,
  MuscleGroup.upperBack,
  MuscleGroup.traps,
  MuscleGroup.shoulderAnterior,
  MuscleGroup.shoulderLateral,
  MuscleGroup.shoulderPosterior,
  MuscleGroup.biceps,
  MuscleGroup.triceps,
  MuscleGroup.quads,
  MuscleGroup.hamstrings,
  MuscleGroup.glutes,
  MuscleGroup.calves,
  MuscleGroup.abs,
];

/// Grupos musculares upper body
const List<MuscleGroup> upperBodyMuscles = [
  MuscleGroup.chest,
  MuscleGroup.lats,
  MuscleGroup.upperBack,
  MuscleGroup.traps,
  MuscleGroup.shoulderAnterior,
  MuscleGroup.shoulderLateral,
  MuscleGroup.shoulderPosterior,
  MuscleGroup.biceps,
  MuscleGroup.triceps,
];

/// Grupos musculares lower body
const List<MuscleGroup> lowerBodyMuscles = [
  MuscleGroup.quads,
  MuscleGroup.hamstrings,
  MuscleGroup.glutes,
  MuscleGroup.calves,
];

/// Grupos musculares core
const List<MuscleGroup> coreMuscles = [MuscleGroup.abs, MuscleGroup.lowerBack];
