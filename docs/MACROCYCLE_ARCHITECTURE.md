# Módulo de Periodización (Macrocycle) — Arquitectura y Guía de Integración

## Visión General

El módulo de macrocycle implementa la **estrategia de periodización anual (52 semanas)** sin duplicar ni interferir con:
- Cálculos de VME / VMR (referencias fisiológicas, nunca entrenables)
- Cálculo de VOP (volumen entrenable único, viene de Tab 1)
- Distribución de intensidades (Pesadas / Medias / Ligeras, viene de Tab 2 y nunca cambia)

**Responsabilidad única**: Aplicar multiplicadores semanales al VOP base.

---

## Estructura de Código

### 1. Dominio (Modelos)

#### `lib/domain/training/macrocycle_week.dart`
Define:
- `MacroPhase`: enum con las 5 fases (adaptation, hypertrophy, intensification, peaking, deload)
- `MacroBlock`: enum con 11 bloques específicos (AA, HF1–HF4, APC1–APC5, PC)
- `MacrocycleWeek`: clase que representa UNA semana (weekNumber, phase, block, volumeMultiplier, isDeload)

**Responsabilidad**: Modelar estructura sin cálculos.

### 2. Servicios (Lógica)

#### `lib/domain/services/macrocycle_template_service.dart`
Genera la estructura de 52 semanas.

**Métodos públicos**:
- `buildDefaultMacrocycle()` → `List<MacrocycleWeek>`
  - Retorna la plantilla estándar (AA 4w, HF1–HF4 16w, APC1–APC5 15w, PC 16w, deload en semanas 4, 8, 12, 16, 21, 26, 32, 42, 52)
  - NO toca músculos, volúmenes ni prioridades
  - Completamente determinista

- `getWeekByNumber(macrocycle, weekNumber)` → `MacrocycleWeek?`
- `getWeeksByBlock(macrocycle, block)` → `List<MacrocycleWeek>`
- `getWeeksByPhase(macrocycle, phase)` → `List<MacrocycleWeek>`
- `getDeloadWeeks(macrocycle)` → `List<MacrocycleWeek>`

**Responsabilidad**: Generar y navegar la estructura anual.

#### `lib/domain/training/macrocycle_calculator.dart`
Calcula volúmenes efectivos **reutilizando** el motor existente.

**Funciones**:
- `calculateEffectiveVopForWeek(baseVop, week)` → `double`
  - Multiplica VOP base por el multiplicador de la semana
  - Ejemplo: 10 × 1.15 = 11.5

- `calculateIntensityDistributionForWeek(effectiveVop, intensitySplit)` → `Map<String, int>`
  - Reutiliza `splitByIntensity()` del motor
  - Aplica exactamente el mismo algoritmo de redondeo
  - El perfil de intensidad NO cambia

- Clase `MacrocycleWeekSummary`
  - Encapsula: week, baseVop, effectiveVop, intensitySplit, distribution
  - Método `calculate()` factory para crear resúmenes tipados

**Responsabilidad**: Transformar VOP base en VOP efectivo SIN rehacer matemática.

### 3. UI (Presentación)

#### `lib/features/training_feature/widgets/macrocycle_overview_tab.dart`
**Pestaña de visualización estratégica** (solo lectura).

**Muestra**:
- Tabla de 52 semanas con: # | Bloque | Fase | Tipo | Multiplicador
- Código de color: Acumulación (verde) / Descarga (morado)
- Leyenda de fases y bloques
- Advertencia: "Solo referencia estratégica, no modifica VOP ni intensidades"

**NO muestra**:
- Series por músculo (eso es runtime)
- VME/VMR
- Distribución de intensidades (reutiliza Tab 2)

#### `lib/features/training_feature/widgets/macrocycle_weekly_calculator_example.dart`
**Widget educativo** (demostración del flujo).

Muestra:
1. VOP base (Tab 1)
2. × Multiplicador (Macrocycle)
3. = VOP efectivo (esta semana)
4. Distribución (Tab 2, sin cambios)

**Uso**: Probar integración, entender lógica.

---

## Flujo de Datos

```
ACTUAL (Tabs 1 y 2):
┌─────────────────────────────┐
│  Motor (VME, VMR, VOP)      │
│  + Priority Lists           │
└──────────────┬──────────────┘
               │
      ┌────────┴────────┐
      │                 │
   Tab 1            Tab 2
  Volumen       Intensidad
  (VOP+Rol)     (H/M/L split)
                (RIR guía)


CON MACROCYCLE (Nuevo Tab 3):
┌──────────────────────────────────┐
│  Motor (VME, VMR, VOP)           │
│  + Priority Lists                │
│  + Intensity Split (default)     │
└──────────────┬────────────────────┘
               │
      ┌────────┼────────┬──────────┐
      │        │        │          │
   Tab 1    Tab 2    Tab 3    
  Volumen  Intensidad Periodización
  (VOP+Rol)(H/M/L)    (estrategia)
           (RIR)      (×V,plantilla)
           
           │
           └─→ Runtime: 
               Para cada semana:
               effectiveVop = baseVop × multiplier
               distribution = reutiliza split
```

---

## Integración en Dashboard

### Paso 1: Agregar Tab 3 al TabBar

```dart
TabBar(
  controller: _tabController!,
  tabs: const [
    Tab(text: 'Volumen'),
    Tab(text: 'Intensidad'),
    Tab(text: 'Periodización'),  // ← NUEVO
  ],
)

// Aumentar TabController de 2 a 3
_tabController = TabController(length: 3, vsync: this);

// Agregar al TabBarView
TabBarView(
  controller: _tabController!,
  children: [
    VolumeRangeMuscleTable(...),
    IntensitySplitTable(...),
    MacrocycleOverviewTab(),  // ← NUEVO
  ],
)
```

### Paso 2: (Futuro) Agregar selector de semana interactivo

```dart
// Widget futura: MacrocycleWeekSelector
// Lee la semana seleccionada y recalcula volúmenes
// Solo para referencia de coaching, no persiste en training log
```

---

## Verificación de Requisitos

✅ **No duplica lógica**
- Reutiliza `splitByIntensity()` exactamente
- No recalcula VME/VMR
- No toca prioridades

✅ **Separación de concerns**
- Modelo (MacrocycleWeek) limpio
- Servicio (Template) generador puro
- Calculadora (Calculator) sin estado
- UI (Overview) solo lectura

✅ **Extensible para futuro**
- Puede agregar selector de semana
- Puede persistir selección en training log
- Puede mostrar variantes personalizadas

✅ **Respeta Excel original**
- AA (1–4) ✓
- HF1–HF4 (5–20) ✓
- APC1–APC5 (21–35) ✓
- PC (36–51) ✓
- Deload cada 4w + final ✓

---

## Testing

### Unit tests sugeridos

```dart
test('MacrocycleWeek.calculateEffectiveVolume multiplies correctly', () {
  final week = MacrocycleWeek(
    weekNumber: 5,
    phase: MacroPhase.hypertrophy,
    block: MacroBlock.HF1,
    volumeMultiplier: 1.15,
    isDeload: false,
  );
  expect(week.calculateEffectiveVolume(10.0), equals(11.5));
});

test('MacrocycleTemplateService builds 52 weeks', () {
  final macro = MacrocycleTemplateService.buildDefaultMacrocycle();
  expect(macro.length, equals(52));
  expect(macro.first.weekNumber, equals(1));
  expect(macro.last.weekNumber, equals(52));
});

test('MacrocycleCalculator preserves rounding rules', () {
  final result = calculateIntensityDistributionForWeek(
    11.5,
    {'heavy': 0.25, 'medium': 0.5, 'light': 0.25},
  );
  expect(
    result['heavy']! + result['medium']! + result['light']!,
    equals(12), // round(11.5) = 12
  );
});
```

---

## Limpieza de Código

### Buscar y eliminar (si existe código duplicado):

- ❌ Tablas que muestren VME/VMR como si fueran entrenables
- ❌ Cálculos de VOP semanales fuera del motor
- ❌ Mapeos RIR duplicados en Tab 2 (ya simplificado)

### Mantener:

- ✅ TrainingProgramEngine (núcleo)
- ✅ splitByIntensity() en Tab 2
- ✅ Lógica de cálculo central intacta

---

## Próximos Pasos (No implementados aún)

1. **Selector interactivo de semana**
   - Dropdown en Tab 4
   - Muestra volumen efectivo en tiempo real

2. **Persistencia (opcional)**
   - Guardar semana seleccionada en plan.extra
   - Usar en bitácora de sesiones

3. **Variantes personalizadas**
   - Permitir al coach ajustar multiplicadores
   - Base: plantilla default, luego customización

4. **Bitácora semanal**
   - Mostrar semana actual del macrocycle
   - Contexto visual para coach

---

## Principios de Diseño

1. **Single Responsibility**: Cada módulo una responsabilidad clara
2. **DRY (Don't Repeat Yourself)**: Reutiliza motor existente siempre
3. **Separation of Concerns**: Dominio, servicios, UI completamente separados
4. **Type Safety**: Usa enums y clases tipadas, no strings mágicos
5. **Immutability**: MacrocycleWeek es const, no hay estado compartido
6. **No Assumptions**: Solo implementa el Excel exacto, sin reinterpretaciones

---

Documento generado: 18-ENE-2026  
Versión: 1.0  
Autor: Sistema de Desarrollo
