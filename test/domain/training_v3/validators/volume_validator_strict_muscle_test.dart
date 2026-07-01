import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/domain/training_v3/validators/volume_validator.dart';

void main() {
  group('VolumeValidator strict muscle normalization', () {
    test('canonical keys remain canonical in public output', () {
      final result = VolumeValidator.validateProgram(
        volumeByMuscle: const {'pectorals': 12},
        trainingLevel: 'novice',
      );

      final output = _publicOutput(result);

      expect(result['muscles_validated'], 1);
      expect(output, contains('pectorals'));
    });

    test('aliases normalize to canonical muscles in public output', () {
      final result = VolumeValidator.validateProgram(
        volumeByMuscle: const {
          'chest': 12,
          'quadriceps': 12,
          'deltoide_anterior': 5,
        },
        trainingLevel: 'novice',
      );

      final output = _publicOutput(result);

      expect(result['muscles_validated'], 3);
      expect(output, contains('pectorals'));
      expect(output, contains('quads'));
      expect(output, contains('delts_front'));
      expect(output, isNot(contains('chest')));
      expect(output, isNot(contains('quadriceps')));
      expect(output, isNot(contains('deltoide_anterior')));
    });

    test('explicit legacy aggregate groups are preserved', () {
      final result = VolumeValidator.validateProgram(
        volumeByMuscle: const {'back': 9, 'shoulders': 7, 'arms': 7, 'legs': 7},
        trainingLevel: 'novice',
      );

      final output = _publicOutput(result);

      expect(result['muscles_validated'], 4);
      expect(result['total_volume'], 30);
      expect(output, contains('back'));
      expect(output, contains('shoulders'));
      expect(output, contains('arms'));
      expect(output, contains('legs'));
    });

    test(
      'recognized non-aggregate groups still expand with existing split',
      () {
        final result = VolumeValidator.validateProgram(
          volumeByMuscle: const {'back_group': 20},
          trainingLevel: 'novice',
        );

        final output = _publicOutput(result);

        expect(result['muscles_validated'], 2);
        expect(result['total_volume'], 20);
        expect(output, contains('upper_back'));
        expect(output, isNot(contains('back_group')));
      },
    );

    test('unknowns are discarded from normalized program volume', () {
      final result = VolumeValidator.validateProgram(
        volumeByMuscle: const {
          'unknown_muscle': 40,
          'back_mid_upper': 40,
          'glute': 40,
          'pectorals': 12,
        },
        trainingLevel: 'novice',
      );

      final output = _publicOutput(result);

      expect(result['muscles_validated'], 1);
      expect(result['total_volume'], 12);
      expect(output, isNot(contains('unknown_muscle')));
      expect(output, isNot(contains('back_mid_upper')));
      expect(output, isNot(contains('glute')));
    });

    test('validateMuscleVolume normalizes canonical and alias inputs', () {
      final canonical = VolumeValidator.validateMuscleVolume(
        muscle: 'pectorals',
        volume: 17,
        trainingLevel: 'novice',
      );
      final alias = VolumeValidator.validateMuscleVolume(
        muscle: 'chest',
        volume: 17,
        trainingLevel: 'novice',
      );

      expect(canonical['status'], 'ok');
      expect(alias['status'], 'ok');
      expect(canonical['message'], contains('pectorals'));
      expect(alias['message'], contains('pectorals'));
      expect(alias['message'], isNot(contains('chest')));
    });

    test('validateMuscleVolume unknowns do not expose raw keys', () {
      final result = VolumeValidator.validateMuscleVolume(
        muscle: 'unknown_muscle',
        volume: 9,
        trainingLevel: 'novice',
      );
      final gluteResult = VolumeValidator.validateMuscleVolume(
        muscle: 'glute',
        volume: 9,
        trainingLevel: 'novice',
      );

      final output =
          '${result.values.join(" ")} ${gluteResult.values.join(" ")}';

      expect(result['status'], 'warning');
      expect(gluteResult['status'], 'warning');
      expect(output, isNot(contains('unknown_muscle')));
      expect(output, isNot(contains('glute')));
    });

    test('known thresholds and severities are preserved', () {
      expect(
        VolumeValidator.validateMuscleVolume(
          muscle: 'pectorals',
          volume: 9,
          trainingLevel: 'novice',
        )['status'],
        'error',
      );
      expect(
        VolumeValidator.validateMuscleVolume(
          muscle: 'pectorals',
          volume: 12,
          trainingLevel: 'novice',
        )['status'],
        'warning',
      );
      expect(
        VolumeValidator.validateMuscleVolume(
          muscle: 'pectorals',
          volume: 17,
          trainingLevel: 'novice',
        )['status'],
        'ok',
      );
      expect(
        VolumeValidator.validateMuscleVolume(
          muscle: 'pectorals',
          volume: 25,
          trainingLevel: 'novice',
        )['status'],
        'error',
      );
    });

    test('quality score ignores unknown-only maps', () {
      final score = VolumeValidator.calculateVolumeQualityScore(
        volumeByMuscle: const {
          'unknown_muscle': 40,
          'back_mid_upper': 40,
          'glute': 40,
        },
        trainingLevel: 'novice',
      );

      expect(score, 0.0);
    });
  });
}

String _publicOutput(Map<String, dynamic> result) {
  final errors = result['errors'] as List<dynamic>;
  final warnings = result['warnings'] as List<dynamic>;
  return [...errors, ...warnings].join(' ');
}
