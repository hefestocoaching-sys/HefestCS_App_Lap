import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hcs_app_lap/domain/training_v3/models/exercise_log.dart';
import 'package:hcs_app_lap/domain/training_v3/models/muscle_decision.dart';
import 'package:hcs_app_lap/domain/training_v3/models/muscle_progression_tracker.dart';
import 'package:hcs_app_lap/domain/training_v3/models/progress_record.dart';
import 'package:hcs_app_lap/domain/training_v3/models/feedback_entry.dart';
import 'package:hcs_app_lap/domain/training_v3/models/training_audit_log.dart';
import 'package:hcs_app_lap/domain/training_v3/services/weekly_progression_service_enhanced.dart';
import 'package:hcs_app_lap/domain/training_v3/services/weekly_progression_service_enhanced_adapter.dart';

class MockEnhancedService extends Mock
    implements WeeklyProgressionServiceEnhanced {}

void main() {
  late WeeklyProgressionServiceEnhancedAdapter adapter;
  late MockEnhancedService mockEnhancedService;

  setUp(() {
    mockEnhancedService = MockEnhancedService();
    adapter = WeeklyProgressionServiceEnhancedAdapter(mockEnhancedService);

    registerFallbackValue(DateTime.now());
    registerFallbackValue(<ExerciseLog>[]);
    registerFallbackValue(<String, FeedbackEntry>{});
  });

  group('WeeklyProgressionServiceEnhancedAdapter', () {
    test(
      'processWeeklyProgression should delegate to enhanced service',
      () async {
        const userId = 'user123';
        const weekNumber = 1;

        // Mock result
        final enhancedResult = EnhancedProgressionResult(
          decisions: {
            'pectorals': MuscleDecision(
              muscle: 'pectorals',
              action: VolumeAction.maintain,
              newVolume: 10,
              previousVolume: 10,
              newPhase: ProgressionPhase.maintaining,
              reason: 'Test decision',
              confidence: 1.0,
            ),
          },
          progressRecords: <String, ProgressRecord>{},
          auditTrail: <TrainingAuditLogEntry>[],
          auditReport: 'Valid',
          allValid: true,
          requiresCoachAttention: <String>[],
        );

        when(
          () => mockEnhancedService.processWeeklyProgressionEnhanced(
            userId: any(named: 'userId'),
            weekNumber: any(named: 'weekNumber'),
            weekStart: any(named: 'weekStart'),
            weekEnd: any(named: 'weekEnd'),
            exerciseLogs: any(named: 'exerciseLogs'),
            feedbackByMuscle: any(named: 'feedbackByMuscle'),
          ),
        ).thenAnswer((_) async => enhancedResult);

        final decisions = await adapter.processWeeklyProgression(
          userId: userId,
          weekNumber: weekNumber,
          weekStart: DateTime.now(),
          weekEnd: DateTime.now(),
          exerciseLogs: [],
          userFeedbackByMuscle: {
            'pectorals': {'muscle_activation': 8.0, 'comments': 'Good workout'},
          },
        );

        expect(decisions.length, 1);
        expect(decisions['pectorals']?.action, VolumeAction.maintain);

        verify(
          () => mockEnhancedService.processWeeklyProgressionEnhanced(
            userId: userId,
            weekNumber: weekNumber,
            weekStart: any(named: 'weekStart'),
            weekEnd: any(named: 'weekEnd'),
            exerciseLogs: any(named: 'exerciseLogs'),
            feedbackByMuscle: any(named: 'feedbackByMuscle'),
          ),
        ).called(1);
      },
    );
  });
}
