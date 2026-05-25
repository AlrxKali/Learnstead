import 'api_client.dart';

typedef AuthException = ApiException;

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

  static void setProfile(Profile profile) {
    final c = current;
    if (c != null) current = c.copyWithProfile(profile);
  }
}

class AuthService {
  final ApiClient _client = ApiClient();

  String _requireToken() {
    final token = Session.current?.accessToken;
    if (token == null) {
      throw ApiException('You are not signed in.');
    }
    return token;
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
    final result = AuthResult.fromJson(response as Map<String, dynamic>);
    Session.current = result;
    return result;
  }

  Future<Profile> updateMyProfile({String? homeZipCode}) async {
    final body = <String, dynamic>{};
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
