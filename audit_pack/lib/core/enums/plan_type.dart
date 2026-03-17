enum PlanType { loss, maintenance, gain }

extension PlanTypeX on PlanType {
  String get label => switch (this) {
    PlanType.loss => 'Pérdida',
    PlanType.maintenance => 'Mantenimiento',
    PlanType.gain => 'Ganancia',
  };
}
