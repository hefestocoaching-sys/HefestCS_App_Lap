import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hcs_app_lap/core/constants/muscle_labels_es.dart';
import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/domain/entities/weekly_volume_record.dart';
import 'package:hcs_app_lap/domain/models/weekly_volume_view.dart';
import 'package:hcs_app_lap/features/training_feature/context/vop_context.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/utils/widgets/hcs_input_decoration.dart';

/// Tab 3 — Progreso Horizontal por Bloques y Músculos (52 semanas)
///
/// PROPÓSITO:
/// Mostrar automáticamente el progreso semanal de volumen POR MÚSCULO
/// en una vista HORIZONTAL, agrupada por bloques fisiológicos (AA, HF1, HF2, etc).
///
/// UNIDAD DE ANÁLISIS: MÚSCULO (selector dropdown)
/// EJE HORIZONTAL: SEMANAS (scroll horizontal)
/// AGRUPADORES: BLOQUES (AA semanas 1-4, HF1 semanas 5-8, HF2 semanas 9-12, repetir cada 12)
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
/// 3. La vista NUNCA está vacía (siempre muestra 52 semanas)
/// 4. REAL > PROGRAMADO siempre
/// 5. Diferenciación visual: REAL (sólido) vs PROGRAMADO (tenue)
/// 6. Sin botones, sin confirmaciones, sin acciones manuales

/// Modelo de bloque fisiológico (SOLO para visual, no persiste)
class TrainingBlockView {
  final String name; // AA, HF1, HF2, etc
  final int startWeek; // Semana inicial (1-52)
  final int endWeek; // Semana final (1-52)

  TrainingBlockView({
    required this.name,
    required this.startWeek,
    required this.endWeek,
  });
}

class MacrocycleOverviewTab extends StatefulWidget {
  final Map<String, dynamic> trainingExtra;

  const MacrocycleOverviewTab({super.key, required this.trainingExtra});

  @override
  State<MacrocycleOverviewTab> createState() => _MacrocycleOverviewTabState();
}

class _MacrocycleOverviewTabState extends State<MacrocycleOverviewTab> {
  // Mapa UI → claves canónicas (delegado a MuscleRegistry SSOT)
  static const Map<String, List<String>> uiMuscleGroups = {
    'Pecho': ['chest'],
    'Espalda': ['lats', 'upper_back', 'traps'],
    'Hombro': ['deltoide_anterior', 'deltoide_lateral', 'deltoide_posterior'],
    'Bíceps': ['biceps'],
    'Tríceps': ['triceps'],
    'Pierna (Cuádriceps)': ['quads'],
    'Pierna (Isquios)': ['hamstrings'],
    'Glúteo': ['glutes'],
    'Pantorrilla': ['calves'],
    'Abdomen': ['abs'],
  };

  String? _selectedUIGroup;

  @override
  void initState() {
    super.initState();
    _selectedUIGroup = uiMuscleGroups.keys.first;
  }

  @override
  void didUpdateWidget(MacrocycleOverviewTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedUIGroup == null ||
        !uiMuscleGroups.containsKey(_selectedUIGroup)) {
      setState(() {
        _selectedUIGroup = uiMuscleGroups.keys.first;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedUIGroup = _selectedUIGroup ?? uiMuscleGroups.keys.first;
    final musclesInGroup = uiMuscleGroups[selectedUIGroup] ?? [];

    final vopCtx = VopContext.ensure(widget.trainingExtra);
    if (vopCtx == null || !vopCtx.hasData) {
      return _buildErrorState(
        context,
        message:
            'No hay VOP definido. Configura volumen en la pestaña Volumen.',
        icon: Icons.error_outline,
        color: Colors.red,
      );
    }

    // Debug temporal para validar SSOT canonico
    debugPrint(
      '[VOP][SSOT] keys=${vopCtx.snapshot.setsByMuscle.keys.toList()}',
    );

    final split = _loadSeriesSplit();
    final missing = <String>[];
    final muscleWeeks = <String, List<WeeklyVolumeView>>{};
    var hasRealData = false;

    final currentWeekIndex = _calculateCurrentWeek();
    final blockStartWeek = ((currentWeekIndex - 1) ~/ 4) * 4 + 1;
    final visibleWeeks = List.generate(4, (i) => blockStartWeek + i);

    for (final muscle in musclesInGroup) {
      final sets = vopCtx.getSetsFor(muscle);
      if (sets == null || sets <= 0) {
        missing.add(muscle);
        continue;
      }

      final realRecords = _loadRealWeeksForMuscle(muscle);
      if (realRecords.isNotEmpty) {
        hasRealData = true;
      }

      final realWeeksByIndex = <int, WeeklyVolumeRecord>{};
      for (final record in realRecords) {
        final weekNum = _extractWeekNumber(record.weekStartIso);
        realWeeksByIndex[weekNum] = record;
      }

      final allWeeks = _buildAllWeeksForGroup(
        group: muscle,
        muscles: [muscle],
        realWeeks: realWeeksByIndex,
        split: split,
        baseSeries: sets,
      );

      final weeksToRender = allWeeks
          .where((w) => visibleWeeks.contains(w.weekIndex))
          .toList();

      muscleWeeks[muscle] = weeksToRender;
    }

    if (musclesInGroup.isEmpty || missing.isNotEmpty) {
      return _buildErrorState(
        context,
        message: missing.isEmpty
            ? 'No hay músculos seleccionados para este grupo.'
            : 'Falta VOP para: ${missing.map(muscleLabelEs).join(', ')}. Configura en Tab Volumen.',
        icon: Icons.warning_amber_rounded,
        color: Colors.orange,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, hasRealData: hasRealData),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 320,
                child: _buildMuscleSelector(context, selectedUIGroup),
              ),
              const SizedBox(width: 16),
              Expanded(child: _buildLegend(context)),
            ],
          ),
          const SizedBox(height: 12),
          ...muscleWeeks.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildActiveBlockView(
                context,
                entry.value,
                muscleLabelEs(entry.key),
                currentWeekIndex,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Header con descripción
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
              Icon(Icons.timeline, color: Colors.teal, size: 20),
              SizedBox(width: 8),
              Text(
                'Macrociclo de Volumen (52 semanas)',
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
                ? 'Progresión teórica ajustada por datos reales de la bitácora.'
                : 'Esta es una guía estructural de progresión. Se ajusta automáticamente al registrar bitácora.',
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
              '🔄 Automático: bloques fisiológicos (AA/HF1/HF2) con progresión conservadora.',
              style: TextStyle(color: kTextColorSecondary, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color color,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, hasRealData: false),
          const SizedBox(height: 12),
          _buildErrorBanner(message: message, icon: icon, color: color),
        ],
      ),
    );
  }

  Widget _buildErrorBanner({
    required String message,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: kTextColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Selector de grupo muscular UI
  Widget _buildMuscleSelector(BuildContext context, String selectedUIGroup) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.fitness_center, size: 18, color: Colors.teal),
                SizedBox(width: 8),
                Text(
                  'Grupo Muscular:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: selectedUIGroup,
              isExpanded: true,
              decoration: hcsDecoration(
                context,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: uiMuscleGroups.keys.map((group) {
                return DropdownMenuItem(
                  value: group,
                  child: Text(group, style: const TextStyle(fontSize: 12)),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedUIGroup = newValue;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Vista en grilla 2×2 para bloques
  /// Vista de bloque activo (solo 4 semanas)
  Widget _buildActiveBlockView(
    BuildContext context,
    List<WeeklyVolumeView> weeksToRender,
    String groupName,
    int currentWeekIndex,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$groupName - Semana $currentWeekIndex (Bloque Actual)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Chip(
                  label: const Text(
                    '4 Semanas',
                    style: TextStyle(fontSize: 11),
                  ),
                  backgroundColor: Colors.teal.withValues(alpha: 0.1),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 4 columnas fijas sin scroll
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: weeksToRender.isEmpty
                  ? [
                      Text(
                        'No hay datos disponibles',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ]
                  : weeksToRender
                        .map((week) => _buildWeekColumn(context, week))
                        .toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Columna de semana (para bloque activo)
  Widget _buildWeekColumn(BuildContext context, WeeklyVolumeView week) {
    final isReal = week.source == WeekVolumeSource.real;
    final isAuto = week.source == WeekVolumeSource.auto;

    Color color;
    double opacity;

    if (isReal) {
      color = Colors.teal;
      opacity = 1.0;
    } else if (isAuto) {
      color = Colors.blue;
      opacity = 0.6; // intermedio entre PLAN y REAL
    } else {
      color = Colors.grey;
      opacity = 0.5; // PLAN es más tenue
    }

    return Expanded(
      child: Tooltip(
        message: _buildTooltip(week),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: color.withValues(alpha: opacity * 0.4),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(8),
            color: color.withValues(alpha: opacity * 0.08),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Número de semana
              Text(
                'S${week.weekIndex}',
                style: const TextStyle(
                  fontSize: 10,
                  color: kTextColorSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              // Series totales (número grande)
              Text(
                week.totalSeries.toString(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color.withValues(alpha: opacity),
                ),
              ),
              const SizedBox(height: 4),
              // Distribución H/M/L
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          week.heavySeries.toString(),
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.red.withValues(alpha: opacity),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text('H', style: TextStyle(fontSize: 8)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          week.mediumSeries.toString(),
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.amber.withValues(alpha: opacity),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text('M', style: TextStyle(fontSize: 8)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          week.lightSeries.toString(),
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.green.withValues(alpha: opacity),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text('L', style: TextStyle(fontSize: 8)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Indicador REAL/AUTO/PLAN
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: opacity * 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  isReal
                      ? 'REAL'
                      : isAuto
                      ? 'AUTO'
                      : 'PLAN',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: color.withValues(alpha: opacity),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Celda semanal (lo mínimo y potente)
  /// Ícono visual del patrón de la semana
  /// Tooltip con detalles de la semana
  String _buildTooltip(WeeklyVolumeView week) {
    final sourceLabel = switch (week.source) {
      WeekVolumeSource.real => 'REAL (Bitácora)',
      WeekVolumeSource.auto => 'AUTO (Fallback Motor / Adaptado)',
      WeekVolumeSource.planned => 'PLAN (Baseline sin adaptación)',
    };

    final weekInBlock = _getWeekInBlock(week.weekIndex);
    final adaptationNote = weekInBlock == 1
        ? '\n📌 Semana 1: Baseline fijo, sin adaptación.'
        : week.source == WeekVolumeSource.auto
        ? '\n📌 Adaptado por bitácora previa o fallback motor.'
        : '';

    return '''
Semana ${week.weekIndex} (Posición $weekInBlock en bloque)
$sourceLabel

Patrón: ${_patternLabel(week.pattern)}

Total: ${week.totalSeries} series
  Pesadas: ${week.heavySeries}
  Medias: ${week.mediumSeries}
  Ligeras: ${week.lightSeries}$adaptationNote
    ''';
  }

  /// Etiqueta en español del patrón
  String _patternLabel(WeekPattern pattern) {
    switch (pattern) {
      case WeekPattern.increase:
        return 'Incremento';
      case WeekPattern.stable:
        return 'Estable';
      case WeekPattern.deload:
        return 'Descarga';
      case WeekPattern.intensification:
        return 'Intensificación';
    }
  }

  /// Leyenda de colores y significados
  Widget _buildLegend(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Leyenda', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            // Fuentes de datos
            const Text(
              'Fuentes:',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                const Text('REAL (bitácora)', style: TextStyle(fontSize: 10)),
              ],
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'AUTO (adaptado motor)',
                  style: TextStyle(fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'PLAN (baseline sin adaptar)',
                  style: TextStyle(fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Patrones
            const Text(
              'Patrones:',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Row(
              children: [
                Icon(Icons.trending_up, size: 14, color: Colors.green),
                SizedBox(width: 6),
                Text('Incremento', style: TextStyle(fontSize: 10)),
                SizedBox(width: 16),
                Icon(Icons.trending_flat, size: 14, color: Colors.blue),
                SizedBox(width: 6),
                Text('Estable', style: TextStyle(fontSize: 10)),
              ],
            ),
            const SizedBox(height: 4),
            const Row(
              children: [
                Icon(Icons.trending_down, size: 14, color: Colors.orange),
                SizedBox(width: 6),
                Text('Descarga', style: TextStyle(fontSize: 10)),
                SizedBox(width: 16),
                Icon(Icons.flash_on, size: 14, color: Colors.red),
                SizedBox(width: 6),
                Text('Intensificación', style: TextStyle(fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LÓGICA DE ADAPTACIÓN CONSERVADORA POR BITÁCORA (AA)
  // ============================================================

  /// Obtiene la posición de una semana dentro de su bloque de 4 semanas.
  /// Ejemplo: semana 1-4 → 1-4; semana 5-8 → 1-4; semana 9-12 → 1-4, etc.
  int _getWeekInBlock(int weekIndex) {
    return ((weekIndex - 1) % 4) + 1;
  }

  /// Determina si una semana dentro del bloque AA puede ser adaptada por bitácora.
  ///
  /// REGLA: Semana 1 nunca adapta (baseline fijo).
  /// Desde Semana 2, puede adaptarse si existe bitácora válida de S-1.
  bool _canAdaptWeek(int weekInBlock) {
    return weekInBlock >= 2;
  }

  /// Resuelve la cantidad de series para una semana:
  /// - S1: baseline fijo (sin adaptación)
  /// - S2+: bitácora si existe, fallback a programado si no
  ///
  /// [weekInBlock]: 1-4 (semana dentro del bloque AA)
  /// [baseVop]: baseline de series (desde VOP de Tab 2)
  /// [prevRealRecord]: dato REAL de bitácora de la semana anterior (o null si no existe)
  /// [split]: distribución H/M/L
  ///
  /// Returns: (totalSeries, heavySeries, mediumSeries, lightSeries, source)
  ({int total, int heavy, int medium, int light, WeekVolumeSource source})
  _resolveWeeklySeries({
    required int weekInBlock,
    required int baseVop,
    required WeeklyVolumeRecord? prevRealRecord,
    required Map<String, int> split,
  }) {
    // Regla R1: Semana 1 nunca adapta
    if (weekInBlock == 1) {
      final heavy = (baseVop * split['heavy']! / 100).round();
      final medium = (baseVop * split['medium']! / 100).round();
      final light = baseVop - heavy - medium;
      return (
        total: baseVop,
        heavy: heavy,
        medium: medium,
        light: light,
        source: WeekVolumeSource.planned,
      );
    }

    // Regla R2: Desde S2, requiere bitácora previa válida
    if (!_canAdaptWeek(weekInBlock) || prevRealRecord == null) {
      // Fallback: generar programado sin adaptación (marcar como AUTO)
      final total = baseVop + (weekInBlock - 1);
      final heavy = (total * split['heavy']! / 100).round();
      final medium = (total * split['medium']! / 100).round();
      final light = total - heavy - medium;
      return (
        total: total,
        heavy: heavy,
        medium: medium,
        light: light,
        source: WeekVolumeSource.auto, // Fallback motor
      );
    }

    // Adaptación conservadora basada en bitácora de S-1
    final adaptedTotal = _applyConservativeAdaptation(
      base: baseVop,
      prevLog: prevRealRecord,
    );

    final heavy = (adaptedTotal * split['heavy']! / 100).round();
    final medium = (adaptedTotal * split['medium']! / 100).round();
    final light = adaptedTotal - heavy - medium;

    return (
      total: adaptedTotal,
      heavy: heavy,
      medium: medium,
      light: light,
      source: WeekVolumeSource.auto, // AUTO-adaptado por bitácora previa
    );
  }

  /// Aplica adaptación conservadora basada en bitácora anterior.
  ///
  /// Reglas de adaptación (MÁXIMO +1 en AA):
  /// 1. Si hay dolor o adherencia < 70% → reducir -1 serie (mín 6)
  /// 2. Si adherencia ≥ 85% Y RIR promedio > targetRIR + 1 → aumentar +1 serie
  /// 3. Sino → mantener baseline
  int _applyConservativeAdaptation({
    required int base,
    required WeeklyVolumeRecord prevLog,
  }) {
    // Extraer datos de bitácora previa
    // Nota: WeeklyVolumeRecord no tiene adherencia/RIR directamente,
    // pero podemos inferir del volumen total realizado vs esperado.

    // SIMPLIFICACIÓN: Usar volumen como proxy de adherencia
    // Si totalSeries fue 0 → no completó (adherencia baja)
    // Si totalSeries >= base * 0.85 → buena adherencia
    // Si totalSeries >= base + (base * 0.1) → excelente adherencia

    if (prevLog.totalSeries == 0) {
      // Sin datos = sin adherencia
      return max(base - 1, 6);
    }

    final adherenceRatio = prevLog.totalSeries / base;

    // Excelente ejecución: aumentar +1
    if (adherenceRatio >= 1.1) {
      return base + 1;
    }

    // Buena ejecución: mantener
    if (adherenceRatio >= 0.85) {
      return base;
    }

    // Ejecución pobre: reducir -1
    return max(base - 1, 6);
  }

  // ============================================================
  // FUNCIONES AUXILIARES DE LÓGICA
  // ============================================================

  /// Obtener lista de músculos disponibles (desde VOP + historial)
  /// Cargar distribución H/M/L (fallback 20/60/20)
  Map<String, int> _loadSeriesSplit() {
    final split =
        widget.trainingExtra[TrainingExtraKeys.seriesTypePercentSplit]
            as Map<String, dynamic>?;

    if (split != null &&
        split.containsKey('heavy') &&
        split.containsKey('medium') &&
        split.containsKey('light')) {
      return {
        'heavy': (split['heavy'] as num).toInt(),
        'medium': (split['medium'] as num).toInt(),
        'light': (split['light'] as num).toInt(),
      };
    }

    // Fallback: 20/60/20
    return {'heavy': 20, 'medium': 60, 'light': 20};
  }

  /// Cargar datos reales del historial para un músculo
  List<WeeklyVolumeRecord> _loadRealWeeksForMuscle(String muscle) {
    final history =
        widget.trainingExtra[TrainingExtraKeys.weeklyVolumeHistory] as List?;

    if (history == null) return [];

    return history
        .whereType<Map<String, dynamic>>()
        .map((item) {
          try {
            return WeeklyVolumeRecord(
              weekStartIso: item['weekStartIso']?.toString() ?? '',
              muscleGroup: item['muscleGroup']?.toString() ?? '',
              totalSeries: (item['totalSeries'] as num).toInt(),
              heavySeries: (item['heavySeries'] as num).toInt(),
              mediumSeries: (item['mediumSeries'] as num).toInt(),
              lightSeries: (item['lightSeries'] as num).toInt(),
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<WeeklyVolumeRecord>()
        .where((r) => r.muscleGroup == muscle)
        .toList();
  }

  /// Inferir patrón fisiológico teórico (GUÍA, NO PROMESA)
  WeekPattern _inferPatternProgrammed(int weekIndex) {
    if (weekIndex % 4 == 0) {
      return WeekPattern.deload; // Descarga cada 4 semanas
    }
    if (weekIndex % 3 == 0) {
      return WeekPattern.stable; // Estable cada 3 semanas
    }
    return WeekPattern.increase; // Por defecto, incremento
  }

  /// Construir todas las 52 semanas para un grupo de músculos.
  /// Usa datos reales del historial si existen, fallback a valores programados.
  List<WeeklyVolumeView> _buildAllWeeksForGroup({
    required String group,
    required List<String> muscles,
    required Map<int, WeeklyVolumeRecord> realWeeks,
    required Map<String, int> split,
    required int baseSeries,
  }) {
    final weeks = <WeeklyVolumeView>[];

    for (int week = 1; week <= 52; week++) {
      // Buscar si existe dato real para esta semana y este grupo
      final realRecord = realWeeks[week];

      late int totalSeries;
      late int heavySeries;
      late int mediumSeries;
      late int lightSeries;
      late WeekVolumeSource source;

      if (realRecord != null) {
        // Usar dato real de bitácora
        totalSeries = realRecord.totalSeries;
        heavySeries = realRecord.heavySeries;
        mediumSeries = realRecord.mediumSeries;
        lightSeries = realRecord.lightSeries;
        source = WeekVolumeSource.real;
      } else {
        // Generar programado: usar base + adaptación por semana dentro del bloque
        final weekInBlock = _getWeekInBlock(week);
        final prevWeekReal = week > 1 ? realWeeks[week - 1] : null;

        final resolved = _resolveWeeklySeries(
          weekInBlock: weekInBlock,
          baseVop: baseSeries,
          prevRealRecord: prevWeekReal,
          split: split,
        );

        totalSeries = resolved.total;
        heavySeries = resolved.heavy;
        mediumSeries = resolved.medium;
        lightSeries = resolved.light;
        source = resolved.source;
      }

      final pattern = realRecord != null
          ? _inferPatternFromReal(
              totalSeries,
              previousTotalSeries: week > 1
                  ? (realWeeks[week - 1]?.totalSeries)
                  : null,
            )
          : _inferPatternProgrammed(week);

      weeks.add(
        WeeklyVolumeView(
          weekIndex: week,
          muscle: group,
          totalSeries: totalSeries,
          heavySeries: heavySeries,
          mediumSeries: mediumSeries,
          lightSeries: lightSeries,
          pattern: pattern,
          source: source,
        ),
      );
    }

    return weeks;
  }

  /// Inferir patrón a partir de dato REAL (cambio vs semana previa)
  WeekPattern _inferPatternFromReal(
    int totalSeries, {
    int? previousTotalSeries,
  }) {
    // Lógica básica: si no hay historia previa, asumir increase
    if (previousTotalSeries == null) return WeekPattern.increase;

    final delta = totalSeries - previousTotalSeries;
    final percentChange = (delta / previousTotalSeries) * 100;

    if (percentChange < -15) return WeekPattern.deload;
    if (percentChange > 10) return WeekPattern.increase;
    return WeekPattern.stable;
  }

  /// Calcular semana actual del año
  int _calculateCurrentWeek() {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year);
    final daysSinceStart = now.difference(startOfYear).inDays;
    final weekIndex = (daysSinceStart ~/ 7) + 1;
    return weekIndex.clamp(1, 52);
  }

  /// Extraer número de semana del año desde fecha ISO (weekStartIso)
  int _extractWeekNumber(String weekStartIso) {
    try {
      final date = DateTime.parse(weekStartIso);
      final startOfYear = DateTime(date.year);
      final daysSinceStart = date.difference(startOfYear).inDays;
      final weekIndex = (daysSinceStart ~/ 7) + 1;
      return weekIndex.clamp(1, 52);
    } catch (_) {
      // Fallback si no se puede parsear la fecha
      return 1;
    }
  }

  /// Generar bloques fisiológicos (AA, HF1, HF2, etc)
}
