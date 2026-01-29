// ignore_for_file: unused_import

import 'dart:convert';

/// Perfil psicológico relacionado con el entrenamiento.
class PsychologicalTrainingProfile {
  final int? motivationLevel; // ej: 1-10
  final int? focusLevel; // ej: 1-10
  final int? confidenceLevel; // ej: 1-10
  final String? mainBarrier; // ej: "Tiempo", "Energía", "Motivación"
  final String? notes;
  final DateTime date;

  const PsychologicalTrainingProfile({
    this.motivationLevel,
    this.focusLevel,
    this.confidenceLevel,
    this.mainBarrier,
    this.notes,
    required this.date,
  });

  PsychologicalTrainingProfile copyWith({
    int? motivationLevel,
    int? focusLevel,
    int? confidenceLevel,
    String? mainBarrier,
    String? notes,
    DateTime? date,
  }) {
    return PsychologicalTrainingProfile(
      motivationLevel: motivationLevel ?? this.motivationLevel,
      focusLevel: focusLevel ?? this.focusLevel,
      confidenceLevel: confidenceLevel ?? this.confidenceLevel,
      mainBarrier: mainBarrier ?? this.mainBarrier,
      notes: notes ?? this.notes,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'motivationLevel': motivationLevel,
      'focusLevel': focusLevel,
      'confidenceLevel': confidenceLevel,
      'mainBarrier': mainBarrier,
      'notes': notes,
      'date': date.toIso8601String(),
    };
  }

  factory PsychologicalTrainingProfile.fromJson(Map<String, dynamic> map) {
    return PsychologicalTrainingProfile(
      motivationLevel: map['motivationLevel'] as int?,
      focusLevel: map['focusLevel'] as int?,
      confidenceLevel: map['confidenceLevel'] as int?,
      mainBarrier: map['mainBarrier'] as String?,
      notes: map['notes'] as String?,
      date: DateTime.parse(
        map['date'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
