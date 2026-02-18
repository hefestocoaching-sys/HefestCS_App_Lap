import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hcs_app_lap/domain/training_v3/models/volume_landmarks.dart';

part 'muscle_progression.freezed.dart';
part 'muscle_progression.g.dart';

/// Progresión científica de un MÚSCULO con lógica explícita de prioridades
///
/// LÓGICA DE PRIORIDADES:
/// - PRIMARIO (P/5): Progresa hasta MRV, puede deload y reiniciar
/// - SECUNDARIO (S/3): Progresa hasta 0.8×MRV, puede deload más
/// - TERCIARIO (T/1): Siempre VOP, nunca sube ni baja
///
/// CICLOS DE PROGRESIÓN:
/// 1. Discovering: Sube sets semanalmente hasta encontrar MRV
/// 2. Maintaining: Se mantiene en MRV (o 0.8×MRV para S)
/// 3. Overreaching: Fatiga acumulada (días 25-35 del ciclo típico)
/// 4. Deloading: Reduce volumen 40-50%, permite recuperación
///
/// FEEDBACK INTEGRATION:
/// - Feedback alto (muscle_activation ≥8, fatiga ≤5): Progresa
/// - Feedback normal: Mantiene
/// - Feedback bajo (fatiga ≥8, recuperación ≤4): Deload
///
/// Versión: 1.0.0
@freezed
abstract class MuscleProgression with _$MuscleProgression {
  const factory MuscleProgression({
    /// Identificación
    required String muscle,
    required int priority, // 5=P(primary), 3=S(secondary), 1=T(tertiary)
    /// Volumen landmarks científicos
    required VolumeLandmarks landmarks, // MEV, VOP, MRV, MRV_target
    /// Estado actual
    required int currentSets, // Sets/semana ACTUAL
    required int vopSets, // VOP específico para este músculo/usuario
    required int mrvSets, // MRV descubierto o estimado
    required bool hasDiscoveredMRV, // ¿Se encontró MRV empíricamente?
    /// Progresión en ciclo
    required String
    currentPhase, // 'discovering'|'maintaining'|'overreaching'|'deloading'
    required int weeksInCurrentPhase,
    required int totalWeeksInTraining,

    /// Control de deload
    required int weeksSinceDeload, // Semanas desde último deload
    required int weeksUntilAutoDeload, // Estimado (4-5 para P, 5-6 para S)
    required bool isAutoDeloadScheduled, // ¿Deload automático programado?
    /// Histórico resumido (últimas 4 semanas)
    @Default([]) List<int> last4WeeksVolume, // [week-3, week-2, week-1, week0]
    @Default([])
    List<double> last4WeeksAdherence, // Adherencia % | last exercise efficiency
    @Default([]) List<String> last4WeeksPhase, // Fases | progression_state
    /// Metadata
    required DateTime createdAt,
    required DateTime lastUpdated,
    required DateTime lastDeloadDate,

    /// Notas
    @Default('') String notes, // Coach notes
  }) = _MuscleProgression;

  factory MuscleProgression.fromJson(Map<String, dynamic> json) =>
      _$MuscleProgressionFromJson(json);
}

/// Lógica de negocio para MuscleProgression
extension MuscleProgressionExtension on MuscleProgression {
  /// ¿Es músculo PRIMARIO?
  bool get isPrimary => priority == 5;

  /// ¿Es múscyl SECUNDARIO?
  bool get isSecondary => priority == 3;

  /// ¿Es músculo TERCIARIO?
  bool get isTertiary => priority == 1;

  /// Tope de sets según prioridad
  int get volumeCap {
    if (isPrimary) return mrvSets;
    if (isSecondary) return (mrvSets * 0.8).ceil();
    return vopSets; // Terciario siempre VOP
  }

  /// ¿Ha alcanzado el tope de volumen?
  bool get hasReachedVolumeCap => currentSets >= volumeCap;

  /// ¿Puede progresar (subir volumen)?
  bool get canProgress {
    // Terciario nunca progresa
    if (isTertiary) return false;

    // Debe estar en discovering
    if (currentPhase != 'discovering') return false;

    // No debe haber alcanzado cap
    if (hasReachedVolumeCap) return false;

    // No debe estar muy cerca de deload automático
    if (weeksSinceDeload >= (weeksUntilAutoDeload - 1)) return false;

    return true;
  }

  /// Incremento de volumen recomendado
  int get recommendedIncrement {
    if (!canProgress) return 0;

    // Más agresivo al principio, más conservador cerca del MRV
    final percentUsed = currentSets / volumeCap;
    if (percentUsed < 0.5) return 3; // 0-50%: +3 sets
    if (percentUsed < 0.75) return 2; // 50-75%: +2 sets
    return 1; // 75-100%: +1 set
  }

  /// Nuevo volumen si progresa
  int get nextVolumeIfProgress =>
      (currentSets + recommendedIncrement).clamp(currentSets, volumeCap);

  /// ¿Debe hacer deload automático?
  bool get shouldAutoDeload {
    if (isTertiary) return false; // Terciario nunca deload
    if (weeksSinceDeload < weeksUntilAutoDeload) return false;

    // Deload automático cada 4-5 semanas en P, 5-6 en S
    return true;
  }

  /// Promedio de adherencia últimas 4 semanas
  double get avgAdherence4Weeks {
    if (last4WeeksAdherence.isEmpty) return 1.0;
    return last4WeeksAdherence.reduce((a, b) => a + b) /
        last4WeeksAdherence.length;
  }

  /// Tendencia de volumen (aumentando, estable, disminuyendo)
  String get volumeTrend {
    if (last4WeeksVolume.length < 2) return 'unknown';

    final latest = last4WeeksVolume.last;
    final avg =
        last4WeeksVolume.reduce((a, b) => a + b) / last4WeeksVolume.length;

    if (latest > avg * 1.05) return 'increasing';
    if (latest < avg * 0.95) return 'decreasing';
    return 'stable';
  }

  /// ¿Está en fatiga acumulada (overreaching)?
  bool get isInOverreaching => currentPhase == 'overreaching';

  /// ¿Está descargado (deload)?
  bool get isInDeload => currentPhase == 'deloading';

  /// Score de salud del músculo (0-100)
  double get healthScore {
    var score = 50.0;

    // Adherencia contribuye
    if (avgAdherence4Weeks >= 0.9)
      score += 20;
    else if (avgAdherence4Weeks >= 0.7)
      score += 10;
    else
      score -= 10;

    // Tendencia contribuye
    if (volumeTrend == 'increasing')
      score += 15;
    else if (volumeTrend == 'stable')
      score += 5;
    else
      score -= 15;

    // Fase contribuye
    if (currentPhase == 'discovering')
      score += 10;
    else if (currentPhase == 'maintaining')
      score += 5;
    else if (currentPhase == 'overreaching')
      score -= 15;
    else if (currentPhase == 'deloading')
      score -= 10;

    // Semanas desde deload (demasiadas = menos saludable)
    if (weeksSinceDeload > weeksUntilAutoDeload) score -= 20;

    return score.clamp(0.0, 100.0);
  }

  /// Color para UI (red, yellow, green)
  String get uiHealthColor {
    if (healthScore >= 70) return 'green';
    if (healthScore >= 40) return 'yellow';
    return 'red';
  }
}
