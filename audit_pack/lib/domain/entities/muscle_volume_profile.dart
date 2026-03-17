import 'package:equatable/equatable.dart';

/// Perfil empírico por músculo (aprendido con bitácora).
/// No cambia estructura; solo actúa como cap/guía para el volumen futuro.
class MuscleVolumeProfile extends Equatable {
  final String muscle; // 'chest', 'back', etc.
  final int? maxToleratedSetsObserved; // MRV observado
  final int lastKnownWeeklySets; // último setpoint usado
  final String lastSignal; // 'ok' | 'fatigue' | 'unknown'

  const MuscleVolumeProfile({
    required this.muscle,
    required this.maxToleratedSetsObserved,
    required this.lastKnownWeeklySets,
    required this.lastSignal,
  });

  MuscleVolumeProfile copyWith({
    int? maxToleratedSetsObserved,
    int? lastKnownWeeklySets,
    String? lastSignal,
  }) {
    return MuscleVolumeProfile(
      muscle: muscle,
      maxToleratedSetsObserved:
          maxToleratedSetsObserved ?? this.maxToleratedSetsObserved,
      lastKnownWeeklySets: lastKnownWeeklySets ?? this.lastKnownWeeklySets,
      lastSignal: lastSignal ?? this.lastSignal,
    );
  }

  Map<String, dynamic> toMap() => {
    'muscle': muscle,
    'maxToleratedSetsObserved': maxToleratedSetsObserved,
    'lastKnownWeeklySets': lastKnownWeeklySets,
    'lastSignal': lastSignal,
  };

  factory MuscleVolumeProfile.fromMap(Map<String, dynamic> map) {
    int readInt(dynamic v, int fallback) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? fallback;
    }

    final rawMax = map['maxToleratedSetsObserved'];
    final max = rawMax == null ? null : readInt(rawMax, 0);

    return MuscleVolumeProfile(
      muscle: map['muscle']?.toString() ?? '',
      maxToleratedSetsObserved: (max == null || max <= 0) ? null : max,
      lastKnownWeeklySets: readInt(map['lastKnownWeeklySets'], 0),
      lastSignal: map['lastSignal']?.toString() ?? 'unknown',
    );
  }

  @override
  List<Object?> get props => [
    muscle,
    maxToleratedSetsObserved,
    lastKnownWeeklySets,
    lastSignal,
  ];
}
