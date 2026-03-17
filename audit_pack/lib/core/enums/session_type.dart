enum SessionType { strength, hypertrophy, conditioning, mobility, mixed }

extension SessionTypeX on SessionType {
  String get label => switch (this) {
        SessionType.strength => 'Fuerza',
        SessionType.hypertrophy => 'Hipertrofia',
        SessionType.conditioning => 'Condicionamiento',
        SessionType.mobility => 'Movilidad',
        SessionType.mixed => 'Mixto',
      };
}
