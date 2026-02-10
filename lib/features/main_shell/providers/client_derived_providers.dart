import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/daily_macro_settings.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';

/// Provider que solo escucha el cliente activo.
final activeClientProvider = Provider<Client?>((ref) {
  return ref.watch(clientsProvider).value?.activeClient;
});

/// Provider que solo escucha el peso.
final clientWeightProvider = Provider<double?>((ref) {
  return ref.watch(activeClientProvider)?.lastWeight;
});

/// Provider que solo escucha los macros semanales.
final weeklyMacroSettingsProvider = Provider<Map<String, DailyMacroSettings>?>((
  ref,
) {
  return ref.watch(activeClientProvider)?.nutrition.weeklyMacroSettings;
});

/// Provider que solo escucha macros de un dia especifico.
final dayMacroSettingsProvider = Provider.family<DailyMacroSettings?, String>((
  ref,
  dayKey,
) {
  final weekly = ref.watch(weeklyMacroSettingsProvider);
  return weekly?[dayKey];
});
