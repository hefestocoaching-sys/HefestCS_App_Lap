class ClinicalHistory {
  final String? pathologies;
  final String? surgeries;
  final String? allergies;
  final String? medications;
  final String? familyHistory;

  // Gineco (mantén todos los que usas)
  final bool? isPregnant;
  final bool? isBreastfeeding;
  final List<String>? cycleRelatedSymptoms;
  final String? specificGynecoConditions;

  final Map<String, dynamic> extra; // para no perder nada

  const ClinicalHistory({
    this.pathologies,
    this.surgeries,
    this.allergies,
    this.medications,
    this.familyHistory,
    this.isPregnant,
    this.isBreastfeeding,
    this.cycleRelatedSymptoms,
    this.specificGynecoConditions,
    this.extra = const {},
  });

  ClinicalHistory copyWith({
    String? pathologies,
    String? surgeries,
    String? allergies,
    String? medications,
    String? familyHistory,
    bool? isPregnant,
    bool? isBreastfeeding,
    List<String>? cycleRelatedSymptoms,
    String? specificGynecoConditions,
    Map<String, dynamic>? extra,
  }) {
    return ClinicalHistory(
      pathologies: pathologies ?? this.pathologies,
      surgeries: surgeries ?? this.surgeries,
      allergies: allergies ?? this.allergies,
      medications: medications ?? this.medications,
      familyHistory: familyHistory ?? this.familyHistory,
      isPregnant: isPregnant ?? this.isPregnant,
      isBreastfeeding: isBreastfeeding ?? this.isBreastfeeding,
      cycleRelatedSymptoms: cycleRelatedSymptoms ?? this.cycleRelatedSymptoms,
      specificGynecoConditions: specificGynecoConditions ?? this.specificGynecoConditions,
      extra: extra ?? this.extra,
    );
  }

  Map<String, dynamic> toJson() => {
    'pathologies': pathologies,
    'surgeries': surgeries,
    'allergies': allergies,
    'medications': medications,
    'familyHistory': familyHistory,
    'isPregnant': isPregnant,
    'isBreastfeeding': isBreastfeeding,
    'cycleRelatedSymptoms': cycleRelatedSymptoms,
    'specificGynecoConditions': specificGynecoConditions,
    'extra': extra,
  };

  factory ClinicalHistory.fromJson(Map<String, dynamic> json) {
    final known = {
      'pathologies','surgeries','allergies','medications','familyHistory',
      'isPregnant','isBreastfeeding','cycleRelatedSymptoms','specificGynecoConditions','extra'
    };
    final extra = <String, dynamic>{};
    final storedExtra = json['extra'];
    if (storedExtra is Map) {
      extra.addAll(
        storedExtra.map((key, value) => MapEntry(key.toString(), value)),
      );
    }
    final unknown = Map<String, dynamic>.from(json)
      ..removeWhere((k, _) => known.contains(k));
    extra.addAll(unknown);
    return ClinicalHistory(
      pathologies: json['pathologies'] as String?,
      surgeries: json['surgeries'] as String?,
      allergies: json['allergies'] as String?,
      medications: json['medications'] as String?,
      familyHistory: json['familyHistory'] as String?,
      isPregnant: json['isPregnant'] as bool?,
      isBreastfeeding: json['isBreastfeeding'] as bool?,
      cycleRelatedSymptoms: (json['cycleRelatedSymptoms'] as List?)?.map((e)=> e.toString()).toList(),
      specificGynecoConditions: json['specificGynecoConditions'] as String?,
      extra: extra,
    );
  }
}
