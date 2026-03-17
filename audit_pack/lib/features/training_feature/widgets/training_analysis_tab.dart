// ignore_for_file: deprecated_member_use_from_same_package
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:hcs_app_lap/utils/widgets/hcs_input_decoration.dart';

import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/training_evaluation.dart';
import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';

enum _TabMode { idle, view, editing, creating }

class TrainingAnalysisTab extends ConsumerStatefulWidget {
  const TrainingAnalysisTab({super.key});

  @override
  ConsumerState<TrainingAnalysisTab> createState() =>
      _TrainingAnalysisTabState();
}

class _TrainingAnalysisTabState extends ConsumerState<TrainingAnalysisTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  _TabMode _mode = _TabMode.idle;
  DateTime? _selectedDate;
  TextEditingController? _avgRpeController;
  TextEditingController? _avgDomsController;
  TextEditingController? _sleepQualityController;
  TextEditingController? _stressLevelController;
  TextEditingController? _feedbackController;
  TextEditingController? _adherenceController;

  @override
  void initState() {
    super.initState();
    _avgRpeController = TextEditingController();
    _avgDomsController = TextEditingController();
    _sleepQualityController = TextEditingController();
    _stressLevelController = TextEditingController();
    _feedbackController = TextEditingController();
    _adherenceController = TextEditingController();
  }

  @override
  void dispose() {
    _avgRpeController?.dispose();
    _avgDomsController?.dispose();
    _sleepQualityController?.dispose();
    _stressLevelController?.dispose();
    _feedbackController?.dispose();
    _adherenceController?.dispose();
    super.dispose();
  }

  // ===================================================================
  // HELPERS
  // ===================================================================
  List<TrainingEvaluation> _readRecords(Client? client) {
    if (client == null) return [];
    final raw =
        client.training.extra[TrainingExtraKeys.trainingEvaluationRecords];
    if (raw == null) return [];
    if (raw is! List) return [];
    return raw
        .map((e) {
          try {
            return TrainingEvaluation.fromJson(e as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<TrainingEvaluation>()
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  void _clearForm() {
    _avgRpeController?.clear();
    _avgDomsController?.clear();
    _sleepQualityController?.clear();
    _stressLevelController?.clear();
    _feedbackController?.clear();
    _adherenceController?.clear();
  }

  // ===================================================================
  // STATE MACHINE
  // ===================================================================
  void _loadRecordInViewMode(TrainingEvaluation record) {
    setState(() {
      _mode = _TabMode.view;
      _selectedDate = record.date;
      _avgRpeController!.text = record.avgRpe?.toString() ?? '';
      _avgDomsController!.text = record.avgDoms?.toString() ?? '';
      _sleepQualityController!.text = record.sleepQuality?.toString() ?? '';
      _stressLevelController!.text = record.stressLevel?.toString() ?? '';
      _feedbackController!.text = record.feedback ?? '';
      _adherenceController!.text = record.adherencePercentage != null
          ? (record.adherencePercentage! * 100).toStringAsFixed(0)
          : '';
    });
  }

  // ===================================================================
  // BUILD
  // ===================================================================
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final clientsAsync = ref.watch(clientsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: clientsAsync.when(
                data: (state) {
                  final client = state.activeClient;
                  return _buildContent(client);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text("Error: $e")),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Client? client) {
    if (client == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assessment_outlined, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text(
              "Selecciona un cliente o crea uno nuevo",
              style: TextStyle(color: kTextColorSecondary),
            ),
          ],
        ),
      );
    }

    final records = _readRecords(client);
    final latestRecord = records.isNotEmpty ? records.first : null;
    final hasNoRecords = records.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_mode == _TabMode.idle) _buildHistorialGrid(records),
        if (_mode != _TabMode.idle) ...[
          _buildContextBar(),
          const SizedBox(height: 24),
          _buildContextBar(),
          const SizedBox(height: 24),
          _buildEstadoActualCard(latestRecord, hasNoRecords),
          const SizedBox(height: 24),
          if (_mode == _TabMode.creating) ...[
            _buildNuevoRegistroCard(),
            const SizedBox(height: 24),
          ],
          if (_mode == _TabMode.editing || _mode == _TabMode.creating) ...[
            _buildFormulario(),
            const SizedBox(height: 24),
          ],
        ],
      ],
    );
  }

  // ===================================================================
  // HISTORIAL GRID CON NUEVO REGISTRO TILE
  // ===================================================================
  Widget _buildHistorialGrid(List<TrainingEvaluation> records) {
    final sortedRecords = [...records]
      ..sort((a, b) => b.date.compareTo(a.date));

    List<Widget> tiles = [
      InkWell(
        onTap: () {
          setState(() {
            _mode = _TabMode.creating;
            _selectedDate = null;
            _clearForm();
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kPrimaryColor.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kPrimaryColor.withAlpha(80), width: 1.5),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 36, color: kPrimaryColor),
              SizedBox(height: 8),
              Text(
                'Nuevo registro',
                style: TextStyle(
                  color: kPrimaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ];

    tiles.addAll(
      sortedRecords.map((record) {
        final isSelected =
            _selectedDate != null &&
            DateUtils.isSameDay(_selectedDate, record.date);
        final day = DateFormat('d').format(record.date);
        final monthYear = DateFormat(
          'MMM yyyy',
          'es',
        ).format(record.date).toUpperCase();
        return InkWell(
          onTap: () => _loadRecordInViewMode(record),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 160,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? kPrimaryColor.withAlpha(51)
                  : kCardColor.withAlpha(100),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? kPrimaryColor : Colors.white.withAlpha(20),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: isSelected ? kPrimaryColor : kTextColorSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      day,
                      style: TextStyle(
                        color: isSelected ? kPrimaryColor : kTextColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  monthYear,
                  style: const TextStyle(
                    color: kTextColorSecondary,
                    fontSize: 12,
                  ),
                ),
                const Divider(color: Colors.white10, height: 16),
                _buildTrainingMetric(
                  'RPE',
                  record.avgRpe?.toStringAsFixed(1) ?? '—',
                ),
                const SizedBox(height: 4),
                _buildTrainingMetric(
                  'Adherencia',
                  record.adherencePercentage != null
                      ? '${(record.adherencePercentage! * 100).toStringAsFixed(0)}%'
                      : '—',
                ),
              ],
            ),
          ),
        );
      }),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Wrap(spacing: 12, runSpacing: 12, children: tiles),
    );
  }

  Widget _buildTrainingMetric(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: kTextColorSecondary, fontSize: 11),
        ),
        Text(
          value,
          style: const TextStyle(
            color: kTextColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildContextBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _mode == _TabMode.creating
            ? 'CREANDO NUEVO REGISTRO'
            : _mode == _TabMode.editing
            ? 'EDITANDO REGISTRO'
            : 'VIENDO REGISTRO',
        style: const TextStyle(
          color: kPrimaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEstadoActualCard(
    TrainingEvaluation? latestRecord,
    bool hasNoRecords,
  ) {
    if (hasNoRecords) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'Sin registros de entrenamiento',
          style: TextStyle(color: kTextColorSecondary),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Registro más reciente: ${DateFormat('yyyy-MM-dd').format(latestRecord!.date)}',
        style: const TextStyle(color: kTextColor),
      ),
    );
  }

  Widget _buildNuevoRegistroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kPrimaryColor.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        'NUEVO REGISTRO',
        style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildFormulario() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Formulario de entrenamiento',
            style: TextStyle(
              color: kPrimaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _avgRpeController,
            decoration: hcsDecoration(context, labelText: 'RPE Promedio'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _adherenceController,
            decoration: hcsDecoration(context, labelText: 'Adherencia (%)'),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }
}
