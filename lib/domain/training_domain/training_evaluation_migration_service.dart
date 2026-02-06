import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/training_domain/pain_rule.dart';
import 'package:hcs_app_lap/domain/training_domain/training_evaluation_snapshot_v1.dart';
import 'package:hcs_app_lap/domain/training_domain/training_progression_state_v1.dart';
import 'package:hcs_app_lap/domain/training_domain/training_setup_v1.dart';

class TrainingEvaluationMigrationService {
  TrainingEvaluationMigrationService._();

  static bool needsMigration(Map<String, dynamic> extra) {
    return !extra.containsKey(TrainingExtraKeys.trainingSetupV1) ||
        !extra.containsKey(TrainingExtraKeys.trainingEvaluationSnapshotV1) ||
        !extra.containsKey(TrainingExtraKeys.trainingProgressionStateV1);
  }

  static Client migrateLegacyToV1(Client client) {
    final extra = Map<String, dynamic>.from(client.training.extra);
    if (!needsMigration(extra)) {
      return client;
    }

    final now = DateTime.now();
    final setup = _buildSetup(client, extra);
    final evaluation = _buildEvaluation(client, extra, now);
    final progression = _buildProgression(client, extra);

    extra[TrainingExtraKeys.trainingSetupV1] = setup.toJson();
    extra[TrainingExtraKeys.trainingEvaluationSnapshotV1] = evaluation.toJson();
    extra[TrainingExtraKeys.trainingProgressionStateV1] = progression.toJson();

    return client.copyWith(training: client.training.copyWith(extra: extra));
  }

  static TrainingSetupV1 _buildSetup(
    Client client,
    Map<String, dynamic> extra,
  ) {
    final heightCm = _readDouble(extra[TrainingExtraKeys.heightCm]);
    final weightKg = _readDouble(extra[TrainingExtraKeys.weightKg]);
    final ageYears = client.training.age ?? client.profile.age ?? 0;
    final sex =
        client.training.gender?.name ?? client.profile.gender?.name ?? '';

    return TrainingSetupV1(
      heightCm: heightCm,
      weightKg: weightKg,
      ageYears: ageYears,
      sex: sex,
    );
  }

  static TrainingEvaluationSnapshotV1 _buildEvaluation(
    Client client,
    Map<String, dynamic> extra,
    DateTime now,
  ) {
    final existing = _readEvaluationSnapshot(extra);
    final createdAt = existing?.createdAt ?? now;

    final daysPerWeek = _readInt(extra[TrainingExtraKeys.daysPerWeek]);
    final sessionDurationMinutes = _readInt(
      extra[TrainingExtraKeys.timePerSessionMinutes],
    );
    final planDurationInWeeks = _readInt(
      extra[TrainingExtraKeys.planDurationInWeeks],
    );

    final primary = _readMuscleList(
      extra[TrainingExtraKeys.priorityMusclesPrimary],
    );
    final secondary = _readMuscleList(
      extra[TrainingExtraKeys.priorityMusclesSecondary],
    );
    final tertiary = _readMuscleList(
      extra[TrainingExtraKeys.priorityMusclesTertiary],
    );

    final priorityVolumeSplit = _buildPrioritySplit(
      extra,
      primary,
      secondary,
      tertiary,
    );
    final intensityDistribution = _readIntensityDistribution(extra);

    final painRules = existing?.painRules ?? _readPainRules(extra);

    final status = _deriveStatus(
      daysPerWeek: daysPerWeek,
      sessionDurationMinutes: sessionDurationMinutes,
      planDurationInWeeks: planDurationInWeeks,
      primary: primary,
      secondary: secondary,
      tertiary: tertiary,
      priorityVolumeSplit: priorityVolumeSplit,
      intensityDistribution: intensityDistribution,
    );

    return TrainingEvaluationSnapshotV1(
      schemaVersion: 1,
      createdAt: createdAt,
      updatedAt: now,
      daysPerWeek: daysPerWeek,
      sessionDurationMinutes: sessionDurationMinutes,
      planDurationInWeeks: planDurationInWeeks,
      primaryMuscles: primary,
      secondaryMuscles: secondary,
      tertiaryMuscles: tertiary,
      priorityVolumeSplit: priorityVolumeSplit,
      intensityDistribution: intensityDistribution,
      painRules: painRules,
      status: status,
    );
  }

  static TrainingProgressionStateV1 _buildProgression(
    Client client,
    Map<String, dynamic> extra,
  ) {
    final existing = _readProgressionState(extra);
    if (existing != null) {
      return existing;
    }

    final weeksCompleted = _readListLength(
      extra[TrainingExtraKeys.weeklyVolumeHistory],
    );
    final sessionsCompleted = _readListLength(
      extra[TrainingExtraKeys.trainingSessionLogRecords],
    );

    final lastPlanId =
        extra[TrainingExtraKeys.activePlanId]?.toString() ??
        (client.trainingPlans.isNotEmpty ? client.trainingPlans.last.id : '');

    return TrainingProgressionStateV1(
      weeksCompleted: weeksCompleted,
      sessionsCompleted: sessionsCompleted,
      consecutiveWeeksTraining: weeksCompleted,
      averageRIR: 0.0,
      averageSessionRPE: 0.0,
      perceivedRecovery: 0.0,
      lastPlanId: lastPlanId,
      lastPlanChangeReason: 'legacy_migration',
    );
  }

  static TrainingEvaluationSnapshotV1? _readEvaluationSnapshot(
    Map<String, dynamic> extra,
  ) {
    final raw = extra[TrainingExtraKeys.trainingEvaluationSnapshotV1];
    if (raw is Map<String, dynamic>) {
      return TrainingEvaluationSnapshotV1.fromJson(raw);
    }
    if (raw is Map) {
      return TrainingEvaluationSnapshotV1.fromJson(raw.cast<String, dynamic>());
    }
    return null;
  }

  static TrainingProgressionStateV1? _readProgressionState(
    Map<String, dynamic> extra,
  ) {
    final raw = extra[TrainingExtraKeys.trainingProgressionStateV1];
    if (raw is Map<String, dynamic>) {
      return TrainingProgressionStateV1.fromJson(raw);
    }
    if (raw is Map) {
      return TrainingProgressionStateV1.fromJson(raw.cast<String, dynamic>());
    }
    return null;
  }

  static double _readDouble(dynamic raw) {
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '') ?? 0.0;
  }

  static int _readInt(dynamic raw) {
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  static int _readListLength(dynamic raw) {
    if (raw is List) return raw.length;
    return 0;
  }

  static List<String> _readMuscleList(dynamic raw) {
    if (raw is String && raw.trim().isNotEmpty) {
      return raw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (raw is List) {
      return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    return const [];
  }

  static Map<String, double> _buildPrioritySplit(
    Map<String, dynamic> extra,
    List<String> primary,
    List<String> secondary,
    List<String> tertiary,
  ) {
    final targetSets = _readTargetSets(extra);
    if (targetSets.isEmpty) return const {};

    double sumFor(List<String> muscles) {
      double total = 0.0;
      for (final muscle in muscles) {
        total += targetSets[muscle] ?? 0.0;
      }
      return total;
    }

    final primaryTotal = sumFor(primary);
    final secondaryTotal = sumFor(secondary);
    final tertiaryTotal = sumFor(tertiary);
    final total = primaryTotal + secondaryTotal + tertiaryTotal;

    if (total <= 0) return const {};

    return {
      'primary': primaryTotal / total,
      'secondary': secondaryTotal / total,
      'tertiary': tertiaryTotal / total,
    };
  }

  static Map<String, double> _readTargetSets(Map<String, dynamic> extra) {
    final raw =
        extra[TrainingExtraKeys.finalTargetSetsByMuscleUi] ??
        extra[TrainingExtraKeys.targetSetsByMuscle];
    if (raw is Map) {
      return raw.map(
        (key, value) =>
            MapEntry(key.toString(), (value as num?)?.toDouble() ?? 0.0),
      );
    }
    return const {};
  }

  static Map<String, double> _readIntensityDistribution(
    Map<String, dynamic> extra,
  ) {
    final raw = extra[TrainingExtraKeys.seriesTypePercentSplit];
    if (raw is Map) {
      return raw.map(
        (key, value) =>
            MapEntry(key.toString(), (value as num?)?.toDouble() ?? 0.0),
      );
    }
    return const {};
  }

  static List<PainRule> _readPainRules(Map<String, dynamic> extra) {
    final raw = extra['painRules'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => PainRule.fromJson(e.cast<String, dynamic>()))
          .toList();
    }
    return const [];
  }

  static String _deriveStatus({
    required int daysPerWeek,
    required int sessionDurationMinutes,
    required int planDurationInWeeks,
    required List<String> primary,
    required List<String> secondary,
    required List<String> tertiary,
    required Map<String, double> priorityVolumeSplit,
    required Map<String, double> intensityDistribution,
  }) {
    final hasBasics =
        daysPerWeek > 0 &&
        sessionDurationMinutes > 0 &&
        planDurationInWeeks > 0;
    final hasMuscles =
        primary.isNotEmpty || secondary.isNotEmpty || tertiary.isNotEmpty;

    if (!hasBasics && !hasMuscles) return 'minimal';

    final hasSplits = priorityVolumeSplit.isNotEmpty;
    final hasIntensity = intensityDistribution.isNotEmpty;

    if (hasBasics && hasMuscles && hasSplits && hasIntensity) {
      return 'complete';
    }

    return 'partial';
  }
}
