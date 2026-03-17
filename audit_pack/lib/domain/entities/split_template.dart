import 'package:equatable/equatable.dart';

/// Representa un split semanal determinístico y su distribución de volumen.
/// - splitId: identificador del patrón (fullbody_3d, upper_lower_4d, ppl_5d, ppl_6d)
/// - dayMuscles: asignación de músculos por día (1..daysPerWeek)
/// - dailyVolume: sets planificados por día y músculo
class SplitTemplate extends Equatable {
  final String splitId;
  final int daysPerWeek;
  final Map<int, List<String>> dayMuscles;
  final Map<int, Map<String, int>> dailyVolume;

  const SplitTemplate({
    required this.splitId,
    required this.daysPerWeek,
    required this.dayMuscles,
    required this.dailyVolume,
  });

  SplitTemplate copyWith({
    String? splitId,
    int? daysPerWeek,
    Map<int, List<String>>? dayMuscles,
    Map<int, Map<String, int>>? dailyVolume,
  }) {
    return SplitTemplate(
      splitId: splitId ?? this.splitId,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      dayMuscles: dayMuscles ?? this.dayMuscles,
      dailyVolume: dailyVolume ?? this.dailyVolume,
    );
  }

  Map<String, dynamic> toJson() => {
    'splitId': splitId,
    'daysPerWeek': daysPerWeek,
    'dayMuscles': dayMuscles.map((k, v) => MapEntry(k.toString(), v)),
    'dailyVolume': dailyVolume.map((k, v) => MapEntry(k.toString(), v)),
  };

  factory SplitTemplate.fromJson(Map<String, dynamic> json) {
    Map<int, List<String>> parseDayMuscles(dynamic raw) {
      final map = <int, List<String>>{};
      if (raw is Map) {
        raw.forEach((key, value) {
          final day = int.tryParse(key.toString()) ?? 1;
          final list = <String>[];
          if (value is List) {
            for (final m in value) {
              list.add(m.toString());
            }
          }
          map[day] = list;
        });
      }
      return map;
    }

    Map<int, Map<String, int>> parseDailyVolume(dynamic raw) {
      final map = <int, Map<String, int>>{};
      if (raw is Map) {
        raw.forEach((key, value) {
          final day = int.tryParse(key.toString()) ?? 1;
          final inner = <String, int>{};
          if (value is Map) {
            value.forEach((mk, mv) {
              inner[mk.toString()] = mv is int
                  ? mv
                  : (mv is num ? mv.toInt() : int.tryParse(mv.toString()) ?? 0);
            });
          }
          map[day] = inner;
        });
      }
      return map;
    }

    return SplitTemplate(
      splitId: json['splitId']?.toString() ?? 'unknown',
      daysPerWeek: (json['daysPerWeek'] as num?)?.toInt() ?? 3,
      dayMuscles: parseDayMuscles(json['dayMuscles']),
      dailyVolume: parseDailyVolume(json['dailyVolume']),
    );
  }

  @override
  List<Object?> get props => [splitId, daysPerWeek, dayMuscles, dailyVolume];
}
