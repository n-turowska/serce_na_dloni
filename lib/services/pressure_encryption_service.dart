import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PressureEncryptionService {
  PressureEncryptionService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _keyStorageKey = 'pressure_entries_encryption_key_v1';
  static const _keyLength = 32;
  static const _nonceLength = 12;

  final FlutterSecureStorage _storage;
  final AesGcm _cipher = AesGcm.with256bits();
  final Hmac _hmac = Hmac.sha256();

  Future<String> encryptMap(Map<String, dynamic> data) async {
    final secretKey = await _getOrCreateSecretKey();
    final nonce = _randomBytes(_nonceLength);
    final encoded = utf8.encode(jsonEncode(data));
    final box = await _cipher.encrypt(
      encoded,
      secretKey: secretKey,
      nonce: nonce,
    );

    return [
      base64Encode(box.nonce),
      base64Encode(box.cipherText),
      base64Encode(box.mac.bytes),
    ].join(':');
  }

  Future<Map<String, dynamic>> decryptMap(String encryptedPayload) async {
    final parts = encryptedPayload.split(':');
    if (parts.length != 3) {
      throw const FormatException('Nieprawidłowy format zaszyfrowanego wpisu.');
    }

    final secretKey = await _getOrCreateSecretKey();
    final clearText = await _cipher.decrypt(
      SecretBox(
        base64Decode(parts[1]),
        nonce: base64Decode(parts[0]),
        mac: Mac(base64Decode(parts[2])),
      ),
      secretKey: secretKey,
    );

    final decoded = jsonDecode(utf8.decode(clearText));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Odszyfrowany wpis nie jest obiektem JSON.');
    }

    return decoded;
  }

  Future<String> userHash(String userEmail) async {
    final normalizedEmail = userEmail.trim().toLowerCase();
    final secretKey = await _getOrCreateSecretKey();
    final mac = await _hmac.calculateMac(
      utf8.encode(normalizedEmail),
      secretKey: secretKey,
    );
    return base64UrlEncode(mac.bytes);
  }

  Future<SecretKey> _getOrCreateSecretKey() async {
    final existingKey = await _storage.read(key: _keyStorageKey);
    if (existingKey != null) {
      return SecretKey(base64Decode(existingKey));
    }

    final keyBytes = _randomBytes(_keyLength);
    await _storage.write(key: _keyStorageKey, value: base64Encode(keyBytes));
    return SecretKey(keyBytes);
  }

  List<int> _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }
}
