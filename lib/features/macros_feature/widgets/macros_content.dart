// ignore_for_file: unused_field, duplicate_ignore

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/core/constants/nutrition_extra_keys.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/features/main_shell/providers/global_date_provider.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/daily_macro_settings.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/utils/macro_ranges.dart';
import 'package:hcs_app_lap/utils/date_helpers.dart';
import 'package:hcs_app_lap/utils/nutrition_record_helpers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hcs_app_lap/ui/clinic_section_surface.dart';

// Modo de visualización (top-level para evitar error enum_in_class)
enum _MacrosMode { idle, view, editing, creating }

class MacrosContent extends ConsumerStatefulWidget {
  const MacrosContent({super.key});

  @override
  ConsumerState<MacrosContent> createState() => MacrosContentState();
}

class MacrosContentState extends ConsumerState<MacrosContent>
    with SingleTickerProviderStateMixin {
  // Flujo de visualización
  _MacrosMode _mode = _MacrosMode.idle;
  static const _days = <String>[
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  late TabController _tabController;

  // ignore: unused_field
  final Map<String, String> _fatCategoryByDay = {};
  static const double _step = 0.05;
  static const double _eps = 1e-9;

  String _activeDateIso() {
    return dateIsoFrom(ref.read(globalDateProvider));
  }

  String? _selectedRecordDateIso;

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

  String _resolveDisplayedMacrosDateIso(
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _days.length, vsync: this);
    // Cargar selección persistida
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final client = ref.read(clientsProvider).value?.activeClient;
      if (client != null) {
        final persisted = client
            .nutrition
            .extra[NutritionExtraKeys.selectedMacrosRecordDateIso];
        if (persisted != null && mounted) {
          setState(() {
            _selectedRecordDateIso = persisted.toString();
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE CÁLCULO ---

  void _updateClientWeek(
    Map<String, DailyMacroSettings> week,
    String activeDateIso,
  ) {
    final client = ref.read(clientsProvider).value?.activeClient;
    if (client == null) return;

    ref.read(clientsProvider.notifier).updateActiveClient((current) {
      final extra = Map<String, dynamic>.from(current.nutrition.extra);
      final records = readNutritionRecordList(
        extra[NutritionExtraKeys.macrosRecords],
      );
      records.removeWhere(
        (record) => record['dateIso']?.toString() == activeDateIso,
      );
      records.add({
        'dateIso': activeDateIso,
        'weeklyMacroSettings': week.map((k, v) => MapEntry(k, v.toJson())),
      });
      sortNutritionRecordsByDate(records);
      final latestRecord = latestNutritionRecordByDate(records);
      final syncedWeeklyMacros = parseWeeklyMacroSettings(
        latestRecord?['weeklyMacroSettings'],
      );
      extra[NutritionExtraKeys.macrosRecords] = records;

      return current.copyWith(
        nutrition: current.nutrition.copyWith(
          extra: extra,
          weeklyMacroSettings:
              syncedWeeklyMacros ?? current.nutrition.weeklyMacroSettings,
        ),
      );
    });
  }

  Future<void> _saveTabIfNeeded(int tabIndex) async {
    final _ = tabIndex;
    final client = ref.read(clientsProvider).value?.activeClient;
    if (client == null) return;
    final activeDateIso = _activeDateIso();
    final records = readNutritionRecordList(
      client.nutrition.extra[NutritionExtraKeys.macrosRecords],
    );
    final displayedDateIso = _resolveDisplayedMacrosDateIso(
      records,
      activeDateIso,
    );
    final record =
        nutritionRecordForDate(records, displayedDateIso) ??
        latestNutritionRecordByDate(records);
    final week =
        parseWeeklyMacroSettings(record?['weeklyMacroSettings']) ??
        Map<String, DailyMacroSettings>.from(
          client.effectiveWeeklyMacros ?? const <String, DailyMacroSettings>{},
        );
    _updateClientWeek(week, displayedDateIso);
  }

  Future<void> saveIfDirty() async {
    await _saveTabIfNeeded(_tabController.index);
  }

  void resetDrafts() {
    if (mounted) {
      setState(() {});
    }
  }

  // ignore: unused_element
  String _normalizeDay(String day) {
    var lower = day.toLowerCase();
    lower = lower
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
    return lower;
  }

  @override
  Widget build(BuildContext context) {
    final client = ref.watch(clientsProvider).value?.activeClient;

    if (client == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu_outlined,
              size: 64,
              color: Colors.white24,
            ),
            const SizedBox(height: 16),
            Text(
              "Selecciona un cliente o crea uno nuevo",
              style: TextStyle(color: kTextColorSecondary),
            ),
          ],
        ),
      );
    }

    final activeDateIso = dateIsoFrom(ref.watch(globalDateProvider));
    final macroRecords = readNutritionRecordList(
      client.nutrition.extra[NutritionExtraKeys.macrosRecords],
    );
    final displayedMacrosDateIso = _resolveDisplayedMacrosDateIso(
      macroRecords,
      activeDateIso,
    );
    final macroRecord =
        nutritionRecordForDate(macroRecords, displayedMacrosDateIso) ??
        latestNutritionRecordByDate(macroRecords);
    final selectedMacroDate = macroRecord == null
        ? null
        : DateTime.tryParse(
            _normalizeDateIso(macroRecord['dateIso']) ?? displayedMacrosDateIso,
          );
    final week =
        parseWeeklyMacroSettings(macroRecord?['weeklyMacroSettings']) ??
        Map<String, DailyMacroSettings>.from(
          client.effectiveWeeklyMacros ?? {},
        );

    final evalRecords = readNutritionRecordList(
      client.nutrition.extra[NutritionExtraKeys.evaluationRecords],
    );
    final evalRecord =
        nutritionRecordForDate(evalRecords, activeDateIso) ??
        latestNutritionRecordByDate(evalRecords);
    final dailyKcal =
        parseDailyKcalMap(evalRecord?['dailyKcal']) ??
        client.nutrition.dailyKcal;
    final maintenanceKcal =
        (evalRecord?['kcal'] as num?)?.toDouble() ?? client.kcal?.toDouble();
    final kcalAdjustment =
        (evalRecord?['kcalAdjustment'] as num?)?.toDouble() ??
        (client.nutrition.extra[NutritionExtraKeys.kcalAdjustment] as num?)
            ?.toDouble() ??
        0.0;

    final targetDateIsoForActions =
        _selectedRecordDateIso ?? displayedMacrosDateIso;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _buildActionButtons(targetDateIsoForActions),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            return;
          }
          unawaited(_saveTabIfNeeded(_tabController.index));
        },
        child: Column(
          children: [
            if (_mode == _MacrosMode.idle) ...[
              ClinicSectionSurface(
                icon: Icons.history,
                title: 'Registros de Macronutrientes',
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: _buildMacrosHistoryGrid(
                    macroRecords,
                    selectedMacroDate,
                    activeDateIso,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ] else ...[
              // TAB BAR ESTILIZADO
              Container(
                color: Colors.transparent,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  padding: const EdgeInsets.only(bottom: 8),
                  indicatorColor: kPrimaryColor,
                  indicatorWeight: 3,
                  tabs: _days.map((d) => Tab(text: d)).toList(),
                ),
              ),
              // CONTENIDO
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: _days.map((day) {
                    return _MacroDayView(
                      key: ValueKey(day),
                      day: day,
                      client: client,
                      dailyKcal: dailyKcal,
                      maintenanceKcal: maintenanceKcal,
                      kcalAdjustment: kcalAdjustment,
                      initialSettings: week[day],
                      onChanged: (newSettings) {
                        final updatedWeek =
                            Map<String, DailyMacroSettings>.from(week);
                        updatedWeek[day] = newSettings;
                        _updateClientWeek(updatedWeek, displayedMacrosDateIso);
                      },
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

  // FABs para acciones en Macros (guardar, borrar, volver)
  Widget? _buildActionButtons(String displayedDateIso) {
    if (_mode == _MacrosMode.idle) {
      return null;
    }

    final saveButton = FloatingActionButton.extended(
      heroTag: 'macros_save',
      onPressed: () async {
        await _saveTabIfNeeded(_tabController.index);
      },
      label: const Text('Guardar'),
      icon: const Icon(Icons.save),
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
    );

    final deleteButton = FloatingActionButton.extended(
      heroTag: 'macros_delete',
      onPressed: () async {
        await _deleteMacrosRecord(displayedDateIso);
      },
      label: const Text('Borrar'),
      icon: const Icon(Icons.delete_outline),
      backgroundColor: Colors.red.shade700,
      foregroundColor: Colors.white,
    );

    final backButton = FloatingActionButton.extended(
      heroTag: 'macros_back',
      onPressed: () async {
        await _saveTabIfNeeded(_tabController.index);
        if (!mounted) return;
        setState(() {
          _mode = _MacrosMode.idle;
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

  Future<void> _deleteMacrosRecord(String dateIso) async {
    final client = ref.read(clientsProvider).value?.activeClient;
    if (client == null) return;

    ref.read(clientsProvider.notifier).updateActiveClient((current) {
      final extra = Map<String, dynamic>.from(current.nutrition.extra);
      final records = readNutritionRecordList(
        extra[NutritionExtraKeys.macrosRecords],
      );
      records.removeWhere(
        (record) => _normalizeDateIso(record['dateIso']) == dateIso,
      );
      sortNutritionRecordsByDate(records);
      final latestRecord = latestNutritionRecordByDate(records);
      final syncedWeeklyMacros = parseWeeklyMacroSettings(
        latestRecord?['weeklyMacroSettings'],
      );
      extra[NutritionExtraKeys.macrosRecords] = records;

      return current.copyWith(
        nutrition: current.nutrition.copyWith(
          extra: extra,
          weeklyMacroSettings:
              syncedWeeklyMacros ?? current.nutrition.weeklyMacroSettings,
        ),
      );
    });

    if (!mounted) return;
    setState(() {
      _selectedRecordDateIso = null;
      _mode = _MacrosMode.idle;
    });
  }

  Future<void> _createNewMacrosRecord(String dateIso) async {
    final client = ref.read(clientsProvider).value?.activeClient;
    if (client == null) return;

    ref.read(clientsProvider.notifier).updateActiveClient((current) {
      final extra = Map<String, dynamic>.from(current.nutrition.extra);
      final records = readNutritionRecordList(
        extra[NutritionExtraKeys.macrosRecords],
      );

      final exists = records.any(
        (r) => _normalizeDateIso(r['dateIso']) == dateIso,
      );
      if (!exists) {
        final baseWeek =
            current.effectiveWeeklyMacros ??
            current.nutrition.weeklyMacroSettings;
        final serialized = baseWeek == null
            ? <String, dynamic>{}
            : baseWeek.map((k, v) => MapEntry(k, v.toJson()));
        records.add({'dateIso': dateIso, 'weeklyMacroSettings': serialized});
        sortNutritionRecordsByDate(records);
      }

      final latestRecord = latestNutritionRecordByDate(records);
      final syncedWeeklyMacros = parseWeeklyMacroSettings(
        latestRecord?['weeklyMacroSettings'],
      );
      extra[NutritionExtraKeys.macrosRecords] = records;

      return current.copyWith(
        nutrition: current.nutrition.copyWith(
          extra: extra,
          weeklyMacroSettings:
              syncedWeeklyMacros ?? current.nutrition.weeklyMacroSettings,
        ),
      );
    });
  }

  // Grid de historial de macros
  Widget _buildMacrosHistoryGrid(
    List<Map<String, dynamic>> macroRecords,
    DateTime? selectedMacroDate,
    String activeDateIso,
  ) {
    final sortedRecords = [...macroRecords]
      ..sort((a, b) {
        try {
          final dateAStr =
              _normalizeDateIso(a['dateIso']) ??
              _normalizeDateIso(a['date']) ??
              activeDateIso;
          final dateBStr =
              _normalizeDateIso(b['dateIso']) ??
              _normalizeDateIso(b['date']) ??
              activeDateIso;
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
            onTap: () async {
              await _createNewMacrosRecord(activeDateIso);
              // Persistir selección
              ref.read(clientsProvider.notifier).updateActiveClient((current) {
                final extra = Map<String, dynamic>.from(
                  current.nutrition.extra,
                );
                extra[NutritionExtraKeys.selectedMacrosRecordDateIso] =
                    activeDateIso;
                return current.copyWith(
                  nutrition: current.nutrition.copyWith(extra: extra),
                );
              });
              if (!mounted) return;
              setState(() {
                _selectedRecordDateIso = activeDateIso;
                _mode = _MacrosMode.view;
              });
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

        // Tarjetas de registros existentes
        final record = sortedRecords[index - 1];
        final iso =
            _normalizeDateIso(record['dateIso']) ??
            _normalizeDateIso(record['date']) ??
            activeDateIso;

        DateTime recordDate;
        try {
          recordDate = DateTime.tryParse(iso) ?? DateTime.now();
        } catch (_) {
          recordDate = DateTime.now();
        }

        final isSelected =
            selectedMacroDate != null &&
            DateUtils.isSameDay(selectedMacroDate, recordDate);
        final day = DateFormat('d').format(recordDate);
        final monthYear = DateFormat(
          'MMM yyyy',
          'es',
        ).format(recordDate).toUpperCase();

        return InkWell(
          onTap: () {
            final dateIso = dateIsoFrom(recordDate);
            // Persistir selección
            ref.read(clientsProvider.notifier).updateActiveClient((current) {
              final extra = Map<String, dynamic>.from(current.nutrition.extra);
              extra[NutritionExtraKeys.selectedMacrosRecordDateIso] = dateIso;
              return current.copyWith(
                nutrition: current.nutrition.copyWith(extra: extra),
              );
            });
            setState(() {
              _selectedRecordDateIso = dateIso;
              _mode = _MacrosMode.view;
            });
          },
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
              crossAxisAlignment: CrossAxisAlignment.center,
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
                const SizedBox(height: 8),
                const Text(
                  'Macros semanales',
                  style: TextStyle(fontSize: 11, color: kTextColorSecondary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// --- WIDGET OPTIMIZADO PARA UN SOLO DÍA ---
class _MacroDayView extends ConsumerStatefulWidget {
  final String day;
  final Client client;
  final Map<String, int>? dailyKcal;
  final double? maintenanceKcal;
  final double kcalAdjustment;
  final DailyMacroSettings? initialSettings;
  final ValueChanged<DailyMacroSettings> onChanged;

  const _MacroDayView({
    super.key,
    required this.day,
    required this.client,
    this.dailyKcal,
    this.maintenanceKcal,
    required this.kcalAdjustment,
    this.initialSettings,
    required this.onChanged,
  });

  @override
  ConsumerState<_MacroDayView> createState() => _MacroDayViewState();
}

class _MacroDayViewState extends ConsumerState<_MacroDayView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late DailyMacroSettings _settings;
  late String _proteinCategory;
  late String _fatCategory;

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  @override
  void didUpdateWidget(covariant _MacroDayView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si los settings que vienen del padre son diferentes a los que tenemos,
    // actualizamos el estado local para reflejar el cambio.
    if (widget.initialSettings != oldWidget.initialSettings) {
      _initializeSettings();
    }
  }

  void _initializeSettings() {
    _settings =
        widget.initialSettings ??
        DailyMacroSettings.defaultFor(
          goalType: widget.client.profile.objective,
          weightKg: widget.client.lastWeight ?? 70.0,
          maintenanceKcal: widget.maintenanceKcal,
        );
    _proteinCategory = _inferProteinCategory(_settings);
    _fatCategory = _inferFatCategory(_settings);
  }

  // --- Métodos Helper movidos desde el padre ---
  double _normalizeToStep({
    required double value,
    required double min,
    required double max,
  }) {
    const double step = 0.05;
    final clamped = value.clamp(min, max);
    final units = ((clamped - min) / step).round();
    final snapped = min + units * step;
    return double.parse(snapped.toStringAsFixed(2));
  }

  double? _kcalForDay(String day, Client client) {
    final daily = widget.dailyKcal;
    if (daily != null && daily.isNotEmpty) {
      final normalizedDay = _normalizeDay(day);
      final entry = daily.entries.firstWhere(
        (e) => _normalizeDay(e.key) == normalizedDay,
        orElse: () =>
            daily.entries.first, // Fallback to the first day if not found
      );
      return entry.value.toDouble();
    }
    return widget.maintenanceKcal;
  }

  String _normalizeDay(String day) {
    var lower = day.toLowerCase();
    lower = lower
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
    return lower;
  }

  double _computeCarbsFromKcal({
    required double weightKg,
    required double proteinGPerKg,
    required double fatGPerKg,
    double? dailyKcal,
  }) {
    if (dailyKcal == null || dailyKcal <= 0 || weightKg <= 0) return 0;
    final proteinKcal = proteinGPerKg * 4 * weightKg;
    final fatKcal = fatGPerKg * 9 * weightKg;
    final remaining = dailyKcal - proteinKcal - fatKcal;
    if (remaining <= 0) return 0;
    return remaining / (4 * weightKg);
  }

  List<double> _buildRangeOptions(MacroRange range) {
    const double step = 0.05;
    const double eps = 1e-9;
    final List<double> options = [];
    double current = range.min;
    while (current <= range.max + eps) {
      final normalized = double.parse(current.toStringAsFixed(2));
      options.add(normalized);
      current += step;
    }
    return options;
  }

  String _inferCarbCategoryFromValue(double value) {
    const double eps = 1e-9;
    final entry = MacroRanges.carbs.entries.firstWhere(
      (e) => value >= e.value.min - eps && value <= e.value.max + eps,
      orElse: () => MacroRanges.carbs.entries.first,
    );
    return entry.key;
  }

  DailyMacroSettings _applyComputedCarbs(
    DailyMacroSettings base,
    double weightKg,
    double? dailyKcal,
  ) {
    final computedCarbs = _computeCarbsFromKcal(
      weightKg: weightKg,
      proteinGPerKg: base.proteinSelected,
      fatGPerKg: base.fatSelected,
      dailyKcal: dailyKcal,
    );
    return base.copyWith(carbSelected: computedCarbs);
  }

  // --- Lógica movida aquí ---
  String _inferProteinCategory(DailyMacroSettings settings) => MacroRanges
      .protein
      .entries
      .firstWhere(
        (e) =>
            (settings.proteinMin - e.value.min).abs() < 0.001 &&
            (settings.proteinMax - e.value.max).abs() < 0.001,
        orElse: () => MacroRanges.protein.entries.first,
      )
      .key;

  String _inferFatCategory(DailyMacroSettings settings) => MacroRanges
      .lipids
      .entries
      .firstWhere(
        (e) =>
            (settings.fatMin - e.value.min).abs() < 0.001 &&
            (settings.fatMax - e.value.max).abs() < 0.001,
        orElse: () => MacroRanges.lipids.entries.first,
      )
      .key;

  void _handleCategoryChange({
    required String category,
    required bool isProtein,
  }) {
    final weightKg = widget.client.lastWeight ?? 70.0;
    final dailyKcal = _kcalForDay(widget.day, widget.client);

    final ranges = isProtein ? MacroRanges.protein : MacroRanges.lipids;
    final range = ranges[category];
    if (range == null) return;

    final snapped = _normalizeToStep(
      value: isProtein ? _settings.proteinSelected : _settings.fatSelected,
      min: range.min,
      max: range.max,
    );

    DailyMacroSettings newSettings;
    if (isProtein) {
      _proteinCategory = category;
      newSettings = _settings.copyWith(
        proteinMin: range.min,
        proteinMax: range.max,
        proteinSelected: snapped,
      );
    } else {
      _fatCategory = category;
      newSettings = _settings.copyWith(
        fatMin: range.min,
        fatMax: range.max,
        fatSelected: snapped,
      );
    }

    final withCarbs = _applyComputedCarbs(newSettings, weightKg, dailyKcal);
    widget.onChanged(withCarbs);
  }

  void _handleValueChange({required double value, required bool isProtein}) {
    final weightKg = widget.client.lastWeight ?? 70.0;
    final dailyKcal = _kcalForDay(widget.day, widget.client);

    DailyMacroSettings newSettings;
    if (isProtein) {
      newSettings = _settings.copyWith(proteinSelected: value);
    } else {
      newSettings = _settings.copyWith(fatSelected: value);
    }
    final withCarbs = _applyComputedCarbs(newSettings, weightKg, dailyKcal);
    widget.onChanged(withCarbs);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final weightKg = widget.client.lastWeight ?? 70.0;
    final dayKcal = _kcalForDay(widget.day, widget.client);

    final proteinKcal = _settings.proteinSelected * 4 * weightKg;
    final fatKcal = _settings.fatSelected * 9 * weightKg;

    final computedCarbSelected = _computeCarbsFromKcal(
      weightKg: weightKg,
      proteinGPerKg: _settings.proteinSelected,
      fatGPerKg: _settings.fatSelected,
      dailyKcal: dayKcal,
    );

    final carbKcal = computedCarbSelected * 4 * weightKg;
    final carbGrams = carbKcal / 4;
    final carbGPerKg = carbGrams / weightKg;
    final macrosKcal = proteinKcal + fatKcal + carbKcal;

    final proteinRange = MacroRanges.protein[_proteinCategory]!;
    final fatRange = MacroRanges.lipids[_fatCategory]!;

    final proteinOptions = _buildRangeOptions(proteinRange);
    final fatOptions = _buildRangeOptions(fatRange);

    final carbCategory = _inferCarbCategoryFromValue(carbGPerKg);
    final carbOptions = [double.parse(carbGPerKg.toStringAsFixed(2))];

    final proteinGrams = _settings.proteinSelected * weightKg;
    final fatGrams = _settings.fatSelected * weightKg;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double height = constraints.maxHeight;
        final double width = constraints.maxWidth;

        return Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            height: height,
            width: width,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _MacroConfigPanel(
                          day: widget.day,
                          rows: [
                            _MacroTableRowData(
                              label: 'PROTEÍNAS',
                              category: _proteinCategory,
                              categoryOptions: MacroRanges.protein.keys
                                  .toList(),
                              valueOptions: proteinOptions,
                              selectedValue: _settings.proteinSelected,
                              gramsTotal: proteinGrams,
                              kcal: proteinKcal,
                              onCategoryChanged: (v) => _handleCategoryChange(
                                category: v,
                                isProtein: true,
                              ),
                              onValueChanged: (v) =>
                                  _handleValueChange(value: v, isProtein: true),
                              enabled: true,
                              color: Colors.greenAccent.shade400,
                            ),
                            _MacroTableRowData(
                              label: 'GRASAS',
                              category: _fatCategory,
                              categoryOptions: MacroRanges.lipids.keys.toList(),
                              valueOptions: fatOptions,
                              selectedValue: _settings.fatSelected,
                              gramsTotal: fatGrams,
                              kcal: fatKcal,
                              onCategoryChanged: (v) => _handleCategoryChange(
                                category: v,
                                isProtein: false,
                              ),
                              onValueChanged: (v) => _handleValueChange(
                                value: v,
                                isProtein: false,
                              ),
                              enabled: true,
                              color: Colors.orangeAccent,
                            ),
                            _MacroTableRowData(
                              label: 'CARBOHIDRATOS',
                              category: carbCategory,
                              categoryOptions: MacroRanges.carbs.keys.toList(),
                              valueOptions: carbOptions,
                              selectedValue: carbGPerKg,
                              gramsTotal: carbGrams,
                              kcal: carbKcal,
                              enabled: false,
                              color: Colors.lightBlueAccent,
                            ),
                          ],
                          referenceWeight: weightKg,
                        ),
                        const SizedBox(height: 20),
                        _EnergySummaryHeader(
                          baseKcal: macrosKcal,
                          kcalAdjustment: widget.kcalAdjustment,
                          proteinGrams: proteinGrams,
                          fatGrams: fatGrams,
                          carbGrams: carbGrams,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 4,
                  child: ClinicSectionSurface(
                    icon: Icons.pie_chart,
                    title: 'Distribución del día',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 200,
                              height: 200,
                              child: _MacroChartDonut(
                                proteinKcal: proteinKcal,
                                fatKcal: fatKcal,
                                carbKcal: carbKcal,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _MacroChartLegend(
                                proteinKcal: proteinKcal,
                                fatKcal: fatKcal,
                                carbKcal: carbKcal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Divider(color: Colors.white10, height: 1),
                        const SizedBox(height: 16),
                        _ClinicalValidationCard(
                          proteinGPerKg: _settings.proteinSelected,
                          proteinRange: MacroRanges.protein[_proteinCategory],
                          proteinCategory: _proteinCategory,
                          proteinGrams: proteinGrams,
                          proteinKcal: proteinKcal,
                          fatGPerKg: _settings.fatSelected,
                          fatRange: MacroRanges.lipids[_fatCategory],
                          fatCategory: _fatCategory,
                          fatGrams: fatGrams,
                          fatKcal: fatKcal,
                          carbGPerKg: carbGPerKg,
                          carbRange: MacroRanges.carbs[carbCategory],
                          carbCategory: carbCategory,
                          carbGrams: carbGrams,
                          carbKcal: carbKcal,
                          totalKcal: macrosKcal,
                          weightKg: weightKg,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MacroConfigPanel extends StatelessWidget {
  final List<_MacroTableRowData> rows;
  final double referenceWeight;
  final String day;

  const _MacroConfigPanel({
    required this.rows,
    required this.referenceWeight,
    required this.day,
  });

  @override
  Widget build(BuildContext context) {
    return ClinicSectionSurface(
      icon: Icons.restaurant_menu,
      title: 'Prescripción Nutricional — $day',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12, top: 4),
            child: Text(
              'Peso de referencia: ${referenceWeight.toStringAsFixed(1)} kg',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _MacroTableRow(data: row),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroTableRow extends StatelessWidget {
  final _MacroTableRowData data;

  const _MacroTableRow({required this.data});

  // Helper para obtener el rango recomendado
  MacroRange? _getMacroRange() {
    if (data.label.toUpperCase() == 'PROTEÍNAS') {
      return MacroRanges.protein[data.category];
    } else if (data.label.toUpperCase() == 'GRASAS') {
      return MacroRanges.lipids[data.category];
    } else if (data.label.toUpperCase() == 'CARBOHIDRATOS') {
      return MacroRanges.carbs[data.category];
    }
    return null;
  }

  // Helper para determinar si está dentro del rango
  bool _isWithinRange() {
    final range = _getMacroRange();
    if (range == null) return false;
    return data.selectedValue >= range.min - 0.001 &&
        data.selectedValue <= range.max + 0.001;
  }

  // Helper para badge de estado
  Color _getBadgeColor() {
    if (!_isWithinRange()) return Colors.red.shade700;
    return Colors.green.shade600;
  }

  String _getBadgeLabel() {
    final range = _getMacroRange();
    if (range == null) return 'N/A';
    return '${range.min.toStringAsFixed(2)}-${range.max.toStringAsFixed(2)} g/kg';
  }

  @override
  Widget build(BuildContext context) {
    // Corrección crítica de dropdown
    final safeSelectedValue = data.valueOptions.firstWhere(
      (opt) => (opt - data.selectedValue).abs() < 0.001,
      orElse: () => data.valueOptions.isNotEmpty
          ? data.valueOptions.first
          : data.selectedValue,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(5),
        border: Border.all(
          color: data.color.withAlpha((255 * 0.3).round()),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Título + Icono + Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Título + Icono de edición vs calculado
              Row(
                children: [
                  Text(
                    data.label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (data.enabled)
                    Icon(Icons.edit, size: 14, color: Colors.white54)
                  else
                    Tooltip(
                      message: 'Calculado automáticamente por el sistema',
                      child: Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: kPrimaryColor.withAlpha((255 * 0.6).round()),
                      ),
                    ),
                ],
              ),
              // Badge de rango
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getBadgeColor().withAlpha((255 * 0.2).round()),
                  border: Border.all(color: _getBadgeColor()),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getBadgeLabel(),
                  style: TextStyle(
                    color: _getBadgeColor(),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Dropdowns
          LayoutBuilder(
            builder: (context, constraints) {
              final itemMaxWidth = (constraints.maxWidth - 16) / 2;

              Widget buildCategory() => ConstrainedBox(
                constraints: BoxConstraints(maxWidth: itemMaxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Categoría',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(77),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: data.category,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white54,
                            size: 16,
                          ),
                          dropdownColor: kAppBarColor,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                          items: data.categoryOptions
                              .map(
                                (opt) => DropdownMenuItem(
                                  value: opt,
                                  child: Text(opt),
                                ),
                              )
                              .toList(),
                          onChanged:
                              data.enabled && data.onCategoryChanged != null
                              ? (value) => data.onCategoryChanged!(value!)
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              );

              Widget buildValue() => ConstrainedBox(
                constraints: BoxConstraints(maxWidth: itemMaxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'g/kg',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(77),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<double>(
                          value: safeSelectedValue,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white54,
                            size: 16,
                          ),
                          dropdownColor: kAppBarColor,
                          style: TextStyle(
                            color: data.color,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          items: data.valueOptions
                              .map(
                                (opt) => DropdownMenuItem(
                                  value: opt,
                                  child: Text(opt.toStringAsFixed(2)),
                                ),
                              )
                              .toList(),
                          onChanged: data.enabled && data.onValueChanged != null
                              ? (value) => data.onValueChanged!(value!)
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              );

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(child: buildCategory()),
                  const SizedBox(width: 16),
                  Flexible(child: buildValue()),
                ],
              );
            },
          ),
          // Texto explicativo para carbohidratos calculados
          if (!data.enabled)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Calculado automáticamente según kcal objetivo',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const SizedBox(height: 12),
          // Resumen: gramos y kcal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Tooltip(
                message: 'Total de gramos para este macronutriente',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 9,
                      ),
                    ),
                    Text(
                      '${data.gramsTotal.toStringAsFixed(0)} g',
                      style: TextStyle(
                        color: data.color,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: 'Kilocalorías aportadas',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'kcal',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 9,
                      ),
                    ),
                    Text(
                      data.kcal.toStringAsFixed(0),
                      style: TextStyle(
                        color: data.color,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroChartDonut extends StatefulWidget {
  final double proteinKcal;
  final double fatKcal;
  final double carbKcal;

  const _MacroChartDonut({
    required this.proteinKcal,
    required this.fatKcal,
    required this.carbKcal,
  });

  @override
  State<_MacroChartDonut> createState() => _MacroChartDonutState();
}

class _MacroChartDonutState extends State<_MacroChartDonut> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final total = widget.proteinKcal + widget.fatKcal + widget.carbKcal;

    // Si no hay datos, mostrar placeholder para evitar error o gráfica vacía
    if (total <= 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline_rounded,
              color: Colors.white24,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              'Sin datos para mostrar',
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      );
    }

    return Center(
      child: SizedBox(
        height: 200,
        width: 200,
        child: PieChart(
          PieChartData(
            pieTouchData: PieTouchData(
              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                setState(() {
                  if (!event.isInterestedForInteractions ||
                      pieTouchResponse == null ||
                      pieTouchResponse.touchedSection == null) {
                    touchedIndex = -1;
                    return;
                  }
                  touchedIndex =
                      pieTouchResponse.touchedSection!.touchedSectionIndex;
                });
              },
            ),
            borderData: FlBorderData(show: false),
            sectionsSpace: 3,
            centerSpaceRadius: 40,
            centerSpaceColor: const Color(0xFF1A1A2E),
            startDegreeOffset: -90,
            sections: _buildSections(total),
          ),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutQuad,
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildSections(double total) {
    // Colores base más vibrantes
    final pColorBase = Colors.greenAccent.shade400;
    final fColorBase = Colors.orangeAccent.shade400;
    final cColorBase = Colors.lightBlueAccent.shade400;

    final items = [
      _ChartItem(
        label: 'Proteínas',
        value: widget.proteinKcal,
        gradient: RadialGradient(
          colors: [pColorBase, pColorBase.withValues(alpha: 0.7)],
          stops: const [0.5, 1.0],
        ),
      ),
      _ChartItem(
        label: 'Grasas',
        value: widget.fatKcal,
        gradient: RadialGradient(
          colors: [fColorBase, fColorBase.withValues(alpha: 0.7)],
          stops: const [0.5, 1.0],
        ),
      ),
      _ChartItem(
        label: 'Carbs',
        value: widget.carbKcal,
        gradient: RadialGradient(
          colors: [cColorBase, cColorBase.withValues(alpha: 0.7)],
          stops: const [0.5, 1.0],
        ),
      ),
    ];

    return List.generate(items.length, (i) {
      final item = items[i];
      final isTouched = i == touchedIndex;
      final double radius = isTouched ? 54 : 46;
      final double fontSize = isTouched ? 14 : 12;
      final percent = (item.value / total * 100).toStringAsFixed(1);

      return PieChartSectionData(
        gradient: item.gradient,
        value: item.value,
        radius: radius,
        title: '$percent%',
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.8),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            Shadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        titlePositionPercentageOffset: 0.55,
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.15),
          width: 2,
        ),
      );
    });
  }
}

// Widget separado para la leyenda de macronutrientes
class _MacroChartLegend extends StatelessWidget {
  final double proteinKcal;
  final double fatKcal;
  final double carbKcal;

  const _MacroChartLegend({
    required this.proteinKcal,
    required this.fatKcal,
    required this.carbKcal,
  });

  @override
  Widget build(BuildContext context) {
    final pColor = Colors.greenAccent.shade400;
    final fColor = Colors.orangeAccent;
    final cColor = Colors.lightBlueAccent;
    final total = proteinKcal + fatKcal + carbKcal;

    if (total <= 0) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLegendItem(pColor, 'Proteínas', proteinKcal, total),
        const SizedBox(height: 8),
        _buildLegendItem(fColor, 'Grasas', fatKcal, total),
        const SizedBox(height: 8),
        _buildLegendItem(cColor, 'Carbohidratos', carbKcal, total),
      ],
    );
  }

  Widget _buildLegendItem(
    Color color,
    String label,
    double value,
    double total,
  ) {
    final percent = (value / total * 100).toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(40),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [color, color.withValues(alpha: 0.7)],
                stops: const [0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${value.toStringAsFixed(0)} kcal',
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                ),
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                  color: kTextColorSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartItem {
  final String label;
  final double value;
  final Gradient gradient;

  _ChartItem({
    required this.label,
    required this.value,
    required this.gradient,
  });
}

class _EnergySummaryHeader extends StatelessWidget {
  final double baseKcal;
  final double kcalAdjustment;
  final double proteinGrams;
  final double fatGrams;
  final double carbGrams;

  const _EnergySummaryHeader({
    required this.baseKcal,
    required this.kcalAdjustment,
    required this.proteinGrams,
    required this.fatGrams,
    required this.carbGrams,
  });

  // Calcular kcal por macro
  double get proteinKcal => proteinGrams * 4;
  double get fatKcal => fatGrams * 9;
  double get carbKcal => carbGrams * 4;

  // Calcular porcentajes
  double _getPercentage(double kcal) {
    if (baseKcal <= 0) return 0;
    return (kcal / baseKcal) * 100;
  }

  @override
  Widget build(BuildContext context) {
    String strategyText;
    Color strategyColor;
    IconData strategyIcon;

    if (kcalAdjustment < -10) {
      strategyText = 'DÉFICIT';
      strategyColor = Colors.orangeAccent;
      strategyIcon = Icons.trending_down;
    } else if (kcalAdjustment > 10) {
      strategyText = 'SUPERÁVIT';
      strategyColor = kSuccessColor;
      strategyIcon = Icons.trending_up;
    } else {
      strategyText = 'MANTENIMIENTO';
      strategyColor = kTextColorSecondary;
      strategyIcon = Icons.balance;
    }

    return ClinicSectionSurface(
      icon: Icons.energy_savings_leaf,
      title: 'Distribución del Día',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- ENCABEZADO: KCAL TOTAL + ESTRATEGIA ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Columna 1: Kcal principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Objetivo Energético',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          baseKcal.toStringAsFixed(0),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'kcal',
                          style: TextStyle(
                            color: kPrimaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Columna 2: Badge de estrategia
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: strategyColor.withAlpha(38),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: strategyColor.withAlpha(102)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(strategyIcon, color: strategyColor, size: 16),
                    const SizedBox(height: 4),
                    Text(
                      strategyText,
                      style: TextStyle(
                        color: strategyColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // --- TABLA DE MACROS CON DETALLES ---
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(5),
              border: Border.all(color: Colors.white10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                // Encabezados de tabla
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(51),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Macro',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Gramos',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'kcal',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '%',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
                // Fila: Proteínas
                _buildMacroRow(
                  'Proteínas',
                  proteinGrams,
                  proteinKcal,
                  _getPercentage(proteinKcal),
                  Colors.greenAccent.shade400,
                ),
                // Divider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Divider(color: Colors.white10, height: 0.5),
                ),
                // Fila: Grasas
                _buildMacroRow(
                  'Grasas',
                  fatGrams,
                  fatKcal,
                  _getPercentage(fatKcal),
                  Colors.orangeAccent,
                ),
                // Divider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Divider(color: Colors.white10, height: 0.5),
                ),
                // Fila: Carbohidratos
                _buildMacroRow(
                  'Carbohidratos',
                  carbGrams,
                  carbKcal,
                  _getPercentage(carbKcal),
                  Colors.lightBlueAccent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroRow(
    String label,
    double grams,
    double kcal,
    double percentage,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              '${grams.toStringAsFixed(0)} g',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            child: Text(
              kcal.toStringAsFixed(0),
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            child: Text(
              '${percentage.toStringAsFixed(0)}%',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClinicalValidationCard extends StatelessWidget {
  final double proteinGPerKg;
  final MacroRange? proteinRange;
  final String proteinCategory;
  final double proteinGrams;
  final double proteinKcal;
  final double fatGPerKg;
  final MacroRange? fatRange;
  final String fatCategory;
  final double fatGrams;
  final double fatKcal;
  final double carbGPerKg;
  final MacroRange? carbRange;
  final String carbCategory;
  final double carbGrams;
  final double carbKcal;
  final double totalKcal;
  final double weightKg;

  const _ClinicalValidationCard({
    required this.proteinGPerKg,
    required this.proteinRange,
    required this.proteinCategory,
    required this.proteinGrams,
    required this.proteinKcal,
    required this.fatGPerKg,
    required this.fatRange,
    required this.fatCategory,
    required this.fatGrams,
    required this.fatKcal,
    required this.carbGPerKg,
    required this.carbRange,
    required this.carbCategory,
    required this.carbGrams,
    required this.carbKcal,
    required this.totalKcal,
    required this.weightKg,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ANÁLISIS CLÍNICO DEL DÍA',
          style: TextStyle(
            color: kPrimaryColor,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        // Análisis de proteína
        _ClinicalMetricRow(
          icon: Icons.fitness_center,
          label: 'Proteína',
          value: '${proteinGPerKg.toStringAsFixed(1)} g/kg',
          status: _getProteinStatus(),
          detail: _getProteinDetail(),
        ),
        const SizedBox(height: 10),
        // Análisis de grasas
        _ClinicalMetricRow(
          icon: Icons.water_drop_outlined,
          label: 'Grasas',
          value: '${fatGPerKg.toStringAsFixed(1)} g/kg',
          status: _getFatStatus(),
          detail: _getFatDetail(),
        ),
        const SizedBox(height: 10),
        // Análisis de carbohidratos
        _ClinicalMetricRow(
          icon: Icons.local_fire_department_outlined,
          label: 'Carbohidratos',
          value: '${carbGPerKg.toStringAsFixed(1)} g/kg',
          status: _getCarbStatus(),
          detail: _getCarbDetail(),
        ),
      ],
    );
  }

  MetricStatus _getProteinStatus() {
    if (proteinRange == null) return MetricStatus.invalid;
    if (proteinGPerKg < proteinRange!.min) return MetricStatus.warning;
    if (proteinGPerKg > proteinRange!.max) return MetricStatus.caution;
    return MetricStatus.valid;
  }

  String _getProteinDetail() {
    if (proteinRange == null) return 'Sin rango definido';
    final min = proteinRange!.min;
    final max = proteinRange!.max;

    if (proteinGPerKg < min) {
      final deficit = (min - proteinGPerKg);
      return 'Bajo rango ${min.toStringAsFixed(1)}-${max.toStringAsFixed(1)} (-${deficit.toStringAsFixed(1)} g/kg)';
    }
    if (proteinGPerKg > max) {
      final excess = (proteinGPerKg - max);
      return 'Sobre rango ${min.toStringAsFixed(1)}-${max.toStringAsFixed(1)} (+${excess.toStringAsFixed(1)} g/kg)';
    }
    return 'Rango óptimo: ${min.toStringAsFixed(1)}-${max.toStringAsFixed(1)} g/kg • $proteinCategory';
  }

  MetricStatus _getFatStatus() {
    if (fatRange == null) return MetricStatus.invalid;
    if (fatGPerKg < fatRange!.min) return MetricStatus.warning;
    if (fatGPerKg > fatRange!.max) return MetricStatus.caution;
    return MetricStatus.valid;
  }

  String _getFatDetail() {
    if (fatRange == null) return 'Sin rango definido';
    final min = fatRange!.min;
    final max = fatRange!.max;

    if (fatGPerKg < min) {
      final deficit = (min - fatGPerKg);
      return 'Bajo rango ${min.toStringAsFixed(1)}-${max.toStringAsFixed(1)} (-${deficit.toStringAsFixed(1)} g/kg)';
    }
    if (fatGPerKg > max) {
      final excess = (fatGPerKg - max);
      return 'Sobre rango ${min.toStringAsFixed(1)}-${max.toStringAsFixed(1)} (+${excess.toStringAsFixed(1)} g/kg)';
    }
    return 'Rango óptimo: ${min.toStringAsFixed(1)}-${max.toStringAsFixed(1)} g/kg • $fatCategory';
  }

  MetricStatus _getCarbStatus() {
    if (carbRange == null) return MetricStatus.invalid;
    if (carbGPerKg < carbRange!.min) return MetricStatus.warning;
    if (carbGPerKg > carbRange!.max) return MetricStatus.caution;
    return MetricStatus.valid;
  }

  String _getCarbDetail() {
    if (carbRange == null) return 'Sin rango definido';
    final min = carbRange!.min;
    final max = carbRange!.max;

    if (carbGPerKg < min) {
      final deficit = (min - carbGPerKg);
      return 'Bajo rango ${min.toStringAsFixed(1)}-${max.toStringAsFixed(1)} (-${deficit.toStringAsFixed(1)} g/kg)';
    }
    if (carbGPerKg > max) {
      final excess = (carbGPerKg - max);
      return 'Sobre rango ${min.toStringAsFixed(1)}-${max.toStringAsFixed(1)} (+${excess.toStringAsFixed(1)} g/kg)';
    }
    return 'Rango óptimo: ${min.toStringAsFixed(1)}-${max.toStringAsFixed(1)} g/kg • $carbCategory';
  }
}

enum MetricStatus { valid, warning, caution, invalid }

class _ClinicalMetricRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final MetricStatus status;
  final String detail;

  const _ClinicalMetricRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.status,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final statusConfig = _getStatusConfig();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: statusConfig.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: statusConfig.color, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Icon(statusConfig.icon, color: statusConfig.color, size: 14),
              const SizedBox(width: 6),
              Text(
                value,
                style: TextStyle(
                  color: statusConfig.color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 9,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig() {
    switch (status) {
      case MetricStatus.valid:
        return _StatusConfig(
          color: Colors.green.shade400,
          icon: Icons.check_circle,
        );
      case MetricStatus.warning:
        return _StatusConfig(
          color: Colors.orange.shade400,
          icon: Icons.warning_amber,
        );
      case MetricStatus.caution:
        return _StatusConfig(color: Colors.amber.shade400, icon: Icons.info);
      case MetricStatus.invalid:
        return _StatusConfig(
          color: Colors.red.shade400,
          icon: Icons.error_outline,
        );
    }
  }
}

class _StatusConfig {
  final Color color;
  final IconData icon;

  _StatusConfig({required this.color, required this.icon});
}

class _MacroTableRowData {
  final String label;
  final String category;
  final List<String> categoryOptions;
  final List<double> valueOptions;
  final double selectedValue;
  final double gramsTotal;
  final double kcal;
  final ValueChanged<String>? onCategoryChanged;
  final ValueChanged<double>? onValueChanged;
  final bool enabled;
  final Color color;

  _MacroTableRowData({
    required this.label,
    required this.category,
    required this.categoryOptions,
    required this.valueOptions,
    required this.selectedValue,
    required this.gramsTotal,
    required this.kcal,
    this.onCategoryChanged,
    this.onValueChanged,
    required this.enabled,
    required this.color,
  });
}
