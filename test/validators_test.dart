import 'package:flutter_test/flutter_test.dart';
import 'package:croplens_app/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('rejects empty email', () {
      expect(Validators.email(''), isNotNull);
    });
    test('rejects malformed email', () {
      expect(Validators.email('not-an-email'), isNotNull);
    });
    test('accepts valid email', () {
      expect(Validators.email('farmer@croplens.app'), isNull);
    });
  });

  group('Validators.password', () {
    test('rejects short password', () {
      expect(Validators.password('Ab1'), isNotNull);
    });
    test('rejects password without uppercase', () {
      expect(Validators.password('lowercase1'), isNotNull);
    });
    test('rejects password without a number', () {
      expect(Validators.password('NoNumbersHere'), isNotNull);
    });
    test('accepts a strong password', () {
      expect(Validators.password('StrongPass1'), isNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('rejects mismatched confirmation', () {
      final validator = Validators.confirmPassword(() => 'StrongPass1');
      expect(validator('DifferentPass1'), isNotNull);
    });
    test('accepts matching confirmation', () {
      final validator = Validators.confirmPassword(() => 'StrongPass1');
      expect(validator('StrongPass1'), isNull);
    });
  });
}
