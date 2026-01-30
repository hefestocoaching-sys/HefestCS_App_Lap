# Progresión y variación del entrenamiento  
## Dinámica adaptativa del estímulo (documento normativo del motor)

> **Propósito**: Este documento define **cómo progresa** el estímulo de entrenamiento a lo largo del tiempo y **cuándo/por qué** se introduce variación.  
> **Regla central**: La progresión es **condicionada** (por respuesta y recuperación); la variación es **instrumental** (para sostener la progresión), nunca un fin.

---

## 0) Dependencias y alcance

Depende explícitamente de:
- Doc 01: Sistema teórico del volumen (MV/MEV/MAV/MRV).
- Doc 02: Distribución y frecuencia.
- Doc 03: Intensidad (modulador del MRV).
- Doc 04: Esfuerzo/RIR/fallo.
- Doc 05: Selección de ejercicios.
- Doc 06: Configuración y splits.

Asume como no negociable:
- El volumen efectivo es la base del progreso.
- La calidad de series y la recuperación gobiernan las decisiones.
- Los umbrales son dinámicos y se recalibran con datos.

Este documento **no** define técnicas avanzadas específicas (doc 08).

---

## 1) Qué significa “progresar” en hipertrofia

Progresar **no** es sinónimo de:
- subir peso cada semana,
- cambiar ejercicios constantemente,
- entrenar más duro sin control.

En el motor, **progresión** significa:
> **Incrementar el estímulo efectivo** de manera sostenible, manteniendo o mejorando la calidad de las series dentro de los límites de recuperación.

---

## 2) Vectores de progresión (orden de prioridad)

El motor reconoce cuatro vectores posibles. **No son equivalentes** y se aplican en orden:

1. **Volumen** (series efectivas/semana)  
2. **Rendimiento a igual carga** (más repeticiones, mejor control)  
3. **Intensidad** (carga)  
4. **Densidad** (mismo volumen en menos tiempo; uso cauteloso)

**Regla dura**:
> En fases de acumulación para hipertrofia, el motor **prioriza volumen** antes que intensidad.

---

## 3) Progresión del volumen (vector primario)

### 3.1 Cuándo progresar volumen
El motor permite aumentar volumen cuando:
- el músculo está entre MEV–MAV,
- el rendimiento es estable o ascendente,
- la fatiga es tolerable,
- la distribución por sesión sigue siendo viable (Doc 02).

### 3.2 Cuánto progresar
Incrementos operativos típicos:
- **+2 a +4 series/semana/músculo**, según tamaño, costo y experiencia.

Incrementos mayores:
- aumentan riesgo de cruzar MRV,
- reducen la calidad de adaptación.

### 3.3 Cuándo NO progresar volumen
- Caída de rendimiento a igualdad de condiciones.
- Señales claras de fatiga acumulada.
- Sesiones saturadas que ya comprometen series finales.

---

## 4) Progresión del rendimiento (vector secundario)

Cuando el volumen está estable:
- aumentar repeticiones a la misma carga,
- mejorar control técnico,
- reducir variabilidad negativa,

constituyen progresión válida.

**Regla**:
> Si el rendimiento mejora sin aumentar volumen, el estímulo **ya está progresando**.

---

## 5) Progresión de la intensidad (vector terciario)

### 5.1 Condiciones para subir intensidad
La intensidad puede progresar cuando:
- el volumen está cercano a MAV pero **no** a MRV,
- el RIR objetivo se mantiene,
- la técnica es consistente,
- el ejercicio lo permite (costo aceptable).

### 5.2 Riesgos
- Subir intensidad demasiado pronto reduce MRV.
- Enmascara problemas de distribución o exceso de volumen.

**Regla dura**:
> No se usa intensidad para “forzar” progreso cuando el volumen es el problema.

---

## 6) Variación: definición y propósito real

### 6.1 Qué es variación
Variación es **cambiar elementos del estímulo** (ejercicio, rango, tempo, orden) **sin cambiar el objetivo**.

### 6.2 Para qué sirve
- Redistribuir estrés.
- Evitar estancamiento por sobreuso.
- Mantener adherencia y calidad técnica.

### 6.3 Para qué NO sirve
- No crea hipertrofia por sí misma.
- No sustituye progresión.
- No corrige mala programación base.

---

## 7) Tipos de variación permitidos

### 7.1 Variación de ejercicios
- Cambios dentro del mismo patrón y músculo primario.
- Manteniendo costo y función similares.

### 7.2 Variación de rangos
- Ajustes de repeticiones para redistribuir fatiga.
- Sin alejarse de rangos funcionales.

### 7.3 Variación de orden
- Priorizar músculos rezagados temporalmente.
- Ajustes logísticos controlados.

**Regla dura**:
> No variar múltiples variables a la vez.

---

## 8) Deloads: reinicio estratégico del sistema

### 8.1 Definición
Un **deload** es una reducción planificada del estímulo para:
- disipar fatiga,
- preservar adaptaciones,
- restaurar capacidad de progreso.

### 8.2 Cuándo deloadear
- Rendimiento cae pese a ajustes conservadores.
- Fatiga acumulada sostenida.
- Cercanía persistente a MRV.

### 8.3 Cómo deloadear
- Reducir volumen (principal).
- Mantener o reducir intensidad.
- Mantener técnica y patrones.

**Regla dura**:
> El deload no es opcional cuando la fatiga lo exige.

---

## 9) Reglas duras del motor (progresión/variación)

1. No progresar si el rendimiento cae.
2. No variar por variar.
3. El volumen se ajusta antes que la intensidad.
4. No cruzar MRV de forma sostenida.
5. El deload se aplica cuando corresponde.

---

## 10) Reglas blandas del motor

1. Atletas avanzados toleran ciclos más largos.
2. La variación puede ser menor en novatos.
3. Preferencias individuales pueden influir si no rompen reglas duras.
4. La progresión puede no ser lineal semana a semana.

---

## 11) Funcionamiento del motor (progresión): lógica interna

### 11.1 Entradas
- Historial de volumen por músculo.
- Tendencias de rendimiento.
- Señales de fatiga.
- Fase del ciclo.

### 11.2 Estado interno
- tendencia_rendimiento[músculo]
- fatiga_acumulada[músculo]
- cercania_MRV[músculo]

### 11.3 Decisiones
El motor decide:
- subir volumen,
- mantener estímulo,
- variar elementos,
- deloadear.

### 11.4 Salidas
- Objetivos semanales ajustados.
- Indicaciones de variación o deload.
- Alertas de estancamiento.

---

## 12) Errores comunes que el motor debe evitar

- Confundir progreso con cambio.
- Forzar incrementos semanales.
- Ignorar señales tempranas de fatiga.
- Usar variación como solución universal.

---

## 13) Resumen operativo

- Progresar es **sostener mejora**, no forzarla.
- El volumen progresa primero.
- La intensidad progresa cuando hay margen.
- La variación apoya, no reemplaza.
- El deload es parte del sistema.

---

## 14) Checklist de implementación

Antes de marcar este módulo completo:
- [ ] El motor detecta tendencias, no solo valores.
- [ ] Existe jerarquía clara de vectores de progresión.
- [ ] La variación está acotada y justificada.
- [ ] El deload se dispara por reglas claras.
- [ ] La UI muestra progreso real, no solo cargas.

