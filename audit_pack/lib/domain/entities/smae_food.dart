class SmaeFood {
  final String id;
  final String nameEs;
  final String smaeGroup;
  final String portion;
  final double kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double? netWeightG;

  const SmaeFood({
    required this.id,
    required this.nameEs,
    required this.smaeGroup,
    required this.portion,
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.netWeightG,
  });

  factory SmaeFood.fromJson(Map<String, dynamic> json) {
    return SmaeFood(
      id: json['id']?.toString() ?? '',
      nameEs: json['nameEs']?.toString() ?? '',
      smaeGroup: json['smaeGroup']?.toString() ?? '',
      portion: json['portion']?.toString() ?? '',
      kcal: (json['kcal'] as num?)?.toDouble() ?? 0,
      proteinG: (json['proteinG'] as num?)?.toDouble() ?? 0,
      carbsG: (json['carbsG'] as num?)?.toDouble() ?? 0,
      fatG: (json['fatG'] as num?)?.toDouble() ?? 0,
      netWeightG: (json['netWeightG'] as num?)?.toDouble(),
    );
  }
}
