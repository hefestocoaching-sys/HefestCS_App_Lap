// lib/domain/services/phase_4_split_distribution_service.dart

/// FACHADA LEGACY para compatibilidad con tests antiguos.
class Phase4SplitDistributionService {
  const Phase4SplitDistributionService();

  @Deprecated('Legacy. Migrar a SplitDistributionEngine V3.')
  dynamic buildWeeklySplit({required Map<String, Object?> input}) {
    throw UnimplementedError('Legacy method. Use SplitDistributionEngine V3.');
  }
}
