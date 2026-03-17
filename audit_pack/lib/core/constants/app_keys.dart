// Centralized non-UI keys used as map/category identifiers across domain/features.
// Strings are repeated in multiple services; kept here for future safe imports.

class AppKeys {
  // Decision trace and guardrails
  static const String volumeClampedFinal = 'volume_clamped_final';
  static const String guardrailClamps = 'guardrail_clamps';
  static const String engineFinalGuardrailApplied =
      'engine_final_guardrail_applied';
  static const String validationResult = 'validation_result';
  static const String volumeConfig = 'volume_config';
  static const String volumeAdjustment = 'volume_adjustment';
  static const String guardrailOverride = 'guardrail_override';
  static const String blockedMissingData = 'blocked_missing_data';
  static const String missingData = 'missing_data';
  static const String timeConstraint = 'time_constraint';
  static const String daySummary = 'day_summary';
  static const String energyUnavailable = 'energy_unavailable';

  // Intensification / prescription markers
  static const String intensificationBudget = 'intensification_budget';
  static const String intensificationApplied = 'intensification_applied';
  static const String intensificationSkippedReason =
      'intensification_skipped_reason';
  static const String restPause = 'rest_pause';
  static const String myoReps = 'myo_reps';
  static const String dropSet = 'drop_set';

  // Feedback / adherence reasons
  static const String painEventPresent = 'pain_event_present';
  static const String adherenceLow = 'adherence_low';
  static const String adherenceModerate = 'adherence_moderate';
  static const String avgEffortHigh = 'avg_effort_high';
}
