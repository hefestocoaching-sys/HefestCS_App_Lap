# A15 - METODOLOGIA Y ALCANCE

## 1) Regla aplicada
- Auditoria forense de codigo real.
- Sin refactor, sin patch funcional, sin cambios de comportamiento.

## 2) Fuentes de evidencia usadas
- Lectura directa de archivos en lib/ y modulos de features/domain/data/core.
- Busquedas por metodos/variables criticas (saveIfDirty, saveClient, push*Record, _syncItem, feature flags, auth gate).
- Verificacion de inventario por conteo de archivos en workspace.

## 3) Criterios de clasificacion
- P0: riesgo critico de consistencia/sync en flujo principal.
- P1: alto riesgo de arquitectura/acoplamiento y divergencia de fuentes.
- P2: riesgo medio de observabilidad y normalizacion.
- P3: deuda menor/documental.

## 4) Limites explicitos
- No se ejecuto en esta pasada una corrida nueva completa de todos los tests.
- No se auditaron servicios externos fuera del repositorio (reglas cloud en runtime real, pipelines CI externos, dashboards externos).

## 5) Entregables del paquete
- 15 archivos A01-A15 en audit_pack/.
- Incluye inventario, arquitectura real, flujos E2E, persistencia/sync, modelos, normalizacion, motor V3, matriz SSOT, deuda tecnica, tests, findings, tabla de verdad, backlog de prompts, resumen ejecutivo y metodologia.
