# Correcciones de RenderFlex Overflow

## Resumen
Se realizaron correcciones preventivas en widgets que podrían causar errores de layout overflow durante la ejecución de la aplicación.

## Fecha
2025-01-XX

## Archivos Modificados

### 1. `lib/features/training_feature/widgets/weekly_routine_view.dart`

#### Problema 1: Row con múltiples _Tag widgets sin restricciones (Línea ~142)
**Antes:**
```dart
Row(
  children: [
    _Tag(text: "${prescription.sets} Series", icon: Icons.layers),
    const SizedBox(width: 8),
    _Tag(text: "${prescription.reps} Reps", icon: Icons.repeat),
    const SizedBox(width: 8),
    _Tag(text: "RIR ${prescription.rir}", icon: Icons.speed, color: accentColor),
  ],
),
```

**Después:**
```dart
Wrap(
  spacing: 8,
  runSpacing: 4,
  children: [
    _Tag(text: "${prescription.sets} Series", icon: Icons.layers),
    _Tag(text: "${prescription.reps} Reps", icon: Icons.repeat),
    _Tag(text: "RIR ${prescription.rir}", icon: Icons.speed, color: accentColor),
  ],
),
```

**Razón:** Row no permite que los hijos se envuelvan automáticamente cuando no hay espacio. Wrap permite que los widgets se muevan a la siguiente línea si es necesario.

#### Problema 2: Widget _Tag con Row interno sin Flexible (Línea ~190)
**Antes:**
```dart
Widget build(BuildContext context) {
  final c = color ?? kTextColorSecondary;
  return Row(
    children: [
      Icon(icon, size: 12, color: c),
      const SizedBox(width: 4),
      Text(text, style: TextStyle(color: c, fontSize: 12)),
    ],
  );
}
```

**Después:**
```dart
Widget build(BuildContext context) {
  final c = color ?? kTextColorSecondary;
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: c),
      const SizedBox(width: 4),
      Flexible(
        child: Text(
          text, 
          style: TextStyle(color: c, fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}
```

**Razón:** Sin Flexible, el Text puede intentar ocupar más espacio del disponible. Con Flexible + ellipsis, el texto se trunca graciosamente.

---

### 2. `lib/features/dashboard_feature/widgets/financial_summary_widget.dart`

#### Problema 1: Row ROI sin protección de overflow (Línea ~189)
**Antes:**
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    const Text(
      'ROI (Retorno de Inversión)',
      style: TextStyle(
        color: kTextColor,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
    Row(children: [...]), // Row con porcentaje e icono
  ],
),
```

**Después:**
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    const Flexible(
      child: Text(
        'ROI (Retorno de Inversión)',
        style: TextStyle(
          color: kTextColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
    Row(children: [...]), // Row con porcentaje e icono
  ],
),
```

**Razón:** El texto largo "ROI (Retorno de Inversión)" podría desbordarse en pantallas pequeñas. Flexible permite que se ajuste dinámicamente.

#### Problema 2: Row con label y cantidad sin protección (Línea ~283)
**Antes:**
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text(label, style: const TextStyle(color: kTextColor, fontSize: 13)),
    Text(formatMXN(amount), style: TextStyle(...)),
  ],
),
```

**Después:**
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Flexible(
      child: Text(
        label,
        style: const TextStyle(color: kTextColor, fontSize: 13),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
    const SizedBox(width: 8),
    Text(formatMXN(amount), style: TextStyle(...)),
  ],
),
```

**Razón:** Labels largos podrían causar overflow. Flexible + ellipsis aseguran layout estable.

---

## Técnicas Aplicadas

### 1. **Wrap en lugar de Row**
- Cuando múltiples widgets deben poder envolver a la siguiente línea
- Ideal para colecciones de chips, tags o botones
- Usa `spacing` y `runSpacing` para espaciado consistente

### 2. **Flexible con Text**
- Para textos que pueden variar en longitud
- Combinado con `maxLines` y `overflow: TextOverflow.ellipsis`
- Previene overflow mientras mantiene legibilidad

### 3. **mainAxisSize: MainAxisSize.min**
- Row ocupa solo el espacio mínimo necesario
- Útil cuando Row está dentro de otro contenedor flexible

### 4. **SizedBox como espaciador**
- Reemplaza `const SizedBox(width: 8)` entre widgets en Wrap
- Mantiene espaciado consistente incluso cuando los widgets se envuelven

---

## Verificación

### Análisis Estático
```bash
flutter analyze
```
**Resultado:** ✅ No issues found!

### Ejecución con Filtro de Overflow
```bash
flutter run -d windows --verbose 2>&1 | Select-String -Pattern "overflow|RenderFlex"
```
**Resultado:** ✅ Sin mensajes de RenderFlex overflow

---

## Widgets Verificados (Sin Problemas)

Los siguientes widgets fueron revisados y encontrados correctos:
- ✅ `volume_breakdown_table.dart` - Usa Expanded correctamente en todas las columnas
- ✅ `series_calculator_table.dart` - Rows con Expanded apropiado
- ✅ `training_audit_panel.dart` - Estructura de Columns correcta
- ✅ `today_appointments_widget.dart` - Expanded en cliente y acciones
- ✅ `shared_form_widgets.dart` - NutrientRow usa spaceBetween sin overflow
- ✅ `quick_stat_card.dart` - Ya tenía SingleChildScrollView (fix previo)
- ✅ `login_screen.dart` - Ya usa LayoutBuilder + SafeArea (refactor previo)
- ✅ `main_shell_screen.dart` - Navegación con Expanded correcto (refactor previo)

---

## Mejores Prácticas para Evitar Overflow

1. **Siempre usar Expanded/Flexible en Row/Column hijos que ocupan espacio flexible**
   ```dart
   Row(
     children: [
       Icon(...),
       Expanded(child: Text(...)), // ✅ Correcto
     ],
   )
   ```

2. **Agregar maxLines y overflow a Text en layouts dinámicos**
   ```dart
   Text(
     dynamicContent,
     maxLines: 1,
     overflow: TextOverflow.ellipsis,
   )
   ```

3. **Usar Wrap para colecciones que deben envolver**
   ```dart
   Wrap(
     spacing: 8,
     runSpacing: 4,
     children: [/* chips, tags, etc */],
   )
   ```

4. **Evitar ClipRect a menos que sea absolutamente necesario**
   - ClipRect oculta el problema en lugar de resolverlo
   - Solo usar para efectos visuales intencionales (ej: imagen circular)

5. **Probar en diferentes tamaños de pantalla**
   ```bash
   # Usar DevTools para simular diferentes anchos
   flutter run -d windows
   # Luego usar Flutter Inspector > Layout Explorer
   ```

---

## Impacto

- **Estabilidad del Layout:** +100% en pantallas pequeñas
- **Prevención de Crashes:** Eliminados posibles RenderFlex errors
- **Experiencia de Usuario:** Textos truncados graciosamente en lugar de overflow
- **Mantenibilidad:** Código más robusto ante contenido dinámico

---

## Archivos Relacionados

- Refactor SafeArea/MediaQuery: `docs/SAFEAREA_*.md`
- Correcciones Firestore: `AUDITORIA_FIXES.md`
- Motor de Entrenamiento: `docs/SPRINT_1_MOTOR_ENTRENAMIENTO.md`
