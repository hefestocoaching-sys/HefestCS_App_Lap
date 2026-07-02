import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/core/services/sync_service.dart';
import 'package:hcs_app_lap/data/datasources/local/sync_queue_helper.dart';

void main() {
  group('SyncService observability', () {
    test('builds item context with minimum metadata only', () {
      final context = SyncService.buildItemFailureContext({
        'id': 'queue-item-1',
        'domain': SyncQueueDomains.client,
        'payload': '{"secret":"value"}',
        'weightKg': 82,
        'email': 'client@example.com',
      }, error: StateError('boom'));

      expect(context.scope, SyncQueueObservabilityScope.item);
      expect(context.message, 'Sync queue item failed');
      expect(context.data['itemId'], 'queue-item-1');
      expect(context.data['operation'], 'sync');
      expect(context.data['entityType'], 'client');
      expect(context.data['domain'], SyncQueueDomains.client);
      expect(context.data['error'], contains('boom'));
      expect(context.data.containsKey('payload'), isFalse);
      expect(context.data.containsKey('weightKg'), isFalse);
      expect(context.data.containsKey('email'), isFalse);
    });

    test('builds item context safely when fields are missing or odd types', () {
      final context = SyncService.buildItemFailureContext(
        {
          'id': ['queue', 'item', 2],
          'domain': 42,
          'payload': {'secret': true},
        },
        error: ArgumentError('bad item'),
        stackTrace: StackTrace.current,
      );

      expect(context.scope, SyncQueueObservabilityScope.item);
      expect(context.data['itemId'], '[queue, item, 2]');
      expect(context.data['operation'], 'unknown');
      expect(context.data['entityType'], 'unknown');
      expect(context.data['domain'], '42');
      expect(context.data['error'], contains('bad item'));
      expect(
        context.data['stackTrace'],
        contains('sync_service_observability_test.dart'),
      );
      expect(context.data.containsKey('payload'), isFalse);
    });

    test('builds global context distinct from item context', () {
      final context = SyncService.buildGlobalFailureContext(
        error: Exception('global failure'),
        stackTrace: StackTrace.current,
      );

      expect(context.scope, SyncQueueObservabilityScope.global);
      expect(context.message, 'Sync queue processing failed');
      expect(context.data['scope'], 'global');
      expect(context.data['error'], contains('global failure'));
      expect(
        context.data['stackTrace'],
        contains('sync_service_observability_test.dart'),
      );
      expect(context.data.containsKey('itemId'), isFalse);
    });

    test('builds unsupported domain context without payload data', () {
      final context = SyncService.buildUnsupportedDomainContext({
        'unexpected': true,
      });

      expect(context.scope, SyncQueueObservabilityScope.item);
      expect(context.message, 'Skipping unsupported sync queue domain');
      expect(context.data['scope'], 'item');
      expect(context.data['domain'], '{unexpected: true}');
      expect(context.data['operation'], 'sync');
      expect(context.data['entityType'], 'unknown');
      expect(context.data.containsKey('payload'), isFalse);
    });
  });
}
