# Selección de ejercicios para la hipertrofia  
## Biomecánica, especificidad y costo de fatiga (documento normativo del motor)

> **Propósito**: Este documento define **cómo y por qué** el motor selecciona ejercicios para hipertrofia, estableciendo criterios biomecánicos, reglas de especificidad muscular, y el **costo de fatiga** asociado a cada patrón.  
> **Regla central**: Un ejercicio solo es válido si **expresa el volumen** en el músculo objetivo con **costo de fatiga compatible** con el contexto del programa.

---

## 0) Dependencias y alcance

Este documento depende explícitamente de:
- Documento 01: Sistema teórico del volumen.
- Documento 02: Distribución, frecuencia y acumulación.
- Documento 03: Intensidad como modulador.
- Documento 04: Esfuerzo y fallo.

Asume como no negociable:
- Volumen = series efectivas/semana/músculo.
- Contabilidad por **entidad muscular** (no inferencias).
- MRV dinámico afectado por intensidad, esfuerzo y ejercicio.

Este documento **no** define:
- organización semanal/splits (doc 06),
- progresión temporal (doc 07),
- técnicas de intensificación (doc 08).

---

## 1) Problema que resuelve la selección de ejercicios

Una mala selección de ejercicios puede:
- “consumir” recuperación sin aportar estímulo específico,
- distorsionar la contabilidad de volumen,
- reducir el número real de series efectivas,
- forzar ajustes innecesarios de volumen/intensidad.

Por tanto, la selección de ejercicios **no es estética ni arbitraria**:
> Es un problema de **eficiencia del estímulo**.

---

## 2) Principio de especificidad muscular

### 2.1 Definición
Cada ejercicio debe tener **un músculo primario explícito** al que se asigna el volumen.

- El músculo primario es aquel que:
  - recibe la mayor tensión mecánica relevante,
  - limita el rendimiento de la serie,
  - justifica la ejecución del ejercicio para hipertrofia.

### 2.2 Prohibición de inferencias
El motor **prohíbe**:
- repartir volumen entre múltiples músculos por “sensación”,
- asumir que un músculo recibe volumen “porque trabaja”.

**Regla dura**:
> Un ejercicio = una entidad muscular primaria para contabilidad de volumen, salvo decisión explícita y auditada.

---

## 3) División muscular oficial (recordatorio operativo)

Entidades musculares utilizadas por el motor (no exhaustivo, pero base):

- Pecho
- Lats (dorsal ancho)
- Espalda media y alta
- Trapecio superior
- Deltoide anterior
- Deltoide lateral
- Deltoide posterior
- Bíceps
- Tríceps
- Glúteo
- Cuádriceps
- Isquiosurales
- Pantorrilla
- Abdomen

**Nota**: Esta división es **obligatoria** para evitar doble conteo y errores de prescripción.

---

## 4) Clasificación de ejercicios por patrón biomecánico

### 4.1 Multiarticulares
Características:
- involucran múltiples articulaciones,
- permiten altas cargas,
- alto estímulo global,
- **alto costo de fatiga**.

Ejemplos:
- sentadillas,
- presses,
- remos,
- dominadas.

Uso principal:
- construir volumen base,
- fases tempranas de acumulación.

Limitación:
- no permiten infinito volumen efectivo.

---

### 4.2 Aislamientos
Características:
- una articulación dominante,
- menor carga absoluta,
- menor costo sistémico,
- alta especificidad.

Ejemplos:
- curls,
- extensiones,
- elevaciones laterales.

Uso principal:
- completar MAV,
- especialización,
- control fino del volumen.

---

## 5) Costo de fatiga: concepto clave

### 5.1 Definición
El **costo de fatiga** es la cantidad de recuperación que un ejercicio “consume” por serie efectiva.

Factores que aumentan el costo:
- alta carga axial,
- alta intensidad,
- proximidad al fallo,
- alta demanda de estabilidad,
- complejidad técnica.

### 5.2 Implicación para el motor
Dos ejercicios que estimulan el mismo músculo **no son equivalentes** si su costo de fatiga difiere.

**Regla causal**:
> A mayor costo del ejercicio, menor volumen tolerable para ese músculo y para el sistema.

---

## 6) Selección de ejercicios y MRV

El MRV no es solo función del músculo:
- también depende de **cómo** se estimula.

Ejemplo interpretativo:
- 10 series de glúteo vía hip thrust ≠ 10 series vía peso muerto pesado.
- Ambos estimulan glúteo, pero el segundo consume más recuperación sistémica.

**Regla del motor**:
> La selección de ejercicios desplaza el MRV tanto como la intensidad o el esfuerzo.

---

## 7) Reglas duras del motor (selección de ejercicios)

Estas reglas no pueden violarse:

1. Todo ejercicio debe tener músculo primario definido.
2. El motor no duplica volumen entre músculos.
3. Ejercicios de alto costo limitan el volumen total permitido.
4. No se seleccionan ejercicios que comprometan técnica de forma crónica.
5. La selección debe ser compatible con el split y la distribución semanal.

---

## 8) Reglas blandas del motor

1. Variar ejercicios puede mejorar adherencia si no aumenta el costo.
2. Aislamientos pueden sustituir multiarticulares para reducir fatiga.
3. Preferencias individuales pueden considerarse si no violan reglas duras.
4. El historial de lesiones puede modificar la selección permitida.

---

## 9) Funcionamiento del motor (selección): lógica interna

### 9.1 Entradas
- Músculo objetivo.
- Volumen semanal objetivo.
- Fase del ciclo.
- Split y frecuencia disponibles.
- Historial de tolerancia y rendimiento.

### 9.2 Estado interno
- costo_ejercicio_estimado[ejercicio]
- volumen_asignado[músculo]
- fatiga_acumulada[músculo]

### 9.3 Decisiones
El motor decide:
- qué ejercicios usar para construir volumen base,
- qué ejercicios usar para completar volumen,
- cuándo sustituir ejercicios por exceso de fatiga.

### 9.4 Salidas
- Lista de ejercicios seleccionados por músculo.
- Alertas si la selección compromete MRV o distribución.

---

## 10) Errores comunes que el motor debe evitar

- Elegir ejercicios por “popularidad”.
- Asumir que más músculos implicados = más hipertrofia.
- Mantener ejercicios de alto costo cuando el volumen ya es alto.
- Cambiar ejercicios sin motivo fisiológico.

---

## 11) Integración con otros módulos

- Con Documento 01: los ejercicios expresan el volumen.
- Con Documento 02: la selección condiciona la distribución.
- Con Documento 03: la intensidad amplifica el costo del ejercicio.
- Con Documento 04: el esfuerzo define la efectividad real de cada serie.
- Con Documento 06: la selección debe encajar en el split.

---

## 12) Resumen operativo

- El ejercicio es un **vehículo** del volumen.
- No todos los ejercicios son equivalentes.
- El músculo primario manda la contabilidad.
- El costo de fatiga define cuánto volumen es viable.
- El motor selecciona por eficiencia, no por variedad.

---

## 13) Checklist de implementación

Antes de marcar este módulo como completo:
- [ ] Cada ejercicio tiene músculo primario definido.
- [ ] Existe estimación de costo por ejercicio.
- [ ] El motor puede sustituir ejercicios por fatiga.
- [ ] La UI muestra músculo objetivo y costo relativo.
- [ ] No hay inferencia automática de volumen entre músculos.

