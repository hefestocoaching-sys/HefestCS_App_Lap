import 'package:flutter/foundation.dart';
import 'package:hcs_app_lap/domain/training_v3/models/muscle_progression.dart';
import 'package:hcs_app_lap/domain/training_v3/models/progress_record.dart';
import 'package:hcs_app_lap/domain/training_v3/models/feedback_entry.dart';
import 'package:hcs_app_lap/domain/training_v3/models/exercise_angle_coverage.dart';

/// Resultado de validación
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final Map<String, dynamic> metadata;

  const ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
    this.metadata = const {},
  });

  /// Créa un ValidationResult exitoso
  factory ValidationResult.success({List<String> warnings = const []}) {
    return ValidationResult(isValid: true, warnings: warnings);
  }

  /// Crea un ValidationResult fallido
  factory ValidationResult.failed({
    required List<String> errors,
    List<String> warnings = const [],
  }) {
    return ValidationResult(isValid: false, errors: errors, warnings: warnings);
  }

  /// Resumen para logging
  String get summary {
    final status = isValid ? '✅ PASS' : '❌ FAIL';
    final errCount = errors.length;
    final warnCount = warnings.length;
    return '$status | Errors: $errCount | Warnings: $warnCount';
  }

  /// Full report
  String get fullReport {
    final buf = StringBuffer();
    buf.writeln('═══════════════════════════════════════════════════════');
    buf.writeln('VALIDATION REPORT: $summary');
    buf.writeln('═══════════════════════════════════════════════════════');

    if (errors.isNotEmpty) {
      buf.writeln('❌ ERRORS:');
      for (final error in errors) {
        buf.writeln('  - $error');
      }
      buf.writeln();
    }

    if (warnings.isNotEmpty) {
      buf.writeln('⚠️  WARNINGS:');
      for (final warning in warnings) {
        buf.writeln('  - $warning');
      }
      buf.writeln();
    }

    if (isValid && errors.isEmpty && warnings.isEmpty) {
      buf.writeln('✅ All validations passed!');
    }

    buf.writeln('═══════════════════════════════════════════════════════');
    return buf.toString();
  }
}

/// Motor de validación QA para auditoría de lógica de entrenamiento
///
/// RESPONSABILIDADES:
/// - Validar logica de progresa primario vs secundario vs terciario
/// - Validar deloads están siendo aplicados correctamente
/// - Validar cobertura angular
/// - Crear logs detallados para auditoría
/// - Prevenir violaciones de reglas científicas
///
/// VALIDACIONES:
/// 1. Primarios nunca superan MRV
/// 2. Secundarios nunca superan 0.8×MRV
/// 3. Terciarios siempre VOP
/// 4. Deload se aplica cuando necesario (feedback o automático)
/// 5. Microdeload cada 4-5 semanas en P, 5-6 en S
/// 6. Cobertura angular suficiente (≥70% para P, ≥50% para S)
/// 7. VMR bien documentado cuando se descubre
/// 8. Decisiones tienen trazabilidad (reason/reason bien documentados)
///
/// VERSIÓN: 1.0.0
class TrainingValidationEngine {
  static final _instance = TrainingValidationEngine._internal();

  TrainingValidationEngine._internal();

  factory TrainingValidationEngine() => _instance;

  /// ═══════════════════════════════════════════════════════════════════
  /// 1. VALIDAR PROGRESIÓN DE MÚSCULO
  /// ═══════════════════════════════════════════════════════════════════

  /// Valida que un MuscleProgression cumple con las reglas científicas
  ValidationResult validateMuscleProgression(MuscleProgression muscle) {
    final errors = <String>[];
    final warnings = <String>[];

    // Rule 1: Primarios no superan MRV
    if (muscle.isPrimary && muscle.currentSets > muscle.mrvSets) {
      errors.add(
        '[${muscle.muscle}] PRIMARY: Sets (${muscle.currentSets}) exceeds MRV (${muscle.mrvSets})',
      );
    }

    // Rule 2: Secundarios no superan 0.8×MRV
    if (muscle.isSecondary) {
      final cap = (muscle.mrvSets * 0.8).ceil();
      if (muscle.currentSets > cap) {
        errors.add(
          '[${muscle.muscle}] SECONDARY: Sets (${muscle.currentSets}) exceeds 0.8×MRV cap ($cap)',
        );
      }
    }

    // Rule 3: Terciarios siempre VOP
    if (muscle.isTertiary && muscle.currentSets != muscle.vopSets) {
      errors.add(
        '[${muscle.muscle}] TERTIARY: Sets (${muscle.currentSets}) must equal VOP (${muscle.vopSets})',
      );
    }

    // Rule 4: Deload automático cada 4-5 semanas (P) o 5-6 (S)
    if (muscle.shouldAutoDeload && muscle.currentPhase != 'deloading') {
      warnings.add(
        '[${muscle.muscle}] AUTO-DELOAD: ${muscle.weeksSinceDeload}w since last deload (${muscle.weeksUntilAutoDeload}w recommended)',
      );
    }

    // Rule 5: VMR debe estar documentado si está en maintaining
    if (muscle.currentPhase == 'maintaining' && !muscle.hasDiscoveredMRV) {
      warnings.add(
        '[${muscle.muscle}] MAINTAINING without VMR discovered: should have empirical MRV',
      );
    }

    // Rule 6: Fases válidas
    const validPhases = [
      'discovering',
      'maintaining',
      'overreaching',
      'deloading',
    ];
    if (!validPhases.contains(muscle.currentPhase)) {
      errors.add('[${muscle.muscle}] INVALID PHASE: ${muscle.currentPhase}');
    }

    return errors.isEmpty
        ? ValidationResult.success(warnings: warnings)
        : ValidationResult.failed(errors: errors, warnings: warnings);
  }

  /// ═══════════════════════════════════════════════════════════════════
  /// 2. VALIDAR PROGRESO RECORD (decisión semanal)
  /// ═══════════════════════════════════════════════════════════════════

  /// Valida que ProgressRecord es coherente y bien documentado
  ValidationResult validateProgressRecord(
    ProgressRecord record,
    MuscleProgression previousMuscleState,
  ) {
    final errors = <String>[];
    final warnings = <String>[];

    // Rule 1: Adherencia debe ser realista (0-1)
    if (record.volumeAdherence < 0.0 || record.volumeAdherence > 1.2) {
      errors.add(
        '[${record.muscle}] ADHERENCE OUT OF RANGE: ${record.volumeAdherence}',
      );
    }

    // Rule 2: Volumen realizado vs prescrito
    final expectedPerformed = (record.volumePrescribed * record.volumeAdherence)
        .ceil();
    final actualPerformed = record.volumePerformed;
    if ((actualPerformed - expectedPerformed).abs() > 2) {
      warnings.add(
        '[${record.muscle}] ADHERENCE CALCULATION: Expected ~$expectedPerformed but got $actualPerformed',
      );
    }

    // Rule 3: RIR debe estar en rango razonable
    if (record.ripRange < 0 || record.ripRange > 5) {
      warnings.add(
        '[${record.muscle}] RIR OUT OF TYPICAL RANGE: ${record.ripRange}',
      );
    }

    // Rule 4: Decisión debe ser coherente con feedback
    if (record.fatigueLevel >= 8.0 && record.volumeAction == 'increase') {
      errors.add(
        '[${record.muscle}] INCOHERENT: HIGH FATIGUE (${record.fatigueLevel}) with INCREASE action',
      );
    }

    // Rule 5: Deload debe estar justificado
    if (record.wasDeload && record.deloadReason.isEmpty) {
      warnings.add(
        '[${record.muscle}] DELOAD: Missing deload reason (should document why)',
      );
    }

    // Rule 6: Cambio de volume debe ser sensato
    final volumeChange = record.newVolume - record.volumePrescribed;
    if (volumeChange.abs() > 6) {
      warnings.add(
        '[${record.muscle}] LARGE VOLUME CHANGE: ${volumeChange > 0 ? '+' : ''}$volumeChange sets',
      );
    }

    // Rule 7: Cobertura angular documentada
    if (record.exerciseAngles.isEmpty && !record.wasDeload) {
      warnings.add(
        '[${record.muscle}] MISSING EXERCISE ANGLES: Should document angle variation',
      );
    }

    // Rule 8: Coach notes para decisiones significativas
    if (record.volumeChange != 0 && record.coachNotes.isEmpty) {
      warnings.add(
        '[${record.muscle}] NOTE: Consider adding coach notes for volume change',
      );
    }

    return errors.isEmpty
        ? ValidationResult.success(warnings: warnings)
        : ValidationResult.failed(errors: errors, warnings: warnings);
  }

  /// ═══════════════════════════════════════════════════════════════════
  /// 3. VALIDAR FEEDBACK ENTRY
  /// ═══════════════════════════════════════════════════════════════════

  /// Valida coherencia de FeedbackEntry
  ValidationResult validateFeedbackEntry(FeedbackEntry feedback) {
    final errors = <String>[];
    final warnings = <String>[];

    // Rule 1: Ratings entre 1-10
    if (feedback.muscleActivation < 0 || feedback.muscleActivation > 10) {
      errors.add(
        '[${feedback.muscle}] Invalid muscleActivation: ${feedback.muscleActivation}',
      );
    }
    if (feedback.pumpQuality < 0 || feedback.pumpQuality > 10) {
      errors.add(
        '[${feedback.muscle}] Invalid pumpQuality: ${feedback.pumpQuality}',
      );
    }
    if (feedback.fatigueLevel < 0 || feedback.fatigueLevel > 10) {
      errors.add(
        '[${feedback.muscle}] Invalid fatigueLevel: ${feedback.fatigueLevel}',
      );
    }
    if (feedback.recoveryQuality < 0 || feedback.recoveryQuality > 10) {
      errors.add(
        '[${feedback.muscle}] Invalid recoveryQuality: ${feedback.recoveryQuality}',
      );
    }

    // Rule 2: Feedback coherencia (muscleActivation vs fatigue inverse)
    if (feedback.muscleActivation >= 8.0 && feedback.fatigueLevel >= 8.0) {
      warnings.add(
        '[${feedback.muscle}] UNUSUAL: High activation + high fatigue simultaneously',
      );
    }

    // Rule 3: Si hay pain, coachFeedback debe estar presente (después revisión)
    if (feedback.hadPain &&
        feedback.coachFeedback.isEmpty &&
        feedback.coachReviewedAt != null) {
      warnings.add(
        '[${feedback.muscle}] PAIN REPORTED: Coach should add notes',
      );
    }

    // Rule 4: Deload requested debe estar justificado
    if (feedback.deloadRequested && feedback.userComments.isEmpty) {
      warnings.add(
        '[${feedback.muscle}] DELOAD REQUESTED: Should provide reason in comments',
      );
    }

    return errors.isEmpty
        ? ValidationResult.success(warnings: warnings)
        : ValidationResult.failed(errors: errors, warnings: warnings);
  }

  /// ═══════════════════════════════════════════════════════════════════
  /// 4. VALIDAR COBERTURA ANGULAR
  /// ═══════════════════════════════════════════════════════════════════

  /// Valida cobertura de ángulos
  ValidationResult validateAngleCoverage(
    ExerciseAngleCoverage coverage,
    MuscleProgression muscle,
  ) {
    final errors = <String>[];
    final warnings = <String>[];

    // Rule 1: Cobertura debe ser suficiente para Primarios (≥70%)
    if (muscle.isPrimary && coverage.coverageRatio < 0.70) {
      warnings.add(
        '[${coverage.muscle}] PRIMARY: Coverage ${(coverage.coverageRatio * 100).toStringAsFixed(0)}% < 70% required',
      );
    }

    // Rule 2: Cobertura debe ser suficiente para Secundarios (≥50%)
    if (muscle.isSecondary && coverage.coverageRatio < 0.50) {
      warnings.add(
        '[${coverage.muscle}] SECONDARY: Coverage ${(coverage.coverageRatio * 100).toStringAsFixed(0)}% < 50% required',
      );
    }

    // Rule 3: Variedad semana a semana (primarios especialmente)
    if (muscle.isPrimary && !coverage.changedFromLastWeek) {
      warnings.add(
        '[${coverage.muscle}] PRIMARY: Same angles as last week - consider variation for better stimulus',
      );
    }

    // Rule 4: Ángulos faltantes documentados
    if (coverage.missingAngles.isNotEmpty && muscle.isPrimary) {
      debugPrint(
        '[${coverage.muscle}][AUDIT] Missing angles: ${coverage.missingAngles.join(", ")}',
      );
    }

    return errors.isEmpty
        ? ValidationResult.success(warnings: warnings)
        : ValidationResult.failed(errors: errors, warnings: warnings);
  }

  /// ═══════════════════════════════════════════════════════════════════
  /// 5. AUDITORÍA SEMANAL COMPLETA
  /// ═══════════════════════════════════════════════════════════════════

  /// Auditoría completa de una semana para todos los músc
  Map<String, ValidationResult> validateWeeklyAudit({
    required String userId,
    required int weekNumber,
    required Map<String, MuscleProgression> muscles,
    required Map<String, ProgressRecord> records,
    required Map<String, ExerciseAngleCoverage> angleCoverage,
  }) {
    final results = <String, ValidationResult>{};

    for (final entry in muscles.entries) {
      final muscle = entry.key;
      final muscleState = entry.value;
      final record = records[muscle];
      final coverage = angleCoverage[muscle];

      final errors = <String>[];
      final warnings = <String>[];

      // Validar MuscleProgression
      final mpResult = validateMuscleProgression(muscleState);
      errors.addAll(mpResult.errors);
      warnings.addAll(mpResult.warnings);

      // Validar ProgressRecord
      if (record != null) {
        final prResult = validateProgressRecord(record, muscleState);
        errors.addAll(prResult.errors);
        warnings.addAll(prResult.warnings);
      }

      // Validar AngleCoverage
      if (coverage != null) {
        final acResult = validateAngleCoverage(coverage, muscleState);
        errors.addAll(acResult.errors);
        warnings.addAll(acResult.warnings);
      }

      results[muscle] = errors.isEmpty
          ? ValidationResult.success(warnings: warnings)
          : ValidationResult.failed(errors: errors, warnings: warnings);

      // Log individual
      debugPrint(results[muscle]!.summary);
    }

    return results;
  }

  /// Genera reporte de auditoría semanal
  String generateWeeklyAuditReport({
    required String userId,
    required int weekNumber,
    required Map<String, ValidationResult> validationResults,
  }) {
    final buf = StringBuffer();
    buf.writeln('╔═══════════════════════════════════════════════════════╗');
    buf.writeln('║          WEEKLY AUDIT REPORT - WEEK $weekNumber         ║');
    buf.writeln('║          User: $userId                ║');
    buf.writeln('╚═══════════════════════════════════════════════════════╝');
    buf.writeln();

    // Summary
    final totalMuscles = validationResults.length;
    final passedMuscles = validationResults.values
        .where((r) => r.isValid)
        .length;
    final failedMuscles = totalMuscles - passedMuscles;

    buf.writeln('SUMMARY:');
    buf.writeln('  Total muscles: $totalMuscles');
    buf.writeln('  ✅ Passed: $passedMuscles');
    buf.writeln('  ❌ Failed: $failedMuscles');
    buf.writeln();

    // Details
    for (final entry in validationResults.entries) {
      final muscle = entry.key;
      final result = entry.value;

      buf.writeln('─────────────────────────────────────────────────────');
      buf.writeln('$muscle: ${result.summary}');

      if (result.errors.isNotEmpty) {
        buf.writeln('Errors:');
        for (final error in result.errors) {
          buf.writeln('  • $error');
        }
      }

      if (result.warnings.isNotEmpty) {
        buf.writeln('Warnings:');
        for (final warning in result.warnings) {
          buf.writeln('  ⚠️  $warning');
        }
      }
    }

    buf.writeln();
    buf.writeln('═══════════════════════════════════════════════════════');

    return buf.toString();
  }
}
