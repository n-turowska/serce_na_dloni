import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:serce_na_dloni/services/pressure_encryption_service.dart';

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
  Future<bool> containsKey({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _storage.containsKey(key);
  }
}

void main() {
  late FakeFlutterSecureStorage fakeStorage;
  late PressureEncryptionService service;

  setUp(() {
    fakeStorage = FakeFlutterSecureStorage();
    service = PressureEncryptionService(storage: fakeStorage);
  });

  group('Testy PressureEncryptionService', () {
    test(
      'Szyfrowanie i odszyfrowywanie mapy powinno zwrócić identyczną mapę',
      () async {
        final originalData = {
          'id': 'entry_123',
          'systolic': 120,
          'diastolic': 80,
          'note': 'Wszystko w porządku',
          'created_at': DateTime.now().toIso8601String(),
        };

        final encrypted = await service.encryptMap(originalData);

        final parts = encrypted.split(':');
        expect(parts.length, equals(3));
        for (final part in parts) {
          expect(part.isNotEmpty, isTrue);
          expect(base64Decode(part), isNotNull);
        }

        final decrypted = await service.decryptMap(encrypted);
        expect(decrypted, equals(originalData));
      },
    );

    test(
      'Klucz szyfrowania powinien być zapisywany w pamięci i używany ponownie',
      () async {
        final originalData = {'systolic': 130, 'diastolic': 85};

        final encrypted = await service.encryptMap(originalData);

        const keyStorageKey = 'pressure_entries_encryption_key_v1';
        expect(await fakeStorage.containsKey(key: keyStorageKey), isTrue);
        final storedKey = await fakeStorage.read(key: keyStorageKey);
        expect(storedKey, isNotNull);

        final secondService = PressureEncryptionService(storage: fakeStorage);

        final decrypted = await secondService.decryptMap(encrypted);
        expect(decrypted, equals(originalData));
      },
    );

    test(
      'Odszyfrowywanie uszkodzonych lub nieprawidłowo sformatowanych danych powinno wyrzucić błąd',
      () async {
        expect(
          () => service.decryptMap('part1:part2'),
          throwsA(isA<FormatException>()),
        );

        final validPayload = await service.encryptMap({'systolic': 120});
        final parts = validPayload.split(':');
        final corruptedCiphertext =
            '${parts[1].substring(0, parts[1].length - 1)}A';
        final corruptedPayload = [
          parts[0],
          corruptedCiphertext,
          parts[2],
        ].join(':');

        expect(() => service.decryptMap(corruptedPayload), throwsException);
      },
    );

    test('Hash użytkownika powinien generować spójne wartości', () async {
      const email = 'Jan.Kowalski@example.com';
      const normalizedEmail = 'jan.kowalski@example.com';

      final hash1 = await service.userHash(email);
      final hash2 = await service.userHash(' $normalizedEmail ');
      expect(hash1, equals(hash2));

      final unpaddedHash = hash1.substring(0, hash1.length - 1);
      expect(Uri.encodeComponent(unpaddedHash), equals(unpaddedHash));

      final hash3 = await service.userHash('other@example.com');
      expect(hash1, isNot(equals(hash3)));
    });

    test(
      'Hash użytkownika powinien ulec zmianie po zmianie klucza szyfrowania',
      () async {
        const email = 'user@example.com';

        final hash1 = await service.userHash(email);

        final freshStorage = FakeFlutterSecureStorage();
        final freshService = PressureEncryptionService(storage: freshStorage);

        const keyStorageKey = 'pressure_entries_encryption_key_v1';
        final key1 = await fakeStorage.read(key: keyStorageKey);
        expect(key1, isNotNull);

        final key1Bytes = base64Decode(key1!);
        final key2Bytes = List<int>.from(key1Bytes);
        key2Bytes[0] = (key2Bytes[0] + 1) % 256;

        await freshStorage.write(
          key: keyStorageKey,
          value: base64Encode(key2Bytes),
        );

        final hash2 = await freshService.userHash(email);
        expect(hash1, isNot(equals(hash2)));
      },
    );
  });
}
