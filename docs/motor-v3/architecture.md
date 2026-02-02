# Motor V3 - Arquitectura Completa

## Resumen Ejecutivo

Motor V3 es un sistema completo de generación y adaptación de programas de entrenamiento **reactivo, personalizado e inteligente**, basado en **151 imágenes de evidencia científica** procesadas del Lic. Jay Ehrenstein (APEKS/Icoan/NFA).

**Características Clave**:
- **5 capas arquitectónicas**: Knowledge Base → Generation → Personalization → Reactive → AI/ML
- **14+ engines especializados**: Cada uno implementa ciencia específica
- **Sistema de bitácora**: Feedback loop bidireccional
- **Gráficas analíticas**: 6 tipos de visualizaciones
- **100% basado en evidencia**: 50+ estudios científicos citados

---

## 1. Arquitectura de 5 Capas

```
┌─────────────────────────────────────────────────────────────┐
│ CAPA 5: IA/ML (Preparación Futura)                         │
│ • PredictionEngine                                          │
│ • PatternDetectionEngine                                    │
│ • RecommendationEngine                                      │
│ • LearningEngine                                            │
└─────────────────────────────────────────────────────────────┘
                             ▲
┌─────────────────────────────────────────────────────────────┐
│ CAPA 4: Motor Reactivo                                     │
│ • LoadProgressionEngine      • DeloadTriggerEngine         │
│ • VolumeProgressionEngine    • WorkoutLogProcessor         │
│ • MonitoringEngine                                          │
└─────────────────────────────────────────────────────────────┘
                             ▲
┌─────────────────────────────────────────────────────────────┐
│ CAPA 3: Personalización Adaptativa                         │
│ • ExerciseSwapEngine         • PreferenceEngine            │
│ • ExerciseFeedbackEngine     • InjuryPreventionEngine      │
└─────────────────────────────────────────────────────────────┘
                             ▲
┌─────────────────────────────────────────────────────────────┐
│ CAPA 2: Generación Inteligente                             │
│ • SplitGeneratorEngine       • OrderingEngine              │
│ • ExerciseSelectionEngine    • VolumeEngine                │
│ • IntensityEngine            • EffortEngine                 │
└─────────────────────────────────────────────────────────────┘
                             ▲
┌─────────────────────────────────────────────────────────────┐
│ CAPA 1: Base de Conocimiento                               │
│ • 151 imágenes científicas   • 50+ estudios                │
│ • Constantes y landmarks     • Validadores                 │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Capa 1: Base de Conocimiento

### 2.1 Material Científico

**7 Semanas de Evidencia**:
1. Semana 1-2: Volumen (35 imágenes) → `01-volume.md`
2. Semana 3: Intensidad (12 imágenes) → `02-intensity.md`
3. Semana 4: Esfuerzo/RIR (43 imágenes) → `03-effort-rir.md`
4. Semana 5: Selección de Ejercicios (26 imágenes) → `04-exercise-selection.md`
5. Semana 6: Configuración y Distribución (14 imágenes) → `05-configuration-distribution.md`
6. Semana 7: Progresión y Variación (13 imágenes) → `06-progression-variation.md`
7. Suplementario: Técnicas de Intensificación (8 imágenes) → `07-intensification-techniques.md`

### 2.2 Constantes Científicas

**Archivo**: `lib/domain/training_v3/constants/scientific_constants.dart`

```dart
class ScientificConstants {
  // Volumen Landmarks (Semana 1-2)
  static const Map<String, VolumeLandmarks> muscleLandmarks = {
    'chest': VolumeLandmarks(mev: 6, mav: 14, mrv: 20),
    'lats': VolumeLandmarks(mev: 8, mav: 16, mrv: 24),
    'quads': VolumeLandmarks(mev: 8, mav: 15, mrv: 25),
    // ... 20+ músculos
  };
  
  // Intensidad Distribution (Semana 3)
  static const Map<String, double> intensityRatios = {
    'heavy': 0.35,    // 30-40%
    'moderate': 0.50, // 40-50%
    'light': 0.15,    // 10-20%
  };
  
  // RIR por Contexto (Semana 4)
  static int getRIR({
    required ExerciseCategory category,
    required IntensityZone zone,
  }) {
    if (category == ExerciseCategory.compound && zone == IntensityZone.heavy) {
      return 3; // Seguridad en compuestos pesados
    }
    if (category == ExerciseCategory.isolation) {
      return 1; // Maximizar en aislados
    }
    return 2; // Default
  }
  
  // Frecuencia Óptima (Semana 6)
  static const Map<String, FrequencyRange> frequencyByMuscle = {
    'chest': FrequencyRange(min: 2, optimal: 2, max: 3),
    'quads': FrequencyRange(min: 2, optimal: 3, max: 4),
    // ...
  };
}
```

### 2.3 Validadores

**Archivos**:
- `lib/domain/training_v3/validators/volume_validator.dart`
- `lib/domain/training_v3/validators/intensity_validator.dart`
- `lib/domain/training_v3/validators/effort_validator.dart`
- `lib/domain/training_v3/validators/configuration_validator.dart`

Validan que programas generados cumplan con ciencia documentada.

---

## 3. Capa 2: Generación Inteligente

### 3.1 Pipeline de Generación

```
Input: UserProfile
  ↓
[VolumeEngine] → Calcula MEV/MAV/MRV por músculo
  ↓
[SplitGeneratorEngine] → Determina split óptimo (PPL/UL/FB)
  ↓
[ExerciseSelectionEngine] → Selecciona ejercicios (6 criterios)
  ↓
[OrderingEngine] → Ordena ejercicios (4 directrices)
  ↓
[IntensityEngine] → Asigna zonas heavy/moderate/light
  ↓
[EffortEngine] → Asigna RIR por set
  ↓
Output: TrainingProgram
```

### 3.2 Volume Engine

**Responsabilidad**: Calcular volumen óptimo por músculo

```dart
class VolumeEngine {
  Map<String, int> calculateVolume({
    required UserProfile user,
    required Map<String, int> priorities, // 1=primary, 2=secondary, 3=tertiary
  }) {
    final volumes = <String, int>{};
    
    for (var muscle in priorities.keys) {
      // Obtener landmarks base
      final landmarks = ScientificConstants.muscleLandmarks[muscle]!;
      
      // Calcular MAV personalizado
      double mav = landmarks.mav.toDouble();
      
      // Ajuste por nivel de entrenamiento
      mav *= switch (user.trainingLevel) {
        'beginner' => 0.8,
        'intermediate' => 1.0,
        'advanced' => 1.2,
      };
      
      // Ajuste por recuperación
      if (user.sleepQuality < 4 || user.stressLevel > 3) {
        mav *= 0.9; // Reducir si recuperación pobre
      }
      
      // Ajuste por prioridad
      mav *= switch (priorities[muscle]!) {
        1 => 1.2,  // Primary: +20%
        2 => 1.0,  // Secondary: baseline
        3 => 0.8,  // Tertiary: -20%
        _ => 1.0,
      };
      
      volumes[muscle] = mav.round().clamp(landmarks.mev, landmarks.mrv);
    }
    
    return volumes;
  }
}
```

### 3.3 Split Generator Engine

**Responsabilidad**: Seleccionar split óptimo

```dart
class SplitGeneratorEngine {
  SplitType selectSplit({
    required int daysPerWeek,
    required TrainingLevel level,
    required List<String> priorities,
  }) {
    // Regla 1: Principiantes → Full Body
    if (level == TrainingLevel.beginner) {
      return SplitType.fullBody;
    }
    
    // Regla 2: Días disponibles
    if (daysPerWeek <= 3) {
      return SplitType.fullBody; // Máxima frecuencia
    } else if (daysPerWeek == 4) {
      return SplitType.upperLower; // Balance
    } else if (daysPerWeek >= 5) {
      return SplitType.ppl; // Distribución óptima
    }
    
    return SplitType.upperLower; // Default seguro
  }
}
```

### 3.4 Exercise Selection Engine

**Responsabilidad**: Seleccionar ejercicios por 6 criterios científicos

```dart
class ExerciseSelectionEngine {
  List<Exercise> selectForMuscle({
    required String muscle,
    required int targetSets,
    required UserProfile user,
    required List<Exercise> availableExercises,
  }) {
    // 1. Filtrar disponibles
    var candidates = availableExercises.where((e) => 
      e.primaryMuscles.contains(muscle) &&
      user.availableEquipment.containsAll(e.equipment)
    ).toList();
    
    // 2. Evaluar por matriz de 6 criterios
    final scored = candidates.map((e) => 
      ExerciseScore(exercise: e, score: _evaluateExercise(e, muscle, user))
    ).toList()..sort((a, b) => b.score.compareTo(a.score));
    
    // 3. Estratificación: 60% compuestos, 40% aislados
    final selected = <Exercise>[];
    int setsAssigned = 0;
    
    // Compuestos (verde score >= 4.0)
    final compounds = scored
      .where((s) => s.exercise.category == 'compound' && s.score >= 4.0)
      .take(2)
      .toList();
    
    for (var c in compounds) {
      int sets = (targetSets * 0.3).round();
      selected.add(c.exercise.copyWith(sets: sets));
      setsAssigned += sets;
    }
    
    // Aislados
    final remaining = targetSets - setsAssigned;
    final isolations = scored
      .where((s) => s.exercise.category == 'isolation' && s.score >= 3.0)
      .take(3)
      .toList();
    
    final setsPerIso = (remaining / isolations.length).round();
    for (var iso in isolations) {
      selected.add(iso.exercise.copyWith(sets: setsPerIso));
    }
    
    return selected;
  }
  
  double _evaluateExercise(Exercise e, String muscle, UserProfile user) {
    // Aplicar ponderación de 6 criterios (ver 04-exercise-selection.md)
    return (
      _scoreResistanceCurve(e) * 0.15 +
      _scoreAngleLength(e, muscle) * 0.25 +
      _scoreROM(e) * 0.20 +
      _scoreOverload(e) * 0.25 +
      _scoreComplexity(e, user.trainingLevel) * 0.10 +
      _scoreJointStress(e, user.injuries) * 0.05
    );
  }
}
```

### 3.5 Ordering Engine

**Responsabilidad**: Ordenar ejercicios por 4 directrices científicas

```dart
class OrderingEngine {
  List<Exercise> orderExercises(List<Exercise> exercises) {
    return exercises..sort((a, b) {
      // Directriz 1: Complejidad técnica (compuestos primero)
      if (a.technicalComplexity != b.technicalComplexity) {
        return b.technicalComplexity.compareTo(a.technicalComplexity);
      }
      
      // Directriz 2: Tamaño muscular (grandes primero)
      final aMuscleSize = _getMuscleSize(a.primaryMuscles[0]);
      final bMuscleSize = _getMuscleSize(b.primaryMuscles[0]);
      if (aMuscleSize != bMuscleSize) {
        return bMuscleSize.compareTo(aMuscleSize);
      }
      
      // Directriz 3: Prioridad individual
      // (si configurado en user profile)
      
      // Directriz 4: Sinergia (agrupar patrones similares)
      return 0;
    });
  }
}
```

### 3.6 Intensity & Effort Engines

**IntensityEngine**: Distribuye 35% heavy, 50% moderate, 15% light  
**EffortEngine**: Asigna RIR 0-4 según contexto

---

## 4. Capa 3: Personalización Adaptativa

### 4.1 Exercise Swap Engine

**Responsabilidad**: Intercambiar ejercicios manteniendo estímulo equivalente

```dart
class ExerciseSwapEngine {
  Exercise? findSwap({
    required Exercise current,
    required List<Exercise> availableExercises,
    required String reason, // 'injury', 'preference', 'equipment'
  }) {
    return availableExercises.firstWhereOrNull((candidate) =>
      candidate.id != current.id &&
      candidate.movementPattern == current.movementPattern &&
      candidate.primaryMuscles[0] == current.primaryMuscles[0] &&
      (candidate.score - current.score).abs() < 0.3 &&
      _isCompatibleWithReason(candidate, reason)
    );
  }
}
```

### 4.2 Exercise Feedback Engine

**Responsabilidad**: Detectar ejercicios problemáticos y actuar

```dart
class ExerciseFeedbackEngine {
  void processSessionFeedback(WorkoutLog log) {
    for (var exerciseLog in log.exercises) {
      if (exerciseLog.feedback != null) {
        final feedback = exerciseLog.feedback!;
        
        switch (feedback.type) {
          case FeedbackType.painful:
            _handlePainfulExercise(exerciseLog.exerciseId, feedback);
            break;
          case FeedbackType.noStimulus:
            _handleNoStimulus(exerciseLog.exerciseId);
            break;
          case FeedbackType.difficultyMismatch:
            _handleDifficultyMismatch(exerciseLog, feedback);
            break;
        }
      }
    }
  }
  
  void _handlePainfulExercise(String exerciseId, ExerciseFeedback feedback) {
    // Registrar lesión potencial
    _injuryRepository.recordPainEvent(
      exerciseId: exerciseId,
      location: feedback.painLocation!,
      severity: feedback.severity!,
    );
    
    // Si severidad >= 7 → reemplazar inmediatamente
    if (feedback.severity! >= 7) {
      _swapEngine.replaceExercise(exerciseId, reason: 'injury');
    }
  }
}
```

---

## 5. Capa 4: Motor Reactivo

### 5.1 Workflow Reactivo

```
Usuario entrena → Registra en WorkoutLog
  ↓
[WorkoutLogProcessor] Analiza log vs plan
  ↓
[MonitoringEngine] Detecta patrones fatiga/progreso
  ↓
[LoadProgressionEngine] Ajusta cargas automáticamente
  ↓
[VolumeProgressionEngine] Ajusta volumen fase-dependiente
  ↓
[DeloadTriggerEngine] Activa deload si necesario
  ↓
Plan actualizado → Usuario recibe next workout
```

### 5.2 Workout Log Processor

**Responsabilidad**: Comparar plan vs realidad

```dart
class WorkoutLogProcessor {
  PerformanceData processWeeklyLogs(List<WorkoutLog> weekLogs) {
    final byMuscle = <String, MusclePerformance>{};
    
    for (var muscle in allMuscles) {
      final muscleExercises = _filterByMuscle(weekLogs, muscle);
      
      byMuscle[muscle] = MusclePerformance(
        muscle: muscle,
        totalSets: _countSets(muscleExercises),
        averageLoad: _calculateAvgLoad(muscleExercises),
        averageReps: _calculateAvgReps(muscleExercises),
        averageRIR: _calculateAvgRIR(muscleExercises),
        isProgressing: _detectProgression(muscleExercises),
        isRegressing: _detectRegression(muscleExercises),
        weeksStagnant: _countStagnantWeeks(muscle),
      );
    }
    
    return PerformanceData(
      userId: weekLogs[0].userId,
      weekStart: weekLogs[0].date,
      weekEnd: weekLogs.last.date,
      byMuscle: byMuscle,
      weeklyFatigueScore: _calculateFatigue(weekLogs),
      fatiguePattern: _detectFatiguePattern(weekLogs),
      loadProgressionByMuscle: _calculateProgression(byMuscle),
      volumeProgressionByMuscle: _calculateVolumeChange(byMuscle),
    );
  }
}
```

### 5.3 Load Progression Engine

**Responsabilidad**: Incrementar cargas automáticamente

```dart
class LoadProgressionEngine {
  Map<String, double> calculateNewLoads({
    required PerformanceData lastWeek,
    required Map<String, ExercisePrescription> currentPlan,
  }) {
    final newLoads = <String, double>{};
    
    for (var exerciseId in currentPlan.keys) {
      final prescription = currentPlan[exerciseId]!;
      final performance = lastWeek.getExercisePerformance(exerciseId);
      
      if (performance == null) continue;
      
      // Regla: Si completó todas reps con RIR <= objetivo → subir carga
      if (performance.completedAllReps && performance.avgRIR <= prescription.rir) {
        double increment = switch (prescription.zone) {
          IntensityZone.heavy => 2.5, // kg, compuestos pesados
          IntensityZone.moderate => 2.0,
          IntensityZone.light => 1.0,
        };
        
        newLoads[exerciseId] = performance.lastLoad + increment;
      } else {
        newLoads[exerciseId] = performance.lastLoad; // Mantener
      }
    }
    
    return newLoads;
  }
}
```

### 5.4 Deload Trigger Engine

**Responsabilidad**: Detectar necesidad de deload

```dart
class DeloadTriggerEngine {
  bool shouldTriggerDeload(PerformanceData data) {
    // Criterio 1: Volumen > 90% MRV por 2+ semanas
    final highVolumeWeeks = _countHighVolumeWeeks(data.userId);
    if (highVolumeWeeks >= 2) return true;
    
    // Criterio 2: Fatiga score < 15 (zona roja)
    if (data.weeklyFatigueScore < 15) return true;
    
    // Criterio 3: Regresión en 2+ músculos
    final regressingMuscles = data.byMuscle.values
      .where((m) => m.isRegressing)
      .length;
    if (regressingMuscles >= 2) return true;
    
    // Criterio 4: 4+ semanas desde último deload
    final weeksSinceDeload = _getWeeksSinceLastDeload(data.userId);
    if (weeksSinceDeload >= 4) return true;
    
    return false;
  }
}
```

---

## 6. Capa 5: IA/ML (Preparación Futura)

### 6.1 Engines Preparados

- **PredictionEngine**: Predicción de progresión óptima
- **PatternDetectionEngine**: Detecta patrones de fatiga
- **RecommendationEngine**: Recomendaciones personalizadas
- **LearningEngine**: Aprendizaje continuo del usuario

**Integración Actual**: Motor V3 ya registra datos en Firestore para futuro ML training.

---

## 7. Orquestador Maestro

### 7.1 MotorV3Orchestrator

**Responsabilidad**: Coordinar todos los engines

```dart
class MotorV3Orchestrator {
  final VolumeEngine _volumeEngine;
  final SplitGeneratorEngine _splitEngine;
  final ExerciseSelectionEngine _selectionEngine;
  final OrderingEngine _orderingEngine;
  final IntensityEngine _intensityEngine;
  final EffortEngine _effortEngine;
  final WorkoutLogProcessor _logProcessor;
  // ... otros engines
  
  Future<TrainingProgram> generateProgram(UserProfile user) async {
    // 1. Calcular volumen
    final volumes = _volumeEngine.calculateVolume(
      user: user,
      priorities: user.musclePriorities,
    );
    
    // 2. Seleccionar split
    final split = _splitEngine.selectSplit(
      daysPerWeek: user.daysPerWeek,
      level: user.trainingLevel,
      priorities: user.musclePriorities.keys.toList(),
    );
    
    // 3. Generar sesiones
    final sessions = <TrainingSession>[];
    for (var day in split.days) {
      final exercises = <Exercise>[];
      
      for (var muscle in day.muscles) {
        // 3a. Seleccionar ejercicios
        final selected = _selectionEngine.selectForMuscle(
          muscle: muscle,
          targetSets: volumes[muscle]!,
          user: user,
          availableExercises: await _exerciseRepository.getAll(),
        );
        exercises.addAll(selected);
      }
      
      // 3b. Ordenar
      final ordered = _orderingEngine.orderExercises(exercises);
      
      // 3c. Asignar intensidad
      final withIntensity = _intensityEngine.assignIntensity(ordered);
      
      // 3d. Asignar RIR
      final withEffort = _effortEngine.assignRIR(withIntensity);
      
      sessions.add(TrainingSession(
        day: day.name,
        exercises: withEffort,
      ));
    }
    
    return TrainingProgram(
      userId: user.id,
      weeks: _buildWeeks(sessions, user),
      createdAt: DateTime.now(),
    );
  }
  
  Future<TrainingProgram> adaptProgram({
    required TrainingProgram current,
    required List<WorkoutLog> weekLogs,
  }) async {
    // 1. Procesar logs
    final performance = _logProcessor.processWeeklyLogs(weekLogs);
    
    // 2. Verificar necesidad de deload
    if (_deloadTrigger.shouldTriggerDeload(performance)) {
      return _generateDeloadWeek(current);
    }
    
    // 3. Progresión de cargas
    final newLoads = _loadProgression.calculateNewLoads(
      lastWeek: performance,
      currentPlan: current.getCurrentWeek(),
    );
    
    // 4. Progresión de volumen (fase-dependiente)
    final newVolumes = _volumeProgression.calculateNewVolumes(
      current: current.getVolumes(),
      phase: current.currentPhase,
    );
    
    // 5. Reconstruir programa con ajustes
    return current.copyWith(
      loads: newLoads,
      volumes: newVolumes,
      weekNumber: current.weekNumber + 1,
    );
  }
}
```

---

## 8. Flujo de Datos Completo

```
┌──────────────────┐
│  User Profile    │
│ (edad, nivel,    │
│  prioridades,    │
│  equipamiento)   │
└────────┬─────────┘
         │
         ▼
┌─────────────────────────────────────┐
│  MotorV3Orchestrator.generateProgram│
└────────┬────────────────────────────┘
         │
         ▼
┌────────────────────────────────────────┐
│ TrainingProgram (4 semanas × N sesiones│
│ × M ejercicios con sets/reps/RIR)     │
└────────┬───────────────────────────────┘
         │
         ▼
┌──────────────────┐
│ Usuario Entrena  │◄─────────────┐
└────────┬─────────┘              │
         │                        │
         ▼                        │
┌──────────────────┐              │
│  WorkoutLog      │              │
│ (sets, reps,     │              │
│  cargas, RIR,    │              │
│  feedback)       │              │
└────────┬─────────┘              │
         │                        │
         ▼                        │
┌──────────────────────────┐     │
│ WorkoutLogProcessor      │     │
│ → PerformanceData        │     │
└────────┬─────────────────┘     │
         │                       │
         ▼                       │
┌────────────────────────────┐  │
│ MonitoringEngine           │  │
│ (detecta fatiga, progreso) │  │
└────────┬───────────────────┘  │
         │                      │
         ▼                      │
    [¿Deload?]                 │
         │                      │
    ┌────┴────┐                │
    │         │                │
   Sí        No                │
    │         │                │
    ▼         ▼                │
 Deload   Progresión           │
  Week      Normal             │
    │         │                │
    └────┬────┘                │
         │                     │
         ▼                     │
┌────────────────────────┐    │
│ Programa Actualizado   │────┘
└────────────────────────┘
```

---

## 9. Directorio de Archivos

```
lib/domain/training_v3/
├── models/
│   ├── user_profile.dart
│   ├── training_program.dart
│   ├── training_session.dart
│   ├── exercise.dart
│   ├── workout_log.dart
│   ├── exercise_log.dart
│   ├── set_log.dart
│   ├── exercise_feedback.dart
│   ├── performance_data.dart
│   ├── muscle_performance.dart
│   ├── fatigue_pattern.dart
│   ├── progression_plan.dart
│   ├── training_phase.dart (enum)
│   └── feedback_type.dart (enum)
│
├── engines/
│   ├── split_generator_engine.dart
│   ├── exercise_selection_engine.dart
│   ├── volume_engine.dart
│   ├── intensity_engine.dart
│   ├── effort_engine.dart
│   ├── ordering_engine.dart
│   ├── exercise_swap_engine.dart
│   ├── exercise_feedback_engine.dart
│   ├── load_progression_engine.dart
│   ├── volumetric_progression_engine.dart
│   ├── monitoring_engine.dart
│   ├── deload_trigger_engine.dart
│   ├── workout_log_processor.dart
│   └── intensification_techniques_engine.dart
│
├── validators/
│   ├── volume_validator.dart
│   ├── intensity_validator.dart
│   ├── effort_validator.dart
│   └── configuration_validator.dart
│
├── services/
│   ├── motor_v3_orchestrator.dart
│   ├── analytics_service.dart
│   └── chart_generator_service.dart
│
├── repositories/
│   ├── exercise_database_repository.dart
│   ├── workout_log_repository.dart
│   └── performance_data_repository.dart
│
└── constants/
    └── scientific_constants.dart
```

---

## 10. Integraciones

### 10.1 Con Firestore

```dart
// Guardar logs
await FirebaseFirestore.instance
  .collection('workout_logs')
  .doc(logId)
  .set(workoutLog.toJson());

// Recuperar performance data
final snapshot = await FirebaseFirestore.instance
  .collection('performance_data')
  .doc(userId)
  .get();
```

### 10.2 Con Assets

```dart
// Cargar base de ejercicios
final String jsonString = await rootBundle.loadString(
  'assets/data/exercises/exercises_database.json'
);
final exercisesData = json.decode(jsonString);
```

---

## 11. Ventajas sobre Motor Legacy

| Aspecto | Legacy | Motor V3 |
|---------|--------|----------|
| **Base científica** | Parcial | 151 imágenes documentadas |
| **Engines** | 8 phases monolíticas | 14+ engines modulares |
| **Reactividad** | Nula | Completa (4 engines reactivos) |
| **Personalización** | Genérica | Individual (historial, feedback) |
| **Validación** | Manual | Automática (4 validadores) |
| **Gráficas** | 0 | 6 tipos implementados |
| **Documentación** | Básica | 13 docs (7 científicos + 6 técnicos) |
| **Testabilidad** | Difícil | Fácil (engines independientes) |

---

**Versión**: 3.0.0  
**Autor**: HCS Team  
**Fecha**: Febrero 2026  
**Basado en**: Lic. Jay Ehrenstein - APEKS/Icoan/NFA (151 imágenes científicas)
