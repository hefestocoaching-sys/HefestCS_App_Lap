/// Unifica todas las métricas de feedback del atleta para una semana.
///
/// Este objeto es la entrada principal para el motor de adaptación, permitiendo
/// tomar decisiones informadas sobre la progresión del volumen e intensidad.
class TrainingFeedback {
  final double fatigue; // 1–10
  final double soreness; // 1–10
  final double motivation; // 1–10
  final double adherence; // 0–1 (ej: 0.85 = 85 %)
  final double avgRir; // promedio semanal
  final double sleepHours; // 0–12
  final double stressLevel; // 1–10
  final double heavySets;
  final double lightSets;

  const TrainingFeedback({
    required this.fatigue,
    required this.soreness,
    required this.motivation,
    required this.adherence,
    required this.avgRir,
    required this.sleepHours,
    required this.stressLevel,
    this.heavySets = 0.0,
    this.lightSets = 0.0,
  });

  /// Estado inicial o sin feedback aún (valores neutrales).
  factory TrainingFeedback.initial() {
    return const TrainingFeedback(
      fatigue: 5.0,
      soreness: 5.0,
      motivation: 5.0,
      adherence: 1.0,
      avgRir: 2.5,
      sleepHours: 7.5,
      stressLevel: 5.0,
    );
  }

  /// Carga de fatiga combinada: fatiga + dolor + falta de motivación.
  double get fatigueLoad => fatigue + soreness + (10 - motivation);

  /// Puntuación de recuperación: pondera el sueño contra el estrés.
  double get recoveryScore =>
      (sleepHours / 8.0).clamp(0.0, 1.5) - (stressLevel * 0.05);
}
