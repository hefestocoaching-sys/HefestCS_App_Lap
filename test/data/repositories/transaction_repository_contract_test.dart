import 'package:flutter_test/flutter_test.dart';
import 'package:hcs_app_lap/data/repositories/transaction_repository.dart';

void main() {
  group('TransactionRepository amount contract', () {
    test('accepts valid int and double values', () {
      expect(readFiniteAmount(10), 10.0);
      expect(readFiniteAmount(12.5), 12.5);
    });

    test('rejects missing and null amount values', () {
      expect(readFiniteAmount(null), isNull);
      expect(readFiniteAmount(const Object()), isNull);
    });

    test('rejects string, bool, map and list values', () {
      expect(readFiniteAmount('10.5'), isNull);
      expect(readFiniteAmount(true), isNull);
      expect(readFiniteAmount(<String, dynamic>{'amount': 10}), isNull);
      expect(readFiniteAmount([10]), isNull);
    });

    test('rejects non-finite doubles', () {
      expect(readFiniteAmount(double.nan), isNull);
      expect(readFiniteAmount(double.infinity), isNull);
      expect(readFiniteAmount(double.negativeInfinity), isNull);
    });
  });
}
