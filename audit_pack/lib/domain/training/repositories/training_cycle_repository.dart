import 'package:hcs_app_lap/domain/training/training_cycle.dart';

/// Contrato del repositorio de ciclos de entrenamiento.
///
/// REGLA CRÍTICA: Solo puede existir 1 ciclo con status == "active"
/// por clientId en todo momento.
abstract class TrainingCycleRepository {
  /// Obtiene el ciclo activo del cliente, o null si no tiene ninguno.
  Future<TrainingCycle?> getActiveCycle(String clientId);

  /// Crea un nuevo ciclo como activo.
  ///
  /// Si ya existe un ciclo activo para el mismo clientId, lo cierra primero
  /// (status = "completed") antes de persistir el nuevo.
  Future<void> createCycle(TrainingCycle cycle);

  /// Cierra un ciclo activo marcándolo como completado.
  ///
  /// - Establece status = "completed"
  /// - Registra endDate como ahora
  Future<void> closeCycle(String cycleId);

  /// Actualiza un ciclo existente sin regenerar estructura.
  ///
  /// Si el ciclo no existe, lo crea respetando la regla de ciclo único activo.
  Future<void> upsertCycle(TrainingCycle cycle);
}
