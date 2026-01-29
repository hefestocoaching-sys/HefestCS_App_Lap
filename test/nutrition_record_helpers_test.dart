import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/utils/nutrition_record_helpers.dart';

void main() {
  test('normalize and find record by date when record has timestamp', () {
    final records = [
      {'dateIso': '2025-12-27T12:00:00Z', 'kcal': 1800},
      {'dateIso': '2025-12-28', 'kcal': 2000},
    ];

    final latest = latestNutritionRecordByDate(records);
    expect(latest != null, true);
    expect(latest!['kcal'], 2000);

    final found = nutritionRecordForDate(records, '2025-12-27');
    expect(found != null, true);
    expect(found!['kcal'], 1800);
  });

  test('latest ignores invalid dates', () {
    final records = [
      {'dateIso': 'invalid-date', 'kcal': 1000},
      {'dateIso': '2025-01-01', 'kcal': 1500},
    ];

    final latest = latestNutritionRecordByDate(records);
    expect(latest != null, true);
    expect(latest!['kcal'], 1500);
  });

  test('sort places invalid dates last and sorts ascending', () {
    final records = [
      {'dateIso': '2025-12-28', 'kcal': 2000},
      {'dateIso': 'bad', 'kcal': 500},
      {'dateIso': '2025-12-27T23:59:59Z', 'kcal': 1800},
    ];

    sortNutritionRecordsByDate(records);
    expect(records[0]['kcal'], 1800);
    expect(records[1]['kcal'], 2000);
    expect(records[2]['kcal'], 500);
  });
}
