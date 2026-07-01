import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:serce_na_dloni/main.dart';
import 'package:serce_na_dloni/providers/auth_provider.dart';
import 'package:serce_na_dloni/services/auth_service.dart';

class FakeFlutterSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _storage[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _storage.remove(key);
    } else {
      _storage[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _storage.remove(key);
  }
}

void main() {
  testWidgets(
    'Logowanie jako admin, przejście do zakładki konto i weryfikacja danych',
    (WidgetTester tester) async {
      final fakeStorage = FakeFlutterSecureStorage();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(AuthService(storage: fakeStorage)),
          ],
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      final emailFieldFinder = find.byType(TextField).first;
      final passwordFieldFinder = find.byType(TextFormField).first;
      final loginButtonFinder = find.byType(FilledButton);

      expect(emailFieldFinder, findsOneWidget);
      expect(passwordFieldFinder, findsOneWidget);
      expect(loginButtonFinder, findsOneWidget);

      await tester.enterText(emailFieldFinder, 'admin');
      await tester.enterText(passwordFieldFinder, 'admin123');
      await tester.pump();

      await tester.tap(loginButtonFinder);
      await tester.pumpAndSettle();

      expect(find.text('Serce na Dłoni'), findsOneWidget);

      final kontoTabButtonFinder = find.text('Konto');
      expect(kontoTabButtonFinder, findsOneWidget);
      
      await tester.tap(kontoTabButtonFinder);
      await tester.pumpAndSettle();

      expect(find.text('Imię: Admin'), findsOneWidget);
      expect(find.text('Nazwisko: Systemowy'), findsOneWidget);
      expect(find.text('Email: admin'), findsOneWidget);
      expect(find.text('Panel Administratora'), findsOneWidget);
    },
  );
}
