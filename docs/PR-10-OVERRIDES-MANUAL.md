/// PR-10: Overrides Manuales Auditables - Guía de Implementación
///
/// ESTRUCTURA COMPLETADA:
/// ✅ [manual_override.dart]: 
///    - ManualOverride class con parsing seguro
///    - VolumeOverride class
///    - validate() con 11 checks de seguridad
///    - TrainingExtraKeys.manualOverrides agregada
///
/// INTEGRACION PENDIENTE (Por Fase):
///
/// FASE 1 - Phase1DataIngestionService:
/// -----
/// 1. Agregar parámetro opcional:
///    ```dart
///    ingestAndValidate({
///      ...params,
///      Map<String, dynamic>? manualOverridesRaw,
///    })
///    ```
/// 
/// 2. Validar dentro:
///    ```dart
///    final override = ManualOverride.fromMap(manualOverridesRaw);
///    final validationWarnings = override.validate();
///    warnings.addAll(validationWarnings);
///    
///    decisions.add(
///      DecisionTrace.info(
///        phase: 'manual_override',
///        category: 'override_detected',
///        description: 'Overrides manuales detectados',
///        context: {
///          'volumeOverrides': override.volumeOverrides?.keys.toList(),
///          'priorityOverrides': override.priorityOverrides?.keys.toList(),
///          'rirTargetOverride': override.rirTargetOverride,
///          'allowIntensification': override.allowIntensification,
///        },
///      ),
///    );
///    ```
/// 
/// 3. Retornar override en Phase1Result (agregar campo)
///
/// FASE 3 - Phase3VolumeCapacityModelService:
/// -----
/// 1. Recibir override en calculateVolumeCapacity()
/// 
/// 2. Aplicar en volumeForMuscle():
///    ```dart
///    // Base
///    var mev = baseVolumeLimits.mev;
///    var mav = baseVolumeLimits.mav;
///    var mrv = baseVolumeLimits.mrv;
///    
///    // Override
///    if (override?.volumeOverrides?[muscle] case VolumeOverride vol) {
///      if (vol.mev != null) mev = vol.mev!;
///      if (vol.mav != null) mav = vol.mav!;
///      if (vol.mrv != null) mrv = vol.mrv!;
///    }
///    
///    // Guardrails defensivos
///    if (trainingLevel == TrainingLevel.beginner && mrv > 16) {
///      mrv = 16; // Cap beginner
///      decisions.add(DecisionTrace.warning(...));
///    }
///    if (mrv < baseVolumeLimits.mev) {
///      mrv = baseVolumeLimits.mev; // MRV >= MEV base
///      decisions.add(DecisionTrace.warning(...));
///    }
///    
///    decisions.add(
///      DecisionTrace.info(
///        phase: 'Phase3VolumeCapacity',
///        category: 'volume_override_applied',
///        description: 'Override de volumen aplicado a $muscle',
///        context: {'muscle': muscle, 'mev': mev, 'mav': mav, 'mrv': mrv},
///      ),
///    );
///    ```
///
/// FASE 4 - Phase4SplitDistributionService:
/// -----
/// 1. Recibir override en buildWeeklySplit()
/// 
/// 2. Aplicar priorityOverrides ANTES de redistribución:
///    ```dart
///    // Mapeo de músculo a prioridad base
///    final priority = <String, String>{};
///    ...
///    
///    // Override
///    if (override?.priorityOverrides != null) {
///      priority.addAll(override.priorityOverrides!);
///    }
///    
///    // Verificar prioridades válidas
///    for (final entry in priority.entries) {
///      try {
///        MuscleGroup.values.byName(entry.key);
///      } catch (_) {
///        decisions.add(DecisionTrace.warning('Músculo inválido ${entry.key}'));
///        priority.remove(entry.key);
///      }
///    }
///    
///    decisions.add(
///      DecisionTrace.info(
///        phase: 'Phase4SplitDistribution',
///        category: 'priority_override_applied',
///        description: 'Overrides de prioridad aplicados',
///        context: {'priorities': override.priorityOverrides},
///      ),
///    );
///    ```
///
/// FASE 5 - Phase5PeriodizationService:
/// -----
/// 1. Recibir override en periodize()
/// 
/// 2. Aplicar rirTargetOverride:
///    ```dart
///    double rirTarget = override?.rirTargetOverride ?? baseRir Target;
///    
///    // Clamp por nivel
///    if (trainingLevel == TrainingLevel.beginner) {
///      rirTarget = rirTarget.clamp(1.0, 3.0);
///    } else if (trainingLevel == TrainingLevel.advanced) {
///      rirTarget = rirTarget.clamp(0.0, 4.0);
///    } else {
///      rirTarget = rirTarget.clamp(0.5, 3.5);
///    }
///    
///    decisions.add(
///      DecisionTrace.info(
///        phase: 'Phase5Periodization',
///        category: 'rir_override_applied',
///        description: 'Override de RIR target aplicado',
///        context: {'rirTarget': rirTarget, 'baseRirTarget': baseRirTarget},
///      ),
///    );
///    ```
///
/// FASE 7 - Phase7PrescriptionService:
/// -----
/// 1. Recibir override en buildPrescriptions()
/// 
/// 2. Controlar intensificación:
///    ```dart
///    bool allowIntensification = 
///      override?.allowIntensification ?? baseAllowIntensification;
///    int maxPerWeek = override?.intensificationMaxPerWeek ?? 1;
///    
///    // En cada semana
///    int appliedThisWeek = 0;
///    for (final session in weekSessions) {
///      if (allowIntensification && appliedThisWeek < maxPerWeek) {
///        // Permitir técnica
///        appliedThisWeek++;
///      }
///    }
///    
///    decisions.add(
///      DecisionTrace.info(
///        phase: 'Phase7Prescription',
///        category: 'intensification_override_applied',
///        description: 'Override de intensificación aplicado',
///        context: {
///          'allowIntensification': allowIntensification,
///          'maxPerWeek': maxPerWeek,
///        },
///      ),
///    );
///    ```
///
/// FASE 8 - Phase8AdaptationService:
/// -----
/// 1. Recibir override en adapt()
/// 
/// 2. Respetar overrides durante adaptación:
///    ```dart
///    // Los overrides persisten durante adaptación
///    // pero pueden ser clampados por guardrails
///    
///    if (volumeLimitsByMuscle != null) {
///      // Aplicar MRV override si existe
///      if (override?.volumeOverrides?[muscle] case VolumeOverride vol
///          when vol.mrv != null) {
///        maxSets = vol.mrv!;
///      }
///    }
///    
///    // Fatiga puede aumentar RIR aunque haya override
///    if (fatigueSignal && rirDelta > 0) {
///      // Aplicar rirDelta
///    }
///    
///    decisions.add(
///      DecisionTrace.info(
///        phase: 'Phase8Adaptation',
///        category: 'override_respected_during_adaptation',
///        description: 'Overrides mantenidos durante adaptación',
///      ),
///    );
///    ```
///
/// FLUJO EN TrainingProgramEngine:
/// -----
/// ```dart
/// TrainingPlanConfig generatePlan({...}) {
///   // Leer overrides una vez
///   final manualOverridesRaw = profile.extra[TrainingExtraKeys.manualOverrides];
///   
///   // Fase 1 - validar
///   final r1 = _phase1.ingestAndValidate(
///     profile: profile,
///     history: history,
///     latestFeedback: latestFeedback,
///     manualOverridesRaw: manualOverridesRaw,
///   );
///   final override = r1.manualOverride;
///   
///   // Fase 3 - aplicar volumen
///   final r3 = _phase3.calculateVolumeCapacity(
///     ...existing,
///     manualOverride: override,
///   );
///   
///   // Fase 4 - aplicar prioridad
///   final r4 = _phase4.buildWeeklySplit(
///     ...existing,
///     manualOverride: override,
///   );
///   
///   // Fase 5 - aplicar RIR
///   final r5 = _phase5.periodize(
///     ...existing,
///     manualOverride: override,
///   );
///   
///   // Fase 7 - aplicar intensificación
///   final r7 = _phase7.buildPrescriptions(
///     ...existing,
///     manualOverride: override,
///   );
///   
///   // Fase 8 - respetar durante adaptación
///   final r8 = _phase8.adapt(
///     ...existing,
///     manualOverride: override,
///   );
/// }
/// ```
///
/// TESTS OBLIGATORIOS (después de integrar):
/// -----
/// test('override volumen MEV/MAV/MRV cambia límites finales')
/// test('override inválido se ignora y registra warning')
/// test('beginner no puede superar MRV seguro 16 aunque override')
/// test('override prioridad aumenta volumen relativo músculo')
/// test('override intensificación permite técnica cuando antes no')
/// test('DecisionTrace contiene TODOS los overrides aplicados')
/// test('determinismo: mismos overrides → mismo plan JSON')
/// test('override MEV persiste en Fase 8 aunque no fatiga')
/// test('override RIR es clampado por nivel')
/// test('override prioridad invalida se detecta en Fase 1')
///
/// GUARDRAILS DE SEGURIDAD (Implementados):
/// -----
/// ✅ Validación de valores positivos
/// ✅ Validación de orden mev ≤ mav ≤ mrv
/// ✅ Validación de nombres de músculo
/// ✅ Cap beginner MRV ≤ 16
/// ✅ MRV >= MEV base
/// ✅ RIR clampado por nivel
/// ✅ Prioridad solo primary|secondary|none
/// ✅ Intensification max per week >= 0
/// ✅ Todas las warnings registradas en DecisionTrace
///
/// NOTAS:
/// - Los overrides se leen UNA VEZ en Fase 1
/// - Se validan en Fase 1, se aplican en 3,4,5,7
/// - Persisten en Fase 8 pero pueden ser clampados
/// - TODO override debe generar DecisionTrace
/// - No crear nuevas entidades persistentes
/// - Mantener determinismo absoluto
