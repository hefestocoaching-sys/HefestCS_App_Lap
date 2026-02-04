# 🧪 Motor V3 Test Suite

## Estructura

```
test/training_v3/
├── motor_v3_orchestrator_test.dart       # Test canónico del orquestador
├── motor_v3_smoke_test.dart              # Smoke tests básicos
├── engines/
│   ├── volume_engine_test.dart           # Tests del motor volumétrico
│   ├── intensity_engine_test.dart        # Tests del motor de intensidad
│   ├── exercise_selection_engine_test.dart # Tests de selección de ejercicios
│   └── periodization_engine_test.dart    # Tests de periodización
└── fixtures/
    ├── user_profile_fixture.dart         # Perfiles de usuario para tests
    ├── exercise_catalog_fixture.dart     # Catálogo de ejercicios
    └── training_context_v3_fixture.dart  # Contextos de entrenamiento (WIP)
```

## Filosofía de Testing

### ✅ LO QUE HACEMOS

1. **Probar inputs → outputs**: Dado un contexto válido, el Motor V3 genera un plan
2. **Probar determinismo**: Mismo input siempre produce mismo output
3. **Probar coherencia científica**: 
   - Principiantes reciben volumen y RIR conservadores
   - Avanzados reciben volumen e intensidad altos
   - Las fases de periodización respetan fundamentos (acumulación, intensificación, deload)
4. **Probar sin UI**: Los tests son puramente de lógica, sin widgets
5. **Probar contratos**: Cada sesión tiene ejercicios, cada ejercicio tiene sets/reps/RIR/rest

### ❌ LO QUE NO HACEMOS

- ❌ Tests frágiles que esperan valores exactos (usar rangos)
- ❌ Tests que prueban detalles de implementación
- ❌ Tests que asumen constructores específicos
- ❌ Tests de UI o interacción
- ❌ Tests que prueban APIs experimentales

## Principios de Diseño

### 1. Fixtures Robustos

Los fixtures no deben cambiar cuando refactorizamos. Proporcionan:
- Perfiles de usuario realistas (principiante, intermedio, avanzado)
- Catálogos de ejercicios válidos (14+ ejercicios reales)
- Contextos de entrenamiento simples pero completos

### 2. Tests Independientes

Cada test debe ser 100% independiente:
- No hay estado compartido
- No dependen del orden de ejecución
- `setUp()` proporciona estado fresco

### 3. Validaciones Científicas

Los tests validan:
- **MEV/MAV/MRV ranges**: Foundación de Schoenfeld et al. (2017)
- **RIR (Reps in Reserve)**: Conservador para principiantes, bajo para avanzados
- **Progresión volumétrica**: Acumulación → Intensificación → Deload

### 4. Determinismo

El Motor V3 SIEMPRE produce el mismo plan para el mismo input:
```dart
// Mismo input 2 veces = mismo output
final plan1 = orchestrator.generatePlan(...);
final plan2 = orchestrator.generatePlan(...);
expect(plan1.weeks.length, equals(plan2.weeks.length));
```

## Ejecución

### Ejecutar todos los tests Motor V3
```bash
flutter test test/training_v3/
```

### Ejecutar solo el test canónico
```bash
flutter test test/training_v3/motor_v3_orchestrator_test.dart
```

### Ejecutar tests de un engine específico
```bash
flutter test test/training_v3/engines/volume_engine_test.dart
```

### Con cobertura
```bash
flutter test --coverage test/training_v3/
```

## Test Naming Convention

- `test('X produces Y for Z', ...)` - Comportamiento simple
- `test('X respects Y', ...)` - Validación de restricción
- `test('X is always Z', ...)` - Propiedad invariante
- `test('Same input produces identical output', ...)` - Determinismo

## Cuando Agregar Tests

1. **Nuevo engine**: Agregar tests en `engines/`
2. **Nuevo comportamiento**: Agregar test en `motor_v3_orchestrator_test.dart`
3. **Nueva validación científica**: Agregar test en engine respectivo
4. **Bug fix**: Agregar regresión test + fix

## Cuando NO Agregar Tests

- ❌ Detalles de implementación privada
- ❌ Métodos auxiliares internos
- ❌ APIs que van a cambiar en próximas semanas
- ❌ UI o presentación

## Referencias Científicas

Tests validan estos fundamentos:
- **Schoenfeld et al. (2017)**: Dosis-respuesta volumen-hipertrofia
- **Schoenfeld et al. (2019)**: Meta-análisis volumen óptimo
- **Helms et al. (2014)**: Periodización del entrenamiento
- **Prilepin's Chart**: Relación intensidad-reps-recuperación

## Política Futura

✅ Los tests siguen al motor, no al revés
✅ Cambiar contrato del motor = actualizar fixtures (no 300 tests)
✅ No hay tests contra APIs experimentales
✅ Motor V3 es el único core científico

---

**Última actualización**: 04 de febrero de 2026
**Generado por**: Rebase Total a Motor V3
**Estado**: ESTABLE - Todos los tests pasan ✅
