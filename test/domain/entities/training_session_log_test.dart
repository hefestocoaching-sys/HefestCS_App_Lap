import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/entities/training_session_log.dart';

void main() {
  group('TrainingSessionLogV2 - Validaciones', () {
    test('rejects invalid RIR values - below range', () {
      final log = TrainingSessionLogV2(
        id: 'test-id',
        clientId: 'client-1',
        exerciseId: 'exercise-1',
        sessionDate: DateTime(2025, 1, 15),
        createdAt: DateTime(2025, 1, 15, 10, 0),
        source: 'mobile',
        plannedSets: 4,
        completedSets: 4,
        avgReportedRIR: -1.0, // INVÁLIDO
        perceivedEffort: 7,
        stoppedEarly: false,
        painFlag: false,
        formDegradation: false,
        schemaVersion: 'v1.0.0',
      );

      expect(
        () => log.validate(),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('avgReportedRIR debe estar en el rango [0.0, 5.0]'),
          ),
        ),
      );
    });

    test('rejects invalid RIR values - above range', () {
      final log = TrainingSessionLogV2(
        id: 'test-id',
        clientId: 'client-1',
        exerciseId: 'exercise-1',
        sessionDate: DateTime(2025, 1, 15),
        createdAt: DateTime(2025, 1, 15, 10, 0),
        source: 'mobile',
        plannedSets: 4,
        completedSets: 4,
        avgReportedRIR: 5.5, // INVÁLIDO
        perceivedEffort: 7,
        stoppedEarly: false,
        painFlag: false,
        formDegradation: false,
        schemaVersion: 'v1.0.0',
      );

      expect(
        () => log.validate(),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('avgReportedRIR debe estar en el rango [0.0, 5.0]'),
          ),
        ),
      );
    });

    test('accepts valid RIR values at boundaries', () {
      final log1 = TrainingSessionLogV2(
        id: 'test-id',
        clientId: 'client-1',
        exerciseId: 'exercise-1',
        sessionDate: DateTime(2025, 1, 15),
        createdAt: DateTime(2025, 1, 15, 10, 0),
        source: 'mobile',
        plannedSets: 4,
        completedSets: 4,
        avgReportedRIR: 0.0,
        perceivedEffort: 7,
        stoppedEarly: false,
        painFlag: false,
        formDegradation: false,
        schemaVersion: 'v1.0.0',
      );

      final log2 = TrainingSessionLogV2(
        id: 'test-id-2',
        clientId: 'client-1',
        exerciseId: 'exercise-1',
        sessionDate: DateTime(2025, 1, 15),
        createdAt: DateTime(2025, 1, 15, 10, 0),
        source: 'mobile',
        plannedSets: 4,
        completedSets: 4,
        avgReportedRIR: 5.0,
        perceivedEffort: 7,
        stoppedEarly: false,
        painFlag: false,
        formDegradation: false,
        schemaVersion: 'v1.0.0',
      );

      expect(() => log1.validate(), returnsNormally);
      expect(() => log2.validate(), returnsNormally);
    });

    test('rejects invalid perceivedEffort values - below range', () {
      final log = TrainingSessionLogV2(
        id: 'test-id',
        clientId: 'client-1',
        exerciseId: 'exercise-1',
        sessionDate: DateTime(2025, 1, 15),
        createdAt: DateTime(2025, 1, 15, 10, 0),
        source: 'mobile',
        plannedSets: 4,
        completedSets: 4,
        avgReportedRIR: 2.0,
        perceivedEffort: 0, // INVÁLIDO
        stoppedEarly: false,
        painFlag: false,
        formDegradation: false,
        schemaVersion: 'v1.0.0',
      );

      expect(
        () => log.validate(),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('perceivedEffort debe estar en el rango [1, 10]'),
          ),
        ),
      );
    });

    test('rejects invalid perceivedEffort values - above range', () {
      final log = TrainingSessionLogV2(
        id: 'test-id',
        clientId: 'client-1',
        exerciseId: 'exercise-1',
        sessionDate: DateTime(2025, 1, 15),
        createdAt: DateTime(2025, 1, 15, 10, 0),
        source: 'mobile',
        plannedSets: 4,
        completedSets: 4,
        avgReportedRIR: 2.0,
        perceivedEffort: 11, // INVÁLIDO
        stoppedEarly: false,
        painFlag: false,
        formDegradation: false,
        schemaVersion: 'v1.0.0',
      );

      expect(
        () => log.validate(),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('perceivedEffort debe estar en el rango [1, 10]'),
          ),
        ),
      );
    });

    test('accepts valid perceivedEffort at boundaries', () {
      final log1 = TrainingSessionLogV2(
        id: 'test-id',
        clientId: 'client-1',
        exerciseId: 'exercise-1',
        sessionDate: DateTime(2025, 1, 15),
        createdAt: DateTime(2025, 1, 15, 10, 0),
        source: 'mobile',
        plannedSets: 4,
        completedSets: 4,
        avgReportedRIR: 2.0,
        perceivedEffort: 1,
        stoppedEarly: false,
        painFlag: false,
        formDegradation: false,
        schemaVersion: 'v1.0.0',
      );

      final log2 = TrainingSessionLogV2(
        id: 'test-id-2',
        clientId: 'client-1',
        exerciseId: 'exercise-1',
        sessionDate: DateTime(2025, 1, 15),
        createdAt: DateTime(2025, 1, 15, 10, 0),
        source: 'mobile',
        plannedSets: 4,
        completedSets: 4,
        avgReportedRIR: 2.0,
        perceivedEffort: 10,
        stoppedEarly: false,
        painFlag: false,
        formDegradation: false,
        schemaVersion: 'v1.0.0',
      );

      expect(() => log1.validate(), returnsNormally);
      expect(() => log2.validate(), returnsNormally);
    });

    test('rejects completedSets > plannedSets', () {
      final log = TrainingSessionLogV2(
        id: 'test-id',
        clientId: 'client-1',
        exerciseId: 'exercise-1',
        sessionDate: DateTime(2025, 1, 15),
        createdAt: DateTime(2025, 1, 15, 10, 0),
        source: 'mobile',
        plannedSets: 4,
        completedSets: 5, // INVÁLIDO
        avgReportedRIR: 2.0,
        perceivedEffort: 7,
        stoppedEarly: false,
        painFlag: false,
        formDegradation: false,
        schemaVersion: 'v1.0.0',
      );

      expect(
        () => log.validate(),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains(
              'completedSets (5) no puede ser mayor que plannedSets (4)',
            ),
          ),
        ),
      );
    });

    test('rejects negative completedSets', () {
      final log = TrainingSessionLogV2(
        id: 'test-id',
        clientId: 'client-1',
        exerciseId: 'exercise-1',
        sessionDate: DateTime(2025, 1, 15),
        createdAt: DateTime(2025, 1, 15, 10, 0),
        source: 'mobile',
        plannedSets: 4,
        completedSets: -1, // INVÁLIDO
        avgReportedRIR: 2.0,
        perceivedEffort: 7,
        stoppedEarly: false,
        painFlag: false,
        formDegradation: false,
        schemaVersion: 'v1.0.0',
      );

      expect(
        () => log.validate(),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('completedSets no puede ser negativo'),
          ),
        ),
      );
    });

    test('completedSets == 0 requires stoppedEarly = true', () {
      final log = TrainingSessionLogV2(
        id: 'test-id',
        clientId: 'client-1',
        exerciseId: 'exercise-1',
        sessionDate: DateTime(2025, 1, 15),
        createdAt: DateTime(2025, 1, 15, 10, 0),
        source: 'mobile',
        plannedSets: 4,
        completedSets: 0,
        avgReportedRIR: 0.0,
        perceivedEffort: 5,
        stoppedEarly: false, // INVÁLIDO
        painFlag: false,
        formDegradation: false,
        schemaVersion: 'v1.0.0',
      );

      expect(
        () => log.validate(),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Si completedSets == 0, stoppedEarly debe ser true'),
          ),
        ),
      );
    });

    test('completedSets == 0 with stoppedEarly = true is valid', () {
      final log = TrainingSessionLogV2(
        id: 'test-id',
        clientId: 'client-1',
        exerciseId: 'exercise-1',
        sessionDate: DateTime(2025, 1, 15),
        createdAt: DateTime(2025, 1, 15, 10, 0),
        source: 'mobile',
        plannedSets: 4,
        completedSets: 0,
        avgReportedRIR: 0.0,
        perceivedEffort: 5,
        stoppedEarly: true,
        painFlag: true,
        formDegradation: false,
        schemaVersion: 'v1.0.0',
      );

      expect(() => log.validate(), returnsNormally);
    });

    test('schemaVersion is required', () {
      final log = TrainingSessionLogV2(
        id: 'test-id',
        clientId: 'client-1',
        exerciseId: 'exercise-1',
        sessionDate: DateTime(2025, 1, 15),
        createdAt: DateTime(2025, 1, 15, 10, 0),
        source: 'mobile',
        plannedSets: 4,
        completedSets: 4,
        avgReportedRIR: 2.0,
        perceivedEffort: 7,
        stoppedEarly: false,
        painFlag: false,
        formDegradation: false,
        schemaVersion: '', // INVÁLIDO
      );

      expect(
        () => log.validate(),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('schemaVersion no puede estar vacío'),
          ),
        ),
      );
    });

    test('rejects invalid source value', () {
      final log = TrainingSessionLogV2(
        id: 'test-id',
        clientId: 'client-1',
        exerciseId: 'exercise-1',
        sessionDate: DateTime(2025, 1, 15),
        createdAt: DateTime(2025, 1, 15, 10, 0),
        source: 'web', // INVÁLIDO
        plannedSets: 4,
        completedSets: 4,
        avgReportedRIR: 2.0,
        perceivedEffort: 7,
        stoppedEarly: false,
        painFlag: false,
        formDegradation: false,
        schemaVersion: 'v1.0.0',
      );

      expect(
        () => log.validate(),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('source debe ser "mobile" o "desktop"'),
          ),
        ),
      );
    });

    test('accepts valid source values', () {
      final logMobile = TrainingSessionLogV2(
        id: 'test-id',
        clientId: 'client-1',
        exerciseId: 'exercise-1',
        sessionDate: DateTime(2025, 1, 15),
        createdAt: DateTime(2025, 1, 15, 10, 0),
        source: 'mobile',
        plannedSets: 4,
        completedSets: 4,
        avgReportedRIR: 2.0,
        perceivedEffort: 7,
        stoppedEarly: false,
        painFlag: false,
        formDegradation: false,
        schemaVersion: 'v1.0.0',
      );

      final logDesktop = TrainingSessionLogV2(
        id: 'test-id-2',
        clientId: 'client-1',
        exerciseId: 'exercise-1',
        sessionDate: DateTime(2025, 1, 15),
        createdAt: DateTime(2025, 1, 15, 10, 0),
        source: 'desktop',
        plannedSets: 4,
        completedSets: 4,
        avgReportedRIR: 2.0,
        perceivedEffort: 7,
        stoppedEarly: false,
        painFlag: false,
        formDegradation: false,
        schemaVersion: 'v1.0.0',
      );

      expect(() => logMobile.validate(), returnsNormally);
      expect(() => logDesktop.validate(), returnsNormally);
    });
  });

  group('TrainingSessionLogV2 - Serialización', () {
    test('serializes and deserializes correctly', () {
      final original = TrainingSessionLogV2(
        id: 'test-id-123',
        clientId: 'client-456',
        exerciseId: 'exercise-789',
        sessionDate: DateTime(2025, 1, 15),
        createdAt: DateTime(2025, 1, 15, 14, 30, 45),
        source: 'mobile',
        plannedSets: 4,
        completedSets: 3,
        avgReportedRIR: 2.5,
        perceivedEffort: 8,
        stoppedEarly: false,
        painFlag: false,
        formDegradation: true,
        notes: 'Última serie con técnica comprometida',
        schemaVersion: 'v1.0.0',
      );

      final json = original.toJson();
      final deserialized = TrainingSessionLogV2.fromJson(json);

      expect(deserialized.id, equals(original.id));
      expect(deserialized.clientId, equals(original.clientId));
      expect(deserialized.exerciseId, equals(original.exerciseId));
      expect(deserialized.sessionDate, equals(original.sessionDate));
      expect(deserialized.createdAt, equals(original.createdAt));
      expect(deserialized.source, equals(original.source));
      expect(deserialized.plannedSets, equals(original.plannedSets));
      expect(deserialized.completedSets, equals(original.completedSets));
      expect(deserialized.avgReportedRIR, equals(original.avgReportedRIR));
      expect(deserialized.perceivedEffort, equals(original.perceivedEffort));
      expect(deserialized.stoppedEarly, equals(original.stoppedEarly));
      expect(deserialized.painFlag, equals(original.painFlag));
      expect(deserialized.formDegradation, equals(original.formDegradation));
      expect(deserialized.notes, equals(original.notes));
      expect(deserialized.schemaVersion, equals(original.schemaVersion));
    });

    test('serializes with null notes', () {
      final log = TrainingSessionLogV2(
        id: 'test-id',
        clientId: 'client-1',
        exerciseId: 'exercise-1',
        sessionDate: DateTime(2025, 1, 15),
        createdAt: DateTime(2025, 1, 15, 10, 0),
        source: 'mobile',
        plannedSets: 4,
        completedSets: 4,
        avgReportedRIR: 2.0,
        perceivedEffort: 7,
        stoppedEarly: false,
        painFlag: false,
        formDegradation: false,
        notes: null,
        schemaVersion: 'v1.0.0',
      );

      final json = log.toJson();
      expect(json['notes'], isNull);

      final deserialized = TrainingSessionLogV2.fromJson(json);
      expect(deserialized.notes, isNull);
    });

    test('dates are serialized in ISO8601 format', () {
      final log = TrainingSessionLogV2(
        id: 'test-id',
        clientId: 'client-1',
        exerciseId: 'exercise-1',
        sessionDate: DateTime(2025, 1, 15),
        createdAt: DateTime(2025, 1, 15, 14, 30, 0),
        source: 'mobile',
        plannedSets: 4,
        completedSets: 4,
        avgReportedRIR: 2.0,
        perceivedEffort: 7,
        stoppedEarly: false,
        painFlag: false,
        formDegradation: false,
        schemaVersion: 'v1.0.0',
      );

      final json = log.toJson();

      expect(json['sessionDate'], isA<String>());
      expect(json['createdAt'], isA<String>());
      expect(json['sessionDate'], contains('2025-01-15'));
      expect(json['createdAt'], contains('2025-01-15T14:30:00'));
    });
  });

  group('TrainingSessionLogV2 - Upsert', () {
    test('upsert replaces same-day log', () {
      final date = DateTime(2025, 1, 15);
      final existing = [
        TrainingSessionLogV2(
          id: 'old-id',
          clientId: 'client-1',
          exerciseId: 'exercise-1',
          sessionDate: date,
          createdAt: DateTime(2025, 1, 15, 10, 0),
          source: 'mobile',
          plannedSets: 4,
          completedSets: 3,
          avgReportedRIR: 2.0,
          perceivedEffort: 7,
          stoppedEarly: false,
          painFlag: false,
          formDegradation: false,
          schemaVersion: 'v1.0.0',
        ),
      ];

      final incoming = TrainingSessionLogV2(
        id: 'new-id',
        clientId: 'client-1',
        exerciseId: 'exercise-1',
        sessionDate: date,
        createdAt: DateTime(2025, 1, 15, 14, 0),
        source: 'desktop',
        plannedSets: 4,
        completedSets: 4,
        avgReportedRIR: 1.5,
        perceivedEffort: 6,
        stoppedEarly: false,
        painFlag: false,
        formDegradation: false,
        schemaVersion: 'v1.0.0',
      );

      final result = upsertTrainingSessionLogByDateV2(existing, incoming);

      expect(result.length, equals(1));
      expect(result.first.id, equals('new-id'));
      expect(result.first.completedSets, equals(4));
      expect(result.first.source, equals('desktop'));
    });

    test('upsert keeps multiple dates', () {
      final existing = [
        TrainingSessionLogV2(
          id: 'log-1',
          clientId: 'client-1',
          exerciseId: 'exercise-1',
          sessionDate: DateTime(2025, 1, 10),
          createdAt: DateTime(2025, 1, 10, 10, 0),
          source: 'mobile',
          plannedSets: 4,
          completedSets: 4,
          avgReportedRIR: 2.0,
          perceivedEffort: 7,
          stoppedEarly: false,
          painFlag: false,
          formDegradation: false,
          schemaVersion: 'v1.0.0',
        ),
        TrainingSessionLogV2(
          id: 'log-2',
          clientId: 'client-1',
          exerciseId: 'exercise-1',
          sessionDate: DateTime(2025, 1, 15),
          createdAt: DateTime(2025, 1, 15, 10, 0),
          source: 'mobile',
          plannedSets: 3,
          completedSets: 3,
          avgReportedRIR: 1.5,
          perceivedEffort: 6,
          stoppedEarly: false,
          painFlag: false,
          formDegradation: false,
          schemaVersion: 'v1.0.0',
        ),
      ];

      final incoming = TrainingSessionLogV2(
        id: 'log-3',
        clientId: 'client-1',
        exerciseId: 'exercise-1',
        sessionDate: DateTime(2025, 1, 20),
        createdAt: DateTime(2025, 1, 20, 10, 0),
        source: 'mobile',
        plannedSets: 5,
        completedSets: 5,
        avgReportedRIR: 3.0,
        perceivedEffort: 8,
        stoppedEarly: false,
        painFlag: false,
        formDegradation: false,
        schemaVersion: 'v1.0.0',
      );

      final result = upsertTrainingSessionLogByDateV2(existing, incoming);

      expect(result.length, equals(3));
      expect(result[0].sessionDate, equals(DateTime(2025, 1, 10)));
      expect(result[1].sessionDate, equals(DateTime(2025, 1, 15)));
      expect(result[2].sessionDate, equals(DateTime(2025, 1, 20)));
    });

    test('upsert maintains sort order by sessionDate', () {
      final existing = [
        TrainingSessionLogV2(
          id: 'log-1',
          clientId: 'client-1',
          exerciseId: 'exercise-1',
          sessionDate: DateTime(2025, 1, 20),
          createdAt: DateTime(2025, 1, 20, 10, 0),
          source: 'mobile',
          plannedSets: 4,
          completedSets: 4,
          avgReportedRIR: 2.0,
          perceivedEffort: 7,
          stoppedEarly: false,
          painFlag: false,
          formDegradation: false,
          schemaVersion: 'v1.0.0',
        ),
        TrainingSessionLogV2(
          id: 'log-2',
          clientId: 'client-1',
          exerciseId: 'exercise-1',
          sessionDate: DateTime(2025, 1, 25),
          createdAt: DateTime(2025, 1, 25, 10, 0),
          source: 'mobile',
          plannedSets: 3,
          completedSets: 3,
          avgReportedRIR: 1.5,
          perceivedEffort: 6,
          stoppedEarly: false,
          painFlag: false,
          formDegradation: false,
          schemaVersion: 'v1.0.0',
        ),
      ];

      final incoming = TrainingSessionLogV2(
        id: 'log-3',
        clientId: 'client-1',
        exerciseId: 'exercise-1',
        sessionDate: DateTime(2025, 1, 15),
        createdAt: DateTime(2025, 1, 15, 10, 0),
        source: 'mobile',
        plannedSets: 5,
        completedSets: 5,
        avgReportedRIR: 3.0,
        perceivedEffort: 8,
        stoppedEarly: false,
        painFlag: false,
        formDegradation: false,
        schemaVersion: 'v1.0.0',
      );

      final result = upsertTrainingSessionLogByDateV2(existing, incoming);

      expect(result.length, equals(3));
      expect(result[0].sessionDate, equals(DateTime(2025, 1, 15)));
      expect(result[1].sessionDate, equals(DateTime(2025, 1, 20)));
      expect(result[2].sessionDate, equals(DateTime(2025, 1, 25)));
    });

    test('upsert does not replace different exercise on same date', () {
      final date = DateTime(2025, 1, 15);
      final existing = [
        TrainingSessionLogV2(
          id: 'log-1',
          clientId: 'client-1',
          exerciseId: 'exercise-1',
          sessionDate: date,
          createdAt: DateTime(2025, 1, 15, 10, 0),
          source: 'mobile',
          plannedSets: 4,
          completedSets: 4,
          avgReportedRIR: 2.0,
          perceivedEffort: 7,
          stoppedEarly: false,
          painFlag: false,
          formDegradation: false,
          schemaVersion: 'v1.0.0',
        ),
      ];

      final incoming = TrainingSessionLogV2(
        id: 'log-2',
        clientId: 'client-1',
        exerciseId: 'exercise-2', // Diferente ejercicio
        sessionDate: date,
        createdAt: DateTime(2025, 1, 15, 14, 0),
        source: 'mobile',
        plannedSets: 3,
        completedSets: 3,
        avgReportedRIR: 1.5,
        perceivedEffort: 6,
        stoppedEarly: false,
        painFlag: false,
        formDegradation: false,
        schemaVersion: 'v1.0.0',
      );

      final result = upsertTrainingSessionLogByDateV2(existing, incoming);

      expect(result.length, equals(2));
      expect(
        result.map((e) => e.exerciseId).toSet(),
        equals({'exercise-1', 'exercise-2'}),
      );
    });

    test('upsert is immutable (does not modify original list)', () {
      final existing = [
        TrainingSessionLogV2(
          id: 'log-1',
          clientId: 'client-1',
          exerciseId: 'exercise-1',
          sessionDate: DateTime(2025, 1, 15),
          createdAt: DateTime(2025, 1, 15, 10, 0),
          source: 'mobile',
          plannedSets: 4,
          completedSets: 4,
          avgReportedRIR: 2.0,
          perceivedEffort: 7,
          stoppedEarly: false,
          painFlag: false,
          formDegradation: false,
          schemaVersion: 'v1.0.0',
        ),
      ];

      final incoming = TrainingSessionLogV2(
        id: 'log-2',
        clientId: 'client-1',
        exerciseId: 'exercise-1',
        sessionDate: DateTime(2025, 1, 20),
        createdAt: DateTime(2025, 1, 20, 10, 0),
        source: 'mobile',
        plannedSets: 3,
        completedSets: 3,
        avgReportedRIR: 1.5,
        perceivedEffort: 6,
        stoppedEarly: false,
        painFlag: false,
        formDegradation: false,
        schemaVersion: 'v1.0.0',
      );

      final originalLength = existing.length;
      upsertTrainingSessionLogByDateV2(existing, incoming);

      expect(existing.length, equals(originalLength));
      expect(existing.first.id, equals('log-1'));
    });
  });

  group('TrainingSessionLogV2 - Equatable', () {
    test('two logs with same values are equal', () {
      final log1 = TrainingSessionLogV2(
        id: 'test-id',
        clientId: 'client-1',
        exerciseId: 'exercise-1',
        sessionDate: DateTime(2025, 1, 15),
        createdAt: DateTime(2025, 1, 15, 10, 0),
        source: 'mobile',
        plannedSets: 4,
        completedSets: 4,
        avgReportedRIR: 2.0,
        perceivedEffort: 7,
        stoppedEarly: false,
        painFlag: false,
        formDegradation: false,
        schemaVersion: 'v1.0.0',
      );

      final log2 = TrainingSessionLogV2(
        id: 'test-id',
        clientId: 'client-1',
        exerciseId: 'exercise-1',
        sessionDate: DateTime(2025, 1, 15),
        createdAt: DateTime(2025, 1, 15, 10, 0),
        source: 'mobile',
        plannedSets: 4,
        completedSets: 4,
        avgReportedRIR: 2.0,
        perceivedEffort: 7,
        stoppedEarly: false,
        painFlag: false,
        formDegradation: false,
        schemaVersion: 'v1.0.0',
      );

      expect(log1, equals(log2));
    });

    test('two logs with different values are not equal', () {
      final log1 = TrainingSessionLogV2(
        id: 'test-id',
        clientId: 'client-1',
        exerciseId: 'exercise-1',
        sessionDate: DateTime(2025, 1, 15),
        createdAt: DateTime(2025, 1, 15, 10, 0),
        source: 'mobile',
        plannedSets: 4,
        completedSets: 4,
        avgReportedRIR: 2.0,
        perceivedEffort: 7,
        stoppedEarly: false,
        painFlag: false,
        formDegradation: false,
        schemaVersion: 'v1.0.0',
      );

      final log2 = TrainingSessionLogV2(
        id: 'test-id-different',
        clientId: 'client-1',
        exerciseId: 'exercise-1',
        sessionDate: DateTime(2025, 1, 15),
        createdAt: DateTime(2025, 1, 15, 10, 0),
        source: 'mobile',
        plannedSets: 4,
        completedSets: 4,
        avgReportedRIR: 2.0,
        perceivedEffort: 7,
        stoppedEarly: false,
        painFlag: false,
        formDegradation: false,
        schemaVersion: 'v1.0.0',
      );

      expect(log1, isNot(equals(log2)));
    });
  });
}
