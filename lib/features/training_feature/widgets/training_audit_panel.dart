import 'package:flutter/material.dart';
import 'package:hcs_app_lap/domain/entities/training_plan_config.dart';
import 'package:hcs_app_lap/features/training_feature/utils/audit_helpers.dart';
import 'package:hcs_app_lap/utils/widgets/hcs_input_decoration.dart';

/// Widget colapsable para auditoría del motor de entrenamiento
class TrainingAuditPanel extends StatefulWidget {
  final TrainingPlanConfig? planConfig;
  final List<Map<String, dynamic>>? decisionTrace;
  final Map<String, dynamic>? metrics;
  final String? generatedAtIso;

  const TrainingAuditPanel({
    super.key,
    this.planConfig,
    this.decisionTrace,
    this.metrics,
    this.generatedAtIso,
  });

  @override
  State<TrainingAuditPanel> createState() => _TrainingAuditPanelState();
}

class _TrainingAuditPanelState extends State<TrainingAuditPanel> {
  final _phaseFilter = <int>{};
  final _searchController = TextEditingController();
  late List<int> _expandedPanels;

  @override
  void initState() {
    super.initState();
    _expandedPanels = [0]; // Primer panel expandido por defecto
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredTrace() {
    if (widget.decisionTrace == null) return [];
    var filtered = widget.decisionTrace!;

    if (_phaseFilter.isNotEmpty) {
      filtered = filtered
          .where((t) => _phaseFilter.contains(_parsePhaseNumber(t['phase'])))
          .toList();
    }

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((t) {
        final desc = (t['description'] ?? '').toString().toLowerCase();
        final cat = (t['category'] ?? '').toString().toLowerCase();
        return desc.contains(query) || cat.contains(query);
      }).toList();
    }

    return filtered;
  }

  int _parsePhaseNumber(String? phase) {
    if (phase == null) return 0;
    final match = RegExp(r'Phase(\d+)').firstMatch(phase);
    return match != null ? int.parse(match.group(1)!) : 0;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.planConfig == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: ExpansionPanelList(
        expandedHeaderPadding: EdgeInsets.zero,
        expansionCallback: (panelIndex, isExpanded) {
          setState(() {
            if (isExpanded) {
              _expandedPanels.remove(panelIndex);
            } else {
              _expandedPanels.add(panelIndex);
            }
          });
        },
        children: [
          // Panel 1: Resumen del Plan
          ExpansionPanel(
            headerBuilder: (context, isExpanded) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Resumen del Plan',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              );
            },
            body: _buildPlanSummary(),
            isExpanded: _expandedPanels.contains(0),
          ),
          // Panel 2: Métricas de ejecución
          ExpansionPanel(
            headerBuilder: (context, isExpanded) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Métricas de ejecución',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              );
            },
            body: _buildMetrics(),
            isExpanded: _expandedPanels.contains(1),
          ),
          // Panel 3: Decision Trace
          ExpansionPanel(
            headerBuilder: (context, isExpanded) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Decision Trace (${widget.decisionTrace?.length ?? 0} items)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              );
            },
            body: _buildDecisionTrace(),
            isExpanded: _expandedPanels.contains(2),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSummary() {
    final plan = widget.planConfig!;
    final totalSets = computeTotalSetsByMuscle(plan);
    final frequency = computeWeeklyMuscleFrequency(plan);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Plan ID', plan.id),
          _buildInfoRow('Semanas', '${plan.weeks.length}'),
          _buildInfoRow(
            'Sesiones totales',
            '${plan.weeks.fold<int>(0, (sum, w) => sum + w.sessions.length)}',
          ),
          const SizedBox(height: 16),
          Text(
            'Sets por músculo:',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          ...totalSets.entries.map(
            (e) => _buildInfoRow(e.key, '${e.value} sets'),
          ),
          const SizedBox(height: 16),
          Text(
            'Frecuencia semanal (sesiones/semana):',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          ...frequency.entries.map(
            (e) => _buildInfoRow(e.key, '${e.value}x/semana'),
          ),
        ],
      ),
    );
  }

  Widget _buildMetrics() {
    final metrics = widget.metrics ?? {};
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Generado en', widget.generatedAtIso ?? 'N/A'),
          _buildInfoRow(
            'Adherencia (logs)',
            ((metrics['adherenceFromLogs'] as num?)?.toStringAsFixed(2) ??
                'N/A'),
          ),
          _buildInfoRow(
            'RPE promedio (logs)',
            ((metrics['avgRpeFromLogs'] as num?)?.toStringAsFixed(1) ?? 'N/A'),
          ),
          const SizedBox(height: 12),
          Text(
            'Señales detectadas:',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(buildSignalsSummary(metrics)),
          ),
        ],
      ),
    );
  }

  Widget _buildDecisionTrace() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filtros por fase
          Text(
            'Filtrar por fase:',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Wrap(
              spacing: 8,
              children: List.generate(8, (i) {
                final phase = i + 1;
                return FilterChip(
                  label: Text('Phase $phase'),
                  selected: _phaseFilter.contains(phase),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _phaseFilter.add(phase);
                      } else {
                        _phaseFilter.remove(phase);
                      }
                    });
                  },
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          // Búsqueda
          TextField(
            controller: _searchController,
            decoration: hcsDecoration(
              context,
              hintText: 'Buscar por keyword...',
              prefixIcon: const Icon(Icons.search),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onChanged: (_) {
              setState(() {});
            },
          ),
          const SizedBox(height: 12),
          // Lista de traces
          ..._getFilteredTrace().map((trace) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${trace['phase'] ?? 'Unknown'} / ${trace['category'] ?? 'Unknown'}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trace['description'] ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (trace['context'] != null) ...[
                      const SizedBox(height: 8),
                      _buildJsonTree(trace['context']),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildJsonTree(dynamic data, {int depth = 0}) {
    if (data == null) return const Text('null');
    if (data is String || data is num || data is bool) {
      return Text(
        data.toString(),
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    if (data is List) {
      return Text(
        '[${data.length} items]',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    if (data is Map) {
      return Padding(
        padding: EdgeInsets.only(left: 16.0 * depth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: data.entries
              .take(5) // Mostrar máximo 5 entries
              .map(
                (e) => Text(
                  '${e.key}: ${_valueToString(e.value)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
              .toList(),
        ),
      );
    }
    return const Text('...');
  }

  String _valueToString(dynamic value) {
    if (value is String || value is num || value is bool) {
      return value.toString();
    }
    if (value is List) {
      return '[${value.length} items]';
    }
    if (value is Map) {
      return '{${value.length} keys}';
    }
    return 'N/A';
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
