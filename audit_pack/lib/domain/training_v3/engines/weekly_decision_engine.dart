/// Resultado de la evaluación semanal del Motor V3.
class WeeklyDecisionResult {
  /// Cambio neto de sets por músculo (positivo = aumentar, negativo = bajar).
  final int volumeDelta;

  /// Si se debe activar una semana de deload.
  final bool triggerDeload;

  /// Índice de fatiga calculado (escala 0–10, mayor = más fatiga).
  final double fatigueIndex;

  /// Índice de recuperación calculado (escala 0–10, mayor = mejor recuperación).
  final double recoveryIndex;

  const WeeklyDecisionResult({
    required this.volumeDelta,
    required this.triggerDeload,
    required this.fatigueIndex,
    required this.recoveryIndex,
  });
}

/// Motor de decisión semanal del Motor V3.
///
/// Evalúa los indicadores de rendimiento de la semana completada
/// y recomienda ajustes de volumen o deload.
///
/// REGLAS:
/// - avgRIR > target + 1  →  volumeDelta = +1
/// - avgRIR < target - 1  →  volumeDelta = -1
/// - recoveryScore < -1   →  volumeDelta = -10% (aproximado a -1)
/// - avgSessionRPE > 9    →  triggerDeload = true
class WeeklyDecisionEngine {
  /// RIR objetivo por defecto (zona media = 2).
  static const double _rirTarget = 2.0;

  WeeklyDecisionResult evaluate({
    required double avgRIR,
    required double avgSessionRPE,
    required double recoveryScore,
  }) {
    int volumeDelta = 0;
    bool triggerDeload = false;

    // Regla 1: RIR demasiado alto → el atleta puede hacer más
    if (avgRIR > _rirTarget + 1) {
      volumeDelta = 1;
    }

    // Regla 2: RIR demasiado bajo → el atleta está llegando al límite
    if (avgRIR < _rirTarget - 1) {
      volumeDelta = -1;
    }

    // Regla 3: Recuperación negativa → reducir volumen ~10% (≈ -1 set)
    if (recoveryScore < -1) {
      volumeDelta -= 1;
    }

    // Regla 4: RPE muy alto → activar deload
    if (avgSessionRPE > 9) {
      triggerDeload = true;
    }

    // Calcular índices
    final fatigueIndex = _computeFatigue(
      avgRIR: avgRIR,
      avgSessionRPE: avgSessionRPE,
      recoveryScore: recoveryScore,
    );
    final recoveryIndex = _computeRecovery(recoveryScore: recoveryScore);

    return WeeklyDecisionResult(
      volumeDelta: volumeDelta,
      triggerDeload: triggerDeload,
      fatigueIndex: fatigueIndex,
      recoveryIndex: recoveryIndex,
    );
  }

  /// Fatiga: promedio ponderado de RPE y déficit de recuperación.
  double _computeFatigue({
    required double avgRIR,
    required double avgSessionRPE,
    required double recoveryScore,
  }) {
    final rpeFatigue = (avgSessionRPE / 10.0).clamp(0.0, 1.0) * 10.0;
    final recFatigue = (-recoveryScore).clamp(0.0, 5.0) * 2.0;
    return ((rpeFatigue + recFatigue) / 2.0).clamp(0.0, 10.0);
  }

  /// Recuperación: convertir recoveryScore (-5..+5) a escala 0-10.
  double _computeRecovery({required double recoveryScore}) {
    return ((recoveryScore + 5.0) / 10.0 * 10.0).clamp(0.0, 10.0);
  }
}
