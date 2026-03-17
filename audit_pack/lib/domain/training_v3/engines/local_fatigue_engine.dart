class LocalFatigueEngine {
  bool needsLocalDeload({
    required double localFatigue,
    required double localRecovery,
    required int weeksAccumulating,
    int? performanceDeclineStreak,
  }) {
    if (localFatigue >= 8.0) return true;
    if (localRecovery <= 3.0) return true;
    if (weeksAccumulating >= 4) return true;
    if ((performanceDeclineStreak ?? 0) >= 2) return true;
    return false;
  }
}
