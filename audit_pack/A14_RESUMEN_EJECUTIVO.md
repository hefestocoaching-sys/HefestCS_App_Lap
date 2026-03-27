# A14 - RESUMEN EJECUTIVO

## Resumen corto
La app opera bajo un patron local-first funcional en cliente/clinico/nutricion/entrenamiento, con replicacion remota best-effort y degradacion controlada para no bloquear UX. El principal riesgo forense no es crash inmediato, sino inconsistencia silenciosa local-remoto en escenarios de error/autorizacion/sync parcial.

## Top 5 hallazgos
1. P0: Cola de sync con _syncItem sin implementacion completa de push por dominio.
2. P0: pushTrainingRecord remoto deshabilitado temporalmente (return directo).
3. P0: _remoteSyncTemporarilyDisabled puede apagar replicacion remota de toda la sesion.
4. P1: Duplicidad de arquitectura para appointments/transactions (flat vs coaches/{uid}).
5. P1: Persistencia de estado derivado de UI en training.extra y uso extensivo de mapas dinamicos.

## Nivel de riesgo global
- Riesgo operativo global: ALTO (por consistencia de datos y trazabilidad de sync).
- Riesgo de caida total de app: MEDIO (hay muchas rutas de degradacion para evitar crash).

## Decision de esta entrega
- Solo auditoria y documentacion forense.
- Sin correcciones de codigo en este paquete.
