import 'package:hcs_app_lap/core/enums/training_focus.dart';
import 'package:hcs_app_lap/core/constants/training_extra_keys.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';

/// Determina si se debe aplicar la lógica de especialización de glúteos.
///
/// Esta política de negocio centraliza las condiciones para activar el "motor"
/// de especialización de glúteos, asegurando que solo se aplique cuando:
/// 1. El foco de entrenamiento está explícitamente establecido en glúteos.
/// 2. Existe una configuración de perfil de especialización en los datos del cliente.
bool shouldUseGluteSpecialization(TrainingProfile profile) {
  // Condición 1: Debe haber un foco explícito en glúteos.
  if (profile.trainingFocus != TrainingFocus.gluteSpecialization) {
    return false;
  }

  // Condición 2: Debe existir un perfil de glúteo configurado en `extra`.
  final gluteProfile =
      profile.extra[TrainingExtraKeys.gluteSpecializationProfile];
  if (gluteProfile is! Map<String, dynamic>) {
    return false;
  }

  return true;
}
