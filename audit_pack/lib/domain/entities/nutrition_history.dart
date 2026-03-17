// lib/domain/entities/nutrition_history.dart
import 'package:equatable/equatable.dart';

/// Historial agregado de nutrición para un cliente.
/// Resume adherencia al plan, desviaciones, y señales clínicas reportadas.
class NutritionHistory extends Equatable {
  /// Primer día con registro nutricional.
  final DateTime? firstLogDate;

  /// Último día con registro nutricional.
  final DateTime? lastLogDate;

  /// Días totales con registro (no necesariamente consecutivos).
  final int totalLoggedDays;

  /// Adherencia promedio a calorías (0–1).
  /// 1.0 = objetivo clavado, 0.8 = 20% de desviación promedio.
  final double calorieAdherence;

  /// Adherencia promedio a proteína (0–1).
  final double proteinAdherence;

  /// Adherencia promedio a carbohidratos (0–1).
  final double carbsAdherence;

  /// Adherencia promedio a grasas (0–1).
  final double fatsAdherence;

  /// Síntomas/feedback subjetivo agregado (conteos o flags).
  /// Ejemplo: { "hambreAlta": 12, "bajaEnergía": 5 }
  final Map<String, int> symptomCounts;

  /// Flags clínicos simples.
  final bool hadBingeEpisodes;
  final bool hadDigestiveIssues;

  bool get hasData => totalLoggedDays > 0;

  const NutritionHistory({
    this.firstLogDate,
    this.lastLogDate,
    this.totalLoggedDays = 0,
    this.calorieAdherence = 0.0,
    this.proteinAdherence = 0.0,
    this.carbsAdherence = 0.0,
    this.fatsAdherence = 0.0,
    this.symptomCounts = const {},
    this.hadBingeEpisodes = false,
    this.hadDigestiveIssues = false,
  });

  factory NutritionHistory.empty() => const NutritionHistory();

  NutritionHistory copyWith({
    DateTime? firstLogDate,
    DateTime? lastLogDate,
    int? totalLoggedDays,
    double? calorieAdherence,
    double? proteinAdherence,
    double? carbsAdherence,
    double? fatsAdherence,
    Map<String, int>? symptomCounts,
    bool? hadBingeEpisodes,
    bool? hadDigestiveIssues,
  }) {
    return NutritionHistory(
      firstLogDate: firstLogDate ?? this.firstLogDate,
      lastLogDate: lastLogDate ?? this.lastLogDate,
      totalLoggedDays: totalLoggedDays ?? this.totalLoggedDays,
      calorieAdherence: calorieAdherence ?? this.calorieAdherence,
      proteinAdherence: proteinAdherence ?? this.proteinAdherence,
      carbsAdherence: carbsAdherence ?? this.carbsAdherence,
      fatsAdherence: fatsAdherence ?? this.fatsAdherence,
      symptomCounts: symptomCounts ?? this.symptomCounts,
      hadBingeEpisodes: hadBingeEpisodes ?? this.hadBingeEpisodes,
      hadDigestiveIssues: hadDigestiveIssues ?? this.hadDigestiveIssues,
    );
  }

  factory NutritionHistory.fromJson(Map<String, dynamic>? json) {
    if (json == null) return NutritionHistory.empty();

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    Map<String, int> parseIntMap(dynamic raw) {
      if (raw is Map) {
        return raw.map<String, int>((key, value) {
          final k = key.toString();
          final v = (value is num) ? value.toInt() : 0;
          return MapEntry(k, v);
        });
      }
      return {};
    }

    return NutritionHistory(
      firstLogDate: parseDate(json['firstLogDate']),
      lastLogDate: parseDate(json['lastLogDate']),
      totalLoggedDays: (json['totalLoggedDays'] as num?)?.toInt() ?? 0,
      calorieAdherence: (json['calorieAdherence'] as num?)?.toDouble() ?? 0.0,
      proteinAdherence: (json['proteinAdherence'] as num?)?.toDouble() ?? 0.0,
      carbsAdherence: (json['carbsAdherence'] as num?)?.toDouble() ?? 0.0,
      fatsAdherence: (json['fatsAdherence'] as num?)?.toDouble() ?? 0.0,
      symptomCounts: parseIntMap(json['symptomCounts']),
      hadBingeEpisodes: json['hadBingeEpisodes'] == true,
      hadDigestiveIssues: json['hadDigestiveIssues'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    String? dateToString(DateTime? d) => d?.toIso8601String();

    return {
      'firstLogDate': dateToString(firstLogDate),
      'lastLogDate': dateToString(lastLogDate),
      'totalLoggedDays': totalLoggedDays,
      'calorieAdherence': calorieAdherence,
      'proteinAdherence': proteinAdherence,
      'carbsAdherence': carbsAdherence,
      'fatsAdherence': fatsAdherence,
      'symptomCounts': symptomCounts,
      'hadBingeEpisodes': hadBingeEpisodes,
      'hadDigestiveIssues': hadDigestiveIssues,
    };
  }

  @override
  List<Object?> get props => [
    firstLogDate,
    lastLogDate,
    totalLoggedDays,
    calorieAdherence,
    proteinAdherence,
    carbsAdherence,
    fatsAdherence,
    symptomCounts,
    hadBingeEpisodes,
    hadDigestiveIssues,
  ];
}
