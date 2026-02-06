class TrainingSetupV1 {
  final double heightCm;
  final double weightKg;
  final int ageYears;
  final String sex;

  const TrainingSetupV1({
    required this.heightCm,
    required this.weightKg,
    required this.ageYears,
    required this.sex,
  });

  bool get isValid =>
      heightCm >= 120 && heightCm <= 230 && weightKg >= 30 && weightKg <= 250;

  Map<String, dynamic> toJson() {
    return {
      'heightCm': heightCm,
      'weightKg': weightKg,
      'ageYears': ageYears,
      'sex': sex,
    };
  }

  factory TrainingSetupV1.fromJson(Map<String, dynamic> json) {
    return TrainingSetupV1(
      heightCm: (json['heightCm'] as num?)?.toDouble() ?? 0.0,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0.0,
      ageYears: (json['ageYears'] as num?)?.toInt() ?? 0,
      sex: json['sex']?.toString() ?? '',
    );
  }
}
