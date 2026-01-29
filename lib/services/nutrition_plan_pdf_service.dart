import 'dart:io';

import 'package:hcs_app_lap/core/constants/nutrition_extra_keys.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/daily_meal_plan.dart';
import 'package:hcs_app_lap/utils/nutrition_record_helpers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

class NutritionPlanPdfService {
  Future<String?> generateForClient({required Client client, required String dateIso}) async {
    final plans = _resolveActivePlans(client, dateIso);
    if (plans.isEmpty) return null;

    final clientLabel = client.fullName;

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text('Plan de comidas', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text(clientLabel),
          pw.SizedBox(height: 16),
          ...plans.entries.map((entry) => _buildDay(entry.key, entry.value)),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'meal_plan_${client.id}_$dateIso.pdf';
    final outPath = '${dir.path}/$fileName';
    final file = File(outPath);
    await file.writeAsBytes(await doc.save());
    return outPath;
  }

  Map<String, DailyMealPlan> _resolveActivePlans(Client client, String dateIso) {
    final records = readNutritionRecordList(
      client.nutrition.extra[NutritionExtraKeys.mealPlanRecords],
    );
    final record = nutritionRecordForDate(records, dateIso) ?? latestNutritionRecordByDate(records);
    final parsed = parseDailyMealPlans(record?['dailyMealPlans']);
    if (parsed != null) return parsed;
    final existing = client.nutrition.dailyMealPlans;
    if (existing != null) return Map<String, DailyMealPlan>.from(existing);
    return {};
  }

  pw.Widget _buildDay(String dayKey, DailyMealPlan plan) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(dayKey, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        ...plan.meals.map(_buildMeal),
        pw.SizedBox(height: 12),
      ],
    );
  }

  pw.Widget _buildMeal(Meal meal) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(meal.name, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          if (meal.items.isEmpty)
            pw.Text('Sin alimentos', style: pw.TextStyle(fontSize: 10))
          else
            pw.Table(
              border: pw.TableBorder.all(width: 0.3),
              columnWidths: const {
                0: pw.FlexColumnWidth(3),
                1: pw.FlexColumnWidth(1),
                2: pw.FlexColumnWidth(1),
                3: pw.FlexColumnWidth(1),
                4: pw.FlexColumnWidth(1),
                5: pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Alimento')),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('g')),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('kcal')),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('P')),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('C')),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('G')),
                  ],
                ),
                ...meal.items.map(
                  (item) => pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(item.name)),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(item.grams.toStringAsFixed(0))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(item.kcal.toStringAsFixed(0))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(item.protein.toStringAsFixed(1))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(item.carbs.toStringAsFixed(1))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(item.fat.toStringAsFixed(1))),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

final nutritionPlanPdfService = NutritionPlanPdfService();
