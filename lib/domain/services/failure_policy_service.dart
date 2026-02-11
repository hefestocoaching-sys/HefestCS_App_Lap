import 'package:hcs_app_lap/core/enums/training_level.dart';
import 'package:hcs_app_lap/core/enums/training_phase.dart';
import 'package:hcs_app_lap/domain/entities/exercise_catalog.dart';
import 'package:hcs_app_lap/domain/entities/failure_policy_decision.dart';
import 'package:hcs_app_lap/domain/models/rir_target.dart';

/// Servicio para evaluar políticas conservadoras de fallo muscular.
/// Determina si se permite fallo en último set y límites semanales.
class FailurePolicyService {
  /// Evalúa la política de fallo para un ejercicio en contexto específico.
  FailurePolicyDecision evaluate({
    required TrainingLevel? level,
    required TrainingPhase phase,
    required String fatigueExpectation,
    required ExerciseEntry exercise,
    required RirTarget targetRir,
    required int weekIndex,
    required int dayIndex,
    required int daysPerWeek,
    required int muscleWeeklySets,
    required int muscleWeeklyFrequency,
  }) {
    final reasons = <String>[];
    final debugContext = <String, dynamic>{};

    // 1. Bloqueo absoluto: deload o fatiga alta
    if (phase == TrainingPhase.deload) {
      reasons.add('phase=deload');
      return FailurePolicyDecision(
        allowFailureOnLastSet: false,
        maxFailureSetsThisSession: 0,
        reasons: reasons,
        debugContext: debugContext,
      );
    }

    if (fatigueExpectation == 'high' || fatigueExpectation == 'reset') {
      reasons.add('fatigueExpectation=$fatigueExpectation');
      return FailurePolicyDecision(
        allowFailureOnLastSet: false,
        maxFailureSetsThisSession: 0,
        reasons: reasons,
        debugContext: debugContext,
      );
    }

    // 2. Principiante: nunca permite fallo
    if (level == TrainingLevel.beginner) {
      reasons.add('level=beginner');
      return FailurePolicyDecision(
        allowFailureOnLastSet: false,
        maxFailureSetsThisSession: 0,
        reasons: reasons,
        debugContext: debugContext,
      );
    }

    // 3. Análisis de ejercicio compuesto vs aislado
    bool isAllowedByExerciseType = true;

    if (exercise.isCompound) {
      // Compounds con barbell/dumbbell: BLOQUEADOS siempre (política conservadora)
      final isMachineOrCable =
          exercise.equipment.contains('machine') ||
          exercise.equipment.contains('cable');

      if (!isMachineOrCable) {
        // Barbell/dumbbell compound: NUNCA permitir fallo
        reasons.add('compound_freeweight_blocked');
        isAllowedByExerciseType = false;
      } else {
        // Machine/cable compound: permitir solo si RIR>=2
        if (targetRir.min < 2) {
          reasons.add(
            'compound(machine/cable) && targetRIR=${targetRir.label}<2',
          );
          isAllowedByExerciseType = false;
        }
      }
    } else {
      // Aislado: necesita RIR>=1.5 idealmente
      // Con rangos discretos usamos criterio conservador: min>=2
      if (targetRir.min < 2) {
        reasons.add('isolation && targetRIR=${targetRir.label}<2');
        isAllowedByExerciseType = false;
      }
    }

    if (!isAllowedByExerciseType) {
      return FailurePolicyDecision(
        allowFailureOnLastSet: false,
        maxFailureSetsThisSession: 0,
        reasons: reasons,
        debugContext: debugContext,
      );
    }

    // 4. Cálculo de presupuesto semanal por frecuencia
    final percentageByFrequency = _getFailureSlotPercentage(
      muscleWeeklyFrequency,
    );
    final maxFailureSlots = (muscleWeeklySets * percentageByFrequency)
        .round()
        .clamp(1, muscleWeeklySets);

    debugContext['muscleWeeklySets'] = muscleWeeklySets;
    debugContext['muscleWeeklyFrequency'] = muscleWeeklyFrequency;
    debugContext['percentageByFrequency'] = percentageByFrequency;
    debugContext['maxFailureSlots'] = maxFailureSlots;

    // 5. Distribución determinística: asignar slots a días de forma rotatoria
    final slotsPerDay = _distributeFailureSlots(
      maxSlots: maxFailureSlots,
      daysPerWeek: daysPerWeek,
      dayIndex: dayIndex,
    );

    debugContext['slotsPerDay'] = slotsPerDay;
    debugContext['slotsThisDay'] = slotsPerDay;

    // 6. Colocación: volumen muy alto => solo últimos días
    if (exercise.isCompound && muscleWeeklySets > 30) {
      const allowedDaysFromEnd = 2;
      final firstDisallowedDay = daysPerWeek - allowedDaysFromEnd;

      if (dayIndex < firstDisallowedDay && dayIndex > 0) {
        // dayIndex es 1-based en el protocolo: día 1, día 2, etc.
        reasons.add(
          'highVolume && compound && day=$dayIndex<$firstDisallowedDay',
        );
        return FailurePolicyDecision(
          allowFailureOnLastSet: false,
          maxFailureSetsThisSession: 0,
          reasons: reasons,
          debugContext: debugContext,
        );
      }
    }

    // Decisión final
    reasons.add('allowed');
    return FailurePolicyDecision(
      allowFailureOnLastSet: slotsPerDay > 0,
      maxFailureSetsThisSession: slotsPerDay,
      reasons: reasons,
      debugContext: debugContext,
    );
  }

  /// Obtiene el porcentaje máximo de sets con opción fallo según frecuencia.
  double _getFailureSlotPercentage(int frequency) {
    if (frequency <= 2) {
      return 0.20; // 20% para baja frecuencia
    } else if (frequency == 3) {
      return 0.16; // 16% para frecuencia media
    } else {
      return 0.10; // 10% para alta frecuencia (4+)
    }
  }

  /// Distribuye slots de fallo de forma determinística entre días.
  /// Retorna número de slots asignados a este día específico.
  int _distributeFailureSlots({
    required int maxSlots,
    required int daysPerWeek,
    required int dayIndex, // 1-based
  }) {
    if (maxSlots <= 0 || daysPerWeek <= 0) return 0;

    // Estrategia: concentrar slots en los últimos días (menor fatiga antes de deload)
    // Calcular cuántos días tendrán al menos 1 slot
    final daysWithSlots = maxSlots > 0 ? maxSlots : 1;
    final firstEligibleDay = (daysPerWeek - daysWithSlots) + 1;

    // Si estamos en uno de los últimos N días, asignar 1 slot (repartición simple)
    if (dayIndex >= firstEligibleDay && dayIndex <= daysPerWeek) {
      return 1;
    }

    return 0;
  }
}
