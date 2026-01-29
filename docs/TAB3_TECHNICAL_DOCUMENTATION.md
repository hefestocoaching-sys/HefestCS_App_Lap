# TAB 3 (52 SEMANAS POR MÚSCULO CON PATRONES) — DOCUMENTACIÓN TÉCNICA FINAL V3

## RESUMEN

**Tab 3** es un visualizador automático y reactivo que muestra el progreso semanal de volumen (series H/M/L) **POR MÚSCULO** en un ciclo de 52 semanas, **con estructura de periodización inteligente** basada en patrones de entrenamiento.

### Principios obligatorios implementados:
✅ **Unidad de análisis:** MÚSCULO (no programa global)  
✅ **Selector obligatorio:** Dropdown para elegir músculo  
✅ **Estructura visible:** Patrones de entrenamiento (incremento, estable, descarga, intensificación)  
✅ **Nunca vacía:** Siempre muestra 52 semanas (reales + programadas)  
✅ **Prioridad de datos:** REAL > PROGRAMADO  
✅ **Automático:** Sin botones, sin confirmaciones, sin "generar"  
✅ **Diferenciación visual:** REAL (sólido) vs PROGRAMADO (tenue)  
✅ **Sin persistencia:** Solo cálculo y presentación  
✅ **Guía estructural:** No valores rígidos, sino patrones adaptables  

---

## ARQUITECTURA

### 1. Modelo de visualización (NO persistente)

**Archivo:** `lib/domain/models/weekly_volume_view.dart`

```dart
enum WeekVolumeSource { real, planned }

enum WeekPattern {
  increase,         // ↑ Incremento progresivo
  stable,          // → Mantenimiento
  deload,          // ↓ Descarga
  intensification, // ⚡ Intensificación
}

class WeeklyVolumeView {
  final int weekIndex;        // 1–52
  final String muscle;        // Músculo específico
  final int totalSeries;
  final int heavySeries;
  final int mediumSeries;
  final int lightSeries;
  final WeekVolumeSource source;
  final WeekPattern pattern;  // NUEVO: Patrón de la semana
  
  bool get isReal => source == WeekVolumeSource.real;
  bool get isPlanned => source == WeekVolumeSource.planned;
}
```

**Cambios clave:** 
- Agregado `WeekPattern` enum (4 patrones)
- Campo `pattern` obligatorio en `WeeklyVolumeView`

---

## LÓGICA DE PATRONES

### A. Patrones PROGRAMADOS (cuando NO hay datos reales)

**Función:** `_inferPatternProgrammed(weekIndex)`

**Reglas estructurales:**
```dart
if (weekIndex % 4 == 0) → DELOAD      // Cada 4 semanas: descarga
if (weekIndex % 3 == 0) → STABLE      // Cada 3 semanas: mantener
else                     → INCREASE    // Por defecto: incremento
```

**Ejemplos:**
- W1: Incremento
- W2: Incremento
- W3: Estable
- W4: Deload
- W5: Incremento
- W6: Estable
- ...

**Aplicación al volumen:**
- **INCREASE**: `+1 serie` respecto a semana anterior
- **STABLE**: Mantener volumen anterior
- **DELOAD**: `-20%` volumen (reducción temporal)
- **INTENSIFICATION**: Mantener volumen, redistribuir a pesadas (40% heavy, 50% medium, 10% light)

### B. Patrones REALES (inferidos desde bitácora)

**Función:** `_inferPatternFromReal(record, previousWeeks)`

**Lógica de inferencia:**
```dart
final delta = current.totalSeries - previous.totalSeries;
final percentChange = delta / previous.totalSeries * 100;

if (percentChange < -15%)      → DELOAD         // Reducción >15%
if (percentChange > 10%)       → INCREASE       // Aumento >10%
if (abs(percentChange) <= 5%)  → STABLE         // Cambio <5%

// Caso especial: Intensificación
if (heavyRatio > 30% && percentChange > 0%) → INTENSIFICATION
```

**Ventaja:** La bitácora "corrige" la guía programada automáticamente.

---

## FLUJO DE DATOS ACTUALIZADO

### 1. Construcción de 52 semanas (`_buildAllWeeksForMuscle`)

```dart
for (int week = 1; week <= 52; week++) {
  if (realWeeks.containsKey(week)) {
    // REAL: inferir patrón desde comportamiento real
    final pattern = _inferPatternFromReal(rec, previousWeeks);
    weeks.add(WeeklyVolumeView(..., pattern: pattern));
  } else {
    // PROGRAMADO: aplicar patrón estructural
    final planned = _buildPlannedWeekForMuscle(
      weekIndex: week,
      muscle: muscle,
      baseSeries: baseSeries,
      vopSplit: split,
      previousWeeks: weeks, // NUEVO: necesita historial
    );
    weeks.add(planned);
  }
}
```

### 2. Cálculo programado con patrón (`_buildPlannedWeekForMuscle`)

**Nueva firma:**
```dart
WeeklyVolumeView _buildPlannedWeekForMuscle({
  required int weekIndex,
  required String muscle,
  required int baseSeries,
  required Map<String, int> vopSplit,
  required List<WeeklyVolumeView> previousWeeks, // NUEVO
})
```

**Lógica:**
1. Inferir patrón: `_inferPatternProgrammed(weekIndex)`
2. Obtener volumen anterior: `previousWeeks.last.totalSeries`
3. Aplicar patrón:
   ```dart
   switch (pattern) {
     case increase:
       total = previous + 1;
     case stable:
       total = previous;
     case deload:
       total = previous * 0.8;
     case intensification:
       total = previous; // pero cambia distribución H/M/L
   }
   ```
4. Distribuir H/M/L:
   - Normal: según `vopSplit` de Tab 2
   - Deload: 10% heavy, 40% medium, 50% light
   - Intensification: 40% heavy, 50% medium, 10% light

---

## UI ACTUALIZADA

### Tabla con columna "Patrón"

```
| Semana | Total | Patrón        | Pesadas | Medias | Ligeras | Fuente |
|--------|-------|---------------|---------|--------|---------|--------|
| W1     | 12    | ↑ Incremento  | 2       | 7      | 3       | Real   |
| W2     | 13    | ↑ Incremento  | 3       | 8      | 2       | Plan   |
| W3     | 13    | → Estable     | 3       | 8      | 2       | Plan   |
| W4     | 10    | ↓ Descarga    | 1       | 4      | 5       | Plan   |
| W5     | 11    | ↑ Incremento  | 2       | 7      | 2       | Plan   |
| ...    | ...   | ...           | ...     | ...    | ...     | ...    |
```

**Widget:** `_buildPatternBadge(pattern)`

**Iconos y colores:**
- ↑ **Incremento** (verde) — `Icons.trending_up`
- → **Estable** (azul) — `Icons.trending_flat`
- ↓ **Descarga** (naranja) — `Icons.trending_down`
- ⚡ **Intensificación** (rojo) — `Icons.flash_on`

**Tooltips:**
- Incremento: "Incremento progresivo de volumen"
- Estable: "Mantenimiento del volumen actual"
- Descarga: "Reducción temporal para recuperación"
- Intensificación: "Aumento de intensidad (más pesadas)"

---

## VENTAJAS DE ESTA IMPLEMENTACIÓN

### 1. **No es una tabla plana de números**
Cada semana tiene SIGNIFICADO estructural. El coach ve la LÓGICA del entrenamiento.

### 2. **Se entiende la periodización**
Patrón cíclico claro:
- 3 semanas incremento/estable
- 1 semana descarga
- Repetir

### 3. **Anticipar decisiones**
El coach puede ver:
- "W4 será descarga → preparar al asesorado"
- "W12 intensificación → evaluar para competencia"

### 4. **La bitácora corrige automáticamente**
Si el asesorado hace:
- Más series → patrón inferido = INCREASE
- Menos series → patrón inferido = DELOAD
- Redistribuye a pesadas → patrón inferido = INTENSIFICATION

La guía se adapta, no se rompe.

### 5. **Sirve para población general Y competencia**
- General: sigue estructura cíclica conservadora
- Competencia (futuro): puede redistribuir patrones hacia intensificación en semanas finales

---

## CASOS DE USO ACTUALIZADOS

### Caso 1: Cliente nuevo (solo programado)
- W1-52 con patrones estructurales
- Deloads automáticos cada 4 semanas
- Coach ve la guía completa antes de empezar

### Caso 2: Cliente con bitácora parcial
- W1-5: datos reales con patrones inferidos
- W6-52: programado con estructura cíclica
- Los patrones reales pueden no coincidir con programados (corrección automática)

### Caso 3: Cambio de músculo
- Cada músculo tiene su propia estructura de 52 semanas
- Patrones independientes por músculo

### Caso 4: Preparación para competencia (futuro-proof)
Si existe `competitionDate` en `trainingExtra`:
1. Calcular semanas restantes
2. Redistribuir patrones:
   - Semanas -12 a -6: INCREASE (acumulación)
   - Semanas -6 a -2: INTENSIFICATION (pico)
   - Semanas -2 a -1: DELOAD (afinamiento)
   - Semana 0: competencia

---

## IMPLEMENTACIÓN TÉCNICA

### Archivos modificados:
1. `lib/domain/models/weekly_volume_view.dart`
   - ✅ Agregado `enum WeekPattern`
   - ✅ Campo `pattern` en `WeeklyVolumeView`

2. `lib/features/training_feature/widgets/weekly_history_tab.dart`
   - ✅ `_inferPatternProgrammed()` — Patrón estructural
   - ✅ `_inferPatternFromReal()` — Patrón desde bitácora
   - ✅ `_buildPlannedWeekForMuscle()` — Actualizado con lógica de patrón
   - ✅ `_buildAllWeeksForMuscle()` — Merge con inferencia de patrón
   - ✅ `_buildPatternBadge()` — Widget visual
   - ✅ Columna "Patrón" en DataTable

---

## CRITERIOS DE ACEPTACIÓN CUMPLIDOS

✔ **La tabla no es plana** → Cada semana tiene patrón estructural  
✔ **Se entiende la lógica** → Ciclos visibles (3 incremento + 1 deload)  
✔ **El coach puede anticipar** → Ve W4, W8, W12 como deloads  
✔ **La bitácora corrige la guía** → Patrones reales infieren comportamiento  
✔ **Sirve para población general Y competencia** → Estructura adaptable  

---

## TESTING SUGERIDO

1. **Verificar patrón estructural:**
   - Seleccionar músculo sin datos reales
   - Verificar: W4, W8, W12, etc. = Descarga
   - Verificar: W3, W6, W9, etc. = Estable
   - Verificar: Resto = Incremento

2. **Inferencia desde bitácora:**
   - Agregar registro con +15% volumen → Patrón = Incremento
   - Agregar registro con -20% volumen → Patrón = Descarga
   - Agregar registro con 40% pesadas → Patrón = Intensificación

3. **Visualización:**
   - Verificar íconos y colores correctos
   - Verificar tooltips explicativos
   - Verificar columna "Patrón" visible

4. **Compilación:**
   - `flutter analyze` ✅ Sin issues

## RESUMEN

**Tab 3** es un visualizador automático y reactivo que muestra el progreso semanal de volumen (series H/M/L) **POR MÚSCULO** en un ciclo de 52 semanas.

### Principios obligatorios implementados:
✅ **Unidad de análisis:** MÚSCULO (no programa global)  
✅ **Selector obligatorio:** Dropdown para elegir músculo  
✅ **Nunca vacía:** Siempre muestra 52 semanas (reales + programadas)  
✅ **Prioridad de datos:** REAL > PROGRAMADO  
✅ **Automático:** Sin botones, sin confirmaciones, sin "generar"  
✅ **Diferenciación visual:** REAL (sólido) vs PROGRAMADO (tenue)  
✅ **Sin persistencia:** Solo cálculo y presentación  

---

## ARQUITECTURA

### 1. Modelo de visualización (NO persistente)

**Archivo:** `lib/domain/models/weekly_volume_view.dart`

```dart
enum WeekVolumeSource { real, planned }

class WeeklyVolumeView {
  final int weekIndex;        // 1–52
  final String muscle;        // NUEVO: músculo específico
  final int totalSeries;
  final int heavySeries;
  final int mediumSeries;
  final int lightSeries;
  final WeekVolumeSource source;
  
  // Propiedades de conveniencia
  bool get isReal => source == WeekVolumeSource.real;
  bool get isPlanned => source == WeekVolumeSource.planned;
}
```

**Cambio clave:** Ahora incluye campo `muscle` para análisis granular.

---

### 2. UI (Tab 3)

**Archivo:** `lib/features/training_feature/widgets/weekly_history_tab.dart`

**Cambio arquitectónico:** ConsumerStatefulWidget (necesita estado para selector de músculo)

**Características:**

#### 2.1 Selector de músculo (OBLIGATORIO)

```dart
DropdownButtonFormField<String>(
  initialValue: _selectedMuscle,
  items: availableMuscles.map(...),
  onChanged: (value) {
    setState(() => _selectedMuscle = value);
  },
)
```

- **Fuente de músculos:**
  1. VOP (`finalTargetSetsByMuscleUi` o `targetSetsByMuscle`) — prioritario
  2. Historial real (`weeklyVolumeHistory`) — fallback
- **Etiquetas:** Usa `muscleLabelEs(muscle)` para español
- **Selección inicial:** Primer músculo disponible

#### 2.2 Tabla vertical (52 filas)

```
| Semana | Total | Pesadas | Medias | Ligeras | Fuente |
|--------|-------|---------|--------|---------|--------|
| W1     | 12 ↑  | 2       | 7      | 3       | Real   |
| W2     | 13    | 3       | 8      | 2       | Plan   |
| ...    | ...   | ...     | ...    | ...     | ...    |
| W52    | 20    | 4       | 12     | 4       | Plan   |
```

- **Filas dinámicas:** Una por semana (1-52)
- **Colores por tipo:**
  - REAL: sólido (negro, rojo intenso, naranja intenso, azul intenso)
  - PROGRAMADO: tenue (gris, rojo pálido, naranja pálido, azul pálido)
- **Tendencias:** Iconos ↑↓→ comparando con semana anterior
- **Tooltips:** Explican origen de dato
- **Badges:** "Real" (verde) / "Plan" (gris)

#### 2.3 Leyenda

Diferencia visualmente REAL vs PROGRAMADO.

---

## FLUJO DE DATOS

### A. Cargar músculos disponibles

**Función:** `_getAvailableMuscles()`

```dart
1. Leer VOP (targetSetsByMuscle)
2. Leer weeklyVolumeHistory
3. Unir y ordenar
4. Retornar lista única
```

### B. Cargar datos REALES por músculo

**Función:** `_loadRealWeeksForMuscle(muscle)`  
**Fuente:** `client.training.extra['weeklyVolumeHistory']`  
**Tipo:** `List<Map<String, dynamic>>` que parsea a `WeeklyVolumeRecord`

```dart
final realWeeks = _loadRealWeeksForMuscle(trainingExtra, muscle);
// Retorna: Map<int, WeeklyVolumeRecord>
// Clave: weekIndex (1–52)
// Valor: WeeklyVolumeRecord FILTRADO por muscle
```

### C. Cargar configuración

**Distribución H/M/L:**  
```dart
final split = _loadSeriesSplit(trainingExtra);
// Retorna: {'heavy': 20, 'medium': 60, 'light': 20} (ej.)
// Fuente: trainingExtra['seriesTypePercentSplit'] (Tab 2)
// Validación: Suma debe ser 100
// Fallback: 20/60/20 si no existe o inválido
```

**Baseline de series por músculo:**  
```dart
final baseSeries = _loadBaseSeriesForMuscle(trainingExtra, muscle);
// Retorna: int (VOP del músculo específico)
// Fuente: trainingExtra['finalTargetSetsByMuscleUi'][muscle]
// Fallback: 12 si no existe
```

### D. Merge REAL → PROGRAMADO por músculo

**Lógica:** Para cada semana 1–52:

```dart
if (realWeeks.containsKey(week)) {
  // REAL: usar dato registrado para este músculo
  weeksToDisplay[week] = WeeklyVolumeView(..., source: real)
} else {
  // PROGRAMADO: calcular para este músculo
  weeksToDisplay[week] = _buildPlannedWeekForMuscle(...)
}
```

### E. Calcular PROGRAMADO por músculo

**Función:** `_buildPlannedWeekForMuscle()`

```dart
// Progresión lineal suave (1 serie cada 4 semanas)
final increment = (weekIndex - 1) ~/ 4;
final total = (baseSeries + increment)
  .clamp(baseSeries, baseSeries * 2)
  .toInt();

// Distribuir H/M/L
final heavy = (total * split['heavy']! / 100).round();
final medium = (total * split['medium']! / 100).round();
final light = total - heavy - medium; // Ajuste exacto
```

**Reglas científicas:**
- Progresión: ~1 serie cada 4 semanas (ultra-conservadora)
- Clamp: Nunca menor que baseSeries, nunca mayor que baseSeries*2
- Distribución: Según split de Tab 2

### F. Calcular tendencia

**Función:** `_calculateTrend()`

Compara totalSeries de semana actual vs anterior:
- ↑ (up): aumento
- → (stable): igual
- ↓ (down): descenso

---

## REACTIVIDAD

**El widget es ConsumerStatefulWidget:**  
- Mantiene estado local `_selectedMuscle`
- NO persiste nada en DB
- NO modifica clientsProvider
- Solo calcula al vuelo basado en trainingExtra pasado

**¿Cuándo se refresca?**
- Si se pasa `trainingExtra` actualizado (ej., cambio en Tab 2 o nueva entrada en `weeklyVolumeHistory`)
- Si usuario cambia músculo en dropdown → setState()
- El widget recalcula automáticamente

---

## CÓMO AGREGAR DATOS REALES

**Punto de integración:**  
Cuando se complete una semana de entrenamiento y se registre en `trainingSessionLogRecords`, generar un `WeeklyVolumeRecord` **POR MÚSCULO** y agregarlo a `client.training.extra['weeklyVolumeHistory']`.

**Ejemplo:**
```dart
// En el servicio que guarda bitácora
final history = List<Map<String, dynamic>>.from(
  (extra[TrainingExtraKeys.weeklyVolumeHistory] as List?) ?? [],
);

// IMPORTANTE: Agregar UN REGISTRO POR MÚSCULO
history.add(WeeklyVolumeRecord(
  weekIndex: 1,
  muscleGroup: 'pecho',  // Músculo específico
  totalSeries: 20,
  heavySeries: 4,
  mediumSeries: 12,
  lightSeries: 4,
).toMap());

history.add(WeeklyVolumeRecord(
  weekIndex: 1,
  muscleGroup: 'espalda',  // Otro músculo
  totalSeries: 18,
  heavySeries: 3,
  mediumSeries: 11,
  lightSeries: 4,
).toMap());

// Mantener últimas 52 semanas × músculos
if (history.length > 52 * 10) {  // Ajustar según cantidad de músculos
  history.removeRange(0, history.length - (52 * 10));
}

extra[TrainingExtraKeys.weeklyVolumeHistory] = history;

// Persistir con updateActiveClient
ref.read(clientsProvider.notifier).updateActiveClient((c) {
  return c.copyWith(training: c.training.copyWith(extra: extra));
});
```

---

## CASOS DE USO

### Caso 1: Cliente sin VOP definido
Tab 3 muestra **estado vacío**.  
Texto: "Define el VOP en Tab 1 para ver el progreso semanal."

### Caso 2: Cliente con VOP pero sin datos reales
- Dropdown muestra músculos del VOP
- Tab 3 muestra **52 semanas programadas** para músculo seleccionado
- Progresión teórica conservadora
- Todos los badges "Plan" (gris)

### Caso 3: Cliente con algunas semanas reales
- Tab 3 mezcla **datos reales** (colores sólidos, badge "Real") + **proyecciones** (tenues, badge "Plan")
- Diferenciación visual clara
- Tendencias ↑↓→ entre semanas

### Caso 4: Cambio de músculo en dropdown
- UI se refresca automáticamente
- Muestra datos del nuevo músculo seleccionado
- Sin persistencia, solo visualización

### Caso 5: Cambio en Tab 2 (distribución H/M/L)
- Las **semanas programadas** se recalculan automáticamente
- Las **semanas reales** no cambian (son fijas)
- Solo afecta músculos sin datos reales

### Caso 6: Nueva entrada en `weeklyVolumeHistory`
- La tabla **agrega automáticamente** la semana real para ese músculo
- Recalcula el resto de semanas programadas
- Actualiza tendencias

---

## COSAS QUE NO HACE (INTENCIONAL)

❌ No muestra todos los músculos juntos  
❌ No suma músculos  
❌ No genera semanas al crear plan  
❌ No persiste datos desde la UI  
❌ No tiene botones de "generar", "confirmar", "ajustar"  
❌ No guarda proyecciones en DB  
❌ No implementa deloads automáticos  
❌ No modifica Tab 1 ni Tab 2 lógica base  

---

## TESTING SUGERIDO

1. **Sin VOP:**
   - Abre Tab 3
   - Verifica: Estado vacío con mensaje

2. **Con VOP, sin datos reales:**
   - Abre Tab 3
   - Verifica: Dropdown con músculos
   - Selecciona músculo
   - Verifica: 52 filas, todas "Plan"

3. **Con datos reales parciales:**
   - Agrega manualmente una entrada a `weeklyVolumeHistory` para un músculo
   - Selecciona ese músculo
   - Verifica: Esa semana muestra "Real", otras "Plan"
   - Verifica: Colores diferenciados
   - Verifica: Tendencias ↑↓→

4. **Cambio de músculo:**
   - Selecciona otro músculo en dropdown
   - Verifica: Datos se actualizan automáticamente
   - Verifica: No persistencia (recargar app, vuelve a músculo inicial)

5. **Cambio en Tab 2:**
   - Modifica % H/M/L en Tab 2
   - Abre Tab 3
   - Verifica: Programadas recalculadas, reales sin cambios

6. **Compilación:**
   - `flutter analyze` ✅ Sin issues
