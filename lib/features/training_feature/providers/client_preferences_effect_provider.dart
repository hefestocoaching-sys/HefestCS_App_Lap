import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';
import 'package:hcs_app_lap/features/training_feature/domain/client_exercise_preferences_resolver.dart';
import 'package:hcs_app_lap/features/training_feature/domain/exercise_preferences_models.dart';

/// Proveedor de preferencias del cliente
final clientPreferencesEffectProvider = FutureProvider<ExercisePreferencesByMuscle>((
  ref,
) async {
  // Obtener cliente activo
  final clientsState = ref.watch(clientsProvider);
  return clientsState.when(
    data: (state) => resolveClientExercisePreferences(state.activeClient),
    error: (_, __) => const ExercisePreferencesByMuscle(),
    loading: () => const ExercisePreferencesByMuscle(),
  );
});
