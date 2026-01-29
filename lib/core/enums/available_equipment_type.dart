enum AvailableEquipmentType {
  gym, // Gimnasio comercial completo
  dumbbells, // Solo mancuernas
  barbell, // Barra y discos
  bands, // Bandas de resistencia
  bodyweight, // Calistenia / Peso corporal
  machines, // Máquinas guiadas
  cables, // Poleas
  smithMachine, // Multipower
  cardio, // Cinta, elíptica, etc.
}

extension AvailableEquipmentTypeX on AvailableEquipmentType {
  String get label {
    switch (this) {
      case AvailableEquipmentType.gym:
        return 'Gimnasio Completo';
      case AvailableEquipmentType.dumbbells:
        return 'Mancuernas';
      case AvailableEquipmentType.barbell:
        return 'Barra Olímpica';
      case AvailableEquipmentType.bands:
        return 'Bandas Elásticas';
      case AvailableEquipmentType.bodyweight:
        return 'Peso Corporal';
      case AvailableEquipmentType.machines:
        return 'Máquinas';
      case AvailableEquipmentType.cables:
        return 'Poleas';
      case AvailableEquipmentType.smithMachine:
        return 'Máquina Smith';
      case AvailableEquipmentType.cardio:
        return 'Equipo Cardio';
    }
  }
}
