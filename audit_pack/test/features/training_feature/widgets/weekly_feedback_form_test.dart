// test/features/training_feature/widgets/weekly_feedback_form_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/features/training_feature/widgets/weekly_feedback_form.dart';

void main() {
  group('WeeklyFeedbackForm Widget', () {
    testWidgets('should render all sliders', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeeklyFeedbackForm(
              muscle: 'pectorals',
              onFeedbackChanged: (feedback) {
                feedback;
              },
            ),
          ),
        ),
      );

      expect(find.text('Activacion Muscular'), findsOneWidget);
      expect(find.text('Calidad del Pump'), findsOneWidget);
      expect(find.text('Nivel de Fatiga'), findsOneWidget);
      expect(find.text('Calidad de Recuperacion'), findsOneWidget);

      expect(find.text('Pectorales'), findsOneWidget);

      expect(find.text('Tuviste dolor?'), findsOneWidget);
    });

    testWidgets('should initialize with default values', (
      WidgetTester tester,
    ) async {
      Map<String, dynamic>? capturedFeedback;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeeklyFeedbackForm(
              muscle: 'quadriceps',
              onFeedbackChanged: (feedback) {
                capturedFeedback = feedback;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(capturedFeedback, isNotNull);
      expect(capturedFeedback!['muscle_activation'], 7.0);
      expect(capturedFeedback!['pump_quality'], 7.0);
      expect(capturedFeedback!['fatigue_level'], 5.0);
      expect(capturedFeedback!['recovery_quality'], 7.0);
      expect(capturedFeedback!['had_pain'], false);
    });

    testWidgets('should update feedback when sliders change', (
      WidgetTester tester,
    ) async {
      Map<String, dynamic>? capturedFeedback;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeeklyFeedbackForm(
              muscle: 'lats',
              onFeedbackChanged: (feedback) {
                capturedFeedback = feedback;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final activationSlider = find.byType(Slider).first;
      await tester.drag(activationSlider, const Offset(100, 0));
      await tester.pumpAndSettle();

      expect(capturedFeedback!['muscle_activation'], greaterThan(7.0));
    });

    testWidgets('should show pain fields when pain switch is enabled', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeeklyFeedbackForm(
              muscle: 'hamstrings',
              onFeedbackChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Severidad del Dolor'), findsNothing);

      final painSwitch = find.byType(SwitchListTile);
      await tester.tap(painSwitch);
      await tester.pumpAndSettle();

      expect(find.text('Severidad del Dolor'), findsOneWidget);
      expect(find.text('Descripcion del dolor (opcional)'), findsOneWidget);
    });

    testWidgets('should handle pain severity and description', (
      WidgetTester tester,
    ) async {
      Map<String, dynamic>? capturedFeedback;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeeklyFeedbackForm(
              muscle: 'biceps',
              onFeedbackChanged: (feedback) {
                capturedFeedback = feedback;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final painSwitch = find.byType(SwitchListTile);
      await tester.tap(painSwitch);
      await tester.pumpAndSettle();

      expect(capturedFeedback!['had_pain'], true);
      expect(capturedFeedback!['pain_severity'], isNotNull);

      final descriptionField = find.byType(TextField);
      await tester.enterText(descriptionField, 'Sharp pain in elbow');
      await tester.pumpAndSettle();

      expect(capturedFeedback!['pain_description'], 'Sharp pain in elbow');
    });

    testWidgets('should load initial feedback correctly', (
      WidgetTester tester,
    ) async {
      final initialFeedback = {
        'muscle_activation': 9.0,
        'pump_quality': 8.5,
        'fatigue_level': 6.0,
        'recovery_quality': 7.5,
        'had_pain': true,
        'pain_severity': 4.0,
        'pain_description': 'Mild soreness',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeeklyFeedbackForm(
              muscle: 'glutes',
              initialFeedback: initialFeedback,
              onFeedbackChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('9.0'), findsOneWidget);
      expect(find.text('8.5'), findsOneWidget);

      expect(find.text('Severidad del Dolor'), findsOneWidget);
      expect(find.text('Mild soreness'), findsOneWidget);
    });

    testWidgets('should validate slider ranges', (WidgetTester tester) async {
      Map<String, dynamic>? capturedFeedback;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeeklyFeedbackForm(
              muscle: 'calves',
              onFeedbackChanged: (feedback) {
                capturedFeedback = feedback;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        capturedFeedback!['muscle_activation'],
        inInclusiveRange(1.0, 10.0),
      );
      expect(capturedFeedback!['pump_quality'], inInclusiveRange(1.0, 10.0));
      expect(capturedFeedback!['fatigue_level'], inInclusiveRange(1.0, 10.0));
      expect(
        capturedFeedback!['recovery_quality'],
        inInclusiveRange(1.0, 10.0),
      );
    });
  });
}
