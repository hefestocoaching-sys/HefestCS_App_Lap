import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/training/models/mev_table.dart';

void main() {
  tearDown(() {
    MevTable.seed(const <String, double>{});
  });

  group('MevTable strict muscle normalization', () {
    test('canonical keys are stored and read unchanged', () {
      MevTable.seed(const {'pectorals': 8.0});

      expect(MevTable.getMev('pectorals'), 8.0);
    });

    test('aliases are stored under canonical keys and readable by alias', () {
      MevTable.seed(const {'chest': 9.0});

      expect(MevTable.getMev('pectorals'), 9.0);
      expect(MevTable.getMev('chest'), 9.0);
    });

    test('supported aliases normalize to their canonical muscles', () {
      MevTable.seed(const {
        'quadriceps': 10.0,
        'deltoide_anterior': 4.0,
        'gluteos': 7.0,
        'abdomen': 5.0,
      });

      expect(MevTable.getMev('quads'), 10.0);
      expect(MevTable.getMev('delts_front'), 4.0);
      expect(MevTable.getMev('glutes'), 7.0);
      expect(MevTable.getMev('abs'), 5.0);
    });

    test('unknowns in seed are discarded', () {
      MevTable.seed(const {'unknown_muscle': 10.0});

      expect(MevTable.getMev('unknown_muscle'), 0.0);
      expect(MevTable.getMev('UNKNOWN_MUSCLE'), 0.0);
    });

    test('unknowns in getMev return zero', () {
      MevTable.seed(const {'pectorals': 8.0});

      expect(MevTable.getMev('glute'), 0.0);
      expect(MevTable.getMev('back_mid_upper'), 0.0);
      expect(MevTable.getMev(''), 0.0);
      expect(MevTable.getMev(' '), 0.0);
    });

    test('unknowns do not use raw or raw lowercase passthrough', () {
      MevTable.seed(const {
        'MysteryChest': 11.0,
        'mysterychest': 12.0,
        'pectorals': 8.0,
      });

      expect(MevTable.getMev('MysteryChest'), 0.0);
      expect(MevTable.getMev('mysterychest'), 0.0);
      expect(MevTable.getMev('pectorals'), 8.0);
    });

    test('alias canonical dedupe preserves last written value', () {
      MevTable.seed(const {'chest': 9.0, 'pectorals': 8.0});

      expect(MevTable.getMev('chest'), 8.0);
      expect(MevTable.getMev('pectorals'), 8.0);
    });
  });
}
