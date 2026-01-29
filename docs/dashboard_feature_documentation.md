# Dashboard Feature - Documentación de Implementación

## Descripción General

El Dashboard es la pantalla principal (index 0) de la aplicación HCS. Proporciona una visión holística del negocio del coach con:
- **Estadísticas rápidas**: Clientes activos, ingresos, gastos, ganancia neta
- **Agenda semanal**: Vista de citas por día de la semana
- **Citas de hoy**: Detalle de citas del día actual con acciones
- **Resumen financiero**: Desglose mensual de ingresos y gastos por categoría
- **Panel de alertas**: Recordatorios de planes por renovar, clientes sin medición, etc.

## Estructura de Archivos

```
lib/features/dashboard_feature/
├── dashboard_screen.dart           # Pantalla principal (ensamblaje de widgets)
├── providers/
│   ├── appointments_provider.dart  # StateNotifier para citas
│   └── transactions_provider.dart  # StateNotifier para transacciones
└── widgets/
    ├── alerts_panel_widget.dart           # Panel de alertas y recordatorios
    ├── financial_summary_widget.dart      # Resumen financiero mensual
    ├── quick_stat_card.dart               # Tarjeta estadística reutilizable
    ├── today_appointments_widget.dart     # Citas del día actual
    └── weekly_calendar_widget.dart        # Calendario semanal
```

## Entidades (Domain Layer)

### Appointment (lib/domain/entities/appointment.dart)

```dart
@freezed
class Appointment with _$Appointment {
  const factory Appointment({
    required String id,
    required String clientId,
    required String clientName,
    required DateTime dateTime,
    required AppointmentType type,
    required AppointmentStatus status,
    @Default(Duration(minutes: 60)) Duration duration,
    String? notes,
    @Default(true) bool reminder,
  }) = _Appointment;
  
  // JSON serialization & extensions
}
```

**AppointmentType**: weeklyCheck, measurement, planRenewal, training, firstConsult, custom  
**AppointmentStatus**: scheduled, completed, cancelled, noShow

### Transaction (lib/domain/entities/transaction.dart)

```dart
@freezed
class Transaction with _$Transaction {
  const factory Transaction({
    required String id,
    required DateTime date,
    required TransactionType type,
    required TransactionCategory category,
    required double amount,
    String? description,
    String? clientId,
  }) = _Transaction;
  
  // JSON serialization & extensions
}
```

**TransactionType**: income, expense  
**TransactionCategory**: 
- Income: newPlan, renewal, consultation, otherIncome
- Expense: software, education, equipment, marketing, otherExpense

## State Management

### appointmentsProvider
- **Tipo**: `StateNotifierProvider<AppointmentsNotifier, List<Appointment>>`
- **Responsabilidad**: Gestionar estado de citas
- **Métodos**:
  - CRUD: `addAppointment()`, `updateAppointment()`, `deleteAppointment()`
  - Acciones: `completeAppointment()`, `cancelAppointment()`
  - Queries: `getTodayAppointments()`, `getWeekAppointments()`, `getAppointmentsByDate()`
  - Auto-generación: `createNextAppointment()` (7 días después, 10:00 AM)

### transactionsProvider
- **Tipo**: `StateNotifierProvider<TransactionsNotifier, List<Transaction>>`
- **Responsabilidad**: Gestionar transacciones financieras
- **Métodos**:
  - CRUD: `addTransaction()`, `updateTransaction()`, `deleteTransaction()`
  - Cálculos: `getMonthlyIncome()`, `getMonthlyExpenses()`, `getMonthlyProfit()`, `getROI()`
  - Desglose: `getIncomeBreakdown()`, `getExpenseBreakdown()`

## Widgets

### QuickStatCard
Tarjeta estadística reutilizable con:
- Icono y color personalizables
- Título y valor principal
- Subtítulo y tendencia (opcional)
- Indicador de tendencia (positiva/negativa)
- Callback onTap para navegación

### WeeklyCalendarWidget
Calendario horizontal de 7 días con:
- Vista de semana actual con navegación (anterior/hoy/siguiente)
- Citas mostradas como chips coloreados (6 colores según tipo)
- Integración con appointmentsProvider y clientsProvider
- Altura de 180px

### TodayAppointmentsWidget
Lista de citas del día con:
- Tarjetas expandibles por cita
- Muestra: hora, avatar del cliente, tipo, notas
- Botones de acción: Cancelar (naranja) y Completar (verde)
- Indicadores de estado (checkmark, cancel)
- Empty state cuando no hay citas

### FinancialSummaryWidget
Resumen financiero mensual con:
- Navegación de meses (anterior/siguiente)
- Resumen principal: ingresos, gastos, ganancia
- Desglose por categoría con barras de progreso
- Cálculo de ROI (Retorno de Inversión)
- Localización a México (pesos, locale 'es_MX')

### AlertsPanelWidget
Panel de alertas inteligentes que detecta:
- Planes próximos a vencer (< 7 días)
- Planes ya expirados
- Clientes sin medición reciente (> 30 días)
- Citas del día
- Citas esta semana
- Clientes sin plan asignado

## Integración en Navegación

**main_shell_screen.dart** fue actualizado para:
1. Importar `DashboardScreen`
2. Agregar Dashboard como primer elemento en `_navigationItems` (index 0)
3. Todos los índices posteriores se incrementaron en 1
4. Historia Clínica: index 1 (antes 0)
5. Antropometría: index 2 (antes 1)
6. ... y así sucesivamente
7. Ajustes: index 8 (antes 7)

## Flujo de Datos

```
User Views Dashboard
    ↓
DashboardScreen (build)
    ├─→ ref.watch(clientsProvider)
    ├─→ ref.read(transactionsProvider.notifier)
    └─→ ref.read(appointmentsProvider.notifier)
    ↓
    Queries & Calculations
    ├─→ getMonthlyIncome(), getMonthlyExpenses()
    ├─→ getTodayAppointments(), getWeekAppointments()
    └─→ Breakdown calculations
    ↓
    Widgets Render
    ├─→ QuickStatCard (4 tarjetas)
    ├─→ WeeklyCalendarWidget
    ├─→ TodayAppointmentsWidget
    ├─→ FinancialSummaryWidget
    └─→ AlertsPanelWidget
```

## Datos de Muestra

### Citas Generadas
- 3 para hoy (9:00 AM, 11:00 AM, 3:00 PM)
- 2 para mañana
- 3 para la semana

### Transacciones Generadas
- **Ingresos**: $12,500 (3 planes nuevos $1,500, 12 renovaciones $600, 5 consultas $160)
- **Gastos**: $3,200 (software $450, educación $200, otros $2,550)
- **Ganancia Neta**: $9,300

## Flujo de Uso

1. **Inicio**: Coach abre la app → Dashboard es la pantalla inicial
2. **Revisión rápida**: Ve stats, alertas y citas del día
3. **Navegación**: Puede ir a módulos específicos con el navbar
4. **Citas**: Puede ver agenda semanal y gestionar citas del día
5. **Finanzas**: Puede navegar por meses, ver desglose por categoría y ROI

## Persistencia (Próxima Fase)

Actualmente todo está en memoria con datos de muestra. Para persistencia:

1. Crear `AppointmentRepository` (SQLite + Firestore sync)
2. Crear `TransactionRepository` (SQLite + Firestore sync)
3. Actualizar providers para leer de repositorios
4. Agregar métodos save/load a las entidades

## Localización

- **Idioma**: Español (es_MX)
- **Moneda**: Pesos mexicanos ($)
- **Formato**: Mediante `NumberFormat.currency(locale: 'es_MX')`
- **Horarios**: 9 AM - 9 PM (configurable en providers)

## Temas de Diseño

Utiliza tema dark glass morphism:
- **Background**: `#232B45` (kBackgroundColor)
- **Card**: `#010510` (kCardColor)
- **Primary**: `#3F51B5` (kPrimaryColor)
- **Éxito**: `#4CAF50` (kSuccessColor)
- **Bordes**: Glassmorphism con `Colors.white.withAlpha(20)`

## Próximas Mejoras

1. **Persistencia**: Guardar citas y transacciones en Firestore/SQLite
2. **Interactividad**: Crear cita directamente desde Dashboard
3. **Gráficos**: Agregar gráficos de evolución de ingresos
4. **Notificaciones**: Recordatorios antes de citas
5. **Exportación**: Descargar reportes financieros en PDF
6. **Filtros**: Filtrar por cliente, tipo de cita, categoría
7. **Dashboard personalizado**: Widgets reordenables
