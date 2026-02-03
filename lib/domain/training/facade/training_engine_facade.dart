import 'package:flutter/foundation.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/exercise.dart';
import 'package:hcs_app_lap/domain/entities/training_plan_config.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/services/training_program_engine.dart';
import 'package:hcs_app_lap/data/repositories/client_repository.dart';

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
  /// - Persiste el plan en client.trainingPlans
  /// - Guarda el cliente actualizado en repositorio ANTES de retornar
  /// - Puede lanzar StateError si datos críticos faltan (fail-fast)
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
      throw StateError(
        'TrainingEngineFacade: exercises es null o vacío. '
        'Debe pasarse el catálogo cargado.',
      );
    }

    final exerciseList = exercises.whereType<Exercise>().toList();
    if (exerciseList.isEmpty) {
      throw StateError(
        'TrainingEngineFacade: exercises no contiene objetos Exercise válidos.',
      );
    }

    debugPrint('🚀 [TrainingEngineFacade] Generando plan Motor V3...');

    // ═══════════════════════════════════════════════════════════════════════
    // PASO 1: Generar plan vía Motor V3 (TrainingProgramEngineV2Full)
    // ═══════════════════════════════════════════════════════════════════════
    final planConfig = _engine.generatePlan(
      planId: planId,
      clientId: clientId,
      planName: planName,
      startDate: startDate,
      profile: profile,
      client: client,
      exercises: exerciseList,
    );

    debugPrint('✅ [TrainingEngineFacade] Plan generado:');
    debugPrint('   Plan ID: ${planConfig.id}');
    debugPrint('   Semanas: ${planConfig.weeks.length}');
    debugPrint('   plan.state keys: ${planConfig.state?.keys.toList()}');

    // Validar que plan.state contiene datos volumétricos
    if (planConfig.state != null && planConfig.state!.containsKey('phase3')) {
      final phase3 = planConfig.state!['phase3'] as Map<String, dynamic>?;
      if (phase3 != null && phase3.containsKey('capacityByMuscle')) {
        final capacityByMuscle =
            phase3['capacityByMuscle'] as Map<String, dynamic>?;
        debugPrint(
          '   plan.state[phase3][capacityByMuscle] músculos: ${capacityByMuscle?.keys.toList()}',
        );
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // PASO 2: Añadir plan a client.trainingPlans
    // ═══════════════════════════════════════════════════════════════════════

    // Obtener lista actual de planes (evitar duplicados)
    final currentPlans = List<TrainingPlanConfig>.from(client.trainingPlans);

    // Remover plan con mismo ID si existe (regeneración)
    currentPlans.removeWhere((p) => p.id == planConfig.id);

    // Añadir nuevo plan
    currentPlans.add(planConfig);

    debugPrint('🔍 [TrainingEngineFacade] Planes después de añadir:');
    debugPrint('   Total planes: ${currentPlans.length}');
    debugPrint('   Plan IDs: ${currentPlans.map((p) => p.id).toList()}');

    // ═══════════════════════════════════════════════════════════════════════
    // PASO 3: Actualizar client.training.extra['activePlanId']
    // ═══════════════════════════════════════════════════════════════════════

    final updatedExtra = Map<String, dynamic>.from(client.training.extra);
    updatedExtra['activePlanId'] = planConfig.id;

    debugPrint(
      '✅ [TrainingEngineFacade] activePlanId actualizado: ${planConfig.id}',
    );

    // ═══════════════════════════════════════════════════════════════════════
    // PASO 4: Actualizar cliente completo
    // ═══════════════════════════════════════════════════════════════════════

    final updatedTraining = client.training.copyWith(extra: updatedExtra);

    final updatedClient = client.copyWith(
      training: updatedTraining,
      trainingPlans:
          currentPlans, // ✅ CRÍTICO: Lista actualizada con nuevo plan
    );

    // ═══════════════════════════════════════════════════════════════════════
    // PASO 5: Persistir cliente en repositorio
    // ═══════════════════════════════════════════════════════════════════════

    debugPrint('💾 [TrainingEngineFacade] Guardando cliente con plan...');

    await repository.saveClient(updatedClient);

    debugPrint('✅ [TrainingEngineFacade] Cliente guardado correctamente');
    debugPrint(
      '   trainingPlans.length: ${updatedClient.trainingPlans.length}',
    );
    debugPrint(
      '   activePlanId: ${updatedClient.training.extra['activePlanId']}',
    );

    // ═══════════════════════════════════════════════════════════════════════
    // PASO 6: Retornar plan generado
    // ═══════════════════════════════════════════════════════════════════════

    return planConfig;
  }

  /// Obtén el último trace de decisiones generadas.
  List<dynamic> get lastDecisions => _engine.lastDecisions;

  // ═══════════════════════════════════════════════════════════════════════════
  // SELECCIÓN DE PLAN (deprecated - no se usa en flujo actual)
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
}
