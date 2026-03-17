class WeeklyVolumeRecord {
  final String weekStartIso;
  final String muscleGroup;
  final int totalSeries;
  final int lightSeries;
  final int mediumSeries;
  final int heavySeries;

  const WeeklyVolumeRecord({
    required this.weekStartIso,
    required this.muscleGroup,
    required this.totalSeries,
    required this.lightSeries,
    required this.mediumSeries,
    required this.heavySeries,
  });

  Map<String, dynamic> toMap() => {
    'weekStartIso': weekStartIso,
    'muscleGroup': muscleGroup,
    'totalSeries': totalSeries,
    'lightSeries': lightSeries,
    'mediumSeries': mediumSeries,
    'heavySeries': heavySeries,
  };

  factory WeeklyVolumeRecord.fromMap(Map<String, dynamic> map) {
    return WeeklyVolumeRecord(
      weekStartIso: map['weekStartIso']?.toString() ?? '',
      muscleGroup: map['muscleGroup']?.toString() ?? '',
      totalSeries: (map['totalSeries'] as num?)?.toInt() ?? 0,
      lightSeries: (map['lightSeries'] as num?)?.toInt() ?? 0,
      mediumSeries: (map['mediumSeries'] as num?)?.toInt() ?? 0,
      heavySeries: (map['heavySeries'] as num?)?.toInt() ?? 0,
    );
  }
}
