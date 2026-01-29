# Dashboard Feature

Pantalla principal de HCS que proporciona visión holística del negocio del coach.

## 📊 Componentes

### Pantalla Principal
- **DashboardScreen** (`dashboard_screen.dart`): Ensamblaje responsivo de todos los widgets

### Estadísticas
- **QuickStatCard**: Tarjeta reutilizable mostrando métrica + tendencia (4 tarjetas en grid)

### Agenda
- **WeeklyCalendarWidget**: Calendario horizontal con vista de citas por día
- **TodayAppointmentsWidget**: Detalle de citas del día con acciones (completar/cancelar)

### Finanzas
- **FinancialSummaryWidget**: Resumen mensual con navegación de meses, desglose por categoría y ROI

### Alertas
- **AlertsPanelWidget**: Panel inteligente de recordatorios (planes por renovar, clientes sin medición, etc.)

## 🔧 State Management

### Providers
- `appointmentsProvider`: Gestiona lista de citas con CRUD, queries y auto-generación
- `transactionsProvider`: Gestiona transacciones financieras con cálculos de ingresos/gastos

### Entidades
- `Appointment`: Cita/consulta con tipo, estado, duración
- `Transaction`: Transacción financiera con tipo y categoría

## 🎨 Diseño

- **Tema**: Dark glass morphism
- **Responsividad**: 4 columnas en desktop (>900px), 2 en mobile
- **Moneda**: Pesos mexicanos (MXN)
- **Idioma**: Español de México

## 📱 Uso

El Dashboard es la pantalla inicial (index 0) de la aplicación. Se carga automáticamente al ingresar.

```
Navbar: [Inicio] [Historia] [Antropometría] ... [Ajustes]
             ↓ Dashboard muestra:
        - 4 stats rápidas
        - Calendario semanal
        - Citas de hoy
        - Resumen financiero
        - Panel de alertas
```

## 📝 Notas

- Los datos actualmente están en memoria con muestras
- Próximamente se integrará persistencia en Firestore/SQLite
- Los widgets son reutilizables y responsivos
- Compatible con la arquitectura MVVM + Riverpod existente
