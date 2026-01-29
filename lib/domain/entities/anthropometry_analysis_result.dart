// ignore: depend_on_referenced_packages
import 'package:equatable/equatable.dart';

class AnthropometryAnalysisResult extends Equatable {
  final double? sumOfSkinfolds;
  final double? bodyFatPercentage;
  final double? waistHipRatio;
  final String? waistHipClassification;
  final double? fatMassKg;
  final double? leanMassKg;
  final double? leanMassPercent;
  final double? bmi;
  final String? bmiCategory;
  final double? muscleMassKg;
  final double? muscleMassPercent;
  final double? muscleIndex;
  final String? muscleIndexClass;
  final double? boneMassKg;
  final double? boneMassPercent;
  final double? visceralMassKg;
  final double? visceralMassPercent;
  final double? muscleBoneRatio;
  final double? naturalLbmPotentialKg;
  final double? naturalLbmPotentialPercent;
  final String? overallInterpretation;
  final Map<String, dynamic> extra;

  const AnthropometryAnalysisResult({
    this.sumOfSkinfolds,
    this.bodyFatPercentage,
    this.waistHipRatio,
    this.waistHipClassification,
    this.fatMassKg,
    this.leanMassKg,
    this.leanMassPercent,
    this.bmi,
    this.bmiCategory,
    this.muscleMassKg,
    this.muscleMassPercent,
    this.muscleIndex,
    this.muscleIndexClass,
    this.boneMassKg,
    this.boneMassPercent,
    this.visceralMassKg,
    this.visceralMassPercent,
    this.muscleBoneRatio,
    this.naturalLbmPotentialKg,
    this.naturalLbmPotentialPercent,
    this.overallInterpretation,
    this.extra = const {},
  });

  AnthropometryAnalysisResult copyWith({
    double? sumOfSkinfolds,
    double? bodyFatPercentage,
    double? waistHipRatio,
    String? waistHipClassification,
    double? fatMassKg,
    double? leanMassKg,
    double? leanMassPercent,
    double? bmi,
    String? bmiCategory,
    double? muscleMassKg,
    double? muscleMassPercent,
    double? muscleIndex,
    String? muscleIndexClass,
    double? boneMassKg,
    double? boneMassPercent,
    double? visceralMassKg,
    double? visceralMassPercent,
    double? muscleBoneRatio,
    double? naturalLbmPotentialKg,
    double? naturalLbmPotentialPercent,
    String? overallInterpretation,
    Map<String, dynamic>? extra,
  }) {
    return AnthropometryAnalysisResult(
      sumOfSkinfolds: sumOfSkinfolds ?? this.sumOfSkinfolds,
      bodyFatPercentage: bodyFatPercentage ?? this.bodyFatPercentage,
      waistHipRatio: waistHipRatio ?? this.waistHipRatio,
      waistHipClassification:
          waistHipClassification ?? this.waistHipClassification,
      fatMassKg: fatMassKg ?? this.fatMassKg,
      leanMassKg: leanMassKg ?? this.leanMassKg,
      leanMassPercent: leanMassPercent ?? this.leanMassPercent,
      bmi: bmi ?? this.bmi,
      bmiCategory: bmiCategory ?? this.bmiCategory,
      muscleMassKg: muscleMassKg ?? this.muscleMassKg,
      muscleMassPercent: muscleMassPercent ?? this.muscleMassPercent,
      muscleIndex: muscleIndex ?? this.muscleIndex,
      muscleIndexClass: muscleIndexClass ?? this.muscleIndexClass,
      boneMassKg: boneMassKg ?? this.boneMassKg,
      boneMassPercent: boneMassPercent ?? this.boneMassPercent,
      visceralMassKg: visceralMassKg ?? this.visceralMassKg,
      visceralMassPercent: visceralMassPercent ?? this.visceralMassPercent,
      muscleBoneRatio: muscleBoneRatio ?? this.muscleBoneRatio,
      naturalLbmPotentialKg:
          naturalLbmPotentialKg ?? this.naturalLbmPotentialKg,
      naturalLbmPotentialPercent:
          naturalLbmPotentialPercent ?? this.naturalLbmPotentialPercent,
      overallInterpretation: overallInterpretation ?? this.overallInterpretation,
      extra: extra ?? this.extra,
    );
  }

  Map<String, dynamic> toJson() => {
        'sumOfSkinfolds': sumOfSkinfolds,
        'bodyFatPercentage': bodyFatPercentage,
        'waistHipRatio': waistHipRatio,
        'waistHipClassification': waistHipClassification,
        'fatMassKg': fatMassKg,
        'leanMassKg': leanMassKg,
        'leanMassPercent': leanMassPercent,
        'bmi': bmi,
        'bmiCategory': bmiCategory,
        'muscleMassKg': muscleMassKg,
        'muscleMassPercent': muscleMassPercent,
        'muscleIndex': muscleIndex,
        'muscleIndexClass': muscleIndexClass,
        'boneMassKg': boneMassKg,
        'boneMassPercent': boneMassPercent,
        'visceralMassKg': visceralMassKg,
        'visceralMassPercent': visceralMassPercent,
        'muscleBoneRatio': muscleBoneRatio,
        'naturalLbmPotentialKg': naturalLbmPotentialKg,
        'naturalLbmPotentialPercent': naturalLbmPotentialPercent,
        'overallInterpretation': overallInterpretation,
        'extra': extra,
      };

  factory AnthropometryAnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnthropometryAnalysisResult(
      sumOfSkinfolds: (json['sumOfSkinfolds'] as num?)?.toDouble(),
      bodyFatPercentage: (json['bodyFatPercentage'] as num?)?.toDouble(),
      waistHipRatio: (json['waistHipRatio'] as num?)?.toDouble(),
      waistHipClassification: json['waistHipClassification'] as String?,
      fatMassKg: (json['fatMassKg'] as num?)?.toDouble(),
      leanMassKg: (json['leanMassKg'] as num?)?.toDouble(),
      leanMassPercent: (json['leanMassPercent'] as num?)?.toDouble(),
      bmi: (json['bmi'] as num?)?.toDouble(),
      bmiCategory: json['bmiCategory'] as String?,
      muscleMassKg: (json['muscleMassKg'] as num?)?.toDouble(),
      muscleMassPercent: (json['muscleMassPercent'] as num?)?.toDouble(),
      muscleIndex: (json['muscleIndex'] as num?)?.toDouble(),
      muscleIndexClass: json['muscleIndexClass'] as String?,
      boneMassKg: (json['boneMassKg'] as num?)?.toDouble(),
      boneMassPercent: (json['boneMassPercent'] as num?)?.toDouble(),
      visceralMassKg: (json['visceralMassKg'] as num?)?.toDouble(),
      visceralMassPercent: (json['visceralMassPercent'] as num?)?.toDouble(),
      muscleBoneRatio: (json['muscleBoneRatio'] as num?)?.toDouble(),
      naturalLbmPotentialKg:
          (json['naturalLbmPotentialKg'] as num?)?.toDouble(),
      naturalLbmPotentialPercent:
          (json['naturalLbmPotentialPercent'] as num?)?.toDouble(),
      overallInterpretation: json['overallInterpretation'] as String?,
      extra: Map<String, dynamic>.from(json['extra'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [
        sumOfSkinfolds,
        bodyFatPercentage,
        waistHipRatio,
        waistHipClassification,
        fatMassKg,
        leanMassKg,
        leanMassPercent,
        bmi,
        bmiCategory,
        muscleMassKg,
        muscleMassPercent,
        muscleIndex,
        muscleIndexClass,
        boneMassKg,
        boneMassPercent,
        visceralMassKg,
        visceralMassPercent,
        muscleBoneRatio,
        naturalLbmPotentialKg,
        naturalLbmPotentialPercent,
        overallInterpretation,
        extra,
      ];
}
