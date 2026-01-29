// Port directo fiel a tu clase en client_model.dart (campos conservados)
class AnthropometryRecord {
  DateTime date;
  double? weightKg;
  double? heightCm;

  double? tricipitalFold;
  double? subscapularFold;
  double? suprailiacFold;
  double? supraspinalFold;
  double? abdominalFold;
  double? thighFold;
  double? calfFold;

  double? armRelaxedCirc;
  double? armFlexedCirc;
  double? waistCircNarrowest;
  double? hipCircMax;
  double? midThighCirc;
  double? maxCalfCirc;
  double? neckCirc;

  double? wristDiameter;
  double? kneeDiameter;

  // Almacenar las tres mediciones individuales [m1, m2, m3] por cada sitio
  Map<String, List<double?>>? individualMeasurements;

  AnthropometryRecord({
    required this.date,
    this.weightKg,
    this.heightCm,
    this.tricipitalFold,
    this.subscapularFold,
    this.suprailiacFold,
    this.supraspinalFold,
    this.abdominalFold,
    this.thighFold,
    this.calfFold,
    this.armRelaxedCirc,
    this.armFlexedCirc,
    this.waistCircNarrowest,
    this.hipCircMax,
    this.midThighCirc,
    this.maxCalfCirc,
    this.neckCirc,
    this.wristDiameter,
    this.kneeDiameter,
    this.individualMeasurements,
  });

  AnthropometryRecord copyWith({
    DateTime? date,
    double? weightKg,
    double? heightCm,
    double? tricipitalFold,
    double? subscapularFold,
    double? suprailiacFold,
    double? supraspinalFold,
    double? abdominalFold,
    double? thighFold,
    double? calfFold,
    double? armRelaxedCirc,
    double? armFlexedCirc,
    double? waistCircNarrowest,
    double? hipCircMax,
    double? midThighCirc,
    double? maxCalfCirc,
    double? neckCirc,
    double? wristDiameter,
    double? kneeDiameter,
    Map<String, List<double?>>? individualMeasurements,
  }) {
    return AnthropometryRecord(
      date: date ?? this.date,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      tricipitalFold: tricipitalFold ?? this.tricipitalFold,
      subscapularFold: subscapularFold ?? this.subscapularFold,
      suprailiacFold: suprailiacFold ?? this.suprailiacFold,
      supraspinalFold: supraspinalFold ?? this.supraspinalFold,
      abdominalFold: abdominalFold ?? this.abdominalFold,
      thighFold: thighFold ?? this.thighFold,
      calfFold: calfFold ?? this.calfFold,
      armRelaxedCirc: armRelaxedCirc ?? this.armRelaxedCirc,
      armFlexedCirc: armFlexedCirc ?? this.armFlexedCirc,
      waistCircNarrowest: waistCircNarrowest ?? this.waistCircNarrowest,
      hipCircMax: hipCircMax ?? this.hipCircMax,
      midThighCirc: midThighCirc ?? this.midThighCirc,
      maxCalfCirc: maxCalfCirc ?? this.maxCalfCirc,
      neckCirc: neckCirc ?? this.neckCirc,
      wristDiameter: wristDiameter ?? this.wristDiameter,
      kneeDiameter: kneeDiameter ?? this.kneeDiameter,
      individualMeasurements:
          individualMeasurements ?? this.individualMeasurements,
    );
  }

  Map<String, dynamic> toJson() {
    double? finiteOrNull(num? value) {
      if (value == null) return null;
      final d = value.toDouble();
      return d.isFinite ? d : null;
    }

    return {
      'date': date.toIso8601String(),
      'weightKg': finiteOrNull(weightKg),
      'heightCm': finiteOrNull(heightCm),
      'tricipitalFold': finiteOrNull(tricipitalFold),
      'subscapularFold': finiteOrNull(subscapularFold),
      'suprailiacFold': finiteOrNull(suprailiacFold),
      'supraspinalFold': finiteOrNull(supraspinalFold),
      'abdominalFold': finiteOrNull(abdominalFold),
      'thighFold': finiteOrNull(thighFold),
      'calfFold': finiteOrNull(calfFold),
      'armRelaxedCirc': finiteOrNull(armRelaxedCirc),
      'armFlexedCirc': finiteOrNull(armFlexedCirc),
      'waistCircNarrowest': finiteOrNull(waistCircNarrowest),
      'hipCircMax': finiteOrNull(hipCircMax),
      'midThighCirc': finiteOrNull(midThighCirc),
      'maxCalfCirc': finiteOrNull(maxCalfCirc),
      'neckCirc': finiteOrNull(neckCirc),
      'wristDiameter': finiteOrNull(wristDiameter),
      'kneeDiameter': finiteOrNull(kneeDiameter),
      'individualMeasurements': individualMeasurements?.map(
        (key, value) => MapEntry(key, value.map((v) => v?.toDouble()).toList()),
      ),
    };
  }

  factory AnthropometryRecord.fromJson(Map<String, dynamic> json) {
    return AnthropometryRecord(
      date: DateTime.parse(json['date']),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      tricipitalFold: (json['tricipitalFold'] as num?)?.toDouble(),
      subscapularFold: (json['subscapularFold'] as num?)?.toDouble(),
      suprailiacFold: (json['suprailiacFold'] as num?)?.toDouble(),
      supraspinalFold: (json['supraspinalFold'] as num?)?.toDouble(),
      abdominalFold: (json['abdominalFold'] as num?)?.toDouble(),
      thighFold: (json['thighFold'] as num?)?.toDouble(),
      calfFold: (json['calfFold'] as num?)?.toDouble(),
      armRelaxedCirc: (json['armRelaxedCirc'] as num?)?.toDouble(),
      armFlexedCirc: (json['armFlexedCirc'] as num?)?.toDouble(),
      waistCircNarrowest: (json['waistCircNarrowest'] as num?)?.toDouble(),
      hipCircMax: (json['hipCircMax'] as num?)?.toDouble(),
      midThighCirc: (json['midThighCirc'] as num?)?.toDouble(),
      maxCalfCirc: (json['maxCalfCirc'] as num?)?.toDouble(),
      neckCirc: (json['neckCirc'] as num?)?.toDouble(),
      wristDiameter: (json['wristDiameter'] as num?)?.toDouble(),
      kneeDiameter: (json['kneeDiameter'] as num?)?.toDouble(),
      individualMeasurements: json['individualMeasurements'] != null
          ? Map<String, List<double?>>.from(
              (json['individualMeasurements'] as Map<String, dynamic>).map(
                (key, value) => MapEntry(
                  key,
                  (value as List<dynamic>)
                      .map((v) => (v as num?)?.toDouble())
                      .toList(),
                ),
              ),
            )
          : null,
    );
  }
}
