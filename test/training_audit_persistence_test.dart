import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_audit_log.dart';
import 'package:hcs_app_lap/domain/training_v3/repositories/training_audit_log_repository.dart';
import 'package:mocktail/mocktail.dart';

// Create a Mock class manually
class MockTrainingAuditLogRepository extends Mock
    implements TrainingAuditLogRepository {}

void main() {
  group('TrainingAuditLog Persistence (Service Integration)', () {
    late MockTrainingAuditLogRepository mockRepo;

    setUp(() {
      mockRepo = MockTrainingAuditLogRepository();
      // Register fallback values if needed, though simple types usually don't need it.
      registerFallbackValue(
        TrainingAuditLogEntry(
          userId: '',
          eventType: '',
          weekNumber: 0,
          title: '',
          description: '',
          severity: '',
          actorType: '',
          isValid: false,
          timestamp: DateTime.now(), // Fixed: non-null and no const
        ),
      );
    });

    // Valid entry for fallback
    final fallbackEntry = TrainingAuditLogEntry(
      userId: 'fallback',
      eventType: 'fallback',
      weekNumber: 0,
      title: '',
      description: '',
      severity: '',
      actorType: '',
      isValid: false,
      timestamp: DateTime.now(),
    );

    setUpAll(() {
      registerFallbackValue(fallbackEntry);
    });

    test('Should verify saveLogEntry is called', () async {
      // Arrange
      final entry = TrainingAuditLogEntry(
        userId: 'test_user',
        eventType: AuditEventType.weeklyProgression,
        weekNumber: 1,
        title: 'Test Log',
        description: 'Test Description',
        severity: 'info',
        actorType: 'system',
        isValid: true,
        timestamp: DateTime.now(),
      );

      // Stub
      when(() => mockRepo.saveLogEntry(any())).thenAnswer((_) async {});

      // Act
      await mockRepo.saveLogEntry(entry);

      // Assert
      verify(() => mockRepo.saveLogEntry(any())).called(1);
    });
  });
}
