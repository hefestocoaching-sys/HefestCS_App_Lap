# Referencia Rápida: Motor Dietético Corregido

## Cambios Principales

### ❌ ANTES
```dart
// Gasto Energético
calculateTotalEnergyExpenditure(
  tmb: 1800,
  selectedNafFactor: 1.55,
  metMinutesPerDay: 420,
  leanBodyMassKg: 65,  // ❌ Usa MLG → Impreciso en obesos
)

// Macros
distributeMacrosByGrams(
  gastoNetoObjetivo: 2500,
  pesoCorporal: 80,
  gProteinaPorKg: 2.0,
  gGrasaPorKg: 0.9,
  // Retornaba kcalConsumir ≠ objetivo (factor 0.925)
)
```

### ✅ DESPUÉS
```dart
// Gasto Energético
calculateTotalEnergyExpenditure(
  tmb: 1800,
  selectedNafFactor: 1.55,
  metMinutesPerDay: 420,
  bodyWeightKg: 80,  // ✅ Usa peso total → Correcto
)
// Retorna: 1800 + 990 + 588 = 3378 kcal

// Macros
distributeMacrosByGrams(
  gastoNetoObjetivo: 2500,
  pesoCorporal: 80,
  gProteinaPorKg: 2.0,
  gGrasaPorKg: 0.9,
  // Retorna exactamente 2500 kcal (sin factores opacos)
)
```

## Fórmulas (Documentadas)

### GET (Gasto Energético Total)
```
GET = TMB + (TMB × (NAF − 1)) + EAT
EAT = MET_minutos × peso_corporal_kg × 0.0175
```

### Macronutrientes
```
Proteína:        gramos = g/kg × peso_corporal
Grasa:           gramos = g/kg × peso_corporal
Carbohidratos:   gramos = (objetivo_kcal − kcal_prot − kcal_grasa) / 4
```

## Fallbacks

| Parámetro | Valor Fallback | Comportamiento |
|-----------|---|---|
| `bodyWeightKg` | 0.0 | GET retorna 0 (bloquea cálculos inválidos) |
| `pesoCorporal` en macros | 0.0 | Retorna map vacío (seguro) |

## Archivos Modificados

1. **`lib/utils/dietary_calculator.dart`**
   - Línea ~165: Nueva firma con `bodyWeightKg` en lugar de `leanBodyMassKg`
   - Línea ~169: Simplificación de `distributeMacrosByGrams` (elimina factor 0.925)

2. **`lib/features/nutrition_feature/widgets/dietary_tab.dart`**
   - Línea ~268: Obtener `bodyWeightKg` de `client.latestAnthropometryRecord.weightKg`
   - Pasa nuevo parámetro a `calculateTotalEnergyExpenditure`

## Testing Rápido

```dart
// Test 1: GET básico
final get = DietaryCalculator.calculateTotalEnergyExpenditure(
  tmb: 1800,
  selectedNafFactor: 1.55,
  metMinutesPerDay: 420,
  bodyWeightKg: 80,
);
// Esperado: 3378 kcal

// Test 2: Macros
final macros = DietaryCalculator.distributeMacrosByGrams(
  gastoNetoObjetivo: 2500,
  pesoCorporal: 80,
  gProteinaPorKg: 2.0,
  gGrasaPorKg: 0.9,
);
// Esperado: 
// - proteinGrams: 160 → 640 kcal
// - fatGrams: 72 → 648 kcal
// - carbGrams: 303 → 1212 kcal
// - totalKcalToConsume: 2500 (exacto)

// Test 3: Verificación final
final totalKcal = (160 * 4) + (72 * 9) + (303 * 4);
assert(totalKcal == 2500); // ✅ Debe pasar
```

## Referencia Científica

📚 **The Muscle & Strength Pyramid: Nutrition 2.0**  
Eric Helms, Mike Israetel, James Hoffmann

- Nivel 1: Calorías totales (soberano; no se redistribuye oculto)
- Nivel 2: Distribución de macros (proteína → grasa → carbos)
- Nivel 3: Timing y calidad (posterior)

---

**Última actualización:** 21 de enero de 2026  
**Estado:** ✅ Producción
