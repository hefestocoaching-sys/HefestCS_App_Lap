// lib/domain/services/phase_7_prescription_service.dart

/// FACHADA LEGACY para compatibilidad con tests antiguos.
enum RepBias { strength, hypertrophy, endurance, moderate, low, high }

class Phase7PrescriptionService {
  const Phase7PrescriptionService();

  @Deprecated('Legacy. Migrar a PrescriptionEngine V3.')
  dynamic buildPrescriptions({
    required dynamic exerciseSelections,
    required dynamic context,
  }) {
    throw UnimplementedError(
      'Phase7PrescriptionService.buildPrescriptions (legacy) no está implementado. '
      'Migrar tests a training_v3.',
    );
  }

  @Deprecated('Legacy. Migrar a PrescriptionEngine V3.')
  dynamic computeRirTarget({required Map<String, Object?> input}) {
    throw UnimplementedError('Legacy method. Use PrescriptionEngine V3.');
  }
}
