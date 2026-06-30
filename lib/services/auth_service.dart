import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}

enum Privilege { User, Admin }

class UserProfile {
  final String? firstName;
  final String? lastName;
  final String? email;
  final Privilege privilege;

  const UserProfile({
    this.firstName,
    this.lastName,
    this.email,
    this.privilege = Privilege.User,
  });
}

class AuthService {
  final FlutterSecureStorage _storage;

  AuthService({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _currentEmailKey = 'current_email';
  static const _firstNameKey = 'first_name';
  static const _lastNameKey = 'last_name';
  static const _emailKey = 'email';

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  String _profileFirstNameKey(String email) =>
      'profile_${_normalizeEmail(email)}_first_name';

  String _profileLastNameKey(String email) =>
      'profile_${_normalizeEmail(email)}_last_name';

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<String?> getCurrentEmail() async {
    return await _storage.read(key: _currentEmailKey);
  }

  Future<void> deleteTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _currentEmailKey);
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _firstNameKey);
    await _storage.delete(key: _lastNameKey);
  }

  Future<void> saveUserProfile({
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    await _storage.write(key: _currentEmailKey, value: normalizedEmail);
    await _storage.write(key: _emailKey, value: normalizedEmail);
    await _storage.write(
      key: _profileFirstNameKey(normalizedEmail),
      value: firstName,
    );
    await _storage.write(
      key: _profileLastNameKey(normalizedEmail),
      value: lastName,
    );
  }

  Future<void> saveUserNames({
    required String firstName,
    required String lastName,
  }) async {
    final email = await getCurrentEmail();
    if (email == null) {
      throw AuthException('Nie można zapisać danych bez zalogowanego konta.');
    }

    await _storage.write(key: _profileFirstNameKey(email), value: firstName);
    await _storage.write(key: _profileLastNameKey(email), value: lastName);
  }

  Future<UserProfile> getUserProfile() async {
    final email = await getCurrentEmail();
    if (email == null) {
      return const UserProfile();
    }

    final privilege = (email == adminUsername) ? Privilege.Admin : Privilege.User;

    final firstName = await _storage.read(key: _profileFirstNameKey(email));
    final lastName = await _storage.read(key: _profileLastNameKey(email));

    if (firstName == null && lastName == null) {
      final legacyEmail = await _storage.read(key: _emailKey);
      if (legacyEmail != null && _normalizeEmail(legacyEmail) == email) {
        return UserProfile(
          firstName: await _storage.read(key: _firstNameKey),
          lastName: await _storage.read(key: _lastNameKey),
          email: email,
          privilege: privilege,
        );
      }
    }

    return UserProfile(
      firstName: firstName,
      lastName: lastName,
      email: email,
      privilege: privilege,
    );
  }

  Future<void> login(String email, String password) async {
    final normalizedEmail = _normalizeEmail(email);
    if (normalizedEmail == adminUsername && password == adminPassword) {
      await saveTokens('admin_access_token', 'admin_refresh_token');
      await _storage.write(key: _currentEmailKey, value: adminUsername);
      await _storage.write(key: _emailKey, value: adminUsername);
      await _storage.write(key: _profileFirstNameKey(adminUsername), value: 'Admin');
      await _storage.write(key: _profileLastNameKey(adminUsername), value: 'Systemowy');
      return;
    }

    final url = Uri.parse('$apiBaseUrl/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'username': email, // OAuth2 convention: email goes in 'username'
        'password': password,
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await saveTokens(
        data['access_token'] as String,
        data['refresh_token'] as String,
      );
      await _storage.write(
        key: _currentEmailKey,
        value: _normalizeEmail(email),
      );
      await _storage.write(key: _emailKey, value: _normalizeEmail(email));
    } else if (response.statusCode == 401) {
      throw AuthException('Niepoprawny login lub hasło.');
    } else {
      throw AuthException('Logowanie nie powiodło się. Spróbuj ponownie.');
    }
  }

  Future<void> register(
    String email,
    String firstName,
    String lastName,
    String password,
  ) async {
    final url = Uri.parse('$apiBaseUrl/auth/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'username': firstName,
        'password': password,
      }),
    );
    if (response.statusCode == 201) {
      await saveUserProfile(
        firstName: firstName,
        lastName: lastName,
        email: email,
      );
      return;
    } else if (response.statusCode == 400) {
      final data = jsonDecode(response.body);
      throw AuthException(data['detail'] as String);
    } else {
      throw AuthException('Rejestracja nie powiodła się. Spróbuj ponownie.');
    }
  }
}
