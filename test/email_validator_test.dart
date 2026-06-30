import 'package:flutter_test/flutter_test.dart';
import 'package:serce_na_dloni/utils/emailValidator.dart';

void main() {
  group('Email Validation Tests', () {
    test('Poprawne adresy email powinny zwracać true', () {
      expect(isValidEmail('test@example.com'), isTrue);
      expect(isValidEmail('user.name@domain.co.uk'), isTrue);
      expect(isValidEmail('a@b.pl'), isTrue);
      expect(isValidEmail('test.email+alex@subdomain.example.org'), isTrue);
    });

    test('Brak symbolu @ powinno zwracać false', () {
      expect(isValidEmail('testexample.com'), isFalse);
    });

    test('Wiele symboli @ powinno zwracać false', () {
      expect(isValidEmail('test@@example.com'), isFalse);
      expect(isValidEmail('test@ex@ample.com'), isFalse);
    });

    test('Brak domeny powinno zwracać false', () {
      expect(isValidEmail('test@example'), isFalse);
    });

    test('Pusta domena albo część lokalna powinna zwracać false', () {
      expect(isValidEmail('@example.com'), isFalse);
      expect(isValidEmail('test@'), isFalse);
    });

    test('Złe ułożenie kropek powinno zwracać false', () {
      expect(isValidEmail('test@.com'), isFalse);
      expect(isValidEmail('test@example.'), isFalse);
      expect(isValidEmail('test@example..com'), isFalse);
    });

    test(
      'Zakończenie domeny o długości mniejszej niż 2 powinno zwracać false',
      () {
        expect(isValidEmail('test@example.c'), isFalse);
      },
    );
  });
}
