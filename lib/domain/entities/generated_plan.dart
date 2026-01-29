import 'package:hcs_app_lap/domain/entities/muscle_volume_buckets.dart';

/// Entidad que representa el plan de entrenamiento generado.
class GeneratedPlan {
  final int weeks;
  final Map<String, MuscleVolumeBuckets> volumePlan;
  final Map<String, dynamic> audit;

  const GeneratedPlan({
    this.weeks = 0,
    this.volumePlan = const {},
    this.audit = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'weeks': weeks,
      'volumePlan': volumePlan.map(
        (muscle, buckets) => MapEntry(muscle, {
          'heavySets': buckets.heavySets,
          'mediumSets': buckets.mediumSets,
          'lightSets': buckets.lightSets,
        }),
      ),
      'audit': audit,
    };
  }

  factory GeneratedPlan.fromMap(Map<String, dynamic> map) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    double parseDouble(dynamic value) {
      if (value is double) return value;
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0.0;
    }

    final volumePlan = <String, MuscleVolumeBuckets>{};
    final rawVolumePlan = map['volumePlan'];
    if (rawVolumePlan is Map) {
      rawVolumePlan.forEach((key, value) {
        if (value is Map) {
          volumePlan[key.toString()] = MuscleVolumeBuckets(
            heavySets: parseDouble(value['heavySets']),
            mediumSets: parseDouble(value['mediumSets']),
            lightSets: parseDouble(value['lightSets']),
          );
        }
      });
    }

    final rawAudit = map['audit'];
    final auditMap = rawAudit is Map
        ? Map<String, dynamic>.from(rawAudit)
        : <String, dynamic>{};

    return GeneratedPlan(
      weeks: parseInt(map['weeks']),
      volumePlan: volumePlan,
      audit: auditMap,
    );
  }
}
