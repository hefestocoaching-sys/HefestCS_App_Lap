// test/features/training_feature/widgets/muscle_progression_card_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/features/training_feature/widgets/muscle_progression_card.dart';
import 'package:hcs_app_lap/domain/training_v3/models/muscle_progression_tracker.dart';
import 'package:hcs_app_lap/domain/training_v3/models/volume_landmarks.dart';

void main() {
  group('MuscleProgressionCard Widget', () {
    testWidgets('should display muscle name and volume', (
      WidgetTester tester,
    ) async {
      final tracker = MuscleProgressionTracker(
        muscle: 'pectorals',
        currentVolume: 14,
        landmarks: const VolumeLandmarks(
          vme: 8,
          vop: 12,
          vmr: 20,
          vmrTarget: 20,
        ),
        currentPhase: ProgressionPhase.discovering,
        weekInCurrentPhase: 2,
        priority: 5,
        totalWeeksInCycle: 2,
        lastUpdated: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MuscleProgressionCard(muscle: 'pectorals', tracker: tracker),
          ),
        ),
      );

      expect(find.text('Pectorales'), findsOneWidget);
      expect(find.text('14 sets'), findsOneWidget);
    });

    testWidgets('should display current phase with correct color', (
      WidgetTester tester,
    ) async {
      final tracker = MuscleProgressionTracker(
        muscle: 'quadriceps',
        currentVolume: 16,
        landmarks: const VolumeLandmarks(
          vme: 12,
          vop: 16,
          vmr: 24,
          vmrTarget: 24,
        ),
        currentPhase: ProgressionPhase.maintaining,
        weekInCurrentPhase: 4,
        priority: 5,
        vmrDiscovered: 18,
        totalWeeksInCycle: 4,
        lastUpdated: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MuscleProgressionCard(muscle: 'quadriceps', tracker: tracker),
          ),
        ),
      );

      expect(find.text('Manteniendo'), findsOneWidget);
      expect(find.text('Semana 5'), findsOneWidget);
    });

    testWidgets('should display VMR when discovered', (
      WidgetTester tester,
    ) async {
      final tracker = MuscleProgressionTracker(
        muscle: 'lats',
        currentVolume: 16,
        landmarks: const VolumeLandmarks(
          vme: 10,
          vop: 14,
          vmr: 22,
          vmrTarget: 22,
        ),
        currentPhase: ProgressionPhase.maintaining,
        weekInCurrentPhase: 3,
        priority: 5,
        vmrDiscovered: 16,
        totalWeeksInCycle: 3,
        lastUpdated: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MuscleProgressionCard(muscle: 'lats', tracker: tracker),
          ),
        ),
      );

      expect(find.text('16 sets'), findsWidgets);
    });

    testWidgets('should display "No descubierto" when VMR not found', (
      WidgetTester tester,
    ) async {
      final tracker = MuscleProgressionTracker(
        muscle: 'biceps',
        currentVolume: 10,
        landmarks: const VolumeLandmarks(
          vme: 6,
          vop: 10,
          vmr: 16,
          vmrTarget: 16,
        ),
        currentPhase: ProgressionPhase.discovering,
        weekInCurrentPhase: 1,
        priority: 3,
        totalWeeksInCycle: 1,
        lastUpdated: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MuscleProgressionCard(muscle: 'biceps', tracker: tracker),
          ),
        ),
      );

      expect(find.text('No descubierto'), findsOneWidget);
    });

    testWidgets('should display priority badge', (WidgetTester tester) async {
      final primaryTracker = MuscleProgressionTracker(
        muscle: 'pectorals',
        currentVolume: 14,
        landmarks: const VolumeLandmarks(
          vme: 8,
          vop: 12,
          vmr: 20,
          vmrTarget: 20,
        ),
        currentPhase: ProgressionPhase.discovering,
        weekInCurrentPhase: 2,
        priority: 5,
        totalWeeksInCycle: 2,
        lastUpdated: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MuscleProgressionCard(
              muscle: 'pectorals',
              tracker: primaryTracker,
            ),
          ),
        ),
      );

      expect(find.text('Primario'), findsOneWidget);
    });

    testWidgets('should call onTap when tapped', (WidgetTester tester) async {
      bool tapped = false;

      final tracker = MuscleProgressionTracker(
        muscle: 'triceps',
        currentVolume: 12,
        landmarks: const VolumeLandmarks(
          vme: 8,
          vop: 12,
          vmr: 18,
          vmrTarget: 18,
        ),
        currentPhase: ProgressionPhase.discovering,
        weekInCurrentPhase: 0,
        priority: 3,
        totalWeeksInCycle: 0,
        lastUpdated: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MuscleProgressionCard(
              muscle: 'triceps',
              tracker: tracker,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(Card));
      await tester.pumpAndSettle();

      expect(tapped, true);
    });

    testWidgets('should display landmarks chips', (WidgetTester tester) async {
      final tracker = MuscleProgressionTracker(
        muscle: 'hamstrings',
        currentVolume: 14,
        landmarks: const VolumeLandmarks(
          vme: 10,
          vop: 14,
          vmr: 22,
          vmrTarget: 22,
        ),
        currentPhase: ProgressionPhase.discovering,
        weekInCurrentPhase: 2,
        priority: 5,
        totalWeeksInCycle: 2,
        lastUpdated: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MuscleProgressionCard(muscle: 'hamstrings', tracker: tracker),
          ),
        ),
      );

      expect(find.text('VME: 10'), findsOneWidget);
      expect(find.text('VOP: 14'), findsOneWidget);
      expect(find.text('MRV: 22'), findsOneWidget);
    });

    testWidgets('should display different phase colors', (
      WidgetTester tester,
    ) async {
      final phases = [
        ProgressionPhase.discovering,
        ProgressionPhase.maintaining,
        ProgressionPhase.overreaching,
        ProgressionPhase.deloading,
        ProgressionPhase.microdeload,
      ];

      for (final phase in phases) {
        final tracker = MuscleProgressionTracker(
          muscle: 'glutes',
          currentVolume: 16,
          landmarks: const VolumeLandmarks(
            vme: 12,
            vop: 16,
            vmr: 24,
            vmrTarget: 24,
          ),
          currentPhase: phase,
          weekInCurrentPhase: 1,
          priority: 5,
          totalWeeksInCycle: 1,
          lastUpdated: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MuscleProgressionCard(muscle: 'glutes', tracker: tracker),
            ),
          ),
        );

        final phaseNames = {
          ProgressionPhase.discovering: 'Descubriendo',
          ProgressionPhase.maintaining: 'Manteniendo',
          ProgressionPhase.overreaching: 'Sobrecarga',
          ProgressionPhase.deloading: 'Descarga',
          ProgressionPhase.microdeload: 'Microdescarga',
        };

        expect(find.text(phaseNames[phase]!), findsOneWidget);
      }
    });
  });
}
