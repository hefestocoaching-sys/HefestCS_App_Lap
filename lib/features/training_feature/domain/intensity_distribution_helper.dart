class IntensityDistributionComputation {
  final int total;
  final int heavy;
  final int medium;
  final int light;

  const IntensityDistributionComputation({
    required this.total,
    required this.heavy,
    required this.medium,
    required this.light,
  });
}

class IntensityDistributionHelper {
  IntensityDistributionHelper._();

  static const int minHeavy = 15;
  static const int maxHeavy = 30;
  static const int minMedium = 40;
  static const int maxMedium = 70;
  static const int minLight = 15;
  static const int maxLight = 30;

  static bool isValidPercentSplit({
    required int heavy,
    required int medium,
    required int light,
  }) {
    final total = heavy + medium + light;
    if (total != 100) return false;
    if (heavy < minHeavy || heavy > maxHeavy) return false;
    if (medium < minMedium || medium > maxMedium) return false;
    if (light < minLight || light > maxLight) return false;
    return true;
  }

  static IntensityDistributionComputation computeSeriesBreakdown({
    required int totalSeries,
    required int heavyPercent,
    required int lightPercent,
  }) {
    final heavy = _roundHalfUp(totalSeries * (heavyPercent / 100.0));
    final light = _roundHalfUp(totalSeries * (lightPercent / 100.0));
    final medium = totalSeries - heavy - light;

    return IntensityDistributionComputation(
      total: totalSeries,
      heavy: heavy,
      medium: medium,
      light: light,
    );
  }

  static int _roundHalfUp(double value) {
    final truncated = value.truncate();
    final decimal = value - truncated;
    if (decimal >= 0.5) return truncated + 1;
    return truncated;
  }
}
