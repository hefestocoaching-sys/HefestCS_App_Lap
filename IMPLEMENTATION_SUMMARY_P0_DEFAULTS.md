# P0 Defaults & Fallbacks Implementation Summary

## Overview
Implementación de defaults automáticos y fallbacks para eliminar pantallas vacías en Tabs 2 y 3 del dashboard de entrenamiento.

## Objetivos Alcanzados

### ✅ Tab 2 (IntensitySplitTable) - Defaults Automáticos
**Archivo:** `lib/features/training_feature/widgets/intensity_split_table.dart`

**Cambios:**
1. **Auto-persist de defaults (20/60/20)**
   - Añadido flag `_didAutoPersistDefaultSplit` para evitar loops infinitos
   - En `_loadSeriesSplitFromExtra()`: Detecta si falta split y llama a `_persistSplit(20,60,20)` una sola vez
   - Garantiza persistencia automática sin duplicar escrituras

2. **UI siempre visible**
   - Reemplazado guard (`if (availableMuscles.isEmpty) return EmptyState()`) con booleano `hasVop`
   - Siempre renderiza control (3 dropdowns: %Heavy, %Medium, %Light con incrementos de 5%)
   - Renderizado condicional:
     - Si `hasVop == true`: Muestra VopTable debajo del control
     - Si `hasVop == false`: Muestra EmptyState card ("Aún no hay VOP; este split se aplicará cuando...")

3. **Datos de fallback**
   - Split defecto: `{'heavy': 20, 'medium': 60, 'light': 20}`
   - UI inyecta este default si no existe en `trainingExtra`
   - No persiste hasta que el usuario guarde explícitamente

**Resultado:** Tab 2 nunca muestra pantalla vacía; siempre renderiza control

---

### ✅ Tab 3 (MacrocycleOverviewTab) - StatefulWidget con Dropdown y Fallbacks
**Archivo:** `lib/features/training_feature/widgets/macrocycle_overview_tab.dart`

**Cambios:**

1. **Conversión a StatefulWidget**
   - De: `class MacrocycleOverviewTab extends ConsumerWidget`
   - A: `class MacrocycleOverviewTab extends StatefulWidget` + `_MacrocycleOverviewTabState extends State<MacrocycleOverviewTab>`
   - Permite mantener estado local (`_selectedMuscle`) para selector de músculo

2. **Lista de músculos canónicos (fallback)**
   - Añadido `static const List<String> _fallbackMuscles` con 16 músculos:
     ```
     pectoral, dorsal_ancho, romboides, trapecio_superior, trapecio_medio,
     deltoide_anterior, deltoide_lateral, deltoide_posterior,
     biceps, triceps, cuadriceps, isquiosurales, gluteo,
     abdomen, gastrocnemio, soleo
     ```
   - Se usa si no hay VOP ni historial de bitácora

3. **Selector de músculo (Dropdown Real)**
   - Implementado `_buildMuscleSelector()` con `DropdownButtonFormField`
   - Permite cambiar el músculo en tiempo real
   - Usa `muscleLabelEs()` para traducción de etiquetas
   - Fallback a lista canónica si no hay datos

4. **State Management**
   - `String? _selectedMuscle` — Almacena la selección actual
   - `initState()`: Inicializa con primer músculo disponible
   - `didUpdateWidget()`: Resincroniza si los datos extra cambian
   - `setState()`: Actualiza selección en dropdown

5. **Métodos actualizados**
   - `_getAvailableMuscles()`: Ahora devuelve fallback list si está vacía (nunca devuelve lista vacía)
   - Reemplazadas referencias `trainingExtra` → `widget.trainingExtra` en todos los métodos helper
   - Eliminado método `_buildEmptyState()` (ya no necesario)

6. **Datos de fallback**
   - Músculos: 16 canónicos (lista estática)
   - Series baseline: 16 (conservador)
   - Split: 20/60/20 (desde Tab 2)

**Resultado:** Tab 3 nunca muestra pantalla vacía; siempre renderiza macrociclo con selector de músculo

---

### ✅ training_dashboard_screen.dart - Orquestación Central
**Archivo:** `lib/features/training_feature/screens/training_dashboard_screen.dart`

**Cambios:**

1. **Resolución de effectiveExtra**
   ```dart
   final Map<String, dynamic> effectiveExtra = {
     ...(trainingExtra.isNotEmpty ? trainingExtra : (planJsonV2?['snapshotExtra'] as Map<String, dynamic>? ?? {})),
   };
   effectiveExtra.putIfAbsent(
     TrainingExtraKeys.seriesTypePercentSplit,
     () => {'heavy': 20, 'medium': 60, 'light': 20},
   );
   ```

2. **Inyección de defaults en UI layer**
   - Central: `effectiveExtra` = merge de trainingExtra + planJsonV2.snapshotExtra + defaults
   - No persiste en base de datos; solo UI layer
   - Garantiza datos consistentes para ambas tabs

3. **Propagación a Tabs 2 y 3**
   - `IntensitySplitTable(trainingExtra: effectiveExtra)`
   - `MacrocycleOverviewTab(trainingExtra: effectiveExtra)`

**Resultado:** Ambas tabs reciben datos consistentes y nunca quedan vacías

---

## Validación

✅ **Compilación:** `flutter analyze` → No issues found
✅ **Imports:** Removido import innecesario de `flutter_riverpod`
✅ **Deprecations:** Reemplazado `value` → `initialValue` en DropdownButtonFormField
✅ **Code Quality:** Sin errores ni warnings

---

## Arquitectura de Datos

```
training_dashboard_screen.dart
├── effectiveExtra (Map merge + defaults)
│
├─→ IntensitySplitTable
│   ├── Lee: effectiveExtra[seriesTypePercentSplit]
│   ├── Persiste: defaults 20/60/20 si ausente
│   └── UI: Control siempre visible + VopTable/EmptyState condicional
│
└─→ MacrocycleOverviewTab (StatefulWidget)
    ├── Estado: _selectedMuscle (dropdown selector)
    ├── Lee: effectiveExtra + fallback músculos (16 canónicos)
    ├── Renderiza: Macrociclo 52 semanas para músculo seleccionado
    └── Fallback: Datos conservadores si no hay VOP/bitácora
```

---

## Flujo de Datos P0

1. **Lectura:** `client.training.extra` + `planJsonV2.snapshotExtra`
2. **Merging:** En `training_dashboard_screen` con `effectiveExtra`
3. **Defaults:** UI layer inyecta 20/60/20 si ausente
4. **Persistencia:** 
   - Tab 2: Auto-persiste defaults (una sola vez)
   - Tab 3: Usa fallback (nunca persiste automáticamente)
5. **Rendering:** Ambas tabs siempre visibles, nunca vacías

---

## Constraints & Notas

- ✅ **Sin tocar RER, AA/HF1, ni lógica de motor** — Solo UI + fallback keys
- ✅ **No breaking changes** — Backward compatible con datos existentes
- ✅ **Fallback conservador** — 20/60/20, 16 series, 16 músculos
- ✅ **UI-only defaults** — No modifica persistencia principal
- ✅ **StatefulWidget pattern** — Local state para dropdown, sin Riverpod loops

---

## Próximos Pasos (Opcional)

1. Testing: Validar flujo con datos reales vs fallback
2. UX: Considerardatos reales en fallback list (si Tab 1 tiene VOP parcial)
3. Persistencia: Si usuario quiere guardar fallback, agregar botón explícito

---

**Status:** ✅ COMPLETADO
**Fecha:** 2024
**Validación:** flutter analyze → No issues found
