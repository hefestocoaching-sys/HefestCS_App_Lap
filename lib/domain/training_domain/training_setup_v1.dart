class TrainingSetupV1 {
  final double heightCm;
  final double weightKg;
  final int ageYears;
  final String sex;

  // PASOS 3B: Campos adicionales para SSOT
  final int daysPerWeek;
  final int planDurationInWeeks;
  final int timePerSessionMinutes;

  // Experiencia de entrenamiento
  final int trainingExperienceTotalYearsLifetime;
  final int trainingExperienceYearsContinuous;
  final int trainingExperienceDetrainingMonths;

  const TrainingSetupV1({
    required this.heightCm,
    required this.weightKg,
    required this.ageYears,
    required this.sex,
    this.daysPerWeek = 0,
    this.planDurationInWeeks = 0,
    this.timePerSessionMinutes = 0,
    this.trainingExperienceTotalYearsLifetime = 0,
    this.trainingExperienceYearsContinuous = 0,
    this.trainingExperienceDetrainingMonths = 0,
  });

  bool get isValid =>
      heightCm >= 120 && heightCm <= 230 && weightKg >= 30 && weightKg <= 250;

  Map<String, dynamic> toJson() {
    return {
      'heightCm': heightCm,
      'weightKg': weightKg,
      'ageYears': ageYears,
      'sex': sex,
      'daysPerWeek': daysPerWeek,
      'planDurationInWeeks': planDurationInWeeks,
      'timePerSessionMinutes': timePerSessionMinutes,
      'trainingExperienceTotalYearsLifetime':
          trainingExperienceTotalYearsLifetime,
      'trainingExperienceYearsContinuous': trainingExperienceYearsContinuous,
      'trainingExperienceDetrainingMonths': trainingExperienceDetrainingMonths,
    };
  }

  factory TrainingSetupV1.fromJson(Map<String, dynamic> json) {
    return TrainingSetupV1(
      heightCm: (json['heightCm'] as num?)?.toDouble() ?? 0.0,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0.0,
      ageYears: (json['ageYears'] as num?)?.toInt() ?? 0,
      sex: json['sex']?.toString() ?? '',
      daysPerWeek: (json['daysPerWeek'] as num?)?.toInt() ?? 0,
      planDurationInWeeks: (json['planDurationInWeeks'] as num?)?.toInt() ?? 0,
      timePerSessionMinutes:
          (json['timePerSessionMinutes'] as num?)?.toInt() ?? 0,
      trainingExperienceTotalYearsLifetime:
          (json['trainingExperienceTotalYearsLifetime'] as num?)?.toInt() ?? 0,
      trainingExperienceYearsContinuous:
          (json['trainingExperienceYearsContinuous'] as num?)?.toInt() ?? 0,
      trainingExperienceDetrainingMonths:
          (json['trainingExperienceDetrainingMonths'] as num?)?.toInt() ?? 0,
    );
  }
}
