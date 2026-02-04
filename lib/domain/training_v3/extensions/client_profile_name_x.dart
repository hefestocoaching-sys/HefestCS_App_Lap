// lib/domain/training_v3/extensions/client_profile_name_x.dart
import 'package:hcs_app_lap/domain/training_v3/models/client_profile.dart';

extension ClientProfileNameX on ClientProfile {
  String get name {
    // ClientProfile no tiene firstName/lastName, usamos el campo 'experience' como placeholder
    // En producción esto debería conectar con el modelo real de cliente
    return 'Cliente ${experience}';
  }
}
