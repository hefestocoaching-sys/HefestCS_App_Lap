import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/core/utils/update_lock.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/domain/entities/client_profile.dart';
import 'package:hcs_app_lap/domain/entities/clinical_history.dart';
import 'package:hcs_app_lap/domain/entities/daily_macro_settings.dart';
import 'package:hcs_app_lap/domain/entities/nutrition_settings.dart';
import 'package:hcs_app_lap/domain/entities/training_profile.dart';

void main() {
  group('Critical Flows - No Breaking Changes', () {
    test('Client serialization backward compatible', () {
      const profile = ClientProfile(
        id: 'test',
        fullName: 'Test User',
        email: 'test@example.com',
        phone: '0000000000',
        country: 'NA',
        occupation: 'QA',
        objective: 'Test',
      );
      const history = ClinicalHistory();
      final training = TrainingProfile.empty();
      final client = Client(
        id: 'test',
        profile: profile,
        history: history,
        training: training,
        nutrition: const NutritionSettings(
          weeklyMacroSettings: {
            'Lunes': DailyMacroSettings(
              proteinSelected: 2.0,
              fatSelected: 0.9,
              carbSelected: 4.5,
            ),
          },
        ),
      );

      final json = client.toJson();
      final deserialized = Client.fromJson(json);

      expect(deserialized.id, client.id);
      expect(deserialized.nutrition.weeklyMacroSettings?.length, 1);
      expect(
        deserialized.nutrition.weeklyMacroSettings?['Lunes']?.proteinSelected,
        2.0,
      );
    });

    test('Equivalents persist correctly', () async {
      const profile = ClientProfile(
        id: 'test',
        fullName: 'Test User',
        email: 'test@example.com',
        phone: '0000000000',
        country: 'NA',
        occupation: 'QA',
        objective: 'Test',
      );
      const history = ClinicalHistory();
      final training = TrainingProfile.empty();
      final client = Client(
        id: 'test',
        profile: profile,
        history: history,
        training: training,
        nutrition: const NutritionSettings(
          extra: {
            'equivalents_by_day': {
              'lunes': {'grains': 2, 'vegetables': 3},
            },
          },
        ),
      );

      final json = client.toJson();
      final deserialized = Client.fromJson(json);

      final extra = deserialized.nutrition.extra;
      final payload = extra['equivalents_by_day'] as Map<String, dynamic>?;
      expect(payload, isNotNull);
      expect((payload?['lunes'] as Map<String, dynamic>)['grains'], 2);
    });

    test('Concurrent updates dont lose data', () async {
      final lock = UpdateLock.instance;
      final order = <int>[];

      await Future.wait([
        lock.safeClientUpdate(() async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          order.add(1);
        }),
        lock.safeClientUpdate(() async {
          order.add(2);
        }),
      ]);

      expect(order, containsAll(<int>[1, 2]));
      expect(order.length, 2);
    });
  });
}
