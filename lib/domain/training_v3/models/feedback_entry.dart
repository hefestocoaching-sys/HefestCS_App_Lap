import 'package:freezed_annotation/freezed_annotation.dart';

part 'feedback_entry.freezed.dart';
part 'feedback_entry.g.dart';

/// Entrada de feedback/bitácora del usuario para un MÚSCULO en una SEMANA
///
/// Captura solo lo SUBJETIVO (cómo se sintió el usuario):
/// - Activación muscular
/// - Calidad del pump
/// - Nivel de fatiga
/// - Calidad de recuperación
/// - Dolor o lesión
/// - Comentarios del usuario
/// - Triggers de deload manual
///
/// RELACIÓN:
/// - N FeedbackEntry por usuario/semana (uno por músculo)
/// - ProgressRecord integra esto + datos objetivos
///
/// Versión: 1.0.0
@freezed
abstract class FeedbackEntry with _$FeedbackEntry {
  const factory FeedbackEntry({
    /// Identificadores
    required String userId,
    required String muscle,
    required int weekNumber,
    required DateTime weekStart,
    required DateTime weekEnd,

    /// Ratings subjetivos (escala 1-10 o 0-10)
    required double
    muscleActivation, // ¿Sentiste bien el músculo? (8=bien, 3=mal)
    required double pumpQuality, // Calidad del pump (8=excelente, 2=nada)
    required double fatigueLevel, // Fatiga acumulada (1=nada, 10=máxima)
    required double
    recoveryQuality, // Calidad de recuperación entre sesiones (1=pésima, 10=perfecta)
    /// Flags
    required bool hadPain, // ¿Tuvo dolor o molestia?
    required bool deloadRequested, // ¿Solicita deload manual? (coach override)
    @Default(false) bool isInjury, // ¿Hay lesión?
    /// Notas libres
    required String userComments, // Cliente escribe qué pasó
    /// Coach override (después de leer feedback)
    @Default('') String coachFeedback, // Coach agrega contexto/notas
    /// Timestamps
    required DateTime submittedAt, // Cuándo se envió el feedback
    @Default(null) DateTime? coachReviewedAt, // Cuándo lo revisó el coach
    /// Metadata
    @Default({}) Map<String, dynamic> metadata,
  }) = _FeedbackEntry;

  factory FeedbackEntry.fromJson(Map<String, dynamic> json) =>
      _$FeedbackEntryFromJson(json);
}

/// Utilidades para FeedbackEntry
extension FeedbackEntryExtension on FeedbackEntry {
  /// Score de "salud" general del músculo (0-100)
  double get healthScore {
    // Combina los scores para dar un score general
    const weight1 = 0.25; // muscleActivation más importante
    const weight2 = 0.25; // pumpQuality
    const weight3 = -0.25; // fatigueLevel (inverso, negativo)
    const weight4 = 0.25; // recoveryQuality

    var score =
        (muscleActivation * weight1 +
        pumpQuality * weight2 +
        (10 - fatigueLevel) * weight3 +
        recoveryQuality * weight4);

    score = score.clamp(0.0, 100.0);
    return score;
  }

  /// ¿Está el usuario reportando fatiga excesiva?
  bool get hasExcessiveFatigue => fatigueLevel >= 8.0;

  /// ¿Reporta recuperación pobre?
  bool get hasPoorRecovery => recoveryQuality <= 4.0;

  /// ¿Indica problema de lesión/dolor?
  bool get hasPainOrInjury => hadPain || isInjury;

  /// ¿Solicita deload o hay señales de deload necesario?
  bool get needsDeload =>
      deloadRequested ||
      hasExcessiveFatigue ||
      hasPoorRecovery ||
      hasPainOrInjury;

  /// Score de "confianza" en hacer más volumen (0-1)
  double get progressionConfidence {
    if (needsDeload) return 0.0;
    if (healthScore < 40) return 0.2;
    if (healthScore < 60) return 0.5;
    if (healthScore < 80) return 0.8;
    return 1.0;
  }
}
