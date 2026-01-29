# Tab 3: Macrociclo Horizontal (Bloques Fisiológicos)

## Cambio Fundamental
**Antes:** Vista vertical con tabla de 52 filas (una fila por semana).  
**Ahora:** Vista horizontal por bloques fisiológicos (AA/HF1/HF2, cada uno con 4 semanas).

## Propósito
Mostrar automáticamente la progresión de volumen semanal **por músculo** en una estructura que visualiza:
- **Eje horizontal:** Semanas (1–52)
- **Agrupadores visuales:** Bloques (AA, HF1, HF2, repetidos cada 12 semanas)
- **Selector:** Dropdown para cambiar de músculo (un músculo a la vez)
- **Fuente de datos:** REAL > PROGRAMADO (bitácora corrige la guía)

---

## Estructura de Bloques

```
AA      (Semanas 1–4)    | HF1     (Semanas 5–8)     | HF2     (Semanas 9–12)   |
AA      (Semanas 13–16)  | HF1     (Semanas 17–20)   | HF2     (Semanas 21–24)  |
AA      (Semanas 25–28)  | HF1     (Semanas 29–32)   | HF2     (Semanas 33–36)  |
AA      (Semanas 37–40)  | HF1     (Semanas 41–44)   | HF2     (Semanas 45–48)  |
AA      (Semanas 49–52)  |
```

**Colores:**
- AA: Rojo
- HF1: Azul
- HF2: Verde

---

## Celda Semanal (Componente Básico)

```
┌─────────────┐
│     S1      │  ← Número de semana
├─────────────┤
│     16      │  ← Total de series (número grande)
├─────────────┤
│   4/10/2    │  ← P/M/L (pesadas/medias/ligeras)
├─────────────┤
│      ↑      │  ← Ícono del patrón
├─────────────┤
│    Real     │  ← Badge (Real/Prog)
└─────────────┘
```

### Significado de Íconos (Patrón):
- `↑` (green) — Incremento (+series)
- `→` (blue) — Estable (mantener)
- `↓` (orange) — Descarga (-20%)
- `⚡` (red) — Intensificación (redistribuir hacia pesadas)

### Badge:
- `Real` (verde) — Dato de la bitácora
- `Prog` (naranja) — Cálculo teórico

---

## Cálculo Programado (Cuando NO hay dato real)

**Fórmula:**
```dart
totalSeries = baseSeries + (weekIndex - 1)
```

Donde `baseSeries` es el VOP para ese músculo.

**Patrón:**
- Cada 4 semanas: deload (×0.8)
- Cada 3 semanas: stable
- Default: increase

**Distribución H/M/L:**
- Aplicar el porcentaje desde Tab 2 (fallback 20/60/20)

**Ejemplo:**
```
Semana 1:  base + 0 = 16 series
Semana 2:  base + 1 = 17 series
Semana 3:  base + 2 = 18 series
Semana 4:  base + 3 = 19 × 0.8 = 15 series (deload)
```

---

## Merge REAL > PROGRAMADO

**Lógica:**
1. Leer `weeklyVolumeHistory` desde `trainingExtra`
2. Filtrar por `muscleGroup` (el seleccionado)
3. Para cada semana 1–52:
   - Si existe REAL → usar ese dato (inferir patrón desde delta)
   - Si NO existe → calcular PROGRAMADO (patrón estructural)

**Inferencia de Patrón (Real):**
```
delta = totalSeries - previousTotal
%change = (delta / previousTotal) × 100

if %change < -15   → deload
if %change > 10    → increase
else               → stable
```

---

## Archivos Involucrados

### Nuevos/Modificados
- **[macrocycle_overview_tab.dart](../lib/features/training_feature/widgets/macrocycle_overview_tab.dart)** — Componente principal (ConsumerWidget)
- **[weekly_volume_view.dart](../lib/domain/models/weekly_volume_view.dart)** — Modelo de vista (WeeklyVolumeView, WeekVolumeSource, WeekPattern)

### Referencias Actualizadas
- **[training_dashboard_screen.dart](../lib/features/training_feature/screens/training_dashboard_screen.dart)** — Cambió importación de `WeeklyHistoryTab` a `MacrocycleOverviewTab`

### Deprecado
- `weekly_history_tab.dart` — Reemplazado por `MacrocycleOverviewTab`

---

## Persistencia

**IMPORTANTE:** La Tab 3 NO persiste datos.

- Tabla es **read-only**
- Datos se recalculan automáticamente al cambiar músculo o al actualizar `weeklyVolumeHistory`
- Datos de entrada:
  - `finalTargetSetsByMuscleUi` (Tab 1 — VOP)
  - `seriesTypePercentSplit` (Tab 2 — H/M/L)
  - `weeklyVolumeHistory` (bitácora — datos reales)

---

## Estados Iniciales

### Caso 1: SIN datos reales (primer día)
```
"Esta es una guía estructural de progresión. 
Se ajusta automáticamente al registrar bitácora."
```
→ Muestra 52 semanas de PROGRAMADO (con patrones teóricos)

### Caso 2: CON datos reales (semanas cerradas)
```
"Progresión teórica ajustada por datos reales de la bitácora."
```
→ Mezcla REAL (cuando existe) con PROGRAMADO (fallback)

---

## Funciones Clave

### `_buildAllWeeksForMuscle()`
Itera semanas 1–52, merge REAL/PROGRAMADO.

### `_inferPatternProgrammed(weekIndex)`
Lógica estructural (ciclical): deload@4, stable@3, else increase.

### `_inferPatternFromReal(totalSeries, previousTotal?)`
Inferencia delta: compara contra semana previa.

### `_buildPlannedWeekForMuscle()`
Calcula serie teórica con patrón y distribución H/M/L.

### `_generateTrainingBlocks()`
Crea lista de TrainingBlockView (AA/HF1/HF2 × 4 ciclos).

---

## Notas de Diseño

1. **No hay botones:** Todo es automático y reactivo.
2. **Scroll horizontal:** Los bloques están en Row dentro de SingleChildScrollView.
3. **Un músculo a la vez:** Simplifica análisis, evita superponer gráficos.
4. **Fallbacks conservadores:**
   - Baseline = 16 series si no existe VOP
   - Split = 20/60/20 si no viene de Tab 2
5. **Tolerancia a errores:** Si falla parseo de fecha, ignora ese registro real.

---

## Acciones Futuras (Sin Cambiar Tab 3)

- Agregar modo "Competencia" que redistribuya patrones hacia intensificación en últimas semanas
- Detectar overtraining y trigger deload adaptativo
- Análisis de correlación entre músculos (si unos decargan, otros también)
- Exportar como PDF/imagen

