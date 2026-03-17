class VolumeToleranceProfile {
  final double tolerance;

  const VolumeToleranceProfile({required this.tolerance});

  Map<String, dynamic> toJson() => {'tolerance': tolerance};

  factory VolumeToleranceProfile.fromJson(Map<String, dynamic> json) {
    return VolumeToleranceProfile(
      tolerance: (json['tolerance'] as num).toDouble(),
    );
  }

  get recommendedVolumeMultiplier => null;
}
