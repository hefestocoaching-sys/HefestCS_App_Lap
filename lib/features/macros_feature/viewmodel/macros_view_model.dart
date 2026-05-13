import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/core/constants/nutrition_extra_keys.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/daily_macro_settings.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/utils/nutrition_record_helpers.dart';

class MacrosViewModel {
  final Ref ref;

  MacrosViewModel(this.ref);

  Future<Client> _updateDay({
    required Client client,
    required String day,
    required String recordDateIso,
    required DailyMacroSettings Function(
      DailyMacroSettings,
      Map<String, DailyMacroSettings>,
    )
    transform,
  }) async {
    var updatedClient = client;

    await ref.read(clientsProvider.notifier).updateActiveClient((current) {
      updatedClient = _applyDayUpdate(
        client: current,
        day: day,
        recordDateIso: recordDateIso,
        transform: transform,
      );
      return updatedClient;
    });

    return updatedClient;
  }

  Client _applyDayUpdate({
    required Client client,
    required String day,
    required String recordDateIso,
    required DailyMacroSettings Function(
      DailyMacroSettings,
      Map<String, DailyMacroSettings>,
    )
    transform,
  }) {
    final extra = Map<String, dynamic>.from(client.nutrition.extra);
    final records = readNutritionRecordList(
      extra[NutritionExtraKeys.macrosRecords],
    );
    final recordIndex = records.indexWhere((r) {
      final rawDate = r['dateIso'] ?? r['date'];
      if (rawDate == null) return false;
      return rawDate.toString().startsWith(recordDateIso);
    });

    Map<String, DailyMacroSettings> oldWeek = {};
    if (recordIndex != -1) {
      oldWeek =
          parseWeeklyMacroSettings(
            records[recordIndex]['weeklyMacroSettings'],
          ) ??
          {};
    } else {
      oldWeek =
          client.effectiveWeeklyMacros ??
          client.nutrition.weeklyMacroSettings ??
          {};
    }

    final oldDay = _settingsForDay(oldWeek, day);
    final newDay = transform(oldDay, oldWeek);

    final newWeek = Map<String, DailyMacroSettings>.from(oldWeek);
    newWeek[day] = newDay;

    if (day == 'Lunes') {
      for (final inheritedDay in const [
        'Martes',
        'Mi\u00e9rcoles',
        'Jueves',
        'Viernes',
        'S\u00e1bado',
        'Domingo',
      ]) {
        final inheritedSettings = _settingsForDay(newWeek, inheritedDay);
        if (!inheritedSettings.isCustom &&
            !inheritedSettings.isCustomizedFromBase) {
          newWeek[inheritedDay] = newDay.copyWith(
            dayOfWeek: inheritedDay,
            isCustom: false,
            isCustomizedFromBase: false,
          );
        }
      }
    }

    if (recordIndex != -1) {
      records.removeAt(recordIndex);
    }
    records.add({
      'dateIso': recordDateIso,
      'weeklyMacroSettings': newWeek.map((k, v) => MapEntry(k, v.toJson())),
    });
    sortNutritionRecordsByDate(records);

    extra[NutritionExtraKeys.macrosRecords] = records;
    final latestRecord = latestNutritionRecordByDate(records);
    final syncedWeeklyMacros = parseWeeklyMacroSettings(
      latestRecord?['weeklyMacroSettings'],
    );

    return client.copyWith(
      nutrition: client.nutrition.copyWith(
        extra: extra,
        weeklyMacroSettings:
            syncedWeeklyMacros ?? client.nutrition.weeklyMacroSettings,
      ),
    );
  }

  Future<Client> updateDailySettings({
    required Client client,
    required String day,
    required String recordDateIso,
    required DailyMacroSettings settings,
  }) async {
    return _updateDay(
      client: client,
      day: day,
      recordDateIso: recordDateIso,
      transform: (_, __) => settings,
    );
  }

  Future<Client> updateProteinGPerKg({
    required Client client,
    required String day,
    required String recordDateIso,
    required double value,
  }) async {
    return _updateDay(
      client: client,
      day: day,
      recordDateIso: recordDateIso,
      transform: (old, _) => old.copyWith(proteinSelected: value),
    );
  }

  Future<Client> updateFatGPerKg({
    required Client client,
    required String day,
    required String recordDateIso,
    required double value,
  }) async {
    return _updateDay(
      client: client,
      day: day,
      recordDateIso: recordDateIso,
      transform: (old, _) => old.copyWith(fatSelected: value),
    );
  }

  Future<Client> updateCarbGPerKg({
    required Client client,
    required String day,
    required String recordDateIso,
    required double value,
  }) async {
    return _updateDay(
      client: client,
      day: day,
      recordDateIso: recordDateIso,
      transform: (old, _) => old.copyWith(carbSelected: value),
    );
  }

  Future<Client> toggleCustomState({
    required Client client,
    required String day,
    required String recordDateIso,
  }) async {
    return _updateDay(
      client: client,
      day: day,
      recordDateIso: recordDateIso,
      transform: (old, week) {
        final currentlyCustom = old.isCustom || old.isCustomizedFromBase;
        final nextCustom = !currentlyCustom;

        if (!nextCustom && day != 'Lunes') {
          final monday = _settingsForDay(week, 'Lunes');
          return monday.copyWith(
            dayOfWeek: day,
            isCustom: false,
            isCustomizedFromBase: false,
          );
        }

        if (nextCustom && day != 'Lunes') {
          final monday = _settingsForDay(week, 'Lunes');
          return old.copyWith(
            dayOfWeek: day,
            proteinSelected: monday.proteinSelected,
            proteinMin: monday.proteinMin,
            proteinMax: monday.proteinMax,
            proteinRangeName: monday.proteinRangeName,
            fatSelected: monday.fatSelected,
            fatMin: monday.fatMin,
            fatMax: monday.fatMax,
            fatRangeName: monday.fatRangeName,
            isCustom: true,
            isCustomizedFromBase: true,
          );
        }

        return old.copyWith(
          dayOfWeek: day,
          isCustom: nextCustom,
          isCustomizedFromBase: nextCustom,
        );
      },
    );
  }

  DailyMacroSettings _settingsForDay(
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

    return DailyMacroSettings(dayOfWeek: day);
  }

  String _normalizeDay(String value) {
    return value
        .toLowerCase()
        .replaceAll('\u00e1', 'a')
        .replaceAll('\u00e9', 'e')
        .replaceAll('\u00ed', 'i')
        .replaceAll('\u00f3', 'o')
        .replaceAll('\u00fa', 'u');
  }
}

final macrosVmProvider = Provider<MacrosViewModel>(
  (ref) => MacrosViewModel(ref),
);
