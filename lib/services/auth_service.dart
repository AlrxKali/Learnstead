import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'api_client.dart';

typedef AuthException = ApiException;

/// Signed in with Supabase (e.g. Google/Apple) but no profile row yet.
class ProfileMissingException extends ApiException {
  ProfileMissingException() : super('Profile not found', statusCode: 404);
}

/// Signup succeeded but the project requires email confirmation first.
class EmailConfirmationRequiredException extends ApiException {
  EmailConfirmationRequiredException(super.message);
}

class Profile {
  final String id;
  final String role;
  final String? fullName;
  final String? homeZipCode;
  final DateTime createdAt;

  Profile({
    required this.id,
    required this.role,
    required this.fullName,
    required this.homeZipCode,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      role: json['role'] as String,
      fullName: json['full_name'] as String?,
      homeZipCode: json['home_zip_code'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class AuthResult {
  final String accessToken;
  final String refreshToken;
  final Profile profile;

  AuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.profile,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      profile: Profile.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  AuthResult copyWithProfile(Profile newProfile) {
    return AuthResult(
      accessToken: accessToken,
      refreshToken: refreshToken,
      profile: newProfile,
    );
  }
}

class Session {
  static AuthResult? current;

  /// Bearer token for API calls.
  ///
  /// Prefers the supabase_flutter session, which is persisted across app
  /// restarts and refreshed automatically before it expires. Falls back
  /// to the token the backend handed out at login.
  static String? get accessToken {
    if (current == null) return null;
    try {
      final live = sb.Supabase.instance.client.auth.currentSession?.accessToken;
      if (live != null) return live;
    } catch (_) {
      // Supabase not initialised (e.g. tests) — use the login token.
    }
    return current?.accessToken;
  }

  static String? get email {
    try {
      return sb.Supabase.instance.client.auth.currentUser?.email;
    } catch (_) {
      return null;
    }
  }

  static void setProfile(Profile profile) {
    final c = current;
    if (c != null) current = c.copyWithProfile(profile);
  }
}

class AuthService {
  final ApiClient _client = ApiClient();

  String _requireToken() {
    final token = Session.accessToken;
    if (token == null) {
      throw ApiException('You are not signed in.');
    }
    return token;
  }

  sb.GoTrueClient get _sbAuth => sb.Supabase.instance.client.auth;

  /// Deep link the OAuth browser tab returns to on mobile/desktop. Must be
  /// listed in Supabase Auth → URL Configuration → Redirect URLs. On web
  /// the Supabase site URL is used instead.
  static const String oauthRedirectUrl = 'io.learnstead.app://login-callback';

  /// Rebuild [Session.current] from the persisted Supabase session.
  ///
  /// Returns the profile when the user is fully signed in, or null when
  /// there is no session. Throws [ProfileMissingException] when there is
  /// a session but no profile yet (first sign-in with Google/Apple).
  Future<Profile?> restoreSession() async {
    final session = _sbAuth.currentSession;
    if (session == null) return null;
    try {
      final response =
          await _client.getJson('/auth/me', token: session.accessToken);
      final profile = Profile.fromJson(response as Map<String, dynamic>);
      Session.current = AuthResult(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken ?? '',
        profile: profile,
      );
      return profile;
    } on ApiException catch (e) {
      if (e.statusCode == 404) throw ProfileMissingException();
      if (e.statusCode == 401) {
        // Stored session is no longer valid; start clean.
        await logout();
        return null;
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    Session.current = null;
    try {
      await _sbAuth.signOut();
    } catch (_) {
      // Already signed out / offline: local state is cleared regardless.
    }
  }

  /// Opens the provider's consent page. The result arrives asynchronously
  /// through Supabase's auth state stream (see AuthGate).
  Future<void> signInWithProvider(sb.OAuthProvider provider) async {
    try {
      final launched = await _sbAuth.signInWithOAuth(
        provider,
        redirectTo: kIsWeb ? null : oauthRedirectUrl,
      );
      if (!launched) {
        throw ApiException("Couldn't open the sign-in page.");
      }
    } on sb.AuthException catch (e) {
      throw ApiException(e.message);
    }
  }

  /// Finish signup for a Google/Apple user who has no profile row yet.
  Future<Profile> completeProfile({
    required String role,
    String? fullName,
    String? homeZipCode,
  }) async {
    final session = _sbAuth.currentSession;
    if (session == null) throw ApiException('You are not signed in.');
    final response = await _client.postJson(
      '/auth/profile',
      {
        'role': role,
        if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
        if (homeZipCode != null && homeZipCode.isNotEmpty)
          'home_zip_code': homeZipCode,
      },
      token: session.accessToken,
    );
    final profile = Profile.fromJson(response as Map<String, dynamic>);
    Session.current = AuthResult(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken ?? '',
      profile: profile,
    );
    return profile;
  }

  /// Emails a 6-digit recovery code (if the address has an account).
  Future<void> requestPasswordReset(String email) async {
    await _client.postJson('/auth/forgot-password', {'email': email});
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _client.postJson('/auth/reset-password', {
      'email': email,
      'code': code,
      'new_password': newPassword,
    });
  }

  Future<void> deleteAccount() async {
    await _client.deleteJson('/auth/me', token: _requireToken());
    await logout();
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.postJson('/auth/login', {
      'email': email,
      'password': password,
    });
    final result = AuthResult.fromJson(response as Map<String, dynamic>);
    Session.current = result;
    await _syncSupabaseSession(email: email, password: password);
    return result;
  }

  Future<AuthResult> signup({
    required String email,
    required String password,
    required String role,
    String? fullName,
    String? homeZipCode,
  }) async {
    final body = <String, dynamic>{
      'email': email,
      'password': password,
      'role': role,
      if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
      if (homeZipCode != null && homeZipCode.isNotEmpty)
        'home_zip_code': homeZipCode,
    };
    final response = await _client.postJson('/auth/signup', body);
    if (response is Map && response['confirmation_required'] == true) {
      throw EmailConfirmationRequiredException(
        (response['detail'] as String?) ??
            'Check your email to confirm your account, then sign in.',
      );
    }
    final result = AuthResult.fromJson(response as Map<String, dynamic>);
    Session.current = result;
    await _syncSupabaseSession(email: email, password: password);
    return result;
  }

  /// Sign into supabase_flutter with the same credentials so its client has
  /// a session for Realtime + chat queries. Same credentials FastAPI just
  /// validated; this is safe and idempotent.
  Future<void> _syncSupabaseSession({
    required String email,
    required String password,
  }) async {
    try {
      await sb.Supabase.instance.client.auth
          .signInWithPassword(email: email, password: password);
    } catch (_) {
      // Non-fatal: chat features will fail loud later, but the rest of
      // the app keeps working on the backend-issued token. Drop any stale
      // session so Session.accessToken can't return another user's token.
      try {
        await sb.Supabase.instance.client.auth.signOut();
      } catch (_) {}
    }
  }

  Future<Profile> updateMyProfile({
    String? fullName,
    String? homeZipCode,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['full_name'] = fullName;
    if (homeZipCode != null) body['home_zip_code'] = homeZipCode;
    final response = await _client.patchJson(
      '/auth/me',
      body,
      token: _requireToken(),
    );
    final profile = Profile.fromJson(response as Map<String, dynamic>);
    Session.setProfile(profile);
    return profile;
  }
}
