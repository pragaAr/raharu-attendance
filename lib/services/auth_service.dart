import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:absensi/config/api_config.dart';

class AuthResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? errors;

  AuthResult({
    required this.success,
    required this.message,
    this.user,
    this.errors,
  });
}

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  /// Login with username and password
  Future<AuthResult> login(String username, String password) async {
    try {
      final response = await _postWithFallback(
        '/login',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Save token and user data
        await _saveToken(data['token']);
        await _saveUser(data['user']);

        return AuthResult(
          success: true,
          message: data['message'] ?? 'Login berhasil',
          user: data['user'],
        );
      } else if (response.statusCode == 422) {
        // Validation errors
        return AuthResult(
          success: false,
          message: data['message'] ?? 'Validasi gagal',
          errors: data['errors'],
        );
      } else if (response.statusCode == 401) {
        return AuthResult(
          success: false,
          message: data['message'] ?? 'Username atau password salah',
        );
      } else if (response.statusCode == 403) {
        return AuthResult(
          success: false,
          message: data['message'] ?? 'Akun tidak aktif',
        );
      } else {
        return AuthResult(
          success: false,
          message: 'Terjadi kesalahan server',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    }
  }

  /// Logout and clear stored data
  Future<void> logout() async {
    final token = await getToken();
    if (token != null) {
      try {
        await _postWithFallback(
          '/logout',
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      } catch (_) {
        // Ignore network errors during logout
      }
    }
    await _clearAuth();
  }

  /// Get stored token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Get stored user data
  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      return jsonDecode(userJson);
    }
    return null;
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> _saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user));
  }

  Future<void> _clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  Future<http.Response> _postWithFallback(
    String endpoint, {
    required Map<String, String> headers,
    Object? body,
  }) async {
    Object? lastError;

    for (final baseUrl in ApiConfig.fallbackBaseUrls) {
      try {
        return await http
            .post(
              Uri.parse('$baseUrl$endpoint'),
              headers: headers,
              body: body,
            )
            .timeout(const Duration(seconds: 10));
      } on SocketException catch (e) {
        lastError = e;
      } on TimeoutException catch (e) {
        lastError = e;
      }
    }

    if (lastError != null) {
      throw lastError;
    }

    throw Exception('Tidak ada API base URL yang valid.');
  }
}
