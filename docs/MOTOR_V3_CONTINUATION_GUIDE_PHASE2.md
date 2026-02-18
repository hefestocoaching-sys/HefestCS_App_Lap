# 🔧 MOTOR V3 ENHANCED - Guía de Continuación FASE 2

**Documento de Transición Operacional**  
**Estado:** Fase 1 ✅ Completada → Fase 2 🚀 Iniciando  
**Actualizado:** Febrero 2026  

---

## 📋 Situación Actual

### ✅ Fase 1 Completada (50% del trabajo)

Los siguientes componentes están **100% listos para usar**:

```
✅ 5 Modelos Freezed con business logic
✅ 1 Motor de validación con 8 reglas formales
✅ 2 Servicios (interface + implementación mejorada)
✅ 3 Documentos técnicos completos
✅ 0 Errores de compilación
✅ 0 Warnings
```

### ❌ Fase 2 No Iniciada (Falta 50%)

Estos componentes están **listos en arquitectura pero sin integración de persistencia**:

```
❌ Repositories (métodos de persistencia no adaptados)
❌ Riverpod Providers (service no inyectado)
❌ UI Components (widgets sin crear)
❌ Tests Automatizados (sin cobertura)
❌ Migración de datos (si es necesaria)
```

---

## 🎯 Objetivos de Fase 2

### Meta Principal
Integrar Motor V3 Enhanced en el flujo de producción de forma que:
- ✅ Usuarios no vean cambios de comportamiento
- ✅ Datos legacy se migran automáticamente
- ✅ Coach tiene acceso a nueva funcionalidad (historial, export)
- ✅ Sistema puede ser reparado en ~30 min si falla

### Timeline Estimado
- **Repositories**: 3-4 horas
- **Providers**: 2-3 horas
- **Migración**: 2-4 horas
- **UI básica**: 6-8 horas
- **Tests**: 4-6 horas
- **QA/Staging**: 2-4 horas
- **TOTAL**: 19-29 horas de desarrollo

---

## 📍 Punto de Partida

> **TU SITUACIÓN COMO DEVELOPER**

1. ✅ Código escrito está en:
   - `lib/domain/training_v3/models/*` (5 archivos)
   - `lib/domain/training_v3/validators/training_validation_engine.dart`
   - `lib/domain/training_v3/services/weekly_progression_service_enhanced*` (2 archivos)

2. ✅ Documentación está en:
   - `docs/MOTOR_V3_DOCUMENTATION_INDEX.md` ← EMPIEZA AQUÍ
   - `docs/MOTOR_V3_PHASE1_SUMMARY.md`
   - `docs/MOTOR_V3_QUICK_REFERENCE.md`
   - `docs/MOTOR_V3_REFACTOR_GUIDE.md`

3. ❓ Lo que NO sabes:
   - Cómo se persisten los datos (Firestore)
   - Dónde se inyecta el servicio (Riverpod)
   - Cómo se ve la UI (no existe)
   - Cómo migrar datos legacy (no plaificado)

---

## 🛠️ TAREA 1: Adaptar Repositories (3-4 horas)

### Problema
Los modelos nuevos (`ProgressRecord`, `TrainingAuditLog`, `ExerciseAngleCoverage`) existen en memoria pero no tienen métodos de persistencia en Firestore.

### Solución de Alto Nivel

Necesitas adaptar `MuscleProgressionRepository` y crear 2 nuevos:

```
lib/data/repositories/
  ├─ muscle_progression_repository.dart  ← ADAPTAR
  │  Agregar: saveProgressRecord, getProgressRecords, getLatestProgressRecordByMuscle
  │
  ├─ training_audit_log_repository.dart  ← CREAR NUEVO
  │  Métodos: saveAuditEntry, getAuditTrail, getAuditTrailByMuscle
  │
  └─ exercise_angle_coverage_repository.dart  ← CREAR NUEVO
     Métodos: saveCoverage, getCoverage, updateCoverageForMuscle
```

### Paso 1.1: Leer Código Actual

Lee estos archivos para entender la estructura:

```bash
lib/data/repositories/muscle_progression_repository.dart
lib/data/repositories/weekly_muscle_analysis_repository.dart
```

**Busca:**
- ¿Cómo se hace un Query a Firestore?
- ¿Cómo se mapean documentos a modelos?
- ¿Cómo se hace un batch write?
- ¿Dónde se define el path de colección?

### Paso 1.2: Adaptar MuscleProgressionRepository

Agrega estos métodos:

```dart
/// Guarda un ProgressRecord en Firestore
/// Path: users/{userId}/muscle_progression/{muscle}/progress_records/{weekNumber}
Future<void> saveProgressRecord(String userId, ProgressRecord record) async {
  // TODO: Implementar
  // 1. Convertir record.toJson() 
  // 2. Ubicación: progress_records/{weekNumber}
  // 3. Batch write con tracker actualizado
}

/// Obtiene últimos 12 ProgressRecords de un músculo
Future<List<ProgressRecord>> getProgressRecords(
  String userId,
  String muscle, {
  int limit = 12,
  DateTime? fromDate,
}) async {
  // TODO: Implementar
  // 1. Query a progress_records colección
  // 2. Ordenar por weekNumber DESC
  // 3. Lmit
  // 4. Mapear a ProgressRecord.fromJson()
}

/// Helper: obtener el ProgressRecord más reciente
Future<ProgressRecord?> getLatestProgressRecordByMuscle(
  String userId,
  String muscle,
) async {
  // TODO: Implementar
  // Query único documento ordenado DESC, limit 1
}
```

### Paso 1.3: Crear TrainingAuditLogRepository

Nuevo archivo: `lib/data/repositories/training_audit_log_repository.dart`

```dart
class TrainingAuditLogRepository {
  final FirebaseFirestore _firestore;
  
  /// Guarda un entry en la auditoría
  /// Path: users/{userId}/audit_log/{eventId}
  Future<void> saveAuditEntry(String userId, TrainingAuditLogEntry entry) async {
    // TODO: Implementar
    // 1. Generar eventId único (timestamp + random)
    // 2. Guardar en audit_log colección
  }
  
  /// Obtiene auditoría de una semana
  Future<List<TrainingAuditLogEntry>> getAuditTrail(
    String userId,
    int weekNumber, {
    TrainingAuditLogFilter? filter,
  }) async {
    // TODO: Implementar
    // Query con filter (muscleAffected, eventType, severity)
  }
  
  /// Obtiene todos los eventos de un músculo
  Future<List<TrainingAuditLogEntry>> getAuditTrailByMuscle(
    String userId,
    String muscle,
  ) async {
    // TODO: Implementar
  }
}
```

### Paso 1.4: Crear ExerciseAngleCoverageRepository

Nuevo archivo: `lib/data/repositories/exercise_angle_coverage_repository.dart`

```dart
class ExerciseAngleCoverageRepository {
  final FirebaseFirestore _firestore;
  
  /// Guarda cobertura angular
  /// Path: users/{userId}/exercise_angles/{muscle}
  Future<void> saveCoverage(String userId, ExerciseAngleCoverage coverage) async {
    // TODO: Implementar
  }
  
  /// Obtiene cobertura de un músculo
  Future<ExerciseAngleCoverage?> getCoverage(String userId, String muscle) async {
    // TODO: Implementar
  }
}
```

### Paso 1.5: Actualizar WeeklyProgressionServiceEnhancedImpl

Ahora que los repositories existen, debe usarlos:

En `weekly_progression_service_enhanced_impl.dart`:

```dart
// Agregar en constructor
final TrainingAuditLogRepository auditLogRepository;
final ExerciseAngleCoverageRepository angleRepository;

// En processWeeklyProgressionEnhanced(), después de crear cada ProgressRecord:
await progressionRepository.saveProgressRecord(userId, progressRecord);
await auditLogRepository.saveAuditEntry(userId, auditEntry);
await angleRepository.saveCoverage(userId, angleCoverage);
```

### ✅ Meta 1.5: Verificación

Después de Tarea 1:
- ✅ 3 repositories con métodos CRUD completos
- ✅ Datos persisten en Firestore correctamente
- ✅ WeeklyProgressionServiceEnhancedImpl usa los repos
- ✅ Sin errores de compilación

---

## 🛠️ TAREA 2: Integrar Riverpod Providers (2-3 horas)

### Problema
El servicio existe pero no está inyectado en el árbol de providers. El codigo actual usa `weekly_progression_service_impl.dart` (legacy). Necesitas reemplazarlo con el mejorado.

### Solución

Actualizar `lib/presentation/providers/training_plan_provider.dart`:

```dart
// Exportar el nuevo servicio
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

// Actualizar la notificación que genera el plan
class TrainingPlanNotifier extends StateNotifier<...> {
  @override
  Future<void> generatePlanV3(...) async {
    // Antes: final service = WeeklyProgressionServiceImpl(...)
    // Después: final service = ref.read(weeklyProgressionServiceEnhancedProvider);
    
    final result = await service.processWeeklyProgressionEnhanced(
      userId,
      weekNumber,
      exerciseLogs,
      feedbackByMuscle,
    );
    
    // Guardar result.progressRecords y result.auditTrail
    // Mostrar warnings si result.requiresCoachAttention
  }
}
```

### ✅ Meta 2: Verificación

- ✅ weeklyProgressionServiceEnhancedProvider existe
- ✅ generatePlanV3 usa el servicio mejorado
- ✅ Sin errores de compilación
- ✅ Tests todavía pasan (o actualizados)

---

## 🛠️ TAREA 3: Migración de Datos (2-4 horas)

### Problema
Datos legacy están en estructura antigua. Si cambias Firestore schema sin migración, datos se pierden.

### Tres Opciones Posibles

**Opción A: Migración on-demand (RECOMENDADo)**
- Cuando usuario entra a app por primera vez
- Se carga tracker legacy
- Se busca si existen ProgressRecords nuevos
- Si no existen, se generan retroactivamente
- ✅ Cero downtime, gradual, reversible

**Opción B: Migración batch (CLI)**
- Script que corre una vez
- Lee todos trackers del proyecto
- Genera ProgressRecords retroactivos
- Índice actualizado
- ✅ Rápido, offline-safe, pero requiere mantenimiento manual

**Opción C: No migrar / Nuevo usuario**
- Los nuevos usuarios usan estrutura mejorada
- Usuarios legacy quedan sin historial
- ❌ No recomendado, pérdida de datos

**RECOMENDACIÓN: Opción A**

### Implementar Opción A

En `weekly_progression_service_enhanced_impl.dart`:

```dart
/// Genera ProgressRecords retroactivos si no existen
/// Se llama una sola vez por usuario+músculo
Future<void> _migrateTrackerDataIfNeeded(String userId, String muscle) async {
  // 1. Chequear si existen ProgressRecords ya
  final existing = await progressionRepository.getProgressRecords(userId, muscle, limit: 1);
  if (existing.isNotEmpty) return; // Ya migrado
  
  // 2. Cargar tracker legacy (si existe)
  final tracker = await progressionRepository.getMuscleProgressionTracker(userId, muscle);
  if (tracker == null) return;
  
  // 3. Para cada entrada en tracker.history, generar ProgressRecord
  // (usa dates, volumes, etc del histórico del tracker)
  for (var historicEntry in tracker.history) {
    final record = ProgressRecord(
      userId: userId,
      muscle: muscle,
      weekNumber: historicEntry.weekNumber,
      volumePrescribed: historicEntry.prescribed,
      volumePerformed: historicEntry.performed,
      volumeAdherence: historicEntry.adherence,
      // ... mapear otros campos
      timestamp: historicEntry.timestamp,
      comment: 'MIGRATED_FROM_V1',
    );
    await progressionRepository.saveProgressRecord(userId, record);
  }
}

// Llamar en processWeeklyProgressionEnhanced():
await _migrateTrackerDataIfNeeded(userId, muscle);
```

### ✅ Meta 3: Verificación

- ✅ Datos legacy accesibles en nueva interfaz
- ✅ ProgressRecords se generan automáticamente
- ✅ Sin pérdida de datos históricos
- ✅ Transición transparente para usuario

---

## 🛠️ TAREA 4: UI Components (6-8 horas)

### Problema
Logic está completa pero usuario no puede ver nada. Necesitas widgets para visualizar y interactuar.

### Components to Build

```
lib/presentation/widgets/training_v3/
├─ progress_history_widget.dart          ← NUEVA
│  Muestra últimas 12 semanas de ProgressRecords
│  Gráficos: volumen, adherencia, fases
│  
├─ weekly_feedback_form_widget.dart      ← NUEVA
│  Form para FeedbackEntry (1-10 sliders)
│  Botón "Enviar Feedback" 
│  
├─ audit_trail_viewer_widget.dart        ← NUEVA
│  Lista de TrainingAuditLogEntry
│  Filter por evento, músculo, fecha
│  
├─ progressio_chart_widget.dart          ← NUEVA
│  Gráfico progreso volumen semanas
│  Línea de deload triggers
│  
└─ deload_indicator_widget.dart          ← NUEVA
   Card mostrando si hay deload recomendado
   Razón: fatiga/recuperación/manual
```

### Sketch 1: ProgressHistoryWidget

```
┌─────────────────────────────────────────┐
│ 📊 Historial de Progresión              │
├─────────────────────────────────────────┤
│ Semana 12: vol=60 [████████░░]          │
│ Semana 11: vol=58 [████████░░] ↑ +2    │
│ Semana 10: vol=58 [████████░░]          │
│ Semana 09: vol=57 [███████░░░] deload  │
│ Semana 08: vol=57 [███████░░░]          │
│ ...                                     │
│ [📥 Exportar] [🔄 Actualizar]          │
└─────────────────────────────────────────┘
```

### Sketch 2: WeeklyFeedbackForm

```
┌──────────────────────────────────────┐
│ 📝 Feedback esta Semana              │
├──────────────────────────────────────┤
│ Activación Muscular: [●───────────]  │
│ Calidad de Pump: [───●──────────]    │
│ Nivel de Fatiga: [──────●────────]   │
│ Recuperación: [───────────●──────]   │
│                                      │
│ ☑ Estrés/Dolor                       │
│ ☑ Solicitar Deload                   │
│                                      │
│ Comentarios: [_______________________] │
│                                      │
│ [Enviar Feedback]                    │
└──────────────────────────────────────┘
```

### Sketch 3: AuditTrailViewer

```
┌────────────────────────────────────────┐
│ 🔍 Auditoría (Últimas 50 eventos)     │
├────────────────────────────────────────┤
│ [Filtros] Músculo: [Pecho▼] [🔄]      │
├────────────────────────────────────────┤
│ 13 Feb 14:22  volumen_adjusted        │
│              Pecho: 60→62 sets        │
│ 06 Feb 08:10  weekly_progression      │
│              Pecho: maintaining       │
│ 30 Ene 19:44  deload_triggered        │
│              Espalda: fatiga ≥8       │
│ ...                                    │
└────────────────────────────────────────┘
```

### ✅ Meta 4: Verificación

- ✅ ProgressHistoryWidget despliega datos correctamente
- ✅ WeeklyFeedbackForm valida y envía datos
- ✅ AuditTrailViewer muestra eventos
- ✅ UI responsive y usable

---

## 🛠️ TAREA 5: Tests Automatizados (4-6 horas)

### Problema
Sin tests, cambios futuros pueden romper lógica crítica silenciosamente.

### Test Structure

```
test/
├─ domain/
│  └─ training_v3/
│     ├─ models_test.dart               ← CREAR
│     │  Tests de MuscleProgression health scoring
│     │  Tests de ProgressRecord extensiones
│     │  Tests de FeedbackEntry validaciones
│     │
│     ├─ validation_engine_test.dart    ← CREAR
│     │  8 test cases: 1 por regla
│     │  Casos positivos + negativos
│     │
│     └─ services_test.dart             ← CREAR
│        Tests de procesamiento semanal
│        Casos PRIMARY, SECONDARY, TERTIARY
│        Deload triggers
│
└─ integration/
   └─ motor_v3_pipeline_test.dart       ← CREAR
      Test completo: logs → decisiones → persistencia
```

### Test Example: PRIMARY logic

```dart
test('PRIMARY muscle: +2 sets if performance≥0.7 and adherence≥0.80', () async {
  // Arrange
  final muscle = MuscleProgression(
    name: 'Pecho',
    priority: 5,  // PRIMARY
    currentSets: 18,
    currentPhase: TrainingPhase.discovering,
  );
  
  final feedback = FeedbackEntry(
    muscleActivation: 8,
    pumpQuality: 7,
    fatigueLevel: 5,
  );
  
  // Act
  final decision = service._decidePrimaryProgression(muscle, feedback, adherence: 0.85);
  
  // Assert
  expect(decision.newSets, equals(20)); // 18 + 2
  expect(decision.reason, contains('performance_high'));
});
```

### ✅ Meta 5: Verificación

- ✅ 30+ tests escritos
- ✅ Coverage ≥ 80% del código nuevo
- ✅ Todos pasan
- ✅ CI/CD pipeline actualizado

---

## 🛠️ TAREA 6: QA & Staging (2-4 horas)

### Checklist Pre-Prod

- [ ] Todos los tests pasan
- [ ] No hay warnings de compilación
- [ ] Datos legacy migrados correctamente en staging
- [ ] UI se ve bien en 3 resoluciones (1920x1080, 1366x768, desktop)
- [ ] Exportar a JSON funciona
- [ ] Exportar a CSV funciona
- [ ] Audit trail es visible para coach
- [ ] Deload triggers funcionan correctamente
- [ ] Performance: procesar semana < 3 segundos
- [ ] No hay memory leaks (Flutter DevTools)

### Staging Environment

```bash
# En Firebase Console:
# Crear Firestore collection "staging"
# Duplicate rules de producción pero a staging/*

# En código:
final env = const String.fromEnvironment('ENV', defaultValue: 'prod');
final firestore = FirebaseFirestore.instanceFor(
  app: Firebase.apps.first,
  databaseId: env == 'staging' ? 'staging' : '(default)',
);

# Build para staging:
flutter run -d windows --dart-define=ENV=staging
```

---

## 📊 Progreso Tracking

Usa este checklist para comunicar progreso:

```
REPOSITORY ADAPTATION
  [ ] Lee code actual (MuscleProgressionRepository)
  [ ] Agrega saveProgressRecord() 
  [ ] Agrega getProgressRecords()
  [ ] TrainingAuditLogRepository creada
  [ ] ExerciseAngleCoverageRepository creada
  [ ] WeeklyProgressionServiceEnhancedImpl integrada
  [ ] Tests repositories OK

RIVERPOD INTEGRATION
  [ ] weeklyProgressionServiceEnhancedProvider creada
  [ ] TrainingPlanNotifier actualizada
  [ ] Dependency injection correcta
  [ ] Tests providers OK

DATA MIGRATION
  [ ] _migrateTrackerDataIfNeeded() implementada
  [ ] Retroactive ProgressRecords creados
  [ ] Sin pérdida de datos
  [ ] Tested en staging

UI COMPONENTS
  [ ] ProgressHistoryWidget completa
  [ ] WeeklyFeedbackForm completa
  [ ] AuditTrailViewer completa
  [ ] Progress Charts completa
  [ ] Deload Indicator completa

TESTS
  [ ] Model tests escritos (30+ cases)
  [ ] Validation engine tests (8 rules + coverage)
  [ ] Service pipeline tests
  [ ] Integration tests
  [ ] Coverage ≥ 80%

STAGING QA
  [ ] All tests ✅
  [ ] No warnings
  [ ] UI responsive
  [ ] Export works
  [ ] Performance OK
  [ ] Ready for production
```

---

## 🚨 Troubleshooting Rapido

### "No puedo compilar"
- ✅ `flutter pub get` (refresca deps)
- ✅ `flutter clean` + `flutter pub get` (limpia cache)
- ✅ Busca `TrainingValidationEngine` - ¿existe?

### "Repository method doesn't exist"
- ✅ Asegúrate que agregaste el método a la clase
- ✅ Asegúrate que el mixin o interface está implementado
- ✅ Run `flutter pub get` nuevamente

### "Provider not found"
- ✅ ¿Exportaste el provider en `providers.dart`?
- ✅ ¿Lo estás referenciando con`ref.watch()` y no `ref.read()`?

### "Firestore collection doesn't exist"
- ✅ Firestore crea colecciones on-demand cuando escribes
- ✅ Verifica que el path es correcto: `users/{userId}/muscle_progression/{muscle}/progress_records/{weekNumber}`

### "Tests fallan después de cambios"
- ✅ Asegúrate que mock data está sincronizada con schema
- ✅ Ejecuta `flutter test --coverage` para ver qué falla
- ✅ Mira el stack trace completo

---

## 📚 Documentos de Referencia

Mientras implementas Fase 2, refiere a estos documentos:

| Necesitas...              | Ve a...                           |
|---------------------------|-----------------------------------|
| Entender ProgressRecord   | MOTOR_V3_QUICK_REFERENCE.md      |
| Entender lógica P/S/T     | MOTOR_V3_REFACTOR_GUIDE.md       |
| Ejemplo de uso completo   | MOTOR_V3_PHASE1_SUMMARY.md       |
| Estructura de servicios   | weekly_progression_service_enhanced_impl.dart |
| Estructuras validadores   | training_validation_engine.dart  |
| Como debugguear           | MOTOR_V3_QUICK_REFERENCE.md > "Common Issues" |

---

## ✅ Definición de "Done" para Fase 2

**Motor V3 Enhanced está LISTO PARA PRODUCCIÓN cuando:**

```
1. REPOSITORIES
   ✅ 3 repositories con CRUD completo
   ✅ Datos persisten en Firestore
   ✅ WeeklyProgressionServiceEnhancedImpl usa repos

2. DEPENDENCIES
   ✅ Riverpod providers definidos
   ✅ Injection correcta
   ✅ Sin import cycles

3. DATA
   ✅ Legacy data migrado automáticamente on-demand
   ✅ Sin pérdida de información
   ✅ Transición transparente para usuario

4. UI
   ✅ 5 widgets funcionales
   ✅ Responsive y usable
   ✅ Feedback visual clara

5. TESTS
   ✅ 40+ tests
   ✅ Coverage ≥ 80%
   ✅ Todos pasan

6. STAGING
   ✅ Deployment a staging exitoso
   ✅ No hay errores
   ✅ Performance acceptable
   ✅ QA sign-off
```

---

## 🎉 ¡Listo para Comenzar!

**Próximo paso:**

1. Lee [MOTOR_V3_DOCUMENTATION_INDEX.md](./MOTOR_V3_DOCUMENTATION_INDEX.md)
2. Lee [MOTOR_V3_QUICK_REFERENCE.md](./MOTOR_V3_QUICK_REFERENCE.md)
3. Comienza con **TAREA 1: Adaptar Repositories**

**Tiempo estimado:** 25-35 horas de desarrollo
**Dificultad:** Media-Alta (Firestore + State Management + UI)
**Prioridad:** 🔥 Alta (bloquea producción)

---

**¿Preguntas?** Refiere a los documentos técnicos o the service implementation code en:
- `weekly_progression_service_enhanced_impl.dart` (lógica core)
- `training_validation_engine.dart` (QA rules)
- `muscle_progression.dart` (model con business logic)

**¡Éxito en Fase 2! 🚀**
