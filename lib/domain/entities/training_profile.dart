import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/core/constants/training_interview_keys.dart';
import 'package:hcs_app_lap/core/enums/gender.dart';
import 'package:hcs_app_lap/core/enums/training_goal.dart';
import 'package:hcs_app_lap/core/enums/training_focus.dart';
import 'package:hcs_app_lap/core/enums/training_level.dart';
import 'package:hcs_app_lap/core/enums/training_interview_enums.dart';
import 'package:hcs_app_lap/domain/entities/volume_tolerance_profile.dart';
import 'package:hcs_app_lap/utils/deep_merge.dart';

/// Perfil completo de entrenamiento del cliente.
/// Este modelo está diseñado como "superset" para ser compatible con:
/// - volume_capacity_estimator.dart
/// - annual_volume_planner.dart
/// - training_program_engine.dart
/// - training_profile_provider.dart
/// - client.dart (getters de PRs, etc.)
class TrainingProfile extends Equatable {
  final String? id;
  final DateTime? date; // Fecha de creación del registro (Snapshot)
  final Gender? gender;
  final int? age;
  final double? bodyWeight;
  final bool isCompetitor;
  final String? competitionCategory;
  final bool usesAnabolics;
  final String? pharmacologyProtocol;
  final String? peakWeekHistory;
  final TrainingGoal globalGoal;
  final TrainingFocus? trainingFocus;
  final TrainingLevel? trainingLevel;
  final int daysPerWeek;
  final int timePerSessionMinutes;
  final int yearsTrainingContinuous;
  final int sessionDurationMinutes;
  final int restBetweenSetsSeconds;
  final double avgSleepHours;
  final List<String> equipment;
  final List<String> movementRestrictions;
  final String? perceivedStress;
  final String? recoveryQuality;
  final double? sorenessLevel;
  final double? motivationLevel;
  final List<String> priorityMusclesPrimary;
  final List<String> priorityMusclesSecondary;
  final List<String> priorityMusclesTertiary;
  final Map<String, int> baseVolumePerMuscle;
  final Map<String, Map<String, double>> seriesDistribution;
  final Map<String, VolumeToleranceProfile> pastVolumeTolerance;
  final int blockLengthWeeks;
  final int currentWeekIndex;
  final Map<String, dynamic> extra;
  final String? prSquat;
  final String? prBench;
  final String? prDeadlift;

  const TrainingProfile({
    this.id,
    this.date,
    this.gender,
    this.age,
    this.bodyWeight,
    this.isCompetitor = false,
    this.competitionCategory,
    this.usesAnabolics = false,
    this.pharmacologyProtocol,
    this.peakWeekHistory,
    this.globalGoal = TrainingGoal.generalFitness,
    this.trainingFocus,
    this.trainingLevel,
    this.daysPerWeek = 0,
    this.timePerSessionMinutes = 0,
    this.yearsTrainingContinuous = 0,
    this.sessionDurationMinutes = 0,
    this.restBetweenSetsSeconds = 0,
    this.avgSleepHours = 0.0,
    this.equipment = const [],
    this.movementRestrictions = const [],
    this.perceivedStress,
    this.recoveryQuality,
    this.sorenessLevel,
    this.motivationLevel,
    this.priorityMusclesPrimary = const [],
    this.priorityMusclesSecondary = const [],
    this.priorityMusclesTertiary = const [],
    this.baseVolumePerMuscle = const {},
    this.seriesDistribution = const {},
    this.pastVolumeTolerance = const {},
    this.blockLengthWeeks = 4,
    this.currentWeekIndex = 0,
    this.extra = const {},
    this.prSquat,
    this.prBench,
    this.prDeadlift,
  });

  /// FACTORY vacía segura para clientes nuevos.
  factory TrainingProfile.empty() {
    return const TrainingProfile(
      globalGoal: TrainingGoal.generalFitness,
      daysPerWeek: 0,
      timePerSessionMinutes: 0,
      yearsTrainingContinuous: 0,
      sessionDurationMinutes: 0,
      restBetweenSetsSeconds: 0,
      avgSleepHours: 0.0,
      equipment: [],
      movementRestrictions: [],
      priorityMusclesPrimary: [],
      priorityMusclesSecondary: [],
      priorityMusclesTertiary: [],
      baseVolumePerMuscle: {},
      seriesDistribution: {},
      pastVolumeTolerance: {},
      extra: {},
    );
  }

  /// Indica si el perfil tiene lo mínimo para generar un plan real.
  /// Debe cumplir con los mismos requisitos que valida generatePlan():
  /// - trainingLevel: requerido para calcular volúmenes
  /// - daysPerWeek: estructura básica del plan
  /// - timePerSessionMinutes: límites de duración
  /// - Al menos UNO de: priority muscles o baseVolumePerMuscle
  bool get isValid {
    // Validación básica
    if (trainingLevel == null) return false;
    if (daysPerWeek <= 0) return false;
    if (timePerSessionMinutes <= 0) return false;

    // Debe tener ALGÚN dato de volumen/músculos
    final hasPriorityMuscles =
        priorityMusclesPrimary.isNotEmpty ||
        priorityMusclesSecondary.isNotEmpty ||
        priorityMusclesTertiary.isNotEmpty;
    final hasBaseVolume = baseVolumePerMuscle.values.any((value) => value > 0);
    final hasSeriesDistribution = seriesDistribution.values.any(
      (dist) => dist.values.any((value) => value > 0),
    );

    return hasBaseVolume || hasSeriesDistribution || hasPriorityMuscles;
  }

  /// Compatibilidad con código previo que consulta `profile.baseSeries`.
  Map<String, int> get baseSeries => baseVolumePerMuscle;

  /// Compatibilidad con código previo que consulta `profile.musclePriority`.
  /// Si en algún momento se diferencian, se puede refinar.
  Map<String, int> get musclePriority => baseVolumePerMuscle;

  // ============================================================
  // GETTERS CLÍNICOS EXPLÍCITOS (Datos de Entrevista)
  // ============================================================
  // Estos getters leen datos de TrainingProfile.extra que son capturados
  // en la UI de evaluación y usados por VolumeIndividualizationService
  // para calcular VME (Volumen Máximo Efectivo) y VMR (Volumen Máximo Recuperable)

  /// Años de entrenamiento continuo (lee primero de TrainingExtraKeys, luego TrainingInterviewKeys)
  int get yearsTrainingContinuousResolved {
    final v =
        extra[TrainingExtraKeys.trainingYears] ??
        extra[TrainingInterviewKeys.yearsTrainingContinuous];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  /// Años de entrenamiento continuo (legacy, mantiene compatibilidad)
  int get yearsTraining =>
      extra[TrainingInterviewKeys.yearsTrainingContinuous] as int? ?? 0;

  /// Horas promedio de sueño (lee primero de TrainingExtraKeys, luego TrainingInterviewKeys)
  double get avgSleepHoursResolved {
    final v =
        extra[TrainingExtraKeys.avgSleepHours] ??
        extra[TrainingInterviewKeys.avgSleepHours];
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0.0;
  }

  /// Horas promedio de sueño (para cálculos de VMR) (legacy)
  double get avgSleepHoursFromExtra =>
      (extra[TrainingInterviewKeys.avgSleepHours] ?? avgSleepHours ?? 7.0)
          .toDouble();

  /// Duración de sesión en minutos (lee primero de TrainingExtraKeys, luego TrainingInterviewKeys)
  int get sessionDurationMinutesResolved {
    final v =
        extra[TrainingExtraKeys.timePerSessionMinutes] ??
        extra[TrainingInterviewKeys.sessionDurationMinutes];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  /// Descanso entre series en segundos (lee primero de TrainingExtraKeys, luego TrainingInterviewKeys)
  int get restBetweenSetsSecondsResolved {
    final v =
        extra[TrainingExtraKeys.restBetweenSetsSeconds] ??
        extra[TrainingInterviewKeys.restBetweenSetsSeconds];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  /// Capacidad de trabajo (escala 1-5)
  int get workCapacity =>
      extra[TrainingInterviewKeys.workCapacity] as int? ?? 3;

  /// Historial de recuperación (escala 1-5)
  int get recoveryHistory =>
      extra[TrainingInterviewKeys.recoveryHistory] as int? ?? 3;

  /// Soporte externo de recuperación (masajes, fisio, etc.)
  bool get externalRecovery =>
      extra[TrainingInterviewKeys.externalRecovery] as bool? ?? false;

  /// Novedad del programa (enum ProgramNovelty)
  ProgramNovelty? get programNovelty {
    final value = extra[TrainingInterviewKeys.programNovelty];
    if (value == null) return null;
    try {
      return ProgramNovelty.values.byName(value.toString());
    } catch (_) {
      return null;
    }
  }

  /// Estrés físico externo (enum InterviewStressLevel)
  InterviewStressLevel? get physicalStress {
    final value = extra[TrainingInterviewKeys.physicalStress];
    if (value == null) return null;
    try {
      return InterviewStressLevel.values.byName(value.toString());
    } catch (_) {
      return null;
    }
  }

  /// Estrés no físico (mental, emocional) (enum InterviewStressLevel)
  InterviewStressLevel? get nonPhysicalStress {
    final value = extra[TrainingInterviewKeys.nonPhysicalStress];
    if (value == null) return null;
    try {
      return InterviewStressLevel.values.byName(value.toString());
    } catch (_) {
      return null;
    }
  }

  /// Calidad del descanso/sueño (enum InterviewRestQuality)
  InterviewRestQuality? get restQualityEnum {
    final value = extra[TrainingInterviewKeys.restQuality];
    if (value == null) return null;
    try {
      return InterviewRestQuality.values.byName(value.toString());
    } catch (_) {
      return null;
    }
  }

  /// Calidad de la dieta (enum DietQuality)
  DietQuality? get dietQuality {
    final value = extra[TrainingInterviewKeys.dietQuality];
    if (value == null) return null;
    try {
      return DietQuality.values.byName(value.toString());
    } catch (_) {
      return null;
    }
  }

  /// Serialización desde JSON / Map (para DB local o remoto).
  factory TrainingProfile.fromJson(Map<String, dynamic> json) {
    // Helper genérico para listas de String
    List<String> stringList(dynamic v) {
      if (v == null) return <String>[];
      if (v is List) {
        return v.map((e) => e.toString()).toList();
      }
      if (v is String) {
        return v
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return <String>[];
    }

    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    int parseMinutes(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      final match = RegExp(r'\d+').firstMatch(v.toString());
      return match == null ? 0 : (int.tryParse(match.group(0)!) ?? 0);
    }

    // Helper para Map<String, int>
    Map<String, int> mapStringInt(dynamic v) {
      if (v == null || v is! Map) return <String, int>{};
      return v.map((key, value) {
        final k = key.toString();
        final intVal = value is int
            ? value
            : (value is num
                  ? value.toInt()
                  : int.tryParse(value.toString()) ?? 0);
        return MapEntry(k, intVal);
      });
    }

    // Helper para Map<String, Map<String, double>>
    Map<String, Map<String, double>> mapSeriesDist(dynamic v) {
      if (v == null || v is! Map) return <String, Map<String, double>>{};
      return v.map((key, value) {
        final k = key.toString();
        if (value is Map) {
          final inner = value.map((ik, iv) {
            final innerKey = ik.toString();
            final doubleVal = iv is double
                ? iv
                : (iv is num
                      ? iv.toDouble()
                      : double.tryParse(iv.toString()) ?? 0.0);
            return MapEntry(innerKey, doubleVal);
          });
          return MapEntry(k, inner);
        }
        return MapEntry(k, <String, double>{});
      });
    }

    // Helper para Map<String, VolumeToleranceProfile>
    Map<String, VolumeToleranceProfile> mapTolerance(dynamic v) {
      if (v == null || v is! Map) return <String, VolumeToleranceProfile>{};
      final result = <String, VolumeToleranceProfile>{};
      v.forEach((key, value) {
        final k = key.toString();
        if (value is Map<String, dynamic>) {
          result[k] = VolumeToleranceProfile.fromJson(value);
        } else if (value is Map) {
          result[k] = VolumeToleranceProfile.fromJson(
            value.cast<String, dynamic>(),
          );
        }
      });
      return result;
    }

    // Helper enum TrainingGoal
    TrainingGoal parseGoal(dynamic v) {
      if (v == null) return TrainingGoal.generalFitness;
      final asString = v.toString();
      try {
        return TrainingGoal.values.firstWhere(
          (e) => e.name == asString || e.toString().split('.').last == asString,
        );
      } catch (_) {
        return TrainingGoal.generalFitness;
      }
    }

    // Helper enum TrainingFocus (puede ser null)
    TrainingFocus? parseFocus(dynamic v) {
      if (v == null) return null;
      final asString = v.toString();
      try {
        return TrainingFocus.values.firstWhere(
          (e) => e.name == asString || e.toString().split('.').last == asString,
        );
      } catch (_) {
        return null;
      }
    }

    // Helper enum TrainingLevel (puede ser null)
    // PRIORIDAD: 1) enum.name directo, 2) parseTrainingLevel (labels humanos)
    TrainingLevel? parseLevel(dynamic v) {
      if (v == null) return null;
      final asString = v.toString();

      // Intento 1: enum.name directo (beginner, intermediate, advanced)
      try {
        return TrainingLevel.values.firstWhere(
          (e) => e.name == asString || e.toString().split('.').last == asString,
        );
      } catch (_) {
        // Intento 2: parsear labels humanos complejos
        return parseTrainingLevel(asString);
      }
    }

    // Helper enum Gender (puede ser null)
    Gender? parseGender(dynamic v) {
      if (v == null) return null;
      final asString = v.toString();
      try {
        return Gender.values.firstWhere(
          (e) => e.name == asString || e.toString().split('.').last == asString,
        );
      } catch (_) {
        return null;
      }
    }

    // --- LÓGICA DE MIGRACIÓN (Sync-Bridge) ---
    // 1. Leemos 'extra' para buscar datos antiguos

    // 2. Helper para leer de top-level O de extra (Fallback)

    // CRITICAL FIX: Manejar extra tanto como JSON string (SQLite) como Map (Firestore)
    final extraMap = (() {
      final raw = json['extra'];
      if (raw == null) return <String, dynamic>{};

      if (raw is String) {
        try {
          return Map<String, dynamic>.from(jsonDecode(raw) as Map);
        } catch (_) {
          return <String, dynamic>{};
        }
      }

      if (raw is Map) {
        return Map<String, dynamic>.from(raw);
      }

      return <String, dynamic>{};
    })();

    final resolvedEquipment = (() {
      final primary = stringList(json['equipment']);
      if (primary.isNotEmpty) return primary;
      return stringList(extraMap[TrainingExtraKeys.availableEquipment]);
    })();

    final resolvedMovementRestrictions = stringList(
      json['movementRestrictions'] ??
          extraMap[TrainingExtraKeys.movementRestrictions],
    );

    final rawDaysPerWeek = parseInt(json['daysPerWeek']);
    final resolvedDaysPerWeek = rawDaysPerWeek > 0
        ? rawDaysPerWeek
        : parseInt(extraMap['daysPerWeek']);

    final rawTimePerSession = parseMinutes(json['timePerSessionMinutes']);
    final resolvedTimePerSessionMinutes = rawTimePerSession > 0
        ? rawTimePerSession
        : parseMinutes(
            extraMap['timePerSession'] ?? extraMap['timePerSessionMinutes'],
          );

    final resolvedTrainingLevel =
        parseLevel(json['trainingLevel']) ??
        parseLevel(extraMap['trainingLevel']?.toString()) ??
        parseTrainingLevel(extraMap['trainingLevelLabel']?.toString()) ??
        parseTrainingLevel(extraMap['trainingLevel']?.toString());

    final rawBaseVolume = mapStringInt(json['baseVolumePerMuscle']);
    final resolvedBaseVolumePerMuscle = rawBaseVolume.isNotEmpty
        ? rawBaseVolume
        : mapStringInt(
            extraMap['baseSeries'] ?? extraMap['baseVolumePerMuscle'],
          );

    final rawSeriesDistribution = mapSeriesDist(json['seriesDistribution']);
    final resolvedSeriesDistribution = rawSeriesDistribution.isNotEmpty
        ? rawSeriesDistribution
        : mapSeriesDist(extraMap['seriesDistribution']);

    final rawBlockLength = parseInt(json['blockLengthWeeks']);
    final resolvedBlockLengthWeeks = rawBlockLength > 0
        ? rawBlockLength
        : parseInt(
            extraMap['planDurationInWeeks'] ?? extraMap['blockLengthWeeks'],
          );

    final rawPrimary = stringList(json['priorityMusclesPrimary']);
    final rawSecondary = stringList(json['priorityMusclesSecondary']);
    final rawTertiary = stringList(json['priorityMusclesTertiary']);
    final resolvedPriorityMusclesPrimary = rawPrimary.isNotEmpty
        ? rawPrimary
        : stringList(extraMap['priorityMusclesPrimary']);
    final resolvedPriorityMusclesSecondary = rawSecondary.isNotEmpty
        ? rawSecondary
        : stringList(extraMap['priorityMusclesSecondary']);
    final resolvedPriorityMusclesTertiary = rawTertiary.isNotEmpty
        ? rawTertiary
        : stringList(extraMap['priorityMusclesTertiary']);

    final resolvedIsCompetitor =
        (extraMap['isCompetitor'] ?? json['isCompetitor']) == true;
    final resolvedUsesAnabolics =
        (extraMap['usesAnabolics'] ?? json['usesAnabolics']) == true;
    final resolvedCompetitionCategory =
        (extraMap['competitionCategory'] ?? json['competitionCategory'])
            ?.toString();
    final resolvedPharmacologyProtocol =
        (extraMap['pharmacologyProtocol'] ?? json['pharmacologyProtocol'])
            ?.toString();
    final resolvedPeakWeekHistory =
        (extraMap['peakWeekHistory'] ?? json['peakWeekHistory'])?.toString();
    final resolvedAvgSleepHours =
        parseDouble(extraMap['avgSleepHours'] ?? json['avgSleepHours']) ?? 0.0;

    final resolvedYearsTrainingContinuous = parseInt(
      json['yearsTrainingContinuous'] ??
          extraMap[TrainingInterviewKeys.yearsTrainingContinuous],
    );
    final resolvedSessionDurationMinutes = parseInt(
      json['sessionDurationMinutes'] ??
          extraMap[TrainingInterviewKeys.sessionDurationMinutes],
    );
    final resolvedRestBetweenSetsSeconds = parseInt(
      json['restBetweenSetsSeconds'] ??
          extraMap[TrainingInterviewKeys.restBetweenSetsSeconds],
    );
    final resolvedPerceivedStress =
        (extraMap['perceivedStress'] ?? json['perceivedStress'])?.toString();
    final resolvedRecoveryQuality =
        (extraMap['recoveryQuality'] ?? json['recoveryQuality'])?.toString();

    return TrainingProfile(
      id: json['id']?.toString(),
      date: json['date'] == null
          ? null
          : DateTime.tryParse(json['date'].toString()),
      gender: parseGender(json['gender']),
      age: json['age'] is int
          ? json['age'] as int
          : int.tryParse('${json['age']}'),
      bodyWeight: json['bodyWeight'] == null
          ? null
          : (json['bodyWeight'] is num
                ? (json['bodyWeight'] as num).toDouble()
                : double.tryParse(json['bodyWeight'].toString())),
      isCompetitor: resolvedIsCompetitor,
      competitionCategory: resolvedCompetitionCategory,
      usesAnabolics: resolvedUsesAnabolics,
      pharmacologyProtocol: resolvedPharmacologyProtocol,
      peakWeekHistory: resolvedPeakWeekHistory,
      globalGoal: parseGoal(json['globalGoal']),
      trainingFocus: parseFocus(json['trainingFocus']),
      trainingLevel: resolvedTrainingLevel,
      daysPerWeek: resolvedDaysPerWeek,
      timePerSessionMinutes: resolvedTimePerSessionMinutes,
      yearsTrainingContinuous: resolvedYearsTrainingContinuous,
      sessionDurationMinutes: resolvedSessionDurationMinutes,
      restBetweenSetsSeconds: resolvedRestBetweenSetsSeconds,
      avgSleepHours: resolvedAvgSleepHours,
      equipment: resolvedEquipment,
      movementRestrictions: resolvedMovementRestrictions,
      perceivedStress: resolvedPerceivedStress,
      recoveryQuality: resolvedRecoveryQuality,
      sorenessLevel: json['sorenessLevel'] == null
          ? null
          : (json['sorenessLevel'] is num
                ? (json['sorenessLevel'] as num).toDouble()
                : double.tryParse(json['sorenessLevel'].toString())),
      motivationLevel: json['motivationLevel'] == null
          ? null
          : (json['motivationLevel'] is num
                ? (json['motivationLevel'] as num).toDouble()
                : double.tryParse(json['motivationLevel'].toString())),
      priorityMusclesPrimary: resolvedPriorityMusclesPrimary,
      priorityMusclesSecondary: resolvedPriorityMusclesSecondary,
      priorityMusclesTertiary: resolvedPriorityMusclesTertiary,
      baseVolumePerMuscle: resolvedBaseVolumePerMuscle,
      seriesDistribution: resolvedSeriesDistribution,
      pastVolumeTolerance: mapTolerance(json['pastVolumeTolerance']),
      blockLengthWeeks: resolvedBlockLengthWeeks > 0
          ? resolvedBlockLengthWeeks
          : 4,
      currentWeekIndex: json['currentWeekIndex'] is int
          ? json['currentWeekIndex'] as int
          : (int.tryParse('${json['currentWeekIndex']}') ?? 0),
      extra: extraMap,
      prSquat: json['prSquat']?.toString(),
      prBench: json['prBench']?.toString(),
      prDeadlift: json['prDeadlift']?.toString(),
    );
  }

  // Mantenemos toJson manual para consistencia con el fromJson manual
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date?.toIso8601String(),
      'gender': gender?.name,
      'age': age,
      'bodyWeight': bodyWeight,
      'isCompetitor': isCompetitor,
      'competitionCategory': competitionCategory,
      'usesAnabolics': usesAnabolics,
      'pharmacologyProtocol': pharmacologyProtocol,
      'peakWeekHistory': peakWeekHistory,
      'globalGoal': globalGoal.name,
      'trainingFocus': trainingFocus?.name,
      'trainingLevel': trainingLevel?.name,
      'daysPerWeek': daysPerWeek,
      'timePerSessionMinutes': timePerSessionMinutes,
      'yearsTrainingContinuous': yearsTrainingContinuous,
      'sessionDurationMinutes': sessionDurationMinutes,
      'restBetweenSetsSeconds': restBetweenSetsSeconds,
      'avgSleepHours': avgSleepHours,
      'equipment': equipment,
      'movementRestrictions': movementRestrictions,
      'perceivedStress': perceivedStress,
      'recoveryQuality': recoveryQuality,
      'sorenessLevel': sorenessLevel,
      'motivationLevel': motivationLevel,
      'priorityMusclesPrimary': priorityMusclesPrimary,
      'priorityMusclesSecondary': priorityMusclesSecondary,
      'priorityMusclesTertiary': priorityMusclesTertiary,
      'baseVolumePerMuscle': baseVolumePerMuscle,
      'seriesDistribution': seriesDistribution,
      'pastVolumeTolerance': pastVolumeTolerance.map(
        (k, v) => MapEntry(k, v.toJson()),
      ),
      'blockLengthWeeks': blockLengthWeeks,
      'currentWeekIndex': currentWeekIndex,
      'extra': _safeExtraMap(),
      'prSquat': prSquat,
      'prBench': prBench,
      'prDeadlift': prDeadlift,
    };
  }

  /// Retorna extra como Map seguro para Firestore/SQLite (no String)
  /// Filtra valores no-serializables de forma conservadora
  Map<String, dynamic> _safeExtraMap() {
    final safe = <String, dynamic>{};

    void putSafe(String key, dynamic value) {
      if (value == null ||
          value is String ||
          value is int ||
          value is double ||
          value is bool) {
        safe[key] = value;
        return;
      }

      if (value is Map) {
        // Map anidado: hacemos una copia segura
        safe[key] = Map<String, dynamic>.from(
          value.map((k, v) => MapEntry(k.toString(), v)),
        );
        return;
      }

      if (value is List) {
        safe[key] = value;
        return;
      }

      // fallback: string (último recurso)
      safe[key] = value.toString();
    }

    extra.forEach(putSafe);
    return safe;
  }

  TrainingProfile normalizedFromExtra() {
    if (extra.isEmpty) return _withNormalizedMuscles();
    try {
      final resolved = TrainingProfile.fromJson(toJson());
      return resolved._withNormalizedMuscles();
    } catch (e) {
      // Si hay error en la re-serialización, simplemente retorna normalized sin cambios
      // Esto evita crashes al renderizar cuando hay datos legados inconsistentes
      return _withNormalizedMuscles();
    }
  }

  /// Normaliza nombres de músculos (pecho/espalda/glúteos…) a claves canónicas
  /// en inglés para que fases 3–6 del motor encuentren día/músculo y sets.
  TrainingProfile _withNormalizedMuscles() {
    List<String> normList(List<String> raw) {
      return raw
          .map(_normalizeMuscleKey)
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
    }

    Map<String, int> normBaseVolume(Map<String, int> raw) {
      final out = <String, int>{};
      raw.forEach((k, v) {
        final nk = _normalizeMuscleKey(k);
        if (nk.isEmpty) return;
        out[nk] = (out[nk] ?? 0) + v;
      });
      return out;
    }

    Map<String, Map<String, double>> normSeriesDist(
      Map<String, Map<String, double>> raw,
    ) {
      final out = <String, Map<String, double>>{};
      raw.forEach((k, v) {
        final nk = _normalizeMuscleKey(k);
        if (nk.isEmpty) return;
        out[nk] = v;
      });
      return out;
    }

    Map<String, VolumeToleranceProfile> normTolerance(
      Map<String, VolumeToleranceProfile> raw,
    ) {
      final out = <String, VolumeToleranceProfile>{};
      raw.forEach((k, v) {
        final nk = _normalizeMuscleKey(k);
        if (nk.isEmpty) return;
        out[nk] = v;
      });
      return out;
    }

    return copyWith(
      priorityMusclesPrimary: normList(priorityMusclesPrimary),
      priorityMusclesSecondary: normList(priorityMusclesSecondary),
      priorityMusclesTertiary: normList(priorityMusclesTertiary),
      baseVolumePerMuscle: normBaseVolume(baseVolumePerMuscle),
      seriesDistribution: normSeriesDist(seriesDistribution),
      pastVolumeTolerance: normTolerance(pastVolumeTolerance),
    );
  }

  static String _normalizeMuscleKey(String raw) {
    final key = raw.toLowerCase().trim();
    if (key.isEmpty) return '';

    const map = {
      // Pecho / espalda / hombro
      'pecho': 'chest',
      'pectorales': 'chest',
      'espalda': 'back',
      'espalda alta': 'back',
      'dorsales': 'back',
      'dorsal': 'back',
      'dorsal ancho': 'back',
      'hombros': 'shoulders',
      'deltoides': 'shoulders',
      'deltoide': 'shoulders',

      // Brazos
      'biceps': 'biceps',
      'bíceps': 'biceps',
      'triceps': 'triceps',
      'tríceps': 'triceps',
      'antebrazo': 'forearms',
      'antebrazos': 'forearms',

      // Piernas
      'cuadriceps': 'quads',
      'cuádriceps': 'quads',
      'quads': 'quads',
      'isquios': 'hamstrings',
      'isquiotibiales': 'hamstrings',
      'femorales': 'hamstrings',
      'gluteos': 'glutes',
      'glúteos': 'glutes',
      'gluteo': 'glutes',
      'glúteo': 'glutes',
      'pantorrillas': 'calves',
      'pantorrilla': 'calves',
      'gemelos': 'calves',

      // Core
      'abs': 'abs',
      'abdomen': 'abs',
      'abdominales': 'abs',
      'core': 'abs',

      // Traps
      'trapecio': 'traps',
      'trapecios': 'traps',

      // Lats
      'lats': 'lats',
      'laterales': 'lats',
    };

    // Si ya es clave conocida, mantenerla
    const canonical = {
      'chest',
      'back',
      'lats',
      'traps',
      'shoulders',
      'biceps',
      'triceps',
      'forearms',
      'quads',
      'hamstrings',
      'glutes',
      'calves',
      'abs',
    };

    if (canonical.contains(key)) {
      return key;
    }
    final mapped = map[key];
    return mapped ??
        ''; // NO fallback: devolver vacío para claves no soportadas
  }

  TrainingProfile copyWith({
    String? id,
    DateTime? date,
    Gender? gender,
    int? age,
    double? bodyWeight,
    bool? isCompetitor,
    String? competitionCategory,
    bool? usesAnabolics,
    String? pharmacologyProtocol,
    String? peakWeekHistory,
    TrainingGoal? globalGoal,
    TrainingFocus? trainingFocus,
    TrainingLevel? trainingLevel,
    int? daysPerWeek,
    int? timePerSessionMinutes,
    int? yearsTrainingContinuous,
    int? sessionDurationMinutes,
    int? restBetweenSetsSeconds,
    double? avgSleepHours,
    List<String>? equipment,
    String? perceivedStress,
    String? recoveryQuality,
    double? sorenessLevel,
    double? motivationLevel,
    List<String>? priorityMusclesPrimary,
    List<String>? priorityMusclesSecondary,
    List<String>? priorityMusclesTertiary,
    Map<String, int>? baseVolumePerMuscle,
    Map<String, Map<String, double>>? seriesDistribution,
    Map<String, VolumeToleranceProfile>? pastVolumeTolerance,
    int? blockLengthWeeks,
    int? currentWeekIndex,
    Map<String, dynamic>? extra,
    String? prSquat,
    String? prBench,
    String? prDeadlift,
  }) {
    return TrainingProfile(
      id: id ?? this.id,
      date: date ?? this.date,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      bodyWeight: bodyWeight ?? this.bodyWeight,
      isCompetitor: isCompetitor ?? this.isCompetitor,
      competitionCategory: competitionCategory ?? this.competitionCategory,
      usesAnabolics: usesAnabolics ?? this.usesAnabolics,
      pharmacologyProtocol: pharmacologyProtocol ?? this.pharmacologyProtocol,
      peakWeekHistory: peakWeekHistory ?? this.peakWeekHistory,
      globalGoal: globalGoal ?? this.globalGoal,
      trainingFocus: trainingFocus ?? this.trainingFocus,
      trainingLevel: trainingLevel ?? this.trainingLevel,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      timePerSessionMinutes:
          timePerSessionMinutes ?? this.timePerSessionMinutes,
      yearsTrainingContinuous:
          yearsTrainingContinuous ?? this.yearsTrainingContinuous,
      sessionDurationMinutes:
          sessionDurationMinutes ?? this.sessionDurationMinutes,
      restBetweenSetsSeconds:
          restBetweenSetsSeconds ?? this.restBetweenSetsSeconds,
      avgSleepHours: avgSleepHours ?? this.avgSleepHours,
      equipment: equipment ?? this.equipment,
      perceivedStress: perceivedStress ?? this.perceivedStress,
      recoveryQuality: recoveryQuality ?? this.recoveryQuality,
      sorenessLevel: sorenessLevel ?? this.sorenessLevel,
      motivationLevel: motivationLevel ?? this.motivationLevel,
      priorityMusclesPrimary:
          priorityMusclesPrimary ?? this.priorityMusclesPrimary,
      priorityMusclesSecondary:
          priorityMusclesSecondary ?? this.priorityMusclesSecondary,
      priorityMusclesTertiary:
          priorityMusclesTertiary ?? this.priorityMusclesTertiary,
      baseVolumePerMuscle: baseVolumePerMuscle ?? this.baseVolumePerMuscle,
      seriesDistribution: seriesDistribution ?? this.seriesDistribution,
      pastVolumeTolerance: pastVolumeTolerance ?? this.pastVolumeTolerance,
      blockLengthWeeks: blockLengthWeeks ?? this.blockLengthWeeks,
      currentWeekIndex: currentWeekIndex ?? this.currentWeekIndex,
      // CRITICAL: Deep merge extra maps to preserve nested Maps (mevByMuscle, etc.)
      extra: extra != null ? deepMerge(this.extra, extra) : this.extra,
      prSquat: prSquat ?? this.prSquat,
      prBench: prBench ?? this.prBench,
      prDeadlift: prDeadlift ?? this.prDeadlift,
    );
  }

  @override
  List<Object?> get props => [
    id,
    date,
    gender,
    age,
    bodyWeight,
    isCompetitor,
    competitionCategory,
    usesAnabolics,
    pharmacologyProtocol,
    peakWeekHistory,
    globalGoal,
    trainingFocus,
    trainingLevel,
    daysPerWeek,
    timePerSessionMinutes,
    yearsTrainingContinuous,
    sessionDurationMinutes,
    restBetweenSetsSeconds,
    avgSleepHours,
    equipment,
    perceivedStress,
    recoveryQuality,
    sorenessLevel,
    motivationLevel,
    priorityMusclesPrimary,
    priorityMusclesSecondary,
    priorityMusclesTertiary,
    baseVolumePerMuscle,
    seriesDistribution,
    pastVolumeTolerance,
    blockLengthWeeks,
    currentWeekIndex,
    extra,
    prSquat,
    prBench,
    prDeadlift,
  ];
}
