# QUICK START: Integrar Macrocycle en Dashboard

## 📋 Requisitos previos
- ✅ Módulo compilado (flutter analyze: 0 issues)
- ✅ Todos los archivos creados en lib/
- ✅ Tab 1 (Volumen) y Tab 2 (Intensidad) funcionales

---

## 🚀 Opción 1: Agregar como Tab 3 (Recomendado)

### Paso 1: Abre TrainingDashboardScreen
Archivo: `lib/features/training_feature/screens/training_dashboard_screen.dart`

### Paso 2: Importa el widget
```dart
import 'package:hcs_app_lap/features/training_feature/widgets/macrocycle_overview_tab.dart';
```

### Paso 3: Aumenta TabController length
Busca:
```dart
_tabController = TabController(length: 2, vsync: this);
```

Reemplaza por:
```dart
_tabController = TabController(length: 3, vsync: this);
```

### Paso 4: Agrega Tab al TabBar
Busca:
```dart
TabBar(
  controller: _tabController!,
  tabs: const [
    Tab(text: 'Volumen'),
    Tab(text: 'Intensidad'),
  ],
)
```

Reemplaza por:
```dart
TabBar(
  controller: _tabController!,
  tabs: const [
    Tab(text: 'Volumen'),
    Tab(text: 'Intensidad'),
    Tab(text: 'Periodización'),  // ← NUEVO
  ],
)
```

### Paso 5: Agrega widget al TabBarView
Busca:
```dart
TabBarView(
  controller: _tabController!,
  children: [
    VolumeRangeMuscleTable(...),
    IntensitySplitTable(...),
  ],
)
```

Reemplaza por:
```dart
TabBarView(
  controller: _tabController!,
  children: [
    VolumeRangeMuscleTable(...),
    IntensitySplitTable(...),
    MacrocycleOverviewTab(),  // ← NUEVO
  ],
)
```

### Paso 6: Verifica y ejecuta
```bash
flutter analyze
flutter run
```

---

## 🎮 Opción 2: Ver ejemplo educativo primero

Si quieres entender el flujo antes de integrar:

```dart
// En qualquier lugar del código puedes mostrar:
import 'package:hcs_app_lap/features/training_feature/widgets/macrocycle_weekly_calculator_example.dart';

// Luego usarlo:
MacrocycleWeeklyCalculatorExample()
```

Esto muestra:
1. Selector interactivo de semana (W1-52)
2. Flujo visual: VOP base → multiplicador → VOP efectivo → distribución
3. Explicación de cómo funciona

---

## ✨ Opción 3: Agregar selector interactivo (Futuro)

Si quieres que usuarios seleccionen la semana actual:

```dart
// En MacrocycleOverviewTab, agregar encima de la tabla:
DropdownButton<int>(
  value: _selectedWeek,
  items: List.generate(52, (i) => DropdownMenuItem(
    value: i + 1,
    child: Text('Semana ${i + 1}'),
  )),
  onChanged: (week) {
    setState(() => _selectedWeek = week!);
    // Opcional: guardar en client.training.extra
  },
)
```

Esto requeriría convertir `MacrocycleOverviewTab` a `StatefulWidget`.

---

## 🔍 Verificación post-integración

Después de integrar, verifica:

1. **Dashboard abre sin errores**
   ```bash
   flutter run
   ```

2. **Tab 4 se muestra correctamente**
   - Click en "Periodización"
   - Debe ver tabla de 52 semanas

3. **Contenido es correcto**
   - Semana 1: AA, multiplier 1.0
   - Semana 5: HF1, multiplier 1.0
   - Semana 21: APC1, multiplier 1.15
   - Semana 52: deload, multiplier 0.5

4. **No hay errores en logs**
   ```
   flutter logs
   ```

---

## 🛠️ Solución de problemas

### Error: "MacrocycleOverviewTab not found"
- Verifica que el archivo exista: `lib/features/training_feature/widgets/macrocycle_overview_tab.dart`
- Verifica el import: debe ser el path correcto

### Error: "TabController length mismatch"
- Verifica que TabController.length = 3
- Verifica que TabBarView tenga exactamente 3 children

### Tab no aparece en la UI
- Ejecuta `flutter clean && flutter pub get`
- Luego `flutter run` de nuevo

### flutter analyze muestra errores
- Ejecuta `flutter pub get` para actualizar dependencias
- Si persiste, verifica que no hay importes faltantes

---

## 📊 Validación rápida de funcionamiento

Abre `macrocycle_weekly_calculator_example.dart` y ejecuta standalone:

```dart
// En lib/main.dart, temporalmente reemplaza home:
home: MacrocycleWeeklyCalculatorExample(),

// Verás:
// - Selector de semana (1-52)
// - Flujo visual de transformación
// - Valores calculados correctamente
```

Si el flujo se ve correcto, la integración al dashboard funcionará.

---

## ⏸️ Pausa: Si necesitas modificar multiplicadores

Los multiplicadores están en:
`lib/domain/services/macrocycle_template_service.dart`

Función: `buildDefaultMacrocycle()`

Ejemplo de cambio:
```dart
// Semana 1-4: AA
final aa1 = MacrocycleWeek(
  weekNumber: 1,
  phase: MacroPhase.adaptation,
  block: MacroBlock.AA,
  volumeMultiplier: 1.0,  // ← Cambiar aquí
  isDeload: false,
);
```

Después de cambios:
```bash
flutter analyze  # Verificar
flutter run      # Probar
```

---

## 📚 Documentación completa

Para entender la arquitectura completa:
- `docs/MACROCYCLE_ARCHITECTURE.md` — Diseño completo
- `docs/MACROCYCLE_MODULE_STATUS.txt` — Status y guía técnica

---

## ✅ Checklist final

- [ ] Archivo macrocycle_overview_tab.dart existe
- [ ] Import agregado en TrainingDashboardScreen
- [ ] TabController.length = 4
- [ ] Tab "Periodización" agregado al TabBar
- [ ] MacrocycleOverviewTab() agregado a TabBarView
- [ ] flutter analyze sin errores
- [ ] flutter run sin errores
- [ ] Tab 3 (Periodización) abre y muestra tabla
- [ ] Tabla muestra 52 semanas
- [ ] Multiplicadores coinciden con Excel

---

**¡Listo para integrar! 🎯**

Si tienes preguntas o necesitas modificaciones, consulta:
- Arquitectura: `docs/MACROCYCLE_ARCHITECTURE.md`
- Status: `docs/MACROCYCLE_MODULE_STATUS.txt`
- Ejemplo: `macrocycle_weekly_calculator_example.dart`
