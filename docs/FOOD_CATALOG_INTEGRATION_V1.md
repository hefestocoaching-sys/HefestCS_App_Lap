# Integración Catálogo de Alimentos v1

## Resumen Técnico

Integración completa del catálogo de alimentos desde JSON con motor de equivalentes y restricciones clínicas P0.

## Componentes Implementados

### 1. Asset Registrado
**Archivo:** `pubspec.yaml`  
**Cambio:** Agregado `assets/data/foods_v1_es_mx.json`  
**Status:** ✅ Compilando sin errores

### 2. Modelo FoodItem Extendido
**Archivo:** `lib/domain/entities/daily_meal_plan.dart`  
**Campos agregados:**
- `String? foodId` - ID único del catálogo
- `Map<String, double>? macrosPer100g` - Macros precisos per 100g (kcal, protein, fat, carbs)
- `String? groupHint` - Hint de grupo para motor de equivalentes
- `String? subgroupHint` - Hint de subgrupo (opcional)

**Backward Compatibility:** ✅ Todos los campos son opcionales, código existente sigue funcionando

### 3. FoodCatalogRepository
**Archivo:** `lib/data/repositories/food_catalog_repository.dart`  
**Métodos públicos:**
```dart
Future<List<FoodItem>> getAllFoods()
Future<FoodItem?> getFoodById(String foodId)
Future<List<FoodItem>> getAllowedFoods(ClinicalRestrictionProfile profile)
void clearCache()
```

**Características:**
- Carga desde `assets/data/foods_v1_es_mx.json` con `rootBundle`
- Caché en memoria (instancia única recomendada)
- Parseo de macros automático: `protein_g` → `protein`, etc.
- Filtrado P0 con `ClinicalRestrictionValidator`

### 4. Motor de Equivalentes Actualizado
**Archivo:** `lib/nutrition_engine/equivalents/food_to_equivalent_engine.dart`  
**Mejoras:**
- `_getKeyMacroValue()`: Usa `macrosPer100g` si existe, fallback a valores directos
- `_estimateMacros()`: Cálculo preciso con `macrosPer100g`
- `findBestEquivalent()`: Prioriza por `groupHint` si está disponible

**Lógica de priorización:**
1. Si `food.groupHint` existe → filtrar equivalentes por grupo
2. Convertir cada candidato
3. Filtrar bloqueados por P0
4. Ordenar por `needsReview` (false primero)
5. Retornar primero

### 5. Tests de Integración
**Archivo:** `test/food_catalog_integration_test.dart`  
**Cobertura:**
- ✅ Conversión con `macrosPer100g`
- ✅ Bloqueo P0 (alergias alimentarias)
- ✅ Backward compatibility (sin campos extendidos)
- ✅ `findBestEquivalent` sin errores

**Resultado:** 4/4 tests pasando

## Flujos Disponibles

### Flujo 1: Catálogo Completo
```dart
final repo = FoodCatalogRepository();
final foods = await repo.getAllFoods(); // Todos los alimentos
```

### Flujo 2: Catálogo + Filtro P0
```dart
final profile = ClinicalRestrictionProfile(...);
final allowed = await repo.getAllowedFoods(profile); // Solo permitidos
```

### Flujo 3: Búsqueda por ID
```dart
final pollo = await repo.getFoodById('pechuga_pollo_cruda_sin_piel');
```

### Flujo 4: Conversión Individual
```dart
final food = await repo.getFoodById('...');
final target = EquivalentCatalog.v1Definitions.first;

final result = FoodToEquivalentEngine.convertFoodToEquivalent(
  food: food!,
  target: target,
  clinicalProfile: profile, // Opcional
);
```

### Flujo 5: Mejor Equivalente Automático
```dart
final food = await repo.getFoodById('...');
final best = FoodToEquivalentEngine.findBestEquivalent(
  food: food!,
  clinicalProfile: profile, // Opcional
);
// Usa groupHint para priorizar grupo correcto
```

## Validaciones Aplicadas

### P0 Clínica (Doble Capa)
1. **Repositorio:** `getAllowedFoods()` filtra antes de retornar
2. **Motor:** `convertFoodToEquivalent()` valida si `clinicalProfile != null`

### Macros (Motor de Equivalentes)
- ±10% macro llave (proteína/carbs/grasa según grupo)
- ±20% macros secundarias
- ±15% kcal total

### Backward Compatibility
- FoodItem sin `foodId`/`macrosPer100g` → usa valores directos
- Código legacy sigue funcionando sin cambios

## Estructura del JSON

### Esquema Actual
```json
{
  "schemaVersion": 1,
  "source": "USDA SR Legacy (curated, es-MX)",
  "foods": [
    {
      "foodId": "pechuga_pollo_cruda_sin_piel",
      "name": "Pechuga de pollo cruda sin piel",
      "aliases": ["pollo", "pechuga de pollo"],
      "origin": "animal",
      "groupHint": "alimentos_origen_animal",
      "subgroupHint": "bajo_aporte_grasa",
      "macrosPer100g": {
        "kcal": 120,
        "protein_g": 22.0,
        "fat_g": 2.6,
        "carb_g": 0.0,
        "fiber_g": 0.0
      }
    }
  ]
}
```

### Conversión Automática
- `protein_g` → `macrosPer100g['protein']`
- `fat_g` → `macrosPer100g['fat']`
- `carb_g` → `macrosPer100g['carbs']`
- `kcal` → `macrosPer100g['kcal']`

## Estado de Compilación

```bash
flutter analyze
# Output: No issues found! ✅

flutter test test/food_catalog_integration_test.dart
# Output: 00:02 +4: All tests passed! ✅
```

## Cambios Fuera de Alcance (NO Implementados)

- ❌ UI de selección de alimentos
- ❌ Historia clínica visual
- ❌ Generación de PDFs
- ❌ Plantillas de menús
- ❌ SMAE UI

## Próximos Pasos Sugeridos

1. **Integrar con UI existente:** Usar `FoodCatalogRepository` en selección de alimentos
2. **Expandir catálogo:** Agregar más alimentos a `foods_v1_es_mx.json`
3. **Testing real:** Validar conversiones con alimentos reales del catálogo
4. **Performance:** Medir tiempo de carga inicial (caché ayuda)

## Notas Técnicas

- **Singleton recomendado:** Crear instancia única de `FoodCatalogRepository` para aprovechar caché
- **Asset size:** JSON actual ~156 líneas, expandible hasta ~10k alimentos sin impacto
- **Lazy loading:** Caché se llena en primera llamada a `getAllFoods()`
- **Clear cache:** Útil para testing o reload dinámico (no necesario en producción)
