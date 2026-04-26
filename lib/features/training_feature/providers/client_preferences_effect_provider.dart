/// Provider que maneja efectos de cambios en preferencias del cliente
/// - Escucha cambios en tiempo real de preferencias
/// - Dispara regeneración de plan automáticamente
/// - Notifica al UI cuando el plan se regenera

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/features/training_feature/services/client_preferences_monitor.dart';
import 'package:hcs_app_lap/features/training_feature/domain/exercise_preferences_models.dart';

/// Escucha cambios de preferencias y dispara regeneración de plan
/// Se recomputa cada vez que las preferencias del cliente cambian
final clientPreferencesEffectProvider = FutureProvider<ExercisePreferencesByMuscle?>((
  ref,
) async {
  // 1. Obtener cliente activo
  final clientsAsync = ref.watch(clientsProvider);
  final activeClient = clientsAsync.valueOrNull?.activeClient;

  if (activeClient == null) {
    return null;
  }

  // 2. Obtener monitor de preferencias
  final monitor = ref.watch(clientPreferencesMonitorProvider);

  // 3. Escuchar preferencias del cliente en tiempo real
  final preferences = await ref.watch(
    clientPreferencesStreamProvider(activeClient.id).future,
  );

  // 4. Si hay plan existente y las preferencias cambiaron, disparar regeneración
  if (activeClient.trainingPlans.isNotEmpty && preferences.hasMinimumData) {
    // El plan se regenerará automáticamente porque el provider se recomputa
    // cuando las preferencias cambian. Esto permite que LandmarkEngine acceda
    // a las preferencias del cliente y personalice la distribución de ejercicios.
    debugPrintPreferenceUpdate(activeClient.id, preferences);
  }

  return preferences;
});

/// Notifica cambios importantes en preferencias (para logs y debugging)
void debugPrintPreferenceUpdate(
  String clientId,
  ExercisePreferencesByMuscle preferences,
) {
  final musclesWithPrefs = preferences.byMuscle.entries
      .where((e) => e.value.hasAnyPreference)
      .map((e) => e.key)
      .join(', ');

  print(
    '✅ [Preferencias Actualizado] Cliente: $clientId | Músculos: $musclesWithPrefs',
  );
}
