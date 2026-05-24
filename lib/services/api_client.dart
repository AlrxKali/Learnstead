import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  static const String _defaultBaseUrl = 'http://127.0.0.1:8000';
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultBaseUrl,
  );

  static const Duration _timeout = Duration(seconds: 15);

  Future<dynamic> getJson(String path, {String? token}) {
    return _send('GET', path, token: token);
  }

  Future<dynamic> postJson(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) {
    return _send('POST', path, body: body, token: token);
  }

  Future<dynamic> putJson(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) {
    return _send('PUT', path, body: body, token: token);
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await http.get(uri, headers: headers).timeout(_timeout);
          break;
        case 'POST':
          response = await http
              .post(uri, headers: headers, body: jsonEncode(body ?? {}))
              .timeout(_timeout);
          break;
        case 'PUT':
          response = await http
              .put(uri, headers: headers, body: jsonEncode(body ?? {}))
              .timeout(_timeout);
          break;
        default:
          throw ApiException('Unsupported method $method');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        "Couldn't reach the server at $baseUrl. Is the backend running?",
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    String message = 'Request failed (${response.statusCode})';
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['detail'] != null) {
        message = decoded['detail'].toString();
      }
    } catch (_) {}
    throw ApiException(message, statusCode: response.statusCode);
  }
}
