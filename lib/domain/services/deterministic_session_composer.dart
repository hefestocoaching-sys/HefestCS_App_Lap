// Compositor de sesiones de entrenamiento deterministas
//
// Propósito:
// - Generar planes de entrenamiento clínicamente válidos
// - Aplicar splits rígidos según días de entrenamiento (3-6)
// - Filtrar ejercicios por equipamiento disponible y restricciones
// - Garantizar mínimo 4 ejercicios por sesión
// - Priorizar músculos objetivo con ejercicios compuestos
// - Solo usar ejercicios del catálogo curado en español

import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/exceptions/training_plan_blocked_exception.dart';
import 'package:hcs_app_lap/domain/services/curated_exercise_catalog.dart';
import 'package:hcs_app_lap/domain/services/training_log_aggregator.dart';
import 'package:hcs_app_lap/core/enums/training_goal.dart';

/// Sesión de entrenamiento generada
class ComposedTrainingSession {
  const ComposedTrainingSession({
    required this.sessionName,
    required this.exercises,
    required this.focusGroups,
  });

  /// Nombre de la sesión (ej: "Día A - Torso Superior", "Empuje")
  final String sessionName;

  /// Lista de ejercicios seleccionados con series y reps sugeridas
  final List<ComposedExercise> exercises;

  /// Grupos musculares enfocados en esta sesión
  final List<MuscleGroup> focusGroups;

  @override
  String toString() {
    return 'Session: $sessionName (${exercises.length} ejercicios)';
  }
}

/// Ejercicio compuesto con prescripción de volumen
class ComposedExercise {
  const ComposedExercise({
    required this.exercise,
    required this.sets,
    required this.repsMin,
    required this.repsMax,
    required this.targetRIR,
  });

  /// Ejercicio del catálogo curado
  final CuratedExercise exercise;

  /// Series prescritas
  final int sets;

  /// Rango de repeticiones mínimo
  final int repsMin;

  /// Rango de repeticiones máximo
  final int repsMax;

  /// RIR objetivo (Reps In Reserve)
  final int targetRIR;

  @override
  String toString() {
    return '${exercise.nameEs}: $sets x $repsMin-$repsMax @ RIR $targetRIR';
  }
}

/// Tipo de split de entrenamiento
enum TrainingSplit {
  fullBodyABC, // 3 días: FullBody A, B, C
  upperLowerAB, // 4 días: Upper A, Lower A, Upper B, Lower B
  pplPlusUpper, // 5 días: Push, Pull, Legs, Upper, Pull
  pplDouble, // 6 días: Push A, Pull A, Legs A, Push B, Pull B, Legs B
}

/// Servicio compositor de sesiones deterministas
class DeterministicSessionComposer {
  const DeterministicSessionComposer();

  /// Genera plan de entrenamiento completo
  ///
  /// - [profile]: Perfil de entrenamiento del cliente
  /// - [logAnalysis]: Análisis de logs para ajustes (opcional)
  ///
  /// GARANTÍAS:
  /// - Número de sesiones == profile.daysPerWeek
  /// - Mínimo 4 ejercicios por sesión
  /// - Solo ejercicios en español del catálogo curado
  /// - Split determinista según días (3/4/5/6)
  /// - Filtrado por equipamiento disponible
  /// - Exclusión de patrones restringidos
  ///
  /// THROWS:
  /// - [StateError] si no se puede generar plan válido
  List<ComposedTrainingSession> composePlan({
    required TrainingProfile profile,
    TrainingLogAnalysis? logAnalysis,
  }) {
    // Validar daysPerWeek en rango válido (3-6)
    final days = profile.daysPerWeek;
    if (days < 3 || days > 6) {
      throw TrainingPlanBlockedException(
        message: 'La frecuencia de entrenamiento debe estar entre 3 y 6 días',
        details:
            'Se recibió: $days días. Configure entre 3 y 6 días por semana.',
        actionableFix:
            'Ajuste la frecuencia de entrenamiento semanal entre 3 y 6 días',
      );
    }

    // Determinar split según días
    final split = _getSplitForDays(days);

    // Parsear equipamiento disponible
    final availableEquipment = _parseEquipment(profile.equipment);

    // Parsear restricciones de movimiento
    final restrictedPatterns = _parseRestrictions(profile.movementRestrictions);

    // Filtrar catálogo por equipamiento y restricciones
    final compounds = ExerciseCatalog.getCompounds(
      availableEquipment: availableEquipment,
      restrictedPatterns: restrictedPatterns,
    );

    final accessories = ExerciseCatalog.getAccessories(
      availableEquipment: availableEquipment,
      restrictedPatterns: restrictedPatterns,
    );

    // Validar que hay ejercicios disponibles
    if (compounds.isEmpty && accessories.isEmpty) {
      throw TrainingPlanBlockedException(
        message:
            'No hay ejercicios disponibles con el equipamiento configurado',
        details:
            'Equipamiento: ${profile.equipment}, Restricciones: ${profile.movementRestrictions}',
        actionableFix:
            'Verifique el equipamiento disponible o reduzca las restricciones de movimiento',
      );
    }

    // Generar sesiones según split
    final sessions = _generateSessions(
      split: split,
      compounds: compounds,
      accessories: accessories,
      profile: profile,
      logAnalysis: logAnalysis,
    );

    // Validar resultado final
    _validateGeneratedPlan(sessions, days);

    return sessions;
  }

  /// Determina el split según días de entrenamiento
  TrainingSplit _getSplitForDays(int days) {
    switch (days) {
      case 3:
        return TrainingSplit.fullBodyABC;
      case 4:
        return TrainingSplit.upperLowerAB;
      case 5:
        return TrainingSplit.pplPlusUpper;
      case 6:
        return TrainingSplit.pplDouble;
      default:
        throw TrainingPlanBlockedException(
          message: 'Frecuencia de entrenamiento no soportada',
          details: 'Días: $days',
          actionableFix:
              'Configure entre 3 y 6 días de entrenamiento por semana',
        );
    }
  }

  /// Parsea equipamiento desde profile.equipment
  Set<EquipmentType> _parseEquipment(List<String> equipment) {
    final parsed = equipment
        .map((e) => EquipmentType.fromString(e))
        .whereType<EquipmentType>()
        .toSet();

    // Fallback: dumbbell + bodyweight si lista vacía
    if (parsed.isEmpty) {
      return {EquipmentType.dumbbell, EquipmentType.bodyweight};
    }

    return parsed;
  }

  /// Parsea restricciones desde profile.movementRestrictions
  Set<MovementPattern> _parseRestrictions(List<String> restrictions) {
    return restrictions
        .map((r) => MovementPattern.fromString(r))
        .whereType<MovementPattern>()
        .toSet();
  }

  /// Genera sesiones según split seleccionado
  List<ComposedTrainingSession> _generateSessions({
    required TrainingSplit split,
    required List<CuratedExercise> compounds,
    required List<CuratedExercise> accessories,
    required TrainingProfile profile,
    TrainingLogAnalysis? logAnalysis,
  }) {
    switch (split) {
      case TrainingSplit.fullBodyABC:
        return _generateFullBodyABC(
          compounds,
          accessories,
          profile,
          logAnalysis,
        );
      case TrainingSplit.upperLowerAB:
        return _generateUpperLowerAB(
          compounds,
          accessories,
          profile,
          logAnalysis,
        );
      case TrainingSplit.pplPlusUpper:
        return _generatePPLPlusUpper(
          compounds,
          accessories,
          profile,
          logAnalysis,
        );
      case TrainingSplit.pplDouble:
        return _generatePPLDouble(compounds, accessories, profile, logAnalysis);
    }
  }

  /// Genera split FullBody A/B/C (3 días)
  List<ComposedTrainingSession> _generateFullBodyABC(
    List<CuratedExercise> compounds,
    List<CuratedExercise> accessories,
    TrainingProfile profile,
    TrainingLogAnalysis? logAnalysis,
  ) {
    return [
      _composeFullBodySession(
        name: 'Día A - Cuerpo Completo',
        compounds: compounds,
        accessories: accessories,
        profile: profile,
        logAnalysis: logAnalysis,
        variant: 'A',
      ),
      _composeFullBodySession(
        name: 'Día B - Cuerpo Completo',
        compounds: compounds,
        accessories: accessories,
        profile: profile,
        logAnalysis: logAnalysis,
        variant: 'B',
      ),
      _composeFullBodySession(
        name: 'Día C - Cuerpo Completo',
        compounds: compounds,
        accessories: accessories,
        profile: profile,
        logAnalysis: logAnalysis,
        variant: 'C',
      ),
    ];
  }

  /// Genera split Upper/Lower A-B (4 días)
  List<ComposedTrainingSession> _generateUpperLowerAB(
    List<CuratedExercise> compounds,
    List<CuratedExercise> accessories,
    TrainingProfile profile,
    TrainingLogAnalysis? logAnalysis,
  ) {
    final upperGroups = [
      MuscleGroup.pectorales,
      MuscleGroup.dorsales,
      MuscleGroup.hombros,
      MuscleGroup.brazos,
    ];

    final lowerGroups = [
      MuscleGroup.cuadriceps,
      MuscleGroup.isquiotibiales,
      MuscleGroup.gluteos,
    ];

    return [
      _composeTargetedSession(
        name: 'Día A - Torso Superior',
        compounds: compounds,
        accessories: accessories,
        targetGroups: upperGroups,
        profile: profile,
        logAnalysis: logAnalysis,
      ),
      _composeTargetedSession(
        name: 'Día A - Tren Inferior',
        compounds: compounds,
        accessories: accessories,
        targetGroups: lowerGroups,
        profile: profile,
        logAnalysis: logAnalysis,
      ),
      _composeTargetedSession(
        name: 'Día B - Torso Superior',
        compounds: compounds,
        accessories: accessories,
        targetGroups: upperGroups,
        profile: profile,
        logAnalysis: logAnalysis,
      ),
      _composeTargetedSession(
        name: 'Día B - Tren Inferior',
        compounds: compounds,
        accessories: accessories,
        targetGroups: lowerGroups,
        profile: profile,
        logAnalysis: logAnalysis,
      ),
    ];
  }

  /// Genera split PPL + Upper (5 días)
  List<ComposedTrainingSession> _generatePPLPlusUpper(
    List<CuratedExercise> compounds,
    List<CuratedExercise> accessories,
    TrainingProfile profile,
    TrainingLogAnalysis? logAnalysis,
  ) {
    return [
      _composeTargetedSession(
        name: 'Día 1 - Empuje',
        compounds: compounds,
        accessories: accessories,
        targetGroups: [
          MuscleGroup.pectorales,
          MuscleGroup.hombros,
          MuscleGroup.brazos,
        ],
        profile: profile,
        logAnalysis: logAnalysis,
      ),
      _composeTargetedSession(
        name: 'Día 2 - Tracción',
        compounds: compounds,
        accessories: accessories,
        targetGroups: [
          MuscleGroup.dorsales,
          MuscleGroup.trapecios,
          MuscleGroup.brazos,
        ],
        profile: profile,
        logAnalysis: logAnalysis,
      ),
      _composeTargetedSession(
        name: 'Día 3 - Pierna',
        compounds: compounds,
        accessories: accessories,
        targetGroups: [
          MuscleGroup.cuadriceps,
          MuscleGroup.isquiotibiales,
          MuscleGroup.gluteos,
        ],
        profile: profile,
        logAnalysis: logAnalysis,
      ),
      _composeTargetedSession(
        name: 'Día 4 - Torso Superior',
        compounds: compounds,
        accessories: accessories,
        targetGroups: [
          MuscleGroup.pectorales,
          MuscleGroup.dorsales,
          MuscleGroup.hombros,
        ],
        profile: profile,
        logAnalysis: logAnalysis,
      ),
      _composeTargetedSession(
        name: 'Día 5 - Tracción + Accesorios',
        compounds: compounds,
        accessories: accessories,
        targetGroups: [MuscleGroup.dorsales, MuscleGroup.brazos],
        profile: profile,
        logAnalysis: logAnalysis,
      ),
    ];
  }

  /// Genera split PPL x2 (6 días)
  List<ComposedTrainingSession> _generatePPLDouble(
    List<CuratedExercise> compounds,
    List<CuratedExercise> accessories,
    TrainingProfile profile,
    TrainingLogAnalysis? logAnalysis,
  ) {
    return [
      _composeTargetedSession(
        name: 'Día 1 - Empuje A',
        compounds: compounds,
        accessories: accessories,
        targetGroups: [
          MuscleGroup.pectorales,
          MuscleGroup.hombros,
          MuscleGroup.brazos,
        ],
        profile: profile,
        logAnalysis: logAnalysis,
      ),
      _composeTargetedSession(
        name: 'Día 2 - Tracción A',
        compounds: compounds,
        accessories: accessories,
        targetGroups: [
          MuscleGroup.dorsales,
          MuscleGroup.trapecios,
          MuscleGroup.brazos,
        ],
        profile: profile,
        logAnalysis: logAnalysis,
      ),
      _composeTargetedSession(
        name: 'Día 3 - Pierna A',
        compounds: compounds,
        accessories: accessories,
        targetGroups: [
          MuscleGroup.cuadriceps,
          MuscleGroup.isquiotibiales,
          MuscleGroup.gluteos,
        ],
        profile: profile,
        logAnalysis: logAnalysis,
      ),
      _composeTargetedSession(
        name: 'Día 4 - Empuje B',
        compounds: compounds,
        accessories: accessories,
        targetGroups: [
          MuscleGroup.pectorales,
          MuscleGroup.hombros,
          MuscleGroup.brazos,
        ],
        profile: profile,
        logAnalysis: logAnalysis,
      ),
      _composeTargetedSession(
        name: 'Día 5 - Tracción B',
        compounds: compounds,
        accessories: accessories,
        targetGroups: [
          MuscleGroup.dorsales,
          MuscleGroup.trapecios,
          MuscleGroup.brazos,
        ],
        profile: profile,
        logAnalysis: logAnalysis,
      ),
      _composeTargetedSession(
        name: 'Día 6 - Pierna B',
        compounds: compounds,
        accessories: accessories,
        targetGroups: [
          MuscleGroup.cuadriceps,
          MuscleGroup.isquiotibiales,
          MuscleGroup.gluteos,
        ],
        profile: profile,
        logAnalysis: logAnalysis,
      ),
    ];
  }

  /// Compone sesión fullbody con variante A/B/C
  ComposedTrainingSession _composeFullBodySession({
    required String name,
    required List<CuratedExercise> compounds,
    required List<CuratedExercise> accessories,
    required TrainingProfile profile,
    TrainingLogAnalysis? logAnalysis,
    required String variant,
  }) {
    final exercises = <ComposedExercise>[];

    // 1 compuesto de empuje (pecho/hombros)
    final pushCompounds = compounds
        .where(
          (e) =>
              e.primaryMuscles.contains(MuscleGroup.pectorales) ||
              e.primaryMuscles.contains(MuscleGroup.hombros),
        )
        .toList();

    // 1 compuesto de tracción (dorsales)
    final pullCompounds = compounds
        .where((e) => e.primaryMuscles.contains(MuscleGroup.dorsales))
        .toList();

    // 1 compuesto de pierna
    final legCompounds = compounds
        .where(
          (e) =>
              e.primaryMuscles.contains(MuscleGroup.cuadriceps) ||
              e.primaryMuscles.contains(MuscleGroup.gluteos) ||
              e.primaryMuscles.contains(MuscleGroup.isquiotibiales),
        )
        .toList();

    // Seleccionar ejercicios compuestos
    if (pushCompounds.isNotEmpty) {
      exercises.add(
        _prescribeExercise(
          exercise: pushCompounds.first,
          profile: profile,
          logAnalysis: logAnalysis,
          isCompound: true,
        ),
      );
    }
    if (pullCompounds.isNotEmpty) {
      exercises.add(
        _prescribeExercise(
          exercise: pullCompounds.first,
          profile: profile,
          logAnalysis: logAnalysis,
          isCompound: true,
        ),
      );
    }
    if (legCompounds.isNotEmpty) {
      exercises.add(
        _prescribeExercise(
          exercise: legCompounds.first,
          profile: profile,
          logAnalysis: logAnalysis,
          isCompound: true,
        ),
      );
    }

    // Completar con accesorios hasta mínimo 4 ejercicios
    final availableAccessories = accessories.toList()..shuffle();
    while (exercises.length < 4 && availableAccessories.isNotEmpty) {
      exercises.add(
        _prescribeExercise(
          exercise: availableAccessories.removeAt(0),
          profile: profile,
          logAnalysis: logAnalysis,
          isCompound: false,
        ),
      );
    }

    return ComposedTrainingSession(
      sessionName: name,
      exercises: exercises,
      focusGroups: [
        MuscleGroup.pectorales,
        MuscleGroup.dorsales,
        MuscleGroup.cuadriceps,
      ],
    );
  }

  /// Compone sesión enfocada en grupos musculares específicos
  ComposedTrainingSession _composeTargetedSession({
    required String name,
    required List<CuratedExercise> compounds,
    required List<CuratedExercise> accessories,
    required List<MuscleGroup> targetGroups,
    required TrainingProfile profile,
    TrainingLogAnalysis? logAnalysis,
  }) {
    final exercises = <ComposedExercise>[];

    // Filtrar compuestos que trabajan grupos objetivo
    final targetCompounds = compounds
        .where((e) => e.primaryMuscles.any((m) => targetGroups.contains(m)))
        .toList();

    // Agregar 1-2 compuestos principales
    final compoundsToAdd = targetCompounds.take(2).toList();
    for (final ex in compoundsToAdd) {
      exercises.add(
        _prescribeExercise(
          exercise: ex,
          profile: profile,
          logAnalysis: logAnalysis,
          isCompound: true,
        ),
      );
    }

    // Filtrar accesorios que trabajan grupos objetivo
    final targetAccessories =
        accessories
            .where((e) => e.primaryMuscles.any((m) => targetGroups.contains(m)))
            .toList()
          ..shuffle();

    // Completar con accesorios hasta mínimo 4 ejercicios
    while (exercises.length < 4 && targetAccessories.isNotEmpty) {
      exercises.add(
        _prescribeExercise(
          exercise: targetAccessories.removeAt(0),
          profile: profile,
          logAnalysis: logAnalysis,
          isCompound: false,
        ),
      );
    }

    // Si aún faltan ejercicios, agregar accesorios generales
    final generalAccessories = accessories.toList()..shuffle();
    while (exercises.length < 4 && generalAccessories.isNotEmpty) {
      exercises.add(
        _prescribeExercise(
          exercise: generalAccessories.removeAt(0),
          profile: profile,
          logAnalysis: logAnalysis,
          isCompound: false,
        ),
      );
    }

    return ComposedTrainingSession(
      sessionName: name,
      exercises: exercises,
      focusGroups: targetGroups,
    );
  }

  /// Prescribe volumen/intensidad para un ejercicio
  ComposedExercise _prescribeExercise({
    required CuratedExercise exercise,
    required TrainingProfile profile,
    required TrainingLogAnalysis? logAnalysis,
    required bool isCompound,
  }) {
    // Ajustar volumen según análisis de logs
    int baseSets = isCompound ? 3 : 3;

    // Reducir sets si hay fatiga o dolor
    if (logAnalysis != null) {
      if (logAnalysis.painFlag) {
        baseSets = (baseSets * 0.7).round().clamp(2, 5);
      } else if (logAnalysis.fatigueFlag) {
        baseSets = (baseSets * 0.85).round().clamp(2, 5);
      }
    }

    // Rangos de reps según objetivo
    int repsMin = 6;
    int repsMax = 12;

    final goal = profile.globalGoal;
    if (goal == TrainingGoal.hypertrophy) {
      repsMin = isCompound ? 6 : 8;
      repsMax = isCompound ? 12 : 15;
    } else if (goal == TrainingGoal.strength) {
      repsMin = isCompound ? 3 : 6;
      repsMax = isCompound ? 6 : 10;
    }

    // RIR según nivel y análisis
    int targetRIR = 2;
    if (logAnalysis != null && logAnalysis.avgReportedRIR < 1.0) {
      targetRIR = 3; // Más conservador si RIR bajo
    }

    return ComposedExercise(
      exercise: exercise,
      sets: baseSets,
      repsMin: repsMin,
      repsMax: repsMax,
      targetRIR: targetRIR,
    );
  }

  /// Valida que el plan generado cumple requisitos
  void _validateGeneratedPlan(
    List<ComposedTrainingSession> sessions,
    int expectedDays,
  ) {
    // Validar número de sesiones
    if (sessions.length != expectedDays) {
      throw TrainingPlanBlockedException(
        message: 'Error en la generación del plan semanal',
        details:
            'Se generaron ${sessions.length} sesiones, se esperaban $expectedDays',
        actionableFix:
            'Contacte a soporte técnico - error interno en el generador',
      );
    }

    // Validar mínimo 4 ejercicios por sesión
    for (final session in sessions) {
      if (session.exercises.length < 4) {
        throw TrainingPlanBlockedException(
          message: 'Catálogo insuficiente para generar un plan completo',
          details:
              'Sesión "${session.sessionName}" tiene solo ${session.exercises.length} ejercicios (mínimo 4)',
          actionableFix:
              'Amplíe el equipamiento disponible o reduzca las restricciones de movimiento',
        );
      }

      // Validar nombres en español (no deben contener caracteres no-latinos)
      for (final ex in session.exercises) {
        if (!_isSpanishName(ex.exercise.nameEs)) {
          throw TrainingPlanBlockedException(
            message: 'Error en el catálogo de ejercicios',
            details:
                'Ejercicio "${ex.exercise.nameEs}" no es un nombre válido en español',
            actionableFix: 'Contacte a soporte técnico - error en el catálogo',
          );
        }
      }
    }
  }

  /// Verifica que el nombre del ejercicio esté en español
  bool _isSpanishName(String name) {
    // Nombres válidos deben contener solo letras, espacios, acentos, guiones
    final spanishPattern = RegExp(r'^[a-zA-ZáéíóúñÁÉÍÓÚÑ\s\-]+$');
    return spanishPattern.hasMatch(name) && name.isNotEmpty;
  }
}
