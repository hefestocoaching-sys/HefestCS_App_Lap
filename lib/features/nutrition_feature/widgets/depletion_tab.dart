import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/core/enums/gender.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/anthropometry_record.dart';
import 'package:hcs_app_lap/domain/entities/daily_tracking_record.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/features/main_shell/providers/global_date_provider.dart';
import 'package:hcs_app_lap/utils/peak_logic_pro.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/utils/save_messages.dart';
import 'package:hcs_app_lap/utils/widgets/record_history_panel.dart';
import 'package:hcs_app_lap/utils/record_helpers.dart';
import 'package:hcs_app_lap/utils/widgets/clinical_context_bar.dart';
import 'package:hcs_app_lap/utils/widgets/hcs_input_decoration.dart';
import 'package:intl/intl.dart';

extension DailyTrackingRecordFromAnthropometry on DailyTrackingRecord {
  static DailyTrackingRecord fromAnthropometry(AnthropometryRecord data) {
    return DailyTrackingRecord(
      date: data.date,
      weightKg: data.weightKg,
      abdominalFold: data.abdominalFold,
      waistCircNarrowest: data.waistCircNarrowest,
      urineColor: null,
    );
  }
}

class DepletionTab extends ConsumerStatefulWidget {
  const DepletionTab({super.key});

  @override
  ConsumerState<DepletionTab> createState() => _DepletionTabState();
}

class _DepletionTabState extends ConsumerState<DepletionTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String? _clientKey;
  late final ValueNotifier<List<DateTime>> _peakWeekDatesNotifier;
  late final ValueNotifier<Map<String, DailyTrackingRecord>>
  _fullTimelineNotifier;
  late final ValueNotifier<Map<String, Map<String, dynamic>>>
  _visualFeedbackNotifier;

  @override
  void initState() {
    super.initState();
    _peakWeekDatesNotifier = ValueNotifier<List<DateTime>>([]);
    _fullTimelineNotifier = ValueNotifier<Map<String, DailyTrackingRecord>>({});
    _visualFeedbackNotifier = ValueNotifier<Map<String, Map<String, dynamic>>>(
      {},
    );
    final client = ref.read(clientsProvider).value?.activeClient;
    _clientKey = client != null ? _clientKeyFor(client) : null;
    _rebuildTimeline(client);
  }

  @override
  void dispose() {
    _peakWeekDatesNotifier.dispose();
    _fullTimelineNotifier.dispose();
    _visualFeedbackNotifier.dispose();
    super.dispose();
  }

  DateTime? _getCompetitionDate(Client client) {
    final raw =
        client.training.extra[TrainingExtraKeys.competitionDateIso] ??
        client.training.extra[TrainingExtraKeys.competitionDateLegacy];
    if (raw == null) return null;

    try {
      if (raw is DateTime) {
        return DateUtils.dateOnly(raw);
      }

      if (raw is String) {
        if (raw.trim().isEmpty) return null;
        final parsed = DateTime.tryParse(raw);
        if (parsed != null) {
          return DateUtils.dateOnly(parsed);
        }
      }
    } catch (e) {
      // Si hay algún error al procesar la fecha, retornar null
      debugPrint('Error al parsear fecha de competencia: $e');
      return null;
    }

    return null;
  }

  bool _getExtraBool(Client client, String key, {required bool defaultValue}) {
    final raw = client.training.extra[key];

    if (raw is bool) return raw;

    if (raw is String) {
      final lower = raw.toLowerCase();
      if (lower == 'true') return true;
      if (lower == 'false') return false;
    }

    if (raw is num) {
      if (raw == 1) return true;
      if (raw == 0) return false;
    }

    return defaultValue;
  }

  String _clientKeyFor(Client client) {
    return '${client.id}:${client.updatedAt.toIso8601String()}';
  }

  void _rebuildTimeline(Client? client) {
    if (client == null) {
      _peakWeekDatesNotifier.value = [];
      _fullTimelineNotifier.value = {};
      return;
    }
    final competitionDate = _getCompetitionDate(client);
    if (competitionDate == null) {
      _peakWeekDatesNotifier.value = [];
      _fullTimelineNotifier.value = {};
      return;
    }

    final cleanCompetitionDate = competitionDate;

    _peakWeekDatesNotifier.value = List.generate(8, (index) {
      final daysToSubtract = 7 - index;
      return cleanCompetitionDate.subtract(Duration(days: daysToSubtract));
    });

    final newTimeline = <String, DailyTrackingRecord>{};

    final globalDate = ref.read(globalDateProvider);
    final baseRecord = client.latestAnthropometryAtOrBefore(globalDate);

    if (baseRecord != null) {
      newTimeline['base'] =
          DailyTrackingRecordFromAnthropometry.fromAnthropometry(baseRecord);
    }

    for (final record in client.tracking) {
      final dateKey = DateFormat('yyyy-MM-dd').format(record.date);
      newTimeline[dateKey] = record;
    }

    _fullTimelineNotifier.value = newTimeline;
  }

  void _showEditDialogForDate(DateTime date) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    final existingRecord = _fullTimelineNotifier.value[dateKey];
    final existingFeedback =
        _visualFeedbackNotifier.value[dateKey] ??
        {'isFlat': false, 'isSpillover': false, 'isPeak3D': false};

    final weightCtrl = TextEditingController(
      text: existingRecord?.weightKg?.toStringAsFixed(1) ?? '',
    );
    final abdFoldCtrl = TextEditingController(
      text: existingRecord?.abdominalFold?.toStringAsFixed(1) ?? '',
    );
    final waistCircCtrl = TextEditingController(
      text: existingRecord?.waistCircNarrowest?.toStringAsFixed(1) ?? '',
    );
    final urineColorCtrl = TextEditingController(
      text: existingRecord?.urineColor?.toString() ?? '3',
    );

    bool isFlat = (existingFeedback['isFlat'] as bool?) ?? false;
    bool isSpillover = (existingFeedback['isSpillover'] as bool?) ?? false;
    bool isPeak3D = (existingFeedback['isPeak3D'] as bool?) ?? false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: kCardColor,
              title: Text(
                "Seguimiento para ${DateFormat('EEE, d MMM', 'es').format(date)}",
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: weightCtrl,
                      decoration: hcsDecoration(
                        context,
                        labelText: 'Peso (kg)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    TextField(
                      controller: abdFoldCtrl,
                      decoration: hcsDecoration(
                        context,
                        labelText: 'Pliegue Abdominal (mm)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    TextField(
                      controller: waistCircCtrl,
                      decoration: hcsDecoration(
                        context,
                        labelText: 'Cintura (cm)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    TextField(
                      controller: urineColorCtrl,
                      decoration: hcsDecoration(
                        context,
                        labelText: 'Color de Orina (1-8)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const Divider(height: 24),
                    Text(
                      "Feedback Visual",
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    CheckboxListTile(
                      title: const Text("âœ… Pico 3D (Lleno y Seco)"),
                      subtitle: const Text("Estado óptimo alcanzado"),
                      value: isPeak3D,
                      activeColor: kPrimaryColor,
                      onChanged: (val) => setDialogState(() {
                        isPeak3D = val ?? false;
                        if (isPeak3D) {
                          isFlat = false;
                          isSpillover = false;
                        }
                      }),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      title: const Text("Plano (Flat)"),
                      value: isFlat,
                      activeColor: kPrimaryColor,
                      onChanged: isPeak3D
                          ? null
                          : (val) =>
                                setDialogState(() => isFlat = val ?? false),
                    ),
                    CheckboxListTile(
                      title: const Text("Aguado (Spillover)"),
                      value: isSpillover,
                      activeColor: kPrimaryColor,
                      onChanged: isPeak3D
                          ? null
                          : (val) => setDialogState(
                              () => isSpillover = val ?? false,
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _saveAndRecalculate(
                      date,
                      weightCtrl.text,
                      abdFoldCtrl.text,
                      waistCircCtrl.text,
                      urineColorCtrl.text,
                      isFlat,
                      isSpillover,
                      isPeak3D,
                    );
                    Navigator.pop(context);
                  },
                  child: Text(
                    existingRecord != null
                        ? SaveMessages.buttonSaveChanges
                        : SaveMessages.buttonCreateNew,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _saveAndRecalculate(
    DateTime date,
    String weight,
    String abdFold,
    String waistCirc,
    String urineColor,
    bool isFlat,
    bool isSpillover,
    bool isPeak3D,
  ) {
    final client = ref.read(clientsProvider).value?.activeClient;
    if (client == null) return;
    final dateKey = DateFormat('yyyy-MM-dd').format(date);

    final recordToSave = DailyTrackingRecord(
      date: date,
      weightKg: double.tryParse(weight),
      abdominalFold: double.tryParse(abdFold),
      waistCircNarrowest: double.tryParse(waistCirc),
      urineColor: int.tryParse(urineColor),
    );

    // Detectar si es edición o nuevo registro
    // ignore: unused_local_variable
    final isEditing = SaveActionDetector.isEditingExistingDate(
      client.tracking,
      date,
      (record) => record.date,
    );

    ref.read(clientsProvider.notifier).updateActiveClient((current) {
      final sortedTracking = upsertRecordByDate<DailyTrackingRecord>(
        existingRecords: current.tracking,
        newRecord: recordToSave,
        dateExtractor: (record) => record.date,
      );
      return current.copyWith(tracking: sortedTracking);
    });

    final currentTimeline = Map<String, DailyTrackingRecord>.from(
      _fullTimelineNotifier.value,
    );
    currentTimeline[dateKey] = recordToSave;
    _fullTimelineNotifier.value = currentTimeline;

    final currentFeedback = Map<String, Map<String, dynamic>>.from(
      _visualFeedbackNotifier.value,
    );
    currentFeedback[dateKey] = {
      'isFlat': isFlat,
      'isSpillover': isSpillover,
      'isPeak3D': isPeak3D,
    };
    _visualFeedbackNotifier.value = currentFeedback;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final client = ref.watch(clientsProvider).value?.activeClient;

    final currentKey = client != null ? _clientKeyFor(client) : null;
    if (_clientKey != currentKey) {
      _clientKey = currentKey;
      _rebuildTimeline(client);
    }

    final competitionDate = client != null ? _getCompetitionDate(client) : null;

    // Estado vacío: sin fecha de competencia
    if (client == null || competitionDate == null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Planificador de Peak Week',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Esta herramienta te permite planificar la semana de competencia (depleción, carga, etc.).',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Establece una fecha de competencia en la sección de Entrenamiento para activar esta función.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return ValueListenableBuilder<List<DateTime>>(
      valueListenable: _peakWeekDatesNotifier,
      builder: (context, peakWeekDates, _) {
        if (peakWeekDates.isEmpty) {
          return const Center(child: Text('No hay días para mostrar.'));
        }
        return ValueListenableBuilder<Map<String, DailyTrackingRecord>>(
          valueListenable: _fullTimelineNotifier,
          builder: (context, fullTimeline, _) {
            return ValueListenableBuilder<Map<String, Map<String, dynamic>>>(
              valueListenable: _visualFeedbackNotifier,
              builder: (context, visualFeedback, _) {
                return SingleChildScrollView(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 16.0,
                          right: 16.0,
                          top: 16.0,
                          bottom: 100.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. CONTEXT BAR
                            _buildContextBar(competitionDate),
                            const SizedBox(height: 16),

                            // 2. CARD DOMINANTE: Estado del plan
                            _buildPlanOverviewCard(
                              competitionDate,
                              fullTimeline,
                              peakWeekDates,
                            ),
                            const SizedBox(height: 16),

                            // 3. TIMELINE DE DÍAS (contenido principal)
                            _buildPeakWeekTimeline(
                              peakWeekDates,
                              fullTimeline,
                              visualFeedback,
                              client,
                            ),

                            // 4. HISTORIAL (colapsable)
                            if (client.tracking.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              _buildHistorySection(client),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  /// 1. Context Bar: Información de la competencia
  Widget _buildContextBar(DateTime competitionDate) {
    final daysUntilComp = competitionDate.difference(DateTime.now()).inDays;
    final isInPast = daysUntilComp < 0;
    final isPeakWeek = daysUntilComp >= -1 && daysUntilComp <= 7;

    final badge = !isInPast
        ? Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isPeakWeek ? Colors.orange : Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isPeakWeek
                  ? 'EN PEAK WEEK'
                  : 'Faltan ${daysUntilComp.abs()} días',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          )
        : null;

    return ClinicalContextBar(
      mode: 'PLANIFICADOR DE PEAK WEEK',
      modeColor: isPeakWeek ? Colors.orange : kPrimaryColor,
      modeIcon: Icons.event,
      dateLabel:
          'Competencia: ${DateFormat('d MMM yyyy', 'es').format(competitionDate)}',
      extraWidgets: badge != null ? [badge] : null,
    );
  }

  /// 2. Card Dominante: Resumen del plan
  Widget _buildPlanOverviewCard(
    DateTime competitionDate,
    Map<String, DailyTrackingRecord> fullTimeline,
    List<DateTime> peakWeekDates,
  ) {
    final baseRecord = fullTimeline['base'];
    final hasBaseData = baseRecord != null;

    // Contar días con datos
    int daysWithData = 0;
    for (final date in peakWeekDates) {
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      if (fullTimeline.containsKey(dateKey)) {
        daysWithData++;
      }
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: kPrimaryColor.withValues(alpha: 0.3), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.timeline, color: kPrimaryColor, size: 24),
                SizedBox(width: 8),
                Text(
                  'Plan de la Semana',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildPlanKPI(
                  'Días Planificados',
                  peakWeekDates.length.toString(),
                  '',
                  Icons.calendar_month,
                ),
                _buildPlanKPI(
                  'Días con Datos',
                  daysWithData.toString(),
                  '/ ${peakWeekDates.length}',
                  Icons.check_circle,
                ),
                if (hasBaseData)
                  _buildPlanKPI(
                    'Peso Base',
                    baseRecord.weightKg?.toStringAsFixed(1) ?? '—',
                    'kg',
                    Icons.scale,
                  ),
                if (hasBaseData && baseRecord.abdominalFold != null)
                  _buildPlanKPI(
                    'Pliegue Base',
                    baseRecord.abdominalFold!.toStringAsFixed(1),
                    'mm',
                    Icons.straighten,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Toca cada día para registrar peso, pliegue abdominal y look visual. El sistema calculará ajustes automáticamente.',
                      style: TextStyle(fontSize: 12, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanKPI(String label, String value, String unit, IconData icon) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: kPrimaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$value $unit',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 3. Timeline de la peak week
  Widget _buildPeakWeekTimeline(
    List<DateTime> peakWeekDates,
    Map<String, DailyTrackingRecord> fullTimeline,
    Map<String, Map<String, dynamic>> visualFeedback,
    Client client,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: kCardColor.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.view_week, color: kPrimaryColor, size: 20),
                SizedBox(width: 8),
                Text(
                  'Timeline Día a Día',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: peakWeekDates.asMap().entries.map((entry) {
                  int index = entry.key;
                  DateTime date = entry.value;
                  return Row(
                    children: [
                      _buildDayColumn(
                        date,
                        index,
                        peakWeekDates,
                        fullTimeline,
                        visualFeedback,
                        client,
                      ),
                      if (index < peakWeekDates.length - 1)
                        const VerticalDivider(
                          width: 24,
                          thickness: 1,
                          color: kAppBarColor,
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

  /// 4. Sección de historial
  Widget _buildHistorySection(Client client) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: kCardColor.withValues(alpha: 0.3),
      child: RecordHistoryPanel<DailyTrackingRecord>(
        records: client.tracking,
        selectedDate: null,
        onSelectDate: (date) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Registro del ${DateFormat('dd MMM yyyy', 'es').format(date)}',
              ),
            ),
          );
        },
        primaryLabel: (record) {
          final weight = record.weightKg?.toStringAsFixed(1) ?? '—';
          final abd = record.abdominalFold?.toStringAsFixed(1) ?? '—';
          return 'Peso: $weight kg • Abd: $abd mm';
        },
        dateOf: (record) => record.date,
        title: 'Historial Completo de Seguimiento',
      ),
    );
  }

  Widget _buildDayColumn(
    DateTime date,
    int index,
    List<DateTime> peakWeekDates,
    Map<String, DailyTrackingRecord> fullTimeline,
    Map<String, Map<String, dynamic>> visualFeedback,
    Client client,
  ) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    final feedback =
        visualFeedback[dateKey] ??
        {'isFlat': false, 'isSpillover': false, 'isPeak3D': false};

    DailyTrackingRecord? recordToday = fullTimeline[dateKey];
    DailyTrackingRecord? recordPrev;

    final baseDailyRecord = fullTimeline["base"];

    if (index == 0) {
      recordPrev = baseDailyRecord;
    } else if (index > 0) {
      final prevDateKey = DateFormat(
        'yyyy-MM-dd',
      ).format(peakWeekDates[index - 1]);
      recordPrev = fullTimeline[prevDateKey];
    }

    final competitionDate = _getCompetitionDate(client);
    if (competitionDate == null) {
      return const SizedBox.shrink();
    }

    final cleanDate = DateUtils.dateOnly(date);
    final daysUntil = cleanDate.difference(competitionDate).inDays;
    final isFirstDay = (daysUntil == -7);

    if (recordToday == null && recordPrev != null) {
      recordToday = recordPrev.copyWith(
        date: date,
        weightKg: null,
        abdominalFold: null,
        waistCircNarrowest: null,
        urineColor: null,
      );
    }

    if (recordToday == null && baseDailyRecord != null) {
      recordToday = baseDailyRecord.copyWith(
        date: date,
        weightKg: null,
        abdominalFold: null,
        waistCircNarrowest: null,
        urineColor: null,
      );
    }

    bool canCompute =
        recordToday?.weightKg != null &&
        (recordPrev?.weightKg != null || baseDailyRecord?.weightKg != null);

    PeakOutput? peakOutput;
    if (canCompute) {
      peakOutput = PeakLogicPro.compute(
        pesoToday: recordToday!.weightKg!,
        pesoPrev: recordPrev?.weightKg ?? baseDailyRecord?.weightKg,
        abdFoldToday: recordToday.abdominalFold,
        abdFoldPrev:
            recordPrev?.abdominalFold ?? baseDailyRecord?.abdominalFold,
        waistToday: recordToday.waistCircNarrowest,
        waistPrev:
            recordPrev?.waistCircNarrowest ??
            baseDailyRecord?.waistCircNarrowest,
        urineColor: recordToday.urineColor,
        daysUntilCompetition: daysUntil,
        useCreatine: _getExtraBool(
          client,
          'useCreatineInPeakWeek',
          defaultValue: true,
        ),
        useGlycerol: _getExtraBool(
          client,
          'useGlycerolInPeakWeek',
          defaultValue: false,
        ),
        isFlat: (feedback['isFlat'] as bool?) ?? false,
        isSpillover: (feedback['isSpillover'] as bool?) ?? false,
        isPeak3D: (feedback['isPeak3D'] as bool?) ?? false,
        bfPercent: client
            .latestAnthropometryAtOrBefore(ref.read(globalDateProvider))
            ?.thighFold, // Simplified
        sexo: client.profile.gender?.label ?? 'Hombre',
        glycerolTested: _getExtraBool(
          client,
          'glycerolTested',
          defaultValue: false,
        ),
      );
    }

    String lookFeedback = "Normal";
    if (feedback['isPeak3D']!) {
      lookFeedback = "âœ… Pico 3D (Óptimo)";
    } else if (feedback['isFlat']! && feedback['isSpillover']!) {
      lookFeedback = "Plano y Aguado";
    } else if (feedback['isFlat']!) {
      lookFeedback = "Plano";
    } else if (feedback['isSpillover']!) {
      lookFeedback = "Aguado";
    }

    return Container(
      width: 250,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Día ${daysUntil == 0 ? "Show" : "$daysUntil"}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat.EEEE('es').format(date),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: kTextColorSecondary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(
                    Icons.edit,
                    color: kTextColorSecondary,
                    size: 20,
                  ),
                  onPressed: () => _showEditDialogForDate(date),
                  tooltip: "Editar datos del día",
                ),
              ],
            ),
            const Divider(height: 24),
            _buildSectionTitle('Plan Nutricional'),
            if (canCompute && peakOutput != null) ...[
              _buildInfoRow(
                'Proteína',
                '${peakOutput.protG.toStringAsFixed(1)} g',
              ),
              _buildInfoRow('Carbs', '${peakOutput.choG.toStringAsFixed(1)} g'),
              _buildInfoRow(
                'Lípidos',
                '${peakOutput.grasaG.toStringAsFixed(1)} g',
              ),
              _buildInfoRow(
                'Agua',
                '${peakOutput.aguaMl.toStringAsFixed(0)} ml',
              ),
              _buildInfoRow(
                'Sodio',
                '${peakOutput.sodioMg.toStringAsFixed(0)} mg',
              ),
              _buildInfoRow(
                'Potasio',
                '${peakOutput.potasioMg.toStringAsFixed(0)} mg',
              ),
              _buildInfoRow(
                'Creatina',
                '${peakOutput.creatinaG.toStringAsFixed(1)} g',
              ),
              _buildInfoRow(
                'Glicerina',
                '${peakOutput.glicerolG.toStringAsFixed(1)} g',
              ),
            ] else ...[
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Completa las métricas...',
                  style: TextStyle(
                    color: kTextColorSecondary,
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            const Divider(height: 24),
            _buildSectionTitle('Métricas y Look'),
            _buildInfoRow(
              'Peso (kg)',
              recordToday?.weightKg?.toStringAsFixed(1) ?? '-',
            ),
            _buildInfoRow(
              'Pliegue (mm)',
              recordToday?.abdominalFold?.toStringAsFixed(1) ?? '-',
            ),
            _buildInfoRow(
              'Cintura (cm)',
              recordToday?.waistCircNarrowest?.toStringAsFixed(1) ?? '-',
            ),
            _buildInfoRow(
              'Color Orina',
              recordToday?.urineColor?.toString() ?? '-',
            ),
            _buildInfoRow('Look Visual', lookFeedback),
            if (canCompute && peakOutput != null && !isFirstDay) ...[
              const Divider(height: 24),
              _buildSectionTitle('Informe de Ajuste'),
              _buildAdjustmentReport(
                _mapRiesgoPeak(peakOutput.riesgo),
                AccionPeak(displayMessage: peakOutput.accion),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: kPrimaryColor,
      ),
    ),
  );

  Widget _buildInfoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: kTextColorSecondary,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );

  Widget _buildAdjustmentReport(RiesgoPeak riesgo, AccionPeak accion) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: kBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: riesgo.color.withAlpha(128)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(riesgo.icon, color: riesgo.color, size: 16),
              const SizedBox(width: 8),
              Text(
                riesgo.displayName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: riesgo.color,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(accion.displayMessage, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class RiesgoPeak {
  final String displayName;
  final Color color;
  final IconData icon;
  const RiesgoPeak({
    required this.displayName,
    required this.color,
    required this.icon,
  });
}

class AccionPeak {
  final String displayMessage;
  const AccionPeak({required this.displayMessage});
}

RiesgoPeak _mapRiesgoPeak(String riesgoRaw) {
  final normalized = riesgoRaw.toUpperCase();
  if (normalized.contains('CRIT') || normalized.contains('CRï¿½')) {
    return const RiesgoPeak(
      displayName: 'Crítico',
      color: Colors.redAccent,
      icon: Icons.warning_rounded,
    );
  }
  if (normalized.contains('ALTA')) {
    return const RiesgoPeak(
      displayName: 'Alerta Alta',
      color: Colors.orangeAccent,
      icon: Icons.warning_amber_rounded,
    );
  }
  if (normalized.contains('ATENC')) {
    return const RiesgoPeak(
      displayName: 'Atención',
      color: Colors.amber,
      icon: Icons.lightbulb_outline,
    );
  }
  if (normalized.contains('MEDIA')) {
    return const RiesgoPeak(
      displayName: 'Precaución',
      color: Colors.deepOrangeAccent,
      icon: Icons.report_problem_outlined,
    );
  }
  if (normalized.contains('XITO') || normalized.contains('EXITO')) {
    return const RiesgoPeak(
      displayName: 'Éxito',
      color: Colors.greenAccent,
      icon: Icons.check_circle_outline,
    );
  }
  return const RiesgoPeak(
    displayName: 'OK',
    color: Colors.lightGreen,
    icon: Icons.check_circle_outline,
  );
}
