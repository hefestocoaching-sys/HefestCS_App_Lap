import 'dart:convert';
import 'package:flutter/foundation.dart';

class MusclePosterior {
  final double mevMean;
  final double mevSd;
  final double mrvMean;
  final double mrvSd;

  const MusclePosterior({
    required this.mevMean,
    required this.mevSd,
    required this.mrvMean,
    required this.mrvSd,
  });

  MusclePosterior copyWith({
    double? mevMean,
    double? mevSd,
    double? mrvMean,
    double? mrvSd,
  }) {
    return MusclePosterior(
      mevMean: mevMean ?? this.mevMean,
      mevSd: mevSd ?? this.mevSd,
      mrvMean: mrvMean ?? this.mrvMean,
      mrvSd: mrvSd ?? this.mrvSd,
    );
  }

  Map<String, dynamic> toJson() => {
    'mevMean': mevMean,
    'mevSd': mevSd,
    'mrvMean': mrvMean,
    'mrvSd': mrvSd,
  };

  static MusclePosterior fromJson(Map<String, dynamic> json) {
    double d(dynamic v, double fb) =>
        (v is num) ? v.toDouble() : double.tryParse('$v') ?? fb;
    return MusclePosterior(
      mevMean: d(json['mevMean'], 0),
      mevSd: d(json['mevSd'], 1),
      mrvMean: d(json['mrvMean'], 0),
      mrvSd: d(json['mrvSd'], 2),
    );
  }
}

class AthleteLongitudinalState {
  /// Posterior por músculo (keys canónicas en inglés)
  final Map<String, MusclePosterior> posteriorByMuscle;

  /// Sensibilidad a sueño/estrés (coeficientes 0..1)
  final double sleepSensitivity;
  final double stressSensitivity;

  /// Confiabilidad de RIR/RPE y adherencia (0..1)
  final double rirReliability;
  final double adherence;

  /// Última fecha de actualización (ISO)
  final String lastUpdatedIso;

  const AthleteLongitudinalState({
    required this.posteriorByMuscle,
    required this.sleepSensitivity,
    required this.stressSensitivity,
    required this.rirReliability,
    required this.adherence,
    required this.lastUpdatedIso,
  });

  factory AthleteLongitudinalState.empty(DateTime now) {
    return AthleteLongitudinalState(
      posteriorByMuscle: const {},
      sleepSensitivity: 0.35,
      stressSensitivity: 0.25,
      rirReliability: 0.70,
      adherence: 0.85,
      lastUpdatedIso: now.toIso8601String(),
    );
  }

  AthleteLongitudinalState copyWith({
    Map<String, MusclePosterior>? posteriorByMuscle,
    double? sleepSensitivity,
    double? stressSensitivity,
    double? rirReliability,
    double? adherence,
    String? lastUpdatedIso,
  }) {
    return AthleteLongitudinalState(
      posteriorByMuscle: posteriorByMuscle ?? this.posteriorByMuscle,
      sleepSensitivity: sleepSensitivity ?? this.sleepSensitivity,
      stressSensitivity: stressSensitivity ?? this.stressSensitivity,
      rirReliability: rirReliability ?? this.rirReliability,
      adherence: adherence ?? this.adherence,
      lastUpdatedIso: lastUpdatedIso ?? this.lastUpdatedIso,
    );
  }

  Map<String, dynamic> toJson() => {
    'posteriorByMuscle': posteriorByMuscle.map(
      (k, v) => MapEntry(k, v.toJson()),
    ),
    'sleepSensitivity': sleepSensitivity,
    'stressSensitivity': stressSensitivity,
    'rirReliability': rirReliability,
    'adherence': adherence,
    'lastUpdatedIso': lastUpdatedIso,
  };

  static AthleteLongitudinalState fromJson(
    Map<String, dynamic> json,
    DateTime now,
  ) {
    final raw = json['posteriorByMuscle'];
    final Map<String, MusclePosterior> post = {};
    if (raw is Map) {
      for (final e in raw.entries) {
        if (e.value is Map) {
          post[e.key.toString()] = MusclePosterior.fromJson(
            Map<String, dynamic>.from(e.value),
          );
        }
      }
    }
    double d(dynamic v, double fb) =>
        (v is num) ? v.toDouble() : double.tryParse('$v') ?? fb;

    return AthleteLongitudinalState(
      posteriorByMuscle: post,
      sleepSensitivity: d(json['sleepSensitivity'], 0.35),
      stressSensitivity: d(json['stressSensitivity'], 0.25),
      rirReliability: d(json['rirReliability'], 0.70),
      adherence: d(json['adherence'], 0.85),
      lastUpdatedIso: (json['lastUpdatedIso']?.toString().isNotEmpty ?? false)
          ? json['lastUpdatedIso'].toString()
          : now.toIso8601String(),
    );
  }

  static AthleteLongitudinalState fromExtra(
    Map<String, dynamic> extra,
    DateTime now,
  ) {
    final raw = extra['athleteLongitudinalState'];
    if (raw is Map) {
      return fromJson(Map<String, dynamic>.from(raw), now);
    }
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return fromJson(Map<String, dynamic>.from(decoded), now);
        }
      } catch (e) {
        // Ignorar error de parsing JSON - usar estado vacío por defecto
        if (kDebugMode) {
          debugPrint('Error parsing athleteLongitudinalState JSON: $e');
        }
      }
    }
    return AthleteLongitudinalState.empty(now);
  }

  Map<String, dynamic> toExtraValue() => toJson();
}
