# Checklist de Validacion Post-Refactor

## Funcionalidad Basica
- [ ] Crear cliente nuevo
- [ ] Abrir cliente existente
- [ ] Cambiar entre tabs sin crashes
- [ ] Guardar datos en cada tab

## Macros
- [ ] Configurar macros para Lunes-Domingo
- [ ] Verificar que se guardan en SQLite
- [ ] Cerrar y reabrir app -> macros persisten
- [ ] Cambiar de cliente -> macros son correctos por cliente

## Equivalentes
- [ ] Abrir tab Equivalentes
- [ ] Verificar que muestra objetivos desde macros del dia
- [ ] Lunes debe mostrar macros de Lunes (no global)
- [ ] Martes debe mostrar macros de Martes
- [ ] Asignar equivalentes
- [ ] Guardar y reabrir -> equivalentes persisten

## Sincronizacion
- [ ] Crear cliente con internet
- [ ] Verificar que sube a Firestore
- [ ] Crear cliente sin internet
- [ ] Reconectar -> verificar que sube automaticamente (5 min)

## Performance
- [ ] Abrir app con 50 clientes -> carga rapida (<2 seg)
- [ ] Cambiar entre tabs -> sin lag
- [ ] Guardar datos -> sin freeze

## Memory Leaks
- [ ] Usar Flutter DevTools -> Memory tab
- [ ] Cambiar 10 veces entre tabs
- [ ] Verificar que memoria no crece indefinidamente
