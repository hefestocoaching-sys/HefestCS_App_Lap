# 🎯 Motor V3 Enhanced - FASE 2 Quick Checklist

**Imprime esto. Pegalo en tu monitor. Refiere constantemente.**

---

## 🚀 Fase 2: 6 Tareas Secuenciales

```
┌─────────────────────────────────────────────────────────────┐
│ TAREA 1: REPOSITORIES (3-4h)                               │
│ ├─ Adaptar: MuscleProgressionRepository                    │
│ ├─ Crear: TrainingAuditLogRepository                       │
│ ├─ Crear: ExerciseAngleCoverageRepository                  │
│ └─ Integrar: WeeklyProgressionServiceEnhancedImpl           │
│ ✅ META: Datos persisten en Firestore                      │
├─────────────────────────────────────────────────────────────┤
│ TAREA 2: RIVERPOD PROVIDERS (2-3h)                         │
│ ├─ Crear: weeklyProgressionServiceEnhancedProvider         │
│ ├─ Actualizar: TrainingPlanNotifier                        │
│ ├─ Integrar: Dependency injection                          │
│ └─ Tests: Providers compilan y funcionan                   │
│ ✅ META: Servicio inyectado en árbol de providers          │
├─────────────────────────────────────────────────────────────┤
│ TAREA 3: MIGRACIÓN DE DATOS (2-4h)                         │
│ ├─ Implementar: _migrateTrackerDataIfNeeded()              │
│ ├─ Generar: ProgressRecords retroactivos                   │
│ ├─ Probar: En staging con datos reales                     │
│ └─ Verificar: Sin pérdida de información                   │
│ ✅ META: Datos legacy accesibles transparentemente         │
├─────────────────────────────────────────────────────────────┤
│ TAREA 4: UI COMPONENTS (6-8h)                              │
│ ├─ Widget 1: ProgressHistoryWidget                         │
│ ├─ Widget 2: WeeklyFeedbackFormWidget                      │
│ ├─ Widget 3: AuditTrailViewerWidget                        │
│ ├─ Widget 4: ProgressChartWidget                           │
│ ├─ Widget 5: DeloadIndicatorWidget                         │
│ └─ Integración: En training_screen                         │
│ ✅ META: UI funcional y responsiva                         │
├─────────────────────────────────────────────────────────────┤
│ TAREA 5: TESTS (4-6h)                                      │
│ ├─ 8 tests validadores (1 por rule)                        │
│ ├─ 6 tests modelos (properties derivadas)                  │
│ ├─ 10 tests servicios (decisiones P/S/T)                   │
│ ├─ 5 tests repositories (CRUD)                             │
│ └─ Integration test: full pipeline                         │
│ ✅ META: ≥80% coverage, todos pasan                        │
├─────────────────────────────────────────────────────────────┤
│ TAREA 6: STAGING & QA (2-4h)                               │
│ ├─ Deploy a staging environment                            │
│ ├─ Ejecutar checklist de 10 items                          │
│ ├─ Performance test (<3s por semana)                       │
│ ├─ Memory test (no leaks)                                  │
│ └─ Coordinador QA sign-off                                 │
│ ✅ META: Ready for production                              │
└─────────────────────────────────────────────────────────────┘

TOTAL: 19-29 horas
DIFICULTAD: Media-Alta
URGENCIA: 🔥 ALTA
```

---

## 📊 Archivos Clave de Referencia

| Archivo | Size | Propósito |
|---------|------|----------|
| `motor_v3_models/*` | ~1,000 LOC | Los 5 modelos listos |
| `training_validation_engine.dart` | 600 LOC | 8 reglas QA |
| `weekly_progression_service_enhanced_impl.dart` | 550 LOC | Lógica P/S/T |
| `MOTOR_V3_QUICK_REFERENCE.md` | 250 LOC | Copy-paste examples |
| `MOTOR_V3_REFACTOR_GUIDE.md` | 500 LOC | Sistema científico |
| `MOTOR_V3_PHASE1_SUMMARY.md` | 400 LOC | Qué cambió |

---

## 🔧 TAREA 1: Repositories

### Copy-Paste Template: saveProgressRecord()

```dart
/// lib/data/repositories/muscle_progression_repository.dart

Future<void> saveProgressRecord(String userId, ProgressRecord record) async {
  try {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('muscle_progression')
        .doc(record.muscle)
        .collection('progress_records')
        .doc('week_${record.weekNumber}');
    
    await docRef.set(record.toJson());
  } catch (e, st) {
    print('ERROR saving ProgressRecord: $e\n$st');
    rethrow;
  }
}
```

### Copy-Paste Template: getProgressRecords()

```dart
Future<List<ProgressRecord>> getProgressRecords(
  String userId,
  String muscle, {
  int limit = 12,
  DateTime? fromDate,
}) async {
  try {
    var query = _firestore
        .collection('users')
        .doc(userId)
        .collection('muscle_progression')
        .doc(muscle)
        .collection('progress_records')
        .orderBy('timestamp', descending: true)
        .limit(limit);
    
    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => ProgressRecord.fromJson(doc.data()))
        .toList();
  } catch (e) {
    return [];
  }
}
```

### Métodos Necesarios (Checklist)

- [ ] `saveProgressRecord(userId, record)` → void
- [ ] `getProgressRecords(userId, muscle, limit)` → List<ProgressRecord>
- [ ] `getLatestProgressRecordByMuscle(userId, muscle)` → ProgressRecord?
- [ ] `saveAuditEntry(userId, entry)` → void (audit repo)
- [ ] `getAuditTrail(userId, weekNumber, filter)` → List<AuditEntry> (audit repo)
- [ ] `saveCoverage(userId, coverage)` → void (angle repo)
- [ ] `getCoverage(userId, muscle)` → ExerciseAngleCoverage? (angle repo)

---

## 🛠️ TAREA 2: Riverpod Providers

### Copy-Paste Template

```dart
/// lib/presentation/providers/motor_v3_providers.dart

final trainingAuditLogRepositoryProvider = Provider<TrainingAuditLogRepository>((ref) {
  return TrainingAuditLogRepository(FirebaseFirestore.instance);
});

final exerciseAngleCoverageRepositoryProvider = Provider<ExerciseAngleCoverageRepository>((ref) {
  return ExerciseAngleCoverageRepository(FirebaseFirestore.instance);
});

final weeklyProgressionServiceEnhancedProvider = Provider<WeeklyProgressionServiceEnhanced>((ref) {
  final progressionRepo = ref.watch(muscleProgressionRepositoryProvider);
  final weeklyAnalysisRepo = ref.watch(weeklyMuscleAnalysisRepositoryProvider);
  final auditLogRepo = ref.watch(trainingAuditLogRepositoryProvider);
  final angleRepo = ref.watch(exerciseAngleCoverageRepositoryProvider);
  
  return WeeklyProgressionServiceEnhancedImpl(
    muscleProgressionRepository: progressionRepo,
    weeklyMuscleAnalysisRepository: weeklyAnalysisRepo,
    trainingAuditLogRepository: auditLogRepo,
    exerciseAngleCoverageRepository: angleRepo,
  );
});
```

### Actualizar TrainingPlanNotifier

```dart
// Antes:
final service = WeeklyProgressionServiceImpl(...);

// Después:
final service = ref.read(weeklyProgressionServiceEnhancedProvider);

// Y usar:
final result = await service.processWeeklyProgressionEnhanced(...);
```

---

## 🛠️ TAREA 3: Migración

### Copy-Paste: _migrateTrackerDataIfNeeded()

```dart
/// lib/domain/training_v3/services/weekly_progression_service_enhanced_impl.dart

Future<void> _migrateTrackerDataIfNeeded(String userId, String muscle) async {
  // Check if already migrated
  final existing = await progressionRepository.getProgressRecords(
    userId,
    muscle,
    limit: 1,
  );
  if (existing.isNotEmpty) return;
  
  // Load legacy tracker
  final tracker = await progressionRepository.getMuscleProgressionTracker(userId, muscle);
  if (tracker == null) return;
  
  // Generate retroactive ProgressRecords
  if (tracker.history != null && tracker.history!.isNotEmpty) {
    for (var i = 0; i < tracker.history!.length; i++) {
      final histEntry = tracker.history![i];
      
      final record = ProgressRecord(
        userId: userId,
        muscle: muscle,
        weekNumber: histEntry.week,
        volumePrescribed: (histEntry.prescribedSets ?? 0).toDouble(),
        volumePerformed: (histEntry.performedSets ?? 0).toDouble(),
        volumeAdherence: histEntry.adherence ?? 0.0,
        rirAverage: histEntry.rir ?? 0.0,
        performanceScore: 0.7, // Default for legacy
        timestamp: DateTime.now().subtract(Duration(days: 7 * (tracker.history!.length - i))),
        comment: 'MIGRATED_FROM_V1_MOTOR',
        wasProgressiveWeek: histEntry.prescribedSets != null 
            ? (i > 0 && tracker.history![i-1].prescribedSets! < histEntry.prescribedSets!)
            : false,
      );
      
      await progressionRepository.saveProgressRecord(userId, record);
    }
  }
}

// En processWeeklyProgressionEnhanced(), al inicio:
await _migrateTrackerDataIfNeeded(userId, muscle);
```

---

## 🛠️ TAREA 4: UI - Widget Templates

### ProgressHistoryWidget Template

```dart
/// lib/presentation/widgets/training_v3/progress_history_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/domain/training_v3/models/progress_record.dart';

class ProgressHistoryWidget extends ConsumerStatefulWidget {
  final String userId;
  final String muscle;
  
  const ProgressHistoryWidget({
    required this.userId,
    required this.muscle,
  });

  @override
  ConsumerState<ProgressHistoryWidget> createState() => _ProgressHistoryWidgetState();
}

class _ProgressHistoryWidgetState extends ConsumerState<ProgressHistoryWidget> {
  @override
  void initState() {
    super.initState();
    // TODO: Cargar datos de repository
  }

  @override
  Widget build(BuildContext context) {
    // TODO: UI aquí
    return Column(
      children: [
        Text('Historial de ${widget.muscle}'),
        // ListView con ProgressRecords
      ],
    );
  }
}
```

### WeeklyFeedbackForm Template

```dart
class WeeklyFeedbackFormWidget extends ConsumerStatefulWidget {
  final String userId;
  final String muscle;
  final Function(FeedbackEntry) onSubmit;
  
  const WeeklyFeedbackFormWidget({
    required this.userId,
    required this.muscle,
    required this.onSubmit,
  });

  @override
  ConsumerState<WeeklyFeedbackFormWidget> createState() => _WeeklyFeedbackFormWidgetState();
}

class _WeeklyFeedbackFormWidgetState extends ConsumerState<WeeklyFeedbackFormWidget> {
  double muscleActivation = 5;
  double pumpQuality = 5;
  double fatigueLevel = 5;
  double recoveryQuality = 5;
  bool hadPain = false;
  bool deloadRequested = false;
  String userComments = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // TODO: Sliders para cada campo
        Slider(value: muscleActivation, onChanged: (v) => setState(() => muscleActivation = v)),
        // ...
        ElevatedButton(
          onPressed: () {
            final feedback = FeedbackEntry(
              muscleActivation: muscleActivation.toInt(),
              pumpQuality: pumpQuality.toInt(),
              fatigueLevel: fatigueLevel.toInt(),
              recoveryQuality: recoveryQuality.toInt(),
              hadPain: hadPain,
              deloadRequested: deloadRequested,
              userComments: userComments,
              timestamp: DateTime.now(),
            );
            widget.onSubmit(feedback);
          },
          child: Text('Enviar Feedback'),
        ),
      ],
    );
  }
}
```

---

## 🧪 TAREA 5: Tests - Ejemplos

### Model Test: PRIMARY Progression

```dart
/// test/domain/training_v3/services_test.dart

test('PRIMARY: +2 sets if performance >= 0.7', () {
  // Arrange
  final muscle = MuscleProgression(
    name: 'Pecho',
    priority: 5, // PRIMARY
    currentSets: 18,
    currentPhase: TrainingPhase.discovering,
    volumeLandmarks: VolumeLandmarks(mev: 10, vop: 14, mrv: 22),
  );
  
  // Act
  final recommended = muscle.recommendedIncrement;
  
  // Assert
  expect(recommended, equals(2));
});

test('SECONDARY: +1 set if performance >= 0.65', () {
  final muscle = MuscleProgression(
    name: 'Traps',
    priority: 3, // SECONDARY
    currentSets: 9,
  );
  
  expect(muscle.recommendedIncrement, equals(1));
});

test('TERTIARY: 0 sets (always VOP)', () {
  final muscle = MuscleProgression(
    name: 'Calves',
    priority: 1, // TERTIARY
    currentSets: 6,
  );
  
  expect(muscle.recommendedIncrement, equals(0));
});
```

### Validator Test: Rule #1 (PRIMARY never > MRV)

```dart
test('ValidationRule #1: PRIMARY never exceeds MRV', () async {
  final validator = TrainingValidationEngine();
  
  final muscle = MuscleProgression(
    name: 'Pecho',
    priority: 5,
    currentSets: 25, // > MRV (22)
    volumeLandmarks: VolumeLandmarks(mev: 10, vop: 14, mrv: 22),
  );
  
  final result = validator.validateMuscleProgression(muscle);
  
  expect(result.isValid, isFalse);
  expect(result.errors, contains(contains('PRIMARY')));
});
```

---

## ✅ TAREA 6: Pre-Prod Checklist

Antes de producción, verifica TODO esto:

```
CODE QUALITY
  [ ] flutter analyze = 0 issues
  [ ] flutter test = 100% pass
  [ ] Coverage ≥ 80% (flutter test --coverage)
  [ ] No unused imports
  [ ] Código formateado (dart format)

FUNCTIONALITY
  [ ] ProgressHistoryWidget carga datos
  [ ] WeeklyFeedbackForm valida entrada
  [ ] AuditTrailViewer filtra correctamente
  [ ] Export a JSON funciona
  [ ] Export a CSV funciona
  [ ] Deload triggers en widget mostrado

PERFORMANCE
  [ ] Process semana < 3 segundos (abierto)
  [ ] No lag al scrollear historial
  [ ] Memory estable (Flutter DevTools)
  [ ] No leaks con 100 operaciones

DATA
  [ ] Firestore schema correcto
  [ ] Legacy data se migra automáticamente
  [ ] ProgressRecords se guardan
  [ ] AuditLog entries completas
  [ ] Datos exportables

UI/UX
  [ ] Responsive 1920x1080
  [ ] Responsive 1366x768
  [ ] Responsive tablet
  [ ] Textos legibles
  [ ] Colores consistentes
  [ ] Iconos claros

SECURITY
  [ ] No hardcoded credentials
  [ ] Firestore rules actualizadas
  [ ] User data aislado por userId
  [ ] No logged sensitive data

DOCUMENTATION
  [ ] Código tiene comentarios
  [ ] README actualizado
  [ ] API documentation completa
  [ ] Wiki con ejemplos

STAGING FINAL
  [ ] Deploy a staging OK
  [ ] 2 horas sin errores
  [ ] Manual QA pasó
  [ ] Coordinador aprrobó
  [ ] Ready for production ✅
```

---

## 🆘 Errores Comunes & Soluciones

| Error | Causa | Solución |
|-------|-------|----------|
| "Repository method not found" | No implementaste el método | Agrega a la clase repository |
| "Provider not found" | No registraste en providers | Exporta en `providers.dart` |
| "Firestore collection empty" | No salvaste datos | Verifica path en saveRecord() |
| "Migration not running" | Llamaste en sitio equivocado | Debe estar en procesamiento semanal |
| "UI no carga datos" | Repository query retorna vacío | Debuggea con print() en query |
| "Tests fallan post-refactor" | Mock data desincronizado | Update mocks en test helpers |
| "Performance lenta" | Query sin índice | Crea índice en Firestore Console |
| "Memory leak" | Subscription no cancelada | Cancela en `onDispose` |

---

## 📞 Resources

- **Documentos Técnicos**: `docs/MOTOR_V3_*.md` (4 archivos)
- **Código Referencia**: `lib/domain/training_v3/*`
- **Quick Copy-Paste**: Este archivo
- **Video Tutorials**: (si existen en proyecto)

---

## 🎯 Definición Final de DONE

Motor V3 Enhanced FASE 2 está DONE cuando:

```
✅ 3 repositories con CRUD completo → datos persisten
✅ Riverpod providers registrados → servicios inyectados
✅ Legacy data migrada → sin pérdida
✅ 5+ UI widgets built → usuario puede interactuar
✅ 30+ tests → 80%+ coverage
✅ Staging QA pasó → ready for production
✅ Este checklist 100% tachado
```

---

**¡Éxito! 🚀 Comienza por TAREA 1: Repositories**

Tiempo promedio: 25-35 horas  
Dificultad: Media-Alta  
Urgencia: 🔥 MUY ALTA

**Next command:** Abre `MOTOR_V3_QUICK_REFERENCE.md`)
