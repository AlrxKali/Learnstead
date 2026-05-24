import 'dart:convert';

import 'package:http/http.dart' as http;

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

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class Session {
  static AuthResult? current;
}

class AuthService {
  static const String _defaultBaseUrl = 'http://127.0.0.1:8000';
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultBaseUrl,
  );

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _post('/auth/login', {
      'email': email,
      'password': password,
    });
    final result = AuthResult.fromJson(response);
    Session.current = result;
    return result;
  }

  Future<AuthResult> signup({
    required String email,
    required String password,
    required String role,
    String? fullName,
  }) async {
    final response = await _post('/auth/signup', {
      'email': email,
      'password': password,
      'role': role,
      if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
    });
    final result = AuthResult.fromJson(response);
    Session.current = result;
    return result;
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$path');
    http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw AuthException(
        "Couldn't reach the server at $baseUrl. Is the backend running?",
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    String message = 'Request failed (${response.statusCode})';
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['detail'] != null) {
        message = decoded['detail'].toString();
      }
    } catch (_) {}
    throw AuthException(message);
  }
}
