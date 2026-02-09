import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hcs_app_lap/data/datasources/local/sync_queue_helper.dart';

class SyncService {
  static final SyncService instance = SyncService._();
  SyncService._();

  Timer? _timer;
  bool _isRunning = false;

  void start() {
    if (_isRunning) return;
    _isRunning = true;

    _timer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _processPendingQueue(),
    );
    _processPendingQueue();
  }

  void stop() {
    _timer?.cancel();
    _isRunning = false;
  }

  Future<void> _processPendingQueue() async {
    if (!_isRunning) return;

    try {
      final pending = await SyncQueueHelper.getPendingItems(limit: 10);

      for (final item in pending) {
        try {
          await _syncItem(item);
          await SyncQueueHelper.markSuccess(item['id'] as String);
        } catch (e) {
          debugPrint('Sync failed for ${item['id']}: $e');
          await SyncQueueHelper.markFailure(item['id'] as String, e.toString());
        }
      }
    } catch (e) {
      debugPrint('Error processing sync queue: $e');
    }
  }

  Future<void> _syncItem(Map<String, dynamic> item) async {
    final domain = item['domain'] as String;
    final clientId = item['client_id'] as String;
    final dateKey = item['date_key'] as String;
    final payload = item['payload'] as String;

    // TODO: Implementar sync especifico por dominio
    if (domain == 'anthropometry') {
      // Parsear payload y subir...
      debugPrint(
        'Sync pending anthropometry for $clientId ($dateKey): ${payload.length} bytes',
      );
    }
  }
}
