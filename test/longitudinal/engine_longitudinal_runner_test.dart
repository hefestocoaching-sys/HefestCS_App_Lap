import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/entities/training_feedback.dart';
import 'package:hcs_app_lap/domain/services/training_program_engine.dart';
import '../fixtures/training_fixtures.dart';

void main() {
  test('LONGITUDINAL RUNNER — export 12 weeks JSON', () async {
    // ====== CONFIGURACIÓN BASE (determinista) ======
    final engine = TrainingProgramEngine();

    final referenceStart = DateTime.utc(2025, 1, 6); // lunes fijo
    final outputDir = Directory('test/longitudinal/output');
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }

    // ====== PERFIL BASE Y CATÁLOGO CANÓNICO ======
    final baseProfile = validTrainingProfile(
      daysPerWeek: 4,
    ).copyWith(id: 'client_longitudinal_01');
    final exercises = canonicalExercises();

    // ====== PLAN DE SEÑALES POR SEMANA ======
    // Define el "stress test" clínico
    TrainingFeedback? feedbackForWeek(int week) {
      if (week == 1) {
        // Primera semana: sin feedback previo
        return null;
      }
      if (week <= 3) {
        // Semanas 2-3: Progresión positiva
        return const TrainingFeedback(
          fatigue: 4.0,
          soreness: 5.0,
          motivation: 8.0,
          adherence: 0.9,
          avgRir: 2.5,
          sleepHours: 7.5,
          stressLevel: 4.0,
        );
      }
      if (week <= 5) {
        // Semanas 4-5: Señales mixtas
        return const TrainingFeedback(
          fatigue: 6.0,
          soreness: 6.0,
          motivation: 7.0,
          adherence: 0.8,
          avgRir: 2.0,
          sleepHours: 7.0,
          stressLevel: 5.0,
        );
      }
      if (week == 6) {
        // Semana 6: Fatiga alta → deload esperado
        return const TrainingFeedback(
          fatigue: 8.5,
          soreness: 8.0,
          motivation: 5.0,
          adherence: 0.7,
          avgRir: 3.0,
          sleepHours: 6.5,
          stressLevel: 7.0,
        );
      }
      if (week <= 8) {
        // Semanas 7-8: Recuperación post-deload
        return const TrainingFeedback(
          fatigue: 3.0,
          soreness: 4.0,
          motivation: 8.5,
          adherence: 0.85,
          avgRir: 2.5,
          sleepHours: 8.0,
          stressLevel: 3.0,
        );
      }
      if (week <= 10) {
        // Semanas 9-10: Nueva progresión
        return const TrainingFeedback(
          fatigue: 5.0,
          soreness: 5.5,
          motivation: 8.0,
          adherence: 0.9,
          avgRir: 2.0,
          sleepHours: 7.5,
          stressLevel: 4.0,
        );
      }
      // Semanas 11-12: Meseta / sobrecarga controlada
      return const TrainingFeedback(
        fatigue: 7.0,
        soreness: 7.0,
        motivation: 6.5,
        adherence: 0.75,
        avgRir: 2.0,
        sleepHours: 7.0,
        stressLevel: 6.0,
      );
    }

    // ====== EJECUCIÓN SEMANA A SEMANA ======
    for (int week = 1; week <= 12; week++) {
      final weekStartDate = referenceStart.add(Duration(days: 7 * (week - 1)));

      try {
        final plan = engine.generatePlan(
          planId: 'longitudinal_plan_w${week.toString().padLeft(2, '0')}',
          clientId: 'client_longitudinal_01',
          planName: 'Longitudinal Week $week',
          startDate: weekStartDate,
          profile: baseProfile,
          latestFeedback: feedbackForWeek(week),
          exercises: exercises,
        );

        // Validación clínica: todas las sesiones deben tener ≥4 ejercicios
        for (final w in plan.weeks) {
          for (final s in w.sessions) {
            expect(
              s.prescriptions.length >= 4,
              isTrue,
              reason:
                  'Parcialmente válido: ${s.id} tiene <4 ejercicios (count=${s.prescriptions.length})',
            );
          }
        }

        // Serializar plan completo
        final planJson = plan.toJson();

        // Serializar feedback manualmente (no tiene toJson)
        final feedback = feedbackForWeek(week);
        final feedbackJson = feedback != null
            ? {
                'fatigue': feedback.fatigue,
                'soreness': feedback.soreness,
                'motivation': feedback.motivation,
                'adherence': feedback.adherence,
                'avgRir': feedback.avgRir,
                'sleepHours': feedback.sleepHours,
                'stressLevel': feedback.stressLevel,
              }
            : null;

        // Agregar metadatos para auditoría
        final auditPackage = {
          'weekNumber': week,
          'generatedAt': DateTime.now().toUtc().toIso8601String(),
          'blocked': false,
          'errorMessage': null,
          'feedbackInput': feedbackJson,
          'plan': planJson,
          'decisions': engine.lastDecisions.map((d) => d.toJson()).toList(),
        };

        final json = const JsonEncoder.withIndent('  ').convert(auditPackage);

        final file = File(
          '${outputDir.path}/week_${week.toString().padLeft(2, '0')}.json',
        );
        file.writeAsStringSync(json);

        // ignore: avoid_print
        print('✅ Generated week_${week.toString().padLeft(2, '0')}.json');
      } on StateError catch (e) {
        // Bloqueo clínico aceptado; exportar auditoría del bloqueo
        final feedback = feedbackForWeek(week);
        final feedbackJson = feedback != null
            ? {
                'fatigue': feedback.fatigue,
                'soreness': feedback.soreness,
                'motivation': feedback.motivation,
                'adherence': feedback.adherence,
                'avgRir': feedback.avgRir,
                'sleepHours': feedback.sleepHours,
                'stressLevel': feedback.stressLevel,
              }
            : null;

        final auditPackage = {
          'weekNumber': week,
          'generatedAt': DateTime.now().toUtc().toIso8601String(),
          'blocked': true,
          'errorMessage': e.message,
          'feedbackInput': feedbackJson,
          'plan': null,
          'decisions': engine.lastDecisions.map((d) => d.toJson()).toList(),
        };

        final json = const JsonEncoder.withIndent('  ').convert(auditPackage);

        final file = File(
          '${outputDir.path}/week_${week.toString().padLeft(2, '0')}.json',
        );
        file.writeAsStringSync(json);
        // ignore: avoid_print
        print(
          '⛔️ Blocked week_${week.toString().padLeft(2, '0')}.json: ${e.message}',
        );
      }
      // Cualquier excepción distinta a StateError es un fallo del sistema
      catch (e) {
        // ignore: avoid_print
        print('❌ System error on week $week: $e');
        rethrow;
      }
    }

    // Runner no falla: solo exporta
    expect(outputDir.existsSync(), isTrue);
    expect(
      outputDir.listSync().where((f) => f.path.endsWith('.json')).length,
      equals(12),
    );
  });
}
