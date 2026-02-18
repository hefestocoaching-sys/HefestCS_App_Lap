# 📚 Motor V3 Enhanced - Quick Reference

**TL;DR:** Copia y pega esto para empezar

---

## 🚀 Importaciones

```dart
// Modelos
import 'package:hcs_app_lap/domain/training_v3/models/muscle_progression.dart';
import 'package:hcs_app_lap/domain/training_v3/models/progress_record.dart';
import 'package:hcs_app_lap/domain/training_v3/models/feedback_entry.dart';
import 'package:hcs_app_lap/domain/training_v3/models/exercise_angle_coverage.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_audit_log.dart';

// Servicios
import 'package:hcs_app_lap/domain/training_v3/services/weekly_progression_service_enhanced.dart';
import 'package:hcs_app_lap/domain/training_v3/services/weekly_progression_service_enhanced_impl.dart';

// Validadores
import 'package:hcs_app_lap/domain/training_v3/validators/training_validation_engine.dart';

// Repos
import 'package:hcs_app_lap/domain/training_v3/repositories/muscle_progression_repository_impl.dart';
```

---

## ⚙️ Setup

```dart
// 1. Crear repositories
final progressionRepo = MuscleProgressionRepositoryImpl();
final analysisRepo = WeeklyMuscleAnalysisRepositoryImpl();

// 2. Crear servicio
final service = WeeklyProgressionServiceEnhancedImpl(
  progressionRepo: progressionRepo,
  analysisRepo: analysisRepo,
);

// 3. Inicializar trackers (una sola vez por usuario)
await progressionRepo.initializeAllTrackers(
  userId: clientId,
  musclePriorities: {
    'pectorals': 5,      // PRIMARY
    'lats': 5,
    'quadriceps': 5,
    'hamstrings': 3,     // SECONDARY
    'deltoids': 3,
    'triceps': 1,        // TERTIARY
    'back': 5,
    'glutes': 3,
    'adductors': 1,
    'abductors': 1,
    'calves': 1,
    'biceps': 3,
    'abs': 1,
    'forearms': 1,
  },
  trainingLevel: 'intermediate',
  age: 30,
);
```

---

## 🎯 Procesar Semana

```dart
// Colectar feedback usuario
final feedback = {
  'pectorals': FeedbackEntry(
    userId: userId,
    muscle: 'pectorals',
    weekNumber: 8,
    weekStart: DateTime(2026, 2, 8),
    weekEnd: DateTime(2026, 2, 14, 23, 59, 59),
    muscleActivation: 8.5,    // 1-10
    pumpQuality: 8.0,         // 1-10
    fatigueLevel: 5.0,        // 1-10
    recoveryQuality: 7.0,     // 1-10
    hadPain: false,
    deloadRequested: false,   // Override manual
    userComments: 'Felt great!',
    submittedAt: DateTime.now(),
  ),
  // ... otros músculos
};

// PROCESAR
final result = await service.processWeeklyProgressionEnhanced(
  userId: userId,
  weekNumber: 8,
  weekStart: DateTime(2026, 2, 8),
  weekEnd: DateTime(2026, 2, 14, 23, 59, 59),
  exerciseLogs: logsThisWeek,     // List<ExerciseLog>
  feedbackByMuscle: feedback,
);

// RESULTADO
print('Decisions: ${result.decisions}');           // Map<muscle, MuscleDecision>
print('History: ${result.progressRecords}');       // Map<muscle, ProgressRecord>
print('Audit: ${result.auditTrail.length} events'); // List<TrainingAuditLogEntry>
print('Valid: ${result.allValid}');                // bool
print('Report:\n${result.auditReport}');           // String
```

---

## 🔍 Models at a Glance

### MuscleProgression

```dart
final prog = MuscleProgression(
  muscle: 'pectorals',
  priority: 5,              // 5=P, 3=S, 1=T
  landmarks: VolumeLandmarks(...),
  currentSets: 14,
  vopSets: 12,
  mrvSets: 20,
  currentPhase: 'discovering',
  // ... fields
);

// Use
print(prog.volumeCap);              // 20 (MRV for PRIMARY)
print(prog.canProgress);            // true/false
print(prog.recommendedIncrement);   // +2, +1, or 0
print(prog.shouldAutoDeload);       // Schedule deload?
print(prog.healthScore);            // 0-100
```

### ProgressRecord

```dart
final record = ProgressRecord(
  userId: 'user123',
  muscle: 'pectorals',
  weekNumber: 8,
  volumePrescribed: 14,
  volumePerformed: 13,
  volumeAdherence: 0.93,    // 13/14
  // ... many fields
  volumeAction: 'increase',
  newVolume: 16,
  decisionReason: 'PRIMARY: Progressing...',
);

// Use
print(record.wasProgressiveWeek);     // Good week?
print(record.shouldDeload);           // Deload needed?
print(record.volumeChangePercent);    // +14%
```

### FeedbackEntry

```dart
final feedback = FeedbackEntry(
  user muscle: 'pectorals',
  muscleActivation: 8.5,
  fatigueLevel: 5.0,
  deloadRequested: false,
);

// Use
print(feedback.healthScore);            // 0-100
print(feedback.needsDeload);            // true/false
print(feedback.progressionConfidence);  // 0.0-1.0
```

### ExerciseAngleCoverage

```dart
final coverage = ExerciseAngleCoverage(
  muscle: 'pectorals',
  angleExerciseMap: {
    'horizontal': ['bench_press', 'pec_deck'],
    'incline': ['incline_press'],
  },
  coverageRatio: 0.67,
  changedFromLastWeek: true,
);

// Use
print(coverage.hasGoodCoverage);          // >=70%?
print(coverage.coveredAngles);            // ['horizontal', 'incline']
print(coverage.missingAngles);            // ['decline', 'vertical']
```

### TrainingAuditLogEntry

```dart
final log = TrainingAuditLogEntry(
  userId: 'user123',
  eventType: AuditEventType.volumeAdjusted,
  muscleAffected: 'pectorals',
  weekNumber: 8,
  title: 'increase | pectorals',
  severity: 'info',
  volumeBefore: 14,
  volumeAfter: 16,
  actorType: 'motor',
  timestamp: DateTime.now(),
);

// Use
print(log.severity icon);    // "ℹ️" (info), "⚠️" (warning), etc.
print(log.displayString);    // "[2026-02-14 10:30:45] increase | pectorals..."
print(log.volumeChangePercent); // 14.3%
```

---

## ✅ Validación

```dart
final validator = TrainingValidationEngine();

// Validar MuscleProgression
final mpResult = validator.validateMuscleProgression(muscleState);
if (!mpResult.isValid) {
  print('❌ Errors: ${mpResult.errors}');
}

// Validar ProgressRecord
final prResult = validator.validateProgressRecord(record, previousState);
print(prResult.summary); // "✅ PASS | Errors: 0 | Warnings: 2"

// Full weekly audit
final auditResults = validator.validateWeeklyAudit(
  userId: userId,
  weekNumber: 8,
  muscles: musclesMap,
  records: recordsMap,
  angleCoverage: coverageMap,
);

// Generate report
final report = validator.generateWeeklyAuditReport(
  userId: userId,
  weekNumber: 8,
  validationResults: auditResults,
);
print(report);
```

---

## 🧮 Como Decidir por Prioridad

### PRIMARY (P/5): Progresa a MRV

```dart
// Semana 1: 12 sets (VOP)
// Semana 2: 14 sets (+2)
// Semana 3: 16 sets (+2)
// ...
// Semana 5: 20 sets (MRV alcanzado)
// Semana 6: 20 sets (mantiene, en "maintaining" phase)
// ...
// Semana 10: DELOAD a 10 sets (-50%)
// Semana 11: 12 sets (back to discovering)

// Condiciones para progresar:
// - performance_score >= 0.7
// - volume_adherence >= 0.80
// - sin deload trigger (feedback/fatiga)
```

### SECONDARY (S/3): Progresa a 0.8×MRV

```dart
// If MRV = 20, target = 16 sets (0.8×20)
//
// Semana 1: 12 sets (VOP)
// Semana 2: 13 sets (+1)
// Semana 3: 14 sets (+1)
// ...
// Semana 6: 16 sets (0.8×MRV alcanzado)
// Semana 7+: 16 sets (mantiene)
// ...
// Semana 12: DELOAD a 12 sets (-40%)

// Condiciones:
// - performance_score >= 0.65 (menos estricto que P)
// - volume_adherence >= 0.75
// - sin deload trigger
```

### TERTIARY (T/1): Siempre VOP

```dart
// Semana 1-52: VOP sets SIEMPRE
// No progresa, no deload, no feedback effect
//
// Ejemplo VOP = 8 sets
// Semana 1: 8 sets
// Semana 2: 8 sets
// Semana 3: 8 sets
// ...
// Semana 52: 8 sets
```

---

## 📊 Deload Triggers

```dart
bool shouldDeload(FeedbackEntry feedback) {
  // Cualquiera es suficiente:
  return feedback.deloadRequested ||              // Manual override
         feedback.fatigueLevel >= 8.0 ||          // High fatigue
         feedback.recoveryQuality <= 4.0 ||       // Poor recovery
         feedback.hasPainOrInjury;                // Pain/injury
}

// Deload volume:
// PRIMARY: -50% (a VOP/2)
// SECONDARY: -40% (pero >= VOP)
// TERTIARY: N/A (always VOP)
```

---

## 📈 Monitorear Salud del Músculo

```dart
final prog = MuscleProgression(...);

// Tendencia
print('Trend: ${prog.volumeTrend}'); // 'increasing', 'stable', 'decreasing'

// Adherencia últimas 4 semanas
print('Adherence: ${(prog.avgAdherence4Weeks * 100).toStringAsFixed(0)}%');

// Score salud
print('Health: ${prog.healthScore}/100');
if (prog.healthScore >= 70) print('🟢 GREEN');
else if (prog.healthScore >= 40) print('🟡 YELLOW');
else print('🔴 RED');

// Auto deload próximo?
if (prog.shouldAutoDeload) {
  print('⚠️ Auto-deload scheduled in ${prog.weeksUntilAutoDeload - prog.weeksSinceDeload}w');
}
```

---

## 💾 Persistencia

```dart
// El servicio automáticamente:
// ✅ Carga tracker actual
// ✅ Crea ProgressRecord
// ✅ Crea AuditLogEntry
// ✅ Guarda tracker actualizado
// ✅ Loguea decisiones

// Acceso a data:
final tracker = await repo.getTracker(userId, muscle);
final allTrackers = await repo.getAllTrackers(userId);
final progressRecords = await repo.getAllProgressRecords(userId, muscle);
final auditTrail = await auditRepo.getAuditTrail(userId, weekNumber);
```

---

## 🎓 Debugging

```dart
// Enable verbose logging
debugPrint('═══════════════════════════════════════════════════════');
debugPrint('[EnhancedProgression] Week 8 for user $userId');

// Check result
print(result.decisions);      // Map of decisions
print(result.requiresCoachAttention); // List of issues
print(result.auditReport);    // Full report with details

// Export for analysis
final json = result.auditTrail.map((e) => e.toJson()).toList();
// → Save to Firebase or local storage
```

---

## 🚨 Common Issues

| Problema | Causa | Solución |
|----------|-------|----------|
| "No trackers found" | Usuario no inicializado | Llamar `initializeAllTrackers()` |
| Todas decisiones "maintain" | Performance score bajo | Check feedback data |
| Deload inesperado | Fatiga alta/recovery baja | Revisar feedback values |
| Coverage warning | Poco ángulos variados | Diversificar ejercicios |
| Validation error | Primario > MRV | Revisar MRV calculado |

---

## 📝 Ejemplo Completo (Copy-Paste Ready)

```dart
Future<void> processWeekExample() async {
  const userId = 'user_123';
  const weekNumber = 8;
  
  // Setup
  final repo = MuscleProgressionRepositoryImpl();
  final service = WeeklyProgressionServiceEnhancedImpl(
    progressionRepo: repo,
    analysisRepo: WeeklyMuscleAnalysisRepositoryImpl(),
  );
  
  // Feedback from user
  final feedback = {
    'pectorals': FeedbackEntry(
      userId: userId,
      muscle: 'pectorals',
      weekNumber: weekNumber,
      weekStart: DateTime(2026, 2, 8),
      weekEnd: DateTime(2026, 2, 14, 23, 59, 59),
      muscleActivation: 8.5,
      pumpQuality: 8.0,
      fatigueLevel: 5.0,
      recoveryQuality: 7.0,
      hadPain: false,
      deloadRequested: false,
      userComments: 'Great week!',
      submittedAt: DateTime.now(),
    ),
  };
  
  // Process
  final result = await service.processWeeklyProgressionEnhanced(
    userId: userId,
    weekNumber: weekNumber,
    weekStart: DateTime(2026, 2, 8),
    weekEnd: DateTime(2026, 2, 14, 23, 59, 59),
    exerciseLogs: exerciseLogs, // Your data
    feedbackByMuscle: feedback,
  );
  
  // Show results
  print('✅ Week $weekNumber processed');
  print('Decisions: ${result.decisions.length} muscles updated');
  print('Audit: ${result.auditTrail.length} events logged');
  print('Valid: ${result.allValid}');
  
  if (!result.allValid) {
    print('⚠️ Requires attention:');
    for (final item in result.requiresCoachAttention) {
      print('   - $item');
    }
  }
}
```

---

**Ready to use! 🚀 Copy the imports, setup, and start processing weeks!**
