import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/core/constants/nutrition_extra_keys.dart';
import 'package:hcs_app_lap/core/contracts/saveable_module.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/features/main_shell/providers/global_date_provider.dart';
import 'package:hcs_app_lap/features/nutrition_feature/providers/equivalents_by_day_provider.dart';
import 'package:hcs_app_lap/features/nutrition_feature/providers/nutrition_plan_engine_provider.dart';
import 'package:hcs_app_lap/features/nutrition_feature/widgets/day_equivalents_tab.dart';
import 'package:hcs_app_lap/utils/date_helpers.dart';
import 'package:hcs_app_lap/utils/nutrition_record_helpers.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:intl/intl.dart';

/// Pantalla de Equivalentes por Dia (indice 5)
/// Tabs: Lunes-Domingo, cada uno con sub-tabs: Generales | Distribucion
class EquivalentsByDayScreen extends ConsumerStatefulWidget {
  const EquivalentsByDayScreen({super.key});

  @override
  ConsumerState<EquivalentsByDayScreen> createState() =>
      _EquivalentsByDayScreenState();
}

class _EquivalentsByDayScreenState extends ConsumerState<EquivalentsByDayScreen>
    with SingleTickerProviderStateMixin
    implements SaveableModule {
  _EquivalentsMode _mode = _EquivalentsMode.idle;
  String? _selectedRecordDateIso;
  String? _lastLoadedRecordIso;

  late TabController _tabController;
  late final ProviderSubscription _clientSubscription;

  final days = const [
    'Lunes',
    'Martes',
    'Miercoles',
    'Jueves',
    'Viernes',
    'Sabado',
    'Domingo',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: days.length, vsync: this);
    // Load equivalents when active client changes, outside build.
    _clientSubscription = ref.listenManual(clientsProvider, (previous, next) {
      final client = next.value?.activeClient;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(equivalentsByDayProvider.notifier).loadFromClient(client);
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final client = ref.read(clientsProvider).value?.activeClient;
      ref.read(equivalentsByDayProvider.notifier).loadFromClient(client);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final client = ref.read(clientsProvider).value?.activeClient;
      if (client == null || !mounted) return;
      final persisted =
          client.nutrition.extra[
              NutritionExtraKeys.selectedEquivalentsRecordDateIso]
              ?.toString();
      if (persisted != null) {
        setState(() {
          _selectedRecordDateIso = persisted;
          _mode = _EquivalentsMode.view;
        });
      }
    });
  }

  @override
  void dispose() {
    _clientSubscription.close();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Future<void> saveIfDirty() async {
    final state = ref.read(equivalentsByDayProvider);
    if (!state.isDirty) return;

    final client = ref.read(clientsProvider).value?.activeClient;
    if (client == null) return;

    final records = readNutritionRecordList(
      client.nutrition.extra[NutritionExtraKeys.equivalentsRecords],
    );
    final activeDateIso = dateIsoFrom(ref.read(globalDateProvider));
    final displayedDateIso = _resolveDisplayedEquivalentsDateIso(
      records,
      activeDateIso,
    );

    final notifier = ref.read(equivalentsByDayProvider.notifier);
    final payload = notifier.toJson();

    await ref.read(clientsProvider.notifier).updateActiveClient((current) {
      final mergedExtra = Map<String, dynamic>.from(current.nutrition.extra);
      final updatedRecords = readNutritionRecordList(
        mergedExtra[NutritionExtraKeys.equivalentsRecords],
      );
      updatedRecords.removeWhere(
        (record) =>
            _normalizeDateIso(record['dateIso']) == displayedDateIso,
      );
      updatedRecords.add({
        'dateIso': displayedDateIso,
        'equivalentsByDay': payload,
      });
      sortNutritionRecordsByDate(updatedRecords);
      mergedExtra[NutritionExtraKeys.equivalentsRecords] = updatedRecords;
      mergedExtra[NutritionExtraKeys.equivalentsByDay] = payload;
      mergedExtra[NutritionExtraKeys.selectedEquivalentsRecordDateIso] =
          displayedDateIso;

      return current.copyWith(
        nutrition: current.nutrition.copyWith(extra: mergedExtra),
      );
    });

    notifier.markSaved();
  }

  @override
  void resetDrafts() {
    final client = ref.read(clientsProvider).value?.activeClient;
    ref
        .read(equivalentsByDayProvider.notifier)
        .loadFromClient(client, force: true);
  }

  @override
  Widget build(BuildContext context) {
    final client = ref.watch(clientsProvider).value?.activeClient;
    final planResult = ref.watch(nutritionPlanResultProvider);
    final activeDateIso = dateIsoFrom(ref.watch(globalDateProvider));

    if (client == null || planResult == null) {
      return _buildEmptyState();
    }

    final records = readNutritionRecordList(
      client.nutrition.extra[NutritionExtraKeys.equivalentsRecords],
    );
    final displayedDateIso = _resolveDisplayedEquivalentsDateIso(
      records,
      activeDateIso,
    );
    final selectedDateTime = DateTime.tryParse(displayedDateIso);

    if (_mode == _EquivalentsMode.view &&
        _lastLoadedRecordIso != displayedDateIso) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final record =
            nutritionRecordForDate(records, displayedDateIso) ??
            latestNutritionRecordByDate(records);
        final payload = record?['equivalentsByDay'];
        ref.read(equivalentsByDayProvider.notifier).loadFromPayload(payload);
        _lastLoadedRecordIso = displayedDateIso;
      });
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _mode == _EquivalentsMode.view
          ? _buildActionButtons(displayedDateIso)
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: _mode == _EquivalentsMode.idle
          ? _buildHistoryView(records, selectedDateTime, activeDateIso)
          : Column(
              children: [
                TabBar(
                  controller: _tabController,
                  labelColor: kPrimaryColor,
                  unselectedLabelColor: kTextColorSecondary,
                  indicatorColor: kPrimaryColor,
                  isScrollable: true,
                  tabs: days.map((day) => Tab(text: day)).toList(),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: days.map((day) {
                      return DayEquivalentsTab(
                        dayKey: day.toLowerCase(),
                        dayLabel: day,
                        planResult: planResult,
                        onSave: saveIfDirty,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHistoryView(
    List<Map<String, dynamic>> records,
    DateTime? selectedDate,
    String activeDateIso,
  ) {
    return SingleChildScrollView(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 100),
            child: _buildEquivalentsHistoryGrid(
              records,
              selectedDate,
              activeDateIso,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEquivalentsHistoryGrid(
    List<Map<String, dynamic>> records,
    DateTime? selectedDate,
    String activeDateIso,
  ) {
    final sortedRecords = [...records]
      ..sort((a, b) {
        final dateAStr =
            _normalizeDateIso(a['dateIso']) ?? activeDateIso;
        final dateBStr =
            _normalizeDateIso(b['dateIso']) ?? activeDateIso;
        final dateA = DateTime.tryParse(dateAStr) ?? DateTime.now();
        final dateB = DateTime.tryParse(dateBStr) ?? DateTime.now();
        return dateB.compareTo(dateA);
      });

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: sortedRecords.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return InkWell(
            onTap: () => _createNewEquivalentsRecord(activeDateIso),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    kPrimaryColor.withAlpha(51),
                    kPrimaryColor.withAlpha(26),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: kPrimaryColor.withAlpha(128),
                  width: 1.5,
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 48, color: kPrimaryColor),
                  SizedBox(height: 12),
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
          );
        }

        final record = sortedRecords[index - 1];
        final iso = _normalizeDateIso(record['dateIso']) ?? activeDateIso;
        final recordDate = DateTime.tryParse(iso) ?? DateTime.now();
        final isSelected =
            selectedDate != null && DateUtils.isSameDay(selectedDate, recordDate);
        final day = DateFormat('d').format(recordDate);
        final monthYear = DateFormat('MMM yyyy', 'es').format(recordDate).toUpperCase();

        return InkWell(
          onTap: () => _selectRecord(dateIsoFrom(recordDate)),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? kPrimaryColor.withAlpha(51)
                  : kCardColor.withAlpha((255 * 0.30).round()),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? kPrimaryColor : Colors.grey.shade700,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: kTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  monthYear,
                  style: const TextStyle(
                    fontSize: 12,
                    color: kTextColorSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(String displayedDateIso) {
    final saveButton = FloatingActionButton.extended(
      heroTag: 'equivalents_save',
      onPressed: () async {
        await saveIfDirty();
      },
      label: const Text('Guardar'),
      icon: const Icon(Icons.save),
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
    );

    final deleteButton = FloatingActionButton.extended(
      heroTag: 'equivalents_delete',
      onPressed: () async {
        await _deleteEquivalentsRecord(displayedDateIso);
      },
      label: const Text('Borrar'),
      icon: const Icon(Icons.delete_outline),
      backgroundColor: Colors.red.shade700,
      foregroundColor: Colors.white,
    );

    final backButton = FloatingActionButton.extended(
      heroTag: 'equivalents_back',
      onPressed: () {
        setState(() {
          _mode = _EquivalentsMode.idle;
          _selectedRecordDateIso = null;
        });
      },
      label: const Text('Volver'),
      icon: const Icon(Icons.arrow_back),
      backgroundColor: Colors.grey.shade700,
      foregroundColor: Colors.white,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        backButton,
        const SizedBox(width: 8),
        deleteButton,
        const SizedBox(width: 8),
        saveButton,
      ],
    );
  }

  void _selectRecord(String dateIso) {
    ref.read(clientsProvider.notifier).updateActiveClient((current) {
      final extra = Map<String, dynamic>.from(current.nutrition.extra);
      extra[NutritionExtraKeys.selectedEquivalentsRecordDateIso] = dateIso;
      return current.copyWith(nutrition: current.nutrition.copyWith(extra: extra));
    });

    setState(() {
      _selectedRecordDateIso = dateIso;
      _mode = _EquivalentsMode.view;
    });
  }

  Future<void> _createNewEquivalentsRecord(String dateIso) async {
    final client = ref.read(clientsProvider).value?.activeClient;
    if (client == null) return;

    final payload = ref.read(equivalentsByDayProvider.notifier).toJson();

    ref.read(clientsProvider.notifier).updateActiveClient((current) {
      final extra = Map<String, dynamic>.from(current.nutrition.extra);
      final records = readNutritionRecordList(
        extra[NutritionExtraKeys.equivalentsRecords],
      );
      records.removeWhere(
        (record) => _normalizeDateIso(record['dateIso']) == dateIso,
      );
      records.add({'dateIso': dateIso, 'equivalentsByDay': payload});
      sortNutritionRecordsByDate(records);
      extra[NutritionExtraKeys.equivalentsRecords] = records;
      extra[NutritionExtraKeys.selectedEquivalentsRecordDateIso] = dateIso;
      return current.copyWith(nutrition: current.nutrition.copyWith(extra: extra));
    });

    if (!mounted) return;
    setState(() {
      _selectedRecordDateIso = dateIso;
      _mode = _EquivalentsMode.view;
    });
  }

  Future<void> _deleteEquivalentsRecord(String dateIso) async {
    final client = ref.read(clientsProvider).value?.activeClient;
    if (client == null) return;

    await ref.read(clientsProvider.notifier).updateActiveClient((current) {
      final extra = Map<String, dynamic>.from(current.nutrition.extra);
      final records = readNutritionRecordList(
        extra[NutritionExtraKeys.equivalentsRecords],
      );
      records.removeWhere(
        (record) => _normalizeDateIso(record['dateIso']) == dateIso,
      );
      sortNutritionRecordsByDate(records);
      final latestRecord = latestNutritionRecordByDate(records);
      extra[NutritionExtraKeys.equivalentsRecords] = records;
      if (latestRecord != null) {
        extra[NutritionExtraKeys.equivalentsByDay] =
            latestRecord['equivalentsByDay'];
      } else {
        extra.remove(NutritionExtraKeys.equivalentsByDay);
      }
      extra.remove(NutritionExtraKeys.selectedEquivalentsRecordDateIso);
      return current.copyWith(nutrition: current.nutrition.copyWith(extra: extra));
    });

    if (!mounted) return;
    setState(() {
      _selectedRecordDateIso = null;
      _mode = _EquivalentsMode.idle;
    });
  }

  String _resolveDisplayedEquivalentsDateIso(
    List<Map<String, dynamic>> records,
    String activeDateIso,
  ) {
    final latest = latestNutritionRecordByDate(records);
    final preferred =
        _selectedRecordDateIso ??
        _normalizeDateIso(latest?['dateIso']) ??
        activeDateIso;
    final record = nutritionRecordForDate(records, preferred) ?? latest;
    return _normalizeDateIso(record?['dateIso']) ?? preferred;
  }

  String? _normalizeDateIso(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString();
    final dt = DateTime.tryParse(s);
    if (dt != null) return dateIsoFrom(dt);
    final match = RegExp(r'^(\d{4}-\d{2}-\d{2})').firstMatch(s);
    if (match != null) {
      final parsed = DateTime.tryParse(match.group(1)!);
      if (parsed != null) return dateIsoFrom(parsed);
    }
    return null;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.table_chart_outlined,
            size: 80,
            color: kTextColorSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Primero calcula calorias y macros',
            style: TextStyle(
              fontSize: 18,
              color: kTextColorSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  
}

typedef EquivalentsByDayScreenState = _EquivalentsByDayScreenState;

enum _EquivalentsMode { idle, view }
