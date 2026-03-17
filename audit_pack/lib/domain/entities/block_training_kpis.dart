class BlockTrainingKpis {
  /// Número de semanas consideradas en el bloque previo.
  final int totalWeeks;

  /// Fatiga promedio 1–10 (promedio de averageFatigue de las semanas).
  final double avgFatigue;

  /// DOMS/promedio de estímulo percibido 1–10.
  final double avgDoms;

  /// RPE promedio de la sesión 1–10.
  final double avgRpe;

  /// Adherencia promedio 0.0–1.0 (sesiones completadas / planificadas).
  final double avgAdherence;

  /// Proporción de semanas que terminaron en deload reactivo (0.0–1.0).
  final double deloadFraction;

  /// Hubo dolor articular “raro” en alguna semana del bloque.
  final bool hadWeirdPain;

  const BlockTrainingKpis({
    required this.totalWeeks,
    required this.avgFatigue,
    required this.avgDoms,
    required this.avgRpe,
    required this.avgAdherence,
    required this.deloadFraction,
    required this.hadWeirdPain,
  });

  bool get hasData => totalWeeks > 0;

  /// ¿Tenemos datos suficientemente completos como para adaptar el siguiente bloque?
  bool get hasReliableData =>
      hasData && avgAdherence >= 0.5; // < 0.5 = casi ningún dato útil.

  Map<String, dynamic> toMap() => {
    'totalWeeks': totalWeeks,
    'avgFatigue': avgFatigue,
    'avgDoms': avgDoms,
    'avgRpe': avgRpe,
    'avgAdherence': avgAdherence,
    'deloadFraction': deloadFraction,
    'hadWeirdPain': hadWeirdPain,
  };

  factory BlockTrainingKpis.fromMap(Map<String, dynamic> map) {
    return BlockTrainingKpis(
      totalWeeks: map['totalWeeks'] ?? 0,
      avgFatigue: (map['avgFatigue'] ?? 0.0).toDouble(),
      avgDoms: (map['avgDoms'] ?? 0.0).toDouble(),
      avgRpe: (map['avgRpe'] ?? 0.0).toDouble(),
      avgAdherence: (map['avgAdherence'] ?? 0.0).toDouble(),
      deloadFraction: (map['deloadFraction'] ?? 0.0).toDouble(),
      hadWeirdPain: map['hadWeirdPain'] ?? false,
    );
  }
}
