import 'package:hcs_app_lap/domain/entities/athlete_longitudinal_state.dart';

class LongitudinalStateUpdateService {
  /// Actualización conservadora:
  /// newMean = lerp(oldMean, observedMean, alpha)
  /// newSd = lerp(oldSd, observedSd, alphaSd) con piso mínimo
  ///
  /// alpha depende de confiabilidad de señal + adherencia + tamaño de muestra.
  AthleteLongitudinalState update({
    required AthleteLongitudinalState prior,
    required Map<String, double> observedMev,
    required Map<String, double> observedMrv,
    required double evidenceStrength, // 0..1
    required DateTime now,
  }) {
    final alpha = _clamp(0.05 + 0.45 * evidenceStrength, 0.05, 0.50);
    final alphaSd = _clamp(0.03 + 0.30 * evidenceStrength, 0.03, 0.35);

    final next = <String, MusclePosterior>{}..addAll(prior.posteriorByMuscle);

    for (final m in {...observedMev.keys, ...observedMrv.keys}) {
      final prev =
          next[m] ??
          const MusclePosterior(mevMean: 0, mevSd: 1, mrvMean: 0, mrvSd: 2);
      final oMev = observedMev[m] ?? prev.mevMean;
      final oMrv = observedMrv[m] ?? prev.mrvMean;

      // SD observada simple (puedes sofisticar con MAD/rolling window)
      final obsMevSd = _clamp(prev.mevSd, 0.75, 6.0);
      final obsMrvSd = _clamp(prev.mrvSd, 1.0, 8.0);

      final newMevMean = _lerp(prev.mevMean, oMev, alpha);
      final newMrvMean = _lerp(prev.mrvMean, oMrv, alpha);

      final newMevSd = _clamp(_lerp(prev.mevSd, obsMevSd, alphaSd), 0.75, 6.0);
      final newMrvSd = _clamp(_lerp(prev.mrvSd, obsMrvSd, alphaSd), 1.0, 8.0);

      next[m] = prev.copyWith(
        mevMean: newMevMean,
        mevSd: newMevSd,
        mrvMean: newMrvMean,
        mrvSd: newMrvSd,
      );
    }

    return prior.copyWith(
      posteriorByMuscle: next,
      lastUpdatedIso: now.toIso8601String(),
    );
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;
  double _clamp(double v, double lo, double hi) =>
      v < lo ? lo : (v > hi ? hi : v);
}
