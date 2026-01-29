import 'package:hcs_app_lap/utils/date_helpers.dart';

class NutritionAdherenceLog {
  final String dateIso;
  final int targetCalories;
  final int actualCalories;
  final double adherencePct;
  final String? notes;
  final String createdAtIso;

  const NutritionAdherenceLog({
    required this.dateIso,
    required this.targetCalories,
    required this.actualCalories,
    required this.adherencePct,
    required this.notes,
    required this.createdAtIso,
  });

  Map<String, dynamic> toJson() => {
    'dateIso': dateIso,
    'targetCalories': targetCalories,
    'actualCalories': actualCalories,
    'adherencePct': adherencePct,
    'notes': notes,
    'createdAtIso': createdAtIso,
  };

  factory NutritionAdherenceLog.fromJson(Map<String, dynamic> json) {
    return NutritionAdherenceLog(
      dateIso: json['dateIso']?.toString() ?? '',
      targetCalories: _parseInt(json['targetCalories']),
      actualCalories: _parseInt(json['actualCalories']),
      adherencePct: _parseDouble(json['adherencePct']),
      notes: json['notes']?.toString(),
      createdAtIso: json['createdAtIso']?.toString() ?? '',
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }
}

List<NutritionAdherenceLog> readNutritionAdherenceLogs(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map(
        (record) =>
            NutritionAdherenceLog.fromJson(record.cast<String, dynamic>()),
      )
      .toList();
}

String? _normalizeDateIso(dynamic raw) {
  if (raw == null) return null;
  final s = raw.toString();
  final dt = DateTime.tryParse(s);
  if (dt != null) return dateIsoFrom(dt);
  final match = RegExp(r'^(\d{4}-\d{2}-\d{2})').firstMatch(s);
  if (match != null) {
    try {
      final d = DateTime.parse(match.group(1)!);
      return dateIsoFrom(d);
    } catch (_) {
      return null;
    }
  }
  return null;
}

NutritionAdherenceLog? nutritionAdherenceLogForDate(
  List<NutritionAdherenceLog> logs,
  String dateIso,
) {
  final target = _normalizeDateIso(dateIso);
  if (target == null) return null;
  for (final log in logs) {
    final ldate = _normalizeDateIso(log.dateIso);
    if (ldate == target) return log;
  }
  return null;
}

NutritionAdherenceLog? latestNutritionAdherenceLogByDate(
  List<NutritionAdherenceLog> logs,
) {
  if (logs.isEmpty) return null;
  NutritionAdherenceLog? latest;
  String? latestIso;
  for (final log in logs) {
    final recordIso = _normalizeDateIso(log.dateIso);
    if (recordIso == null) continue;
    if (latestIso == null || recordIso.compareTo(latestIso) > 0) {
      latest = log;
      latestIso = recordIso;
    }
  }
  return latest;
}

List<NutritionAdherenceLog> upsertNutritionAdherenceLogByDate(
  List<NutritionAdherenceLog> logs,
  NutritionAdherenceLog log,
) {
  final target = _normalizeDateIso(log.dateIso) ?? log.dateIso;
  final updated = List<NutritionAdherenceLog>.from(logs)
    ..removeWhere((entry) => _normalizeDateIso(entry.dateIso) == target)
    ..add(log);
  updated.sort((a, b) {
    final aIso = _normalizeDateIso(a.dateIso) ?? a.dateIso;
    final bIso = _normalizeDateIso(b.dateIso) ?? b.dateIso;
    return aIso.compareTo(bIso);
  });
  return updated;
}
