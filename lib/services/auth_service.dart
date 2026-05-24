import 'api_client.dart';

typedef AuthException = ApiException;

class Profile {
  final String id;
  final String role;
  final String? fullName;
  final DateTime createdAt;

  Profile({
    required this.id,
    required this.role,
    required this.fullName,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      role: json['role'] as String,
      fullName: json['full_name'] as String?,
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
}

class Session {
  static AuthResult? current;
}

class AuthService {
  final ApiClient _client = ApiClient();

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
  }) async {
    final response = await _client.postJson('/auth/signup', {
      'email': email,
      'password': password,
      'role': role,
      if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
    });
    final result = AuthResult.fromJson(response as Map<String, dynamic>);
    Session.current = result;
    return result;
  }
}
