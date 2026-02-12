import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/core/constants/training_interview_keys.dart';
import 'package:hcs_app_lap/core/constants/training_interview_legacy_keys.dart';
import 'package:hcs_app_lap/core/enums/training_level.dart';
import 'package:hcs_app_lap/core/enums/training_discipline.dart';
import 'package:hcs_app_lap/core/enums/time_per_session_bucket.dart';
import 'package:hcs_app_lap/core/enums/rest_profile.dart';
import 'package:hcs_app_lap/core/enums/sleep_bucket.dart';
import 'package:hcs_app_lap/core/enums/stress_level.dart';
import 'package:hcs_app_lap/core/enums/injury_region.dart';
import 'package:hcs_app_lap/core/enums/training_interview_enums.dart';
import 'package:hcs_app_lap/core/enums/performance_trend.dart';
import 'package:hcs_app_lap/domain/training/models/supported_muscles.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/services/volume_individualization_service.dart';
import 'package:hcs_app_lap/domain/services/volume_by_muscle_derivation_service.dart';
import 'package:hcs_app_lap/domain/services/athlete_context_resolver.dart';
import 'package:hcs_app_lap/domain/services/training_history_derivation_service.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/features/training_feature/providers/training_plan_provider.dart';
import 'package:hcs_app_lap/features/training_feature/services/training_profile_form_mapper.dart';
import 'package:hcs_app_lap/utils/widgets/muscle_selection_widget.dart';
import 'package:hcs_app_lap/utils/widgets/enum_dropdown_widget.dart';
import 'package:hcs_app_lap/utils/widgets/shared_form_widgets.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/ui/clinic_section_surface.dart';

class TrainingInterviewTab extends ConsumerStatefulWidget {
  const TrainingInterviewTab({super.key});

  @override
  ConsumerState<TrainingInterviewTab> createState() =>
      TrainingInterviewTabState();
}

class TrainingInterviewTabState extends ConsumerState<TrainingInterviewTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Client? _client;
  bool _isDirty = false;
  bool _initialized = false;
  String? _loadedClientId;

  // Controladores (SOLO para PRs opcionales)
  late TextEditingController _prSquatCtrl;
  late TextEditingController _prBenchCtrl;
  late TextEditingController _prDeadliftCtrl;
  late TextEditingController _historicalFreqCtrl;
  int? _daysPerWeek;
  int? _planDurationInWeeks;

  // Controllers for critical numeric fields
  late TextEditingController _yearsTrainingCtrl;
  late TextEditingController _sessionDurationCtrl;
  late TextEditingController _restBetweenSetsCtrl;
  late TextEditingController _avgSleepHoursCtrl;

  // Controllers for weight/height (minimum required data)
  late TextEditingController _heightCmCtrl;
  late TextEditingController _weightKgCtrl;
  late TextEditingController _ageYearsCtrl;

  // CONTROLLERS V2 (2025) - MANDATORY FIELDS
  late TextEditingController _avgWeeklySetsPerMuscleCtrl;
  late TextEditingController _consecutiveWeeksTrainingCtrl;
  late TextEditingController _perceivedRecoveryStatusCtrl;
  late TextEditingController _averageRIRCtrl;
  late TextEditingController _averageSessionRPECtrl;

  // CONTROLLERS V2 - RECOMMENDED FIELDS (optional)
  late TextEditingController _maxWeeklySetsCtrl;
  late TextEditingController _deloadFrequencyCtrl;
  late TextEditingController _soreness48hCtrl;
  late TextEditingController _periodBreaksCtrl;

  // STATE V2 - ENUMS
  PerformanceTrend? _performanceTrend;

  // Variables de Estado - TODAS cerradas
  TrainingDiscipline? _discipline;
  int? _historicalFrequency; // dias reales ultimo mes
  int? _plannedFrequency; // compat: igual a daysPerWeek
  TimePerSessionBucket? _timePerSession;
  RestProfile? _restProfile;
  SleepBucket? _sleepBucket;
  StressLevel? _stressLevel;

  // Lesiones por region (checklist)
  Set<InjuryRegion> _activeInjuries = {};

  // Restricciones por hombro (detalle)
  bool _shoulderAvoidOverheadPress = false;
  bool _shoulderAvoidPainfulLateralRaise = false;
  bool _shoulderAvoidWideGripPress = false;
  bool _shoulderAvoidEndRangePain = false;

  // Prioridades musculares
  List<String> _primaryMuscles = [];
  List<String> _secondaryMuscles = [];
  List<String> _tertiaryMuscles = [];

  // Historia de entrenamiento (SSOT)
  bool? _hasTrainedBefore;
  int? _totalYearsTrainedBefore;
  bool? _hadLongPause;
  int? _longestPauseMonths;
  bool? _isTrainingNow;
  int? _monthsTrainingNow;

  bool _showValidationErrors = false;

  // PRs opcionales
  bool _knowsPRs = false;

  // ============ NUEVOS CAMPOS DE ENTREVISTA CLINICA ============
  // Estos se persisten usando TrainingInterviewKeys canonicas
  // Las variables numericas permiten override, pero derivan desde buckets por default

  int? _yearsTraining; // anos de entrenamiento continuo (override opcional)
  double? _avgSleepHours; // horas promedio de sueno (override opcional)
  int? _sessionDurationMinutes; // duracion tipica sesion (override opcional)
  int? _restBetweenSetsSeconds; // descanso entre series (override opcional)

  bool _volumeRelevantChanged(
    Map<String, dynamic> oldExtra,
    Map<String, dynamic> newExtra,
  ) {
    const keys = [
      'trainingYears',
      'monthsTrainingNow',
      'daysPerWeek',
      'sessionDurationMinutes',
      'restBetweenSetsSeconds',
      'avgSleepHours',
      'effectiveTrainingLevel',
      'priorityMusclesPrimary',
      'priorityMusclesSecondary',
      'priorityMusclesTertiary',
    ];

    for (final k in keys) {
      if (oldExtra[k] != newExtra[k]) return true;
    }
    return false;
  }

  int? _workCapacity; // escala 1-5
  int? _recoveryHistory; // escala 1-5
  bool _externalRecovery = false; // soporte externo
  ProgramNovelty? _programNovelty; // enum
  InterviewStressLevel? _physicalStress; // enum (estres fisico externo)
  DietQuality? _dietQuality; // enum

  String? _strengthLevelClass;
  int? _workCapacityScore;
  int? _recoveryHistoryScore;
  @override
  void initState() {
    super.initState();
    _initializeControllers();
    final client = ref.read(clientsProvider).value?.activeClient;
    if (client != null) {
      _client = client;
      _loadFromClient(client);
    }
  }

  void _initializeControllers() {
    _prSquatCtrl = TextEditingController();
    _prBenchCtrl = TextEditingController();
    _prDeadliftCtrl = TextEditingController();
    _historicalFreqCtrl = TextEditingController();
    _daysPerWeek = null;
    _planDurationInWeeks = null;

    // Inicializar controllers de campos criticos
    _yearsTrainingCtrl = TextEditingController();
    _sessionDurationCtrl = TextEditingController();
    _restBetweenSetsCtrl = TextEditingController();
    _avgSleepHoursCtrl = TextEditingController();

    // Inicializar controllers de peso y estatura
    _heightCmCtrl = TextEditingController();
    _weightKgCtrl = TextEditingController();
    _ageYearsCtrl = TextEditingController();

    // V2 Controllers (mandatory)
    _avgWeeklySetsPerMuscleCtrl = TextEditingController();
    _consecutiveWeeksTrainingCtrl = TextEditingController();
    _perceivedRecoveryStatusCtrl = TextEditingController();
    _averageRIRCtrl = TextEditingController();
    _averageSessionRPECtrl = TextEditingController();

    // V2 Controllers (recommended)
    _maxWeeklySetsCtrl = TextEditingController();
    _deloadFrequencyCtrl = TextEditingController();
    _soreness48hCtrl = TextEditingController();
    _periodBreaksCtrl = TextEditingController();
  }

  // Helper: lectura robusta con fallback keys
  double? _readNumExtra(Map<String, dynamic> extra, List<String> keys) {
    for (final k in keys) {
      final v = extra[k];
      if (v is num) return v.toDouble();
      if (v is String) {
        final parsed = double.tryParse(v.replaceAll(',', '.'));
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  void _loadFromClient(Client? client) {
    if (client == null) {
      // Limpiar todos los campos
      _discipline = null;
      _historicalFrequency = null;
      _plannedFrequency = null;
      _timePerSession = null;
      _restProfile = null;
      _sleepBucket = null;
      _stressLevel = null;
      _activeInjuries = {};
      _primaryMuscles = [];
      _secondaryMuscles = [];
      _tertiaryMuscles = [];
      _knowsPRs = false;
      _prSquatCtrl.clear();
      _prBenchCtrl.clear();
      _prDeadliftCtrl.clear();
      _historicalFreqCtrl.clear();
      _daysPerWeek = null;
      _planDurationInWeeks = null;

      // Limpiar nuevos campos
      _yearsTraining = null;
      _avgSleepHours = null;
      _sessionDurationMinutes = null;
      _restBetweenSetsSeconds = null;
      _workCapacity = null;
      _recoveryHistory = null;
      _externalRecovery = false;
      _programNovelty = null;
      _physicalStress = null;
      _dietQuality = null;
      _hasTrainedBefore = null;
      _totalYearsTrainedBefore = null;
      _hadLongPause = null;
      _longestPauseMonths = null;
      _isTrainingNow = null;
      _monthsTrainingNow = null;
      _shoulderAvoidOverheadPress = false;
      _shoulderAvoidPainfulLateralRaise = false;
      _shoulderAvoidWideGripPress = false;
      _shoulderAvoidEndRangePain = false;
      _strengthLevelClass = null;
      _workCapacityScore = null;
      _recoveryHistoryScore = null;

      // Limpiar controllers
      _yearsTrainingCtrl.clear();
      _sessionDurationCtrl.clear();
      _restBetweenSetsCtrl.clear();
      _avgSleepHoursCtrl.clear();
      _ageYearsCtrl.clear();

      // Limpiar controllers V2
      _avgWeeklySetsPerMuscleCtrl.clear();
      _consecutiveWeeksTrainingCtrl.clear();
      _perceivedRecoveryStatusCtrl.clear();
      _averageRIRCtrl.clear();
      _averageSessionRPECtrl.clear();
      _maxWeeklySetsCtrl.clear();
      _deloadFrequencyCtrl.clear();
      _soreness48hCtrl.clear();
      _periodBreaksCtrl.clear();
      _performanceTrend = null;
      _showValidationErrors = false;

      return;
    }

    final t = client.training;
    final extra = t.extra;

    // Cargar desde extra con parsers
    _discipline = parseTrainingDiscipline(
      extra[TrainingExtraKeys.discipline]?.toString(),
    );
    _historicalFrequency = extra[TrainingExtraKeys.historicalFrequency] as int?;
    _plannedFrequency = extra[TrainingExtraKeys.plannedFrequency] as int?;
    final daysPerWeekExtra = (extra[TrainingExtraKeys.daysPerWeek] as num?)
        ?.toInt();
    final planDurationExtra =
        (extra[TrainingExtraKeys.planDurationInWeeks] as num?)?.toInt();
    final setupV1Map =
        extra[TrainingExtraKeys.trainingSetupV1] as Map<String, dynamic>?;
    final setupDaysPerWeek = (setupV1Map?['daysPerWeek'] as num?)?.toInt();
    final setupPlanDuration = (setupV1Map?['planDurationInWeeks'] as num?)
        ?.toInt();
    final experienceMap =
        setupV1Map?['experience'] as Map<String, dynamic>? ?? {};

    _daysPerWeek = daysPerWeekExtra ?? setupDaysPerWeek ?? _plannedFrequency;
    _planDurationInWeeks = planDurationExtra ?? setupPlanDuration;
    _plannedFrequency = _daysPerWeek;

    final experienceTotalYears =
        (experienceMap['yearsTotalStrengthTraining'] as num?)?.toInt();
    final experienceLongestPause =
        (experienceMap['longestBreakMonthsLast5Years'] as num?)?.toInt();
    final experienceMonthsCurrent =
        (experienceMap['monthsContinuousCurrent'] as num?)?.toInt();

    final hasTrainedBeforeExtra = extra[TrainingInterviewKeys.hasTrainedBefore];
    _hasTrainedBefore = hasTrainedBeforeExtra is bool
        ? hasTrainedBeforeExtra
        : (experienceTotalYears != null ? experienceTotalYears > 0 : null);

    final hadLongPauseExtra = extra[TrainingInterviewKeys.hadLongPause];
    _hadLongPause = hadLongPauseExtra is bool
        ? hadLongPauseExtra
        : (experienceLongestPause != null ? experienceLongestPause > 0 : null);

    final isTrainingNowExtra = extra[TrainingInterviewKeys.isTrainingNow];
    _isTrainingNow = isTrainingNowExtra is bool
        ? isTrainingNowExtra
        : (experienceMonthsCurrent != null
              ? experienceMonthsCurrent > 0
              : null);

    _totalYearsTrainedBefore =
        _readNumExtra(extra, [
          TrainingInterviewKeys.totalYearsTrainedBefore,
        ])?.toInt() ??
        experienceTotalYears;
    _longestPauseMonths =
        _readNumExtra(extra, [
          TrainingInterviewKeys.longestPauseMonths,
        ])?.toInt() ??
        experienceLongestPause;
    _monthsTrainingNow =
        _readNumExtra(extra, [
          TrainingInterviewKeys.monthsTrainingNow,
        ])?.toInt() ??
        experienceMonthsCurrent;
    _timePerSession = parseTimePerSessionBucket(
      extra[TrainingExtraKeys.timePerSessionBucket]?.toString(),
    );
    _restProfile = parseRestProfile(
      extra[TrainingExtraKeys.restProfile]?.toString(),
    );
    _sleepBucket = parseSleepBucket(
      extra[TrainingExtraKeys.sleepBucket]?.toString(),
    );
    _stressLevel = parseStressLevel(
      extra[TrainingExtraKeys.stressLevel]?.toString(),
    );
    _strengthLevelClass =
        extra[TrainingExtraKeys.strengthLevelClass] as String?;
    _workCapacityScore = (extra[TrainingExtraKeys.workCapacityScore] as num?)
        ?.toInt();
    _recoveryHistoryScore =
        (extra[TrainingExtraKeys.recoveryHistoryScore] as num?)?.toInt();

    // Cargar lesiones
    final injuriesData = extra[TrainingExtraKeys.activeInjuries];
    if (injuriesData is List) {
      _activeInjuries = injuriesData
          .map((e) => parseInjuryRegion(e?.toString()))
          .whereType<InjuryRegion>()
          .toSet();
    } else {
      _activeInjuries = {};
    }

    final restrictionsDetail =
        extra['movementRestrictionsDetail'] as Map<String, dynamic>?;
    final shoulderRestrictions =
        restrictionsDetail?['shoulder'] as Map<String, dynamic>?;
    _shoulderAvoidOverheadPress =
        shoulderRestrictions?['avoidOverheadPress'] == true;
    _shoulderAvoidPainfulLateralRaise =
        shoulderRestrictions?['avoidPainfulLateralRaise'] == true;
    _shoulderAvoidWideGripPress =
        shoulderRestrictions?['avoidWideGripPress'] == true;
    _shoulderAvoidEndRangePain =
        shoulderRestrictions?['avoidEndRangePain'] == true;

    // Cargar prioridades musculares
    _primaryMuscles = _parseMuscleList(
      t.priorityMusclesPrimary.isNotEmpty
          ? t.priorityMusclesPrimary.join(',')
          : extra[TrainingExtraKeys.priorityMusclesPrimary]?.toString(),
    );
    _secondaryMuscles = _parseMuscleList(
      t.priorityMusclesSecondary.isNotEmpty
          ? t.priorityMusclesSecondary.join(',')
          : extra[TrainingExtraKeys.priorityMusclesSecondary]?.toString(),
    );
    _tertiaryMuscles = _parseMuscleList(
      t.priorityMusclesTertiary.isNotEmpty
          ? t.priorityMusclesTertiary.join(',')
          : extra[TrainingExtraKeys.priorityMusclesTertiary]?.toString(),
    );

    // Cargar PRs
    _knowsPRs = extra[TrainingExtraKeys.knowsPRs] as bool? ?? false;
    _prSquatCtrl.text = extra[TrainingExtraKeys.prSquat]?.toString() ?? '';
    _prBenchCtrl.text = extra[TrainingExtraKeys.prBench]?.toString() ?? '';
    _prDeadliftCtrl.text =
        extra[TrainingExtraKeys.prDeadlift]?.toString() ?? '';

    // Actualizar controladores de frecuencia
    _historicalFreqCtrl.text = _historicalFrequency?.toString() ?? '';

    // ============ CARGAR NUEVOS CAMPOS DE ENTREVISTA (con fallback keys) ============
    // ORDEN DE PRIORIDAD: TrainingExtraKeys -> TrainingInterviewKeys -> legacy strings
    final yearsRead =
        _readNumExtra(extra, [
          TrainingExtraKeys.trainingYears, // 1: clave canonica
          TrainingInterviewLegacyKeys.yearsTrainingContinuous, // 2: legacy
          'yearsTrainingContinuous', // 3: legacy string
          'trainingAgeYears', // 4: fallback muy antiguo
        ]) ??
        0;
    final sessionRead =
        _readNumExtra(extra, [
          TrainingExtraKeys.timePerSessionMinutes, // 1: canonica
          TrainingInterviewLegacyKeys.sessionDurationMinutes, // 2: legacy
          'sessionDurationMinutes', // 3: legacy
          'timePerSessionMinutes', // 4: fallback
        ]) ??
        0;
    final restRead =
        _readNumExtra(extra, [
          TrainingExtraKeys.restBetweenSetsSeconds, // 1: canonica
          TrainingInterviewLegacyKeys.restBetweenSetsSeconds, // 2: legacy
          'restBetweenSetsSeconds', // 3: legacy
        ]) ??
        0;
    final sleepRead =
        _readNumExtra(extra, [
          TrainingExtraKeys.avgSleepHours, // 1: canonica
          TrainingInterviewLegacyKeys.avgSleepHours, // 2: legacy
          'avgSleepHours', // 3: legacy
        ]) ??
        0;

    _yearsTraining = yearsRead > 0 ? yearsRead.toInt() : null;
    _avgSleepHours = sleepRead > 0 ? sleepRead : null;
    _sessionDurationMinutes = sessionRead > 0 ? sessionRead.toInt() : null;
    _restBetweenSetsSeconds = restRead > 0 ? restRead.toInt() : null;

    // CRITICAL FIX: Solo actualizar controllers si cambio el clientId
    // NO resetear en cada guardado del mismo cliente
    if (_loadedClientId != client.id) {
      _yearsTrainingCtrl.text = _yearsTraining?.toString() ?? '';
      _sessionDurationCtrl.text = _sessionDurationMinutes?.toString() ?? '';
      _restBetweenSetsCtrl.text = _restBetweenSetsSeconds?.toString() ?? '';
      _avgSleepHoursCtrl.text = _avgSleepHours?.toString() ?? '';

      // Cargar peso y estatura
      final heightCm =
          _readNumExtra(extra, [
            TrainingExtraKeys.heightCm,
            TrainingInterviewLegacyKeys.heightCm,
            'heightCm',
          ]) ??
          0;
      final weightKg =
          _readNumExtra(extra, [
            TrainingExtraKeys.weightKg,
            TrainingInterviewLegacyKeys.weightKg,
            'weightKg',
          ]) ??
          0;
      final ageYears = _readNumExtra(extra, [TrainingExtraKeys.ageYears]) ?? 0;

      _heightCmCtrl.text = heightCm > 0 ? heightCm.toString() : '';
      _weightKgCtrl.text = weightKg > 0 ? weightKg.toString() : '';
      _ageYearsCtrl.text = ageYears > 0 ? ageYears.toString() : '';
    }

    // LOG TEMPORAL: Verificar que se cargaron correctamente
    debugPrint(
      'UI load years=${_yearsTrainingCtrl.text} session=${_sessionDurationCtrl.text} rest=${_restBetweenSetsCtrl.text} sleep=${_avgSleepHoursCtrl.text}',
    );
    debugPrint('UI reads extra keys present: ${extra.keys.toList()}');

    _workCapacity = extra[TrainingInterviewLegacyKeys.workCapacity] as int?;
    _recoveryHistory =
        extra[TrainingInterviewLegacyKeys.recoveryHistory] as int?;
    _externalRecovery =
        extra[TrainingInterviewLegacyKeys.externalRecovery] as bool? ?? false;

    // Cargar enums
    if (extra[TrainingInterviewLegacyKeys.programNovelty] is String) {
      try {
        _programNovelty = ProgramNovelty.values.byName(
          extra[TrainingInterviewLegacyKeys.programNovelty].toString(),
        );
      } catch (_) {
        _programNovelty = null;
      }
    }

    if (extra[TrainingInterviewLegacyKeys.physicalStress] is String) {
      try {
        _physicalStress = InterviewStressLevel.values.byName(
          extra[TrainingInterviewLegacyKeys.physicalStress].toString(),
        );
      } catch (_) {
        _physicalStress = null;
      }
    }

    if (extra[TrainingInterviewLegacyKeys.dietQuality] is String) {
      try {
        _dietQuality = DietQuality.values.byName(
          extra[TrainingInterviewLegacyKeys.dietQuality].toString(),
        );
      } catch (_) {
        _dietQuality = null;
      }
    }

    // CARGAR CAMPOS V2 (2025)

    // Mandatory V2
    _avgWeeklySetsPerMuscleCtrl.text =
        (extra[TrainingInterviewLegacyKeys.avgWeeklySetsPerMuscle] ?? 12)
            .toString();

    _consecutiveWeeksTrainingCtrl.text =
        (extra[TrainingInterviewLegacyKeys.consecutiveWeeksTraining] ?? 4)
            .toString();

    _perceivedRecoveryStatusCtrl.text =
        (extra[TrainingInterviewLegacyKeys.perceivedRecoveryStatus] ?? 7)
            .toString();

    _averageRIRCtrl.text =
        (extra[TrainingInterviewLegacyKeys.averageRIR] ?? 2.0).toString();

    _averageSessionRPECtrl.text =
        (extra[TrainingInterviewLegacyKeys.averageSessionRPE] ?? 7).toString();

    // Recommended V2 (opcionales)
    final maxSets =
        extra[TrainingInterviewLegacyKeys.maxWeeklySetsBeforeOverreaching];
    _maxWeeklySetsCtrl.text = maxSets != null ? maxSets.toString() : '';

    final deloadFreq = extra[TrainingInterviewLegacyKeys.deloadFrequencyWeeks];
    _deloadFrequencyCtrl.text = deloadFreq != null ? deloadFreq.toString() : '';

    final soreness = extra[TrainingInterviewLegacyKeys.soreness48hAverage];
    _soreness48hCtrl.text = soreness != null ? soreness.toString() : '';

    final breaks = extra[TrainingInterviewLegacyKeys.periodBreaksLast12Months];
    _periodBreaksCtrl.text = breaks != null ? breaks.toString() : '';

    // Performance Trend
    _performanceTrend = null;
    if (extra[TrainingInterviewLegacyKeys.performanceTrend] != null) {
      _performanceTrend = performanceTrendFromString(
        extra[TrainingInterviewLegacyKeys.performanceTrend].toString(),
      );
    }

    _showValidationErrors = false;
    _isDirty = false;
  }

  List<String> _parseMuscleList(String? value) {
    if (value == null || value.trim().isEmpty) return [];
    return value
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  Future<Client?> saveIfDirty() async {
    if (!_isDirty || _client == null) return null;
    final updatedClient = _buildUpdatedClient();
    _isDirty = false;
    // Devolver explicitamente el cliente actualizado para que se persista
    return updatedClient;
  }

  Future<void> commit() async {
    await _onSavePressed();
  }

  void resetDrafts() {
    final client = ref.read(clientsProvider).value?.activeClient ?? _client;
    if (client == null) return;
    _client = client;
    _loadFromClient(client);
    if (mounted) {
      setState(() {});
    }
  }

  int? _parseIntFromText(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return null;
    return int.tryParse(cleaned);
  }

  // ============ FUNCIONES HELPER PARA DERIVAR VALORES NUMERICOS ============
  int? _deriveSessionDurationFromBucket(TimePerSessionBucket? bucket) {
    if (bucket == null) return null;
    // Usar averageMinutes del enum
    return bucket.averageMinutes;
  }

  int? _deriveRestBetweenSetsFromProfile(RestProfile? profile) {
    if (profile == null) return null;
    switch (profile) {
      case RestProfile.short:
        return 60;
      case RestProfile.moderate:
        return 120;
      case RestProfile.long:
        return 180;
      case RestProfile.veryLong:
        return 240;
    }
  }

  double? _deriveSleepHoursFromBucket(SleepBucket? bucket) {
    if (bucket == null) return null;
    // averageHours siempre existe en el enum, pero por seguridad usamos mapeo
    return _mapSleepBucketToHours(bucket);
  }

  double _mapSleepBucketToHours(SleepBucket bucket) {
    switch (bucket) {
      case SleepBucket.lessThan6:
        return 5.5;
      case SleepBucket.sixToSeven:
        return 6.5;
      case SleepBucket.sevenToEight:
        return 7.5;
      case SleepBucket.moreThanEight:
        return 8.5;
    }
  }
  // ============ FIN FUNCIONES HELPER ============

  Client _buildUpdatedClient() {
    final client = _client!;
    final extra = Map<String, dynamic>.from(client.training.extra);

    // Guardar todos los enums como nombres
    extra[TrainingExtraKeys.discipline] = _discipline?.name;
    extra[TrainingExtraKeys.historicalFrequency] = _historicalFrequency;
    extra[TrainingExtraKeys.daysPerWeek] = _daysPerWeek;
    extra[TrainingExtraKeys.planDurationInWeeks] = _planDurationInWeeks;
    extra[TrainingExtraKeys.plannedFrequency] = _daysPerWeek;
    extra[TrainingExtraKeys.timePerSessionBucket] = _timePerSession?.name;
    extra[TrainingExtraKeys.restProfile] = _restProfile?.name;
    extra[TrainingExtraKeys.sleepBucket] = _sleepBucket?.name;
    extra[TrainingExtraKeys.stressLevel] = _stressLevel?.name;
    extra[TrainingExtraKeys.activeInjuries] = _activeInjuries
        .map((e) => e.name)
        .toList();
    final existingRestrictionsDetail =
        extra['movementRestrictionsDetail'] as Map<String, dynamic>?;
    final movementRestrictionsDetail =
        Map<String, dynamic>.from(existingRestrictionsDetail ?? {})
          ..['shoulder'] = {
            'avoidOverheadPress': _shoulderAvoidOverheadPress,
            'avoidPainfulLateralRaise': _shoulderAvoidPainfulLateralRaise,
            'avoidWideGripPress': _shoulderAvoidWideGripPress,
            'avoidEndRangePain': _shoulderAvoidEndRangePain,
          };
    extra['movementRestrictionsDetail'] = movementRestrictionsDetail;
    extra[TrainingExtraKeys.knowsPRs] = _knowsPRs;
    extra[TrainingExtraKeys.prSquat] = _knowsPRs ? _prSquatCtrl.text : null;
    extra[TrainingExtraKeys.prBench] = _knowsPRs ? _prBenchCtrl.text : null;
    extra[TrainingExtraKeys.prDeadlift] = _knowsPRs
        ? _prDeadliftCtrl.text
        : null;

    // ============ MAPEO AUTOMATICO PARA VME/VMR ============
    // Mapear stressLevel -> nonPhysicalStressLevel2
    if (_stressLevel != null) {
      String nonPhysStress = 'P'; // default Promedio
      switch (_stressLevel) {
        case StressLevel.low:
          nonPhysStress = 'B'; // Bajo
          break;
        case StressLevel.moderate:
          nonPhysStress = 'P'; // Promedio
          break;
        case StressLevel.high:
          nonPhysStress = 'A'; // Alto
          break;
        default:
          nonPhysStress = 'P';
      }
      extra[TrainingExtraKeys.nonPhysicalStressLevel2] = nonPhysStress;
    }

    // Mapear sleepBucket -> restQuality2
    if (_sleepBucket != null) {
      String restQuality = 'P'; // default Promedio
      switch (_sleepBucket) {
        case SleepBucket.moreThanEight:
        case SleepBucket.sevenToEight:
          restQuality = 'A'; // Alta calidad (7-8+ horas)
          break;
        case SleepBucket.sixToSeven:
          restQuality = 'P'; // Promedio (6-7 horas)
          break;
        case SleepBucket.lessThan6:
          restQuality = 'B'; // Baja calidad (<6 horas)
          break;
        default:
          restQuality = 'P';
      }
      extra[TrainingExtraKeys.restQuality2] = restQuality;
    }

    // ============ PERSISTIR NUEVOS CAMPOS DE ENTREVISTA ============
    // Leer desde controllers (UI) en lugar de variables internas
    // Esto evita que se pierdan valores al guardar

    // Parsear valores desde controllers
    final yearsFromCtrl = _parseIntFromText(_yearsTrainingCtrl.text);
    final sessionFromCtrl = int.tryParse(_sessionDurationCtrl.text);
    final restFromCtrl = int.tryParse(_restBetweenSetsCtrl.text);
    final sleepFromCtrl = double.tryParse(
      _avgSleepHoursCtrl.text.replaceAll(',', '.'),
    );

    // Parsear peso y estatura desde controllers
    final heightCmFromCtrl = double.tryParse(
      _heightCmCtrl.text.replaceAll(',', '.'),
    );
    final weightKgFromCtrl = double.tryParse(
      _weightKgCtrl.text.replaceAll(',', '.'),
    );
    final ageYearsFromCtrl = _parseIntFromText(_ageYearsCtrl.text);

    // Actualizar variables internas desde controllers
    _yearsTraining = yearsFromCtrl;
    _sessionDurationMinutes = sessionFromCtrl;
    _restBetweenSetsSeconds = restFromCtrl;
    _avgSleepHours = sleepFromCtrl;

    // Calcular valores derivados (usar overrides numericos del usuario si existen)
    final derivedYears = _yearsTraining;
    final derivedSession =
        _sessionDurationMinutes ??
        _deriveSessionDurationFromBucket(_timePerSession);
    final derivedRest =
        _restBetweenSetsSeconds ??
        _deriveRestBetweenSetsFromProfile(_restProfile);
    final derivedSleep =
        _avgSleepHours ?? _deriveSleepHoursFromBucket(_sleepBucket);

    // GUARDAR EN TrainingExtraKeys (fuente de verdad)
    if (derivedYears != null) {
      extra[TrainingExtraKeys.trainingYears] = derivedYears;
    }
    if (derivedSession != null) {
      extra[TrainingExtraKeys.timePerSessionMinutes] = derivedSession;
    }
    if (derivedRest != null) {
      extra[TrainingExtraKeys.restBetweenSetsSeconds] = derivedRest;
    }
    if (derivedSleep != null) {
      extra[TrainingExtraKeys.avgSleepHours] = derivedSleep;
    }

    if (ageYearsFromCtrl != null && ageYearsFromCtrl > 0) {
      extra[TrainingExtraKeys.ageYears] = ageYearsFromCtrl;
    }

    if (_strengthLevelClass != null) {
      extra[TrainingExtraKeys.strengthLevelClass] = _strengthLevelClass;
    }
    if (_workCapacityScore != null) {
      extra[TrainingExtraKeys.workCapacityScore] = _workCapacityScore;
    }
    if (_recoveryHistoryScore != null) {
      extra[TrainingExtraKeys.recoveryHistoryScore] = _recoveryHistoryScore;
    }

    // GUARDAR PESO Y ESTATURA (datos minimos para entrenamiento)
    if (heightCmFromCtrl != null && heightCmFromCtrl > 0) {
      extra[TrainingExtraKeys.heightCm] = heightCmFromCtrl;
    }
    if (weightKgFromCtrl != null && weightKgFromCtrl > 0) {
      extra[TrainingExtraKeys.weightKg] = weightKgFromCtrl;
    }

    // Campos opcionales que se guardan si el usuario los edita directamente
    if (_workCapacity != null) {
      extra[TrainingInterviewLegacyKeys.workCapacity] = _workCapacity;
    }
    if (_recoveryHistory != null) {
      extra[TrainingInterviewLegacyKeys.recoveryHistory] = _recoveryHistory;
    }

    // IMPORTANTE: Guardar externalRecovery SIEMPRE (true o false), no solo cuando es true
    extra[TrainingInterviewLegacyKeys.externalRecovery] = _externalRecovery;

    if (_programNovelty != null) {
      extra[TrainingInterviewLegacyKeys.programNovelty] = _programNovelty!.name;
    }
    if (_physicalStress != null) {
      extra[TrainingInterviewLegacyKeys.physicalStress] = _physicalStress!.name;
    }
    if (_dietQuality != null) {
      extra[TrainingInterviewLegacyKeys.dietQuality] = _dietQuality!.name;
    }

    final hasTrainedBefore = _hasTrainedBefore ?? false;
    final isTrainingNow = _isTrainingNow ?? false;
    final totalYearsTrainedBefore = hasTrainedBefore
        ? (_totalYearsTrainedBefore ?? 0)
        : 0;
    final hadLongPause = hasTrainedBefore ? (_hadLongPause ?? false) : false;
    final longestPauseMonths = hadLongPause ? (_longestPauseMonths ?? 0) : null;
    final monthsTrainingNow = isTrainingNow ? (_monthsTrainingNow ?? 0) : 0;

    extra[TrainingInterviewKeys.hasTrainedBefore] = hasTrainedBefore;
    if (hasTrainedBefore) {
      extra[TrainingInterviewKeys.totalYearsTrainedBefore] =
          totalYearsTrainedBefore;
      extra[TrainingInterviewKeys.hadLongPause] = hadLongPause;
      if (longestPauseMonths != null) {
        extra[TrainingInterviewKeys.longestPauseMonths] = longestPauseMonths;
      } else {
        extra.remove(TrainingInterviewKeys.longestPauseMonths);
      }
    } else {
      extra
        ..remove(TrainingInterviewKeys.totalYearsTrainedBefore)
        ..remove(TrainingInterviewKeys.hadLongPause)
        ..remove(TrainingInterviewKeys.longestPauseMonths);
    }

    extra[TrainingInterviewKeys.isTrainingNow] = isTrainingNow;
    if (isTrainingNow) {
      extra[TrainingInterviewKeys.monthsTrainingNow] = monthsTrainingNow;
    } else {
      extra.remove(TrainingInterviewKeys.monthsTrainingNow);
    }

    final effectiveState = TrainingHistoryDerivationService.deriveState(
      hasTrainedBefore: hasTrainedBefore,
      isTrainingNow: isTrainingNow,
      monthsTrainingNow: monthsTrainingNow,
    );
    final effectiveLevel = TrainingHistoryDerivationService.deriveTrainingLevel(
      state: effectiveState,
      totalYearsTrainedBefore: totalYearsTrainedBefore,
    );
    extra[TrainingExtraKeys.effectiveTrainingState] = effectiveState.name;
    extra[TrainingExtraKeys.effectiveTrainingLevel] = effectiveLevel.name;
    extra[TrainingExtraKeys.isReconditioningPhase] =
        TrainingHistoryDerivationService.isReconditioningPhase(effectiveState);
    extra[TrainingExtraKeys.volumeToleranceModifier] =
        TrainingHistoryDerivationService.volumeToleranceModifier(
          effectiveState,
        );
    extra[TrainingExtraKeys.legacyTrainingLevel] = effectiveLevel.name;

    // Defaults conservadores para campos que aun no se capturan en UI
    // SOLO si no existen ya (para no sobrescribir datos previos)
    if (!extra.containsKey(TrainingExtraKeys.strengthLevelClass)) {
      extra[TrainingExtraKeys.strengthLevelClass] = 'M'; // Medio (neutral)
    }
    if (!extra.containsKey(TrainingExtraKeys.workCapacityScore)) {
      extra[TrainingExtraKeys.workCapacityScore] = 3; // Medio (neutral)
    }
    if (!extra.containsKey(TrainingExtraKeys.recoveryHistoryScore)) {
      extra[TrainingExtraKeys.recoveryHistoryScore] = 3; // Promedio (neutral)
    }
    if (!extra.containsKey(TrainingExtraKeys.externalRecoverySupport)) {
      extra[TrainingExtraKeys.externalRecoverySupport] =
          false; // Sin soporte externo (conservador)
    }
    if (!extra.containsKey(TrainingExtraKeys.programNoveltyClass)) {
      extra[TrainingExtraKeys.programNoveltyClass] =
          'I'; // Intermedio (neutral)
    }
    if (!extra.containsKey(TrainingExtraKeys.externalPhysicalStressLevel)) {
      extra[TrainingExtraKeys.externalPhysicalStressLevel] =
          'N'; // Normal (neutral)
    }
    if (!extra.containsKey(TrainingExtraKeys.dietHabitsClass)) {
      extra[TrainingExtraKeys.dietHabitsClass] = 'ISO'; // Isocalorico (neutral)
    }

    // IMPORTANTE: Preservar todos los campos que NO estamos editando en esta pestana
    // (heightCm, strengthLevelClass, workCapacityScore, recuperationHistoryScore,
    // externalRecoverySupport, programNoveltyClass, externalPhysicalStressLevel,
    // nonPhysicalStressLevel2, restQuality2, dietHabitsClass, y otros campos del extra)
    // No removemos ni sobrescribimos, solo actualizamos los que se editan aqui

    // Calcular dias por semana desde seleccion dura
    final daysPerWeek = _daysPerWeek ?? 0;
    final planDurationWeeks = _planDurationInWeeks ?? 8;

    final primaryMuscles = List<String>.from(_primaryMuscles);
    final secondaryMuscles = List<String>.from(_secondaryMuscles);
    final tertiaryMuscles = List<String>.from(_tertiaryMuscles);

    extra[TrainingExtraKeys.priorityMusclesPrimary] = primaryMuscles;
    extra[TrainingExtraKeys.priorityMusclesSecondary] = secondaryMuscles;
    extra[TrainingExtraKeys.priorityMusclesTertiary] = tertiaryMuscles;

    final updatedTraining = TrainingProfileFormMapper.apply(
      base: client.training,
      input: TrainingProfileFormInput(
        extra: extra,
        daysPerWeekLabel: daysPerWeek > 0 ? daysPerWeek.toString() : '',
        timePerSessionLabel: _timePerSession?.label,
        planDurationWeeks: planDurationWeeks,
        priorityMusclesPrimary: primaryMuscles,
        priorityMusclesSecondary: secondaryMuscles,
        priorityMusclesTertiary: tertiaryMuscles,
        avgSleepHours: derivedSleep,
        perceivedStress: _stressLevel?.label,
        recoveryQuality: client.training.recoveryQuality,
        usesAnabolics: false, // Campo eliminado
        isCompetitor: false, // Campo eliminado
        competitionCategory: null,
        competitionDateIso: null,
        prSquat: _knowsPRs ? _prSquatCtrl.text : null,
        prBench: _knowsPRs ? _prBenchCtrl.text : null,
        prDeadlift: _knowsPRs ? _prDeadliftCtrl.text : null,
      ),
    );

    final continuousYears = isTrainingNow ? (monthsTrainingNow ~/ 12) : 0;
    // Aplicar los 4 campos tipados con copyWith()
    final finalTraining = updatedTraining.copyWith(
      trainingLevel: effectiveLevel,
      yearsTrainingContinuous: continuousYears,
      sessionDurationMinutes: derivedSession ?? 0,
      restBetweenSetsSeconds: derivedRest ?? 0,
      avgSleepHours: derivedSleep ?? 0.0,
    );

    // GUARDAR CAMPOS V2 (2025) - MANDATORY

    extra[TrainingInterviewLegacyKeys.avgWeeklySetsPerMuscle] =
        int.tryParse(_avgWeeklySetsPerMuscleCtrl.text) ?? 12;

    extra[TrainingInterviewLegacyKeys.consecutiveWeeksTraining] =
        int.tryParse(_consecutiveWeeksTrainingCtrl.text) ?? 4;

    extra[TrainingInterviewLegacyKeys.perceivedRecoveryStatus] =
        int.tryParse(_perceivedRecoveryStatusCtrl.text) ?? 7;

    extra[TrainingInterviewLegacyKeys.averageRIR] =
        double.tryParse(_averageRIRCtrl.text) ?? 2.0;

    extra[TrainingInterviewLegacyKeys.averageSessionRPE] =
        int.tryParse(_averageSessionRPECtrl.text) ?? 7;

    // GUARDAR CAMPOS V2 - RECOMMENDED (solo si tienen valor)

    final maxSets = int.tryParse(_maxWeeklySetsCtrl.text);
    if (maxSets != null && maxSets > 0) {
      extra[TrainingInterviewLegacyKeys.maxWeeklySetsBeforeOverreaching] =
          maxSets;
    }

    final deloadFreq = int.tryParse(_deloadFrequencyCtrl.text);
    if (deloadFreq != null && deloadFreq > 0) {
      extra[TrainingInterviewLegacyKeys.deloadFrequencyWeeks] = deloadFreq;
    }

    final soreness = int.tryParse(_soreness48hCtrl.text);
    if (soreness != null && soreness > 0) {
      extra[TrainingInterviewLegacyKeys.soreness48hAverage] = soreness;
    }

    final breaks = int.tryParse(_periodBreaksCtrl.text);
    if (breaks != null && breaks >= 0) {
      extra[TrainingInterviewLegacyKeys.periodBreaksLast12Months] = breaks;
    }

    if (_performanceTrend != null) {
      extra[TrainingInterviewLegacyKeys.performanceTrend] =
          _performanceTrend!.name;
    }

    // PASO 3B: PERSISTIR SSOT ESTRUCTURADO (trainingSetupV1, trainingEvaluationSnapshotV1, trainingProgressionStateV1)

    // 1. Crear TrainingSetupV1 y persistir como Map
    final existingSetupV1Map =
        extra[TrainingExtraKeys.trainingSetupV1] as Map<String, dynamic>?;
    final resolvedSex =
        _client?.profile.gender?.name ??
        existingSetupV1Map?['sex']?.toString() ??
        'other';
    final trainingSetupV1Map =
        Map<String, dynamic>.from(existingSetupV1Map ?? {})..addAll({
          'heightCm': heightCmFromCtrl ?? 0.0,
          'weightKg': weightKgFromCtrl ?? 0.0,
          'ageYears': _client?.profile.age ?? 0,
          'sex': resolvedSex,
          'daysPerWeek': daysPerWeek,
          'planDurationInWeeks': planDurationWeeks,
          'timePerSessionMinutes': derivedSession ?? 0,
          'trainingExperienceTotalYearsLifetime': totalYearsTrainedBefore,
          'trainingExperienceYearsContinuous': continuousYears,
          'trainingExperienceDetrainingMonths': 0,
        });

    final existingExperience =
        trainingSetupV1Map['experience'] as Map<String, dynamic>?;
    final experienceMap = Map<String, dynamic>.from(existingExperience ?? {})
      ..addAll({
        'yearsTotalStrengthTraining': _totalYearsTrainedBefore,
        'yearsContinuousStrengthTraining': continuousYears,
        'longestBreakMonthsLast5Years': _longestPauseMonths,
        'monthsContinuousCurrent': _monthsTrainingNow,
      });
    trainingSetupV1Map['experience'] = experienceMap;
    extra[TrainingExtraKeys.trainingSetupV1] = trainingSetupV1Map;

    // 2. Crear TrainingEvaluationSnapshotV1 y persistir como Map
    final now = DateTime.now();

    // E2 GOBERNANZA: Determinar politica de regeneracion segun historial
    final existingSnapshotMap =
        extra[TrainingExtraKeys.trainingEvaluationSnapshotV1] as Map?;
    final existingProgressionMap =
        extra[TrainingExtraKeys.trainingProgressionStateV1] as Map?;
    final weeksCompleted =
        (existingProgressionMap?['weeksCompleted'] as num?)?.toInt() ?? 0;

    // Politica de regeneracion:
    // - 'allow' si weeksCompleted == 0 (sin historial, permitir regenerar)
    // - 'adapt_only' si weeksCompleted > 0 (con historial, solo adaptar)
    final regenerationPolicy = weeksCompleted == 0 ? 'allow' : 'adapt_only';

    final trainingEvaluationSnapshotV1Map = {
      'schemaVersion': 1,
      'createdAt': existingSnapshotMap?['createdAt'] ?? now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'daysPerWeek': daysPerWeek,
      'sessionDurationMinutes': derivedSession ?? 0,
      'planDurationInWeeks': planDurationWeeks,
      'primaryMuscles': primaryMuscles,
      'secondaryMuscles': secondaryMuscles,
      'tertiaryMuscles': tertiaryMuscles,
      'priorityVolumeSplit': existingSnapshotMap?['priorityVolumeSplit'] ?? {},
      'intensityDistribution':
          existingSnapshotMap?['intensityDistribution'] ?? {},
      'painRules': existingSnapshotMap?['painRules'] ?? [],
      'status': 'partial', // partial = datos basicos capturados
      // E2 GOBERNANZA: Campos de decision clinica
      'regenerationPolicy': regenerationPolicy,
      'weeksToCompetition': null,
      'profileArchetype': _deriveProfileArchetype(totalYearsTrainedBefore),
      'rampUpRequired': _deriveRampUpRequired(totalYearsTrainedBefore),
      'peakPhaseWindow': false,
    };
    extra[TrainingExtraKeys.trainingEvaluationSnapshotV1] =
        trainingEvaluationSnapshotV1Map;

    // 3. Crear TrainingProgressionStateV1 y persistir como Map
    // (inicialmente, se actualiza con datos reales durante el entrenamiento)
    final trainingProgressionStateV1Map = {
      'weeksCompleted': 0,
      'sessionsCompleted': 0,
      'consecutiveWeeksTraining': 0,
      'averageRIR': 2.0,
      'averageSessionRPE': 7,
      'perceivedRecovery': 7,
      'lastPlanId': '',
      'lastPlanChangeReason': 'initial_evaluation',
    };
    extra[TrainingExtraKeys.trainingProgressionStateV1] =
        trainingProgressionStateV1Map;

    // PASO 3B: Explicitamente persistir daysPerWeek en extra[] (para Motor V3)
    extra[TrainingExtraKeys.daysPerWeek] = daysPerWeek;
    extra[TrainingExtraKeys.planDurationInWeeks] = planDurationWeeks;

    return client.copyWith(training: finalTraining.copyWith(extra: extra));
  }

  Future<void> _onSavePressed() async {
    if (_client == null) return;

    final ageYears = _parseIntFromText(_ageYearsCtrl.text);
    final hasMissingRequired =
        _daysPerWeek == null ||
        _planDurationInWeeks == null ||
        ageYears == null ||
        ageYears <= 0 ||
        _strengthLevelClass == null ||
        _workCapacityScore == null ||
        _recoveryHistoryScore == null;
    final missingTrainingHistory =
        _hasTrainedBefore == null ||
        _isTrainingNow == null ||
        (_hasTrainedBefore == true && _totalYearsTrainedBefore == null) ||
        (_hasTrainedBefore == true && _hadLongPause == null) ||
        (_hasTrainedBefore == true &&
            _hadLongPause == true &&
            _longestPauseMonths == null) ||
        (_isTrainingNow == true && _monthsTrainingNow == null);
    if (hasMissingRequired || missingTrainingHistory) {
      setState(() => _showValidationErrors = true);
      return;
    }

    final previousExtra = Map<String, dynamic>.from(
      _client?.training.extra ?? {},
    );

    try {
      // ============ PASO 1: GUARDAR DATOS DE ENTREVISTA ============
      // Construir el TrainingProfile editado explicitamente
      // Esto persiste los 4 campos: trainingYears, sessionDurationMinutes, restBetweenSetsSeconds, avgSleepHours
      final editedProfile = _buildUpdatedClient().training;

      debugPrint('ANTES DE GUARDAR - training.extra contiene:');
      debugPrint(
        '   hasTrainedBefore: ${editedProfile.extra[TrainingInterviewKeys.hasTrainedBefore]}',
      );
      debugPrint(
        '   totalYearsTrainedBefore: ${editedProfile.extra[TrainingInterviewKeys.totalYearsTrainedBefore]}',
      );
      debugPrint(
        '   isTrainingNow: ${editedProfile.extra[TrainingInterviewKeys.isTrainingNow]}',
      );
      debugPrint(
        '   monthsTrainingNow: ${editedProfile.extra[TrainingInterviewKeys.monthsTrainingNow]}',
      );

      // ESPERAR a que se guarden los datos de entrevista
      await ref.read(clientsProvider.notifier).updateActiveClient((prev) {
        // PASO 1: Merge superficial para evitar costos altos en mapas grandes
        final mergedTrainingExtra = Map<String, dynamic>.from(
          prev.training.extra,
        )..addAll(editedProfile.extra);
        final mergedTraining = editedProfile.copyWith(
          extra: mergedTrainingExtra,
        );

        // VALIDACION: Confirmar merge
        debugPrint('DESPUES DE MERGE - training.extra contiene:');
        debugPrint(
          '   hasTrainedBefore: ${mergedTraining.extra[TrainingInterviewKeys.hasTrainedBefore]}',
        );
        debugPrint(
          '   totalYearsTrainedBefore: ${mergedTraining.extra[TrainingInterviewKeys.totalYearsTrainedBefore]}',
        );
        debugPrint(
          '   isTrainingNow: ${mergedTraining.extra[TrainingInterviewKeys.isTrainingNow]}',
        );
        debugPrint(
          '   monthsTrainingNow: ${mergedTraining.extra[TrainingInterviewKeys.monthsTrainingNow]}',
        );

        // PASO 2: Retornar el Client con el training actualizado
        return prev.copyWith(training: mergedTraining);
      });

      // Verificar que el widget sigue montado despues de la operacion async
      if (!mounted) return;

      unawaited(_postSaveRecomputeAndRegen(previousExtra));

      _isDirty = false;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil de entrenamiento guardado correctamente.'),
            backgroundColor: kPrimaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar entrevista: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _postSaveRecomputeAndRegen(
    Map<String, dynamic> previousExtra,
  ) async {
    try {
      // ============ PASO 2: CALCULAR Y GUARDAR MEV/MRV ============
      await ref.read(clientsProvider.notifier).updateActiveClient((prev) {
        const resolver = AthleteContextResolver();
        const volume = VolumeIndividualizationService();

        final athlete = resolver.resolve(prev);
        final level = prev.training.trainingLevel ?? TrainingLevel.intermediate;

        final bounds = volume.computeBounds(
          level: level,
          athlete: athlete,
          trainingExtra: prev.training.extra,
        );

        final volumeByMuscle = VolumeByMuscleDerivationService.derive(
          mevGlobal: bounds.mevIndividual,
          mrvGlobal: bounds.mrvIndividual,
          rawMuscleKeys: SupportedMuscles.keys,
        );
        final mevByMuscle = volumeByMuscle['mevByMuscle'] ?? {};
        final mrvByMuscle = volumeByMuscle['mrvByMuscle'] ?? {};

        final Map<String, double> targetSetsByMuscle = {};
        for (final key in mevByMuscle.keys) {
          final mevVal = mevByMuscle[key];
          final mrvVal = mrvByMuscle[key];

          if (mevVal != null && mrvVal != null) {
            final mev = mevVal.toDouble();
            final mrv = mrvVal.toDouble();
            final mid = ((mev + mrv) / 2.0).roundToDouble();
            targetSetsByMuscle[key] = mid;
          }
        }

        debugPrint(
          '[SAVE][COMPUTE] targetSetsByMuscle=${targetSetsByMuscle.length} mevByMuscle=${mevByMuscle.length} mrvByMuscle=${mrvByMuscle.length}',
        );

        final priorityVolumeSplit = <String, double>{
          'primary': 0.45,
          'secondary': 0.35,
          'tertiary': 0.20,
        };

        final rawPrimary = prev.training.extra['priorityMusclesPrimary'];
        final rawSecondary = prev.training.extra['priorityMusclesSecondary'];
        final rawTertiary = prev.training.extra['priorityMusclesTertiary'];

        final primaryMuscles = <String>{};
        final secondaryMuscles = <String>{};
        final tertiaryMuscles = <String>{};

        if (rawPrimary is List) {
          for (final m in rawPrimary) {
            if (m is String) primaryMuscles.add(m);
          }
        }
        if (rawSecondary is List) {
          for (final m in rawSecondary) {
            if (m is String) secondaryMuscles.add(m);
          }
        }
        if (rawTertiary is List) {
          for (final m in rawTertiary) {
            if (m is String) tertiaryMuscles.add(m);
          }
        }

        final Map<String, Map<String, double>> targetSetsByMusclePriority = {};

        for (final entry in targetSetsByMuscle.entries) {
          final muscle = entry.key;
          final total = entry.value;

          double p, s, t;

          if (primaryMuscles.contains(muscle)) {
            p = total * priorityVolumeSplit['primary']!;
            s = total * priorityVolumeSplit['secondary']!;
            t = total * priorityVolumeSplit['tertiary']!;
          } else if (secondaryMuscles.contains(muscle)) {
            p = total * 0.35;
            s = total * 0.40;
            t = total * 0.25;
          } else if (tertiaryMuscles.contains(muscle)) {
            p = total * 0.25;
            s = total * 0.35;
            t = total * 0.40;
          } else {
            p = total * 0.33;
            s = total * 0.34;
            t = total * 0.33;
          }

          targetSetsByMusclePriority[muscle] = {
            'primary': (p * 10).roundToDouble() / 10,
            'secondary': (s * 10).roundToDouble() / 10,
            'tertiary': (t * 10).roundToDouble() / 10,
          };
        }

        double heavyPct = 0.30;
        double mediumPct = 0.40;
        double lightPct = 0.30;

        final trainingLevel =
            prev.training.extra[TrainingExtraKeys.effectiveTrainingLevel] ??
            prev.training.extra[TrainingExtraKeys.legacyTrainingLevel];
        if (trainingLevel == 'beginner') {
          heavyPct = 0.25;
          lightPct = 0.35;
        } else if (trainingLevel == 'advanced') {
          heavyPct = 0.35;
          lightPct = 0.25;
        }

        mediumPct = 1.0 - heavyPct - lightPct;

        final intensityVolumeSplit = <String, double>{
          'heavy': heavyPct,
          'medium': mediumPct,
          'light': lightPct,
        };

        final Map<String, Map<String, Map<String, double>>>
        targetSetsByMusclePriorityIntensity = {};

        for (final muscleEntry in targetSetsByMusclePriority.entries) {
          final muscle = muscleEntry.key;
          final byPriority = muscleEntry.value;

          final Map<String, Map<String, double>> muscleOut = {};

          for (final priorityEntry in byPriority.entries) {
            final priority = priorityEntry.key;
            final total = priorityEntry.value;

            final heavy = (total * heavyPct * 10).roundToDouble() / 10;
            final medium = (total * mediumPct * 10).roundToDouble() / 10;
            final light = (total * lightPct * 10).roundToDouble() / 10;

            muscleOut[priority] = {
              'heavy': heavy,
              'medium': medium,
              'light': light,
            };
          }

          targetSetsByMusclePriorityIntensity[muscle] = muscleOut;
        }

        debugPrint(
          '[PHASE4] targetSetsByMusclePriority=${targetSetsByMusclePriority.length}',
        );
        debugPrint(
          '[PHASE5] targetSetsByMusclePriorityIntensity=${targetSetsByMusclePriorityIntensity.length}',
        );

        final updatedExtra = Map<String, dynamic>.from(prev.training.extra)
          ..['mevBase'] = bounds.mevBase
          ..['mrvBase'] = bounds.mrvBase
          ..['mevAdjustTotal'] = bounds.mevAdjustTotal
          ..['mrvAdjustTotal'] = bounds.mrvAdjustTotal
          ..['mevIndividual'] = bounds.mevIndividual
          ..['mrvIndividual'] = bounds.mrvIndividual
          ..['targetSetsByMuscle'] = targetSetsByMuscle
          ..['mevByMuscle'] = mevByMuscle
          ..['mrvByMuscle'] = mrvByMuscle
          ..['priorityVolumeSplit'] = priorityVolumeSplit
          ..['targetSetsByMusclePriority'] = targetSetsByMusclePriority
          ..['intensityVolumeSplit'] = intensityVolumeSplit
          ..['targetSetsByMusclePriorityIntensity'] =
              targetSetsByMusclePriorityIntensity;

        return prev.copyWith(
          training: prev.training.copyWith(extra: updatedExtra),
        );
      });

      if (!mounted) return;

      final updatedClient = ref.read(clientsProvider).value?.activeClient;
      if (updatedClient == null) return;

      final newExtra = updatedClient.training.extra;
      final needsRegenBase = _volumeRelevantChanged(previousExtra, newExtra);
      final mapsMissing =
          newExtra['mevByMuscle'] is! Map || newExtra['mrvByMuscle'] is! Map;
      final needsRegen = needsRegenBase || mapsMissing;

      if (needsRegen) {
        debugPrint('CAMBIO RELEVANTE DETECTADO - Regenerando plan...');
        try {
          await ref
              .read(trainingPlanProvider.notifier)
              .generatePlan(profile: updatedClient.training);
          debugPrint('Plan regenerado exitosamente');
        } catch (e) {
          debugPrint('Error al regenerar plan: $e');
        }
      }
    } catch (e) {
      debugPrint('Error en post-save MEV/MRV: $e');
    }
  }

  @override
  void dispose() {
    _prSquatCtrl.dispose();
    _prBenchCtrl.dispose();
    _prDeadliftCtrl.dispose();
    _historicalFreqCtrl.dispose();

    // Dispose de controllers de campos criticos
    _yearsTrainingCtrl.dispose();
    _sessionDurationCtrl.dispose();
    _restBetweenSetsCtrl.dispose();
    _avgSleepHoursCtrl.dispose();

    // Dispose de controllers de peso y estatura
    _heightCmCtrl.dispose();
    _weightKgCtrl.dispose();
    _ageYearsCtrl.dispose();

    // V2 Controllers
    _avgWeeklySetsPerMuscleCtrl.dispose();
    _consecutiveWeeksTrainingCtrl.dispose();
    _perceivedRecoveryStatusCtrl.dispose();
    _averageRIRCtrl.dispose();
    _averageSessionRPECtrl.dispose();
    _maxWeeklySetsCtrl.dispose();
    _deloadFrequencyCtrl.dispose();
    _soreness48hCtrl.dispose();
    _periodBreaksCtrl.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    ref.listen(clientsProvider, (previous, next) {
      final nextClient = next.value?.activeClient;
      if (nextClient == null) return;

      // CRITICAL FIX: Solo recargar si es DIFERENTE cliente
      // NO recargar al guardar el mismo cliente (evita reset de UI)
      final isDifferentClient = _loadedClientId != nextClient.id;
      if (!_initialized || isDifferentClient) {
        _client = nextClient;
        _loadFromClient(nextClient);
        _loadedClientId = nextClient.id;
        _initialized = true;
        setState(() {});
      } else {
        // Mismo cliente actualizado: solo actualizar referencia interna
        _client = nextClient;
      }
    });

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
        child: Column(
          children: [
            ClinicSectionSurface(
              icon: Icons.person,
              title: '1. Perfil de Entrenamiento',
              child: _buildTrainingProfile(),
            ),
            ClinicSectionSurface(
              icon: Icons.history,
              title: 'Historia de entrenamiento (dato duro)',
              child: _buildTrainingHistory(),
            ),
            ClinicSectionSurface(
              icon: Icons.schedule,
              title: '2. Disponibilidad y Capacidad',
              child: _buildAvailability(),
            ),
            ClinicSectionSurface(
              icon: Icons.fitness_center,
              title: '3. Tolerancias de Entrenamiento',
              child: _buildTolerances(),
            ),
            ClinicSectionSurface(
              icon: Icons.health_and_safety,
              title: '4. Factores de Recuperacion',
              child: _buildRecoveryFactors(),
            ),
            ClinicSectionSurface(
              icon: Icons.healing,
              title: '5. Lesiones Activas',
              child: _buildInjuries(),
            ),
            ClinicSectionSurface(
              icon: Icons.fact_check,
              title: 'Evaluacion rapida (obligatoria)',
              child: _buildQuickEvaluation(),
            ),
            ClinicSectionSurface(
              icon: Icons.accessibility_new,
              title: '6. Prioridades Musculares',
              child: _buildMuscles(),
            ),
            ClinicSectionSurface(
              icon: Icons.emoji_events,
              title: '7. PRs Opcionales (Fuerza)',
              child: _buildPRs(),
            ),
            const SizedBox(height: 32),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _onSavePressed,
                icon: const Icon(Icons.save),
                label: const Text('Guardar Evaluacion'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: kTextColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // 1. PERFIL DE ENTRENAMIENTO
  Widget _buildTrainingProfile() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        // DATOS MINIMOS PARA ENTRENAMIENTO (peso y estatura)
        SizedBox(
          width: 380,
          child: TextField(
            controller: _heightCmCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Estatura (cm) *',
              prefixIcon: Icon(Icons.height),
              helperText: 'Requerido para entrenamiento',
            ),
            onChanged: (_) => _markDirty(),
          ),
        ),
        SizedBox(
          width: 380,
          child: TextField(
            controller: _weightKgCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Peso (kg) *',
              prefixIcon: Icon(Icons.monitor_weight),
              helperText: 'Requerido para entrenamiento',
            ),
            onChanged: (_) => _markDirty(),
          ),
        ),
        SizedBox(
          width: 380,
          child: TextField(
            controller: _ageYearsCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Edad (anos) *',
              prefixIcon: const Icon(Icons.cake),
              errorText:
                  _showValidationErrors &&
                      _parseIntFromText(_ageYearsCtrl.text) == null
                  ? 'Requerido'
                  : null,
            ),
            onChanged: (_) => _markDirty(),
          ),
        ),
        SizedBox(
          width: 380,
          child: EnumGlassDropdown<TrainingDiscipline>(
            label: 'Disciplina principal de entrenamiento',
            value: _discipline,
            values: TrainingDiscipline.values,
            labelBuilder: (d) => d.label,
            onChanged: (v) {
              setState(() => _discipline = v);
              _markDirty();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildIntDropdown({
    required String label,
    required int? value,
    required List<int> options,
    String? helperText,
    String? errorText,
    required void Function(int?) onChanged,
  }) {
    final normalizedOptions =
        value == null || options.contains(value)
            ? options
            : ([...options, value]..sort());
    final safeValue = normalizedOptions.contains(value) ? value : null;
    return DropdownButtonFormField<int>(
      initialValue: safeValue,
      isExpanded: true,
      items: normalizedOptions
          .map(
            (v) => DropdownMenuItem<int>(value: v, child: Text(v.toString())),
          )
          .toList(),
      onChanged: onChanged,
      dropdownColor: kBackgroundColor,
      iconEnabledColor: kTextColor,
      style: const TextStyle(color: kTextColor),
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        errorText: errorText,
      ),
    );
  }

  Widget _buildBoolDropdown({
    required String label,
    required bool? value,
    String? helperText,
    String? errorText,
    required void Function(bool?) onChanged,
  }) {
    return DropdownButtonFormField<bool>(
      initialValue: value,
      isExpanded: true,
      items: const [
        DropdownMenuItem<bool>(value: true, child: Text('Si')),
        DropdownMenuItem<bool>(value: false, child: Text('No')),
      ],
      onChanged: onChanged,
      dropdownColor: kBackgroundColor,
      iconEnabledColor: kTextColor,
      style: const TextStyle(color: kTextColor),
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        errorText: errorText,
      ),
    );
  }

  Widget _buildTrainingHistory() {
    final yearOptions = List<int>.generate(21, (i) => i);
    final pauseOptions = [1, 2, 3, 4, 6, 9, 12, 18, 24, 36];
    final monthsCurrentOptions = [1, 2, 3, 4, 6, 9, 12, 18, 24, 36, 48, 60];

    final missingHasTrained =
        _showValidationErrors && _hasTrainedBefore == null;
    final missingTotalYears =
        _showValidationErrors &&
        _hasTrainedBefore == true &&
        _totalYearsTrainedBefore == null;
    final missingHadLongPause =
        _showValidationErrors &&
        _hasTrainedBefore == true &&
        _hadLongPause == null;
    final missingLongestPause =
        _showValidationErrors &&
        _hasTrainedBefore == true &&
        _hadLongPause == true &&
        _longestPauseMonths == null;
    final missingIsTrainingNow =
        _showValidationErrors && _isTrainingNow == null;
    final missingMonthsNow =
        _showValidationErrors &&
        _isTrainingNow == true &&
        _monthsTrainingNow == null;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        SizedBox(
          width: 360,
          child: _buildBoolDropdown(
            label: 'Has entrenado fuerza antes?',
            value: _hasTrainedBefore,
            errorText: missingHasTrained ? 'Requerido' : null,
            onChanged: (v) {
              setState(() {
                _hasTrainedBefore = v;
                if (v != true) {
                  _totalYearsTrainedBefore = null;
                  _hadLongPause = null;
                  _longestPauseMonths = null;
                }
              });
              _markDirty();
            },
          ),
        ),
        if (_hasTrainedBefore == true)
          SizedBox(
            width: 360,
            child: _buildIntDropdown(
              label: 'Cuanto tiempo entrenaste fuerza antes? (anos)',
              value: _totalYearsTrainedBefore,
              options: yearOptions,
              errorText: missingTotalYears ? 'Requerido' : null,
              onChanged: (v) {
                setState(() => _totalYearsTrainedBefore = v);
                _markDirty();
              },
            ),
          ),
        if (_hasTrainedBefore == true)
          SizedBox(
            width: 360,
            child: _buildBoolDropdown(
              label: 'Has hecho una pausa larga en tu entrenamiento?',
              value: _hadLongPause,
              errorText: missingHadLongPause ? 'Requerido' : null,
              onChanged: (v) {
                setState(() {
                  _hadLongPause = v;
                  if (v != true) {
                    _longestPauseMonths = null;
                  }
                });
                _markDirty();
              },
            ),
          ),
        if (_hadLongPause == true)
          SizedBox(
            width: 360,
            child: _buildIntDropdown(
              label: 'Cual fue la pausa mas larga? (meses)',
              value: _longestPauseMonths,
              options: pauseOptions,
              errorText: missingLongestPause ? 'Requerido' : null,
              onChanged: (v) {
                setState(() => _longestPauseMonths = v);
                _markDirty();
              },
            ),
          ),
        SizedBox(
          width: 360,
          child: _buildBoolDropdown(
            label: 'Estas entrenando fuerza actualmente?',
            value: _isTrainingNow,
            errorText: missingIsTrainingNow ? 'Requerido' : null,
            onChanged: (v) {
              setState(() {
                _isTrainingNow = v;
                if (v != true) {
                  _monthsTrainingNow = null;
                }
              });
              _markDirty();
            },
          ),
        ),
        if (_isTrainingNow == true)
          SizedBox(
            width: 360,
            child: _buildIntDropdown(
              label:
                  'Cuanto tiempo llevas entrenando de forma continua actualmente? (meses)',
              value: _monthsTrainingNow,
              options: monthsCurrentOptions,
              errorText: missingMonthsNow ? 'Requerido' : null,
              onChanged: (v) {
                setState(() => _monthsTrainingNow = v);
                _markDirty();
              },
            ),
          ),
      ],
    );
  }

  // 2. DISPONIBILIDAD Y CAPACIDAD
  Widget _buildAvailability() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        SizedBox(
          width: 250,
          child: GlassNumericField(
            controller: _historicalFreqCtrl,
            label: 'Dias entrenados REALMENTE el ultimo mes (1-31)',
            onChanged: (v) {
              _historicalFrequency = int.tryParse(v);
              _markDirty();
            },
          ),
        ),
        SizedBox(
          width: 320,
          child: _buildIntDropdown(
            label: 'Dias por semana (proximas 8 semanas)',
            value: _daysPerWeek,
            options: const [3, 4, 5, 6],
            helperText: 'Dato duro: selecciona el maximo realista sostenido.',
            errorText: _showValidationErrors && _daysPerWeek == null
                ? 'Selecciona un valor.'
                : null,
            onChanged: (v) {
              setState(() {
                _daysPerWeek = v;
                _plannedFrequency = v;
              });
              _markDirty();
            },
          ),
        ),
        SizedBox(
          width: 320,
          child: _buildIntDropdown(
            label: 'Duracion del plan (semanas)',
            value: _planDurationInWeeks,
            options: const [4, 6, 8, 12, 16],
            helperText:
                'Se usa para el ciclo actual y gobierno de regeneracion/adaptacion.',
            errorText: _showValidationErrors && _planDurationInWeeks == null
                ? 'Selecciona un valor.'
                : null,
            onChanged: (v) {
              setState(() => _planDurationInWeeks = v);
              _markDirty();
            },
          ),
        ),
        SizedBox(
          width: 380,
          child: EnumGlassDropdown<TimePerSessionBucket>(
            label: 'Tiempo disponible promedio por sesion *',
            value: _timePerSession,
            values: TimePerSessionBucket.values,
            labelBuilder: (t) => t.label,
            onChanged: (v) {
              setState(() => _timePerSession = v);
              _markDirty();
            },
          ),
        ),
      ],
    );
  }

  // 3. TOLERANCIAS
  Widget _buildTolerances() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        SizedBox(
          width: 380,
          child: EnumGlassDropdown<RestProfile>(
            label: 'Descansos tipicos entre series',
            value: _restProfile,
            values: RestProfile.values,
            labelBuilder: (r) => r.label,
            onChanged: (v) {
              setState(() => _restProfile = v);
              _markDirty();
            },
          ),
        ),
      ],
    );
  }

  // 4. FACTORES DE RECUPERACION
  Widget _buildRecoveryFactors() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        SizedBox(
          width: 250,
          child: EnumGlassDropdown<SleepBucket>(
            label: 'Horas promedio de sueno',
            value: _sleepBucket,
            values: SleepBucket.values,
            labelBuilder: (s) => s.label,
            onChanged: (v) {
              setState(() => _sleepBucket = v);
              _markDirty();
            },
          ),
        ),
        SizedBox(
          width: 250,
          child: EnumGlassDropdown<StressLevel>(
            label: 'Nivel de estres diario',
            value: _stressLevel,
            values: StressLevel.values,
            labelBuilder: (s) => s.label,
            onChanged: (v) {
              setState(() => _stressLevel = v);
              _markDirty();
            },
          ),
        ),
      ],
    );
  }

  // 5. LESIONES
  Widget _buildInjuries() {
    final hasShoulder = _activeInjuries.contains(InjuryRegion.shoulder);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: InjuryRegion.values.map((region) {
            final isSelected = _activeInjuries.contains(region);
            return FilterChip(
              label: Text(region.label),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _activeInjuries.add(region);
                  } else {
                    _activeInjuries.remove(region);
                  }
                });
                _markDirty();
              },
              selectedColor: kPrimaryColor.withValues(alpha: 0.3),
              checkmarkColor: kPrimaryColor,
              backgroundColor: kBackgroundColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
              ),
            );
          }).toList(),
        ),
        if (hasShoulder) ...[
          const SizedBox(height: 16),
          _buildShoulderRestrictions(),
        ],
      ],
    );
  }

  Widget _buildShoulderRestrictions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Restricciones por hombro (selecciona lo que aplica)',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: kPrimaryColor),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          value: _shoulderAvoidOverheadPress,
          onChanged: (v) {
            setState(() => _shoulderAvoidOverheadPress = v ?? false);
            _markDirty();
          },
          title: const Text(
            'Evitar empujes por encima de la cabeza (overhead press)',
          ),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          value: _shoulderAvoidPainfulLateralRaise,
          onChanged: (v) {
            setState(() => _shoulderAvoidPainfulLateralRaise = v ?? false);
            _markDirty();
          },
          title: const Text('Evitar elevaciones laterales dolorosas'),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          value: _shoulderAvoidWideGripPress,
          onChanged: (v) {
            setState(() => _shoulderAvoidWideGripPress = v ?? false);
            _markDirty();
          },
          title: const Text('Evitar press con agarre ancho'),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          value: _shoulderAvoidEndRangePain,
          onChanged: (v) {
            setState(() => _shoulderAvoidEndRangePain = v ?? false);
            _markDirty();
          },
          title: const Text('Evitar rangos finales por dolor'),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }

  Widget _buildQuickEvaluation() {
    final strengthError = _showValidationErrors && _strengthLevelClass == null;
    final workCapacityError =
        _showValidationErrors && _workCapacityScore == null;
    final recoveryHistoryError =
        _showValidationErrors && _recoveryHistoryScore == null;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        SizedBox(
          width: 380,
          child: DropdownButtonFormField<String>(
            initialValue: _strengthLevelClass,
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: 'B', child: Text('Principiante')),
              DropdownMenuItem(value: 'M', child: Text('Intermedio')),
              DropdownMenuItem(value: 'A', child: Text('Avanzado')),
              DropdownMenuItem(value: 'MA', child: Text('Muy avanzado')),
            ],
            onChanged: (v) {
              setState(() => _strengthLevelClass = v);
              _markDirty();
            },
            dropdownColor: kBackgroundColor,
            iconEnabledColor: kTextColor,
            style: const TextStyle(color: kTextColor),
            decoration: InputDecoration(
              labelText: 'Nivel de fuerza actual (estimacion del coach) *',
              errorText: strengthError ? 'Requerido' : null,
            ),
          ),
        ),
        SizedBox(
          width: 380,
          child: _buildIntDropdown(
            label: 'Capacidad de trabajo (1-5) *',
            value: _workCapacityScore,
            options: const [1, 2, 3, 4, 5],
            helperText:
                '1 = Me fatigo muy rapido, 3 = Promedio, 5 = Alta tolerancia al volumen',
            errorText: workCapacityError ? 'Requerido' : null,
            onChanged: (v) {
              setState(() => _workCapacityScore = v);
              _markDirty();
            },
          ),
        ),
        SizedBox(
          width: 380,
          child: _buildIntDropdown(
            label: 'Historial de recuperacion (1-5) *',
            value: _recoveryHistoryScore,
            options: const [1, 2, 3, 4, 5],
            helperText:
                '1 = Me cuesta recuperar, 3 = Promedio, 5 = Recupero muy bien',
            errorText: recoveryHistoryError ? 'Requerido' : null,
            onChanged: (v) {
              setState(() => _recoveryHistoryScore = v);
              _markDirty();
            },
          ),
        ),
      ],
    );
  }

  // 6. PRIORIDADES MUSCULARES
  Widget _buildMuscles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Seleccione los musculos por prioridad',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 12),
        MuscleSelectionGroup(
          selectedPrimary: _primaryMuscles.toSet(),
          selectedSecondary: _secondaryMuscles.toSet(),
          selectedTertiary: _tertiaryMuscles.toSet(),
          onChanged: (tier, newSet) {
            setState(() {
              switch (tier) {
                case 'primary':
                  _primaryMuscles = newSet.toList();
                  break;
                case 'secondary':
                  _secondaryMuscles = newSet.toList();
                  break;
                case 'tertiary':
                  _tertiaryMuscles = newSet.toList();
                  break;
              }
            });
            _markDirty();
          },
        ),
      ],
    );
  }

  // 7. PRS OPCIONALES
  Widget _buildPRs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: _knowsPRs,
              onChanged: (v) {
                setState(() => _knowsPRs = v ?? false);
                _markDirty();
              },
              activeColor: kPrimaryColor,
            ),
            const Text(
              'Conozco mis records personales (1RM)',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        if (_knowsPRs) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 200,
                child: GlassNumericField(
                  controller: _prSquatCtrl,
                  label: 'PR Sentadilla (kg)',
                  onChanged: (_) => _markDirty(),
                ),
              ),
              SizedBox(
                width: 200,
                child: GlassNumericField(
                  controller: _prBenchCtrl,
                  label: 'PR Banca (kg)',
                  onChanged: (_) => _markDirty(),
                ),
              ),
              SizedBox(
                width: 200,
                child: GlassNumericField(
                  controller: _prDeadliftCtrl,
                  label: 'PR Peso Muerto (kg)',
                  onChanged: (_) => _markDirty(),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Estado de volumen individualizado leido directamente desde training.extra.
  // REMOVIDO: No mostrar esta informacion en la UI
  /*
  Widget _buildVolumeStatus() {
    final client = ref.watch(clientsProvider).value?.activeClient;
    if (client == null) {
      return const SizedBox.shrink();
    }

    final extra = client.trainingProfile.extra;

    final double? mevIndividual = (extra['mevIndividual'] is num)
        ? (extra['mevIndividual'] as num).toDouble()
        : null;
    final double? mrvIndividual = (extra['mrvIndividual'] is num)
        ? (extra['mrvIndividual'] as num).toDouble()
        : null;

    final Map<String, dynamic> targetSetsByMuscle =
        (extra['targetSetsByMuscle'] is Map)
        ? Map<String, dynamic>.from(extra['targetSetsByMuscle'])
        : {};

    final bool hasIndividualizedVolume =
        mevIndividual != null ||
        mrvIndividual != null ||
        targetSetsByMuscle.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kAppBarColor.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPrimaryColor.withValues(alpha: 0.2)),
      ),
      child: hasIndividualizedVolume
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Volumen individualizado disponible (persistente)',
                  style: TextStyle(
                    color: kTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    if (mevIndividual != null)
                      Text(
                        'MEV: ${mevIndividual.toStringAsFixed(1)}',
                        style: const TextStyle(color: kTextColorSecondary),
                      ),
                    if (mrvIndividual != null)
                      Text(
                        'MRV: ${mrvIndividual.toStringAsFixed(1)}',
                        style: const TextStyle(color: kTextColorSecondary),
                      ),
                    if (targetSetsByMuscle.isNotEmpty)
                      Text(
                        'targetSetsByMuscle: ${targetSetsByMuscle.length} musculos',
                        style: const TextStyle(color: kTextColorSecondary),
                      ),
                  ],
                ),
              ],
            )
          : const Text(
              'No hay datos de volumen individualizado almacenados aun. Se mostraran aqui cuando esten disponibles.',
              style: TextStyle(color: kTextColorSecondary),
            ),
    );
  }
  */

  // E2 GOBERNANZA: Helpers para derivar campos clinicos

  /// Deriva el arquetipo de perfil segun anos de entrenamiento y desentrenamiento
  String? _deriveProfileArchetype(int? yearsTraining) {
    if (yearsTraining == null || yearsTraining == 0) {
      return 'beginner';
    }

    if (yearsTraining >= 5) {
      return 'advanced';
    } else if (yearsTraining >= 2) {
      return 'intermediate';
    } else {
      return 'beginner';
    }
  }

  /// Determina si se requiere rampa progresiva (ramp-up)
  bool _deriveRampUpRequired(int? yearsTraining) {
    // Requiere rampa si:
    // - Es principiante (< 1 ano)
    // - O es "returning_detrained" (anos altos + desentrenamiento)

    if (yearsTraining == null || yearsTraining < 1) {
      return true; // Principiante
    }

    return false; // Por defecto, no requiere rampa
  }
}

// ============================================================================
// WIDGETS AUXILIARES
// ============================================================================
// Los widgets Glass ahora estan en shared_form_widgets.dart
