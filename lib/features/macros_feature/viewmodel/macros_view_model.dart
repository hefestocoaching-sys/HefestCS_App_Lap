import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/daily_macro_settings.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';

class MacrosViewModel {
  final Ref ref;

  MacrosViewModel(this.ref);

  Future<Client> _updateDay({
    required Client client,
    required String day,
    required DailyMacroSettings Function(DailyMacroSettings) transform,
  }) async {
    final oldWeek = client.nutrition.weeklyMacroSettings ?? {};
    final oldDay = oldWeek[day] ?? DailyMacroSettings(dayOfWeek: day);

    final newDay = transform(oldDay);

    final newWeek = Map<String, DailyMacroSettings>.from(oldWeek);
    newWeek[day] = newDay;

    final updatedClient = client.copyWith(
      nutrition: client.nutrition.copyWith(weeklyMacroSettings: newWeek),
    );

    await ref.read(clientsProvider.notifier).updateActiveClient((prev) {
      final mergedExtra = Map<String, dynamic>.from(prev.nutrition.extra);
      mergedExtra.addAll(updatedClient.nutrition.extra);
      return prev.copyWith(
        nutrition: prev.nutrition.copyWith(
          extra: mergedExtra,
          weeklyMacroSettings:
              updatedClient.nutrition.weeklyMacroSettings ??
              prev.nutrition.weeklyMacroSettings,
        ),
      );
    });

    return updatedClient;
  }

  Future<Client> updateProteinGPerKg({
    required Client client,
    required String day,
    required double value,
  }) async {
    return await _updateDay(
      client: client,
      day: day,
      transform: (old) => old.copyWith(proteinSelected: value),
    );
  }

  Future<Client> updateFatGPerKg({
    required Client client,
    required String day,
    required double value,
  }) async {
    return await _updateDay(
      client: client,
      day: day,
      transform: (old) => old.copyWith(fatSelected: value),
    );
  }

  Future<Client> updateCarbGPerKg({
    required Client client,
    required String day,
    required double value,
  }) async {
    return await _updateDay(
      client: client,
      day: day,
      transform: (old) => old.copyWith(carbSelected: value),
    );
  }
}

final macrosVmProvider = Provider.autoDispose<MacrosViewModel>(
  (ref) => MacrosViewModel(ref),
);
