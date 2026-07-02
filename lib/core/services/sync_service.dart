import 'dart:async';

import 'package:hcs_app_lap/core/services/background_sync_service.dart';
import 'package:hcs_app_lap/core/utils/app_logger.dart';
import 'package:hcs_app_lap/data/datasources/local/sync_queue_helper.dart';

enum SyncQueueObservabilityScope { item, global }

class SyncQueueObservabilityContext {
  const SyncQueueObservabilityContext({
    required this.scope,
    required this.message,
    required this.data,
  });

  final SyncQueueObservabilityScope scope;
  final String message;
  final Map<String, Object?> data;
}

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
            final context = buildItemFailureContext(
              item,
              error: 'retryable_failure',
            );
            logger.warning(context.message, context.data);
            await SyncQueueHelper.markFailure(
              item['id'] as String,
              'sync failed',
            );
          }
        } catch (e, st) {
          final context = buildItemFailureContext(
            item,
            error: e,
            stackTrace: st,
          );
          logger.warning(context.message, context.data);
          await SyncQueueHelper.markFailure(item['id'] as String, e.toString());
        }
      }

      await backgroundSyncService.trySyncPendingData();
    } catch (e, st) {
      final context = buildGlobalFailureContext(error: e, stackTrace: st);
      logger.error(context.message, e, st);
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

    final context = buildUnsupportedDomainContext(domain);
    logger.warning(context.message, context.data);
    return SyncQueueProcessOutcome.pending;
  }

  static SyncQueueObservabilityContext buildItemFailureContext(
    Map<String, dynamic> item, {
    required Object error,
    StackTrace? stackTrace,
  }) {
    final domain = _safeString(item['domain']);
    final itemId = _safeString(item['id']);

    return SyncQueueObservabilityContext(
      scope: SyncQueueObservabilityScope.item,
      message: 'Sync queue item failed',
      data: {
        'itemId': itemId ?? 'unknown',
        'operation': _operationForDomain(domain),
        'entityType': _entityTypeForDomain(domain),
        'domain': domain ?? 'unknown',
        'error': error.toString(),
        if (stackTrace != null) 'stackTrace': stackTrace.toString(),
      },
    );
  }

  static SyncQueueObservabilityContext buildGlobalFailureContext({
    required Object error,
    StackTrace? stackTrace,
  }) {
    return SyncQueueObservabilityContext(
      scope: SyncQueueObservabilityScope.global,
      message: 'Sync queue processing failed',
      data: {
        'scope': 'global',
        'error': error.toString(),
        if (stackTrace != null) 'stackTrace': stackTrace.toString(),
      },
    );
  }

  static SyncQueueObservabilityContext buildUnsupportedDomainContext(
    Object? domain,
  ) {
    return SyncQueueObservabilityContext(
      scope: SyncQueueObservabilityScope.item,
      message: 'Skipping unsupported sync queue domain',
      data: {
        'scope': 'item',
        'domain': _safeString(domain) ?? 'unknown',
        'operation': 'sync',
        'entityType': 'unknown',
      },
    );
  }

  static String? _safeString(Object? value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  static String _operationForDomain(String? domain) {
    if (domain == null) return 'unknown';
    if (domain == SyncQueueDomains.client) return 'sync';
    if (domain.endsWith('_upsert')) return 'upsert';
    if (domain.endsWith('_delete')) return 'delete';
    return 'unknown';
  }

  static String _entityTypeForDomain(String? domain) {
    if (domain == null) return 'unknown';
    if (domain == SyncQueueDomains.client) return 'client';
    if (domain == SyncQueueDomains.anthropometryRecordUpsert ||
        domain == SyncQueueDomains.anthropometryRecordDelete) {
      return 'anthropometry_record';
    }
    if (domain == SyncQueueDomains.biochemistryRecordUpsert ||
        domain == SyncQueueDomains.biochemistryRecordDelete) {
      return 'biochemistry_record';
    }
    return 'unknown';
  }
}
