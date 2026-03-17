// lib/domain/services/phase_5_periodization_service.dart

/// FACHADA LEGACY para compatibilidad con tests antiguos.
class Phase5PeriodizationService {
  const Phase5PeriodizationService();

  @Deprecated('Legacy. Migrar a PeriodizationEngine V3.')
  dynamic periodize({required Map<String, Object?> input}) {
    throw UnimplementedError('Legacy method. Use PeriodizationEngine V3.');
  }
}

/// Legacy types usados por tests viejos:
class Phase5PeriodizationResult {
  const Phase5PeriodizationResult();
}

class PeriodizedWeek {
  const PeriodizedWeek();
}
