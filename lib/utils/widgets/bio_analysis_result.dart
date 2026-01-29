// lib/models/bio_analysis_result.dart
import 'package:flutter/material.dart'; // Necesitarás importar esto para 'Color'

enum BioStatus { normal, optimal, low, high, criticallyLow, criticallyHigh }

class BioAnalysisResult {
  final BioStatus status;
  final String interpretation;
  final String recommendation;
  final Color color;

  BioAnalysisResult({
    required this.status,
    required this.interpretation,
    required this.recommendation,
    required this.color,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is BioAnalysisResult &&
              runtimeType == other.runtimeType &&
              status == other.status &&
              interpretation == other.interpretation &&
              recommendation == other.recommendation &&
              color == other.color;

  @override
  int get hashCode =>
      status.hashCode ^
      interpretation.hashCode ^
      recommendation.hashCode ^
      color.hashCode;
}