enum MuscleKey {
  chest,
  back,
  lats,
  traps,
  shoulders,
  biceps,
  triceps,
  forearms,
  quads,
  hamstrings,
  glutes,
  calves,
  abs,
  fullBody;

  static MuscleKey? fromRaw(String raw) {
    final key = raw
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('_', '')
        .replaceAll('-', '');

    for (final m in MuscleKey.values) {
      if (m.name.toLowerCase() == key) return m;
    }
    return null;
  }
}
