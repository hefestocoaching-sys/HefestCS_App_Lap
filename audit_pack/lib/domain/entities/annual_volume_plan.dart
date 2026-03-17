import 'weekly_muscle_volume.dart';

class AnnualVolumePlan {
  final int year;
  final List<WeeklyMuscleVolume> weeklyPlans;

  const AnnualVolumePlan({required this.year, required this.weeklyPlans});

  int get totalWeeks => weeklyPlans.length;

  Map<String, dynamic> toMap() => {
    'year': year,
    'weeklyPlans': weeklyPlans.length, // placeholder
  };

  factory AnnualVolumePlan.fromMap(Map<String, dynamic> map) {
    return AnnualVolumePlan(year: map['year'], weeklyPlans: const []);
  }
}
