import 'package:freezed_annotation/freezed_annotation.dart';

part 'progress_record.freezed.dart';
part 'progress_record.g.dart';

/// Registro histórico COMPLETO de una semana/músculo
///
/// - Volumen prescrito vs realizado
/// - Feedback del usuario (subjetivo)
/// - Rendimiento objetivo (logs de ejercicios)
/// - Decisión tomada (acción del motor)
/// - Razón de la decisión (trazabilidad)
/// - Cobertura angular (ejercicios usados)
/// - Comentarios del coach
///
/// FUNDAMENTO CIENTÍFICO:
/// - Permite auditoría completa de cada decisión
/// - Detecta patrones para IA/ML
/// - Coach puede ver histórico y ajustar
/// - Exportable para análisis
///
/// Versión: 1.0.0
@freezed
abstract class ProgressRecord with _$ProgressRecord {
  const factory ProgressRecord({
    /// Identificadores
    required String userId,
    required String muscle,
    required int weekNumber,

    /// Volumen (sets/semana)
    required int volumePrescribed,
    required int volumePerformed,
    required double
    volumeAdherence, // 0.0-1.0 (volumePerformed/volumePrescribed)
    /// Rango de repeticiones
    required int ripRange, // RIR realizado (promedio)
    required int ripTarget, // RIR objetivo (de plan)
    /// Feedback del usuario (subjetivo, 1-10)
    required double muscleActivation, // Qué tan bien sentiste el músculo
    required double pumpQuality, // Calidad del pump
    required double fatigueLevel, // Fatiga acumulada
    required double recoveryQuality, // Calidad de recuperación
    required bool hadPain, // ¿Tuvo dolor?
    required String userComments, // Notas del usuario
    /// Progresión de volumen (objetivo)
    required String
    exerciseAngles, // Ángulos usados (ej: "plano,inclinado,declinado")
    required int exerciseVariations, // Número de ejercicios/ángulos diferentes
    /// Decisión del motor
    required String
    volumeAction, // 'increase', 'maintain', 'decrease', 'deload', 'microdeload'
    required int newVolume, // Volumen prescrpto para la siguiente semana
    required String
    progressionPhase, // 'discovering', 'maintaining', 'overreaching', 'deloading', 'microdeload'
    required String
    decisionReason, // Razón de la decisión (ej: "VMR discovered at 20 sets")
    /// Deload info
    required bool wasDeload, // ¿Fue una semana de deload?
    required String deloadReason, // Razón del deload (si procede)
    /// Timestamps
    required DateTime recordedAt, // Cuándo se registró
    required DateTime updatedAt, // Última actualización
    /// Coach notes (opcional)
    @Default('') String coachNotes, // Notas que el coach quiera agregar
    /// Metadata para auditoría
    @Default({}) Map<String, dynamic> auditMetadata,
  }) = _ProgressRecord;

  factory ProgressRecord.fromJson(Map<String, dynamic> json) =>
      _$ProgressRecordFromJson(json);
}

/// Resumen de ProgressRecord para UI/reportes
extension ProgressRecordExtension on ProgressRecord {
  /// ¿La progresión fue positiva esta semana?
  bool get wasProgressiveWeek =>
      volumeAdherence >= 0.80 &&
      muscleActivation >= 7.0 &&
      fatigueLevel <= 7.0 &&
      recoveryQuality >= 6.0 &&
      !hadPain;

  /// ¿La semana indicó necesidad de deload?
  bool get shouldDeload =>
      fatigueLevel >= 8.0 || recoveryQuality <= 4.0 || hadPain;

  /// Cambio de volumen en %
  double get volumeChangePercent {
    if (volumePrescribed == 0) return 0.0;
    return ((newVolume - volumePrescribed) / volumePrescribed) * 100;
  }

  /// Cambio de volumen absoluto
  int get volumeChange => newVolume - volumePrescribed;

  /// Está en fase de descubrimiento (VMR)
  bool get isDiscoveringVMR => progressionPhase == 'discovering';

  /// Está en mantenimiento
  bool get isMaintaining => progressionPhase == 'maintaining';

  /// Está en overreaching/fatiga acumulada
  bool get isOverreaching => progressionPhase == 'overreaching';

  /// Está en deload
  bool get isDeloading =>
      progressionPhase == 'deloading' || progressionPhase == 'microdeload';
}
