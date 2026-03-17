import 'package:hcs_app_lap/domain/training_v3/ml/decision_strategy.dart';
import 'package:hcs_app_lap/domain/training_v3/ml/feature_vector.dart';

/// Estrategia basada en reglas científicas
/// 
/// Implementa el conocimiento de:
/// - Israetel et al. (2020-2024): MEV/MAV/MRV, volume progression
/// - Schoenfeld et al. (2017-2021): dose-response curve, volume optimization
/// - Helms et al. (2018-2023): RPE/RIR autoregulation, readiness markers
/// - NSCA (2022): fatigue management, recovery protocols
/// 
/// V1.1 Changes:
/// - Alineado con Phase2ReadinessEvaluationService (volume adjustment ranges)
/// - Usa mismo sistema de clamps que motor legacy para consistencia
/// 
/// Esta estrategia es DETERMINISTA y EXPLICABLE.
/// Todas las decisiones tienen reasoning basado en literatura.
class RuleBasedStrategy implements DecisionStrategy {
  @override
  String get name => 'RuleBased_Israetel_Schoenfeld_Helms';
  
  @override
  String get version => '1.1.0';
  
  @override
  bool get isTrainable => false;
  
  @override
  VolumeDecision decideVolume(FeatureVector features) {
    double adjustment = 1.0;
    final reasons = <String>[];
    
    // ════════════════════════════════════════════════════════════
    // REGLA 1: Overreaching Risk (Israetel MRV management)
    // ════════════════════════════════════════════════════════════
    
    if (features.overreachingRisk > 0.8) {
      // Riesgo alto: deload inmediato
      adjustment = 0.55; // ✅ AJUSTADO: dentro de range critical (0.50-0.65)
      reasons.add(
        'Riesgo alto de sobreentrenamiento (${(features.overreachingRisk * 100).toStringAsFixed(0)}%) → deload -45%'
      );
      
      return VolumeDecision.deload(
        reasoning: reasons.join(' | '),
        factor: adjustment,
      );
    } else if (features.overreachingRisk > 0.6) {
      // Riesgo moderado: reducir progresión
      adjustment *= 0.85; // -15%
      reasons.add(
        'Proximidad a MRV (${(features.overreachingRisk * 100).toStringAsFixed(0)}%) → -15%'
      );
    }
    
    // ════════════════════════════════════════════════════════════
    // REGLA 2: Perceived Recovery Status (Helms readiness marker)
    // ════════════════════════════════════════════════════════════
    
    if (features.perceivedRecoveryNorm < 0.4) {
      // PRS <4/10: fatiga alta
      adjustment *= 0.75; // -25% adicional
      reasons.add('PRS muy bajo (<4/10) → -25%');
    } else if (features.perceivedRecoveryNorm < 0.6) {
      // PRS 4-6/10: fatiga moderada
      adjustment *= 0.90; // -10% adicional
      reasons.add('PRS bajo (4-6/10) → -10%');
    } else if (features.perceivedRecoveryNorm > 0.8) {
      // PRS >8/10: bien recuperado
      if (adjustment >= 1.0) {
        adjustment *= 1.03; // ✅ AJUSTADO: +3% (conservador dentro de range good/excellent)
        reasons.add('PRS alto (>8/10) → +3%');
      }
    }
    
    // ════════════════════════════════════════════════════════════
    // REGLA 3: Fatigue Index (Helms RPE autoregulation)
    // ════════════════════════════════════════════════════════════
    
    if (features.fatigueIndex > 0.6) {
      // Fatiga alta acumulada
      adjustment *= 0.80; // -20% adicional
      reasons.add('Fatiga acumulada alta → -20%');
    } else if (features.fatigueIndex < 0.3) {
      // Bien recuperado, puede progresar
      if (adjustment >= 1.0 && features.readinessScore > 0.7) {
        adjustment *= 1.05; // ✅ AJUSTADO: +5% (dentro de range excellent)
        reasons.add('Baja fatiga + alta readiness → +5%');
      }
    }
    
    // ════════════════════════════════════════════════════════════
    // REGLA 4: Recovery Capacity (Schoenfeld sleep + stress)
    // ════════════════════════════════════════════════════════════
    
    if (features.recoveryCapacity < 0.4) {
      // Mala recuperación (sueño/estrés)
      adjustment *= 0.85; // -15% adicional
      reasons.add('Capacidad de recuperación baja → -15%');
    } else if (features.recoveryCapacity > 0.7) {
      // Buena recuperación
      if (adjustment >= 1.0) {
        adjustment *= 1.03; // ✅ AJUSTADO: +3% conservador
        reasons.add('Buena capacidad de recuperación → +3%');
      }
    }
    
    // ════════════════════════════════════════════════════════════
    // REGLA 5: Training Maturity (Israetel MRV progression)
    // ════════════════════════════════════════════════════════════
    
    if (features.trainingMaturity > 0.8) {
      // Atleta maduro (>3 años consistentes)
      if (adjustment >= 1.0 && features.overreachingRisk < 0.5) {
        adjustment *= 1.05; // +5% (pueden tolerar más)
        reasons.add('Atleta maduro con capacidad → +5%');
      }
    } else if (features.trainingMaturity < 0.3) {
      // Principiante o inconsistente
      // ✅ AJUSTADO: Limitar a range good (0.95-1.0) máximo
      adjustment = adjustment.clamp(0.5, 1.0);
      reasons.add('Atleta principiante → progresión conservadora');
    }
    
    // ════════════════════════════════════════════════════════════
    // REGLA 6: Performance Trend (validación externa)
    // ════════════════════════════════════════════════════════════
    
    if (features.performanceTrendEncoded < 0.3) {
      // Declining performance
      adjustment *= 0.80; // -20% adicional
      reasons.add('Rendimiento declinando → -20% (señal de fatiga)');
    } else if (features.performanceTrendEncoded > 0.8) {
      // Improving performance
      if (adjustment >= 1.0) {
        adjustment *= 1.05; // +5%
        reasons.add('Rendimiento mejorando → +5%');
      }
    }
    
    // ════════════════════════════════════════════════════════════
    // REGLA 7: Volume Optimality (Schoenfeld dose-response)
    // ════════════════════════════════════════════════════════════
    
    if (features.volumeOptimalityIndex > 0.9) {
      // Cerca o excediendo MRV (>2.7x MEV)
      // ✅ AJUSTADO: Solo mantener o reducir (max 1.0)
      adjustment = adjustment.clamp(0.5, 1.0);
      reasons.add('Volumen cerca de MRV → evitar progresión');
    } else if (features.volumeOptimalityIndex < 0.5) {
      // Muy por debajo de MEV (<1.5x MEV)
      if (adjustment >= 1.0 && features.readinessScore > 0.6) {
        adjustment *= 1.08; // +8% (tiene margen amplio)
        reasons.add('Volumen bajo de MEV → +8%');
      }
    }
    
    // ════════════════════════════════════════════════════════════
    // ✅ NUEVO: CLAMP POR READINESS LEVEL (Alineado con Phase2)
    // ════════════════════════════════════════════════════════════
    
    // Inferir ReadinessLevel desde readinessScore
    final inferredLevel = _inferReadinessLevel(features.readinessScore);
    
    // Aplicar clamps específicos por nivel (match Phase2)
    adjustment = _clampByReadinessLevel(adjustment, inferredLevel);
    
    // Agregar metadata sobre clamp aplicado
    reasons.add(
      'Clamp aplicado por nivel ${inferredLevel.name}: ${adjustment.toStringAsFixed(2)}'
    );
    
    // ════════════════════════════════════════════════════════════
    // REASONING FINAL
    // ════════════════════════════════════════════════════════════
    
    String finalReasoning;
    if (reasons.isEmpty) {
      finalReasoning = 'Sin ajustes necesarios → mantener volumen';
    } else {
      finalReasoning = reasons.join(' | ');
    }
    
    // Clasificar tipo de decisión
    if (adjustment < 0.8) {
      return VolumeDecision.deload(
        reasoning: finalReasoning,
        factor: adjustment,
      );
    } else if (adjustment > 1.02) {
      return VolumeDecision.progress(
        reasoning: finalReasoning,
        factor: adjustment,
      );
    } else {
      return VolumeDecision.maintain(
        reasoning: finalReasoning,
      );
    }
  }
  
  @override
  ReadinessDecision decideReadiness(FeatureVector features) {
    final recommendations = <String>[];
    
    // ════════════════════════════════════════════════════════════
    // CÁLCULO DE READINESS SCORE
    // ════════════════════════════════════════════════════════════
    
    // Usar el score derivado del FeatureVector (ya calculado)
    double score = features.readinessScore;
    
    // Ajustes adicionales basados en otras features
    
    // Penalización por sueño insuficiente
    if (features.avgSleepHoursNorm < 0.5) { // <6h
      score *= 0.85;
      recommendations.add('Mejorar cantidad de sueño (objetivo: 7-9h)');
    }
    
    // Penalización por estrés alto
    if (features.stressLevelNorm > 0.7) {
      score *= 0.90;
      recommendations.add('Gestionar estrés (técnicas de relajación, mindfulness)');
    }
    
    // Penalización por DOMS persistente
    if (features.soreness48hNorm > 0.7) {
      score *= 0.92;
      recommendations.add('DOMS alto a 48h → considerar más recuperación activa');
    }
    
    // Bonus por buenos hábitos de recuperación
    if (features.recoveryCapacity > 0.7) {
      score *= 1.05;
    }
    
    // Clamp final
    score = score.clamp(0.0, 1.0);
    
    // ════════════════════════════════════════════════════════════
    // ✅ ACTUALIZADO: THRESHOLDS ALINEADOS CON PHASE2
    // ════════════════════════════════════════════════════════════
    
    ReadinessLevel level;
    if (score < 0.40) { // ✅ AJUSTADO: era 0.30, ahora 0.40 (match Phase2)
      level = ReadinessLevel.critical;
      recommendations.add('CRÍTICO: Deload o semana de descanso activo');
    } else if (score < 0.55) { // ✅ AJUSTADO: era 0.50, ahora 0.55 (match Phase2)
      level = ReadinessLevel.low;
      recommendations.add('Reducir volumen 20-35%');
    } else if (score < 0.70) {
      level = ReadinessLevel.moderate;
      recommendations.add('Mantener volumen conservador');
    } else if (score < 0.85) {
      level = ReadinessLevel.good;
      recommendations.add('Volumen normal, puede progresar moderadamente');
    } else {
      level = ReadinessLevel.excellent;
      recommendations.add('Puede manejar volumen alto o intensificación');
    }
    
    // ════════════════════════════════════════════════════════════
    // RECOMENDACIONES ESPECÍFICAS POR FEATURE
    // ════════════════════════════════════════════════════════════
    
    // RIR no óptimo
    if (features.rirOptimalityScore < 0.6) {
      if (features.averageRIRNorm < 0.3) {
        recommendations.add('Aumentar RIR (evitar fallo muscular frecuente)');
      } else {
        recommendations.add('Disminuir RIR (acercarse más al fallo, RIR 2-3)');
      }
    }
    
    // Adherencia baja
    if (features.adherenceHistorical < 0.7) {
      recommendations.add('Adherencia baja → simplificar plan o reducir frecuencia');
    }
    
    // Pausas frecuentes
    if (features.periodBreaksNorm > 0.5) {
      recommendations.add('Pausas frecuentes → investigar barreras de adherencia');
    }
    
    // Performance declining
    if (features.performanceTrendEncoded < 0.3) {
      recommendations.add('Rendimiento declinando → DELOAD recomendado');
    }
    
    return ReadinessDecision(
      level: level,
      score: score,
      confidence: 0.85, // Alta confianza en reglas científicas
      recommendations: recommendations,
      metadata: {
        'strategy': 'rule_based',
        'version': version,
        'fatigueIndex': features.fatigueIndex,
        'recoveryCapacity': features.recoveryCapacity,
        'overreachingRisk': features.overreachingRisk,
      },
    );
  }
  
  // ════════════════════════════════════════════════════════════
  // ✅ NUEVO: MÉTODOS HELPER PARA ALINEACIÓN CON PHASE2
  // ════════════════════════════════════════════════════════════
  
  /// Infiere ReadinessLevel desde readinessScore usando thresholds de Phase2
  ReadinessLevel _inferReadinessLevel(double score) {
    if (score < 0.40) return ReadinessLevel.critical;
    if (score < 0.55) return ReadinessLevel.low;
    if (score < 0.70) return ReadinessLevel.moderate;
    if (score < 0.85) return ReadinessLevel.good;
    return ReadinessLevel.excellent;
  }
  
  /// Clamp volumeAdjustment por ReadinessLevel usando rangos exactos de Phase2
  /// 
  /// Rangos basados en:
  /// lib/domain/services/phase_2_readiness_evaluation_service.dart
  /// líneas 1154-1246 (_calculateVolumeAdjustmentV2)
  double _clampByReadinessLevel(double adjustment, ReadinessLevel level) {
    switch (level) {
      case ReadinessLevel.critical:
        // Phase2: factor = 0.5 + score * 0.37; // 0.5 - 0.65
        return adjustment.clamp(0.50, 0.65);
        
      case ReadinessLevel.low:
        // Phase2: factor = 0.65 + (score - 0.4) * 0.5; // 0.65 - 0.8
        return adjustment.clamp(0.65, 0.80);
        
      case ReadinessLevel.moderate:
        // Phase2: factor = 0.8 + (score - 0.55) * 0.5; // 0.8 - 0.95
        return adjustment.clamp(0.80, 0.95);
        
      case ReadinessLevel.good:
        // Phase2: factor = 0.95 + (score - 0.7) * 0.33; // 0.95 - 1.0
        return adjustment.clamp(0.95, 1.00);
        
      case ReadinessLevel.excellent:
        // Phase2: factor = 1.0 + (score - 0.85) * 0.5; // 1.0 - 1.15
        return adjustment.clamp(1.00, 1.15);
    }
  }
}
