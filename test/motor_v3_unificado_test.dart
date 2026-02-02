import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/core/enums/gender.dart';
import 'package:hcs_app_lap/domain/entities/anthropometry_record.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/client_profile.dart';
import 'package:hcs_app_lap/domain/entities/clinical_history.dart';
import 'package:hcs_app_lap/domain/entities/daily_tracking_record.dart';
import 'package:hcs_app_lap/domain/entities/nutrition_settings.dart';
import 'package:hcs_app_lap/domain/entities/strength_assessment.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/entities/volume_tolerance_profile.dart';
import 'package:hcs_app_lap/domain/training_v3/ml/client_data_snapshot.dart';
import 'package:hcs_app_lap/domain/training_v3/ml/data_normalizer.dart';
import 'package:hcs_app_lap/domain/training_v3/ml/normalized_client_data.dart';
import 'package:hcs_app_lap/domain/training_v3/ml/unified_data_collector.dart';

void main() {
  group('Motor V3 Unificado - Layer 0: UnifiedDataCollector', () {
    late Client testClient;

    setUp(() {
      // Crear cliente de prueba con todos los datos
      final now = DateTime.now();

      testClient = Client(
        id: 'test-client-123',
        profile: ClientProfile(
          name: 'Test Client',
          email: 'test@example.com',
          dateOfBirth: DateTime(1990, 1, 1), // 34-35 años
        ),
        history: ClinicalHistory(
          conditions: [],
          medications: [],
        ),
        training: TrainingProfile(
          id: 'training-1',
          gender: Gender.male,
          age: 34,
          bodyWeight: 80.0,
          usesAnabolics: false,
          yearsTrainingContinuous: 5,
          restBetweenSetsSeconds: 90,
          avgSleepHours: 7.5,
          extra: {
            'height': 175.0,
          },
        ),
        nutrition: NutritionSettings.empty(),
        anthropometry: [
          AnthropometryRecord(
            date: now.subtract(Duration(days: 7)),
            heightCm: 175.0,
            weightKg: 80.0,
          ),
          AnthropometryRecord(
            date: now.subtract(Duration(days: 30)),
            heightCm: 175.0,
            weightKg: 82.0,
          ),
        ],
        tracking: [
          DailyTrackingRecord(
            date: now.subtract(Duration(days: 1)),
            weightKg: 79.5,
          ),
          DailyTrackingRecord(
            date: now.subtract(Duration(days: 15)),
            weightKg: 80.2,
          ),
        ],
        strengthAssessments: [
          StrengthAssessment(
            exerciseName: 'Squat',
            oneRmEstimated: 150.0,
            date: now.subtract(Duration(days: 10)),
          ),
        ],
      );
    });

    test('collectClientData creates snapshot with all data', () async {
      final snapshot = await UnifiedDataCollector.collectClientData(testClient);

      expect(snapshot.clientId, equals('test-client-123'));
      expect(snapshot.clientProfile, isNotNull);
      expect(snapshot.trainingProfile, isNotNull);
      expect(snapshot.latestAnthropometry, isNotNull);
      expect(snapshot.anthropometryHistory.length, equals(2));
      expect(snapshot.recentDailyTracking.length, greaterThan(0));
      expect(snapshot.strengthAssessments.length, equals(1));
    });

    test('collectClientData selects latest anthropometry record', () async {
      final snapshot = await UnifiedDataCollector.collectClientData(testClient);

      // Debe seleccionar el registro más reciente (7 días atrás)
      expect(snapshot.latestAnthropometry!.weightKg, equals(80.0));
      expect(snapshot.latestAnthropometry!.heightCm, equals(175.0));
    });

    test('collectClientData filters tracking by time window', () async {
      final now = DateTime.now();
      final snapshot = await UnifiedDataCollector.collectClientData(
        testClient,
        asOfDate: now,
      );

      // Solo debe incluir tracking de últimas 4 semanas (28 días)
      for (final record in snapshot.recentDailyTracking) {
        final daysDiff = now.difference(record.date).inDays;
        expect(daysDiff, lessThanOrEqualTo(28));
      }
    });

    test('snapshot helpers work correctly', () async {
      final snapshot = await UnifiedDataCollector.collectClientData(testClient);

      expect(snapshot.hasAnthropometry, isTrue);
      expect(snapshot.hasTracking, isTrue);
      expect(snapshot.hasStrengthData, isTrue);
      expect(snapshot.trackingWeeksAvailable, greaterThan(0));
    });

    test('collectClientData handles empty client data gracefully', () async {
      final emptyClient = Client(
        id: 'empty-client',
        profile: ClientProfile(
          name: 'Empty Client',
          email: 'empty@example.com',
        ),
        history: ClinicalHistory(
          conditions: [],
          medications: [],
        ),
        training: TrainingProfile.empty(),
        nutrition: NutritionSettings.empty(),
        anthropometry: [],
        tracking: [],
        strengthAssessments: [],
      );

      final snapshot = await UnifiedDataCollector.collectClientData(emptyClient);

      expect(snapshot.clientId, equals('empty-client'));
      expect(snapshot.hasAnthropometry, isFalse);
      expect(snapshot.hasTracking, isFalse);
      expect(snapshot.hasStrengthData, isFalse);
      expect(snapshot.latestAnthropometry, isNull);
    });
  });

  group('Motor V3 Unificado - Layer 1: DataNormalizer', () {
    late ClientDataSnapshot testSnapshot;

    setUp(() {
      testSnapshot = ClientDataSnapshot(
        clientId: 'test-client-123',
        capturedAt: DateTime.now(),
        clientProfile: ClientProfile(
          name: 'Test Client',
          email: 'test@example.com',
          dateOfBirth: DateTime(1990, 1, 1),
        ),
        trainingProfile: TrainingProfile(
          id: 'training-1',
          gender: Gender.male,
          age: 34,
          bodyWeight: 80.0,
          usesAnabolics: false,
          yearsTrainingContinuous: 5,
          restBetweenSetsSeconds: 90,
          avgSleepHours: 7.5,
          extra: {
            'height': 175.0,
          },
        ),
        latestAnthropometry: AnthropometryRecord(
          date: DateTime.now(),
          heightCm: 175.0,
          weightKg: 80.0,
        ),
        anthropometryHistory: [],
        recentDailyTracking: [],
        recentSessionLogs: [],
        strengthAssessments: [],
        volumeToleranceByMuscle: {},
      );
    });

    test('normalize extracts demographics correctly', () {
      final normalized = DataNormalizer.normalize(testSnapshot);

      expect(normalized.age, equals(34));
      expect(normalized.gender, equals('male'));
      expect(normalized.ageCategory, equals('adult')); // 18-40
    });

    test('normalize prioritizes anthropometry record over training profile', () {
      final normalized = DataNormalizer.normalize(testSnapshot);

      // Altura debe venir de AnthropometryRecord, no de TrainingProfile.extra
      expect(normalized.heightCm, equals(175.0));
      expect(normalized.weightKg, equals(80.0));
    });

    test('normalize calculates BMI correctly', () {
      final normalized = DataNormalizer.normalize(testSnapshot);

      // BMI = 80 / (1.75^2) = 80 / 3.0625 = 26.12
      expect(normalized.bmi, closeTo(26.12, 0.01));
    });

    test('normalize classifies height correctly', () {
      final tests = [
        (heightCm: 155.0, expected: 'very_short'),
        (heightCm: 165.0, expected: 'short'),
        (heightCm: 175.0, expected: 'average'),
        (heightCm: 185.0, expected: 'tall'),
        (heightCm: 195.0, expected: 'very_tall'),
      ];

      for (final test in tests) {
        final snapshot = testSnapshot.copyWith(
          latestAnthropometry: AnthropometryRecord(
            date: DateTime.now(),
            heightCm: test.heightCm,
            weightKg: 80.0,
          ),
        );
        final normalized = DataNormalizer.normalize(snapshot);
        expect(
          normalized.heightClass,
          equals(test.expected),
          reason: 'Height ${test.heightCm} should be ${test.expected}',
        );
      }
    });

    test('normalize classifies weight correctly', () {
      final tests = [
        // BMI = weight / (height^2)
        (weightKg: 55.0, heightCm: 175.0, expected: 'underweight'), // BMI ~18
        (weightKg: 70.0, heightCm: 175.0, expected: 'normal'), // BMI ~22.9
        (weightKg: 85.0, heightCm: 175.0, expected: 'overweight'), // BMI ~27.8
        (weightKg: 100.0, heightCm: 175.0, expected: 'obese'), // BMI ~32.7
      ];

      for (final test in tests) {
        final snapshot = testSnapshot.copyWith(
          latestAnthropometry: AnthropometryRecord(
            date: DateTime.now(),
            heightCm: test.heightCm,
            weightKg: test.weightKg,
          ),
        );
        final normalized = DataNormalizer.normalize(snapshot);
        expect(
          normalized.weightClass,
          equals(test.expected),
          reason: 'Weight ${test.weightKg}kg at ${test.heightCm}cm should be ${test.expected}',
        );
      }
    });

    test('normalize applies Israetel height adjustments correctly', () {
      // Persona alta (>185cm): +10%
      final tallSnapshot = testSnapshot.copyWith(
        latestAnthropometry: AnthropometryRecord(
          date: DateTime.now(),
          heightCm: 190.0,
          weightKg: 90.0,
        ),
      );
      final tallNormalized = DataNormalizer.normalize(tallSnapshot);
      expect(tallNormalized.heightAdjustmentVME, equals(1.10));
      expect(tallNormalized.heightAdjustmentVMR, equals(1.10));

      // Persona baja (<165cm): -10%
      final shortSnapshot = testSnapshot.copyWith(
        latestAnthropometry: AnthropometryRecord(
          date: DateTime.now(),
          heightCm: 160.0,
          weightKg: 60.0,
        ),
      );
      final shortNormalized = DataNormalizer.normalize(shortSnapshot);
      expect(shortNormalized.heightAdjustmentVME, equals(0.90));
      expect(shortNormalized.heightAdjustmentVMR, equals(0.90));

      // Persona promedio: sin ajuste
      final normalized = DataNormalizer.normalize(testSnapshot);
      expect(normalized.heightAdjustmentVME, equals(1.0));
      expect(normalized.heightAdjustmentVMR, equals(1.0));
    });

    test('normalize applies Israetel sleep adjustments correctly', () {
      final tests = [
        (sleep: 5.0, expectedVME: 0.80, expectedVMR: 0.80), // <6h: -20%
        (sleep: 6.5, expectedVME: 0.90, expectedVMR: 0.90), // 6-7h: -10%
        (sleep: 8.0, expectedVME: 1.0, expectedVMR: 1.0), // 7-9h: normal
        (sleep: 10.0, expectedVME: 1.05, expectedVMR: 1.05), // >9h: +5%
      ];

      for (final test in tests) {
        final snapshot = testSnapshot.copyWith(
          trainingProfile: TrainingProfile(
            avgSleepHours: test.sleep,
          ),
        );
        final normalized = DataNormalizer.normalize(snapshot);
        expect(
          normalized.sleepAdjustmentVME,
          equals(test.expectedVME),
          reason: 'Sleep ${test.sleep}h should have VME adjustment ${test.expectedVME}',
        );
        expect(
          normalized.sleepAdjustmentVMR,
          equals(test.expectedVMR),
          reason: 'Sleep ${test.sleep}h should have VMR adjustment ${test.expectedVMR}',
        );
      }
    });

    test('normalize applies experience adjustments correctly', () {
      final tests = [
        (years: 0, expectedVME: 0.80, expectedVMR: 0.80), // Principiante: -20%
        (years: 3, expectedVME: 1.0, expectedVMR: 1.0), // Intermedio: normal
        (years: 8, expectedVME: 1.15, expectedVMR: 1.15), // Avanzado: +15%
      ];

      for (final test in tests) {
        final snapshot = testSnapshot.copyWith(
          trainingProfile: TrainingProfile(
            yearsTrainingContinuous: test.years,
          ),
        );
        final normalized = DataNormalizer.normalize(snapshot);
        expect(
          normalized.experienceAdjustmentVME,
          equals(test.expectedVME),
          reason: 'Years ${test.years} should have VME adjustment ${test.expectedVME}',
        );
        expect(
          normalized.experienceAdjustmentVMR,
          equals(test.expectedVMR),
          reason: 'Years ${test.years} should have VMR adjustment ${test.expectedVMR}',
        );
      }
    });

    test('normalize applies anabolics adjustment correctly', () {
      final snapshot = testSnapshot.copyWith(
        trainingProfile: TrainingProfile(
          usesAnabolics: true,
        ),
      );
      final normalized = DataNormalizer.normalize(snapshot);

      // Israetel: +15% MRV si usa anabólicos
      expect(normalized.usesAnabolics, isTrue);
      expect(normalized.anabolicsAdjustmentVMR, equals(1.15));
    });

    test('normalize applies rest adjustment correctly', () {
      // Descanso corto (<120s): 1.8x fatiga
      final shortRestSnapshot = testSnapshot.copyWith(
        trainingProfile: TrainingProfile(
          restBetweenSetsSeconds: 90,
        ),
      );
      final shortRestNormalized = DataNormalizer.normalize(shortRestSnapshot);
      expect(shortRestNormalized.restAdjustmentFatigue, equals(1.8));

      // Descanso normal (>=120s): sin ajuste
      final normalRestSnapshot = testSnapshot.copyWith(
        trainingProfile: TrainingProfile(
          restBetweenSetsSeconds: 180,
        ),
      );
      final normalRestNormalized = DataNormalizer.normalize(normalRestSnapshot);
      expect(normalRestNormalized.restAdjustmentFatigue, equals(1.0));
    });

    test('normalize calculates total adjustments correctly', () {
      final normalized = DataNormalizer.normalize(testSnapshot);

      // VME total = producto de todos los ajustes
      final expectedVME = normalized.heightAdjustmentVME *
          normalized.weightAdjustmentVME *
          normalized.sleepAdjustmentVME *
          normalized.stressAdjustmentVME *
          normalized.experienceAdjustmentVME *
          normalized.noveltyAdjustmentVME;

      expect(normalized.totalVMEAdjustment, equals(expectedVME));

      // VMR total = producto de todos los ajustes (incluyendo anabólicos)
      final expectedVMR = normalized.heightAdjustmentVMR *
          normalized.weightAdjustmentVMR *
          normalized.sleepAdjustmentVMR *
          normalized.stressAdjustmentVMR *
          normalized.experienceAdjustmentVMR *
          normalized.noveltyAdjustmentVMR *
          normalized.anabolicsAdjustmentVMR;

      expect(normalized.totalVMRAdjustment, equals(expectedVMR));
    });

    test('normalize handles missing anthropometry gracefully', () {
      final snapshot = testSnapshot.copyWith(
        latestAnthropometry: null,
      );
      final normalized = DataNormalizer.normalize(snapshot);

      // Debe usar fallback de TrainingProfile.extra
      expect(normalized.heightCm, equals(175.0));
      expect(normalized.weightKg, equals(80.0));
    });

    test('hasMinimalData returns correct values', () {
      final normalized = DataNormalizer.normalize(testSnapshot);
      expect(normalized.hasMinimalData, isTrue);

      final emptySnapshot = ClientDataSnapshot(
        clientId: 'empty',
        capturedAt: DateTime.now(),
      );
      final emptyNormalized = DataNormalizer.normalize(emptySnapshot);
      expect(emptyNormalized.hasMinimalData, isFalse);
    });
  });

  group('Motor V3 Unificado - Integration Tests', () {
    test('End-to-end: Client → Snapshot → Normalized', () async {
      // 1. Crear cliente completo
      final client = Client(
        id: 'integration-test',
        profile: ClientProfile(
          name: 'Integration Test',
          email: 'integration@example.com',
          dateOfBirth: DateTime(1988, 6, 15),
        ),
        history: ClinicalHistory(
          conditions: [],
          medications: [],
        ),
        training: TrainingProfile(
          gender: Gender.female,
          age: 36,
          bodyWeight: 65.0,
          usesAnabolics: false,
          yearsTrainingContinuous: 4,
          restBetweenSetsSeconds: 120,
          avgSleepHours: 8.0,
        ),
        nutrition: NutritionSettings.empty(),
        anthropometry: [
          AnthropometryRecord(
            date: DateTime.now(),
            heightCm: 165.0,
            weightKg: 65.0,
          ),
        ],
      );

      // 2. Recolectar snapshot
      final snapshot = await UnifiedDataCollector.collectClientData(client);

      expect(snapshot.clientId, equals('integration-test'));
      expect(snapshot.hasAnthropometry, isTrue);

      // 3. Normalizar
      final normalized = DataNormalizer.normalize(snapshot);

      // 4. Verificar datos normalizados
      expect(normalized.age, equals(36));
      expect(normalized.gender, equals('female'));
      expect(normalized.ageCategory, equals('adult'));
      expect(normalized.heightCm, equals(165.0));
      expect(normalized.weightKg, equals(65.0));
      expect(normalized.heightClass, equals('short'));
      expect(normalized.heightAdjustmentVME, equals(0.90)); // Persona baja
      expect(normalized.sleepAdjustmentVME, equals(1.0)); // 8h = normal
      expect(normalized.experienceAdjustmentVME, equals(1.0)); // 4 años = intermedio
      expect(normalized.hasMinimalData, isTrue);
    });
  });
}

// Extension helper para copiar snapshot en tests
extension ClientDataSnapshotCopyWith on ClientDataSnapshot {
  ClientDataSnapshot copyWith({
    String? clientId,
    DateTime? capturedAt,
    ClientProfile? clientProfile,
    TrainingProfile? trainingProfile,
    AnthropometryRecord? latestAnthropometry,
    List<AnthropometryRecord>? anthropometryHistory,
    List<DailyTrackingRecord>? recentDailyTracking,
  }) {
    return ClientDataSnapshot(
      clientId: clientId ?? this.clientId,
      capturedAt: capturedAt ?? this.capturedAt,
      clientProfile: clientProfile ?? this.clientProfile,
      trainingProfile: trainingProfile ?? this.trainingProfile,
      latestAnthropometry: latestAnthropometry ?? this.latestAnthropometry,
      anthropometryHistory: anthropometryHistory ?? this.anthropometryHistory,
      recentDailyTracking: recentDailyTracking ?? this.recentDailyTracking,
    );
  }
}
