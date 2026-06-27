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

class UserProfile {
  final String? firstName;
  final String? lastName;
  final String? email;

  const UserProfile({this.firstName, this.lastName, this.email});
}

class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _firstNameKey = 'first_name';
  static const _lastNameKey = 'last_name';
  static const _emailKey = 'email';

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

  Future<void> deleteTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<void> saveUserProfile({
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    await _storage.write(key: _firstNameKey, value: firstName);
    await _storage.write(key: _lastNameKey, value: lastName);
    await _storage.write(key: _emailKey, value: email);
  }

  Future<void> saveUserNames({
    required String firstName,
    required String lastName,
  }) async {
    await _storage.write(key: _firstNameKey, value: firstName);
    await _storage.write(key: _lastNameKey, value: lastName);
  }

  Future<UserProfile> getUserProfile() async {
    return UserProfile(
      firstName: await _storage.read(key: _firstNameKey),
      lastName: await _storage.read(key: _lastNameKey),
      email: await _storage.read(key: _emailKey),
    );
  }

  Future<void> login(String email, String password) async {
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
      await _storage.write(key: _emailKey, value: email);
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
