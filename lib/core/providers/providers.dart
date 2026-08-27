import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/zego_call_manager.dart';

// --- Locale Provider ---
class LocaleNotifier extends Notifier<Locale> {
  static const _key = 'app_locale';

  @override
  Locale build() => const Locale('hi');

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code != null) state = Locale(code);
  }

  Future<void> setLocale(Locale locale) async {
    if (locale == state) return;
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
  }

  Future<void> toggle() =>
      setLocale(state.languageCode == 'hi'
          ? const Locale('en')
          : const Locale('hi'));
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

// --- Auth Provider ---
enum AuthStatus { unknown, signedOut, signedIn }

class AuthState {
  AuthState({this.status = AuthStatus.unknown, this.user, this.busy = false});
  final AuthStatus status;
  final AppUser? user;
  final bool busy;

  AuthState copyWith({AuthStatus? status, AppUser? user, bool? busy, bool clearUser = false}) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      busy: busy ?? this.busy,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => AuthState();

  AuthService get _service => ref.read(authServiceProvider);

  Future<void> bootstrap() async {
    final user = await _service.currentUser();
    debugPrint('🔐 Bootstrap User: ${user?.id} (${user?.name})');
    state = state.copyWith(
      user: user,
      status: user == null ? AuthStatus.signedOut : AuthStatus.signedIn,
    );
    if (user != null) {
      await ZegoCallManager.initService(user.id, user.name);
    }
  }

  // Existing signInOrSignUp kept for compatibility but updated to use mobile
  Future<AuthResult> signInOrSignUp({
    required String email, 
    required String password,
    String? name,
    String? phone,
    bool? subscriber,
  }) async {
    state = state.copyWith(busy: true);
    final result = await _service.signInOrSignUp(email: email, password: password, name: name, subscriber: subscriber);
    if (result == AuthResult.ok) {
      final user = await _service.currentUser();
      state = state.copyWith(user: user, status: AuthStatus.signedIn, busy: false);
      if (user != null) {
        await ZegoCallManager.initService(user.id, user.name);
      }
    } else {
      state = state.copyWith(busy: false);
    }
    return result;
  }

  Future<bool> checkUserStatus(String mobile, {Function(String, bool)? onUserFound}) async {
    return await _service.checkUserStatus(mobile, onUserFound: onUserFound);
  }

  Future<Map<String, dynamic>> requestOtp(String mobile, {String? name, bool? isSubscriber}) async {
    state = state.copyWith(busy: true);
    final response = await _service.requestOtp(mobile, name: name, isSubscriber: isSubscriber);
    state = state.copyWith(busy: false);
    return response;
  }

  Future<AuthResult> verifyOtp(String mobile, String otp, {String? name, bool? subscriber}) async {
    state = state.copyWith(busy: true);
    final result = await _service.verifyOtp(mobile, otp, name: name, subscriber: subscriber);
    if (result == AuthResult.ok) {
      final user = await _service.currentUser();
      state = state.copyWith(user: user, status: AuthStatus.signedIn, busy: false);
      if (user != null) {
        await ZegoCallManager.initService(user.id, user.name);
      }
    } else {
      state = state.copyWith(busy: false);
    }
    return result;
  }

  Future<void> updateProfile({required String name, required String phone}) async {
    if (state.user == null) return;
    final updatedUser = state.user!.copyWith(name: name, phone: phone);
    await _service.updateProfile(updatedUser);
    state = state.copyWith(user: updatedUser);
  }

  Future<AuthResult> resetPassword(String email, String newPassword) async {
    return AuthResult.ok;
  }

  Future<void> signOut() async {
    await _service.signOut();
    ZegoCallManager.uninitService();
    state = state.copyWith(clearUser: true, status: AuthStatus.signedOut);
  }
}

final apiServiceProvider = Provider((ref) {
  final locale = ref.watch(localeProvider);
  return ApiService(languageCode: locale.languageCode);
});
final authServiceProvider = Provider((ref) => AuthService(ref.read(apiServiceProvider)));
final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
