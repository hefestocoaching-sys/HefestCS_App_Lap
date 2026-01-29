## VopSnapshot SSOT Implementation Summary

### Objetivo
Crear una **Single Source of Truth (SSOT)** para el Volumen Operativo Prescrito (VOP), eliminando la actual fragmentación de mapas heredados (`finalTargetSetsByMuscleUi`, `targetSetsByMuscle`, etc.) distribuidos entre múltiples puntos de lectura y escritura.

---

## Arquitectura

### 1. **VopSnapshot Model** (`lib/domain/training/vop_snapshot.dart`)
Modelo `@freezed` que encapsula toda la información del VOP en un único objeto persistible:

```dart
@freezed
class VopSnapshot with _$VopSnapshot {
  const factory VopSnapshot({
    required String generatedAtIso,
    required Map<String, double> totalSetsByMuscle,
    required Map<String, Map<String, double>> setsByMuscleAndIntensity,
    required Map<String, Map<String, double>> setsByMuscleAndPriority,
    required Map<String, String> muscleGroupMapping,
    required List<String> allMuscles,
    String? trainingProfileId,
    @Default(false) bool migratedFromLegacy,
    Map<String, dynamic>? legacySourceData,
  }) = _VopSnapshot;
}
```

**Características:**
- ✅ Almacenado en `training.extra['vopSnapshot']`
- ✅ Incluye breakdown por intensidad (H/M/L) y prioridad
- ✅ Mapeo de grupos musculares (divisibles a padres)
- ✅ Flag de migración para datos heredados
- ✅ Métodos de acceso seguro (`getTotalSetsForMuscle`, `getIntensityForMuscle`, etc.)

### 2. **VopContext Helper** (`lib/features/training_feature/context/vop_context.dart`)
Utilidades para acceder y gestionar VopSnapshot:

```dart
class VopContext {
  // Lectura
  static VopSnapshot? readSnapshot(Map<String, dynamic>? extra)
  static VopSnapshot? tryMigrateFromLegacy(Map<String, dynamic>? extra)
  static VopSnapshot? getOrMigrate(Map<String, dynamic>? extra)
  
  // Escritura
  static Map<String, dynamic> writeSnapshot(Map<String, dynamic> extra, VopSnapshot snapshot)
  
  // Validación
  static bool isValid(VopSnapshot? snapshot)
  static double getTotalSetsForMuscle(VopSnapshot? snapshot, String muscle)
}
```

**Estrategia:**
- `getOrMigrate()`: Intenta lectura de VopSnapshot → migration de mapas legacy → null
- Sin fallbacks silenciosos ni placeholders
- Expone dependencia del catálogo cuando es crítica

### 3. **Key en TrainingExtraKeys** (`lib/core/constants/training_extra_keys.dart`)
```dart
static const vopSnapshot = 'vopSnapshot';
```

---

## Flujo de Datos

### **Tab 2 (IntensitySplitTable) — ESCRITOR**
`training_plan_provider.dart::generatePlan()`

**Paso 1: Síntesis de VOP**
```dart
// Derivar totalSetsByMuscle desde planConfig
final Map<String, double> finalTargetSetsByMuscleUi = {};
rawPriorityIntensity.forEach((muscle, priorityMap) {
  double total = 0;
  priorityMap.forEach((_, intensityMap) {
    intensityMap.forEach((_, sets) => total += sets as num);
  });
  finalTargetSetsByMuscleUi[muscle] = total;
});
```

**Paso 2: Crear VopSnapshot**
```dart
final vopSnapshot = _buildVopSnapshot(
  totalSetsByMuscle: finalTargetSetsByMuscleUi,
  profileExtra: snapshotExtra,
);
if (vopSnapshot != null) {
  extra = VopContext.writeSnapshot(extra, vopSnapshot);
}
```

**Paso 3: Persistir en Firestore**
- Se guarda automáticamente en `client.training.extra['vopSnapshot']`
- Los mapas legacy se conservan por compatibilidad (pueden ser retirados después)

### **Tabs 3, 4 & 1 (Lectores) — LECTURA SÓLO**

#### Tab 3 (MacrocycleOverviewTab)
```dart
int _resolveBaselineForMuscle(String muscle) {
  final vopSnapshot = VopContext.getOrMigrate(widget.trainingExtra);
  if (vopSnapshot != null && VopContext.isValid(vopSnapshot)) {
    return vopSnapshot.getTotalSetsForMuscle(muscle)?.round() ?? 0;
  }
  // Fallback SÓLO si no hay snapshot y no hay legacy
  return _fallbackByMuscleSize(muscle);
}
```

#### Tab 4 (WeeklyPlanTab)
```dart
Map<String, int> _extractVopByMuscleInternal() {
  final vopSnapshot = VopContext.getOrMigrate(widget.trainingExtra);
  if (vopSnapshot != null && VopContext.isValid(vopSnapshot)) {
    final result = <String, int>{};
    vopSnapshot.totalSetsByMuscle.forEach((muscle, value) {
      result[muscle] = value.round();
    });
    return result;
  }
  // Fallback a legacy
  return _extractLegacyVop();
}
```

#### Tab 2 (IntensitySplitTable) — Lectura y Edición de Split
```dart
@override
Widget build(BuildContext context) {
  final vopSnapshot = VopContext.getOrMigrate(widget.trainingExtra);
  if (vopSnapshot != null && VopContext.isValid(vopSnapshot)) {
    // Mostrar VOP desde snapshot
    final vopRaw = vopSnapshot.totalSetsByMuscle;
  } else {
    // Fallback a legacy maps
  }
  // Tabs 2 NO modifica el VOP directamente
  // Edita seriesTypePercentSplit (distribución H/M/L)
}
```

#### Tab 1 (VolumeRangeMuscleTable)
```dart
List<VolumeRangeUiRow> mapFromTrainingExtra(
  Map<String, dynamic>? extra,
  VolumeRangeMuscleTable parent,
) {
  // Lee directamente de extra['mevByMuscle'], extra['mrvByMuscle']
  // (datos del motor v2, independientes de VOP)
  // No necesita VopSnapshot
}
```

---

## Cambios Implementados

### Archivos Creados
1. **`lib/domain/training/vop_snapshot.dart`**
   - Modelo VopSnapshot con factories
   - Helpers de construcción desde mapas legacy

2. **`lib/features/training_feature/context/vop_context.dart`**
   - Utilidades de acceso y migración
   - Validación segura

### Archivos Modificados
1. **`lib/core/constants/training_extra_keys.dart`**
   - Agregada key `vopSnapshot`

2. **`lib/features/training_feature/providers/training_plan_provider.dart`**
   - Importación de VopSnapshot y VopContext
   - Agregado `_buildVopSnapshot()` method
   - Escritura de vopSnapshot en updateActiveClient()
   - Helpers `_readIntensityMap()`, `_readPriorityMap()`, `_readMuscleGroupMapping()`

3. **`lib/features/training_feature/widgets/macrocycle_overview_tab.dart`**
   - Importación de VopContext
   - Refactorizado `_resolveVopMapNormalized()` para usar SSOT
   - Refactorizado `_resolveBaselineForMuscle()` con fallback seguro

4. **`lib/features/training_feature/widgets/weekly_plan_tab.dart`**
   - Importación de VopContext
   - Refactorizado `_extractVopByMuscleInternal()` para usar SSOT

5. **`lib/features/training_feature/widgets/intensity_split_table.dart`**
   - Importación de VopContext
   - Refactorizado `build()` para leer de SSOT primero

---

## Migración y Compatibilidad

### Datos Antiguos (sin VopSnapshot)
1. Primera lectura detecta ausencia de vopSnapshot
2. `VopContext.getOrMigrate()` construye snapshot desde mapas legacy
3. Snapshot se utiliza con `migratedFromLegacy=true`
4. En próxima generación de plan, se escribe vopSnapshot nativo

### Garantías
- ✅ Backwards compatible con datos heredados
- ✅ No requiere migración inmediata de BD
- ✅ Transición gradual hacia SSOT puro
- ✅ Mapas legacy se preservan durante transición

---

## Validación y Pruebas Sugeridas

### Escenarios
1. **New Plan Generation**
   - Generar plan → verificar vopSnapshot en extra
   - Verificar totalSetsByMuscle tiene valores correctos
   - Verificar allMuscles es lista única ordenada

2. **Lectura en Tabs**
   - Tab 3: Baseline para cada músculo coincide con vopSnapshot.totalSetsByMuscle
   - Tab 4: VOP por músculo expandido correctamente
   - Tab 2: Mostrar VOP sin errores

3. **Migración Legacy**
   - Cliente sin vopSnapshot + con finalTargetSetsByMuscleUi heredado
   - Lectura detectors VopSnapshot faltante → migra → usa con flag
   - Próxima generación escribe vopSnapshot nativo

4. **Split Distribution**
   - Tab 2 conserva seriesTypePercentSplit separado (no modifica VOP)
   - H/M/L split persiste independientemente

---

## Diagrama de Flujo

```
[Cliente Entrenamiento]
    ↓
    client.training.extra
    ├── vopSnapshot (NUEVO)
    │   ├── totalSetsByMuscle
    │   ├── setsByMuscleAndIntensity
    │   ├── setsByMuscleAndPriority
    │   └── muscleGroupMapping
    │
    ├── seriesTypePercentSplit (LEGACY, conservado)
    │   └── {heavy, medium, light} %
    │
    ├── targetSetsByMuscle (LEGACY, conservado para compat)
    ├── finalTargetSetsByMuscleUi (LEGACY, conservado para compat)
    └── ... otros keys ...

[Tab 2 — IntensitySplitTable]
    ↓ VopContext.getOrMigrate()
    ↓ Lecturo vopSnapshot
    ↓ Muestro VOP + Split H/M/L
    ↓ No modifica VOP (sólo distribuye por intensidad)

[Tab 3 — MacrocycleOverviewTab]
    ↓ VopContext.getOrMigrate()
    ↓ _resolveBaselineForMuscle()
    ↓ Construyo progreso 52 semanas

[Tab 4 — WeeklyPlanTab]
    ↓ VopContext.getOrMigrate()
    ↓ _extractVopByMuscleInternal()
    ↓ Distribuyo VOP entre días
```

---

## Próximos Pasos (Opcional)

1. **Deprecación gradual de mapas legacy**
   - Mantener 3-4 releases de transición
   - Loguear warnings cuando se use fallback legacy
   - Eventual eliminación de keys legacy

2. **Mejoras a VopSnapshot**
   - Versioning (schema)
   - Auditoría de cambios (quién/cuándo)
   - Validaciones más estrictas en lectura

3. **UI improvements**
   - Mostrar "SSOT" badge cuando vopSnapshot esté activo
   - Warning visual si datos vienen de migración legacy

---

## Resumen Técnico

| Aspecto | Antes | Después |
|--------|--------|---------|
| **Fuente VOP** | Múltiples keys dispersas | VopSnapshot centralizado |
| **Validación** | Fallbacks silenciosos | VopContext.isValid() explícito |
| **Migración** | Manual/inexistente | Automática en lectura |
| **Dependencia de Catálogo** | Implícita | Explícita en métodos |
| **Composición de datos** | Ad-hoc en cada tab | Unificada en VopSnapshot |

**Resultado:** Código más mantenible, testeable y menos propenso a bugs de divergencia de datos.
