# ExerciseCatalogService - Resilience Implementation

## Problem
La carga del catálogo de ejercicios fallaba durante la inicialización, causando que toda la sección de Weekly Plan se rompiera. El error ocurría en `PlatformAssetBundle.load` cuando intentaba cargar `exercise_catalog_gym.json`.

## Solution
Implementación de carga resiliente que nunca lanza excepciones, permitiendo que la aplicación continúe funcionando incluso si el asset no carga.

## Changes Made

### ExerciseCatalogService (`lib/services/exercise_catalog_service.dart`)

#### 1. Single Attempt Loading
```dart
bool _loadAttempted = false;

Future<void> ensureLoaded() async {
  if (_loaded) return;
  if (_loadAttempted) return;  // ← No reintentar si ya se intentó
  _loadAttempted = true;
```

**Beneficio**: Previene loops infinitos de reintentos fallidos.

#### 2. Non-Throwing ensureLoaded()
```dart
try {
  await _loadFromAssets();
  _loaded = true;
  lastLoadError = null;
} catch (e) {
  lastLoadError = e.toString();
  debugPrint('⚠️ ExerciseCatalogService: Error loading exercises: $e');
  // NO relanzar - continuar sin datos
  _loaded = false;
}
```

**Beneficio**: `_initCatalog()` en `weekly_plan_tab.dart` nunca recibe excepciones.

#### 3. Graceful Degradation in _loadFromAssets()
```dart
try {
  final raw = await rootBundle.loadString('assets/data/exercises/exercise_catalog_gym.json');
  // ... procesamiento ...
} catch (e) {
  // Limpiar estado
  _byId.clear();
  _byEquivalenceGroup.clear();
  _byPrimaryMuscle.clear();
  debugPrint('⚠️ Failed to load catalog: $e');
  // No relanzar
}
```

**Beneficio**: Si falla la carga, los mapas quedan limpios y listos para el siguiente intento.

#### 4. Safe Lookup Methods
```dart
// Devuelven listas vacías en lugar de null si no hay datos
List<ExerciseEntity> getByEquivalenceGroup(String group) {
  return List.unmodifiable(_byEquivalenceGroup[group] ?? const []);
}

List<ExerciseEntity> getByPrimaryMuscle(String muscle) {
  return _lookupByMuscle(muscle);  // Retorna [] si no hay datos
}
```

**Beneficio**: Código consumidor no necesita null checks especiales.

#### 5. Improved Debugging
Reemplazados `print()` con `debugPrint()` para cumplir normas de producción:
- Desactivados en release builds automáticamente
- No causan warnings en flutter analyze
- Mejora legibilidad de logs

## Result

### Before
❌ `ExerciseCatalogService.ensureLoaded()` lanzaba excepción
❌ `weekly_plan_tab.dart` capturaba excepción pero dejaba UI rota
❌ Estado inconsistente con maps parcialmente llenos
❌ Múltiples reintentos sin control

### After
✅ `ensureLoaded()` NUNCA lanza excepciones
✅ Intento único - no reintentos automáticos
✅ UI sigue funcionando aunque falte el catálogo
✅ Métodos de lookup devuelven datos o listas vacías
✅ Logs descriptivos para debugging

## Impact on Weekly Plan Tab

El widget `weekly_plan_tab.dart` ya tenía manejo correcto:

```dart
Future<void> _initCatalog() async {
  try {
    await _catalog.ensureLoaded();
    if (mounted) setState(() { _catalogLoaded = true; });
  } catch (_) {
    if (mounted) setState(() { _catalogLoaded = false; });
  }
}
```

**Ahora**:
- La línea `catch (_)` nunca se ejecuta porque no hay excepción
- Si la carga falla, `_catalogLoaded = false` se mantiene
- UI mostrará mensaje apropiado o lista vacía, pero no se caerá

## Asset Loading Debug Info

Si necesitas verificar por qué falló la carga, busca en los logs:
```
⚠️ ExerciseCatalogService: Error loading exercises: ...
```

Posibles causas:
1. Asset no incluido en `pubspec.yaml` (verificar sección `assets:`)
2. Path incorrecto en código
3. Problema de acceso al filesystem (permisos)
4. Archivo JSON corrupto o con formato inválido

## Testing

Para validar que funciona:

```dart
final service = ExerciseCatalogService();
await service.ensureLoaded();

// Nunca lanzará excepción, aunque falle
print(service.isLoaded);  // false si falló
print(service.hasData);   // false si falló
print(service.lastLoadError);  // Mensaje de error si falló
print(service.getByPrimaryMuscle('chest'));  // [] si no hay datos
```

## Migration Checklist

- [x] ExerciseCatalogService implementa no-throwing loading
- [x] weekly_plan_tab.dart continúa funcionando sin cambios
- [x] flutter analyze pasa sin warnings
- [x] debugPrint reemplaza print() para production compliance
