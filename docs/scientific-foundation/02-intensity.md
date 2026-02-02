# Semana 3: Intensidad de Entrenamiento

## Resumen Ejecutivo

La intensidad de entrenamiento (carga relativa al 1RM) determina el tipo de adaptación neural y mecánica. Este documento detalla las **zonas de intensidad científicas** basadas en 12 imágenes de evidencia del Lic. Jay Ehrenstein (APEKS/Icoan/NFA).

**Puntos Clave:**
- **Heavy**: 1-6 reps (85-100% 1RM) - Fuerza y tensión mecánica
- **Moderate**: 6-15 reps (70-85% 1RM) - Hipertrofia óptima
- **Light**: 16-30+ reps (60-70% 1RM) - Estrés metabólico y resistencia
- **Distribución óptima**: 30-40% heavy, 40-50% moderate, 10-20% light

---

## 1. Fundamentos de Intensidad (Imágenes 1-4)

### 1.1 Definición y Métricas

**Intensidad Relativa**:
- Porcentaje del 1RM (one-repetition maximum)
- Ejemplo: Si 1RM = 100kg, 80kg = 80% 1RM

**Relación Intensidad-Repeticiones**:
```
100% 1RM → 1 rep
95% 1RM → 2-3 reps
90% 1RM → 4-5 reps
85% 1RM → 6-7 reps
80% 1RM → 8-10 reps
75% 1RM → 10-12 reps
70% 1RM → 12-15 reps
65% 1RM → 15-20 reps
60% 1RM → 20-30 reps
```

**Evidencia Científica**:
- Brzycki (1993): Fórmulas de predicción 1RM
- Schoenfeld et al. (2021): Continuum intensidad-hipertrofia

### 1.2 Zonas de Intensidad

#### Zona Heavy (85-100% 1RM)
- **Rango de reps**: 1-6
- **Mecanismo primario**: Tensión mecánica máxima
- **Adaptaciones**:
  - Fuerza máxima ↑↑↑
  - Hipertrofia miofibrilar ↑↑
  - Reclutamiento fibras tipo IIx ↑↑↑
  - Estrés neural alto

**Aplicaciones**:
- Ejercicios compuestos principales
- Periodos de fuerza
- Atletas avanzados

#### Zona Moderate (70-85% 1RM)
- **Rango de reps**: 6-15
- **Mecanismo primario**: Tensión mecánica + estrés metabólico
- **Adaptaciones**:
  - Hipertrofia sarcoplasmática ↑↑↑
  - Hipertrofia miofibrilar ↑↑
  - Fuerza ↑↑
  - Eficiencia técnica ↑↑

**Aplicaciones**:
- Base de hipertrofia
- Mayoría de ejercicios
- Todos los niveles

#### Zona Light (60-70% 1RM)
- **Rango de reps**: 16-30+
- **Mecanismo primario**: Estrés metabólico
- **Adaptaciones**:
  - Hipertrofia sarcoplasmática ↑↑
  - Resistencia muscular ↑↑↑
  - Capilarización ↑↑
  - Daño muscular mínimo

**Aplicaciones**:
- Músculos pequeños (bíceps, gemelos)
- Finishers metabólicos
- Fases de deload
- Principiantes

---

## 2. Distribución de Intensidad (Imágenes 5-8)

### 2.1 Modelo de Distribución Óptima

**Para Hipertrofia General**:
```
Heavy (1-6 reps):    30-40% del volumen total
Moderate (6-15 reps): 40-50% del volumen total
Light (16-30 reps):   10-20% del volumen total
```

**Ejemplo con 20 sets semanales de pectorales**:
```
Heavy:    6-8 sets  (Press Banca 5 reps, Press Inclinado 6 reps)
Moderate: 8-10 sets (Press Máquina 10 reps, Press Mancuernas 12 reps)
Light:    2-4 sets  (Cruces Cable 20 reps, Peck Deck 15 reps)
```

### 2.2 Variación por Objetivo

#### Fuerza Máxima
```
Heavy:    60-70% del volumen
Moderate: 25-35% del volumen
Light:    5-10% del volumen
```

#### Hipertrofia (Balance)
```
Heavy:    30-40% del volumen
Moderate: 40-50% del volumen
Light:    10-20% del volumen
```

#### Resistencia Muscular
```
Heavy:    10-20% del volumen
Moderate: 30-40% del volumen
Light:    40-50% del volumen
```

### 2.3 Variación por Grupo Muscular (Imágenes 9-10)

**Músculos que Responden Bien a Heavy**:
- Cuádriceps (sentadillas pesadas)
- Glúteos (hip thrust pesado)
- Pectorales (press pesado)
- Dorsales (dominadas lastradas)

**Músculos que Prefieren Moderate-Light**:
- Gemelos (alta resistencia)
- Antebrazos
- Bíceps (pump metabólico)
- Deltoides lateral (bombeo)

---

## 3. Consideraciones Técnicas (Imágenes 11-12)

### 3.1 Fatiga Neural vs. Metabólica

**Heavy (Alta Fatiga Neural)**:
- Requiere descansos largos (3-5 min)
- Frecuencia moderada (2x/semana)
- Volumen limitado por SNC
- Priorizar técnica impecable

**Light (Alta Fatiga Metabólica)**:
- Descansos cortos (60-90 seg)
- Frecuencia alta posible (3-4x/semana)
- Volumen limitado por dolor metabólico
- Técnica puede degradarse al final

### 3.2 Periodización de Intensidad

#### Modelo Ondulado Diario (DUP)
```
Lunes:    Heavy (5 reps)
Miércoles: Moderate (10 reps)
Viernes:  Light (20 reps)
```

#### Modelo de Bloques
```
Semanas 1-3:  Predominio Moderate (base hipertrófica)
Semanas 4-6:  Introducción Heavy (tensión mecánica)
Semanas 7-8:  Predominio Heavy (pico de fuerza)
Semana 9:     Deload Light
```

---

## 4. Implicaciones Prácticas

### 4.1 Para el Motor V3

**Intensity Engine debe**:
1. Distribuir volumen según ratios 30-40-50-10-20
2. Asignar intensidades según tipo de ejercicio
3. Periodizar intensidad dentro del microciclo
4. Ajustar según fatiga acumulada

**Algoritmo de Asignación**:
```dart
enum IntensityZone { heavy, moderate, light }

class IntensityEngine {
  Map<IntensityZone, List<ExercisePrescription>> distributeIntensity({
    required List<Exercise> exercises,
    required int totalSets,
    required Goal goal,
  }) {
    // Calcular ratios según objetivo
    final ratios = _getIntensityRatios(goal);
    
    // Asignar por ejercicio
    final Map<IntensityZone, List<ExercisePrescription>> distribution = {};
    
    for (var exercise in exercises) {
      final zone = _determineOptimalZone(exercise);
      final sets = _calculateSets(exercise, totalSets, ratios[zone]);
      final reps = _getRepsForZone(zone);
      
      distribution[zone] ??= [];
      distribution[zone]!.add(
        ExercisePrescription(
          exercise: exercise,
          sets: sets,
          reps: reps,
          rir: _getRIRForZone(zone),
        ),
      );
    }
    
    return distribution;
  }
  
  Map<IntensityZone, double> _getIntensityRatios(Goal goal) {
    return switch (goal) {
      Goal.hypertrophy => {
        IntensityZone.heavy: 0.35,
        IntensityZone.moderate: 0.50,
        IntensityZone.light: 0.15,
      },
      Goal.strength => {
        IntensityZone.heavy: 0.65,
        IntensityZone.moderate: 0.30,
        IntensityZone.light: 0.05,
      },
      Goal.endurance => {
        IntensityZone.heavy: 0.15,
        IntensityZone.moderate: 0.40,
        IntensityZone.light: 0.45,
      },
    };
  }
  
  IntensityZone _determineOptimalZone(Exercise exercise) {
    // Compuestos pesados → Heavy
    if (exercise.category == 'compound' && 
        exercise.movementPattern.contains(['squat', 'deadlift', 'press'])) {
      return IntensityZone.heavy;
    }
    
    // Aislados pequeños → Light
    if (exercise.primaryMuscles.any(['biceps', 'calves', 'forearms'])) {
      return IntensityZone.light;
    }
    
    // Default → Moderate
    return IntensityZone.moderate;
  }
}
```

### 4.2 Para Ordering Engine

**Prioridad de Orden**:
1. Heavy primero (cuando SNC fresco)
2. Moderate en medio
3. Light al final (finishers)

**Ejemplo Sesión de Pecho**:
```
1. Press Banca 5x5 @ RIR 2-3 (Heavy)
2. Press Inclinado Mancuernas 3x10 @ RIR 1-2 (Moderate)
3. Press Máquina 3x12 @ RIR 1 (Moderate)
4. Cruces Cable 2x20 @ RIR 0 (Light, finisher)
```

### 4.3 Para Progression Engine

**Progresión por Zona**:

**Heavy**: 
- Priorizar aumento de carga (2.5-5kg)
- Mantener reps estables (5-6)
- Progresión lenta pero consistente

**Moderate**:
- Combinar carga + reps
- Cuando alcanza 15 reps → subir peso, volver a 8 reps
- Progresión flexible

**Light**:
- Priorizar aumento de reps (20 → 25 → 30)
- Reducir descansos
- Carga secundaria

---

## 5. Ejemplos de Aplicación

### Ejemplo 1: Sesión de Espalda (Hipertrofia)
```
Heavy (35%):
- Dominadas Lastradas: 4 sets x 5 reps @ 85% 1RM
- Remo con Barra: 3 sets x 6 reps @ 82% 1RM

Moderate (50%):
- Pull-down: 3 sets x 10 reps @ 75% 1RM
- Remo Mancuerna: 3 sets x 12 reps @ 72% 1RM
- Remo Cable: 3 sets x 10 reps @ 75% 1RM

Light (15%):
- Pullover: 2 sets x 20 reps @ 65% 1RM
- Face Pulls: 2 sets x 25 reps @ 60% 1RM

Total: 20 sets
```

### Ejemplo 2: Sesión de Piernas (Fuerza + Hipertrofia)
```
Heavy (50%):
- Sentadilla: 5 sets x 5 reps @ 85% 1RM
- Peso Muerto: 4 sets x 4 reps @ 88% 1RM

Moderate (40%):
- Prensa: 3 sets x 10 reps @ 75% 1RM
- Zancadas: 3 sets x 12 reps @ 70% 1RM

Light (10%):
- Extensiones: 2 sets x 20 reps @ 65% 1RM

Total: 17 sets
```

---

## 6. Referencias Científicas

1. **Schoenfeld, B. J., et al. (2021)**. "Loading Recommendations for Muscle Strength, Hypertrophy, and Local Endurance: A Re-Examination of the Repetition Continuum." *Sports*, 9(2), 32.

2. **Brzycki, M. (1993)**. "Strength testing—predicting a one-rep max from reps-to-fatigue." *Journal of Physical Education, Recreation & Dance*, 64(1), 88-90.

3. **Schoenfeld, B. J., et al. (2017)**. "Strength and hypertrophy adaptations between low- vs. high-load resistance training: A systematic review and meta-analysis." *Journal of Strength and Conditioning Research*, 31(12), 3508-3523.

4. **Lasevicius, T., et al. (2018)**. "Effects of different intensities of resistance training with equated volume load on muscle strength and hypertrophy." *European Journal of Sport Science*, 18(6), 772-780.

---

## 7. Términos Clave

- **1RM**: One-repetition maximum (máxima carga para 1 repetición)
- **Tensión mecánica**: Fuerza generada por el músculo bajo carga
- **Estrés metabólico**: Acumulación de metabolitos (lactato, H+)
- **DUP**: Daily Undulating Periodization (periodización ondulada diaria)
- **Hipertrofia miofibrilar**: Aumento de proteínas contractiles
- **Hipertrofia sarcoplasmática**: Aumento de fluidos y energéticos

---

**Fuente**: Lic. Jay Ehrenstein - APEKS Performance Institute / Icoan Nutrición / NFA  
**Material**: Semana 3 (12 imágenes procesadas)  
**Última actualización**: Febrero 2026
