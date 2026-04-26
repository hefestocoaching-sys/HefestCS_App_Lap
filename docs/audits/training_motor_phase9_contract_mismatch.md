# Fase 9 - Contract Mismatch (Validator SSOT)

## Objetivo
Alinear motor V3 al contrato del validator forense, sin debilitar reglas y sin fallback silencioso.

## Divergencias detectadas antes del fix

1. Frecuencia (regla 2.2)
- Validator: frecuencia esperada depende de volumen semanal (6-12 => f1, 13-22 => f2, 23-34 => f3).
- Motor previo: podia escalar frecuencia por factibilidad (base -> base+1...) y ademas forzar f2 en UL de 4 dias.
- Efecto: planes con actual f != expected f, luego bloqueo forense 2.2.

2. Pairing (regla 2.6)
- Validator: bloquea pairing con mismo musculo primario y pairing fuera de contrato.
- Builder previo: asignaba pairGroupId por bloque con 2 ejercicios sin validar pairing final del par.
- Efecto: bloqueos 2.6 en casos con combinaciones no validas.

3. Orden estructural (regla 2.5)
- Validator: warning si aparece medium/light antes que heavy en la sesion.
- Builder previo: ordenaba por bloque/calidad, no garantizaba heavy-first en orden final.
- Efecto: warnings recurrentes 2.5.

4. Doble logica y contradiccion
- Validator tenia funcion local de frecuencia; motor tenia otra ruta con ajuste de frecuencia.
- Efecto: riesgos de desalineacion de contrato con el tiempo.

## Evidencia de mismatch
- Resumen de casos: docs/audits/generated_cases/index_summary.md
- Casos con fallos de frecuencia/factibilidad previos y migracion de error: docs/audits/generated_cases/case_01_normal_torso_priority.md, docs/audits/generated_cases/case_03_rare_high_volume_frequency3.md

## Causa raiz
Reglas de factibilidad y construccion de estructura estaban optimizadas para generar plan, pero no estrictamente acopladas al contrato forense como fuente unica de verdad.
