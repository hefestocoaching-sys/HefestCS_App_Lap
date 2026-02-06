import 'package:hcs_app_lap/domain/training_domain/pain_rule.dart';

class TrainingEvaluationSnapshotV1 {
  final int schemaVersion;
  final DateTime createdAt;
  final DateTime updatedAt;

  final int daysPerWeek;
  final int sessionDurationMinutes;
  final int planDurationInWeeks;

  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final List<String> tertiaryMuscles;

  final Map<String, double> priorityVolumeSplit;
  final Map<String, double> intensityDistribution;

  final List<PainRule> painRules;

  final String status; // minimal | partial | complete

  const TrainingEvaluationSnapshotV1({
    required this.schemaVersion,
    required this.createdAt,
    required this.updatedAt,
    required this.daysPerWeek,
    required this.sessionDurationMinutes,
    required this.planDurationInWeeks,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.tertiaryMuscles,
    required this.priorityVolumeSplit,
    required this.intensityDistribution,
    required this.painRules,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'daysPerWeek': daysPerWeek,
      'sessionDurationMinutes': sessionDurationMinutes,
      'planDurationInWeeks': planDurationInWeeks,
      'primaryMuscles': primaryMuscles,
      'secondaryMuscles': secondaryMuscles,
      'tertiaryMuscles': tertiaryMuscles,
      'priorityVolumeSplit': priorityVolumeSplit,
      'intensityDistribution': intensityDistribution,
      'painRules': painRules.map((rule) => rule.toJson()).toList(),
      'status': status,
    };
  }

  factory TrainingEvaluationSnapshotV1.fromJson(Map<String, dynamic> json) {
    final rawPainRules = json['painRules'];
    final painRules = <PainRule>[];
    if (rawPainRules is List) {
      for (final item in rawPainRules) {
        if (item is Map<String, dynamic>) {
          painRules.add(PainRule.fromJson(item));
        } else if (item is Map) {
          painRules.add(PainRule.fromJson(item.cast<String, dynamic>()));
        }
      }
    }

    return TrainingEvaluationSnapshotV1(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      daysPerWeek: (json['daysPerWeek'] as num?)?.toInt() ?? 0,
      sessionDurationMinutes:
          (json['sessionDurationMinutes'] as num?)?.toInt() ?? 0,
      planDurationInWeeks: (json['planDurationInWeeks'] as num?)?.toInt() ?? 0,
      primaryMuscles: _readStringList(json['primaryMuscles']),
      secondaryMuscles: _readStringList(json['secondaryMuscles']),
      tertiaryMuscles: _readStringList(json['tertiaryMuscles']),
      priorityVolumeSplit: _readDoubleMap(json['priorityVolumeSplit']),
      intensityDistribution: _readDoubleMap(json['intensityDistribution']),
      painRules: painRules,
      status: json['status']?.toString() ?? 'minimal',
    );
  }

  static List<String> _readStringList(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      return raw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static Map<String, double> _readDoubleMap(dynamic raw) {
    if (raw is Map) {
      return raw.map(
        (key, value) =>
            MapEntry(key.toString(), (value as num?)?.toDouble() ?? 0.0),
      );
    }
    return const {};
  }
}
