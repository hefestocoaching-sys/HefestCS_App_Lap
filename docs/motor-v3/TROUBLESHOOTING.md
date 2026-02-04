# Motor V3 - Troubleshooting Guide

## 🚨 Problemas Comunes

### 1. Plan Bloqueado por Fatiga Alta

**Síntoma**:
```dart
result.isBlocked == true
result.blockReason == "Fatiga acumulada muy alta"
```

**Causas**:
- Sueño insuficiente (<5 horas)
- Estrés muy alto (>8/10)
- Energía muy baja (<4/10)

**Soluciones**:
1. **Inmediato**: Programar deload de 1 semana
2. **Corto plazo**: Mejorar higiene del sueño (7-9h)
3. **Largo plazo**: Reducir fuentes de estrés

**Código de ejemplo**:
```dart
// Verificar factores de fatiga
final client = ...;
final profile = ClientProfile.fromClient(client);

print('Sleep: ${profile.sleepQuality}/10');
print('Stress: ${profile.stressLevel}/10');
print('Energy: ${profile.energyLevel}/10');
print('Needs deload: ${profile.needsDeload}');
```

---

### 2. Plan Bloqueado por Datos Faltantes

**Síntoma**:
```dart
result.isBlocked == true
result.blockReason == "Edad no disponible"
result.suggestions == ["Completa la edad en Personal Data"]
```

**Causas**:
- Client.training.age == null
- Client.profile.age == null
- Client.training.gender == null

**Soluciones**:
```dart
// Verificar datos mínimos
if (client.training.age == null && client.profile.age == null) {
  print('❌ Falta edad');
}

if (client.training.gender == null && client.profile.gender == null) {
  print('❌ Falta género');
}

// Actualizar cliente
final updatedClient = client.copyWith(
  training: client.training.copyWith(
    age: 30,
    gender: 'male',
  ),
);
```

---

### 3. Volumen Generado Muy Bajo

**Síntoma**:
- Plan se genera correctamente
- Pero volumen semanal <10 sets por músculo

**Causas**:
- Factores de ajuste muy bajos (edad >60, déficit >-600 kcal, fatiga alta)
- Nivel de experiencia "ultra beginner"
- Override manual del coach muy conservador

**Diagnóstico**:
```dart
final trace = result.trace!;

trace.volumeDecisions.forEach((muscle, decision) {
  final mev = decision['mev'];
  final mav = decision['mav'];
  final mrv = decision['mrv'];
  final target = decision['target'];
  final factors = decision['adjustmentFactors'];
  
  print('$muscle:');
  print('  MEV: $mev, MAV: $mav, MRV: $mrv');
  print('  Target: $target');
  print('  Factores: $factors');
});
```

**Soluciones**:
1. Verificar factores de ajuste individuales
2. Ajustar recuperación si está subestimada
3. Considerar override manual si factores automáticos son demasiado conservadores

---

### 4. Error "UserProfile constructor failed"

**Síntoma**:
```
Error: The argument type 'Map<String, dynamic>' can't be assigned to the parameter type 'List<String>'
```

**Causas**:
- Formato incorrecto en Client.training.extra
- Campos esperados como List pero provistos como String

**Soluciones**:
```dart
// ❌ INCORRECTO
final extra = {
  'priorityMusclesPrimary': 'pectorals,back,legs', // String
};

// ✅ CORRECTO (opción 1: lista)
final extra = {
  'priorityMusclesPrimary': ['pectorals', 'back', 'legs'],
};

// ✅ CORRECTO (opción 2: string CSV, parseado en código)
final extra = {
  'priorityMusclesPrimary': 'pectorals,back,legs',
};
// El código parsea automáticamente por comas
```

---

### 5. Plan Generado Está Vacío (0 Semanas)

**Síntoma**:
```dart
result.isBlocked == false
result.plan != null
result.plan!.weeks.length == 0
```

**Causas**:
- TrainingProgram → TrainingPlanConfig conversion incompleta
- TODO pendiente en `_createBasicPlanConfig()`

**Estado Actual**:
Este es un **placeholder temporal**. La conversión completa TrainingProgram → TrainingPlanConfig está en desarrollo.

**Workaround temporal**:
```dart
// El plan se genera correctamente en el backend (HybridOrchestratorV3)
// pero la conversión a TrainingPlanConfig aún no está completa

// Acceder directamente al resultado interno si necesitas debuggear:
final metadata = result.metadata;
print('ML applied: ${metadata?['ml_applied']}');
print('Strategy: ${metadata?['strategy']}');
```

---

## 🔍 Debugging Avanzado

### Habilitar Trace de Decisiones

```dart
final result = await orchestrator.generatePlan(
  client: client,
  exercises: exercises,
  asOfDate: DateTime.now(),
);

if (result.trace != null) {
  final trace = result.trace!;
  
  // Ver decisiones de volumen
  print('VOLUMEN:');
  print(trace.volumeDecisions);
  
  // Ver decisiones de intensidad
  print('INTENSIDAD:');
  print(trace.intensityDecisions);
  
  // Ver ejercicios seleccionados
  print('EJERCICIOS:');
  print(trace.exerciseSelections);
  
  // Ver rationale de decisiones
  print('SPLIT: ${trace.splitRationale}');
  print('FASE: ${trace.phaseRationale}');
}
```

### Logs del Motor

El Motor V3 imprime logs detallados en consola:

```
🚀 [Motor V3] Generando plan con pipeline científico...
🔬 [Fase 1] Generando programa científico...
✅ Programa científico generado: prog_123
   Volumen total: 84.0 sets
📊 [Fase 2] Obteniendo logs históricos...
   Logs encontrados: 12
🤖 [Fase 3] Aplicando refinamientos ML...
✅ ML aplicado: 0.0% volumen
   Readiness: good
```

Para desactivar logs:
```dart
// Modificar HybridOrchestratorV3 temporalmente
// (o esperar a que se implemente flag de logging)
```

---

## 📞 Soporte

**Documentación adicional**:
- README: `/docs/motor-v3/README.md`
- Arquitectura: `/docs/motor-v3/architecture.md`
- API Reference: `/docs/motor-v3/api-reference.md`

**Issues conocidos**:
- [ ] TrainingProgram → TrainingPlanConfig conversion incompleta
- [ ] ML strategy no implementada (placeholder)
- [ ] Validación de ejercicios por equipo disponible pendiente

**Reportar problemas**:
- GitHub Issues: [Crear issue](https://github.com/hefestocoaching-sys/HefestCS_App_Lap/issues)
- Email: support@hefestcs.com
