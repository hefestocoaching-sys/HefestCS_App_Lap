// Port directo fiel a tu clase en client_model.dart
class DailyTrackingRecord {
  final DateTime date;
  final double? weightKg;
  final double? abdominalFold;
  final double? waistCircNarrowest;
  final int? urineColor; // 1–8

  const DailyTrackingRecord({
    required this.date,
    this.weightKg,
    this.abdominalFold,
    this.waistCircNarrowest,
    this.urineColor,
  });

  DailyTrackingRecord copyWith({
    DateTime? date,
    double? weightKg,
    double? abdominalFold,
    double? waistCircNarrowest,
    int? urineColor,
  }) {
    return DailyTrackingRecord(
      date: date ?? this.date,
      weightKg: weightKg ?? this.weightKg,
      abdominalFold: abdominalFold ?? this.abdominalFold,
      waistCircNarrowest: waistCircNarrowest ?? this.waistCircNarrowest,
      urineColor: urineColor ?? this.urineColor,
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'weightKg': weightKg,
    'abdominalFold': abdominalFold,
    'waistCircNarrowest': waistCircNarrowest,
    'urineColor': urineColor,
  };

  factory DailyTrackingRecord.fromJson(Map<String, dynamic> json) {
    return DailyTrackingRecord(
      date: DateTime.parse(json['date']),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      abdominalFold: (json['abdominalFold'] as num?)?.toDouble(),
      waistCircNarrowest: (json['waistCircNarrowest'] as num?)?.toDouble(),
      urineColor: json['urineColor'] as int?,
    );
  }
}
