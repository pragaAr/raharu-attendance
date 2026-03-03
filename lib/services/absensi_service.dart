import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:absensi/config/api_config.dart';
import 'package:absensi/services/auth_service.dart';

class AbsensiResult {
  final bool success;
  final String message;

  AbsensiResult({required this.success, required this.message});
}

class AbsensiService {
  final _authService = AuthService();

  Future<AbsensiResult> submitAbsen() async {
    final token = await _authService.getToken();
    if (token == null) {
      return AbsensiResult(success: false, message: 'Tidak ada sesi aktif, harap login kembali.');
    }

    try {
      final response = await _postWithFallback(
        '/absensi/store',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return AbsensiResult(
          success: true,
          message: data['message'] ?? 'Berhasil absen',
        );
      } else {
        return AbsensiResult(
          success: false,
          message: data['message'] ?? 'Gagal melakukan absen',
        );
      }
    } catch (e) {
      return AbsensiResult(
        success: false,
        message: 'Tidak dapat terhubung ke server',
      );
    }
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
            .timeout(const Duration(seconds: 15));
      } catch (e) {
        lastError = e;
      }
    }

    throw lastError ?? Exception('Gagal terhubung ke API');
  }
}
