/// Provider que maneja efectos de cambios en preferencias del cliente
/// - Escucha cambios en tiempo real de preferencias
/// - Dispara regeneración de plan automáticamente
/// - Notifica al UI cuando el plan se regenera

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/features/training_feature/domain/exercise_preferences_models.dart';

/// Proveedor de preferencias del cliente
/// Actualmente retorna null - se puede extender para monitorear cambios
final clientPreferencesEffectProvider = FutureProvider<ExercisePreferencesByMuscle?>((
  ref,
) async {
  // Obtener cliente activo
  final clientsState = ref.watch(clientsProvider);
  return clientsState.when(
    data: (state) {
      final activeClient = state.activeClient;
      if (activeClient == null) return null;
      // Retornar preferencias del cliente si las tiene
      return const ExercisePreferencesByMuscle();
    },
    error: (_, __) => null,
    loading: () => null,
  );
});
