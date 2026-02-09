import 'package:synchronized/synchronized.dart';

/// Lock global para prevenir race conditions en updates de cliente
class UpdateLock {
  static final UpdateLock instance = UpdateLock._();
  UpdateLock._();

  final _clientUpdateLock = Lock();
  final _dbWriteLock = Lock();

  /// Ejecuta update de cliente de forma thread-safe
  Future<T> safeClientUpdate<T>(Future<T> Function() operation) async {
    return _clientUpdateLock.synchronized(() async {
      return operation();
    });
  }

  /// Ejecuta escritura en DB de forma thread-safe
  Future<T> safeDbWrite<T>(Future<T> Function() operation) async {
    return _dbWriteLock.synchronized(() async {
      return operation();
    });
  }
}
