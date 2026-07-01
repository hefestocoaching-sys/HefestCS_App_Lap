import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hcs_app_lap/core/services/background_sync_service.dart';
import 'package:hcs_app_lap/data/datasources/local/sync_queue_helper.dart';

class SyncService {
  static final SyncService instance = SyncService._();
  SyncService._();

  Timer? _timer;
  bool _isRunning = false;
  bool _isProcessing = false;
  BackgroundSyncService? _backgroundSyncServiceOverride;

  void setBackgroundSyncServiceForTest(
    BackgroundSyncService backgroundSyncService,
  ) {
    _backgroundSyncServiceOverride = backgroundSyncService;
  }

  void clearBackgroundSyncServiceForTest() {
    _backgroundSyncServiceOverride = null;
  }

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

  Future<void> processPendingQueueOnce() => _processPendingQueue(force: true);

  Future<void> _processPendingQueue({bool force = false}) async {
    if (!force && !_isRunning) return;
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final pending = await SyncQueueHelper.getPendingItems();
      final backgroundSyncService =
          _backgroundSyncServiceOverride ?? BackgroundSyncService.instance;

      for (final item in pending) {
        try {
          final outcome = await _syncItem(item);
          if (outcome == SyncQueueProcessOutcome.retryableFailure) {
            await SyncQueueHelper.markFailure(
              item['id'] as String,
              'sync failed',
            );
          }
        } catch (e) {
          debugPrint('Sync failed for ${item['id']}: $e');
          await SyncQueueHelper.markFailure(item['id'] as String, e.toString());
        }
      }

      await backgroundSyncService.trySyncPendingData();
    } catch (e) {
      debugPrint('Error processing sync queue: $e');
    } finally {
      _isProcessing = false;
    }
  }

  Future<SyncQueueProcessOutcome> _syncItem(Map<String, dynamic> item) async {
    final domain = item['domain'] as String;
    if (domain == SyncQueueDomains.client) {
      final backgroundSyncService =
          _backgroundSyncServiceOverride ?? BackgroundSyncService.instance;
      return backgroundSyncService.processClientOutboxItem(item);
    }

    if (domain == SyncQueueDomains.anthropometryRecordUpsert ||
        domain == SyncQueueDomains.biochemistryRecordUpsert ||
        domain == SyncQueueDomains.anthropometryRecordDelete ||
        domain == SyncQueueDomains.biochemistryRecordDelete) {
      final backgroundSyncService =
          _backgroundSyncServiceOverride ?? BackgroundSyncService.instance;
      return backgroundSyncService.processClinicalRecordOutboxItem(item);
    }

    debugPrint('Skipping unsupported sync queue domain: $domain');
    return SyncQueueProcessOutcome.pending;
  }
}
