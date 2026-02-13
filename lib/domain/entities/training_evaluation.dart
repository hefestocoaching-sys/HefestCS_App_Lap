// ignore_for_file: unused_import

import 'dart:convert';

import 'package:hcs_app_lap/core/enums/training_phase.dart';
import 'package:hcs_app_lap/domain/training/models/muscle_priorities.dart';

/// Registra el feedback y las métricas de recuperación de una semana de entrenamiento.
class TrainingEvaluation {
  final int daysPerWeek;
  final int sessionDurationMinutes;
  final int planDurationInWeeks;
  final MusclePriorities musclePriorities;

  @Deprecated('Use musclePriorities instead')
  final String? priorityMusclesPrimary;

  @Deprecated('Use musclePriorities instead')
  final String? priorityMusclesSecondary;

  @Deprecated('Use musclePriorities instead')
  final String? priorityMusclesTertiary;

  final List<String> availableEquipment;
  final String experienceLevel;
  final String mainGoal;

  final DateTime date;
  final int? weekNumber;
  final TrainingPhase? phase;
  final double? avgRpe;
  final int? avgDoms;
  final int? sleepQuality; // ej: 1-5
  final int? stressLevel; // ej: 1-10
  final String? feedback;
  final double? adherencePercentage; // ej: 0.0 a 1.0

  TrainingEvaluation({
    this.daysPerWeek = 0,
    this.sessionDurationMinutes = 0,
    this.planDurationInWeeks = 0,
    MusclePriorities? musclePriorities,
    @Deprecated('Use musclePriorities instead') this.priorityMusclesPrimary,
    @Deprecated('Use musclePriorities instead') this.priorityMusclesSecondary,
    @Deprecated('Use musclePriorities instead') this.priorityMusclesTertiary,
    List<String> availableEquipment = const [],
    this.experienceLevel = 'intermediate',
    this.mainGoal = 'hypertrophy',
    required this.date,
    this.weekNumber,
    this.phase,
    this.avgRpe,
    this.avgDoms,
    this.sleepQuality,
    this.stressLevel,
    this.feedback,
    this.adherencePercentage,
  }) : musclePriorities = musclePriorities ?? MusclePriorities(),
       availableEquipment = List.unmodifiable(availableEquipment);

  TrainingEvaluation copyWith({
    int? daysPerWeek,
    int? sessionDurationMinutes,
    int? planDurationInWeeks,
    MusclePriorities? musclePriorities,
    String? priorityMusclesPrimary,
    String? priorityMusclesSecondary,
    String? priorityMusclesTertiary,
    List<String>? availableEquipment,
    String? experienceLevel,
    String? mainGoal,
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
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      sessionDurationMinutes:
          sessionDurationMinutes ?? this.sessionDurationMinutes,
      planDurationInWeeks: planDurationInWeeks ?? this.planDurationInWeeks,
      musclePriorities: musclePriorities ?? this.musclePriorities,
      priorityMusclesPrimary:
          priorityMusclesPrimary ?? this.priorityMusclesPrimary,
      priorityMusclesSecondary:
          priorityMusclesSecondary ?? this.priorityMusclesSecondary,
      priorityMusclesTertiary:
          priorityMusclesTertiary ?? this.priorityMusclesTertiary,
      availableEquipment: availableEquipment ?? this.availableEquipment,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      mainGoal: mainGoal ?? this.mainGoal,
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
      'daysPerWeek': daysPerWeek,
      'sessionDurationMinutes': sessionDurationMinutes,
      'planDurationInWeeks': planDurationInWeeks,
      'musclePriorities': musclePriorities.values,
      'priorityMusclesPrimary': priorityMusclesPrimary,
      'priorityMusclesSecondary': priorityMusclesSecondary,
      'priorityMusclesTertiary': priorityMusclesTertiary,
      'availableEquipment': availableEquipment,
      'experienceLevel': experienceLevel,
      'mainGoal': mainGoal,
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
    final rawPriorities = map['musclePriorities'];
    MusclePriorities? priorities;
    if (rawPriorities is Map) {
      priorities = MusclePriorities(
        initialValues: rawPriorities.map((key, value) {
          if (value is num) {
            return MapEntry(key.toString(), value.toInt());
          }
          final parsed = int.tryParse(value?.toString() ?? '');
          return MapEntry(key.toString(), parsed ?? 0);
        }),
      );
    }
    priorities ??= MusclePriorities.fromLegacyLists(
      primaryString: map['priorityMusclesPrimary']?.toString() ?? '',
      secondaryString: map['priorityMusclesSecondary']?.toString() ?? '',
      tertiaryString: map['priorityMusclesTertiary']?.toString() ?? '',
    );

    return TrainingEvaluation(
      daysPerWeek: (map['daysPerWeek'] as num?)?.toInt() ?? 0,
      sessionDurationMinutes:
          (map['sessionDurationMinutes'] as num?)?.toInt() ?? 0,
      planDurationInWeeks: (map['planDurationInWeeks'] as num?)?.toInt() ?? 0,
      musclePriorities: priorities,
      priorityMusclesPrimary: map['priorityMusclesPrimary'] as String?,
      priorityMusclesSecondary: map['priorityMusclesSecondary'] as String?,
      priorityMusclesTertiary: map['priorityMusclesTertiary'] as String?,
      availableEquipment:
          (map['availableEquipment'] as List?)?.cast<String>() ?? const [],
      experienceLevel: map['experienceLevel']?.toString() ?? 'intermediate',
      mainGoal: map['mainGoal']?.toString() ?? 'hypertrophy',
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
