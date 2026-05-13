import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/core/constants/nutrition_extra_keys.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/daily_macro_settings.dart';
import 'package:hcs_app_lap/features/macros_feature/widgets/macro_day_view_data.dart';
import 'package:hcs_app_lap/features/macros_feature/widgets/weekly_macros_layout.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/features/main_shell/providers/global_date_provider.dart';
import 'package:hcs_app_lap/utils/date_helpers.dart';
import 'package:hcs_app_lap/utils/nutrition_record_helpers.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:intl/intl.dart';

enum _MacrosMode { idle, view, editing, creating }

class MacrosContent extends ConsumerStatefulWidget {
  const MacrosContent({super.key});

  @override
  ConsumerState<MacrosContent> createState() => MacrosContentState();
}

class MacrosContentState extends ConsumerState<MacrosContent> {
  static const List<String> _days = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  _MacrosMode _mode = _MacrosMode.idle;
  String? _selectedRecordDateIso;
  String? _optimisticRecordDateIso;
  Map<String, DailyMacroSettings>? _optimisticWeek;
  int _selectedDayIndex = 0;

  String get _activeDateIso => dateIsoFrom(ref.read(globalDateProvider));

  Future<void> saveIfDirty() async {
    final client = ref.read(clientsProvider).value?.activeClient;
    if (client == null || _mode == _MacrosMode.idle) return;

    final recordDateIso = _selectedRecordDateIso ?? _activeDateIso;
    final records = readNutritionRecordList(
      client.nutrition.extra[NutritionExtraKeys.macrosRecords],
    );
    final record = nutritionRecordForDate(records, recordDateIso);
    final parsedWeek =
        parseWeeklyMacroSettings(record?['weeklyMacroSettings']) ??
        _completeWeek(client);
    final week = _optimisticRecordDateIso == recordDateIso
        ? (_optimisticWeek ?? parsedWeek)
        : parsedWeek;

    await _updateClientWeek(week, recordDateIso);
  }

  void resetDrafts() {
    setState(() {
      _mode = _MacrosMode.idle;
      _selectedRecordDateIso = null;
      _optimisticRecordDateIso = null;
      _optimisticWeek = null;
      _selectedDayIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsProvider);

    return clientsAsync.when(
      data: (state) {
        final client = state.activeClient;
        if (client == null) {
          return const Center(
            child: Text(
              'Selecciona un cliente para trabajar macros.',
              style: TextStyle(color: kTextColorSecondary),
            ),
          );
        }

        final activeDateIso = dateIsoFrom(ref.watch(globalDateProvider));
        final macroRecords = readNutritionRecordList(
          client.nutrition.extra[NutritionExtraKeys.macrosRecords],
        );

        if (_mode == _MacrosMode.idle) {
          return _buildMacrosHistoryGrid(macroRecords, activeDateIso);
        }

        final displayedMacrosDateIso = _resolveDisplayedMacrosDateIso(
          macroRecords,
          activeDateIso,
        );
        final macroRecord =
            nutritionRecordForDate(macroRecords, displayedMacrosDateIso) ??
            latestNutritionRecordByDate(macroRecords);
        final parsedWeek =
            parseWeeklyMacroSettings(macroRecord?['weeklyMacroSettings']) ??
            _completeWeek(client);
        final week = _optimisticRecordDateIso == displayedMacrosDateIso
            ? (_optimisticWeek ?? parsedWeek)
            : parsedWeek;

        final evalRecords = readNutritionRecordList(
          client.nutrition.extra[NutritionExtraKeys.evaluationRecords],
        );
        final evalRecord =
            nutritionRecordForDate(evalRecords, displayedMacrosDateIso) ??
            latestNutritionRecordByDate(evalRecords);
        final dailyKcal =
            parseDailyKcalMap(evalRecord?['dailyKcal']) ??
            client.nutrition.dailyKcal;
        final maintenanceKcal =
            (evalRecord?['avgGet'] as num?)?.toDouble() ??
            (evalRecord?['maintenanceKcal'] as num?)?.toDouble() ??
            (evalRecord?['maintenanceCalories'] as num?)?.toDouble() ??
            client.kcal?.toDouble() ??
            (evalRecord?['kcal'] as num?)?.toDouble() ??
            2000.0;
        final dailyMaintenance = _parseDailyMaintenanceMap(evalRecord);

        return Column(
          children: [
            Expanded(
              child: Builder(
                builder: (context) {
                  final macroDayViewData = _buildMacroDayViewData(
                    client: client,
                    week: week,
                    dailyKcal: dailyKcal,
                    dailyMaintenance: dailyMaintenance,
                    maintenanceKcal: maintenanceKcal,
                  );

                  final safeSelectedIndex = _selectedDayIndex.clamp(
                    0,
                    macroDayViewData.length - 1,
                  );

                  return WeeklyMacrosLayout(
                    days: macroDayViewData,
                    selectedIndex: safeSelectedIndex,
                    onSelectDay: (index) {
                      setState(() {
                        _selectedDayIndex = index;
                      });
                    },
                    onChangedSelectedDay: (newSettings) {
                      final selectedDay = macroDayViewData[safeSelectedIndex];

                      _handleMacroDayChanged(
                        dayName: selectedDay.dayName,
                        newSettings: newSettings,
                        currentWeek: week,
                        recordDateIso: displayedMacrosDateIso,
                        client: client,
                        dailyKcal: dailyKcal,
                        maintenanceKcal: maintenanceKcal,
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: _buildActionButtons(displayedMacrosDateIso),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text(
          'Error al cargar macros: $error',
          style: const TextStyle(color: kErrorColor),
        ),
      ),
    );
  }

  Widget _buildMacrosHistoryGrid(
    List<Map<String, dynamic>> macroRecords,
    String activeDateIso,
  ) {
    final sortedRecords = [...macroRecords]
      ..sort((a, b) {
        final aIso =
            _normalizeDateIso(a['dateIso']) ??
            _normalizeDateIso(a['date']) ??
            activeDateIso;
        final bIso =
            _normalizeDateIso(b['dateIso']) ??
            _normalizeDateIso(b['date']) ??
            activeDateIso;
        return bIso.compareTo(aIso);
      });

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Historial de macronutrientes',
                      style: TextStyle(
                        color: kTextColor,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Registros semanales por fecha',
                      style: TextStyle(color: kTextColorSecondary),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () async {
                  await _createNewMacrosRecord(activeDateIso);
                },
                icon: const Icon(Icons.add),
                label: const Text('Nuevo registro'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: sortedRecords.isEmpty
                ? _EmptyMacrosHistory(
                    onCreate: () => _createNewMacrosRecord(activeDateIso),
                  )
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 220,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.9,
                        ),
                    itemCount: sortedRecords.length,
                    itemBuilder: (context, index) {
                      final record = sortedRecords[index];
                      final iso =
                          _normalizeDateIso(record['dateIso']) ??
                          _normalizeDateIso(record['date']) ??
                          activeDateIso;
                      return _MacroRecordCard(
                        dateIso: iso,
                        onOpen: () {
                          setState(() {
                            _selectedRecordDateIso = iso;
                            _optimisticRecordDateIso = null;
                            _optimisticWeek = null;
                            _selectedDayIndex = 0;
                            _mode = _MacrosMode.view;
                          });
                        },
                        onDelete: () => _confirmAndDeleteMacrosRecord(iso),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String displayedMacrosDateIso) {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: () async {
            await _saveTabIfNeeded(_selectedDayIndex);
            if (!mounted) return;
            setState(() {
              _mode = _MacrosMode.idle;
              _selectedRecordDateIso = null;
              _optimisticRecordDateIso = null;
              _optimisticWeek = null;
              _selectedDayIndex = 0;
            });
          },
          icon: const Icon(Icons.arrow_back),
          label: const Text('Volver'),
        ),
        const Spacer(),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
          ),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Eliminar registro'),
                content: const Text('¿Deseas eliminar este registro?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Eliminar'),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              await _deleteMacrosRecord(displayedMacrosDateIso);
            }
          },
          icon: const Icon(Icons.delete_outline),
          label: const Text('Borrar'),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: () async {
            await saveIfDirty();
            await _showSavedFeedback();
          },
          icon: const Icon(Icons.save_outlined),
          label: const Text('Guardar'),
        ),
      ],
    );
  }

  double _kcalForDay(
    String day,
    Map<String, int>? dailyKcal,
    double maintenanceKcal,
  ) {
    if (dailyKcal == null || dailyKcal.isEmpty) return maintenanceKcal;

    final normalized = _normalizeDay(day);

    final direct = dailyKcal[day];
    if (direct != null && direct > 0) return direct.toDouble();

    double? found;
    for (final entry in dailyKcal.entries) {
      if (_normalizeDay(entry.key) == normalized && entry.value > 0) {
        found = entry.value.toDouble();
        break;
      }
    }

    return found ?? maintenanceKcal;
  }

  Map<String, double> _parseDailyMaintenanceMap(Map<String, dynamic>? record) {
    if (record == null) return const {};

    const possibleKeys = [
      'dailyGet',
      'dailyMaintenanceKcal',
      'dailyMaintenanceCalories',
      'maintenanceByDay',
      'maintenanceKcalByDay',
      'dailyTdee',
      'tdeeByDay',
    ];

    for (final key in possibleKeys) {
      final raw = record[key];
      if (raw is Map) {
        final parsed = <String, double>{};

        raw.forEach((key, value) {
          if (key == null || value == null) return;
          final parsedValue = value is num
              ? value.toDouble()
              : double.tryParse(value.toString());
          if (parsedValue != null && parsedValue > 0) {
            parsed[key.toString()] = parsedValue;
          }
        });

        if (parsed.isNotEmpty) return parsed;
      }
    }

    return const {};
  }

  double _maintenanceForDay({
    required String day,
    required Map<String, double> dailyMaintenance,
    required double fallbackMaintenance,
  }) {
    final normalized = _normalizeDay(day);

    final direct = dailyMaintenance[day];
    if (direct != null && direct > 0) return direct;

    for (final entry in dailyMaintenance.entries) {
      if (_normalizeDay(entry.key) == normalized && entry.value > 0) {
        return entry.value;
      }
    }

    return fallbackMaintenance;
  }

  DailyMacroSettings _computeSettingsWithAutomaticCarbs({
    required DailyMacroSettings settings,
    required double weightKg,
    required double targetKcal,
  }) {
    final safeWeight = weightKg > 0 ? weightKg : 70.0;
    final proteinKcal = settings.proteinSelected * safeWeight * 4;
    final fatKcal = settings.fatSelected * safeWeight * 9;
    final remainingKcal = targetKcal - proteinKcal - fatKcal;
    final carbGPerKg = (remainingKcal / 4) / safeWeight;

    return settings.copyWith(
      carbSelected: carbGPerKg,
      totalCalories: targetKcal,
    );
  }

  List<MacroDayViewData> _buildMacroDayViewData({
    required Client client,
    required Map<String, DailyMacroSettings> week,
    required Map<String, int>? dailyKcal,
    required Map<String, double> dailyMaintenance,
    required double maintenanceKcal,
  }) {
    final weightKg = client.lastWeight ?? 70.0;
    final baseSettings =
        _settingsForDay(week, _days.first) ??
        DailyMacroSettings.defaultFor(
          goalType: _goalType(client),
          weightKg: weightKg,
          maintenanceKcal: maintenanceKcal,
        );

    return List<MacroDayViewData>.generate(_days.length, (index) {
      final dayName = _days[index];
      final isBase = index == 0;
      final rawSettings =
          _settingsForDay(week, dayName) ??
          DailyMacroSettings.defaultFor(
            goalType: _goalType(client),
            weightKg: weightKg,
            maintenanceKcal: maintenanceKcal,
          );

      final isCustomized =
          rawSettings.isCustomizedFromBase || rawSettings.isCustom;
      final inheritedSettings = !isBase && !isCustomized
          ? baseSettings.copyWith(
              dayOfWeek: dayName,
              isCustomizedFromBase: false,
              isCustom: false,
            )
          : rawSettings.copyWith(
              dayOfWeek: dayName,
              isCustomizedFromBase: !isBase && isCustomized,
              isCustom: !isBase && isCustomized,
            );

      final targetKcal = _kcalForDay(dayName, dailyKcal, maintenanceKcal);
      final dayMaintenanceKcal = _maintenanceForDay(
        day: dayName,
        dailyMaintenance: dailyMaintenance,
        fallbackMaintenance: maintenanceKcal,
      );

      final finalSettings = _computeSettingsWithAutomaticCarbs(
        settings: inheritedSettings,
        weightKg: weightKg,
        targetKcal: targetKcal,
      );

      final subtitle = _activitySubtitleForDay(
        isBase: isBase,
        dayMaintenanceKcal: dayMaintenanceKcal,
        dailyMaintenance: dailyMaintenance,
      );

      return MacroDayViewData.fromSettings(
        dayName: dayName,
        settings: finalSettings,
        isBase: isBase,
        weightKg: weightKg,
        targetKcal: targetKcal,
        maintenanceKcal: dayMaintenanceKcal,
        subtitle: subtitle,
      );
    });
  }

  String _activitySubtitleForDay({
    required bool isBase,
    required double dayMaintenanceKcal,
    required Map<String, double> dailyMaintenance,
  }) {
    final values = dailyMaintenance.values.where((value) => value > 0).toList();
    if (values.length >= 2) {
      final minMaintenance = values.reduce((a, b) => a < b ? a : b);
      final maxMaintenance = values.reduce((a, b) => a > b ? a : b);

      if ((maxMaintenance - minMaintenance).abs() >= 75) {
        if (dayMaintenanceKcal >= maxMaintenance - 10) {
          return 'Entrenamiento / gimnasio';
        }
        if (dayMaintenanceKcal <= minMaintenance + 10) {
          return 'Descanso / sin gimnasio';
        }
      }
    }

    return isBase ? 'Entrenamiento' : 'Plan diario';
  }

  void _handleMacroDayChanged({
    required String dayName,
    required DailyMacroSettings newSettings,
    required Map<String, DailyMacroSettings> currentWeek,
    required String recordDateIso,
    required Client client,
    required Map<String, int>? dailyKcal,
    required double maintenanceKcal,
  }) {
    final updatedWeek = Map<String, DailyMacroSettings>.from(currentWeek);
    final isBase = dayName == _days.first;
    final weightKg = client.lastWeight ?? 70.0;

    if (isBase) {
      final baseTargetKcal = _kcalForDay(dayName, dailyKcal, maintenanceKcal);
      final baseWithCarbs = _computeSettingsWithAutomaticCarbs(
        settings: newSettings.copyWith(
          dayOfWeek: dayName,
          isCustomizedFromBase: false,
          isCustom: false,
        ),
        weightKg: weightKg,
        targetKcal: baseTargetKcal,
      );

      updatedWeek[dayName] = baseWithCarbs;

      for (final otherDay in _days.skip(1)) {
        final existing = updatedWeek[otherDay];
        final existingIsCustom =
            existing?.isCustomizedFromBase == true ||
            existing?.isCustom == true;

        if (existing == null || !existingIsCustom) {
          final targetKcal = _kcalForDay(otherDay, dailyKcal, maintenanceKcal);
          updatedWeek[otherDay] = _computeSettingsWithAutomaticCarbs(
            settings: baseWithCarbs.copyWith(
              dayOfWeek: otherDay,
              isCustomizedFromBase: false,
              isCustom: false,
            ),
            weightKg: weightKg,
            targetKcal: targetKcal,
          );
        }
      }
    } else {
      final targetKcal = _kcalForDay(dayName, dailyKcal, maintenanceKcal);

      if (!newSettings.isCustomizedFromBase && !newSettings.isCustom) {
        final monday =
            _settingsForDay(updatedWeek, _days.first) ??
            DailyMacroSettings.defaultFor(
              goalType: _goalType(client),
              weightKg: weightKg,
              maintenanceKcal: maintenanceKcal,
            );

        updatedWeek[dayName] = _computeSettingsWithAutomaticCarbs(
          settings: monday.copyWith(
            dayOfWeek: dayName,
            isCustomizedFromBase: false,
            isCustom: false,
          ),
          weightKg: weightKg,
          targetKcal: targetKcal,
        );
      } else {
        updatedWeek[dayName] = _computeSettingsWithAutomaticCarbs(
          settings: newSettings.copyWith(
            dayOfWeek: dayName,
            isCustomizedFromBase: true,
            isCustom: true,
          ),
          weightKg: weightKg,
          targetKcal: targetKcal,
        );
      }
    }

    setState(() {
      if (_mode == _MacrosMode.view) {
        _mode = _MacrosMode.editing;
      }
      _optimisticRecordDateIso = recordDateIso;
      _optimisticWeek = updatedWeek;
    });
    unawaited(_updateClientWeek(updatedWeek, recordDateIso));
  }

  Future<void> _updateClientWeek(
    Map<String, DailyMacroSettings> updatedWeek,
    String recordDateIso,
  ) async {
    final normalizedDate = _normalizeDateIso(recordDateIso) ?? recordDateIso;

    await ref.read(clientsProvider.notifier).updateActiveClient((current) {
      final extra = Map<String, dynamic>.from(current.nutrition.extra);
      final records = readNutritionRecordList(
        extra[NutritionExtraKeys.macrosRecords],
      );

      records.removeWhere(
        (record) =>
            _normalizeDateIso(record['dateIso'] ?? record['date']) ==
            normalizedDate,
      );
      records.add({
        'dateIso': normalizedDate,
        'weeklyMacroSettings': updatedWeek.map(
          (key, value) => MapEntry(key, value.toJson()),
        ),
      });
      sortNutritionRecordsByDate(records);

      extra[NutritionExtraKeys.macrosRecords] = records;
      extra[NutritionExtraKeys.selectedMacrosRecordDateIso] = normalizedDate;

      return current.copyWith(
        nutrition: current.nutrition.copyWith(
          extra: extra,
          weeklyMacroSettings: updatedWeek,
        ),
      );
    });
  }

  Future<void> _saveTabIfNeeded(int tabIndex) async {
    final _ = tabIndex;
    await saveIfDirty();
  }

  Future<void> _createNewMacrosRecord(String dateIso) async {
    await ref.read(clientsProvider.notifier).updateActiveClient((current) {
      final normalizedDate = _normalizeDateIso(dateIso) ?? dateIso;
      final extra = Map<String, dynamic>.from(current.nutrition.extra);
      final records = readNutritionRecordList(
        extra[NutritionExtraKeys.macrosRecords],
      );

      final exists = records.any(
        (record) =>
            _normalizeDateIso(record['dateIso'] ?? record['date']) ==
            normalizedDate,
      );
      if (!exists) {
        final week = _completeWeek(current);
        records.add({
          'dateIso': normalizedDate,
          'weeklyMacroSettings': week.map((key, value) {
            return MapEntry(key, value.toJson());
          }),
        });
      }

      sortNutritionRecordsByDate(records);
      extra[NutritionExtraKeys.macrosRecords] = records;
      extra[NutritionExtraKeys.selectedMacrosRecordDateIso] = normalizedDate;

      return current.copyWith(
        nutrition: current.nutrition.copyWith(
          extra: extra,
          weeklyMacroSettings: _completeWeek(current),
        ),
      );
    });

    if (!mounted) return;
    setState(() {
      _selectedRecordDateIso = _normalizeDateIso(dateIso) ?? dateIso;
      _optimisticRecordDateIso = null;
      _optimisticWeek = null;
      _selectedDayIndex = 0;
      _mode = _MacrosMode.creating;
    });
  }

  Future<void> _confirmAndDeleteMacrosRecord(String dateIso) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar registro'),
        content: const Text('¿Deseas eliminar este registro?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteMacrosRecord(dateIso);
    }
  }

  Future<void> _deleteMacrosRecord(String dateIso) async {
    await ref.read(clientsProvider.notifier).updateActiveClient((current) {
      final normalizedDate = _normalizeDateIso(dateIso) ?? dateIso;
      final extra = Map<String, dynamic>.from(current.nutrition.extra);
      final records = readNutritionRecordList(
        extra[NutritionExtraKeys.macrosRecords],
      );

      records.removeWhere(
        (record) =>
            _normalizeDateIso(record['dateIso'] ?? record['date']) ==
            normalizedDate,
      );
      sortNutritionRecordsByDate(records);
      extra[NutritionExtraKeys.macrosRecords] = records;

      final latestRecord = latestNutritionRecordByDate(records);
      final syncedWeeklyMacros = parseWeeklyMacroSettings(
        latestRecord?['weeklyMacroSettings'],
      );

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
      _optimisticRecordDateIso = null;
      _optimisticWeek = null;
      _selectedDayIndex = 0;
      _mode = _MacrosMode.idle;
    });
  }

  String _resolveDisplayedMacrosDateIso(
    List<Map<String, dynamic>> macroRecords,
    String activeDateIso,
  ) {
    final selected = _normalizeDateIso(_selectedRecordDateIso);
    if (selected != null) return selected;

    final selectedFromExtra = _normalizeDateIso(
      ref
          .read(clientsProvider)
          .value
          ?.activeClient
          ?.nutrition
          .extra[NutritionExtraKeys.selectedMacrosRecordDateIso],
    );
    if (selectedFromExtra != null) return selectedFromExtra;

    final activeRecord = nutritionRecordForDate(macroRecords, activeDateIso);
    if (activeRecord != null) return activeDateIso;

    final latestRecord = latestNutritionRecordByDate(macroRecords);
    return _normalizeDateIso(
          latestRecord?['dateIso'] ?? latestRecord?['date'],
        ) ??
        activeDateIso;
  }

  Map<String, DailyMacroSettings> _completeWeek(Client client) {
    final maintenanceKcal = client.kcal?.toDouble() ?? 2000.0;
    final weightKg = client.lastWeight ?? 70.0;
    final source =
        client.effectiveWeeklyMacros ??
        client.nutrition.weeklyMacroSettings ??
        const <String, DailyMacroSettings>{};
    final result = <String, DailyMacroSettings>{};

    for (final day in _days) {
      final settings =
          _settingsForDay(source, day) ??
          DailyMacroSettings.defaultFor(
            goalType: _goalType(client),
            weightKg: weightKg,
            maintenanceKcal: maintenanceKcal,
          );
      result[day] = _computeSettingsWithAutomaticCarbs(
        settings: settings.copyWith(dayOfWeek: day),
        weightKg: weightKg,
        targetKcal: maintenanceKcal,
      );
    }

    return result;
  }

  DailyMacroSettings? _settingsForDay(
    Map<String, DailyMacroSettings> settings,
    String day,
  ) {
    final direct = settings[day];
    if (direct != null) return direct;

    final normalized = _normalizeDay(day);
    for (final entry in settings.entries) {
      if (_normalizeDay(entry.key) == normalized) {
        return entry.value;
      }
    }

    return null;
  }

  Future<void> _showSavedFeedback() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Macros guardados localmente'),
        duration: Duration(seconds: 1),
        backgroundColor: kPrimaryColor,
      ),
    );
  }

  String _goalType(Client client) {
    return client.profile.objective.trim().isEmpty
        ? 'Mantenimiento'
        : client.profile.objective;
  }

  String? _normalizeDateIso(dynamic raw) {
    if (raw == null) return null;
    final value = raw.toString().trim();
    if (value.isEmpty) return null;

    final parsed = DateTime.tryParse(value);
    if (parsed != null) return dateIsoFrom(parsed);

    final match = RegExp(r'^(\d{4}-\d{2}-\d{2})').firstMatch(value);
    final extracted = match?.group(1);
    if (extracted == null) return null;

    final parsedExtracted = DateTime.tryParse(extracted);
    return parsedExtracted == null ? null : dateIsoFrom(parsedExtracted);
  }

  String _normalizeDay(String value) {
    return value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('Á', 'a')
        .replaceAll('É', 'e')
        .replaceAll('Í', 'i')
        .replaceAll('Ó', 'o')
        .replaceAll('Ú', 'u');
  }
}

class _EmptyMacrosHistory extends StatelessWidget {
  final Future<void> Function() onCreate;

  const _EmptyMacrosHistory({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: kCardColor.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.monitor_weight_outlined,
              color: kTextColorSecondary,
              size: 38,
            ),
            const SizedBox(height: 12),
            const Text(
              'No hay registros de macros.',
              style: TextStyle(
                color: kTextColor,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Crea un registro semanal para editar la distribución.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kTextColorSecondary),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                unawaited(onCreate());
              },
              icon: const Icon(Icons.add),
              label: const Text('Nuevo registro'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroRecordCard extends StatelessWidget {
  final String dateIso;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _MacroRecordCard({
    required this.dateIso,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final parsed = DateTime.tryParse(dateIso);
    final label = parsed == null
        ? dateIso
        : DateFormat('dd/MM/yyyy').format(parsed);

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kCardColor.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  color: kInfoColor,
                  size: 22,
                ),
                const Spacer(),
                IconButton(
                  onPressed: onDelete,
                  tooltip: 'Borrar',
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              label,
              style: const TextStyle(
                color: kTextColor,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              dateIso,
              style: const TextStyle(color: kTextColorSecondary, fontSize: 12),
            ),
            const SizedBox(height: 14),
            const Row(
              children: [
                Text(
                  'Abrir semana',
                  style: TextStyle(
                    color: kInfoColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Spacer(),
                Icon(Icons.chevron_right_rounded, color: kInfoColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
