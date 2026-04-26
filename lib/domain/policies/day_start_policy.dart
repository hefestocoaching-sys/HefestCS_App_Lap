/// Contrato Fase 2 para inicio del día.
///
/// Regla: el día inicia con el músculo primario dominante.
class DayStartPolicy {
  static String resolvePrimaryMuscle({
    required Map<String, int> dayAllocation,
    required Map<String, int> priorities,
  }) {
    if (dayAllocation.isEmpty) {
      return '';
    }

    return dayAllocation.keys.reduce((a, b) {
      final aScore = (dayAllocation[a] ?? 0) * 10 + (priorities[a] ?? 0);
      final bScore = (dayAllocation[b] ?? 0) * 10 + (priorities[b] ?? 0);
      return aScore >= bScore ? a : b;
    });
  }
}
