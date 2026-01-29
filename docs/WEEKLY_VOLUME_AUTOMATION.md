## PASO 3 — Dónde crear registros semanales automáticos

### Ubicación objetivo

**Archivo a modificar:**  
`lib/features/training_feature/screens/training_dashboard_screen.dart`

**Método relevante:**  
Busca donde se guarda un `TrainingSessionLog` (bitácora de sesión individual).

### Lógica requerida

Cuando se complete una semana de entrenamiento (7 días o ciclo completo):

1. **Detectar cierre de semana:**
   - Por fecha (domingo → lunes)
   - O al completar todas las sesiones del microciclo

2. **Calcular series totales por músculo:**
   ```dart
   // Pseudocódigo
   final weekLogs = _getLogsForWeek(weekStartIso);
   final seriesByMuscle = <String, int>{};
   
   for (final log in weekLogs) {
     for (final exercise in log.exercises) {
       final muscle = exercise.primaryMuscle;
       seriesByMuscle[muscle] = (seriesByMuscle[muscle] ?? 0) + exercise.sets;
     }
   }
   ```

3. **Clasificar series según % de Tab 2:**
   ```dart
   final split = client.training.extra[TrainingExtraKeys.seriesTypePercentSplit] ?? {
     'heavy': 20,
     'medium': 60,
     'light': 20,
   };
   
   for (final muscle in seriesByMuscle.keys) {
     final total = seriesByMuscle[muscle]!;
     final heavy = (total * split['heavy']! / 100).round();
     final medium = (total * split['medium']! / 100).round();
     final light = total - heavy - medium; // ajuste para suma exacta
     
     final record = WeeklyVolumeRecord(
       weekStartIso: weekStartIso,
       muscleGroup: muscle,
       totalSeries: total,
       heavySeries: heavy,
       mediumSeries: medium,
       lightSeries: light,
     );
     
     // Agregar a historial
   }
   ```

4. **Persistir en `weeklyVolumeHistory`:**
   ```dart
   await ref.read(clientsProvider.notifier).updateActiveClient((c) {
     final t = c.training;
     final e = Map<String, dynamic>.from(t.extra);
     
     final history = List<Map<String, dynamic>>.from(
       (e[TrainingExtraKeys.weeklyVolumeHistory] as List?) ?? [],
     );
     
     history.addAll(weekRecords.map((r) => r.toMap()));
     
     // Mantener solo últimas 52 semanas
     if (history.length > 52) {
       history.removeRange(0, history.length - 52);
     }
     
     e[TrainingExtraKeys.weeklyVolumeHistory] = history;
     
     return c.copyWith(
       training: t.copyWith(extra: e),
       updatedAt: DateTime.now(),
     );
   });
   ```

### Tab 3 se actualiza automáticamente

Una vez guardado en `weeklyVolumeHistory`, la Tab 3 (`WeeklyHistoryTab`) se refresca sola porque:
- Lee directamente de `trainingExtra[TrainingExtraKeys.weeklyVolumeHistory]`
- Es un `ConsumerWidget` que reacciona a cambios en `clientsProvider`
- No tiene botones ni acciones manuales

---

**Punto de integración sugerido:**

Busca en `training_dashboard_screen.dart` el método que persiste logs de sesión individual y agrega la lógica de agregación semanal después de guardar cada log. Alternativamente, crea un servicio separado `WeeklyVolumeAggregatorService` que escuche cambios en `trainingSessionLogRecords` y calcule automáticamente los registros semanales.
