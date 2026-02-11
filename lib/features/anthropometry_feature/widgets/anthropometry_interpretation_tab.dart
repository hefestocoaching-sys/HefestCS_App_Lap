import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/core/enums/gender.dart';
import 'package:hcs_app_lap/domain/entities/anthropometry_analysis_result.dart';
import 'package:hcs_app_lap/domain/entities/anthropometry_record.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/services/anthropometry_analyzer.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/features/main_shell/providers/global_date_provider.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/utils/widgets/section_header.dart';
import 'package:intl/intl.dart';

class AnthropometryInterpretationTab extends ConsumerStatefulWidget {
  const AnthropometryInterpretationTab({super.key});

  @override
  ConsumerState<AnthropometryInterpretationTab> createState() =>
      _AnthropometryInterpretationTabState();
}

class _AnthropometryInterpretationTabState
    extends ConsumerState<AnthropometryInterpretationTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final AnthropometryAnalyzer _analyzer = AnthropometryAnalyzer();
  Client? _client;

  // Selectores de Comparación (TUS VARIABLES ORIGINALES)
  AnthropometryRecord? _compareRecordA;
  AnthropometryRecord? _compareRecordB;

  String formatNumber(double? value, {int decimals = 1}) {
    if (value == null || value.isNaN || value.isInfinite) return '--';
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(decimals);
  }

  @override
  void initState() {
    super.initState();
    _client = ref.read(clientsProvider).value?.activeClient;
    // Inicializamos usando la fecha global actual
    _autoSelectByDate(ref.read(globalDateProvider));
  }

  @override
  void didUpdateWidget(covariant AnthropometryInterpretationTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // El listener en build() ahora se encarga de sincronizar cambios
    // Este método solo se necesita si la fecha global cambia fuera de este widget
    final globalDate = ref.read(globalDateProvider);
    _autoSelectByDate(globalDate);
  }

  /// Selecciona automáticamente los registros basándose en la fecha global (Time Travel)
  void _autoSelectByDate(DateTime targetDate) {
    if (_client == null || _client!.anthropometry.isEmpty) {
      setState(() {
        _compareRecordA = null;
        _compareRecordB = null;
      });
      return;
    }

    // Filtramos registros que existían en la fecha seleccionada o antes
    final validRecords = _client!.anthropometry.where((r) {
      return r.date.isBefore(targetDate) ||
          DateUtils.isSameDay(r.date, targetDate);
    }).toList();

    // Ordenamos descendente (el más nuevo primero)
    validRecords.sort((a, b) => b.date.compareTo(a.date));

    setState(() {
      // B es el registro "Actual" para esa fecha (el más reciente disponible)
      _compareRecordB = validRecords.isNotEmpty ? validRecords.first : null;
      // A es el registro previo inmediato
      _compareRecordA = validRecords.length > 1 ? validRecords[1] : null;
    });
  }

  Future<void> _deleteRecord(AnthropometryRecord record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCardColor,
        title: const Text(
          '¿Eliminar registro?',
          style: TextStyle(color: Colors.redAccent),
        ),
        content: Text(
          'Se eliminará permanentemente la medición del ${DateFormat('dd MMM yyyy', 'es').format(record.date)}.\nEsta acción no se puede deshacer.',
          style: const TextStyle(color: kTextColorSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (!mounted) {
      return;
    }
    if (confirm == true && _client != null) {
      final updatedList = List<AnthropometryRecord>.from(
        _client!.anthropometry,
      );
      updatedList.removeWhere(
        (r) => r == record,
      ); // Asumiendo igualdad por referencia o id

      // Actualizamos el cliente globalmente
      ref
          .read(clientsProvider.notifier)
          .updateActiveClient(
            (current) => current.copyWith(anthropometry: updatedList),
          );

      // La UI se actualizará automáticamente gracias al listener en build/initState
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro eliminado correctamente.')),
      );
    }
  }

  String _getBmiCategory(double? bmi) {
    if (bmi == null) return '';
    if (bmi < 18.5) return 'Bajo Peso';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Sobrepeso';
    return 'Obesidad';
  }

  // --- TU LÓGICA DE INSIGHTS (INTACTA) ---
  List<String> _generateInsights(
    AnthropometryRecord current,
    AnthropometryRecord? previous,
  ) {
    final List<String> insights = [];
    final client = _client;
    if (client == null) return [];

    final genderLabel = client.profile.gender?.label ?? 'Hombre';
    final isMale = client.profile.gender == Gender.male;
    final analysisCurr = _analyzer.analyze(
      record: current,
      age: client.profile.age,
      gender: genderLabel,
    );

    // ICC
    final double? icc =
        (current.waistCircNarrowest != null &&
            current.hipCircMax != null &&
            current.hipCircMax! > 0)
        ? current.waistCircNarrowest! / current.hipCircMax!
        : null;

    if (icc != null) {
      final double limit = isMale ? 0.90 : 0.85;
      if (icc >= limit) {
        insights.add(
          "⚠️ Riesgo Cardiometabólico: El índice cintura-cadera (${icc.toStringAsFixed(2)}) es elevado. Se recomienda priorizar la reducción de grasa visceral.",
        );
      } else {
        insights.add(
          "✅ Salud Metabólica: El índice cintura-cadera (${icc.toStringAsFixed(2)}) está en rango saludable.",
        );
      }
    }

    // % Grasa
    if (analysisCurr.bodyFatPercentage != null) {
      final fat = analysisCurr.bodyFatPercentage!;
      if (isMale) {
        if (fat < 10) {
          insights.add("ℹ️ Nivel de Grasa: Rango de atleta / competencia.");
        } else if (fat > 25) {
          insights.add(
            "⚠️ Composición Corporal: Porcentaje de grasa elevado, foco en déficit calórico.",
          );
        }
      } else {
        if (fat < 18) {
          insights.add("ℹ️ Nivel de Grasa: Rango de atleta / competencia.");
        } else if (fat > 32) {
          insights.add(
            "⚠️ Composición Corporal: Porcentaje de grasa elevado, foco en déficit calórico.",
          );
        }
      }
    }

    // Análisis Comparativo
    if (previous != null) {
      final analysisPrev = _analyzer.analyze(
        record: previous,
        age: client.profile.age,
        gender: genderLabel,
      );
      final int days = current.date.difference(previous.date).inDays.abs();

      final double weightDiff =
          (current.weightKg ?? 0) - (previous.weightKg ?? 0);
      final double? muscleDiff =
          (analysisCurr.muscleMassPercent != null &&
              analysisPrev.muscleMassPercent != null)
          ? analysisCurr.muscleMassPercent! - analysisPrev.muscleMassPercent!
          : null;
      final double? fatDiff =
          (analysisCurr.bodyFatPercentage != null &&
              analysisPrev.bodyFatPercentage != null)
          ? analysisCurr.bodyFatPercentage! - analysisPrev.bodyFatPercentage!
          : null;

      // Peso
      if (weightDiff.abs() < 0.5) {
        insights.add(
          "⚖️ Estabilidad: El peso se ha mantenido estable (var ${weightDiff.toStringAsFixed(1)} kg) en los últimos $days días.",
        );
      } else if (weightDiff > 0) {
        insights.add(
          "📈 Tendencia de Peso: Aumento de ${weightDiff.toStringAsFixed(1)} kg.",
        );
      } else {
        insights.add(
          "📉 Tendencia de Peso: Reducción de ${weightDiff.abs().toStringAsFixed(1)} kg.",
        );
      }

      // Recomposición
      if (muscleDiff != null && fatDiff != null) {
        if (muscleDiff > 0 && fatDiff < 0) {
          insights.add(
            "🔥 Recomposición Exitosa: Aumento de masa muscular (+${muscleDiff.toStringAsFixed(1)}%) simultáneo a pérdida de grasa (${fatDiff.toStringAsFixed(1)}%). Escenario ideal.",
          );
        } else if (muscleDiff < 0 && fatDiff < 0) {
          insights.add(
            "⚠️ Alerta Muscular: Pérdida de peso proveniente tanto de grasa como de músculo (-${muscleDiff.abs().toStringAsFixed(1)}%). Revisar ingesta proteica.",
          );
        } else if (muscleDiff > 0 && fatDiff > 0) {
          insights.add(
            "💪 Volumen: Ganancia de músculo acompañada de leve aumento de grasa. Normal en etapas de superávit.",
          );
        }
      }
    } else {
      insights.add(
        "📅 Línea Base: Este es el registro de referencia. Los próximos análisis mostrarán tu evolución.",
      );
    }

    return insights;
  }

  // --- BUILD PRINCIPAL (NUEVA ESTRUCTURA VISUAL) ---
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final clientState = ref.watch(clientsProvider);
    final client = clientState.value?.activeClient;

    // Listener que detecta cambios en anthropometry
    ref.listen<AsyncValue<ClientsState>>(clientsProvider, (previous, next) {
      final prevAnthro = previous?.value?.activeClient?.anthropometry ?? [];
      final nextAnthro = next.value?.activeClient?.anthropometry ?? [];

      // Si la lista cambió (diferente referencia o longitud), actualizar
      if (prevAnthro != nextAnthro || prevAnthro.length != nextAnthro.length) {
        _client = next.value?.activeClient;
        _autoSelectByDate(ref.read(globalDateProvider));
      }
    });

    if (client == null || client.anthropometry.isEmpty) {
      return const Center(
        child: Text(
          "No hay registros.",
          style: TextStyle(color: kTextColorSecondary),
        ),
      );
    }

    // Lista completa para los dropdowns (si el usuario quiere cambiar manualmente)
    final records = List<AnthropometryRecord>.from(client.anthropometry)
      ..sort((a, b) => b.date.compareTo(a.date));

    // Si el Time Travel nos dejó sin registros (fecha muy antigua), mostramos vacío o el más viejo
    if (_compareRecordB == null && records.isNotEmpty) {
      // Fallback visual si no hay datos en esa fecha
      return const Center(
        child: Text(
          "No hay datos registrados antes de esta fecha.",
          style: TextStyle(color: kTextColorSecondary),
        ),
      );
    }

    final rightRecord = _compareRecordB!;
    final leftRecord = _compareRecordA;

    final analysisRight = _analyzer.analyze(
      record: rightRecord,
      age: client.profile.age,
      gender: client.profile.gender?.label ?? 'Hombre',
    );
    final analysisLeft = leftRecord != null
        ? _analyzer.analyze(
            record: leftRecord,
            age: client.profile.age,
            gender: client.profile.gender?.label ?? 'Hombre',
          )
        : null;

    final insights = _generateInsights(rightRecord, leftRecord);

    // Se envuelve en un Scaffold transparente para unificar el comportamiento
    // con las otras pestañas y permitir que el fondo de la app se vea.
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Header Control (Rediseñado)
                  _buildHeaderControl(records, leftRecord, rightRecord),
                  const SizedBox(height: 24),

                  // 2. Tarjetas de Análisis Visuales (Reemplaza la tabla antigua)
                  _buildModernAnalysisCards(
                    leftRecord: leftRecord,
                    rightRecord: rightRecord,
                    leftAnalysis: analysisLeft,
                    rightAnalysis: analysisRight,
                    client: client,
                  ),
                  const SizedBox(height: 24),

                  // 3. INSIGHTS (Rediseñado)
                  _buildInsightsPanel(insights),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- 1. HEADER: SELECTORES (Estilo Dark Dashboard) ---
  Widget _buildHeaderControl(
    List<AnthropometryRecord> records,
    AnthropometryRecord? left,
    AnthropometryRecord? right,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kCardColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: kPrimaryColor.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: "CONFIGURACIÓN DE ANÁLISIS",
            icon: Icons.bar_chart_rounded,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _MetricDropdown(
                  label: "Fecha a comparar",
                  value: left,
                  items: records,
                  allowNull: true,
                  onChanged: (v) => setState(() => _compareRecordA = v),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kBackgroundColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: kTextColorSecondary.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.swap_horiz_rounded,
                  color: kTextColorSecondary,
                  size: 20,
                ),
              ),
              Expanded(
                child: _MetricDropdown(
                  label: "Fecha actual",
                  value: right,
                  items: records,
                  onDelete: () => _deleteRecord(right!),
                  onChanged: (v) => setState(() {
                    if (v != null) _compareRecordB = v;
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 2. CONSTRUCTOR DE TARJETAS MÉTRICAS VISUALES ---
  Widget _buildModernAnalysisCards({
    required AnthropometryRecord? leftRecord,
    required AnthropometryRecord rightRecord,
    required AnthropometryAnalysisResult? leftAnalysis,
    required AnthropometryAnalysisResult rightAnalysis,
    required Client client,
  }) {
    final bool isComparison = leftRecord != null && leftAnalysis != null;
    final double currentWeight = rightRecord.weightKg ?? 0.0;

    // --- LÓGICA DE MÁXIMO VISUAL ---
    // Define el 100% de la barra de progreso.
    double weightVisualMax;
    double componentVisualMax;

    if (isComparison) {
      // MODO COMPARACIÓN: El máximo para el peso es el valor más alto entre los dos registros.
      // Para los componentes en %, el máximo es 100.
      weightVisualMax = max(currentWeight, leftRecord.weightKg ?? 0.0);
      if (weightVisualMax == 0) weightVisualMax = 150.0; // Fallback
      componentVisualMax = 100.0; // Para porcentajes
    } else {
      // MODO SIN COMPARACIÓN: El peso actual es el 100% para todas las barras.
      weightVisualMax = currentWeight > 0 ? currentWeight : 150.0;
      componentVisualMax = currentWeight > 0 ? currentWeight : 100.0;
    }

    final rows = [
      _RowData(
        label: 'Peso Corporal',
        unit: 'kg',
        valA: isComparison ? leftRecord.weightKg : null,
        valB: rightRecord.weightKg,
        icon: Icons.monitor_weight_outlined,
        isLowerBetter: client.profile.objective != 'Hipertrofia',
        visualMax: weightVisualMax,
        accentColor: kPrimaryColor,
      ),
      _RowData(
        label: 'Grasa Corporal',
        unit: isComparison ? '%' : 'kg',
        valA: isComparison ? leftAnalysis.bodyFatPercentage : null,
        valB: isComparison
            ? rightAnalysis.bodyFatPercentage
            : rightAnalysis.fatMassKg,
        subValA: isComparison ? leftAnalysis.fatMassKg : null,
        subValB: isComparison
            ? rightAnalysis.fatMassKg
            : rightAnalysis.bodyFatPercentage,
        subUnit: isComparison ? 'kg' : '%',
        icon: Icons.water_drop_outlined,
        isLowerBetter: true,
        visualMax: componentVisualMax,
        accentColor: kPrimaryColor,
      ),
      _RowData(
        label: 'Masa Magra (MLG)',
        unit: isComparison ? '%' : 'kg',
        valA: isComparison ? leftAnalysis.leanMassPercent : null,
        valB: isComparison
            ? rightAnalysis.leanMassPercent
            : rightAnalysis.leanMassKg,
        subValA: isComparison ? leftAnalysis.leanMassKg : null,
        subValB: isComparison
            ? rightAnalysis.leanMassKg
            : rightAnalysis.leanMassPercent,
        subUnit: isComparison ? 'kg' : '%',
        icon: Icons.shield_outlined,
        isLowerBetter: false,
        visualMax: componentVisualMax,
        accentColor: kPrimaryColor,
      ),
      _RowData(
        label: 'Masa Muscular',
        unit: isComparison ? '%' : 'kg',
        valA: isComparison ? leftAnalysis.muscleMassPercent : null,
        valB: isComparison
            ? rightAnalysis.muscleMassPercent
            : rightAnalysis.muscleMassKg,
        subValA: isComparison ? leftAnalysis.muscleMassKg : null,
        subValB: isComparison
            ? rightAnalysis.muscleMassKg
            : rightAnalysis.muscleMassPercent,
        subUnit: isComparison ? 'kg' : '%',
        icon: Icons.fitness_center_rounded,
        isLowerBetter: false,
        visualMax: componentVisualMax,
        accentColor: kPrimaryColor,
      ),
      _RowData(
        label: 'Masa Ósea',
        unit: isComparison ? '%' : 'kg',
        valA: isComparison ? leftAnalysis.boneMassPercent : null,
        valB: isComparison
            ? rightAnalysis.boneMassPercent
            : rightAnalysis.boneMassKg,
        subValA: isComparison ? leftAnalysis.boneMassKg : null,
        subValB: isComparison
            ? rightAnalysis.boneMassKg
            : rightAnalysis.boneMassPercent,
        subUnit: isComparison ? 'kg' : '%',
        icon: Icons.accessibility_new_rounded,
        isLowerBetter: false,
        visualMax: componentVisualMax,
        accentColor: kPrimaryColor,
      ),
      _RowData(
        label: 'Masa Residual',
        unit: isComparison ? '%' : 'kg',
        valA: isComparison ? leftAnalysis.visceralMassPercent : null,
        valB: isComparison
            ? rightAnalysis.visceralMassPercent
            : rightAnalysis.visceralMassKg,
        subValA: isComparison ? leftAnalysis.visceralMassKg : null,
        subValB: isComparison
            ? rightAnalysis.visceralMassKg
            : rightAnalysis.visceralMassPercent,
        subUnit: isComparison ? 'kg' : '%',
        icon: Icons.inventory_2_outlined,
        isLowerBetter: true,
        visualMax: componentVisualMax,
        accentColor: kPrimaryColor,
      ),
      _RowData(
        label: 'IMC',
        unit: 'kg/m²',
        valA: isComparison ? leftAnalysis.bmi : null,
        valB: rightAnalysis.bmi,
        subLabel: _getBmiCategory(rightAnalysis.bmi),
        icon: Icons.calculate_outlined,
        isLowerBetter: true,
        visualMax: 40.0, // IMC tiene su propia escala fija
        accentColor: kPrimaryColor,
      ),
    ];

    return Column(
      children: rows
          .map((row) => _buildModernMetricCard(row, isComparison))
          .toList(),
    );
  }

  // Widget de Tarjeta Métrica Individual (El nuevo diseño)
  Widget _buildModernMetricCard(_RowData row, bool isComparison) {
    final accent = row.accentColor ?? kPrimaryColor; // Color por defecto (azul)

    // --- LÓGICA DE COLOR Y MÁXIMO DINÁMICO ---
    final double diff = (row.valB ?? 0) - (row.valA ?? 0);

    Color barAndLabelColor;
    // Si no hay comparación o no hay cambio, usamos el color por defecto.
    if (!isComparison || diff.abs() < 0.01) {
      barAndLabelColor = accent;
    } else {
      // Si hay cambio, determinamos si es bueno o malo.
      final bool isPositiveChange = diff > 0;
      final bool isGood = row.isLowerBetter
          ? !isPositiveChange
          : isPositiveChange;
      // Verde para bueno, Rojo para malo.
      barAndLabelColor = isGood ? kSuccessColor : Colors.redAccent;
    }

    double barMax;
    // Si la unidad es %, la barra va de 0 a 100 (o lo que defina visualMax).
    if (row.unit == '%') {
      barMax = row.visualMax;
    }
    // Para otras unidades, el 100% de la barra es el valor más alto entre los dos.
    else if (isComparison && (row.valA != null || row.valB != null)) {
      // El 100% de la barra será el valor más alto entre el anterior y el actual.
      barMax = max(row.valA ?? 0.0, row.valB ?? 0.0);
      if (barMax == 0) barMax = row.visualMax; // Evitar división por cero.
    } else {
      // Usar máximo fijo si no hay comparación.
      barMax = row.visualMax;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCardColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: barAndLabelColor.withValues(alpha: 0.15),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          // A. Header de la Tarjeta (Icono, Título, Badge de cambio)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: barAndLabelColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(row.icon, color: barAndLabelColor, size: 20),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.label.toUpperCase(),
                    style: const TextStyle(
                      color: kTextColorSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  if (row.unit.isNotEmpty)
                    Text(
                      row.unit,
                      style: TextStyle(
                        color: kTextColorSecondary.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
              const Spacer(),
              if (isComparison) _buildChangeBadge(row),
            ],
          ),
          const SizedBox(height: 24),

          // B. Cuerpo Comparativo (Valores y Barras Visuales)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Bloque Anterior (PREV) - Se oculta si no hay comparación
              if (isComparison)
                Expanded(
                  child: _buildVisualDataBlock(
                    label: "PREV",
                    value: row.valA,
                    subValue: row.subValA,
                    subUnit: row.subUnit,
                    unit: row.unit,
                    max: barMax,
                    color: kPrimaryColor, // El anterior siempre es azul
                    isPrev: true,
                  ),
                ),
              if (isComparison) const SizedBox(width: 24),
              // Bloque Actual (ACTUAL)
              Expanded(
                child: _buildVisualDataBlock(
                  label: "ACTUAL",
                  value: row.valB,
                  subValue: row.subValB,
                  subUnit: row.subUnit,
                  unit: row.unit,
                  max: barMax,
                  subLabel: row.subLabel,
                  color: barAndLabelColor,
                  isPrev: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Badge pequeño que muestra la diferencia (+1.5)
  Widget _buildChangeBadge(_RowData row) {
    final double valA = row.valA ?? 0;
    final double valB = row.valB ?? 0;
    final double diff = valB - valA;

    if (diff.abs() < 0.01) return const SizedBox.shrink();

    final bool isPositiveChange = diff > 0;
    // Determinar si el cambio es "bueno" basado en isLowerBetter
    final bool isGood = row.isLowerBetter
        ? !isPositiveChange
        : isPositiveChange;
    final Color diffColor = isGood ? kSuccessColor : Colors.redAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: diffColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: diffColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        "${diff > 0 ? '+' : ''}${formatNumber(diff)}",
        style: TextStyle(
          color: diffColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Bloque que construye el número y la barra de progreso visual debajo
  Widget _buildVisualDataBlock({
    required String label,
    required double? value,
    double? subValue,
    String? subUnit,
    required String unit,
    required double max,
    String? subLabel,
    required Color color,
    required bool isPrev,
  }) {
    final double safeValue = value ?? 0;
    // Calcula el porcentaje de llenado de la barra (topado a 1.0)
    final double percentage = (max > 0)
        ? (safeValue / max).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Etiqueta PREV/ACTUAL
        Text(
          label,
          style: TextStyle(
            color: isPrev
                ? kTextColorSecondary.withValues(alpha: 0.7)
                : kTextColorSecondary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        // Valor Numérico Grande
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              formatNumber(safeValue),
              style: TextStyle(
                color: isPrev ? kTextColorSecondary : color,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: TextStyle(
                color: kTextColorSecondary.withValues(alpha: 0.8),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        // Sub-etiquetas (ej. kg debajo del %)
        if (subValue != null && subUnit != null)
          Padding(
            padding: const EdgeInsets.only(top: 2.0, bottom: 8.0),
            child: Text(
              "${formatNumber(subValue)} $subUnit",
              style: const TextStyle(color: kTextColorSecondary, fontSize: 12),
            ),
          )
        else if (subLabel != null)
          Padding(
            padding: const EdgeInsets.only(top: 2.0, bottom: 8.0),
            child: Text(
              subLabel,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          const SizedBox(height: 10), // Espacio si no hay sub-etiqueta
        // --- Barra Visual de Progreso ---
        Stack(
          children: [
            // Fondo de la barra
            Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                color: kBackgroundColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Barra de relleno con gradiente y brillo
            FractionallySizedBox(
              widthFactor: percentage,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.6), color],
                  ),
                  boxShadow: isPrev
                      ? []
                      : [
                          // Brillo tipo neón solo para la barra actual
                          BoxShadow(
                            color: color.withValues(alpha: 0.6),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- 3. PANEL DE INSIGHTS (Estilo Dark Dashboard) ---
  Widget _buildInsightsPanel(List<String> insights) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kCardColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: kPrimaryColor.withValues(alpha: 0.15),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: "ANÁLISIS INTELIGENTE",
            icon: Icons.psychology_alt_rounded,
            letterSpacing: 1.2,
            fontSize: 12,
          ),
          const SizedBox(height: 20),
          if (insights.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "No hay suficientes datos para generar un análisis.",
                style: TextStyle(color: kTextColorSecondary),
              ),
            ),
          ...insights.map(
            (insight) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icono de punto coloreado según el tipo de insight
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Icon(
                      Icons.circle,
                      size: 8,
                      color: _getInsightColor(insight),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      // Limpiamos el emoji del string original ya que usamos el icono de punto
                      insight.replaceAll(RegExp(r'^[^\w\s]+'), '').trim(),
                      style: TextStyle(
                        color: kTextColor.withValues(alpha: 0.9),
                        height: 1.5,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getInsightColor(String text) {
    final t = text.toLowerCase();
    if (t.contains('riesgo') || t.contains('alerta') || t.contains('elevado')) {
      return Colors.redAccent;
    }
    if (t.contains('saludable') ||
        t.contains('exitosa') ||
        t.contains('favorable') ||
        t.contains('atleta')) {
      return kSuccessColor;
    }
    return kPrimaryColor; // Color neutro por defecto
  }
}

// --- MODELOS AUXILIARES (Actualizados) ---

class _RowData {
  final String label;
  final String unit;
  final double? valA;
  final double? valB;
  final double? subValA;
  final double? subValB;
  final String? subUnit;
  final IconData icon;
  final String? subLabel;
  final bool isLowerBetter;
  // Propiedades nuevas para la visualización
  final double visualMax;
  final Color? accentColor;

  const _RowData({
    required this.label,
    required this.unit,
    this.valA,
    this.valB,
    this.subValA,
    this.subValB,
    this.subUnit,
    this.subLabel,
    required this.icon,
    required this.isLowerBetter,
    this.visualMax = 100.0, // Valor por defecto
    this.accentColor,
  });
}

// Dropdown personalizado con estilo oscuro
class _MetricDropdown extends StatelessWidget {
  final String label;
  final AnthropometryRecord? value;
  final List<AnthropometryRecord> items;
  final ValueChanged<AnthropometryRecord?> onChanged;
  final VoidCallback? onDelete; // Callback opcional para borrar
  final bool allowNull;

  const _MetricDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.onDelete,
    this.allowNull = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: kTextColorSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (onDelete != null && value != null)
              InkWell(
                onTap: onDelete,
                child: const Padding(
                  padding: EdgeInsets.only(left: 8.0, bottom: 2.0),
                  child: Icon(
                    Icons.delete_outline,
                    size: 14,
                    color: Colors.redAccent,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withAlpha(30)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<AnthropometryRecord?>(
              value: value,
              isExpanded: true,
              dropdownColor: kCardColor,
              borderRadius: BorderRadius.circular(12),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: kTextColorSecondary,
                size: 20,
              ),
              style: const TextStyle(
                color: kTextColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              hint: Text(
                "Seleccionar",
                style: TextStyle(
                  color: kTextColorSecondary.withValues(alpha: 0.5),
                ),
              ),
              items: [
                if (allowNull)
                  DropdownMenuItem(
                    child: Text(
                      "Sin referencia previa",
                      style: TextStyle(
                        color: kTextColorSecondary.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ...items.map(
                  (r) => DropdownMenuItem(
                    value: r,
                    child: Text(DateFormat('dd MMM yyyy', 'es').format(r.date)),
                  ),
                ),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
