import 'package:equatable/equatable.dart';

/// Define los límites de volumen de entrenamiento por grupo muscular
/// basados en la literatura científica (MEV, MAV, MRV).
///
/// MEV: Minimum Effective Volume (volumen mínimo para progreso)
/// MAV: Maximum Adaptive Volume (volumen óptimo para adaptación)
/// MRV: Maximum Recoverable Volume (volumen máximo recuperable)
///
/// Referencias:
/// - Mike Israetel et al., Renaissance Periodization
/// - Schoenfeld et al., 2017 (meta-análisis volumen-hipertrofia)
class VolumeLimits extends Equatable {
  /// Grupo muscular al que aplican estos límites
  final String muscleGroup;

  /// Minimum Effective Volume (series/semana)
  /// Por debajo de este valor, el progreso es mínimo o nulo
  final int mev;

  /// Maximum Adaptive Volume (series/semana)
  /// Rango óptimo para maximizar adaptación sin fatiga excesiva
  final int mav;

  /// Maximum Recoverable Volume (series/semana)
  /// Límite absoluto de seguridad, NO debe excederse
  final int mrv;

  /// Volumen recomendado inicial para este perfil específico
  final int recommendedStartVolume;

  /// Factor de ajuste aplicado (ej: por farmacología, experiencia)
  final double adjustmentFactor;

  /// Razonamiento detrás de los límites calculados
  final String reasoning;

  const VolumeLimits({
    required this.muscleGroup,
    required this.mev,
    required this.mav,
    required this.mrv,
    required this.recommendedStartVolume,
    this.adjustmentFactor = 1.0,
    this.reasoning = '',
  });

  /// Verifica si un volumen dado está dentro de los límites seguros
  bool isVolumeSafe(int weeklyVolume) {
    return weeklyVolume <= mrv;
  }

  /// Verifica si un volumen está en el rango óptimo (MAV)
  bool isVolumeOptimal(int weeklyVolume) {
    return weeklyVolume >= mev && weeklyVolume <= mav;
  }

  /// Verifica si un volumen está por debajo del mínimo efectivo
  bool isVolumeTooLow(int weeklyVolume) {
    return weeklyVolume < mev;
  }

  /// Verifica si un volumen está en zona de riesgo (cercano o sobre MRV)
  bool isVolumeRisky(int weeklyVolume) {
    return weeklyVolume > mav;
  }

  /// Clamp de volumen al rango seguro
  int clampToSafeRange(int proposedVolume) {
    if (proposedVolume < mev) return mev;
    if (proposedVolume > mrv) return mrv;
    return proposedVolume;
  }

  /// Clamp de volumen al rango óptimo (MAV)
  int clampToOptimalRange(int proposedVolume) {
    if (proposedVolume < mev) return mev;
    if (proposedVolume > mav) return mav;
    return proposedVolume;
  }

  VolumeLimits copyWith({
    String? muscleGroup,
    int? mev,
    int? mav,
    int? mrv,
    int? recommendedStartVolume,
    double? adjustmentFactor,
    String? reasoning,
  }) {
    return VolumeLimits(
      muscleGroup: muscleGroup ?? this.muscleGroup,
      mev: mev ?? this.mev,
      mav: mav ?? this.mav,
      mrv: mrv ?? this.mrv,
      recommendedStartVolume:
          recommendedStartVolume ?? this.recommendedStartVolume,
      adjustmentFactor: adjustmentFactor ?? this.adjustmentFactor,
      reasoning: reasoning ?? this.reasoning,
    );
  }

  Map<String, dynamic> toJson() => {
    'muscleGroup': muscleGroup,
    'mev': mev,
    'mav': mav,
    'mrv': mrv,
    'recommendedStartVolume': recommendedStartVolume,
    'adjustmentFactor': adjustmentFactor,
    'reasoning': reasoning,
  };

  factory VolumeLimits.fromJson(Map<String, dynamic> json) {
    return VolumeLimits(
      muscleGroup: json['muscleGroup'] as String? ?? '',
      mev: json['mev'] as int? ?? 0,
      mav: json['mav'] as int? ?? 0,
      mrv: json['mrv'] as int? ?? 0,
      recommendedStartVolume: json['recommendedStartVolume'] as int? ?? 0,
      adjustmentFactor: (json['adjustmentFactor'] as num?)?.toDouble() ?? 1.0,
      reasoning: json['reasoning'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
    muscleGroup,
    mev,
    mav,
    mrv,
    recommendedStartVolume,
    adjustmentFactor,
    reasoning,
  ];

  @override
  String toString() {
    return 'VolumeLimits($muscleGroup: MEV=$mev, MAV=$mav, MRV=$mrv, Start=$recommendedStartVolume)';
  }
}
