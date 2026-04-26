import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/features/training_feature/domain/exercise_preferences_models.dart';

/// Servicio que monitorea cambios de preferencias de ejercicios del cliente
/// y dispara regeneración de planes
class ClientPreferencesMonitor {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Escucha cambios en preferencias del cliente en tiempo real
  /// Retorna stream con las preferencias actualizadas
  Stream<ExercisePreferencesByMuscle> watchClientPreferences(String clientId) {
    return _firestore
        .collection('clients')
        .doc(clientId)
        .collection('profile')
        .doc('training')
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            return const ExercisePreferencesByMuscle();
          }

          final data = doc.data() as Map<String, dynamic>?;
          final extra = data?['extra'] as Map<String, dynamic>? ?? {};
          final rawPrefs =
              extra['exercisePreferencesByMuscle'] as Map<String, dynamic>?;

          return rawPrefs != null
              ? ExercisePreferencesByMuscle.fromDynamic(rawPrefs)
              : const ExercisePreferencesByMuscle();
        });
  }

  /// Obtiene las preferencias actuales del cliente (una sola lectura)
  Future<ExercisePreferencesByMuscle> fetchClientPreferences(
    String clientId,
  ) async {
    try {
      final doc = await _firestore
          .collection('clients')
          .doc(clientId)
          .collection('profile')
          .doc('training')
          .get();

      if (!doc.exists) {
        return const ExercisePreferencesByMuscle();
      }

      final data = doc.data() as Map<String, dynamic>?;
      final extra = data?['extra'] as Map<String, dynamic>? ?? {};
      final rawPrefs =
          extra['exercisePreferencesByMuscle'] as Map<String, dynamic>?;

      return rawPrefs != null
          ? ExercisePreferencesByMuscle.fromDynamic(rawPrefs)
          : const ExercisePreferencesByMuscle();
    } catch (e) {
      debugPrint('Error fetching client preferences: $e');
      return const ExercisePreferencesByMuscle();
    }
  }
}

/// Provider para el monitor de preferencias
final clientPreferencesMonitorProvider = Provider((ref) {
  return ClientPreferencesMonitor();
});

/// Provider que escucha cambios en preferencias de un cliente específico
final clientPreferencesStreamProvider =
    StreamProvider.family<ExercisePreferencesByMuscle, String>((ref, clientId) {
      final monitor = ref.watch(clientPreferencesMonitorProvider);
      return monitor.watchClientPreferences(clientId);
    });
