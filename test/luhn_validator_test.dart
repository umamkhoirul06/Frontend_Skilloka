import 'package:flutter_test/flutter_test.dart';
import 'package:skilloka/core/security/luhn_validator.dart';

void main() {
  group('LuhnValidator Tests', () {
    test('Validates Luhn algorithm correctly for valid card numbers', () {
      // 4242 4242 4242 4242 (Stripe Canonical Test Visa)
      expect(LuhnValidator.isValid('4242 4242 4242 4242'), isTrue);
      // 4111 1111 1111 1111 (Official Test Visa)
      expect(LuhnValidator.isValid('4111 1111 1111 1111'), isTrue);
      // 4000 0012 3456 7899
      expect(LuhnValidator.isValid('4000 0012 3456 7899'), isTrue);
    });

    test('Detects invalid card numbers with wrong check digit', () {
      expect(LuhnValidator.isValid('4242 4242 4242 4243'), isFalse);
      expect(LuhnValidator.isValid(''), isFalse);
      expect(LuhnValidator.isValid(null), isFalse);
      expect(LuhnValidator.isValid('12345'), isFalse); // < 13 digits
    });

    test('Detects card brands correctly', () {
      expect(LuhnValidator.getCardBrand('4242 4242 4242 4242'), 'Visa');
      expect(LuhnValidator.getCardBrand('5105 1051 0510 5100'), 'Mastercard');
      expect(LuhnValidator.getCardBrand('3528 1234 5678 9012'), 'JCB');
      expect(LuhnValidator.getCardBrand('3782 8224 6310 005'), 'American Express');
    });

    test('Formats card numbers in groups of 4', () {
      expect(
        LuhnValidator.formatCardNumber('4242424242424242'),
        '4242 4242 4242 4242',
      );
    });

    test('Validates expiry and CVV correctly', () {
      expect(LuhnValidator.isExpiryValid('12/28'), isTrue);
      expect(LuhnValidator.isExpiryValid('13/28'), isFalse); // Invalid month
      expect(LuhnValidator.isExpiryValid('01/20'), isFalse); // Expired in past
      expect(LuhnValidator.isCvvValid('123'), isTrue);
      expect(LuhnValidator.isCvvValid('12'), isFalse);
    });
  });
}
