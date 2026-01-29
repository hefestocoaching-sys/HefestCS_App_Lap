import 'package:equatable/equatable.dart';

/// Perfil de métricas para un cliente con enfoque en especialización de glúteos.
/// Se usa para decidir si se activa el motor especializado de glúteo y cómo
/// ajustar el volumen/tipo de estímulo.
class GluteSpecializationProfile extends Equatable {
  final double? hipThrust1RM;
  final double? squat1RM;
  final double? hipCircumference;
  final int? gluteActivationScore; // ej: 1–10
  final String? primaryFocus; // ej: "strength", "hypertrophy", "activation"
  final String? notes;
  final DateTime lastUpdated;

  const GluteSpecializationProfile({
    this.hipThrust1RM,
    this.squat1RM,
    this.hipCircumference,
    this.gluteActivationScore,
    this.primaryFocus,
    this.notes,
    required this.lastUpdated,
  });

  GluteSpecializationProfile copyWith({
    double? hipThrust1RM,
    double? squat1RM,
    double? hipCircumference,
    int? gluteActivationScore,
    String? primaryFocus,
    String? notes,
    DateTime? lastUpdated,
  }) {
    return GluteSpecializationProfile(
      hipThrust1RM: hipThrust1RM ?? this.hipThrust1RM,
      squat1RM: squat1RM ?? this.squat1RM,
      hipCircumference: hipCircumference ?? this.hipCircumference,
      gluteActivationScore: gluteActivationScore ?? this.gluteActivationScore,
      primaryFocus: primaryFocus ?? this.primaryFocus,
      notes: notes ?? this.notes,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hipThrust1RM': hipThrust1RM,
      'squat1RM': squat1RM,
      'hipCircumference': hipCircumference,
      'gluteActivationScore': gluteActivationScore,
      'primaryFocus': primaryFocus,
      'notes': notes,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory GluteSpecializationProfile.fromMap(Map<String, dynamic> map) {
    return GluteSpecializationProfile(
      hipThrust1RM: (map['hipThrust1RM'] as num?)?.toDouble(),
      squat1RM: (map['squat1RM'] as num?)?.toDouble(),
      hipCircumference: (map['hipCircumference'] as num?)?.toDouble(),
      gluteActivationScore: map['gluteActivationScore'] as int?,
      primaryFocus: map['primaryFocus'] as String?,
      notes: map['notes'] as String?,
      lastUpdated:
          DateTime.tryParse(map['lastUpdated']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory GluteSpecializationProfile.fromJson(Map<String, dynamic> json) {
    return GluteSpecializationProfile.fromMap(json);
  }

  @override
  List<Object?> get props => [
    hipThrust1RM,
    squat1RM,
    hipCircumference,
    gluteActivationScore,
    primaryFocus,
    notes,
    lastUpdated,
  ];
}
