import 'dart:convert';

import 'package:equatable/equatable.dart';

// Historias balanceadas para ML
import 'package:hcs_app_lap/domain/entities/nutrition_history.dart';
import 'package:hcs_app_lap/domain/entities/training_history.dart';
import 'package:hcs_app_lap/domain/services/latest_record_resolver.dart';
import 'package:hcs_app_lap/domain/training/training_cycle.dart';

import 'anthropometry_record.dart';
import 'biochemistry_record.dart';
import 'client_profile.dart';
import 'clinical_history.dart';
import 'daily_macro_settings.dart';
import 'daily_tracking_record.dart';
import 'exercise_log_entry.dart';
import 'glute_specialization_profile.dart';
import 'mobility_assessment.dart';
import 'movement_pattern_assessment.dart';
import 'psychological_training_profile.dart';
import 'strength_assessment.dart';
import 'training_evaluation.dart';
import 'emi2_profile.dart';
import 'volume_tolerance_profile.dart';
import 'nutrition_settings.dart';
import 'session_summary_log.dart';
import 'training_plan_config.dart';
import 'training_profile.dart';
import 'training_session.dart';
import 'training_week.dart';

/// Estado del cliente dentro del sistema.
enum ClientStatus { active, inactive, archived }

class Client extends Equatable {
  final String id;
  final ClientProfile profile;
  final ClinicalHistory history;
  final TrainingProfile training;
  final NutritionSettings nutrition;

  final DateTime createdAt;
  final DateTime updatedAt;
  final ClientStatus status;

  final TrainingHistory? trainingHistory;
  final NutritionHistory? nutritionHistory;

  final List<AnthropometryRecord> anthropometry;
  final List<BioChemistryRecord> biochemistry;
  final List<DailyTrackingRecord> tracking;

  final List<TrainingPlanConfig> trainingPlans;
  final List<TrainingWeek> trainingWeeks;
  final List<TrainingSession> trainingSessions;
  final List<ExerciseLogEntry> trainingLogs;
  final List<SessionSummaryLog> sessionLogs;
  final List<TrainingCycle> trainingCycles;
  final String? activeCycleId;

  final TrainingEvaluation? trainingEvaluation;
  final Emi2Profile? exerciseMotivation;
  final GluteSpecializationProfile? gluteSpecializationProfile;

  final List<MobilityAssessment> mobilityAssessments;
  final List<MovementPatternAssessment> movementPatternAssessments;
  final List<StrengthAssessment> strengthAssessments;
  final List<VolumeToleranceProfile> volumeToleranceProfiles;
  final List<PsychologicalTrainingProfile> psychologicalTrainingProfiles;

  final int? paidWeeks;

  /// Código de invitación único para que el cliente acceda a su cuenta
  final String? invitationCode;

  Client({
    required this.id,
    required this.profile,
    required this.history,
    required this.training,
    required this.nutrition,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.status = ClientStatus.active,
    this.trainingHistory,
    this.nutritionHistory,
    this.invitationCode,
    this.anthropometry = const [],
    this.biochemistry = const [],
    this.tracking = const [],
    this.trainingPlans = const [],
    this.trainingWeeks = const [],
    this.trainingSessions = const [],
    this.trainingLogs = const [],
    this.sessionLogs = const [],
    this.trainingCycles = const [],
    this.activeCycleId,
    this.trainingEvaluation,
    this.exerciseMotivation,
    this.gluteSpecializationProfile,
    this.mobilityAssessments = const [],
    this.movementPatternAssessments = const [],
    this.strengthAssessments = const [],
    this.volumeToleranceProfiles = const [],
    this.psychologicalTrainingProfiles = const [],
    this.paidWeeks,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Alias legacy.
  TrainingProfile get trainingProfile => training;

  // ===========================================================================
  // FROM JSON
  // ===========================================================================
  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] as String,

      profile: ClientProfile.fromJson(
        json['profile'] is String
            ? jsonDecode(json['profile'])
            : json['profile'],
      ),

      history: ClinicalHistory.fromJson(
        json['history'] is String
            ? jsonDecode(json['history'])
            : json['history'],
      ),

      training: json['training'] != null
          ? TrainingProfile.fromJson(
              json['training'] is String
                  ? jsonDecode(json['training'])
                  : json['training'],
            )
          : TrainingProfile.empty(),

      nutrition: NutritionSettings.fromJson(
        json['nutrition'] is String
            ? jsonDecode(json['nutrition'])
            : json['nutrition'],
      ),

      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      status: _parseStatus(json['status']),

      trainingHistory: json['trainingHistory'] != null
          ? TrainingHistory.fromJson(
              json['trainingHistory'] is String
                  ? jsonDecode(json['trainingHistory'])
                  : json['trainingHistory'],
            )
          : null,

      nutritionHistory: json['nutritionHistory'] != null
          ? NutritionHistory.fromJson(
              json['nutritionHistory'] is String
                  ? jsonDecode(json['nutritionHistory'])
                  : json['nutritionHistory'],
            )
          : null,

      anthropometry: _decodeList(
        json['anthropometry'],
        (e) => AnthropometryRecord.fromJson(e),
      ),

      biochemistry: _decodeList(
        json['biochemistry'],
        (e) => BioChemistryRecord.fromJson(e),
      ),

      tracking: _decodeList(
        json['tracking'],
        (e) => DailyTrackingRecord.fromJson(e),
      ),

      trainingPlans: _decodeList(
        json['trainingPlans'],
        (e) => TrainingPlanConfig.fromJson(e),
      ),

      trainingWeeks: _decodeList(
        json['trainingWeeks'],
        (e) => TrainingWeek.fromJson(e),
      ),

      trainingSessions: _decodeList(
        json['trainingSessions'],
        (e) => TrainingSession.fromJson(e),
      ),

      trainingLogs: _decodeList(
        json['trainingLogs'],
        (e) => ExerciseLogEntry.fromJson(e),
      ),

      sessionLogs: _decodeList(
        json['sessionLogs'],
        (e) => SessionSummaryLog.fromJson(e),
      ),

      trainingCycles: _decodeList(
        json['trainingCycles'],
        (e) => TrainingCycle.fromMap(e),
      ),

      activeCycleId: json['activeCycleId'] as String?,

      trainingEvaluation: json['trainingEvaluation'] == null
          ? null
          : TrainingEvaluation.fromJson(
              json['trainingEvaluation'] is String
                  ? jsonDecode(json['trainingEvaluation'])
                  : json['trainingEvaluation'],
            ),

      exerciseMotivation: json['exerciseMotivation'] == null
          ? null
          : Emi2Profile.fromJson(
              json['exerciseMotivation'] is String
                  ? jsonDecode(json['exerciseMotivation'])
                  : json['exerciseMotivation'],
            ),

      gluteSpecializationProfile: json['gluteSpecializationProfile'] == null
          ? null
          : GluteSpecializationProfile.fromJson(
              json['gluteSpecializationProfile'] is String
                  ? jsonDecode(json['gluteSpecializationProfile'])
                  : json['gluteSpecializationProfile'],
            ),

      mobilityAssessments: _decodeList(
        json['mobilityAssessments'],
        (e) => MobilityAssessment.fromJson(e),
      ),

      movementPatternAssessments: _decodeList(
        json['movementPatternAssessments'],
        (e) => MovementPatternAssessment.fromJson(e),
      ),

      strengthAssessments: _decodeList(
        json['strengthAssessments'],
        (e) => StrengthAssessment.fromJson(e),
      ),

      volumeToleranceProfiles: _decodeList(
        json['volumeToleranceProfiles'],
        (e) => VolumeToleranceProfile.fromJson(e),
      ),

      psychologicalTrainingProfiles: _decodeList(
        json['psychologicalTrainingProfiles'],
        (e) => PsychologicalTrainingProfile.fromJson(e),
      ),

      paidWeeks: json['paidWeeks'] as int?,
      invitationCode: json['invitationCode'] as String?,
    );
  }

  // ===========================================================================
  // TO JSON
  // ===========================================================================
  Map<String, dynamic> toJson() => {
    'id': id,
    'profile': profile.toJson(),
    'history': history.toJson(),
    'training': training.toJson(),
    'nutrition': nutrition.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'status': status.name,

    'trainingHistory': trainingHistory?.toJson(),
    'nutritionHistory': nutritionHistory?.toJson(),

    'anthropometry': anthropometry.map((e) => e.toJson()).toList(),
    'biochemistry': biochemistry.map((e) => e.toJson()).toList(),
    'tracking': tracking.map((e) => e.toJson()).toList(),

    'trainingPlans': trainingPlans.map((e) => e.toJson()).toList(),
    'trainingWeeks': trainingWeeks.map((e) => e.toJson()).toList(),
    'trainingSessions': trainingSessions.map((e) => e.toJson()).toList(),
    'trainingLogs': trainingLogs.map((e) => e.toJson()).toList(),
    'sessionLogs': sessionLogs.map((e) => e.toJson()).toList(),

    'trainingCycles': trainingCycles.map((e) => e.toMap()).toList(),
    'activeCycleId': activeCycleId,

    'trainingEvaluation': trainingEvaluation?.toJson(),
    'exerciseMotivation': exerciseMotivation?.toJson(),
    'gluteSpecializationProfile': gluteSpecializationProfile?.toJson(),

    'mobilityAssessments': mobilityAssessments.map((e) => e.toJson()).toList(),
    'movementPatternAssessments': movementPatternAssessments
        .map((e) => e.toJson())
        .toList(),
    'strengthAssessments': strengthAssessments.map((e) => e.toJson()).toList(),
    'volumeToleranceProfiles': volumeToleranceProfiles
        .map((e) => e.toJson())
        .toList(),
    'psychologicalTrainingProfiles': psychologicalTrainingProfiles
        .map((e) => e.toJson())
        .toList(),

    'paidWeeks': paidWeeks,
    'invitationCode': invitationCode,
  };

  // ===========================================================================
  // HELPERS
  // ===========================================================================
  static List<T> _decodeList<T>(
    dynamic raw,
    T Function(Map<String, dynamic>) builder,
  ) {
    if (raw == null) return [];
    final list = raw is String ? jsonDecode(raw) : raw;
    return (list as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(builder)
        .toList();
  }

  static ClientStatus _parseStatus(dynamic raw) {
    if (raw == null) return ClientStatus.active;
    return ClientStatus.values.firstWhere(
      (s) => s.name == raw.toString(),
      orElse: () => ClientStatus.active,
    );
  }

  // ===========================================================================
  // GETTERS UTILITARIOS
  // ===========================================================================
  String get fullName => profile.fullName;
  String get phone => profile.phone;
  int? get age => profile.age;
  String? get gender => profile.gender?.name;

  /// Helper genérico: filtra registros con fecha <= target (mismo día incluido)
  T? _latestAtOrBefore<T>(
    List<T> records,
    DateTime? target,
    DateTime? Function(T) dateOf,
  ) {
    if (records.isEmpty) return null;

    final baseTarget = target ?? DateTime.now();

    // Normalizar target a fin de día para incluir coincidencias en la misma fecha
    final targetDate = DateTime(
      baseTarget.year,
      baseTarget.month,
      baseTarget.day,
      23,
      59,
      59,
      999,
      999,
    );

    T? latest;
    DateTime? latestDate;

    for (final record in records) {
      final date = dateOf(record);
      if (date == null) continue;

      // Solo considerar registros con fecha <= globalDate
      if (date.isAfter(targetDate)) continue;

      if (latestDate == null || date.isAfter(latestDate)) {
        latest = record;
        latestDate = date;
      }
    }

    return latest;
  }

  AnthropometryRecord? get latestAnthropometryRecord =>
      _latestAtOrBefore(anthropometry, DateTime.now(), (record) => record.date);

  BioChemistryRecord? get latestBiochemistryRecord =>
      _latestAtOrBefore(biochemistry, DateTime.now(), (record) => record.date);

  DailyTrackingRecord? get latestTrackingRecord =>
      _latestAtOrBefore(tracking, DateTime.now(), (record) => record.date);

  /// Retorna el último registro de antropometría con fecha <= globalDate
  AnthropometryRecord? latestAnthropometryAtOrBefore(DateTime globalDate) =>
      _latestAtOrBefore(anthropometry, globalDate, (record) => record.date);

  /// Retorna el último registro bioquímico con fecha <= globalDate
  BioChemistryRecord? latestBiochemistryAtOrBefore(DateTime globalDate) =>
      _latestAtOrBefore(biochemistry, globalDate, (record) => record.date);

  /// Retorna el último registro de tracking con fecha <= globalDate
  DailyTrackingRecord? latestTrackingAtOrBefore(DateTime globalDate) =>
      _latestAtOrBefore(tracking, globalDate, (record) => record.date);

  /// Retorna la última evaluación de movilidad con fecha <= globalDate
  MobilityAssessment? latestMobilityAssessmentAtOrBefore(DateTime globalDate) =>
      _latestAtOrBefore(
        mobilityAssessments,
        globalDate,
        (record) => record.date,
      );

  /// Retorna la última evaluación de patrón de movimiento con fecha <= globalDate
  MovementPatternAssessment? latestMovementPatternAssessmentAtOrBefore(
    DateTime globalDate,
  ) => _latestAtOrBefore(
    movementPatternAssessments,
    globalDate,
    (record) => record.date,
  );

  /// Retorna la última evaluación de fuerza con fecha <= globalDate
  StrengthAssessment? latestStrengthAssessmentAtOrBefore(DateTime globalDate) =>
      _latestAtOrBefore(
        strengthAssessments,
        globalDate,
        (record) => record.date,
      );

  /// Retorna el último perfil de tolerancia al volumen con fecha <= globalDate
  /// Nota: VolumeToleranceProfile no tiene fecha; usar último del listado
  VolumeToleranceProfile? latestVolumeToleranceProfileAtOrBefore(
    DateTime globalDate,
  ) => volumeToleranceProfiles.isEmpty ? null : volumeToleranceProfiles.last;

  /// Retorna el último perfil de entrenamiento psicológico con fecha <= globalDate
  PsychologicalTrainingProfile? latestPsychologicalTrainingProfileAtOrBefore(
    DateTime globalDate,
  ) => _latestAtOrBefore(
    psychologicalTrainingProfiles,
    globalDate,
    (record) => record.date,
  );

  /// Retorna el último log de sesión con fecha <= globalDate
  SessionSummaryLog? latestSessionLogAtOrBefore(DateTime globalDate) =>
      _latestAtOrBefore(sessionLogs, globalDate, (record) => record.date);

  /// Retorna el último log de ejercicio con fecha <= globalDate
  ExerciseLogEntry? latestTrainingLogAtOrBefore(DateTime globalDate) =>
      _latestAtOrBefore(trainingLogs, globalDate, (record) => record.date);

  /// Retorna el último plan de entrenamiento con fecha <= globalDate
  TrainingPlanConfig? latestTrainingPlanAtOrBefore(DateTime globalDate) =>
      _latestAtOrBefore(
        trainingPlans,
        globalDate,
        (record) => record.startDate,
      );

  /// Retorna la última semana de entrenamiento con fecha <= globalDate
  /// Nota: TrainingWeek no tiene campo date; usar último del listado
  TrainingWeek? latestTrainingWeekAtOrBefore(DateTime globalDate) =>
      trainingWeeks.isEmpty ? null : trainingWeeks.last;

  double? get initialHeightCm {
    final resolver = LatestRecordResolver();
    final latest = resolver.latestAnthropometry(anthropometry);
    return latest?.heightCm;
  }

  double? get lastWeight {
    if (latestTrackingRecord?.weightKg != null) {
      return latestTrackingRecord!.weightKg;
    }
    if (latestAnthropometryRecord?.weightKg != null) {
      return latestAnthropometryRecord!.weightKg;
    }
    return null;
  }

  /// Acceso directo a las calorías base
  int? get kcal => nutrition.kcal;

  /// Acceso directo a la configuración semanal de macros
  Map<String, DailyMacroSettings>? get effectiveWeeklyMacros =>
      nutrition.weeklyMacroSettings;

  // ===========================================================================
  // COPYWITH
  // ===========================================================================
  Client copyWith({
    String? id,
    ClientProfile? profile,
    ClinicalHistory? history,
    TrainingProfile? training,
    NutritionSettings? nutrition,
    DateTime? createdAt,
    DateTime? updatedAt,
    ClientStatus? status,
    TrainingHistory? trainingHistory,
    NutritionHistory? nutritionHistory,
    List<AnthropometryRecord>? anthropometry,
    List<BioChemistryRecord>? biochemistry,
    List<DailyTrackingRecord>? tracking,
    List<TrainingPlanConfig>? trainingPlans,
    List<TrainingWeek>? trainingWeeks,
    List<TrainingSession>? trainingSessions,
    List<ExerciseLogEntry>? trainingLogs,
    List<SessionSummaryLog>? sessionLogs,
    List<TrainingCycle>? trainingCycles,
    String? activeCycleId,
    TrainingEvaluation? trainingEvaluation,
    Emi2Profile? exerciseMotivation,
    GluteSpecializationProfile? gluteSpecializationProfile,
    List<MobilityAssessment>? mobilityAssessments,
    List<MovementPatternAssessment>? movementPatternAssessments,
    List<StrengthAssessment>? strengthAssessments,
    List<VolumeToleranceProfile>? volumeToleranceProfiles,
    List<PsychologicalTrainingProfile>? psychologicalTrainingProfiles,
    int? paidWeeks,
    String? invitationCode,
  }) {
    return Client(
      id: id ?? this.id,
      profile: profile ?? this.profile,
      history: history ?? this.history,
      training: training ?? this.training,
      nutrition: nutrition ?? this.nutrition,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      trainingHistory: trainingHistory ?? this.trainingHistory,
      nutritionHistory: nutritionHistory ?? this.nutritionHistory,
      anthropometry: anthropometry ?? this.anthropometry,
      biochemistry: biochemistry ?? this.biochemistry,
      tracking: tracking ?? this.tracking,
      trainingPlans: trainingPlans ?? this.trainingPlans,
      trainingWeeks: trainingWeeks ?? this.trainingWeeks,
      trainingSessions: trainingSessions ?? this.trainingSessions,
      trainingLogs: trainingLogs ?? this.trainingLogs,
      sessionLogs: sessionLogs ?? this.sessionLogs,
      trainingCycles: trainingCycles ?? this.trainingCycles,
      activeCycleId: activeCycleId ?? this.activeCycleId,
      trainingEvaluation: trainingEvaluation ?? this.trainingEvaluation,
      exerciseMotivation: exerciseMotivation ?? this.exerciseMotivation,
      gluteSpecializationProfile:
          gluteSpecializationProfile ?? this.gluteSpecializationProfile,
      mobilityAssessments: mobilityAssessments ?? this.mobilityAssessments,
      movementPatternAssessments:
          movementPatternAssessments ?? this.movementPatternAssessments,
      strengthAssessments: strengthAssessments ?? this.strengthAssessments,
      volumeToleranceProfiles:
          volumeToleranceProfiles ?? this.volumeToleranceProfiles,
      psychologicalTrainingProfiles:
          psychologicalTrainingProfiles ?? this.psychologicalTrainingProfiles,
      paidWeeks: paidWeeks ?? this.paidWeeks,
      invitationCode: invitationCode ?? this.invitationCode,
    );
  }

  @override
  List<Object?> get props => [
    id,
    profile,
    history,
    training,
    nutrition,
    createdAt,
    updatedAt,
    status,
    trainingHistory,
    nutritionHistory,
    anthropometry,
    biochemistry,
    tracking,
    trainingPlans,
    trainingWeeks,
    trainingSessions,
    trainingLogs,
    sessionLogs,
    trainingCycles,
    activeCycleId,
    trainingEvaluation,
    exerciseMotivation,
    gluteSpecializationProfile,
    mobilityAssessments,
    movementPatternAssessments,
    strengthAssessments,
    volumeToleranceProfiles,
    psychologicalTrainingProfiles,
    paidWeeks,
  ];
}
