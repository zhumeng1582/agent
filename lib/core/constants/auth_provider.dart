import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/api_service.dart';
import '../../data/services/database_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? userId;
  final String? email;
  final String? phone;
  final String? nickname;
  final String? avatarUrl;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.userId,
    this.email,
    this.phone,
    this.nickname,
    this.avatarUrl,
    this.error,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    String? userId,
    String? email,
    String? phone,
    String? nickname,
    String? avatarUrl,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Wait for ApiService to be fully initialized (including token loading)
    while (!ApiService.isInitialized) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    // Additional delay to ensure tokens are loaded into memory
    await Future.delayed(const Duration(milliseconds: 100));

    // Check if we have stored tokens
    if (ApiService.isAuthenticated) {
      debugPrint('[AuthNotifier] Token found, verifying with server...');
      // Verify token by fetching user info
      final response = await ApiService.getMe();
      if (response.success && response.data != null) {
        final userId = response.data['id'] as String?;
        state = AuthState(
          status: AuthStatus.authenticated,
          userId: userId,
          email: response.data['email'],
          phone: response.data['phone'],
          nickname: response.data['nickname'],
          avatarUrl: response.data['avatar_url'],
        );
        DatabaseService.setCurrentUser(userId);
        debugPrint('[AuthNotifier] Auth restored successfully');
        return;
      } else {
        debugPrint('[AuthNotifier] Token invalid or expired, clearing...');
        await ApiService.clearTokens();
      }
    } else {
      debugPrint('[AuthNotifier] No token found, staying logged out');
    }
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<bool> loginWithEmail(String email, String password) async {
    state = state.copyWith(error: null);
    final response = await ApiService.login(email, password);
    if (response.success && response.data != null) {
      final accessToken = response.data['access_token'];
      final refreshToken = response.data['refresh_token'];
      ApiService.setTokens(accessToken: accessToken, refreshToken: refreshToken);

      // Fetch user info
      final userResponse = await ApiService.getMe();
      if (userResponse.success && userResponse.data != null) {
        final userId = userResponse.data['id'] as String?;
        state = AuthState(
          status: AuthStatus.authenticated,
          userId: userId,
          email: userResponse.data['email'],
          phone: userResponse.data['phone'],
          nickname: userResponse.data['nickname'],
          avatarUrl: userResponse.data['avatar_url'],
        );
        DatabaseService.setCurrentUser(userId);
        return true;
      }
    }
    state = state.copyWith(error: response.error ?? 'Login failed');
    return false;
  }

  Future<bool> loginWithPhone(String phone, String password) async {
    state = state.copyWith(error: null);
    final response = await ApiService.phoneLogin(phone, password);
    if (response.success && response.data != null) {
      final accessToken = response.data['access_token'];
      final refreshToken = response.data['refresh_token'];
      ApiService.setTokens(accessToken: accessToken, refreshToken: refreshToken);

      final userResponse = await ApiService.getMe();
      if (userResponse.success && userResponse.data != null) {
        final userId = userResponse.data['id'] as String?;
        state = AuthState(
          status: AuthStatus.authenticated,
          userId: userId,
          email: userResponse.data['email'],
          phone: userResponse.data['phone'],
          nickname: userResponse.data['nickname'],
          avatarUrl: userResponse.data['avatar_url'],
        );
        DatabaseService.setCurrentUser(userId);
        return true;
      }
    }
    state = state.copyWith(error: response.error ?? 'Login failed');
    return false;
  }

  Future<bool> sendSmsCode(String phone) async {
    final response = await ApiService.sendSmsCode(phone);
    return response.success;
  }

  Future<bool> verifySmsCode(String phone, String code) async {
    state = state.copyWith(error: null);
    final response = await ApiService.verifySmsCode(phone, code);
    if (response.success && response.data != null) {
      final accessToken = response.data['access_token'];
      final refreshToken = response.data['refresh_token'];
      ApiService.setTokens(accessToken: accessToken, refreshToken: refreshToken);

      final userResponse = await ApiService.getMe();
      if (userResponse.success && userResponse.data != null) {
        final userId = userResponse.data['id'] as String?;
        state = AuthState(
          status: AuthStatus.authenticated,
          userId: userId,
          email: userResponse.data['email'],
          phone: userResponse.data['phone'],
          nickname: userResponse.data['nickname'],
          avatarUrl: userResponse.data['avatar_url'],
        );
        DatabaseService.setCurrentUser(userId);
        return true;
      }
    }
    state = state.copyWith(error: response.error ?? 'Verification failed');
    return false;
  }

  Future<bool> registerWithPhone(String phone, String password, {String? nickname}) async {
    state = state.copyWith(error: null);
    final response = await ApiService.phoneRegister(phone, password, nickname: nickname);
    if (response.success && response.data != null) {
      // After register, need to login
      return loginWithPhone(phone, password);
    }
    state = state.copyWith(error: response.error ?? 'Registration failed');
    return false;
  }

  Future<bool> registerWithEmail(String email, String password, {String? nickname}) async {
    state = state.copyWith(error: null);
    final response = await ApiService.register(email, password, nickname: nickname);
    if (response.success && response.data != null) {
      // After register, login automatically
      return loginWithEmail(email, password);
    }
    state = state.copyWith(error: response.error ?? 'Registration failed');
    return false;
  }

  Future<bool> wechatLogin(String code) async {
    state = state.copyWith(error: null);
    final response = await ApiService.wechatLogin(code);
    if (response.success && response.data != null) {
      final accessToken = response.data['access_token'];
      final refreshToken = response.data['refresh_token'];
      ApiService.setTokens(accessToken: accessToken, refreshToken: refreshToken);

      final userResponse = await ApiService.getMe();
      if (userResponse.success && userResponse.data != null) {
        final userId = userResponse.data['id'] as String?;
        state = AuthState(
          status: AuthStatus.authenticated,
          userId: userId,
          email: userResponse.data['email'],
          phone: userResponse.data['phone'],
          nickname: userResponse.data['nickname'],
          avatarUrl: userResponse.data['avatar_url'],
        );
        DatabaseService.setCurrentUser(userId);
        return true;
      }
    }
    state = state.copyWith(error: response.error ?? 'WeChat login failed');
    return false;
  }

  Future<void> logout() async {
    await ApiService.logout();
    await ApiService.clearTokens();
    DatabaseService.setCurrentUser(null);
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
