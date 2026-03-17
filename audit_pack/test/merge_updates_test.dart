import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/client_profile.dart';
import 'package:hcs_app_lap/domain/entities/clinical_history.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';
import 'package:hcs_app_lap/domain/entities/nutrition_settings.dart';

Client buildBaseClient() {
  const profile = ClientProfile(
    id: 'p1',
    fullName: 'Test',
    email: 't@example.com',
    phone: '000',
    country: 'Nowhere',
    occupation: 'Test',
    objective: 'Test',
  );

  return Client(
    id: 'c1',
    profile: profile,
    history: const ClinicalHistory(),
    training: TrainingProfile.empty(),
    nutrition: const NutritionSettings(),
  );
}

void main() {
  test('Sequential merges preserve non-conflicting nutrition.extra keys', () {
    final prev = buildBaseClient();

    // Simulate first update: dietary evaluation records
    Client updateA(Client p) {
      final merged = Map<String, dynamic>.from(p.nutrition.extra);
      merged['evaluationRecords'] = [
        {'dateIso': '2025-12-28', 'kcal': 2000},
      ];
      return p.copyWith(nutrition: p.nutrition.copyWith(extra: merged));
    }

    // Simulate second update: meal plan records
    Client updateB(Client p) {
      final merged = Map<String, dynamic>.from(p.nutrition.extra);
      merged['mealPlanRecords'] = [
        {'dateIso': '2025-12-28', 'meals': []},
      ];
      return p.copyWith(nutrition: p.nutrition.copyWith(extra: merged));
    }

    // Apply A then B as would happen with merge-on-write
    final afterA = updateA(prev);
    final afterB = updateB(afterA);

    expect(afterB.nutrition.extra.containsKey('evaluationRecords'), true);
    expect(afterB.nutrition.extra.containsKey('mealPlanRecords'), true);

    // Now apply in reverse order (B then A)
    final afterBfirst = updateB(prev);
    final afterAsecond = updateA(afterBfirst);

    expect(afterAsecond.nutrition.extra.containsKey('evaluationRecords'), true);
    expect(afterAsecond.nutrition.extra.containsKey('mealPlanRecords'), true);
  });

  test('Conflicting keys: last merge wins for the same key', () {
    final prev = buildBaseClient();

    Client updateA(Client p) {
      final merged = Map<String, dynamic>.from(p.nutrition.extra);
      merged['evaluationRecords'] = [
        {'dateIso': '2025-12-28', 'kcal': 2000},
      ];
      return p.copyWith(nutrition: p.nutrition.copyWith(extra: merged));
    }

    Client updateAconflict(Client p) {
      final merged = Map<String, dynamic>.from(p.nutrition.extra);
      merged['evaluationRecords'] = [
        {'dateIso': '2025-12-28', 'kcal': 1500},
      ];
      return p.copyWith(nutrition: p.nutrition.copyWith(extra: merged));
    }

    final afterFirst = updateA(prev);
    final afterSecond = updateAconflict(afterFirst);

    final records =
        afterSecond.nutrition.extra['evaluationRecords'] as List<dynamic>;
    expect(records.first['kcal'], 1500);
  });
}
