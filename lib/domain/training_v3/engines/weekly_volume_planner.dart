import 'package:hcs_app_lap/domain/constants/volume_progression.dart';

/// Planificador de volumen semanal determinístico (Motor V3)
///
/// Responsable de calcular el volumen exacto para cada músculo en cada semana
/// basándose en reglas científicas y prioridades, sin aleatoriedad.
class WeeklyVolumePlanner {
  static final Map<String, dynamic> _decisionTrace = {};

  /// Construye el volumen para una semana específica
  static Map<String, int> buildWeekVolume({
    required Map<String, int> baseVop,
    required Map<String, int> mevByMuscle,
    required Map<String, int> mrvByMuscle,
    required Map<String, int> priorities,
    required String trainingLevel,
    required int weekNumber,
    required String phase,
    required Map<String, dynamic> feedback,
  }) {
    final weekVolume = <String, int>{};
    final weekTrace = <String, String>{};

    // Reset decision trace for this week if starting fresh
    if (weekNumber == 1) {
      _decisionTrace.clear();
      _decisionTrace['baseVop'] = baseVop;
    }

    // 1. Base case: Week 1 is always Base VOP (adjusted by phase start if needed, but usually VOP)
    if (weekNumber == 1) {
      baseVop.forEach((muscle, sets) {
        weekVolume[muscle] = sets;
        weekTrace[muscle] = 'Week 1: Base VOP';
      });
      _recordTrace(weekNumber, weekVolume, weekTrace);
      return weekVolume;
    }

    // 2. Progression logic for subsequent weeks
    for (final muscle in baseVop.keys) {
      final startSets = baseVop[muscle] ?? 10; // Fallback safe
      final currentMev = mevByMuscle[muscle] ?? 8;
      final currentMrv = mrvByMuscle[muscle] ?? 20; // Default safe cap
      final priority = priorities[muscle] ?? 3; // Default secondary

      int newSets = startSets;
      String decision = '';

      switch (phase) {
        case 'accumulation':
          // Logic: Progressive overload based on priorities
          final incrementBase = VolumeProgression.getIncrement(trainingLevel);
          final weeksInterval = VolumeProgression.getWeeksInterval(
            trainingLevel,
          );

          // Check if this week is an increment week
          // Week 1: Base. Week 2: +Inc? No, usually after interval.
          // But req says: Week 2..WkEnd: increment based on rules.
          // Let's interpret "Week 2..WkEnd" as potential increment points.
          // Standard linear: Increment every 'weeksInterval' weeks.
          // Example: Beginner (Int=3). W1=Base, W2=Base, W3=Base, W4=+2.
          // However, user requirement implies "buildWeekVolume" calculates FOR that week.
          // We need to calculate cumulative increment.

          final incrementsCount = (weekNumber - 1) ~/ weeksInterval;

          if (incrementsCount > 0) {
            int totalIncrement = 0;

            if (priority == 5) {
              // Primario: Full increment
              totalIncrement = incrementBase * incrementsCount;
              decision =
                  'Accumulation (P5): +$totalIncrement sets ($incrementsCount jumps)';
            } else if (priority >= 3) {
              // Secundario: Half increment (ceil)
              final halfInc = (incrementBase / 2).ceil();
              totalIncrement = halfInc * incrementsCount;
              decision =
                  'Accumulation (P3-4): +$totalIncrement sets ($incrementsCount jumps)';
            } else {
              // Terciario: Maintenance or very slight (+1 max total typically, or Just Base)
              // Req: "mantener o +1 máximo"
              totalIncrement = incrementsCount > 0
                  ? 1
                  : 0; // Cap at +1 total for the block
              decision =
                  'Accumulation (P2): +$totalIncrement set (Maintenance)';
            }
            newSets += totalIncrement;
          } else {
            decision = 'Accumulation: Base VOP (Building constraint)';
          }

          // Clamp MEV - MRV
          final allowMrv = feedback['allowMRV'] == true;
          final safeCap = allowMrv ? currentMrv : (currentMrv - 1);

          if (newSets > safeCap) {
            newSets = safeCap;
            decision += ' [Capped at MRV-1]';
          }
          if (newSets < currentMev) {
            newSets = currentMev;
            decision += ' [Boosted to MEV]';
          }
          break;

        case 'intensification':
          // Logic: -10% volume, intensity managed elsewhere
          // Base reference is PREVIOUS WEEK (Week - 1)
          // Since this function is stateless, we calculate based on Accumulation logic for Week-1 then cut.
          // OR simpler: Input 'baseVop' is usually the starting point.
          // If we assume linear from BaseVOP:
          // We calculate what Accumulation WOULD have given for this week, then cut 10%.

          // Let's presume Intensification follows an Accumulation block.
          // We calculate the theoretical accumulation volume for this week, then apply drop.

          final theoreticalAccum = _calculateAccumulationVolume(
            startSets,
            priority,
            trainingLevel,
            weekNumber,
            incrementBase: VolumeProgression.getIncrement(trainingLevel),
            interval: VolumeProgression.getWeeksInterval(trainingLevel),
          );

          newSets = (theoreticalAccum * 0.90).round();
          if (newSets < currentMev) newSets = currentMev;
          decision = 'Intensification: -10% volume (Targeting intensity)';
          break;

        case 'deload':
          // Logic: -50% volume
          // Usually Deload follows Accum or Intens.
          // We take the volume of the previous active week and cut 50%.
          // For simplicity/determinism: Base it on Peak Volume (Week - 1).

          final previousWeekVol = _calculateAccumulationVolume(
            startSets,
            priority,
            trainingLevel,
            weekNumber - 1,
            incrementBase: VolumeProgression.getIncrement(trainingLevel),
            interval: VolumeProgression.getWeeksInterval(trainingLevel),
          );

          newSets = (previousWeekVol * 0.50).round();
          if (newSets < currentMev) {
            newSets = currentMev; // Ensure minimum stimulus
          }
          decision = 'Deload: -50% volume (Recovery)';
          break;

        default:
          newSets = startSets;
          decision = 'Unknown phase: Base VOP';
      }

      weekVolume[muscle] = newSets;
      weekTrace[muscle] = decision;
    }

    _recordTrace(weekNumber, weekVolume, weekTrace);
    return weekVolume;
  }

  static int _calculateAccumulationVolume(
    int start,
    int priority,
    String level,
    int week, {
    required int incrementBase,
    required int interval,
  }) {
    if (week <= 1) return start;
    final jumps = (week - 1) ~/ interval;
    if (jumps <= 0) return start;

    int added = 0;
    if (priority == 5) {
      added = incrementBase * jumps;
    } else if (priority >= 3) {
      added = (incrementBase / 2).ceil() * jumps;
    } else {
      added = 1; // Max +1 for Tertiary
    }
    return start + added;
  }

  static void _recordTrace(
    int week,
    Map<String, int> vols,
    Map<String, String> reasons,
  ) {
    if (!_decisionTrace.containsKey('weekDecisions')) {
      _decisionTrace['weekDecisions'] = <String, dynamic>{};
    }
    if (!_decisionTrace.containsKey('weekVolumes')) {
      _decisionTrace['weekVolumes'] = <String, dynamic>{};
    }

    (_decisionTrace['weekDecisions'] as Map)[week.toString()] = reasons;
    (_decisionTrace['weekVolumes'] as Map)[week.toString()] = vols;
  }

  static Map<String, dynamic> buildDecisionTrace() {
    return Map<String, dynamic>.from(_decisionTrace);
  }
}
