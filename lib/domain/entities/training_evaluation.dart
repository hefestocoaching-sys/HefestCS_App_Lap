// ignore_for_file: unused_import

import 'dart:convert';

import 'package:hcs_app_lap/core/enums/training_phase.dart';

/// Registra el feedback y las métricas de recuperación de una semana de entrenamiento.
class TrainingEvaluation {
  final DateTime date;
  final int? weekNumber;
  final TrainingPhase? phase;
  final double? avgRpe;
  final int? avgDoms;
  final int? sleepQuality; // ej: 1-5
  final int? stressLevel; // ej: 1-10
  final String? feedback;
  final double? adherencePercentage; // ej: 0.0 a 1.0

  const TrainingEvaluation({
    required this.date,
    this.weekNumber,
    this.phase,
    this.avgRpe,
    this.avgDoms,
    this.sleepQuality,
    this.stressLevel,
    this.feedback,
    this.adherencePercentage,
  });

  TrainingEvaluation copyWith({
    DateTime? date,
    int? weekNumber,
    TrainingPhase? phase,
    double? avgRpe,
    int? avgDoms,
    int? sleepQuality,
    int? stressLevel,
    String? feedback,
    double? adherencePercentage,
  }) {
    return TrainingEvaluation(
      date: date ?? this.date,
      weekNumber: weekNumber ?? this.weekNumber,
      phase: phase ?? this.phase,
      avgRpe: avgRpe ?? this.avgRpe,
      avgDoms: avgDoms ?? this.avgDoms,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      stressLevel: stressLevel ?? this.stressLevel,
      feedback: feedback ?? this.feedback,
      adherencePercentage: adherencePercentage ?? this.adherencePercentage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'weekNumber': weekNumber,
      'phase': phase?.name,
      'avgRpe': avgRpe,
      'avgDoms': avgDoms,
      'sleepQuality': sleepQuality,
      'stressLevel': stressLevel,
      'feedback': feedback,
      'adherencePercentage': adherencePercentage,
    };
  }

  factory TrainingEvaluation.fromJson(Map<String, dynamic> map) {
    return TrainingEvaluation(
      date: DateTime.parse(
        map['date'] as String? ?? DateTime.now().toIso8601String(),
      ),
      weekNumber: map['weekNumber'] as int?,
      phase: map['phase'] != null
          ? TrainingPhase.values.firstWhere(
              (e) => e.name == map['phase'],
              orElse: () => TrainingPhase.accumulation, // Fallback
            )
          : null,
      avgRpe: map['avgRpe'] as double?,
      avgDoms: map['avgDoms'] as int?,
      sleepQuality: map['sleepQuality'] as int?,
      stressLevel: map['stressLevel'] as int?,
      feedback: map['feedback'] as String?,
      adherencePercentage: map['adherencePercentage'] as double?,
    );
  }
}
