import 'package:flutter_test/flutter_test.dart';
import 'package:airsoft_shop/utils/validators.dart';

void main() {
  group('Validators Unit Tests', () {
    test('isEmail should validate correct and incorrect emails', () {
      expect(Validators.isEmail('test@example.com'), isTrue);
      expect(Validators.isEmail('invalid-email'), isFalse);
    });

    test('isRegisterPasswordValid should validate register passwords', () {
      expect(Validators.isRegisterPasswordValid('P@ssword123'), isTrue);
      expect(Validators.isRegisterPasswordValid('simple'), isFalse);
    });
  });
}
