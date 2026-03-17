import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/core/constants/muscle_labels_es.dart';
import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/domain/entities/weekly_volume_record.dart';
import 'package:hcs_app_lap/domain/models/weekly_volume_view.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/utils/widgets/hcs_input_decoration.dart';

/// Tab 3 — Progreso Semanal de Volumen POR MÚSCULO (52 semanas)
///
/// PROPÓSITO:
/// Mostrar automáticamente el progreso de volumen semanal POR MÚSCULO,
/// usando datos REALES cuando existan o PROGRAMADOS cuando no.
///
/// UNIDAD DE ANÁLISIS: MÚSCULO (selector dropdown)
///
/// DATOS REALES:
/// - Fuente: client.training.extra['weeklyVolumeHistory']
/// - Representan: semanas cerradas con registros de bitácora
///
/// DATOS PROGRAMADOS:
/// - Fuente: Motor (calculados al vuelo)
/// - Distribución: De Tab 2 (seriesTypePercentSplit)
/// - Progresión: Conservadora (incremental, sin saltos)
///
/// REGLA DE ORO:
/// 1. Si existe dato REAL para ese músculo → usarlo
/// 2. Si no existe → generar PROGRAMADO para ese músculo
/// 3. La tabla NUNCA está vacía (siempre muestra 52 semanas)
/// 4. Diferenciación visual: REAL (sólido) vs PROGRAMADO (tenue)
/// 5. Sin botones, sin confirmaciones, sin acciones manuales

class WeeklyHistoryTab extends ConsumerStatefulWidget {
  final Map<String, dynamic> trainingExtra;

  const WeeklyHistoryTab({super.key, required this.trainingExtra});

  @override
  ConsumerState<WeeklyHistoryTab> createState() => _WeeklyHistoryTabState();
}

class _WeeklyHistoryTabState extends ConsumerState<WeeklyHistoryTab> {
  String? _selectedMuscle;

  @override
  Widget build(BuildContext context) {
    // Obtener lista de músculos disponibles
    final availableMuscles = _getAvailableMuscles();

    // Seleccionar músculo por defecto si no hay ninguno
    if (_selectedMuscle == null && availableMuscles.isNotEmpty) {
      _selectedMuscle = availableMuscles.first;
    }

    // Si no hay músculos disponibles, mostrar estado vacío
    if (availableMuscles.isEmpty || _selectedMuscle == null) {
      return _buildEmptyState(context);
    }

    // Leer datos reales del historial para el músculo seleccionado
    final realWeeks = _loadRealWeeksForMuscle(
      widget.trainingExtra,
      _selectedMuscle!,
    );

    // Leer distribución H/M/L (fallback 20/60/20)
    final split = _loadSeriesSplit(widget.trainingExtra);

    // Leer baseline de series para este músculo específico
    final baseSeries = _loadBaseSeriesForMuscle(
      widget.trainingExtra,
      _selectedMuscle!,
    );

    // Construir 52 semanas: real cuando existe, programado cuando no
    final allWeeks = _buildAllWeeksForMuscle(
      muscle: _selectedMuscle!,
      realWeeks: realWeeks,
      split: split,
      baseSeries: baseSeries,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, hasRealData: realWeeks.isNotEmpty),
          const SizedBox(height: 12),
          _buildMuscleSelector(context, availableMuscles),
          const SizedBox(height: 12),
          _buildWeeksTable(context, allWeeks),
          const SizedBox(height: 12),
          _buildLegend(),
        ],
      ),
    );
  }

  /// Header con ícono y descripción
  Widget _buildHeader(BuildContext context, {required bool hasRealData}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: Colors.teal.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, color: Colors.teal, size: 20),
              SizedBox(width: 8),
              Text(
                'Progreso de Volumen por Músculo (52 semanas)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            hasRealData
                ? 'Datos reales del asesorado combinados con proyecciones teóricas.'
                : 'Mientras no haya registros de bitácora, se muestra una progresión teórica conservadora basada en el motor.',
            style: const TextStyle(color: kTextColorSecondary, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
            ),
            child: const Text(
              '🔄 Automático y reactivo: se actualiza al registrar bitácora. Distribución H/M/L según Tab 2.',
              style: TextStyle(color: kTextColorSecondary, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  /// Selector de músculo (dropdown obligatorio)
  Widget _buildMuscleSelector(
    BuildContext context,
    List<String> availableMuscles,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.fitness_center, size: 18, color: Colors.teal),
            const SizedBox(width: 8),
            const Text(
              'Músculo:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _selectedMuscle,
                decoration: hcsDecoration(
                  context,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: availableMuscles.map((muscle) {
                  return DropdownMenuItem(
                    value: muscle,
                    child: Text(
                      muscleLabelEs(muscle),
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedMuscle = value;
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Estado vacío (sin músculos disponibles)
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          const Text(
            'Sin músculos disponibles',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: kTextColorSecondary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Define el VOP en Tab 1 para ver el progreso semanal.',
            style: TextStyle(color: kTextColorSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  /// Tabla con 52 semanas para el músculo seleccionado
  Widget _buildWeeksTable(BuildContext context, List<WeeklyVolumeView> weeks) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historial de ${muscleLabelEs(_selectedMuscle!)}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 32,
                dataRowMinHeight: 28,
                dataRowMaxHeight: 28,
                columnSpacing: 12,
                headingRowColor: WidgetStateColor.resolveWith(
                  (states) => Colors.grey.withValues(alpha: 0.1),
                ),
                columns: const [
                  DataColumn(
                    label: Text('Semana', style: TextStyle(fontSize: 10)),
                  ),
                  DataColumn(
                    label: Text('Total', style: TextStyle(fontSize: 10)),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text('Patrón', style: TextStyle(fontSize: 10)),
                  ),
                  DataColumn(
                    label: Text('Pesadas', style: TextStyle(fontSize: 10)),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text('Medias', style: TextStyle(fontSize: 10)),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text('Ligeras', style: TextStyle(fontSize: 10)),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text('Fuente', style: TextStyle(fontSize: 10)),
                  ),
                ],
                rows: weeks.map((w) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          'W${w.weekIndex}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                      DataCell(
                        Text(
                          w.totalSeries.toString(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: w.isReal
                                ? Colors.black87
                                : Colors.grey.shade400,
                          ),
                        ),
                      ),
                      DataCell(_buildPatternBadge(w.pattern)),
                      DataCell(
                        Text(
                          w.heavySeries.toString(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: w.isReal
                                ? Colors.red.shade700
                                : Colors.red.shade300,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          w.mediumSeries.toString(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: w.isReal
                                ? Colors.orange.shade700
                                : Colors.orange.shade300,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          w.lightSeries.toString(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: w.isReal
                                ? Colors.blue.shade700
                                : Colors.blue.shade300,
                          ),
                        ),
                      ),
                      DataCell(
                        Tooltip(
                          message: w.isReal
                              ? 'Registrado por el asesorado.'
                              : 'Estimado por el motor. Se ajusta automáticamente al registrar bitácora.',
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: w.isReal
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              w.isReal ? 'Real' : 'Plan',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: w.isReal
                                    ? Colors.green.shade700
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Leyenda de diferenciación REAL vs PROGRAMADO
  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green.shade700,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Real',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 4),
                const Text(
                  '= Registrado en bitácora',
                  style: TextStyle(fontSize: 9, color: kTextColorSecondary),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Plan',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 4),
                const Text(
                  '= Estimado por motor',
                  style: TextStyle(fontSize: 9, color: kTextColorSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // FUNCIONES PRIVADAS — LÓGICA DE DATOS
  // =====================================================================

  /// Obtiene lista de músculos disponibles (desde VOP o historial)
  List<String> _getAvailableMuscles() {
    final muscles = <String>{};

    // 1. Músculos desde VOP (prioritario)
    final vopRaw =
        widget.trainingExtra[TrainingExtraKeys.finalTargetSetsByMuscleUi] ??
        widget.trainingExtra['targetSetsByMuscle'];
    if (vopRaw is Map) {
      for (final key in vopRaw.keys) {
        if (key is String) {
          muscles.add(key);
        }
      }
    }

    // 2. Músculos desde historial real (si existen)
    final historyRaw =
        widget.trainingExtra[TrainingExtraKeys.weeklyVolumeHistory];
    if (historyRaw is List) {
      for (final item in historyRaw) {
        if (item is Map && item['muscleGroup'] != null) {
          muscles.add(item['muscleGroup'].toString());
        }
      }
    }

    final list = muscles.toList()..sort();
    return list;
  }

  /// Carga registros reales para un músculo específico
  Map<int, WeeklyVolumeRecord> _loadRealWeeksForMuscle(
    Map<String, dynamic> trainingExtra,
    String muscle,
  ) {
    final raw = trainingExtra[TrainingExtraKeys.weeklyVolumeHistory];
    if (raw is! List) return {};

    final out = <int, WeeklyVolumeRecord>{};

    for (final item in raw) {
      if (item is Map<String, dynamic>) {
        try {
          final rec = WeeklyVolumeRecord.fromMap(item);
          // Filtrar solo el músculo seleccionado
          if (rec.muscleGroup == muscle) {
            // Asumir que el índice de semana viene en el registro
            // Si no, usar índice secuencial
            final weekIndex = item['weekIndex'] as int? ?? (out.length + 1);
            out[weekIndex] = rec;
          }
        } catch (e) {
          // Ignorar registros malformados
        }
      }
    }

    return out;
  }

  /// Carga distribución H/M/L desde Tab 2 (fallback 20/60/20)
  Map<String, int> _loadSeriesSplit(Map<String, dynamic> trainingExtra) {
    final raw = trainingExtra[TrainingExtraKeys.seriesTypePercentSplit];
    if (raw is Map) {
      try {
        final split = {
          'heavy': (raw['heavy'] as num?)?.toInt() ?? 20,
          'medium': (raw['medium'] as num?)?.toInt() ?? 60,
          'light': (raw['light'] as num?)?.toInt() ?? 20,
        };

        // Validar que sume 100, si no usar fallback
        final total = split['heavy']! + split['medium']! + split['light']!;
        if (total == 100) {
          return split;
        }
      } catch (e) {
        // Fallback
      }
    }
    return {'heavy': 20, 'medium': 60, 'light': 20};
  }

  /// Carga baseline de series para un músculo específico
  int _loadBaseSeriesForMuscle(
    Map<String, dynamic> trainingExtra,
    String muscle,
  ) {
    final vopRaw =
        trainingExtra[TrainingExtraKeys.finalTargetSetsByMuscleUi] ??
        trainingExtra['targetSetsByMuscle'];

    if (vopRaw is Map && vopRaw[muscle] is num) {
      return (vopRaw[muscle] as num).toInt();
    }

    return 12; // Fallback conservador para un músculo
  }

  /// Construye lista de 52 semanas para un músculo: real si existe, programado si no
  List<WeeklyVolumeView> _buildAllWeeksForMuscle({
    required String muscle,
    required Map<int, WeeklyVolumeRecord> realWeeks,
    required Map<String, int> split,
    required int baseSeries,
  }) {
    final weeks = <WeeklyVolumeView>[];

    for (int week = 1; week <= 52; week++) {
      if (realWeeks.containsKey(week)) {
        // REAL: usar dato registrado
        final rec = realWeeks[week]!;
        // Inferir patrón desde datos reales comparando con semana anterior
        final pattern = _inferPatternFromReal(rec, weeks);
        weeks.add(
          WeeklyVolumeView(
            weekIndex: week,
            muscle: muscle,
            totalSeries: rec.totalSeries,
            heavySeries: rec.heavySeries,
            mediumSeries: rec.mediumSeries,
            lightSeries: rec.lightSeries,
            source: WeekVolumeSource.real,
            pattern: pattern,
          ),
        );
      } else {
        // PROGRAMADO: calcular conservador con patrón estructural
        final planned = _buildPlannedWeekForMuscle(
          weekIndex: week,
          muscle: muscle,
          baseSeries: baseSeries,
          vopSplit: split,
          previousWeeks: weeks,
        );
        weeks.add(planned);
      }
    }

    return weeks;
  }

  /// Infiere patrón de entrenamiento desde datos reales
  WeekPattern _inferPatternFromReal(
    WeeklyVolumeRecord current,
    List<WeeklyVolumeView> previousWeeks,
  ) {
    if (previousWeeks.isEmpty) return WeekPattern.increase;

    final previous = previousWeeks.last;
    final delta = current.totalSeries - previous.totalSeries;
    final percentChange = (delta / previous.totalSeries * 100);

    // Lógica de inferencia basada en cambio porcentual
    if (percentChange < -15) return WeekPattern.deload; // Reducción >15%
    if (percentChange > 10) return WeekPattern.increase; // Aumento >10%
    if (percentChange.abs() <= 5) return WeekPattern.stable; // Cambio <5%

    // Si hay aumento moderado + ratio de pesadas alto → intensificación
    final heavyRatio = current.heavySeries / current.totalSeries;
    if (heavyRatio > 0.3 && percentChange > 0) {
      return WeekPattern.intensification;
    }

    return WeekPattern.increase;
  }

  /// Infiere patrón estructural programado (cuando no hay datos reales)
  WeekPattern _inferPatternProgrammed(int weekIndex) {
    // Deload cada 4 semanas
    if (weekIndex % 4 == 0) return WeekPattern.deload;

    // Estable cada 3 semanas (si no es deload)
    if (weekIndex % 3 == 0) return WeekPattern.stable;

    // Por defecto: incremento
    return WeekPattern.increase;
  }

  /// Calcula volumen PROGRAMADO para una semana y músculo específico con patrón
  /// Reglas:
  /// - increase: +1 serie
  /// - stable: mantener
  /// - deload: -20%
  /// - intensification: mantener volumen, redistribuir a pesadas
  WeeklyVolumeView _buildPlannedWeekForMuscle({
    required int weekIndex,
    required String muscle,
    required int baseSeries,
    required Map<String, int> vopSplit,
    required List<WeeklyVolumeView> previousWeeks,
  }) {
    // Inferir patrón estructural
    final pattern = _inferPatternProgrammed(weekIndex);

    // Calcular volumen base según la semana anterior o baseline
    final previousTotal = previousWeeks.isNotEmpty
        ? previousWeeks.last.totalSeries
        : baseSeries;

    // Aplicar patrón al volumen
    int total;
    switch (pattern) {
      case WeekPattern.increase:
        total = (previousTotal + 1).clamp(baseSeries, baseSeries * 2).toInt();
        break;
      case WeekPattern.stable:
        total = previousTotal;
        break;
      case WeekPattern.deload:
        total = (previousTotal * 0.8)
            .round()
            .clamp(baseSeries ~/ 2, baseSeries * 2)
            .toInt();
        break;
      case WeekPattern.intensification:
        total = previousTotal; // Mantener volumen
        break;
    }

    // Distribuir según split H/M/L
    int heavy, medium, light;

    if (pattern == WeekPattern.intensification) {
      // Intensificación: más pesadas, menos ligeras
      heavy = (total * 0.4).round(); // 40% pesadas
      medium = (total * 0.5).round(); // 50% medias
      light = total - heavy - medium;
    } else if (pattern == WeekPattern.deload) {
      // Deload: más ligeras, menos pesadas
      heavy = (total * 0.1).round(); // 10% pesadas
      medium = (total * 0.4).round(); // 40% medias
      light = total - heavy - medium;
    } else {
      // Normal: usar split configurado
      heavy = (total * vopSplit['heavy']! / 100).round();
      medium = (total * vopSplit['medium']! / 100).round();
      light = total - heavy - medium;
    }

    return WeeklyVolumeView(
      weekIndex: weekIndex,
      muscle: muscle,
      totalSeries: total,
      heavySeries: heavy,
      mediumSeries: medium,
      lightSeries: light,
      source: WeekVolumeSource.planned,
      pattern: pattern,
    );
  }

  /// Widget badge para mostrar el patrón de entrenamiento
  Widget _buildPatternBadge(WeekPattern pattern) {
    IconData icon;
    Color color;
    String label;
    String tooltip;

    switch (pattern) {
      case WeekPattern.increase:
        icon = Icons.trending_up;
        color = Colors.green;
        label = 'Incremento';
        tooltip = 'Incremento progresivo de volumen';
        break;
      case WeekPattern.stable:
        icon = Icons.trending_flat;
        color = Colors.blue;
        label = 'Estable';
        tooltip = 'Mantenimiento del volumen actual';
        break;
      case WeekPattern.deload:
        icon = Icons.trending_down;
        color = Colors.orange;
        label = 'Descarga';
        tooltip = 'Reducción temporal para recuperación';
        break;
      case WeekPattern.intensification:
        icon = Icons.flash_on;
        color = Colors.red;
        label = 'Intensificación';
        tooltip = 'Aumento de intensidad (más pesadas)';
        break;
    }

    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
