import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/daily_meal_plan.dart';
import 'package:hcs_app_lap/core/constants/nutrition_extra_keys.dart';
import 'package:hcs_app_lap/features/history_clinic_feature/viewmodel/history_clinic_view_model.dart';
import 'package:hcs_app_lap/features/main_shell/providers/global_date_provider.dart';
import 'package:hcs_app_lap/features/meal_plan_feature/widgets/daily_meal_plan_tab.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/utils/date_helpers.dart';
import 'package:hcs_app_lap/utils/nutrition_record_helpers.dart';
import 'package:hcs_app_lap/core/contracts/saveable_module.dart';

enum _MealPlanMode { idle, view }

class MealPlanScreen extends ConsumerStatefulWidget {
  final Client client;
  final Function(Client) onClientUpdated;

  const MealPlanScreen({
    super.key,
    required this.client,
    required this.onClientUpdated,
  });

  @override
  ConsumerState<MealPlanScreen> createState() => MealPlanScreenState();
}

class MealPlanScreenState extends ConsumerState<MealPlanScreen>
    implements SaveableModule {
  final GlobalKey<_MealPlanDaysCardState> _mealPlanDaysKey =
      GlobalKey<_MealPlanDaysCardState>();

  @override
  Future<void> saveIfDirty() async {
    await _mealPlanDaysKey.currentState?.saveIfDirty();
  }

  @override
  void resetDrafts() {
    _mealPlanDaysKey.currentState?.resetDrafts();
  }

  @override
  Widget build(BuildContext context) {
    Future<void> handleClientUpdated(Client updated) async {
      widget.onClientUpdated(updated);
      await ref.read(historyClinicVmProvider).saveClient(updated);
    }

    final activeDateIso = dateIsoFrom(ref.watch(globalDateProvider));

    return MealPlanDaysCard(
      key: _mealPlanDaysKey,
      client: widget.client,
      activeDateIso: activeDateIso,
      onClientUpdated: handleClientUpdated,
    );
  }
}

class MealPlanDaysCard extends StatefulWidget {
  final Client client;
  final String activeDateIso;
  final Function(Client) onClientUpdated;

  const MealPlanDaysCard({
    super.key,
    required this.client,
    required this.activeDateIso,
    required this.onClientUpdated,
  });

  @override
  State<MealPlanDaysCard> createState() => _MealPlanDaysCardState();
}

class _MealPlanDaysCardState extends State<MealPlanDaysCard>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  Client? _pendingClient;
  _MealPlanMode _mode = _MealPlanMode.idle;

  String? _selectedRecordDateIso;

  final days = const [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: days.length, vsync: this);
    // Cargar selección persistida
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final persisted = widget
          .client
          .nutrition
          .extra[NutritionExtraKeys.selectedMealPlanRecordDateIso];
      if (persisted != null && mounted) {
        setState(() {
          _selectedRecordDateIso = persisted.toString();
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  Client _upsertMealPlanRecord(
    Client baseClient,
    Map<String, DailyMealPlan> plans,
    String dateIso,
  ) {
    final extra = Map<String, dynamic>.from(baseClient.nutrition.extra);
    final records = readNutritionRecordList(
      extra[NutritionExtraKeys.mealPlanRecords],
    );
    records.removeWhere((record) => record['dateIso']?.toString() == dateIso);
    records.add({
      'dateIso': dateIso,
      'dailyMealPlans': plans.map((k, v) => MapEntry(k, v.toJson())),
    });
    sortNutritionRecordsByDate(records);
    final latestRecord = latestNutritionRecordByDate(records);
    final syncedMealPlans = parseDailyMealPlans(
      latestRecord?['dailyMealPlans'],
    );
    extra[NutritionExtraKeys.mealPlanRecords] = records;

    return baseClient.copyWith(
      nutrition: baseClient.nutrition.copyWith(
        extra: extra,
        dailyMealPlans: syncedMealPlans ?? baseClient.nutrition.dailyMealPlans,
      ),
    );
  }

  Map<String, DailyMealPlan> _resolvePlansForDate(String dateIso) {
    final records = readNutritionRecordList(
      widget.client.nutrition.extra[NutritionExtraKeys.mealPlanRecords],
    );
    final record =
        nutritionRecordForDate(records, dateIso) ??
        latestNutritionRecordByDate(records);
    return parseDailyMealPlans(record?['dailyMealPlans']) ??
        Map<String, DailyMealPlan>.from(
          widget.client.nutrition.dailyMealPlans ?? {},
        );
  }

  @override
  Widget build(BuildContext context) {
    final planRecords = readNutritionRecordList(
      widget.client.nutrition.extra[NutritionExtraKeys.mealPlanRecords],
    );
    final displayedDateIso = _resolveDisplayedMealPlanDateIso(planRecords);
    final activePlans = _resolvePlansForDate(displayedDateIso);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _handlePop(result);
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: _mode == _MealPlanMode.view
            ? _buildActionButtons(displayedDateIso)
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: Column(
          children: [
            if (_mode == _MealPlanMode.idle) ...[
              Expanded(
                child: SingleChildScrollView(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 100),
                        child: _buildMealPlanHistoryGrid(planRecords),
                      ),
                    ),
                  ),
                ),
              ),
            ] else ...[
              Container(
                color: Colors.transparent,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  padding: const EdgeInsets.only(bottom: 8),
                  indicatorColor: kPrimaryColor,
                  indicatorWeight: 3,
                  tabs: days.map((day) => Tab(text: day)).toList(),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: days.map((day) {
                    final plan = activePlans[day];
                    return DailyMealPlanTab(
                      key: ValueKey('$day-$displayedDateIso'),
                      dayKey: day,
                      dailyMealPlan: plan,
                      onMealsUpdated: (meals) =>
                          _handleMealsUpdated(meals, day, displayedDateIso),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _resolveDisplayedMealPlanDateIso(List<Map<String, dynamic>> records) {
    final latest = latestNutritionRecordByDate(records);
    final preferred =
        _selectedRecordDateIso ??
        _normalizeDateIso(latest?['dateIso']) ??
        widget.activeDateIso;
    final record = nutritionRecordForDate(records, preferred) ?? latest;
    return _normalizeDateIso(record?['dateIso']) ?? preferred;
  }

  void _handleMealsUpdated(
    List<Meal> meals,
    String dayKey,
    String targetDateIso,
  ) {
    final safeMeals = List<Meal>.from(meals);
    final activePlans = _resolvePlansForDate(targetDateIso);
    final currentPlan = activePlans[dayKey];
    final updatedPlan =
        (currentPlan ?? DailyMealPlan(dayKey: dayKey, meals: [])).copyWith(
          meals: safeMeals,
        );

    final updatedPlans = Map<String, DailyMealPlan>.from(activePlans);
    updatedPlans[dayKey] = updatedPlan;

    final updatedClient = _upsertMealPlanRecord(
      widget.client,
      updatedPlans,
      targetDateIso,
    );

    _pendingClient = updatedClient;
    widget.onClientUpdated(updatedClient);
  }

  Future<void> _saveTabIfNeeded(int tabIndex) async {
    final client = _pendingClient ?? widget.client;
    final result = widget.onClientUpdated(client);
    if (result is Future) {
      await result;
    }
  }

  Future<void> saveIfDirty() async {
    await _saveTabIfNeeded(_tabController.index);
  }

  void resetDrafts() {
    _pendingClient = null;
    if (mounted) {
      setState(() {});
    }
  }

  void _handlePop(Object? result) {
    final navigator = Navigator.of(context);
    _saveTabIfNeeded(_tabController.index).whenComplete(() {
      if (!navigator.mounted) {
        return;
      }
      navigator.pop(result);
    });
  }

  Widget _buildActionButtons(String displayedDateIso) {
    final saveButton = FloatingActionButton.extended(
      heroTag: 'meal_plan_save',
      onPressed: () async {
        await _saveTabIfNeeded(_tabController.index);
      },
      label: const Text('Guardar'),
      icon: const Icon(Icons.save),
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
    );

    final deleteButton = FloatingActionButton.extended(
      heroTag: 'meal_plan_delete',
      onPressed: () async {
        await _deleteMealPlanRecord(displayedDateIso);
      },
      label: const Text('Borrar'),
      icon: const Icon(Icons.delete_outline),
      backgroundColor: Colors.red.shade700,
      foregroundColor: Colors.white,
    );

    final backButton = FloatingActionButton.extended(
      heroTag: 'meal_plan_back',
      onPressed: () async {
        await _saveTabIfNeeded(_tabController.index);
        if (!mounted) return;
        setState(() {
          _mode = _MealPlanMode.idle;
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

  Future<void> _deleteMealPlanRecord(String dateIso) async {
    final records = readNutritionRecordList(
      widget.client.nutrition.extra[NutritionExtraKeys.mealPlanRecords],
    );
    records.removeWhere(
      (record) => _normalizeDateIso(record['dateIso']) == dateIso,
    );
    sortNutritionRecordsByDate(records);
    final latestRecord = latestNutritionRecordByDate(records);
    final syncedMealPlans = parseDailyMealPlans(
      latestRecord?['dailyMealPlans'],
    );

    final extra = Map<String, dynamic>.from(widget.client.nutrition.extra);
    extra[NutritionExtraKeys.mealPlanRecords] = records;

    final updatedClient = widget.client.copyWith(
      nutrition: widget.client.nutrition.copyWith(
        extra: extra,
        dailyMealPlans:
            syncedMealPlans ?? widget.client.nutrition.dailyMealPlans,
      ),
    );

    widget.onClientUpdated(updatedClient);

    if (!mounted) return;
    setState(() {
      _selectedRecordDateIso = null;
      _mode = _MealPlanMode.idle;
    });
  }

  Widget _buildMealPlanHistoryGrid(List<Map<String, dynamic>> records) {
    final sortedRecords = [...records]
      ..sort((a, b) {
        try {
          final dateAStr =
              _normalizeDateIso(a['dateIso']) ??
              _normalizeDateIso(a['date']) ??
              widget.activeDateIso;
          final dateBStr =
              _normalizeDateIso(b['dateIso']) ??
              _normalizeDateIso(b['date']) ??
              widget.activeDateIso;
          final dateA = DateTime.tryParse(dateAStr) ?? DateTime.now();
          final dateB = DateTime.tryParse(dateBStr) ?? DateTime.now();
          return dateB.compareTo(dateA);
        } catch (_) {
          return 0;
        }
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
      itemCount: sortedRecords.length + 1, // +1 para "Nuevo registro"
      itemBuilder: (context, index) {
        // Primer item: botón estilo tarjeta para nuevo registro
        if (index == 0) {
          return InkWell(
            onTap: () {
              var updatedClient = _upsertMealPlanRecord(
                widget.client,
                _resolvePlansForDate(widget.activeDateIso),
                widget.activeDateIso,
              );
              final extra = Map<String, dynamic>.from(
                updatedClient.nutrition.extra,
              );
              extra[NutritionExtraKeys.selectedMealPlanRecordDateIso] =
                  widget.activeDateIso;
              updatedClient = updatedClient.copyWith(
                nutrition: updatedClient.nutrition.copyWith(extra: extra),
              );
              setState(() {
                _selectedRecordDateIso = widget.activeDateIso;
                _mode = _MealPlanMode.view;
              });
              widget.onClientUpdated(updatedClient);
            },
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 48, color: kPrimaryColor),
                  const SizedBox(height: 12),
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

        // Items: registros existentes
        final record = sortedRecords[index - 1];
        final dateIso =
            _normalizeDateIso(record['dateIso']) ?? widget.activeDateIso;
        final date = DateTime.tryParse(dateIso) ?? DateTime(1900);
        final isSelected = _selectedRecordDateIso == dateIso;
        final day = date.day.toString();
        final monthYear = DateFormat(
          'MMM yyyy',
          'es',
        ).format(date).toUpperCase();

        return InkWell(
          onTap: () {
            final extra = Map<String, dynamic>.from(
              widget.client.nutrition.extra,
            );
            extra[NutritionExtraKeys.selectedMealPlanRecordDateIso] = dateIso;
            final updatedClient = widget.client.copyWith(
              nutrition: widget.client.nutrition.copyWith(extra: extra),
            );
            widget.onClientUpdated(updatedClient);
            setState(() {
              _selectedRecordDateIso = dateIso;
              _mode = _MealPlanMode.view;
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? kCardColor.withAlpha(51)
                  : kCardColor.withAlpha(26),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? Colors.white.withAlpha(102)
                    : Colors.white.withAlpha(15),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: isSelected ? Colors.white : kTextColorSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        day,
                        style: TextStyle(
                          color: isSelected ? Colors.white : kTextColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    monthYear,
                    style: const TextStyle(
                      color: kTextColorSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Icon(
                    Icons.restaurant_menu,
                    size: 20,
                    color: isSelected ? kPrimaryColor : kTextColorSecondary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
