// ignore: depend_on_referenced_packages
import 'package:equatable/equatable.dart';

class ExerciseLogEntry extends Equatable {
  final String id;
  final String clientId;
  final String exercisePrescriptionId;
  final DateTime date;
  final int setIndex;
  final double? weight;
  final int? reps;
  final double? rirReal;
  final int? stimulusRating;
  final int? jointPainRating;
  final int? techniqueRating;
  final int? enjoymentRating;

  const ExerciseLogEntry({
    required this.id,
    required this.clientId,
    required this.exercisePrescriptionId,
    required this.date,
    required this.setIndex,
    this.weight,
    this.reps,
    this.rirReal,
    this.stimulusRating,
    this.jointPainRating,
    this.techniqueRating,
    this.enjoymentRating,
  });

  ExerciseLogEntry copyWith({
    String? id,
    String? clientId,
    String? exercisePrescriptionId,
    DateTime? date,
    int? setIndex,
    double? weight,
    int? reps,
    double? rirReal,
    int? stimulusRating,
    int? jointPainRating,
    int? techniqueRating,
    int? enjoymentRating,
  }) {
    return ExerciseLogEntry(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      exercisePrescriptionId:
          exercisePrescriptionId ?? this.exercisePrescriptionId,
      date: date ?? this.date,
      setIndex: setIndex ?? this.setIndex,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      rirReal: rirReal ?? this.rirReal,
      stimulusRating: stimulusRating ?? this.stimulusRating,
      jointPainRating: jointPainRating ?? this.jointPainRating,
      techniqueRating: techniqueRating ?? this.techniqueRating,
      enjoymentRating: enjoymentRating ?? this.enjoymentRating,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientId': clientId,
        'exercisePrescriptionId': exercisePrescriptionId,
        'date': date.toIso8601String(),
        'setIndex': setIndex,
        'weight': weight,
        'reps': reps,
        'rirReal': rirReal,
        'stimulusRating': stimulusRating,
        'jointPainRating': jointPainRating,
        'techniqueRating': techniqueRating,
        'enjoymentRating': enjoymentRating,
      };

  factory ExerciseLogEntry.fromJson(Map<String, dynamic> json) {
    return ExerciseLogEntry(
      id: json['id'] as String? ?? '',
      clientId: json['clientId'] as String? ?? '',
      exercisePrescriptionId:
          json['exercisePrescriptionId'] as String? ?? '',
      date: _parseDate(json['date']),
      setIndex: json['setIndex'] as int? ?? 0,
      weight: (json['weight'] as num?)?.toDouble(),
      reps: json['reps'] as int?,
      rirReal: (json['rirReal'] as num?)?.toDouble(),
      stimulusRating: json['stimulusRating'] as int?,
      jointPainRating: json['jointPainRating'] as int?,
      techniqueRating: json['techniqueRating'] as int?,
      enjoymentRating: json['enjoymentRating'] as int?,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  List<Object?> get props => [
        id,
        clientId,
        exercisePrescriptionId,
        date,
        setIndex,
        weight,
        reps,
        rirReal,
        stimulusRating,
        jointPainRating,
        techniqueRating,
        enjoymentRating,
      ];
}
