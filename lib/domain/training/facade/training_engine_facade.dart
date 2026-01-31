import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/domain/entities/training_plan_config.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/entities/training_session.dart';
import 'package:hcs_app_lap/domain/entities/training_week.dart';
import 'package:hcs_app_lap/domain/services/training_program_engine.dart';
import 'package:hcs_app_lap/data/repositories/client_repository.dart';
import 'package:hcs_app_lap/core/constants/muscle_keys.dart';
import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';

/// Fachada de acceso único al motor de entrenamiento (8 fases).
///
/// INVARIANTE CRÍTICO:
/// - UI y providers SOLO pueden importar este archivo
/// - Ningún llamador directo a TrainingProgramEngine, Phase*, o pipelines legacy
/// - Garantiza contrato estable y permite refactoring interno sin romper UI
///
/// Entrypoint único para generación de planes de entrenamiento.
///
/// Esta clase actúa como Facade: oculta complejidad del motor (8 fases) y expone
/// una API simple. UI/providers importan SOLO esta clase.
class TrainingEngineFacade {
  static final TrainingEngineFacade _instance = TrainingEngineFacade._();

  final TrainingProgramEngine _engine = TrainingProgramEngine();

  TrainingEngineFacade._();

  factory TrainingEngineFacade() => _instance;

  /// Genera plan de entrenamiento completo (8 fases) y lo persiste obligatoriamente.
  ///
  /// ENTRADA:
  /// - planId, clientId, planName: Metadatos del plan
  /// - startDate: Fecha de inicio
  /// - profile: Perfil del cliente (trainingLevel, daysPerWeek, etc.)
  /// - client: Cliente completo que será actualizado y persistido
  /// - repository: Repositorio para guardar el cliente con plan persistido
  /// - exercises: Catálogo de ejercicios disponibles
  ///
  /// SALIDA: TrainingPlanConfig con semanas, sesiones, prescripciones
  /// GARANTÍA: El plan retornado YA está persistido en `client.trainingPlans` vía repositorio
  ///
  /// COMPORTAMIENTO:
  /// - Ejecuta 8 fases deterministas
  /// - Persiste el plan en client.trainingPlans (usando fecha como clave lógica)
  /// - Guarda el cliente actualizado en repositorio ANTES de retornar
  /// - Puede lanzar StateError si datos críticos faltan (fail-fast)
  /// - Persiste trace de decisiones en snapshot.extra['decisionTraceRecords']
  Future<TrainingPlanConfig> generatePlan({
    required String planId,
    required String clientId,
    required String planName,
    required DateTime startDate,
    required TrainingProfile profile,
    required Client client,
    required ClientRepository repository,
    List<dynamic>? exercises,
  }) async {
    // Fail-fast explícito si el catálogo está vacío
    if (exercises == null || exercises.isEmpty) {
      throw Exception(
        'Catálogo de ejercicios vacío. Verifica asset en assets/data/exercises/exercise_catalog_gym.json y pubspec.yaml',
      );
    }

    // Cast seguro: convertir List<dynamic> a List<Exercise>
    final exerciseList = exercises.whereType<Exercise>().toList();

    if (exerciseList.isEmpty) {
      throw Exception(
        'Error de tipo: exercises no contiene objetos Exercise válidos. Tipo recibido: ${exercises.runtimeType}',
      );
    }

    // Generar plan vía motor
    final planConfig = _engine.generatePlan(
      planId: planId,
      clientId: clientId,
      planName: planName,
      startDate: startDate,
      profile: profile,
      client: client,
      exercises: exerciseList,
    );

    // ═══════════════════════════════════════════════════════════════════════
    // NORMALIZACIÓN: Garantizar estructura de training.extra consistente
    // ═══════════════════════════════════════════════════════════════════════
    final normalizedExtra = _normalizeTrainingExtra(
      planConfig.trainingProfileSnapshot?.extra ?? {},
    );

    // ═══════════════════════════════════════════════════════════════════════
    // ADAPTACIÓN: Mapear output normalizado a estructura legacy que UI espera
    // ═══════════════════════════════════════════════════════════════════════
    final legacyExtra = _mapMotorOutputToLegacyExtra(normalizedExtra);

    final normalizedSnapshot =
        planConfig.trainingProfileSnapshot?.copyWith(extra: legacyExtra) ??
        planConfig.trainingProfileSnapshot;

    // Crear plan con snapshot adaptado a legacy
    final normalizedPlanConfig = normalizedSnapshot != null
        ? planConfig.copyWith(trainingProfileSnapshot: normalizedSnapshot)
        : planConfig;

    // ═══════════════════════════════════════════════════════════════════════
    // PERSISTENCIA OBLIGATORIA: Insertar o sobrescribir en client.trainingPlans
    // ═══════════════════════════════════════════════════════════════════════

    // 1. Obtener planes existentes
    final updatedTrainingPlans =
        List<TrainingPlanConfig>.from(client.trainingPlans)
          // Sobrescribir plan con la misma fecha (misma fecha = mismo plan)
          ..removeWhere(
            (p) =>
                p.startDate.year == startDate.year &&
                p.startDate.month == startDate.month &&
                p.startDate.day == startDate.day,
          )
          // Agregar plan normalizado
          ..add(normalizedPlanConfig);

    // 2. Actualizar referencias a semanas y sesiones
    final newWeekIds = normalizedPlanConfig.weeks.map((w) => w.id).toSet();
    final updatedTrainingWeeks = List<TrainingWeek>.from(client.trainingWeeks)
      // Remover semanas antiguas del mismo plan
      ..removeWhere((w) => newWeekIds.contains(w.id))
      // Agregar semanas nuevas
      ..addAll(normalizedPlanConfig.weeks);

    final newSessionIds = normalizedPlanConfig.weeks
        .expand((w) => w.sessions)
        .map((s) => s.id)
        .toSet();
    final updatedTrainingSessions =
        List<TrainingSession>.from(client.trainingSessions)
          // Remover sesiones antiguas del mismo plan
          ..removeWhere((s) => newSessionIds.contains(s.id))
          // Agregar sesiones nuevas
          ..addAll(normalizedPlanConfig.weeks.expand((w) => w.sessions));

    // 3. Actualizar training.extra con SSOT del ciclo: activePlanId
    final updatedExtra = Map<String, dynamic>.from(client.training.extra);
    updatedExtra[TrainingExtraKeys.activePlanId] = normalizedPlanConfig.id;

    // Nota: NO borramos nada del extra, solo escribimos activePlanId.
    final updatedTraining = client.training.copyWith(extra: updatedExtra);

    // 4. Actualizar cliente con plan + weeks + sessions + training(extra)
    final updatedClient = client.copyWith(
      training: updatedTraining,
      trainingPlans: updatedTrainingPlans,
      trainingWeeks: updatedTrainingWeeks,
      trainingSessions: updatedTrainingSessions,
    );

    // 5. GUARDAR EN REPOSITORIO (commit)
    await repository.saveClient(updatedClient);

    // 6. Retornar el plan recién generado (es el vigente por definición del SSOT)
    return normalizedPlanConfig;
  }

  /// Obtén el último trace de decisiones generadas.
  List<dynamic> get lastDecisions => _engine.lastDecisions;

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS PRIVADOS (EN ORDEN ESPECIFICADO)
  // ═══════════════════════════════════════════════════════════════════════════
  // 1. Selección (_selectLatestPlan)
  // 2. Persistencia (integrada en generatePlan)
  // 3. Normalización (_normalizeTrainingExtra)
  // 4. Mapping legacy (_mapMotorOutputToLegacyExtra)
  // 5. Normalización muscular (_canonicalizeMuscleKey, _canonicalizeMuscleMap)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Selecciona el plan más reciente de una lista (orden determinístico).
  ///
  /// ENTRADA: Lista de planes (posiblemente múltiples)
  /// SALIDA: Plan con fecha más reciente (determinístico)
  /// ERROR: StateError si la lista está vacía
  ///
  /// ALGORITMO:
  /// 1. Ordenar exclusivamente por startDate (descendente)
  /// 2. Si hay empate de fechas, mantener orden de inserción (stable sort)
  /// 3. Retornar el primero
  ///
  /// INVARIANTE:
  /// - La facade es la única autoridad sobre qué plan es vigente
  /// - Nadie más decide en la UI o providers
  // ignore: unused_element
  @Deprecated('Use activePlanId from SSOT instead')
  // ignore: unused_element
  TrainingPlanConfig _selectLatestPlan(List<TrainingPlanConfig> plans) {
    if (plans.isEmpty) {
      throw StateError('No training plans available for selection');
    }

    // Ordenar por fecha descendente (más reciente primero)
    final sorted = List<TrainingPlanConfig>.from(plans)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    return sorted.first;
  }

  /// Normaliza training.extra para garantizar estructura consistente
  /// que la UI espera. Crea claves faltantes con estructuras vacías válidas.
  ///
  /// INVARIANTE:
  /// - Nunca retorna null para claves esperadas
  /// - Crea estructura vacía si falta (no inventa valores)
  /// - Mantiene claves existentes sin cambios
  Map<String, dynamic> _normalizeTrainingExtra(Map<String, dynamic> rawExtra) {
    final normalized = Map<String, dynamic>.from(rawExtra);

    // ═══════════════════════════════════════════════════════════════════════
    // GARANTIZAR ESTRUCTURA DE CLAVES UI ESPERADAS
    // ═══════════════════════════════════════════════════════════════════════

    // ✅ Tab 1: Volumen (VME / VMR / Primario / Secundario / Terciario)
    normalized.putIfAbsent('mevByMuscle', () => <String, double>{});
    normalized.putIfAbsent('mrvByMuscle', () => <String, double>{});
    normalized.putIfAbsent('targetSetsByMuscleUi', () => <String, double>{});
    normalized.putIfAbsent(
      'finalTargetSetsByMuscleUi',
      () => <String, double>{},
    );
    normalized.putIfAbsent('priorityMusclesPrimary', () => '');
    normalized.putIfAbsent('priorityMusclesSecondary', () => '');
    normalized.putIfAbsent('priorityMusclesTertiary', () => '');

    // ✅ Tab 2: Intensidad (pesadas / medias / ligeras)
    normalized.putIfAbsent(
      'seriesTypePercentSplit',
      () => const {'heavy': 0.40, 'medium': 0.40, 'light': 0.20},
    );
    normalized.putIfAbsent('intensityProfiles', () => <String, dynamic>{});
    normalized.putIfAbsent('weeklyVolumeHistory', () => <dynamic>[]);

    // ✅ Tab 3: Macrociclo
    normalized.putIfAbsent('macroPlan', () => <String, dynamic>{});
    normalized.putIfAbsent('vopSnapshot', () => <String, dynamic>{});

    // ✅ Tab 4: Plan semanal
    normalized.putIfAbsent('weeklySplitTemplateId', () => '');
    normalized.putIfAbsent('weeklyPlanOverrides', () => <String, dynamic>{});

    // ✅ Metadata y referencias
    normalized.putIfAbsent('trainingExtraVersion', () => 'v1');
    normalized.putIfAbsent('targetSetsByMuscle', () => <String, int>{});

    return normalized;
  }

  /// Mapea output normalizado del motor a estructura legacy que UI consume.
  ///
  /// RESPONSABILIDAD:
  /// - Tomar normalized extra (ya con todas las claves)
  /// - Reubicar/renombrar según expectativas legacy de UI
  /// - Canonicalizar nombres musculares en mapas
  /// - Crear estructuras vacías válidas si combinación no existe
  /// - Nunca retornar null para claves esperadas
  ///
  /// INVARIANTE:
  /// - Entrada: normalized extra (completo)
  /// - Salida: legacy extra que UI espera consumir (musculos canonicalizados)
  /// - UI NO debe saber que existe v2 (toda conversión aquí)
  Map<String, dynamic> _mapMotorOutputToLegacyExtra(
    Map<String, dynamic> normalizedExtra,
  ) {
    final legacy = Map<String, dynamic>.from(normalizedExtra);

    // ═══════════════════════════════════════════════════════════════════════
    // NORMALIZACIÓN CANÓNICA: Asegurar nombres musculares consistentes
    // ═══════════════════════════════════════════════════════════════════════

    // ✅ Canonicalizar mapas muscular-clave (eliminada duplicación)
    legacy['mevByMuscle'] = _canonicalizeMuscleMap(
      legacy['mevByMuscle'] as Map<String, dynamic>?,
    );
    legacy['mrvByMuscle'] = _canonicalizeMuscleMap(
      legacy['mrvByMuscle'] as Map<String, dynamic>?,
    );
    legacy['targetSetsByMuscleUi'] = _canonicalizeMuscleMap(
      legacy['targetSetsByMuscleUi'] as Map<String, dynamic>?,
    );
    legacy['finalTargetSetsByMuscleUi'] = _canonicalizeMuscleMap(
      legacy['finalTargetSetsByMuscleUi'] as Map<String, dynamic>?,
    );
    legacy['targetSetsByMuscle'] = _canonicalizeMuscleMap(
      legacy['targetSetsByMuscle'] as Map<String, dynamic>?,
    );

    // ═══════════════════════════════════════════════════════════════════════
    // MAPEOS DETERMINÍSTICOS: Normalizado → Legacy
    // ═══════════════════════════════════════════════════════════════════════

    // ✅ Tab 2: Intensidad - Mapeos de estructura
    // seriesTypePercentSplit: { 'heavy': %, 'medium': %, 'light': % }
    // Ya normalizado con valores por defecto 40-40-20
    final seriesSplit = legacy['seriesTypePercentSplit'] as Map?;
    if (seriesSplit != null) {
      // Convertir valores si son int a double para coherencia
      final cleaned = <String, dynamic>{};
      seriesSplit.forEach((k, v) {
        cleaned[k.toString()] = (v as num).toDouble();
      });
      legacy['seriesTypePercentSplit'] = cleaned;
    } else {
      // Fallback: default split si falta
      legacy['seriesTypePercentSplit'] = {
        'heavy': 0.40,
        'medium': 0.40,
        'light': 0.20,
      };
    }

    // ✅ Canonicalizar intensityProfiles (Map<String, Map<priority, Map<intensity, sets>>>>)
    final rawIntensityProfiles = legacy['intensityProfiles'] as Map?;
    if (rawIntensityProfiles != null && rawIntensityProfiles.isNotEmpty) {
      final canonicalIntensityProfiles = <String, dynamic>{};
      rawIntensityProfiles.forEach((muscleKey, priorityMap) {
        final canonMuscle = _canonicalizeMuscleKey(muscleKey.toString());
        canonicalIntensityProfiles[canonMuscle] = priorityMap;
      });
      legacy['intensityProfiles'] = canonicalIntensityProfiles;
    }

    // intensityProfiles: Map<String, Map<String, int>> ya normalizado
    // (vacío si no existe)

    // weeklyVolumeHistory: List[] ya normalizado (no tiene names musculares directos)

    // ✅ Tab 3: Macrociclo - Mantener como-está
    // - macroPlan: Map ya normalizado
    // - vopSnapshot: Map ya normalizado

    // ✅ Tab 4: Plan semanal - Mantener como-está
    // - weeklySplitTemplateId: String ya normalizado
    // - weeklyPlanOverrides: Map ya normalizado

    // ✅ Metadata - Mantener como-está
    // - trainingExtraVersion: String

    return legacy;
  }

  /// Normaliza un nombre muscular a forma canónica esperada por la UI.
  ///
  /// ENTRADA: Nombre recibido del motor (puede ser variación, traducción, etc.)
  /// SALIDA: Nombre canónico según _muscleCanonicalMap
  /// FALLBACK: Si no existe en map, retorna original (no rompe)
  ///
  /// INVARIANTE: Toda clave muscular en training.extra debe pasar por este método
  String _canonicalizeMuscleKey(String rawName) {
    // Normalizar a minúsculas para búsqueda case-insensitive
    final normalized = rawName.toLowerCase().trim();

    // Buscar en map canónico
    return _muscleCanonicalMap[normalized] ?? rawName;
  }

  /// Canonicaliza todas las claves de un mapa muscular.
  ///
  /// ENTRADA: Map<String, dynamic> con claves musculares (posiblemente no canónicas)
  /// SALIDA: Nuevo map con claves canonicalizadas
  /// COMPORTAMIENTO: Retorna vacío si input es null o vacío
  ///
  /// OPTIMIZATION: Helper privado para eliminar 5x duplicación en _mapMotorOutputToLegacyExtra
  Map<String, dynamic> _canonicalizeMuscleMap(Map<String, dynamic>? rawMap) {
    if (rawMap == null || rawMap.isEmpty) {
      return <String, dynamic>{};
    }

    final canonical = <String, dynamic>{};
    rawMap.forEach((k, v) {
      final canonKey = _canonicalizeMuscleKey(k.toString());
      canonical[canonKey] = v;
    });
    return canonical;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MAPA CANÓNICO: Normalización de nombres musculares (nivel archivo)
// ═══════════════════════════════════════════════════════════════════════════
/// Mapeo determinístico de nombres musculares a forma canónica que usa la UI.
/// SSOT para normalización muscular dentro de la facade.
const Map<String, String> _muscleCanonicalMap = {
  // Deltoide frontal
  'deltoide_anterior': MuscleKeys.deltoideAnterior,
  'anterior': MuscleKeys.deltoideAnterior,
  'front': MuscleKeys.deltoideAnterior,
  'front_delt': MuscleKeys.deltoideAnterior,

  // Deltoide lateral
  'deltoide_lateral': MuscleKeys.deltoideLateral,
  'lateral': MuscleKeys.deltoideLateral,
  'side': MuscleKeys.deltoideLateral,
  'side_delt': MuscleKeys.deltoideLateral,
  'middle': MuscleKeys.deltoideLateral,

  // Deltoide posterior
  'deltoide_posterior': MuscleKeys.deltoidePosterior,
  'posterior': MuscleKeys.deltoidePosterior,
  'rear': MuscleKeys.deltoidePosterior,
  'rear_delt': MuscleKeys.deltoidePosterior,
  'back_delt': MuscleKeys.deltoidePosterior,

  // Trapecio
  'trapecio': MuscleKeys.traps,
  'traps': MuscleKeys.traps,
  'trapezius': MuscleKeys.traps,

  // Gastrocnemio / Sóleo
  'gastrocnemio': MuscleKeys.calves,
  'calves': MuscleKeys.calves,
  'calf': MuscleKeys.calves,
  'soleo': MuscleKeys.calves,
  'soleus': MuscleKeys.calves,

  // Isquiosurales
  'isquiosurales': MuscleKeys.hamstrings,
  'hamstrings': MuscleKeys.hamstrings,
  'hamstring': MuscleKeys.hamstrings,
  'ischio': MuscleKeys.hamstrings,

  // Cuádriceps
  'cuadriceps': MuscleKeys.quads,
  'quads': MuscleKeys.quads,
  'quad': MuscleKeys.quads,
  'quadriceps': MuscleKeys.quads,

  // Glúteo
  'gluteo': MuscleKeys.glutes,
  'glutes': MuscleKeys.glutes,
  'glute': MuscleKeys.glutes,
  'buttocks': MuscleKeys.glutes,

  // Pecho
  'chest': MuscleKeys.chest,
  'pecho': MuscleKeys.chest,

  // Dorsales
  'lats': MuscleKeys.lats,
  'latissimus': MuscleKeys.lats,

  // Espalda superior
  'upper_back': MuscleKeys.upperBack,
  'upper back': MuscleKeys.upperBack,

  // Bíceps
  'biceps': MuscleKeys.biceps,
  'bicep': MuscleKeys.biceps,

  // Tríceps
  'triceps': MuscleKeys.triceps,
  'tricep': MuscleKeys.triceps,

  // Abdominales
  'abs': MuscleKeys.abs,
  'abdominals': MuscleKeys.abs,
  'abdominales': MuscleKeys.abs,
};
