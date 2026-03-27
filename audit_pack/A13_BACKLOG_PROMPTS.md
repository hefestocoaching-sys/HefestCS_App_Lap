# A13 - BACKLOG DE PROMPTS (SOLO PREPARACION, SIN APLICAR CAMBIOS)

## P0 prompts
1. "Audita e implementa la ejecucion real de SyncService._syncItem para cada domain soportado, conservando local-first y agregando metricas de exito/fallo por item."
2. "Audita y diseña estrategia de reactivacion segura de _remoteSyncTemporarilyDisabled tras permission-denied, sin romper UX offline."
3. "Audita y reestablece sincronizacion remota de training records con payload contract estricto y fallback controlado."

## P1 prompts
4. "Unifica arquitectura de appointments en una sola ruta de datos y produce plan de migracion con tabla de compatibilidad."
5. "Unifica arquitectura de transactions en una sola ruta de datos y define estrategia de deprecacion de la ruta legacy."
6. "Tipa claves criticas de nutrition.extra y training.extra con wrappers/VOs para reducir errores semanticos."
7. "Extrae logica de negocio de saveIfDirty en pantallas a servicios de aplicacion para reducir acople UI-persistencia."

## P2 prompts
8. "Agrega observabilidad funcional para degradaciones silenciosas (skip remoto, auth fallback, payload invalid) con dashboard de eventos."
9. "Revisa normalizacion de dateKey/timezone en records clinicos y define contrato unico UTC/local."

## P3 prompts
10. "Limpia comentarios temporales legacy en zonas de sync y documenta decision records ADR."
11. "Construye mapa de ownership por modulo y limite de responsabilidades por provider/screen."

## Regla de uso
- Estos prompts son backlog de ejecución futura.
- Este paquete forense NO aplica refactors ni parches de codigo funcional.
