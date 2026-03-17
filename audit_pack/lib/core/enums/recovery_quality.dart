enum RecoveryQuality { recovered, partial, fatigued }

extension RecoveryQualityX on RecoveryQuality {
  String get label => switch (this) {
    RecoveryQuality.recovered => 'Recuperado',
    RecoveryQuality.partial => 'Parcialmente recuperado',
    RecoveryQuality.fatigued => 'Fatigado',
  };
}

RecoveryQuality? parseRecoveryQuality(String? value) {
  if (value == null) return null;
  final normalized = value.toLowerCase().trim();

  if (normalized.contains('recuperado') ||
      normalized.contains('recovered') ||
      normalized.contains('bien') ||
      normalized.contains('excelente') ||
      normalized.contains('buena')) {
    return RecoveryQuality.recovered;
  }
  if (normalized.contains('parcial') ||
      normalized.contains('partial') ||
      normalized.contains('regular') ||
      normalized.contains('medio')) {
    return RecoveryQuality.partial;
  }
  if (normalized.contains('fatigado') ||
      normalized.contains('fatigued') ||
      normalized.contains('cansado') ||
      normalized.contains('mala')) {
    return RecoveryQuality.fatigued;
  }

  return null;
}
