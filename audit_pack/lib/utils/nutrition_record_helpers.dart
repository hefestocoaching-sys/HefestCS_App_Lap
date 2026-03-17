import 'package:hcs_app_lap/domain/entities/daily_macro_settings.dart';
import 'package:hcs_app_lap/domain/entities/daily_meal_plan.dart';
import 'package:hcs_app_lap/utils/date_helpers.dart';

List<Map<String, dynamic>> readNutritionRecordList(dynamic raw) {
  if (raw is! List) return [];
  return raw
      .whereType<Map>()
      .map(
        (record) => record.map((key, value) => MapEntry(key.toString(), value)),
      )
      .toList();
}

String? _normalizeDateIso(dynamic raw) {
  if (raw == null) return null;
  try {
    final s = raw.toString().trim();
    if (s.isEmpty) return null;

    // Try full parse first (handles timestamps and date-only)
    var dt = DateTime.tryParse(s);
    if (dt != null) return dateIsoFrom(dt);

    // Fallback: try to extract YYYY-MM-DD prefix and parse safely
    final match = RegExp(r'^(\d{4}-\d{2}-\d{2})').firstMatch(s);
    if (match != null) {
      final extracted = match.group(1)!;
      dt = DateTime.tryParse(extracted);
      if (dt != null) return dateIsoFrom(dt);
    }

    return null;
  } catch (_) {
    return null;
  }
}

Map<String, dynamic>? nutritionRecordForDate(
  List<Map<String, dynamic>> records,
  String dateIso, {
  String dateKey = 'dateIso',
}) {
  for (final record in records) {
    final recordDateNorm = _normalizeDateIso(record[dateKey]);
    if (recordDateNorm == dateIso) {
      return record;
    }
  }
  return null;
}

Map<String, dynamic>? latestNutritionRecordByDate(
  List<Map<String, dynamic>> records, {
  String dateKey = 'dateIso',
}) {
  if (records.isEmpty) return null;
  Map<String, dynamic>? latest;
  String? latestIso;
  for (final record in records) {
    final recordIso = _normalizeDateIso(record[dateKey]);
    if (recordIso == null) continue; // ignore invalid dates
    if (latestIso == null || recordIso.compareTo(latestIso) > 0) {
      latest = record;
      latestIso = recordIso;
    }
  }
  return latest;
}

void sortNutritionRecordsByDate(
  List<Map<String, dynamic>> records, {
  String dateKey = 'dateIso',
}) {
  try {
    records.sort((a, b) {
      try {
        final leftIso = _normalizeDateIso(a[dateKey]);
        final rightIso = _normalizeDateIso(b[dateKey]);
        if (leftIso == null && rightIso == null) return 0;
        if (leftIso == null) return 1; // invalid dates go last
        if (rightIso == null) return -1;
        return leftIso.compareTo(rightIso);
      } catch (_) {
        // Si algo falla en la comparación, mantener orden actual
        return 0;
      }
    });
  } catch (_) {
    // Si el sort falla completamente, ignorar silenciosamente
    // Los registros se quedan en su orden actual
  }
}

Map<String, int>? parseDailyKcalMap(dynamic raw) {
  if (raw is! Map) return null;
  return raw.map<String, int>((key, value) {
    final kcal = value is num ? value.toInt() : 0;
    return MapEntry(key.toString(), kcal);
  });
}

Map<String, DailyMacroSettings>? parseWeeklyMacroSettings(dynamic raw) {
  if (raw is! Map) return null;
  final Map<String, DailyMacroSettings> parsed = {};
  raw.forEach((key, value) {
    if (value is DailyMacroSettings) {
      parsed[key.toString()] = value;
    } else if (value is Map) {
      parsed[key.toString()] = DailyMacroSettings.fromJson(
        value.cast<String, dynamic>(),
      );
    }
  });
  return parsed;
}

Map<String, DailyMealPlan>? parseDailyMealPlans(dynamic raw) {
  if (raw is! Map) return null;
  final Map<String, DailyMealPlan> parsed = {};
  raw.forEach((key, value) {
    if (value is DailyMealPlan) {
      parsed[key.toString()] = value;
    } else if (value is Map) {
      parsed[key.toString()] = DailyMealPlan.fromJson(
        value.cast<String, dynamic>(),
      );
    }
  });
  return parsed;
}
