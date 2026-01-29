enum MuscleGroup {
  chest,
  back,
  lats,
  traps,
  shoulders,
  biceps,
  triceps,
  forearms,
  quads,
  hamstrings,
  glutes,
  calves,
  abs,

  // Agregado para ejercicios compuestos globales (ej. Burpees, Clean & Jerk)
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
    }
  }
}
