import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:hcs_app_lap/domain/training_v3/models/training_plan.dart';
import 'package:hcs_app_lap/domain/training_v3/services/training_plan_formatter.dart';

Future<Uint8List> exportTrainingPlanPdf(TrainingPlan plan) async {
  final formatted = formatPlan(plan);
  final document = pw.Document();

  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) {
        final widgets = <pw.Widget>[
          pw.Text(
            'Programa de Entrenamiento',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Mesociclo: 4 semanas',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 16),
        ];

        for (final week in formatted.weeks) {
          widgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Text(
                'SEMANA ${week.weekNumber}',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          );

          for (final session in week.sessions) {
            widgets.add(
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Text(
                  'DIA ${session.dayNumber}: ${session.name}',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            );

            widgets.add(
              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.grey400,
                  width: 0.5,
                ),
                columnWidths: {
                  0: const pw.FixedColumnWidth(28),
                  1: const pw.FlexColumnWidth(4),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FixedColumnWidth(36),
                  4: const pw.FixedColumnWidth(52),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: _headerRow(),
                  ),
                  ...session.rows.map((row) {
                    return pw.TableRow(
                      children: [
                        _cell(row.slotLabel),
                        _cell(row.exerciseName),
                        _cell(row.primaryMuscle),
                        _cell('${row.sets}'),
                        _cell(row.reps),
                      ],
                    );
                  }),
                ],
              ),
            );
            widgets.add(pw.SizedBox(height: 10));
          }

          widgets.add(pw.SizedBox(height: 8));
        }

        return widgets;
      },
    ),
  );

  return document.save();
}

Future<void> printTrainingPlanPdf(TrainingPlan plan) async {
  final bytes = await exportTrainingPlanPdf(plan);
  await Printing.layoutPdf(onLayout: (_) async => bytes);
}

List<pw.Widget> _headerRow() {
  return [
    _headerCell('Slot'),
    _headerCell('Ejercicio'),
    _headerCell('Musculo'),
    _headerCell('Sets'),
    _headerCell('Reps'),
  ];
}

pw.Widget _headerCell(String text) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(4),
    child: pw.Text(
      text,
      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
    ),
  );
}

pw.Widget _cell(String text) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(4),
    child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
  );
}
