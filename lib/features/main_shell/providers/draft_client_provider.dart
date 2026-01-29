// Provider para manejar un cliente borrador cuando no hay cliente activo
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/client_profile.dart';
import 'package:hcs_app_lap/domain/entities/clinical_history.dart';
import 'package:hcs_app_lap/domain/entities/nutrition_settings.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';

class DraftClientNotifier extends Notifier<Client?> {
  @override
  Client? build() => null;

  /// Obtiene el cliente borrador o crea uno nuevo vacío
  Client getOrCreateDraft() {
    if (state != null) return state!;

    final now = DateTime.now();
    final draftClient = Client(
      id: 'draft_${now.millisecondsSinceEpoch}',
      profile: ClientProfile(
        id: 'profile_draft_${now.millisecondsSinceEpoch}',
        fullName: '',
        email: '',
        phone: '',
        country: '',
        occupation: '',
        objective: '',
      ),
      history: const ClinicalHistory(),
      training: TrainingProfile.empty(),
      nutrition: const NutritionSettings(),
    );

    state = draftClient;
    return draftClient;
  }

  /// Actualiza el cliente borrador
  void updateDraft(Client client) {
    state = client;
  }

  /// Limpia el borrador (después de guardar o al cancelar)
  void clearDraft() {
    state = null;
  }

  /// Verifica si el borrador tiene datos suficientes para guardar
  bool hasMinimumData() {
    if (state == null) return false;
    return state!.profile.fullName.trim().isNotEmpty;
  }
}

final draftClientProvider = NotifierProvider<DraftClientNotifier, Client?>(
  () => DraftClientNotifier(),
);
