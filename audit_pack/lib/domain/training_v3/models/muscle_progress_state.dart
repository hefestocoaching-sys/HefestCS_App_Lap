class MuscleProgressState {
  final String muscle;
  final int vme;
  final int vop;
  final int mrv;
  final int currentSets;
  final int weeksAccumulating;
  final bool localDeloadPending;
  final double localFatigue;
  final double localRecovery;

  const MuscleProgressState({
    required this.muscle,
    required this.vme,
    required this.vop,
    required this.mrv,
    required this.currentSets,
    required this.weeksAccumulating,
    required this.localDeloadPending,
    required this.localFatigue,
    required this.localRecovery,
  });

  MuscleProgressState copyWith({
    String? muscle,
    int? vme,
    int? vop,
    int? mrv,
    int? currentSets,
    int? weeksAccumulating,
    bool? localDeloadPending,
    double? localFatigue,
    double? localRecovery,
  }) {
    return MuscleProgressState(
      muscle: muscle ?? this.muscle,
      vme: vme ?? this.vme,
      vop: vop ?? this.vop,
      mrv: mrv ?? this.mrv,
      currentSets: currentSets ?? this.currentSets,
      weeksAccumulating: weeksAccumulating ?? this.weeksAccumulating,
      localDeloadPending: localDeloadPending ?? this.localDeloadPending,
      localFatigue: localFatigue ?? this.localFatigue,
      localRecovery: localRecovery ?? this.localRecovery,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'muscle': muscle,
      'vme': vme,
      'vop': vop,
      'mrv': mrv,
      'currentSets': currentSets,
      'weeksAccumulating': weeksAccumulating,
      'localDeloadPending': localDeloadPending,
      'localFatigue': localFatigue,
      'localRecovery': localRecovery,
    };
  }

  factory MuscleProgressState.fromMap(Map<String, dynamic> map) {
    return MuscleProgressState(
      muscle: map['muscle'] as String? ?? 'unknown',
      vme: (map['vme'] as num?)?.toInt() ?? 0,
      vop: (map['vop'] as num?)?.toInt() ?? 0,
      mrv: (map['mrv'] as num?)?.toInt() ?? 0,
      currentSets: (map['currentSets'] as num?)?.toInt() ?? 0,
      weeksAccumulating: (map['weeksAccumulating'] as num?)?.toInt() ?? 0,
      localDeloadPending: map['localDeloadPending'] as bool? ?? false,
      localFatigue: (map['localFatigue'] as num?)?.toDouble() ?? 0.0,
      localRecovery: (map['localRecovery'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
