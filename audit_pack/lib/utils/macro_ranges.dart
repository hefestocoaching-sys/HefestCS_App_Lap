class MacroRange {
  final double min;
  final double max;
  const MacroRange({required this.min, required this.max});
}

class MacroRanges {
  static const Map<String, MacroRange> protein = {
    'Sedentarias': MacroRange(min: 0.8, max: 1.2),
    'Larga Duración': MacroRange(min: 1.2, max: 1.4),
    'Intermitentes/Equipo': MacroRange(min: 1.4, max: 1.6),
    'Fuerza/Potencia': MacroRange(min: 1.6, max: 1.8),
    'Hipertrofia': MacroRange(min: 1.6, max: 2.2),
    'Recomposicion Corporal': MacroRange(min: 1.8, max: 3.6),
  };

  static const Map<String, MacroRange> lipids = {
    'Salud': MacroRange(min: 0.5, max: 1.0),
    'Musculacion': MacroRange(min: 1.0, max: 1.5),
    'Rendimiento': MacroRange(min: 1.5, max: 2.0),
  };

  static const Map<String, MacroRange> carbs = {
    'Muy Bajas': MacroRange(min: 0.5, max: 1.0),
    'Bajas': MacroRange(min: 1.0, max: 2.0),
    'Perdida-Grasa': MacroRange(min: 2.0, max: 3.0),
    'Hipertrofia Muscular': MacroRange(min: 3.0, max: 5.0),
    'Potencia/Fuerza': MacroRange(min: 5.0, max: 6.0),
    'Equipo/Intermitentes': MacroRange(min: 6.0, max: 7.0),
    'Larga Duración': MacroRange(min: 7.0, max: 9.0),
    'Ultra Resistencia': MacroRange(min: 9.0, max: 12.0),
  };
}
