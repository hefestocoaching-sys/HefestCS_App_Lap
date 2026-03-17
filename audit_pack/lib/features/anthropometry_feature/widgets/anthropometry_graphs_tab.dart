import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/domain/entities/anthropometry_record.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hcs_app_lap/utils/widgets/shared_form_widgets.dart';

class AnthropometryGraphsTab extends ConsumerStatefulWidget {
  const AnthropometryGraphsTab({super.key});

  @override
  ConsumerState<AnthropometryGraphsTab> createState() =>
      _AnthropometryGraphsTabState();
}

class _AnthropometryGraphsTabState extends ConsumerState<AnthropometryGraphsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _selectedMetricNotifier = ValueNotifier<String>('weightKg');
  List<int> showingTooltipOnSpots = [];

  final Map<String, String> _metricsResults = {'weightKg': 'Peso (kg)'};
  final Map<String, String> _metricsSkinfolds = {
    'tricipitalFold': 'Pl. Tríceps (mm)',
    'subscapularFold': 'Pl. Subescapular (mm)',
    'suprailiacFold': 'Pl. Suprailíaco (mm)',
    'supraspinalFold': 'Pl. Supraespinal (mm)',
    'abdominalFold': 'Pl. Abdominal (mm)',
    'thighFold': 'Pl. Muslo (mm)',
    'calfFold': 'Pl. Pantorrilla (mm)',
  };
  final Map<String, String> _metricsCircumferences = {
    'armRelaxedCirc': 'Per. Brazo Rel. (cm)',
    'armFlexedCirc': 'Per. Brazo Cont. (cm)',
    'waistCircNarrowest': 'Per. Cintura (cm)',
    'hipCircMax': 'Per. Cadera (cm)',
    'midThighCirc': 'Per. Muslo Medial (cm)',
    'maxCalfCirc': 'Per. Pantorrilla (cm)',
  };
  final Map<String, String> _metricsDiameters = {
    'wristDiameter': 'Diám. Muñeca (cm)',
    'kneeDiameter': 'Diám. Rodilla (cm)',
  };
  late final Map<String, String> _allMetrics;

  @override
  void initState() {
    super.initState();
    _allMetrics = {}
      ..addAll(_metricsResults)
      ..addAll(_metricsSkinfolds)
      ..addAll(_metricsCircumferences)
      ..addAll(_metricsDiameters);
  }

  @override
  void dispose() {
    _selectedMetricNotifier.dispose();
    super.dispose();
  }

  double? _getValue(AnthropometryRecord record, String metricKey) {
    final recordMap = record.toJson();
    return (recordMap[metricKey] as num?)?.toDouble();
  }

  String _getUnit(String key) {
    if (key.contains('kg')) return 'kg';
    if (key.contains('Percentage')) return '%';
    if (key.contains('Circ') || key.contains('Diameter')) return 'cm';
    if (key.contains('Fold') || key.contains('Folds')) return 'mm';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final client = ref.watch(clientsProvider).value?.activeClient;
    if (client == null || client.anthropometry.length < 2) {
      return const Center(
        child: Text(
          "Se necesitan al menos 2 registros antropométricos para graficar.",
          style: TextStyle(color: kTextColorSecondary),
        ),
      );
    }

    final records = client.anthropometry;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          ValueListenableBuilder<String>(
            valueListenable: _selectedMetricNotifier,
            builder: (context, selectedMetric, _) {
              return Column(
                children: [
                  CompactDropdown<String>(
                    title: 'Métrica a Graficar',
                    value: selectedMetric,
                    items: _allMetrics.keys.toList(),
                    itemLabelBuilder: (key) => _allMetrics[key]!,
                    onChanged: (val) {
                      if (val != null) _selectedMetricNotifier.value = val;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 300,
                    child: LineChart(
                      _buildLineChartData(records, selectedMetric),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  LineChartData _buildLineChartData(
    List<AnthropometryRecord> records,
    String metricKey,
  ) {
    final unit = _getUnit(metricKey);
    final List<FlSpot> spots = [];
    double minY = double.infinity;
    double maxY = -double.infinity;

    for (int i = 0; i < records.length; i++) {
      final record = records[i];
      final double? yValue = _getValue(record, metricKey);

      if (yValue != null) {
        spots.add(FlSpot(i.toDouble(), yValue));
        minY = yValue < minY ? yValue : minY;
        maxY = yValue > maxY ? yValue : maxY;
      }
    }

    if (spots.isEmpty) {
      return LineChartData(
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(),
          bottomTitles: AxisTitles(),
          topTitles: AxisTitles(),
          rightTitles: AxisTitles(),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      );
    }

    double yMargin = (maxY - minY) * 0.2;
    if (yMargin == 0 || yMargin.isNaN) yMargin = (maxY * 0.1).abs() + 1.0;
    minY = (minY - yMargin).floorToDouble();
    maxY = (maxY + yMargin).ceilToDouble();

    const gradientColor1 = kPrimaryColor;
    const gradientColor2 = kAccentColor;
    final gradientColor3 = Colors.redAccent.shade100;

    final lineBarData = LineChartBarData(
      showingIndicators: showingTooltipOnSpots,
      spots: spots,
      isCurved: true,
      barWidth: 4,
      shadow: const Shadow(blurRadius: 2),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [
            gradientColor1.withAlpha(102),
            gradientColor2.withAlpha(102),
            gradientColor3.withAlpha(102),
          ],
        ),
      ),
      dotData: const FlDotData(show: false),
      gradient: LinearGradient(
        colors: [gradientColor1, gradientColor2, gradientColor3],
        stops: const [0.1, 0.4, 0.9],
      ),
    );

    return LineChartData(
      showingTooltipIndicators: showingTooltipOnSpots.map((index) {
        return ShowingTooltipIndicators([
          LineBarSpot(lineBarData, 0, lineBarData.spots[index]),
        ]);
      }).toList(),
      lineTouchData: LineTouchData(
        handleBuiltInTouches: false,
        touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
          if (response == null || response.lineBarSpots == null) {
            return;
          }
          if (event is FlTapUpEvent) {
            final spotIndex = response.lineBarSpots!.first.spotIndex;
            setState(() {
              if (showingTooltipOnSpots.contains(spotIndex)) {
                showingTooltipOnSpots.remove(spotIndex);
              } else {
                showingTooltipOnSpots.add(spotIndex);
              }
            });
          }
        },
        mouseCursorResolver: (FlTouchEvent event, LineTouchResponse? response) {
          if (response == null || response.lineBarSpots == null) {
            return SystemMouseCursors.basic;
          }
          return SystemMouseCursors.click;
        },
        getTouchedSpotIndicator:
            (LineChartBarData barData, List<int> spotIndexes) {
              return spotIndexes.map((index) {
                return TouchedSpotIndicatorData(
                  const FlLine(color: kAccentColor),
                  FlDotData(
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(
                          radius: 8,
                          color: lerpGradient(
                            barData.gradient!.colors,
                            barData.gradient!.stops!,
                            percent / 100,
                          ),
                          strokeWidth: 2,
                          strokeColor: kTextColor,
                        ),
                  ),
                );
              }).toList();
            },
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => kAccentColor.withAlpha(204),
          tooltipBorderRadius: BorderRadius.circular(8),
          getTooltipItems: (touchedSpots) =>
              _getTooltipItems(touchedSpots, records, metricKey),
        ),
      ),
      lineBarsData: [lineBarData],
      minY: minY,
      maxY: maxY,
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          axisNameWidget: unit.isEmpty
              ? null
              : Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    unit,
                    style: const TextStyle(
                      color: kTextColorSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
          axisNameSize: 24,
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 45,
            getTitlesWidget: (value, meta) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(
                    color: kTextColorSecondary,
                    fontSize: 10,
                  ),
                ),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: spots.isNotEmpty,
            reservedSize: 32,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final int index = value.toInt();
              if (index < 0 || index >= records.length) {
                return const SizedBox.shrink();
              }
              if (!spots.any((spot) => spot.x == value)) {
                return const SizedBox.shrink();
              }

              final date =
                  '${records[index].date.day.toString().padLeft(2, '0')}/${records[index].date.month.toString().padLeft(2, '0')}/${records[index].date.year.toString().substring(2)}';
              return SideTitleWidget(
                meta: meta,
                space: 4,
                child: Text(
                  date,
                  style: const TextStyle(
                    color: kAccentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              );
            },
          ),
        ),
        topTitles: AxisTitles(
          axisNameWidget: Text(
            _allMetrics[metricKey] ?? 'Evolución',
            style: const TextStyle(
              color: kTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          axisNameSize: 32,
        ),
        rightTitles: const AxisTitles(
          
        ),
      ),
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: kAppBarColor.withAlpha(153)),
      ),
    );
  }

  List<LineTooltipItem> _getTooltipItems(
    List<LineBarSpot> touchedSpots,
    List<AnthropometryRecord> records,
    String metricKey,
  ) {
    return touchedSpots
        .map((barSpot) {
          if (barSpot.spotIndex >= records.length) return null;

          final record = records[barSpot.spotIndex];
          final date =
              '${record.date.day.toString().padLeft(2, '0')}/${record.date.month.toString().padLeft(2, '0')}/${record.date.year}';
          final value = barSpot.y;

          final label = _allMetrics[metricKey] ?? '';
          final unit = label.split('(').last.replaceAll(')', '');

          return LineTooltipItem(
            '$date\n',
            const TextStyle(
              color: kTextColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            children: [
              TextSpan(
                text: '${value.toStringAsFixed(1)} $unit',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          );
        })
        .whereType<LineTooltipItem>()
        .toList();
  }
}

/// Lerps between a [LinearGradient] colors, based on [t]
Color lerpGradient(List<Color> colors, List<double> stops, double t) {
  if (colors.isEmpty) {
    throw ArgumentError('"colors" is empty.');
  } else if (colors.length == 1) {
    return colors[0];
  }

  if (stops.length != colors.length) {
    stops = [];

    /// provided gradientColorStops is invalid and we calculate it here
    colors.asMap().forEach((index, color) {
      final percent = 1.0 / (colors.length - 1);
      stops.add(percent * index);
    });
  }

  for (var s = 0; s < stops.length - 1; s++) {
    final leftStop = stops[s];
    final rightStop = stops[s + 1];
    final leftColor = colors[s];
    final rightColor = colors[s + 1];
    if (t <= leftStop) {
      return leftColor;
    } else if (t < rightStop) {
      final sectionT = (t - leftStop) / (rightStop - leftStop);
      return Color.lerp(leftColor, rightColor, sectionT)!;
    }
  }
  return colors.last;
}
