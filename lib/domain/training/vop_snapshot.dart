import 'package:flutter/foundation.dart';

/// SSOT canónico para Volumen Operativo Prescrito (VOP).
///
/// CLÍNICO, CANÓNICO: cada key es UN músculo real (sin grupos).
/// Se escribe una sola vez (Tab Volumen) y se consume en modo read-only.
class VopSnapshot {
  final Map<String, int> setsByMuscle;
  final DateTime updatedAt;
  final String source; // 'manual', 'auto', 'imported', 'migration', etc.

  const VopSnapshot({
    required this.setsByMuscle,
    required this.updatedAt,
    required this.source,
  });

  // Compatibilidad legacy (alias)
  Map<String, int> get setsByMuscleInternal => setsByMuscle;

  bool get isEmpty => setsByMuscle.isEmpty;

  Map<String, dynamic> toMap() => {
    'setsByMuscle': setsByMuscle,
    'updatedAt': updatedAt.toIso8601String(),
    'source': source,
  };

  factory VopSnapshot.fromMap(Map<String, dynamic> map) {
    final rawSets = Map<String, int>.from(
      map['setsByMuscle'] ?? map['setsByMuscleInternal'] ?? {},
    );
    return VopSnapshot(
      setsByMuscle: rawSets,
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
      source: map['source']?.toString() ?? 'unknown',
    );
  }

  @override
  String toString() =>
      'VopSnapshot(muscles=${setsByMuscle.length}, source=$source)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VopSnapshot &&
          mapEquals(setsByMuscle, other.setsByMuscle) &&
          updatedAt == other.updatedAt &&
          source == other.source;

  @override
  int get hashCode =>
      setsByMuscle.hashCode ^ updatedAt.hashCode ^ source.hashCode;
}
