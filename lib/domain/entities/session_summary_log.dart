// ignore: depend_on_referenced_packages
import 'package:equatable/equatable.dart';

class SessionSummaryLog extends Equatable {
  final String id;
  final String clientId;
  final String sessionId;
  final DateTime date;
  final double rpeSession;
  final int energyRating;
  final int fatigueRating;
  final int moodRating;
  final bool hadWeirdPain;

  const SessionSummaryLog({
    required this.id,
    required this.clientId,
    required this.sessionId,
    required this.date,
    required this.rpeSession,
    required this.energyRating,
    required this.fatigueRating,
    required this.moodRating,
    required this.hadWeirdPain,
  });

  SessionSummaryLog copyWith({
    String? id,
    String? clientId,
    String? sessionId,
    DateTime? date,
    double? rpeSession,
    int? energyRating,
    int? fatigueRating,
    int? moodRating,
    bool? hadWeirdPain,
  }) {
    return SessionSummaryLog(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      sessionId: sessionId ?? this.sessionId,
      date: date ?? this.date,
      rpeSession: rpeSession ?? this.rpeSession,
      energyRating: energyRating ?? this.energyRating,
      fatigueRating: fatigueRating ?? this.fatigueRating,
      moodRating: moodRating ?? this.moodRating,
      hadWeirdPain: hadWeirdPain ?? this.hadWeirdPain,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientId': clientId,
        'sessionId': sessionId,
        'date': date.toIso8601String(),
        'rpeSession': rpeSession,
        'energyRating': energyRating,
        'fatigueRating': fatigueRating,
        'moodRating': moodRating,
        'hadWeirdPain': hadWeirdPain,
      };

  factory SessionSummaryLog.fromJson(Map<String, dynamic> json) {
    return SessionSummaryLog(
      id: json['id'] as String? ?? '',
      clientId: json['clientId'] as String? ?? '',
      sessionId: json['sessionId'] as String? ?? '',
      date: _parseDate(json['date']),
      rpeSession: (json['rpeSession'] as num?)?.toDouble() ?? 0.0,
      energyRating: json['energyRating'] as int? ?? 0,
      fatigueRating: json['fatigueRating'] as int? ?? 0,
      moodRating: json['moodRating'] as int? ?? 0,
      hadWeirdPain: json['hadWeirdPain'] as bool? ?? false,
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
        sessionId,
        date,
        rpeSession,
        energyRating,
        fatigueRating,
        moodRating,
        hadWeirdPain,
      ];
}
