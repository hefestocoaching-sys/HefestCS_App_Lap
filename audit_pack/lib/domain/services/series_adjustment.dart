import 'dart:math';

Map<String, int> adjustSeries({
  required Map<String, int> baseSeries,
  required double adherence, // 0–100 %
  required double fatigue, // 1–5
  required double rirAverage, // 0–5
  required String blockName,
}) {
  final output = <String, int>{};

  baseSeries.forEach((muscle, sets) {
    int newSets = sets;

    // 1. Adherencia
    if (adherence < 60) {
      newSets = (newSets * 0.7).round();
    } else if (adherence < 80) {
      newSets = (newSets * 0.9).round();
    } else if (adherence > 95) {
      newSets = (newSets * 1.05).round();
    }

    // 2. Fatiga
    if (fatigue >= 4.5) {
      newSets = max(1, (newSets * 0.7).round());
    } else if (fatigue >= 4) {
      newSets = max(1, (newSets * 0.85).round());
    } else if (fatigue <= 2) {
      newSets = (newSets * 1.1).round();
    }

    // 3. RIR alto (estímulo insuficiente)
    if (rirAverage >= 3.5) {
      newSets = (newSets * 1.15).round();
    }

    // 4. RIR muy bajo (fallo constante)
    if (rirAverage <= 1.0) {
      newSets = max(1, (newSets * 0.8).round());
    }

    output[muscle] = max(1, newSets);
  });

  return output;
}
