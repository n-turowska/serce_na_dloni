import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

enum AuthState { initial, loading, authenticated, unauthenticated }

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(AuthState.initial);

  Future<void> checkAuth() async {
    final token = await _authService.getAccessToken();
    if (token != null) {
      state = AuthState.authenticated;
    } else {
      state = AuthState.unauthenticated;
    }
  }

  Future<void> login(String email, String password) async {
    state = AuthState.loading;
    try {
      await _authService.login(email, password);
      state = AuthState.authenticated;
    } on AuthException {
      state = AuthState.unauthenticated;
      rethrow;
    }
  }

  Future<void> register(
    String email,
    String firstName,
    String lastName,
    String password,
  ) async {
    state = AuthState.loading;
    try {
      await _authService.register(email, firstName, lastName, password);
      // po rejestracji od razu zaloguj
      await _authService.login(email, password);
      state = AuthState.authenticated;
    } on AuthException {
      state = AuthState.unauthenticated;
      rethrow;
    }
  }

  Future<void> logout() async {
    await _authService.deleteTokens();
    state = AuthState.unauthenticated;
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});

final userProfileProvider = FutureProvider<UserProfile>((ref) {
  return ref.read(authServiceProvider).getUserProfile();
});
