import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/features/main_shell/providers/clients_provider.dart';

class HistoryClinicViewModel {
  final Ref ref;

  HistoryClinicViewModel(this.ref);

  Future<void> saveClient(Client updated) async {
    // Merge update: ensure we don't overwrite concurrent changes. Merge extras at least.
    await ref.read(clientsProvider.notifier).updateActiveClient((prev) {
      final mergedNutritionExtra = Map<String, dynamic>.from(
        prev.nutrition.extra,
      );
      mergedNutritionExtra.addAll(updated.nutrition.extra);

      final mergedTrainingExtra = Map<String, dynamic>.from(
        prev.training.extra,
      );
      mergedTrainingExtra.addAll(updated.training.extra);

      // ✅ CRITICAL FIX: Usar updated.training como base (contiene campos editados)
      // Solo mergear extra para no perder datos concurrentes
      final mergedTraining = updated.training.copyWith(
        extra: mergedTrainingExtra,
      );

      return prev.copyWith(
        profile: updated.profile,
        history: updated.history,
        training: mergedTraining,
        nutrition: prev.nutrition.copyWith(
          extra: mergedNutritionExtra,
          dailyMealPlans:
              updated.nutrition.dailyMealPlans ?? prev.nutrition.dailyMealPlans,
        ),
      );
    });
  }
}

final historyClinicVmProvider = Provider.autoDispose<HistoryClinicViewModel>(
  (ref) => HistoryClinicViewModel(ref),
);
