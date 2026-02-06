import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/core/constants/training_interview_keys.dart';
import 'package:hcs_app_lap/core/enums/training_level.dart';
import 'package:hcs_app_lap/core/enums/training_discipline.dart';
import 'package:hcs_app_lap/core/enums/training_age_bucket.dart';
import 'package:hcs_app_lap/core/enums/time_per_session_bucket.dart';
import 'package:hcs_app_lap/core/enums/volume_tolerance.dart';
import 'package:hcs_app_lap/core/enums/intensity_tolerance.dart';
import 'package:hcs_app_lap/core/enums/rest_profile.dart';
import 'package:hcs_app_lap/core/enums/sleep_bucket.dart';
import 'package:hcs_app_lap/core/enums/stress_level.dart';
import 'package:hcs_app_lap/core/enums/recovery_quality.dart';
import 'package:hcs_app_lap/core/enums/injury_region.dart';
import 'package:hcs_app_lap/core/enums/training_interview_enums.dart';
import 'package:hcs_app_lap/core/enums/performance_trend.dart';
import 'package:hcs_app_lap/core/enums/muscle_group.dart';
import 'package:hcs_app_lap/domain/training/models/supported_muscles.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/services/volume_individualization_service.dart';
import 'package:hcs_app_lap/domain/services/volume_by_muscle_derivation_service.dart';
import 'package:hcs_app_lap/domain/services/athlete_context_resolver.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/features/training_feature/providers/training_plan_provider.dart';
import 'package:hcs_app_lap/features/training_feature/services/training_profile_form_mapper.dart';
import 'package:hcs_app_lap/utils/widgets/muscle_selection_widget.dart';
import 'package:hcs_app_lap/utils/widgets/enum_dropdown_widget.dart';
import 'package:hcs_app_lap/utils/widgets/shared_form_widgets.dart';
import 'package:hcs_app_lap/utils/widgets/hcs_input_decoration.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/ui/clinic_section_surface.dart';
import 'package:hcs_app_lap/utils/deep_merge.dart';

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
  late TextEditingController _plannedFreqCtrl;

  // ✅ Controllers para los 4 campos críticos (evita reset al guardar)
  late TextEditingController _yearsTrainingCtrl;
  late TextEditingController _sessionDurationCtrl;
  late TextEditingController _restBetweenSetsCtrl;
  late TextEditingController _avgSleepHoursCtrl;

  // ✅ Controllers para peso y estatura (datos mínimos)
  late TextEditingController _heightCmCtrl;
  late TextEditingController _weightKgCtrl;

  // ═══════════════════════════════════════════════════════════════
  // CONTROLLERS V2 (2025) - MANDATORY FIELDS
  // ═══════════════════════════════════════════════════════════════

  late TextEditingController _avgWeeklySetsPerMuscleCtrl;
  late TextEditingController _consecutiveWeeksTrainingCtrl;
  late TextEditingController _perceivedRecoveryStatusCtrl;
  late TextEditingController _averageRIRCtrl;
  late TextEditingController _averageSessionRPECtrl;

  // ═══════════════════════════════════════════════════════════════
  // CONTROLLERS V2 - RECOMMENDED FIELDS (opcionales)
  // ═══════════════════════════════════════════════════════════════

  late TextEditingController _maxWeeklySetsCtrl;
  late TextEditingController _deloadFrequencyCtrl;
  late TextEditingController _soreness48hCtrl;
  late TextEditingController _periodBreaksCtrl;

  // ═══════════════════════════════════════════════════════════════
  // STATE V2 - ENUMS
  // ═══════════════════════════════════════════════════════════════

  PerformanceTrend? _performanceTrend;

  // Variables de Estado - TODAS cerradas
  TrainingDiscipline? _discipline;
  TrainingLevel? _trainingLevel;
  TrainingAgeBucket? _trainingAge;
  int? _historicalFrequency; // días reales último mes
  int? _plannedFrequency; // días sostenibles próximos 2 meses
  TimePerSessionBucket? _timePerSession;
  VolumeTolerance? _volumeTolerance;
  IntensityTolerance? _intensityTolerance;
  RestProfile? _restProfile;
  SleepBucket? _sleepBucket;
  StressLevel? _stressLevel;
  RecoveryQuality? _recoveryQuality;

  // Lesiones por región (checklist)
  Set<InjuryRegion> _activeInjuries = {};

  // Prioridades musculares
  List<String> _primaryMuscles = [];
  List<String> _secondaryMuscles = [];
  List<String> _tertiaryMuscles = [];

  // PRs opcionales
  bool _knowsPRs = false;

  // ============ NUEVOS CAMPOS DE ENTREVISTA CLÍNICA ============
  // Estos se persisten usando TrainingInterviewKeys canónicas
  // Las variables numéricas permiten override, pero derivan desde buckets por default

  int? _yearsTraining; // años de entrenamiento continuo (override opcional)
  double? _avgSleepHours; // horas promedio de sueño (override opcional)
  int? _sessionDurationMinutes; // duración típica sesión (override opcional)
  int? _restBetweenSetsSeconds; // descanso entre series (override opcional)

  bool _volumeRelevantChanged(
    Map<String, dynamic> oldExtra,
    Map<String, dynamic> newExtra,
  ) {
    const keys = [
      'trainingYears',
      'yearsTrainingContinuous',
      'daysPerWeek',
      'sessionDurationMinutes',
      'restBetweenSetsSeconds',
      'avgSleepHours',
      'volumeTolerance',
      'intensityTolerance',
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
  InterviewStressLevel? _physicalStress; // enum (estrés físico externo)
  DietQuality? _dietQuality; // enum
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
    _plannedFreqCtrl = TextEditingController();

    // ✅ Inicializar controllers de campos críticos
    _yearsTrainingCtrl = TextEditingController();
    _sessionDurationCtrl = TextEditingController();
    _restBetweenSetsCtrl = TextEditingController();
    _avgSleepHoursCtrl = TextEditingController();

    // ✅ Inicializar controllers de peso y estatura
    _heightCmCtrl = TextEditingController();
    _weightKgCtrl = TextEditingController();

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

  // ✅ Helper: lectura robusta con fallback keys
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
      _trainingLevel = null;
      _trainingAge = null;
      _historicalFrequency = null;
      _plannedFrequency = null;
      _timePerSession = null;
      _volumeTolerance = null;
      _intensityTolerance = null;
      _restProfile = null;
      _sleepBucket = null;
      _stressLevel = null;
      _recoveryQuality = null;
      _activeInjuries = {};
      _primaryMuscles = [];
      _secondaryMuscles = [];
      _tertiaryMuscles = [];
      _knowsPRs = false;
      _prSquatCtrl.clear();
      _prBenchCtrl.clear();
      _prDeadliftCtrl.clear();
      _historicalFreqCtrl.clear();
      _plannedFreqCtrl.clear();

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

      // ✅ Limpiar controllers
      _yearsTrainingCtrl.clear();
      _sessionDurationCtrl.clear();
      _restBetweenSetsCtrl.clear();
      _avgSleepHoursCtrl.clear();

      // ✅ Limpiar controllers V2
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

      return;
    }

    final t = client.training;
    final extra = t.extra;

    // Cargar desde extra con parsers
    _discipline = parseTrainingDiscipline(
      extra[TrainingExtraKeys.discipline]?.toString(),
    );
    _trainingLevel =
        t.trainingLevel ??
        parseTrainingLevel(extra[TrainingExtraKeys.trainingLevel]?.toString());
    _trainingAge = parseTrainingAgeBucket(
      extra[TrainingExtraKeys.trainingAge]?.toString(),
    );
    _historicalFrequency = extra[TrainingExtraKeys.historicalFrequency] as int?;
    _plannedFrequency = extra[TrainingExtraKeys.plannedFrequency] as int?;
    _timePerSession = parseTimePerSessionBucket(
      extra[TrainingExtraKeys.timePerSessionBucket]?.toString(),
    );
    _volumeTolerance = parseVolumeTolerance(
      extra[TrainingExtraKeys.volumeTolerance]?.toString(),
    );
    _intensityTolerance = parseIntensityTolerance(
      extra[TrainingExtraKeys.intensityTolerance]?.toString(),
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
    _recoveryQuality = parseRecoveryQuality(
      extra[TrainingExtraKeys.recoveryQuality]?.toString(),
    );

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
    _plannedFreqCtrl.text = _plannedFrequency?.toString() ?? '';

    // ============ CARGAR NUEVOS CAMPOS DE ENTREVISTA (con fallback keys) ============
    // ✅ ORDEN DE PRIORIDAD: TrainingExtraKeys → TrainingInterviewKeys → legacy strings
    final yearsRead =
        _readNumExtra(extra, [
          TrainingExtraKeys.trainingYears, // 1º: clave canónica
          TrainingInterviewKeys.yearsTrainingContinuous, // 2º: interview key
          'yearsTrainingContinuous', // 3º: legacy string
          'trainingAgeYears', // 4º: fallback muy antiguo
        ]) ??
        0;
    final sessionRead =
        _readNumExtra(extra, [
          TrainingExtraKeys.timePerSessionMinutes, // 1º: canónica
          TrainingInterviewKeys.sessionDurationMinutes, // 2º: interview
          'sessionDurationMinutes', // 3º: legacy
          'timePerSessionMinutes', // 4º: fallback
        ]) ??
        0;
    final restRead =
        _readNumExtra(extra, [
          TrainingExtraKeys.restBetweenSetsSeconds, // 1º: canónica
          TrainingInterviewKeys.restBetweenSetsSeconds, // 2º: interview
          'restBetweenSetsSeconds', // 3º: legacy
        ]) ??
        0;
    final sleepRead =
        _readNumExtra(extra, [
          TrainingExtraKeys.avgSleepHours, // 1º: canónica
          TrainingInterviewKeys.avgSleepHours, // 2º: interview
          'avgSleepHours', // 3º: legacy
        ]) ??
        0;

    _yearsTraining = yearsRead > 0 ? yearsRead.toInt() : null;
    _avgSleepHours = sleepRead > 0 ? sleepRead : null;
    _sessionDurationMinutes = sessionRead > 0 ? sessionRead.toInt() : null;
    _restBetweenSetsSeconds = restRead > 0 ? restRead.toInt() : null;

    // ✅ CRITICAL FIX: Solo actualizar controllers si cambió el clientId
    // NO resetear en cada guardado del mismo cliente
    if (_loadedClientId != client.id) {
      _yearsTrainingCtrl.text = _yearsTraining?.toString() ?? '';
      _sessionDurationCtrl.text = _sessionDurationMinutes?.toString() ?? '';
      _restBetweenSetsCtrl.text = _restBetweenSetsSeconds?.toString() ?? '';
      _avgSleepHoursCtrl.text = _avgSleepHours?.toString() ?? '';

      // ✅ Cargar peso y estatura
      final heightCm =
          _readNumExtra(extra, [
            TrainingExtraKeys.heightCm,
            TrainingInterviewKeys.heightCm,
            'heightCm',
          ]) ??
          0;
      final weightKg =
          _readNumExtra(extra, [
            TrainingExtraKeys.weightKg,
            TrainingInterviewKeys.weightKg,
            'weightKg',
          ]) ??
          0;

      _heightCmCtrl.text = heightCm > 0 ? heightCm.toString() : '';
      _weightKgCtrl.text = weightKg > 0 ? weightKg.toString() : '';
    }

    // 🔍 LOG TEMPORAL: Verificar que se cargaron correctamente
    debugPrint(
      'UI load years=${_yearsTrainingCtrl.text} session=${_sessionDurationCtrl.text} rest=${_restBetweenSetsCtrl.text} sleep=${_avgSleepHoursCtrl.text}',
    );
    debugPrint('UI reads extra keys present: ${extra.keys.toList()}');

    _workCapacity = extra[TrainingInterviewKeys.workCapacity] as int?;
    _recoveryHistory = extra[TrainingInterviewKeys.recoveryHistory] as int?;
    _externalRecovery =
        extra[TrainingInterviewKeys.externalRecovery] as bool? ?? false;

    // Cargar enums
    if (extra[TrainingInterviewKeys.programNovelty] is String) {
      try {
        _programNovelty = ProgramNovelty.values.byName(
          extra[TrainingInterviewKeys.programNovelty].toString(),
        );
      } catch (_) {
        _programNovelty = null;
      }
    }

    if (extra[TrainingInterviewKeys.physicalStress] is String) {
      try {
        _physicalStress = InterviewStressLevel.values.byName(
          extra[TrainingInterviewKeys.physicalStress].toString(),
        );
      } catch (_) {
        _physicalStress = null;
      }
    }

    if (extra[TrainingInterviewKeys.dietQuality] is String) {
      try {
        _dietQuality = DietQuality.values.byName(
          extra[TrainingInterviewKeys.dietQuality].toString(),
        );
      } catch (_) {
        _dietQuality = null;
      }
    }

    // ════════════════════════════════════════════════════════════════
    // CARGAR CAMPOS V2 (2025)
    // ═══════════════════════════════════════════════════════════════

    // Mandatory V2
    _avgWeeklySetsPerMuscleCtrl.text =
        (extra[TrainingInterviewKeys.avgWeeklySetsPerMuscle] ?? 12).toString();

    _consecutiveWeeksTrainingCtrl.text =
        (extra[TrainingInterviewKeys.consecutiveWeeksTraining] ?? 4).toString();

    _perceivedRecoveryStatusCtrl.text =
        (extra[TrainingInterviewKeys.perceivedRecoveryStatus] ?? 7).toString();

    _averageRIRCtrl.text = (extra[TrainingInterviewKeys.averageRIR] ?? 2.0)
        .toString();

    _averageSessionRPECtrl.text =
        (extra[TrainingInterviewKeys.averageSessionRPE] ?? 7).toString();

    // Recommended V2 (opcionales)
    final maxSets =
        extra[TrainingInterviewKeys.maxWeeklySetsBeforeOverreaching];
    _maxWeeklySetsCtrl.text = maxSets != null ? maxSets.toString() : '';

    final deloadFreq = extra[TrainingInterviewKeys.deloadFrequencyWeeks];
    _deloadFrequencyCtrl.text = deloadFreq != null ? deloadFreq.toString() : '';

    final soreness = extra[TrainingInterviewKeys.soreness48hAverage];
    _soreness48hCtrl.text = soreness != null ? soreness.toString() : '';

    final breaks = extra[TrainingInterviewKeys.periodBreaksLast12Months];
    _periodBreaksCtrl.text = breaks != null ? breaks.toString() : '';

    // Performance Trend
    _performanceTrend = null;
    if (extra[TrainingInterviewKeys.performanceTrend] != null) {
      _performanceTrend = performanceTrendFromString(
        extra[TrainingInterviewKeys.performanceTrend].toString(),
      );
    }

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
    // Devolver explícitamente el cliente actualizado para que se persista
    return updatedClient;
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

  // ============ FUNCIONES HELPER PARA DERIVAR VALORES NUMÉRICOS ============
  int? _deriveYearsTrainingFromBucket(TrainingAgeBucket? bucket) {
    if (bucket == null) return null;
    switch (bucket) {
      case TrainingAgeBucket.lessThanOne:
        return 1;
      case TrainingAgeBucket.oneToTwo:
        return 2;
      case TrainingAgeBucket.threeToFive:
        return 4;
      case TrainingAgeBucket.moreThanFive:
        return 6;
    }
  }

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
    extra[TrainingExtraKeys.trainingAge] = _trainingAge?.name;
    extra[TrainingExtraKeys.historicalFrequency] = _historicalFrequency;
    extra[TrainingExtraKeys.plannedFrequency] = _plannedFrequency;
    extra[TrainingExtraKeys.timePerSessionBucket] = _timePerSession?.name;
    extra[TrainingExtraKeys.volumeTolerance] = _volumeTolerance?.name;
    extra[TrainingExtraKeys.intensityTolerance] = _intensityTolerance?.name;
    extra[TrainingExtraKeys.restProfile] = _restProfile?.name;
    extra[TrainingExtraKeys.sleepBucket] = _sleepBucket?.name;
    extra[TrainingExtraKeys.stressLevel] = _stressLevel?.name;
    extra[TrainingExtraKeys.recoveryQuality] = _recoveryQuality?.name;
    extra[TrainingExtraKeys.activeInjuries] = _activeInjuries
        .map((e) => e.name)
        .toList();
    extra[TrainingExtraKeys.knowsPRs] = _knowsPRs;
    extra[TrainingExtraKeys.prSquat] = _knowsPRs ? _prSquatCtrl.text : null;
    extra[TrainingExtraKeys.prBench] = _knowsPRs ? _prBenchCtrl.text : null;
    extra[TrainingExtraKeys.prDeadlift] = _knowsPRs
        ? _prDeadliftCtrl.text
        : null;

    // ============ MAPEO AUTOMÁTICO PARA VME/VMR ============
    // Mapear stressLevel → nonPhysicalStressLevel2
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

    // Mapear sleepBucket → restQuality2
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
    // ✅ Leer desde controllers (UI) en lugar de variables internas
    // Esto evita que se pierdan valores al guardar

    // Parsear valores desde controllers
    final yearsFromCtrl = int.tryParse(_yearsTrainingCtrl.text);
    final sessionFromCtrl = int.tryParse(_sessionDurationCtrl.text);
    final restFromCtrl = int.tryParse(_restBetweenSetsCtrl.text);
    final sleepFromCtrl = double.tryParse(
      _avgSleepHoursCtrl.text.replaceAll(',', '.'),
    );

    // ✅ Parsear peso y estatura desde controllers
    final heightCmFromCtrl = double.tryParse(
      _heightCmCtrl.text.replaceAll(',', '.'),
    );
    final weightKgFromCtrl = double.tryParse(
      _weightKgCtrl.text.replaceAll(',', '.'),
    );

    // Actualizar variables internas desde controllers
    _yearsTraining = yearsFromCtrl;
    _sessionDurationMinutes = sessionFromCtrl;
    _restBetweenSetsSeconds = restFromCtrl;
    _avgSleepHours = sleepFromCtrl;

    // Calcular valores derivados (usar overrides numéricos del usuario si existen)
    final derivedYears =
        _yearsTraining ?? _deriveYearsTrainingFromBucket(_trainingAge);
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

    // ✅ GUARDAR PESO Y ESTATURA (datos mínimos para entrenamiento)
    if (heightCmFromCtrl != null && heightCmFromCtrl > 0) {
      extra[TrainingExtraKeys.heightCm] = heightCmFromCtrl;
      extra[TrainingInterviewKeys.heightCm] = heightCmFromCtrl;
    }
    if (weightKgFromCtrl != null && weightKgFromCtrl > 0) {
      extra[TrainingExtraKeys.weightKg] = weightKgFromCtrl;
      extra[TrainingInterviewKeys.weightKg] = weightKgFromCtrl;
    }

    // Guardar también en TrainingInterviewKeys (backward compatibility)
    if (derivedYears != null) {
      extra[TrainingInterviewKeys.yearsTrainingContinuous] = derivedYears;
    }
    if (derivedSession != null) {
      extra[TrainingInterviewKeys.sessionDurationMinutes] = derivedSession;
    }
    if (derivedRest != null) {
      extra[TrainingInterviewKeys.restBetweenSetsSeconds] = derivedRest;
    }
    if (derivedSleep != null) {
      extra[TrainingInterviewKeys.avgSleepHours] = derivedSleep;
    }

    // Campos opcionales que se guardan si el usuario los edita directamente
    if (_workCapacity != null) {
      extra[TrainingInterviewKeys.workCapacity] = _workCapacity;
    }
    if (_recoveryHistory != null) {
      extra[TrainingInterviewKeys.recoveryHistory] = _recoveryHistory;
    }

    // IMPORTANTE: Guardar externalRecovery SIEMPRE (true o false), no solo cuando es true
    extra[TrainingInterviewKeys.externalRecovery] = _externalRecovery;

    if (_programNovelty != null) {
      extra[TrainingInterviewKeys.programNovelty] = _programNovelty!.name;
    }
    if (_physicalStress != null) {
      extra[TrainingInterviewKeys.physicalStress] = _physicalStress!.name;
    }
    if (_dietQuality != null) {
      extra[TrainingInterviewKeys.dietQuality] = _dietQuality!.name;
    }

    // Defaults conservadores para campos que aún no se capturan en UI
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
      extra[TrainingExtraKeys.dietHabitsClass] = 'ISO'; // Isocalórico (neutral)
    }

    // IMPORTANTE: Preservar todos los campos que NO estamos editando en esta pestaña
    // (heightCm, strengthLevelClass, workCapacityScore, recuperationHistoryScore,
    // externalRecoverySupport, programNoveltyClass, externalPhysicalStressLevel,
    // nonPhysicalStressLevel2, restQuality2, dietHabitsClass, y otros campos del extra)
    // No removemos ni sobrescribimos, solo actualizamos los que se editan aquí

    // Calcular días por semana desde frequencia planificada
    final daysPerWeek = _plannedFrequency ?? 0;

    final updatedTraining = TrainingProfileFormMapper.apply(
      base: client.training,
      input: TrainingProfileFormInput(
        extra: extra,
        trainingLevelLabel: _trainingLevel != null
            ? TrainingProfileFormMapper.optionFromTrainingLevel(_trainingLevel)
            : null,
        daysPerWeekLabel: daysPerWeek.toString(),
        timePerSessionLabel: _timePerSession?.label,
        planDurationWeeks: 8, // Valor por defecto de 8 semanas
        priorityMusclesPrimary: _primaryMuscles,
        priorityMusclesSecondary: _secondaryMuscles,
        priorityMusclesTertiary: _tertiaryMuscles,
        avgSleepHours: derivedSleep,
        perceivedStress: _stressLevel?.label,
        recoveryQuality: _recoveryQuality?.label,
        usesAnabolics: false, // Campo eliminado
        isCompetitor: false, // Campo eliminado
        competitionCategory: null,
        competitionDateIso: null,
        prSquat: _knowsPRs ? _prSquatCtrl.text : null,
        prBench: _knowsPRs ? _prBenchCtrl.text : null,
        prDeadlift: _knowsPRs ? _prDeadliftCtrl.text : null,
      ),
    );

    // Aplicar los 4 campos tipados con copyWith()
    final finalTraining = updatedTraining.copyWith(
      yearsTrainingContinuous: derivedYears ?? 0,
      sessionDurationMinutes: derivedSession ?? 0,
      restBetweenSetsSeconds: derivedRest ?? 0,
      avgSleepHours: derivedSleep ?? 0.0,
    );

    // ═══════════════════════════════════════════════════════════════
    // GUARDAR CAMPOS V2 (2025) - MANDATORY
    // ═══════════════════════════════════════════════════════════════

    extra[TrainingInterviewKeys.avgWeeklySetsPerMuscle] =
        int.tryParse(_avgWeeklySetsPerMuscleCtrl.text) ?? 12;

    extra[TrainingInterviewKeys.consecutiveWeeksTraining] =
        int.tryParse(_consecutiveWeeksTrainingCtrl.text) ?? 4;

    extra[TrainingInterviewKeys.perceivedRecoveryStatus] =
        int.tryParse(_perceivedRecoveryStatusCtrl.text) ?? 7;

    extra[TrainingInterviewKeys.averageRIR] =
        double.tryParse(_averageRIRCtrl.text) ?? 2.0;

    extra[TrainingInterviewKeys.averageSessionRPE] =
        int.tryParse(_averageSessionRPECtrl.text) ?? 7;

    // ═══════════════════════════════════════════════════════════════
    // GUARDAR CAMPOS V2 - RECOMMENDED (solo si tienen valor)
    // ═══════════════════════════════════════════════════════════════

    final maxSets = int.tryParse(_maxWeeklySetsCtrl.text);
    if (maxSets != null && maxSets > 0) {
      extra[TrainingInterviewKeys.maxWeeklySetsBeforeOverreaching] = maxSets;
    }

    final deloadFreq = int.tryParse(_deloadFrequencyCtrl.text);
    if (deloadFreq != null && deloadFreq > 0) {
      extra[TrainingInterviewKeys.deloadFrequencyWeeks] = deloadFreq;
    }

    final soreness = int.tryParse(_soreness48hCtrl.text);
    if (soreness != null && soreness > 0) {
      extra[TrainingInterviewKeys.soreness48hAverage] = soreness;
    }

    final breaks = int.tryParse(_periodBreaksCtrl.text);
    if (breaks != null && breaks >= 0) {
      extra[TrainingInterviewKeys.periodBreaksLast12Months] = breaks;
    }

    if (_performanceTrend != null) {
      extra[TrainingInterviewKeys.performanceTrend] = _performanceTrend!.name;
    }

    return client.copyWith(training: finalTraining.copyWith(extra: extra));
  }

  Future<void> _onSavePressed() async {
    if (_client == null) return;

    try {
      // ============ PASO 1: GUARDAR DATOS DE ENTREVISTA ============
      // Construir el TrainingProfile editado explícitamente
      // Esto persiste los 4 campos: trainingYears, sessionDurationMinutes, restBetweenSetsSeconds, avgSleepHours
      final editedProfile = _buildUpdatedClient().training;

      // 🔍 VALIDACIÓN: Verificar que los 4 campos estén presentes en extra
      debugPrint('📋 ANTES DE GUARDAR - training.extra contiene:');
      debugPrint(
        '   yearsTrainingContinuous: ${editedProfile.extra[TrainingInterviewKeys.yearsTrainingContinuous]}',
      );
      debugPrint(
        '   sessionDurationMinutes: ${editedProfile.extra[TrainingInterviewKeys.sessionDurationMinutes]}',
      );
      debugPrint(
        '   restBetweenSetsSeconds: ${editedProfile.extra[TrainingInterviewKeys.restBetweenSetsSeconds]}',
      );
      debugPrint(
        '   avgSleepHours: ${editedProfile.extra[TrainingInterviewKeys.avgSleepHours]}',
      );
      debugPrint(
        '   Campos tipados: years=${editedProfile.yearsTrainingContinuous}, session=${editedProfile.sessionDurationMinutes}, rest=${editedProfile.restBetweenSetsSeconds}, sleep=${editedProfile.avgSleepHours}',
      );

      // ESPERAR a que se guarden los datos de entrevista
      await ref.read(clientsProvider.notifier).updateActiveClient((prev) {
        // PASO 1: Deep merge para preservar Maps anidados (mevByMuscle, etc.)
        final mergedTrainingExtra = deepMerge(
          prev.training.extra,
          editedProfile.extra,
        );
        final mergedTraining = editedProfile.copyWith(
          extra: mergedTrainingExtra,
        );

        // 🔍 VALIDACIÓN: Confirmar merge
        debugPrint('✅ DESPUÉS DE MERGE - training.extra contiene:');
        debugPrint(
          '   yearsTrainingContinuous: ${mergedTraining.extra[TrainingInterviewKeys.yearsTrainingContinuous]}',
        );
        debugPrint(
          '   sessionDurationMinutes: ${mergedTraining.extra[TrainingInterviewKeys.sessionDurationMinutes]}',
        );
        debugPrint(
          '   restBetweenSetsSeconds: ${mergedTraining.extra[TrainingInterviewKeys.restBetweenSetsSeconds]}',
        );
        debugPrint(
          '   avgSleepHours: ${mergedTraining.extra[TrainingInterviewKeys.avgSleepHours]}',
        );

        // PASO 2: Retornar el Client con el training actualizado
        return prev.copyWith(training: mergedTraining);
      });

      // ✅ Verificar que el widget sigue montado después de la operación async
      if (!mounted) return;

      // ============ PASO 2: CALCULAR Y GUARDAR MEV/MRV ============
      // IMPORTANTE: Solo después de que los datos de entrevista estén guardados
      await ref.read(clientsProvider.notifier).updateActiveClient((prev) {
        final resolver = AthleteContextResolver();
        final volume = VolumeIndividualizationService();

        // Resolver contexto del atleta desde el cliente actualizado
        final athlete = resolver.resolve(prev);
        final level = prev.training.trainingLevel ?? TrainingLevel.intermediate;

        // Calcular MEV/MRV individualizados
        final bounds = volume.computeBounds(
          level: level,
          athlete: athlete,
          trainingExtra: prev.training.extra,
        );

        // ✅ P0 FIX: Derivar MEV/MRV por músculo PRIMERO para usarlos en el cálculo
        final volumeByMuscle = VolumeByMuscleDerivationService.derive(
          mevGlobal: bounds.mevIndividual,
          mrvGlobal: bounds.mrvIndividual,
          rawMuscleKeys: MuscleGroup.values
              .where((m) => SupportedMuscles.isSupported(m.name))
              .map((m) => m.name),
        );
        final mevByMuscle = volumeByMuscle['mevByMuscle'] ?? {};
        final mrvByMuscle = volumeByMuscle['mrvByMuscle'] ?? {};

        // ✅ P0 FIX FINAL: SIEMPRE calcular targetSetsByMuscle usando MEV/MRV POR MÚSCULO
        // No preservar valores previos para evitar targets planos persistidos
        final Map<String, double> targetSetsByMuscle = {};
        for (final key in mevByMuscle.keys) {
          final mevVal = mevByMuscle[key];
          final mrvVal = mrvByMuscle[key];

          if (mevVal != null && mrvVal != null) {
            final mev = mevVal.toDouble();
            final mrv = mrvVal.toDouble();
            final mid = ((mev + mrv) / 2.0)
                .roundToDouble(); // Punto medio por músculo
            targetSetsByMuscle[key] = mid;
          }
        }

        debugPrint(
          '[SAVE][COMPUTE] targetSetsByMuscle calculado con ${targetSetsByMuscle.length} músculos',
        );

        // 🔎 INSTRUMENTACIÓN P0: Verificar que hay valores distintos
        debugPrint('[WRITE][targetSetsByMuscle] = $targetSetsByMuscle');
        debugPrint('[WRITE][mevByMuscle] = $mevByMuscle');
        debugPrint('[WRITE][mrvByMuscle] = $mrvByMuscle');

        // ═══════════════════════════════════════════════════════════════════
        // PHASE 4: Distribuir targetSetsByMuscle en primary/secondary/tertiary
        // según prioridades musculares, sin cambiar el volumen total por músculo
        // ═══════════════════════════════════════════════════════════════════

        // PASO 1: Definir split base (estable y explícito)
        final priorityVolumeSplit = <String, double>{
          'primary': 0.45,
          'secondary': 0.35,
          'tertiary': 0.20,
        };

        // PASO 2: Obtener prioridades del perfil (con cast seguro)
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

        // PASO 3: Distribuir por músculo
        final Map<String, Map<String, double>> targetSetsByMusclePriority = {};

        for (final entry in targetSetsByMuscle.entries) {
          final muscle = entry.key;
          final total = entry.value;

          double p, s, t;

          if (primaryMuscles.contains(muscle)) {
            // Músculo priorizado como PRIMARY → mayor peso en primary
            p = total * priorityVolumeSplit['primary']!;
            s = total * priorityVolumeSplit['secondary']!;
            t = total * priorityVolumeSplit['tertiary']!;
          } else if (secondaryMuscles.contains(muscle)) {
            // Músculo priorizado como SECONDARY → balance hacia secondary
            p = total * 0.35;
            s = total * 0.40;
            t = total * 0.25;
          } else if (tertiaryMuscles.contains(muscle)) {
            // Músculo priorizado como TERTIARY → mayor peso en tertiary
            p = total * 0.25;
            s = total * 0.35;
            t = total * 0.40;
          } else {
            // Sin prioridad declarada → balance neutro
            p = total * 0.33;
            s = total * 0.34;
            t = total * 0.33;
          }

          targetSetsByMusclePriority[muscle] = {
            'primary': (p * 10).roundToDouble() / 10, // 1 decimal
            'secondary': (s * 10).roundToDouble() / 10,
            'tertiary': (t * 10).roundToDouble() / 10,
          };
        }

        // PASO 4: Log de validación
        debugPrint('[PHASE4] priorityVolumeSplit = $priorityVolumeSplit');
        debugPrint(
          '[PHASE4] targetSetsByMusclePriority = $targetSetsByMusclePriority',
        );

        // ═══════════════════════════════════════════════════════════════════
        // PHASE 5: Distribuir series por intensidad (Heavy / Medium / Light)
        // sin alterar el volumen total semanal ni la prioridad
        // ═══════════════════════════════════════════════════════════════════

        // PASO 1: Definir split base por intensidad
        double heavyPct = 0.30;
        double mediumPct = 0.40;
        double lightPct = 0.30;

        // Ajustes por nivel de entrenamiento
        final trainingLevel = prev.training.extra['trainingLevel'];
        if (trainingLevel == 'beginner') {
          heavyPct = 0.25;
          lightPct = 0.35;
        } else if (trainingLevel == 'advanced') {
          heavyPct = 0.35;
          lightPct = 0.25;
        }

        // Normalizar medium para que sume 100%
        mediumPct = 1.0 - heavyPct - lightPct;

        final intensityVolumeSplit = <String, double>{
          'heavy': heavyPct,
          'medium': mediumPct,
          'light': lightPct,
        };

        // PASO 2: Distribuir por músculo y prioridad
        final Map<String, Map<String, Map<String, double>>>
        targetSetsByMusclePriorityIntensity = {};

        for (final muscleEntry in targetSetsByMusclePriority.entries) {
          final muscle = muscleEntry.key;
          final byPriority = muscleEntry.value;

          final Map<String, Map<String, double>> muscleOut = {};

          for (final priorityEntry in byPriority.entries) {
            final priority =
                priorityEntry.key; // primary / secondary / tertiary
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

        // PASO 3: Log de validación
        debugPrint('[PHASE5] intensityVolumeSplit = $intensityVolumeSplit');
        debugPrint(
          '[PHASE5] targetSetsByMusclePriorityIntensity = $targetSetsByMusclePriorityIntensity',
        );

        // GUARDAR MEV/MRV en training.extra
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

      // ✅ Verificar que el widget sigue montado después de la operación async
      if (!mounted) return;

      // 🔴 P0: asegurar que el cliente activo en memoria coincide con el guardado
      final updatedClient = ref.read(clientsProvider).value?.activeClient;
      if (updatedClient != null) {
        // 🔎 VERIFICACIÓN PRE-SYNC: Confirmar que los mapas por músculo están presentes
        debugPrint(
          '🔎 PRE-SYNC extra keys: ${updatedClient.training.extra.keys.toList()}',
        );
        debugPrint(
          '🔎 PRE-SYNC has mevByMuscle: ${updatedClient.training.extra['mevByMuscle'] is Map}',
        );
        debugPrint(
          '🔎 PRE-SYNC has mrvByMuscle: ${updatedClient.training.extra['mrvByMuscle'] is Map}',
        );
        debugPrint(
          '🔎 PRE-SYNC has targetSetsByMuscle: ${updatedClient.training.extra['targetSetsByMuscle'] is Map}',
        );

        await ref
            .read(clientsProvider.notifier)
            .setActiveClientById(updatedClient.id);
      }

      // ✅ Verificar que el widget sigue montado después de la operación async
      if (!mounted) return;

      _isDirty = false;

      // 🔥 Regenerar plan si cambió algo relevante para volumen
      final oldExtra = _client?.training.extra ?? {};
      final newExtra = updatedClient?.training.extra ?? {};
      final needsRegenBase = _volumeRelevantChanged(oldExtra, newExtra);

      // 🔥 Forzar regen si aún no existen los mapas por músculo
      final mapsMissing =
          newExtra['mevByMuscle'] is! Map || newExtra['mrvByMuscle'] is! Map;

      final needsRegen = needsRegenBase || mapsMissing;

      if (needsRegen && updatedClient != null) {
        debugPrint('🔄 CAMBIO RELEVANTE DETECTADO - Regenerando plan...');
        try {
          await ref
              .read(trainingPlanProvider.notifier)
              .generatePlan(profile: updatedClient.training);
          debugPrint('✅ Plan regenerado exitosamente');
        } catch (e) {
          debugPrint('⚠️ Error al regenerar plan: $e');
        }

        // ✅ Verificar que el widget sigue montado después de la operación async
        if (!mounted) return;
      }

      // 🔍 VALIDACIÓN FINAL: Confirmar que los datos se guardaron en memoria (antes de persistencia)
      final finalClient = ref.read(clientsProvider).value?.activeClient;
      if (finalClient != null) {
        debugPrint('🎯 GUARDADO COMPLETADO - training.extra final contiene:');
        debugPrint(
          '   yearsTrainingContinuous: ${finalClient.training.extra[TrainingInterviewKeys.yearsTrainingContinuous]}',
        );
        debugPrint(
          '   sessionDurationMinutes: ${finalClient.training.extra[TrainingInterviewKeys.sessionDurationMinutes]}',
        );
        debugPrint(
          '   restBetweenSetsSeconds: ${finalClient.training.extra[TrainingInterviewKeys.restBetweenSetsSeconds]}',
        );
        debugPrint(
          '   avgSleepHours: ${finalClient.training.extra[TrainingInterviewKeys.avgSleepHours]}',
        );
        debugPrint(
          '   mevIndividual: ${finalClient.training.extra['mevIndividual']}',
        );
        debugPrint(
          '   mrvIndividual: ${finalClient.training.extra['mrvIndividual']}',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil de entrenamiento guardado correctamente.'),
            backgroundColor: kPrimaryColor,
          ),
        );
      }
    } catch (e) {
      // Si falla el cálculo de MEV/MRV, mostrar error pero mantener los datos guardados
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al calcular MEV/MRV: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _prSquatCtrl.dispose();
    _prBenchCtrl.dispose();
    _prDeadliftCtrl.dispose();
    _historicalFreqCtrl.dispose();
    _plannedFreqCtrl.dispose();

    // ✅ Dispose de controllers de campos críticos
    _yearsTrainingCtrl.dispose();
    _sessionDurationCtrl.dispose();
    _restBetweenSetsCtrl.dispose();
    _avgSleepHoursCtrl.dispose();

    // ✅ Dispose de controllers de peso y estatura
    _heightCmCtrl.dispose();
    _weightKgCtrl.dispose();

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

      // ✅ CRITICAL FIX: Solo recargar si es DIFERENTE cliente
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
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
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
                  title: '4. Factores de Recuperación',
                  child: _buildRecoveryFactors(),
                ),
                ClinicSectionSurface(
                  icon: Icons.healing,
                  title: '5. Lesiones Activas',
                  child: _buildInjuries(),
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
                ClinicSectionSurface(
                  icon: Icons.edit_note,
                  title: '8. Datos Individualizados (Override Opcional)',
                  child: _buildIndividualizedDataOverrides(),
                ),
                ClinicSectionSurface(
                  icon: Icons.trending_up,
                  title: '9. Evaluación Avanzada V2 (Científica 2025)',
                  child: _buildAdvancedEvaluationV2(),
                ),
                const SizedBox(height: 32),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _onSavePressed,
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar Evaluación'),
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
        // ✅ DATOS MÍNIMOS PARA ENTRENAMIENTO (peso y estatura)
        SizedBox(
          width: 380,
          child: TextField(
            controller: _heightCmCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
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
            decoration: InputDecoration(
              labelText: 'Peso (kg) *',
              prefixIcon: Icon(Icons.monitor_weight),
              helperText: 'Requerido para entrenamiento',
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
        SizedBox(
          width: 380,
          child: EnumGlassDropdown<TrainingLevel>(
            label: 'Nivel de entrenamiento real *',
            value: _trainingLevel,
            values: TrainingLevel.values,
            labelBuilder: (l) => l.label,
            onChanged: (v) {
              setState(() => _trainingLevel = v);
              _markDirty();
            },
          ),
        ),
        SizedBox(
          width: 380,
          child: EnumGlassDropdown<TrainingAgeBucket>(
            label: 'Años entrenando de forma continua',
            value: _trainingAge,
            values: TrainingAgeBucket.values,
            labelBuilder: (a) => a.label,
            onChanged: (v) {
              setState(() => _trainingAge = v);
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
            label: 'Días entrenados REALMENTE el último mes (1-31)',
            onChanged: (v) {
              _historicalFrequency = int.tryParse(v);
              _markDirty();
            },
          ),
        ),
        SizedBox(
          width: 250,
          child: GlassNumericField(
            controller: _plannedFreqCtrl,
            label: 'Días que puede sostener los próximos 2 meses (1-7) *',
            onChanged: (v) {
              _plannedFrequency = int.tryParse(v);
              _markDirty();
            },
          ),
        ),
        SizedBox(
          width: 380,
          child: EnumGlassDropdown<TimePerSessionBucket>(
            label: 'Tiempo disponible promedio por sesión *',
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EnumGlassDropdown<VolumeTolerance>(
                label: 'Tolerancia al volumen',
                value: _volumeTolerance,
                values: VolumeTolerance.values,
                labelBuilder: (v) => v.label,
                onChanged: (v) {
                  setState(() => _volumeTolerance = v);
                  _markDirty();
                },
              ),
              const SizedBox(height: 6),
              const Text(
                'Anclaje: Con 10-12 series/músculo/semana...',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 380,
          child: EnumGlassDropdown<IntensityTolerance>(
            label: 'Frecuencia de entrenamiento cercano al fallo',
            value: _intensityTolerance,
            values: IntensityTolerance.values,
            labelBuilder: (i) => i.label,
            onChanged: (v) {
              setState(() => _intensityTolerance = v);
              _markDirty();
            },
          ),
        ),
        SizedBox(
          width: 380,
          child: EnumGlassDropdown<RestProfile>(
            label: 'Descansos típicos entre series',
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

  // 4. FACTORES DE RECUPERACIÓN
  Widget _buildRecoveryFactors() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        SizedBox(
          width: 250,
          child: EnumGlassDropdown<SleepBucket>(
            label: 'Horas promedio de sueño',
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
            label: 'Nivel de estrés diario',
            value: _stressLevel,
            values: StressLevel.values,
            labelBuilder: (s) => s.label,
            onChanged: (v) {
              setState(() => _stressLevel = v);
              _markDirty();
            },
          ),
        ),
        SizedBox(
          width: 250,
          child: EnumGlassDropdown<RecoveryQuality>(
            label: 'Sensación general de recuperación',
            value: _recoveryQuality,
            values: RecoveryQuality.values,
            labelBuilder: (r) => r.label,
            onChanged: (v) {
              setState(() => _recoveryQuality = v);
              _markDirty();
            },
          ),
        ),
      ],
    );
  }

  // 5. LESIONES
  Widget _buildInjuries() {
    return Wrap(
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
    );
  }

  // 6. PRIORIDADES MUSCULARES
  Widget _buildMuscles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Seleccione los músculos por prioridad (sin límite)',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 12),
        MuscleSelectionGroup(
          primarySelection: _primaryMuscles,
          secondarySelection: _secondaryMuscles,
          tertiarySelection: _tertiaryMuscles,
          onUpdate: (p, s, t) {
            setState(() {
              _primaryMuscles = p;
              _secondaryMuscles = s;
              _tertiaryMuscles = t;
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
              'Conozco mis récords personales (1RM)',
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

  // 8. DATOS INDIVIDUALIZADOS (OVERRIDE OPCIONAL)
  Widget _buildIndividualizedDataOverrides() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estos valores se calculan automáticamente desde los buckets seleccionados arriba. '
          'Puede editarlos manualmente si desea especificar valores exactos.',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: 250,
              child: GlassNumericField(
                controller: _yearsTrainingCtrl,
                label: 'Años de entrenamiento continuo',
                onChanged: (_) => _markDirty(),
              ),
            ),
            SizedBox(
              width: 250,
              child: GlassNumericField(
                controller: _sessionDurationCtrl,
                label: 'Duración sesión (minutos)',
                onChanged: (_) => _markDirty(),
              ),
            ),
            SizedBox(
              width: 250,
              child: GlassNumericField(
                controller: _restBetweenSetsCtrl,
                label: 'Descanso entre series (seg)',
                onChanged: (_) => _markDirty(),
              ),
            ),
            SizedBox(
              width: 250,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Horas promedio de sueño',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 48,
                    child: TextFormField(
                      controller: _avgSleepHoursCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => _markDirty(),
                      style: const TextStyle(color: Colors.white),
                      decoration: hcsDecoration(
                        context,
                        labelText: 'Horas promedio de sueño',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 9. EVALUACIÓN AVANZADA V2 (2025)
  Widget _buildAdvancedEvaluationV2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // SUBSECCIÓN: VOLUMEN
        Text(
          'Capacidad de Volumen',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: kPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: 380,
              child: CustomTextFormField(
                controller: _avgWeeklySetsPerMuscleCtrl,
                label: '¿Cuántos sets DUROS haces por músculo/semana? *',
                hintText:
                    'Ejemplo: 12 (si haces pecho 2 días, 6 sets cada día)',
                keyboardType: TextInputType.number,
                onChanged: (_) => _markDirty(),
              ),
            ),
            SizedBox(
              width: 380,
              child: CustomTextFormField(
                controller: _consecutiveWeeksTrainingCtrl,
                label: '¿Cuántas semanas consecutivas llevas entrenando? *',
                hintText: 'Ejemplo: 16 (sin parar >1 semana)',
                keyboardType: TextInputType.number,
                onChanged: (_) => _markDirty(),
              ),
            ),
            SizedBox(
              width: 380,
              child: CustomTextFormField(
                controller: _maxWeeklySetsCtrl,
                label: '¿Máximo sets/semana tolerados? (opcional)',
                hintText: 'Ejemplo: 20 (máximo sin sobreentrenarte)',
                keyboardType: TextInputType.number,
                onChanged: (_) => _markDirty(),
              ),
            ),
            SizedBox(
              width: 380,
              child: CustomTextFormField(
                controller: _deloadFrequencyCtrl,
                label: '¿Cada cuántas semanas necesitas descarga? (opcional)',
                hintText: 'Ejemplo: 4 (deload cada 4 semanas)',
                keyboardType: TextInputType.number,
                onChanged: (_) => _markDirty(),
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 16),

        // SUBSECCIÓN: RECUPERACIÓN Y READINESS
        Text(
          'Recuperación y Estado de Readiness',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: kPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: 380,
              child: CustomTextFormField(
                controller: _perceivedRecoveryStatusCtrl,
                label: '¿Cómo te sientes antes de entrenar? (PRS 1-10) *',
                hintText: '1=Agotado, 10=Fresco',
                keyboardType: TextInputType.number,
                onChanged: (_) => _markDirty(),
              ),
            ),
            SizedBox(
              width: 380,
              child: CustomTextFormField(
                controller: _soreness48hCtrl,
                label: '¿Qué tan adolorido quedas a las 48h? (DOMS 1-10)',
                hintText: '1=Sin dolor, 10=Dolor extremo',
                keyboardType: TextInputType.number,
                onChanged: (_) => _markDirty(),
              ),
            ),
            SizedBox(
              width: 380,
              child: CustomTextFormField(
                controller: _periodBreaksCtrl,
                label: '¿Pausas >2 semanas en el último año?',
                hintText: 'Ejemplo: 2 (dos pausas largas)',
                keyboardType: TextInputType.number,
                onChanged: (_) => _markDirty(),
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 16),

        // SUBSECCIÓN: INTENSIDAD Y ESFUERZO
        Text(
          'Intensidad y Esfuerzo Percibido',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: kPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: 380,
              child: CustomTextFormField(
                controller: _averageRIRCtrl,
                label: '¿Cuántas reps dejas en reserva? (RIR 0-5) *',
                hintText: '0=Fallo, 2=Óptimo hipertrofia, 5=Muy fácil',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => _markDirty(),
              ),
            ),
            SizedBox(
              width: 380,
              child: CustomTextFormField(
                controller: _averageSessionRPECtrl,
                label: '¿Qué tan duro entrenas? (RPE 1-10) *',
                hintText: '1=Muy fácil, 10=Máximo esfuerzo',
                keyboardType: TextInputType.number,
                onChanged: (_) => _markDirty(),
              ),
            ),
            SizedBox(
              width: 380,
              child: EnumGlassDropdown<PerformanceTrend>(
                label: 'Tendencia de rendimiento actual',
                value: _performanceTrend,
                values: PerformanceTrend.values,
                labelBuilder: (trend) => trend.label,
                onChanged: (v) {
                  setState(() => _performanceTrend = v);
                  _markDirty();
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Nota informativa
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kPrimaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kPrimaryColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: kPrimaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Los campos marcados con * son OBLIGATORIOS para el Motor de entrenamiento. '
                  'Los opcionales mejoran la precisión de la prescripción.',
                  style: TextStyle(
                    fontSize: 13,
                    color: kTextColor.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Estado de volumen individualizado leído directamente desde training.extra.
  // REMOVIDO: No mostrar esta información en la UI
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
                        'targetSetsByMuscle: ${targetSetsByMuscle.length} músculos',
                        style: const TextStyle(color: kTextColorSecondary),
                      ),
                  ],
                ),
              ],
            )
          : const Text(
              'No hay datos de volumen individualizado almacenados aún. Se mostrarán aquí cuando estén disponibles.',
              style: TextStyle(color: kTextColorSecondary),
            ),
    );
  }
  */
}

// ============================================================================
// WIDGETS AUXILIARES
// ============================================================================
// Los widgets Glass ahora están en shared_form_widgets.dart
