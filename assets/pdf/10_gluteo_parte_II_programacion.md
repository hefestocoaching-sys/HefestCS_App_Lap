# Glúteo – Parte II  
## Programación específica del glúteo dentro del motor de hipertrofia (documento normativo)

> **Propósito**: Este documento define **cómo se programa** el glúteo dentro del motor: volumen, frecuencia, selección de ejercicios dominantes de cadera, distribución semanal y control de interferencias.  
> **Regla central**: El glúteo requiere **intención programática explícita**; entrenarlo “de rebote” produce estímulos inconsistentes y errores de volumen.

---

## 0) Dependencias y alcance

Depende explícitamente de:
- Docs 01–08 (Hipertrofia completa).
- Doc 09: Glúteo – Parte I (anatomía funcional y rol).

Asume como no negociable:
- Glúteo = entidad muscular independiente.
- Volumen = series efectivas/semana.
- MRV dinámico afectado por selección, intensidad y esfuerzo.
- Distribución por sesión viable (Doc 02).

Este documento **no** cubre aún:
- especialización avanzada y fases dedicadas (Parte III).

---

## 1) Problema que resuelve la programación específica del glúteo

Sin programación explícita:
- el volumen real de glúteo es impredecible,
- la fatiga proviene de cuádriceps/lumbar, no del glúteo,
- se sobreestima el estímulo efectivo,
- se subestima el costo sistémico.

**Decisión estructural**:
> El glúteo siempre tiene volumen propio asignado o no se considera trabajado.

---

## 2) Volumen efectivo del glúteo

### 2.1 Características generales
El glúteo suele mostrar:
- buena tolerancia a volumen moderado–alto,
- buena recuperación local,
- alta respuesta a rangos largos de movimiento.

Sin embargo:
- su volumen efectivo **no es infinito**,
- el costo sistémico puede elevarse rápidamente con bisagras pesadas.

### 2.2 Aplicación de MV / MEV / MAV / MRV
- **MV**: suficiente para mantener tamaño cuando no es prioridad.
- **MEV**: volumen explícito mínimo para inducir crecimiento.
- **MAV**: rango donde el glúteo progresa eficientemente.
- **MRV**: límite donde la fatiga (local y sistémica) supera recuperación.

**Regla**:
> El glúteo puede tolerar más volumen local que otros músculos, pero su MRV cae si se combinan bisagras pesadas y alta intensidad.

---

## 3) Frecuencia óptima de estímulo

### 3.1 Interpretación aplicada
El material y la práctica indican que el glúteo responde bien a:
- **2–3 estímulos semanales** bien distribuidos,
- evitando concentrar todo el volumen en una sola sesión.

### 3.2 Relación con volumen
- A mayor volumen semanal, mayor necesidad de distribución.
- Frecuencia mayor permite mantener calidad de series.

**Regla del motor**:
> La frecuencia se ajusta para **distribuir volumen**, no para inflarlo.

---

## 4) Selección de ejercicios dominantes de glúteo

### 4.1 Ejercicios primarios (extensión de cadera dominante)
- Hip thrust / glute bridge
- Variantes de bisagra con énfasis en cadera
- Sentadilla profunda con énfasis posterior (si la técnica lo permite)

Estos ejercicios:
- asignan volumen primario al glúteo,
- deben evaluarse por su costo sistémico.

### 4.2 Ejercicios secundarios
- Lunges
- Step-ups
- Variantes unilaterales

Útiles para:
- completar volumen,
- reducir carga axial,
- introducir variación con menor costo.

---

## 5) Rango de movimiento y énfasis mecánico

El glúteo responde especialmente bien a:
- rangos largos de movimiento,
- alta tensión en posición elongada,
- control excéntrico.

**Implicación**:
> Ejercicios que acortan el rango reducen estímulo efectivo por serie.

---

## 6) Interferencia con otros músculos

### 6.1 Con cuádriceps
- Compartición de patrones en sentadilla.
- Volumen y orden deben evitar que el cuádriceps limite el estímulo del glúteo.

### 6.2 Con isquiosurales
- Alta interferencia en bisagras.
- Programar ambos con alto volumen eleva rápidamente la fatiga.

### 6.3 Con zona lumbar
- El glúteo fatigado compromete estabilidad.
- El motor debe proteger la técnica y la columna.

---

## 7) Distribución semanal aplicada al glúteo

Ejemplo conceptual:
- Sesión A: ejercicio primario de glúteo (volumen base).
- Sesión B: ejercicio secundario/unilateral (volumen complementario).
- Sesión C (opcional): estímulo ligero/técnico.

**Regla**:
> Si el glúteo es prioridad, va **al inicio** de la sesión.

---

## 8) Reglas duras del motor (glúteo – programación)

1. El glúteo siempre tiene volumen explícito.
2. No se infiere volumen desde pierna.
3. Bisagras pesadas reducen MRV del glúteo.
4. El orden protege al glúteo de ser “secundario”.
5. La distribución debe respetar límites por sesión.

---

## 9) Reglas blandas del motor

1. Sujetos entrenados toleran mayor frecuencia.
2. Mujeres suelen tolerar mejor volumen distribuido.
3. Unilaterales pueden reducir costo sistémico.
4. Preferencias se permiten si no rompen reglas duras.

---

## 10) Funcionamiento del motor (glúteo – programación)

### Entradas
- Volumen objetivo de glúteo.
- Frecuencia disponible.
- Selección de ejercicios.
- Prioridad del ciclo.

### Estado
- volumen_gluteo_semana
- volumen_gluteo_por_sesion
- fatiga_gluteo
- interferencia_bisagra

### Decisiones
- Ajustar volumen y frecuencia.
- Elegir ejercicios primarios/secundarios.
- Redistribuir sesiones si hay saturación.

### Salidas
- Plan semanal explícito de glúteo.
- Alertas de interferencia y sobrecarga.

---

## 11) Resumen operativo

- El glúteo se programa de forma explícita.
- Volumen y frecuencia se distribuyen.
- La selección prioriza extensión real de cadera.
- La interferencia limita el MRV.
- El motor protege técnica y recuperación.

---

## 12) Checklist de implementación

- [ ] Glúteo con volumen semanal explícito.
- [ ] Frecuencia ajustada al volumen.
- [ ] Ejercicios dominantes de cadera validados.
- [ ] Orden prioriza glúteo cuando aplica.
- [ ] Interferencia controlada por el motor.

